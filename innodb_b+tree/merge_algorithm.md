# B+ Tree Page Merge in InnoDB

## Merge Function


## Merge related functions
in storage/innobase/btr/
- btr_compress(): main merge function
- btr_cur_compress_if_useful()
- btr_cur_compress_recommendation()
 
## When?
Merge called during ``DELETE`` or ``UPDATE``
- ``UPDATE`` : btr_cur_pessimistic_update()
- ``DELETE`` : btr_cur_pessimistic_delete()

## Page Merging Algorithm

### btr_cur_compress_if_useful(): btr0cur.cc
```bash
/*************************************************************//**
Tries to compress a page of the tree if it seems useful. It is assumed
that mtr holds an x-latch on the tree and on the cursor page. To avoid
deadlocks, mtr must also own x-latches to brothers of page, if those
brothers exist. NOTE: it is assumed that the caller has reserved enough
free extents so that the compression will always succeed if done!
@return	TRUE if compression occurred */
UNIV_INTERN
ibool
btr_cur_compress_if_useful(
/*=======================*/
	btr_cur_t*	cursor,	/*!< in/out: cursor on the page to compress;
				cursor does not stay valid if !adjust and
				compression occurs */
	ibool		adjust,	/*!< in: TRUE if should adjust the
				cursor position even if compression occurs */
	mtr_t*		mtr)	/*!< in/out: mini-transaction */
{
	ut_ad(mtr_memo_contains(mtr,
				dict_index_get_lock(btr_cur_get_index(cursor)),
				MTR_MEMO_X_LOCK));
	ut_ad(mtr_memo_contains(mtr, btr_cur_get_block(cursor),
				MTR_MEMO_PAGE_X_FIX));

	return(btr_cur_compress_recommendation(cursor, mtr)
	       && btr_compress(cursor, adjust, mtr));
}

```
### MERGE THRESHOLD: BTR_CUR_PAGE_COMPRESS_LIMIT
```bash
/** In the pessimistic delete, if the page data size drops below this
limit, merging it to a neighbor is tried */

/* lbh */
//#define BTR_CUR_PAGE_COMPRESS_LIMIT	(UNIV_PAGE_SIZE / 2)
#define BTR_CUR_PAGE_COMPRESS_LIMIT	(UNIV_PAGE_SIZE /4*3)
/* end */
```

### btr_cur_compress_recommendation(): btr0cur.ic
```bash
Checks if compressing an index page where a btr cursor is placed makes
sense.
@return	TRUE if compression is recommended */
UNIV_INLINE
ibool
btr_cur_compress_recommendation(
/*============================*/
	btr_cur_t*	cursor,	/*!< in: btr cursor */
	mtr_t*		mtr)	/*!< in: mtr */
{
	const page_t*	page;

	ut_ad(mtr_memo_contains(mtr, btr_cur_get_block(cursor),
				MTR_MEMO_PAGE_X_FIX));

	page = btr_cur_get_page(cursor);

	LIMIT_OPTIMISTIC_INSERT_DEBUG(page_get_n_recs(page) * 2,
				      return(FALSE));

	if ((page_get_data_size(page) < BTR_CUR_PAGE_COMPRESS_LIMIT)
	    || ((btr_page_get_next(page, mtr) == FIL_NULL)
		&& (btr_page_get_prev(page, mtr) == FIL_NULL))) {

		/* The page fillfactor has dropped below a predefined
		minimum value OR the level in the B-tree contains just
		one page: we recommend compression if this is not the
		root page. */

		return(dict_index_get_page(cursor->index)
		       != page_get_page_no(page));
	}

	return(FALSE);
}
```
### btr_compress(): btr0btr.cc
```bash
/*************************************************************//**
Tries to merge the page first to the left immediate brother if such a
brother exists, and the node pointers to the current page and to the brother
reside on the same page. If the left brother does not satisfy these
conditions, looks at the right brother. If the page is the only one on that
level lifts the records of the page to the father page, thus reducing the
tree height. It is assumed that mtr holds an x-latch on the tree and on the
page. If cursor is on the leaf level, mtr must also hold x-latches to the
brothers, if they exist.
@return	TRUE on success */
UNIV_INTERN
ibool
btr_compress(
/*=========*/
	btr_cur_t*	cursor,	/*!< in/out: cursor on the page to merge
				or lift; the page must not be empty:
				when deleting records, use btr_discard_page()
				if the page would become empty */
	ibool		adjust,	/*!< in: TRUE if should adjust the
				cursor position even if compression occurs */
	mtr_t*		mtr)	/*!< in/out: mini-transaction */
{
	dict_index_t*	index;
	ulint		space;
	ulint		zip_size;
	ulint		left_page_no;
	ulint		right_page_no;
	buf_block_t*	merge_block;
	page_t*		merge_page = NULL;
	page_zip_des_t*	merge_page_zip;
	ibool		is_left;
	buf_block_t*	block;
	page_t*		page;
	btr_cur_t	father_cursor;
	mem_heap_t*	heap;
	ulint*		offsets;
	ulint		nth_rec = 0; /* remove bogus warning */
	DBUG_ENTER("btr_compress");

	block = btr_cur_get_block(cursor);
	page = btr_cur_get_page(cursor);
	index = btr_cur_get_index(cursor);

	btr_assert_not_corrupted(block, index);

	ut_ad(mtr_memo_contains(mtr, dict_index_get_lock(index),
				MTR_MEMO_X_LOCK));
	ut_ad(mtr_memo_contains(mtr, block, MTR_MEMO_PAGE_X_FIX));
	space = dict_index_get_space(index);
	zip_size = dict_table_zip_size(index->table);

	MONITOR_INC(MONITOR_INDEX_MERGE_ATTEMPTS);

	left_page_no = btr_page_get_prev(page, mtr);
	right_page_no = btr_page_get_next(page, mtr);

#ifdef UNIV_DEBUG
	if (!page_is_leaf(page) && left_page_no == FIL_NULL) {
		ut_a(REC_INFO_MIN_REC_FLAG & rec_get_info_bits(
			page_rec_get_next(page_get_infimum_rec(page)),
			page_is_comp(page)));
	}
#endif /* UNIV_DEBUG */

	heap = mem_heap_create(100);
	offsets = btr_page_get_father_block(NULL, heap, index, block, mtr,
					    &father_cursor);

	if (adjust) {
		nth_rec = page_rec_get_n_recs_before(btr_cur_get_rec(cursor));
		ut_ad(nth_rec > 0);
	}

	if (left_page_no == FIL_NULL && right_page_no == FIL_NULL) {
		/* The page is the only one on the level, lift the records
		to the father */

		merge_block = btr_lift_page_up(index, block, mtr);
		goto func_exit;
	}

	/* Decide the page to which we try to merge and which will inherit
	the locks */

	is_left = btr_can_merge_with_page(cursor, left_page_no,
					  &merge_block, mtr);

	DBUG_EXECUTE_IF("ib_always_merge_right", is_left = FALSE;);

	if(!is_left
	   && !btr_can_merge_with_page(cursor, right_page_no, &merge_block,
				       mtr)) {
		goto err_exit;
	}

	merge_page = buf_block_get_frame(merge_block);

#ifdef UNIV_BTR_DEBUG
	if (is_left) {
                ut_a(btr_page_get_next(merge_page, mtr)
                     == buf_block_get_page_no(block));
	} else {
               ut_a(btr_page_get_prev(merge_page, mtr)
                     == buf_block_get_page_no(block));
	}
#endif /* UNIV_BTR_DEBUG */

	ut_ad(page_validate(merge_page, index));

	merge_page_zip = buf_block_get_page_zip(merge_block);
#ifdef UNIV_ZIP_DEBUG
	if (merge_page_zip) {
		const page_zip_des_t*	page_zip
			= buf_block_get_page_zip(block);
		ut_a(page_zip);
		ut_a(page_zip_validate(merge_page_zip, merge_page, index));
		ut_a(page_zip_validate(page_zip, page, index));
	}
#endif /* UNIV_ZIP_DEBUG */

	/* Move records to the merge page */
	if (is_left) {
		rec_t*	orig_pred = page_copy_rec_list_start(
			merge_block, block, page_get_supremum_rec(page),
			index, mtr);

		if (!orig_pred) {
			goto err_exit;
		}

		btr_search_drop_page_hash_index(block);

		/* Remove the page from the level list */
		btr_level_list_remove(space, zip_size, page, index, mtr);

		btr_node_ptr_delete(index, block, mtr);
		lock_update_merge_left(merge_block, orig_pred, block);

		if (adjust) {
			nth_rec += page_rec_get_n_recs_before(orig_pred);
		}
	} else {
		rec_t*		orig_succ;
		ibool		compressed;
		dberr_t		err;
		btr_cur_t	cursor2;
					/* father cursor pointing to node ptr
					of the right sibling */
#ifdef UNIV_BTR_DEBUG
		byte		fil_page_prev[4];
#endif /* UNIV_BTR_DEBUG */

		btr_page_get_father(index, merge_block, mtr, &cursor2);

		if (merge_page_zip && left_page_no == FIL_NULL) {

			/* The function page_zip_compress(), which will be
			invoked by page_copy_rec_list_end() below,
			requires that FIL_PAGE_PREV be FIL_NULL.
			Clear the field, but prepare to restore it. */
#ifdef UNIV_BTR_DEBUG
			memcpy(fil_page_prev, merge_page + FIL_PAGE_PREV, 4);
#endif /* UNIV_BTR_DEBUG */
#if FIL_NULL != 0xffffffff
# error "FIL_NULL != 0xffffffff"
#endif
			memset(merge_page + FIL_PAGE_PREV, 0xff, 4);
		}

		orig_succ = page_copy_rec_list_end(merge_block, block,
						   page_get_infimum_rec(page),
						   cursor->index, mtr);

		if (!orig_succ) {
			ut_a(merge_page_zip);
#ifdef UNIV_BTR_DEBUG
			if (left_page_no == FIL_NULL) {
				/* FIL_PAGE_PREV was restored from
				merge_page_zip. */
				ut_a(!memcmp(fil_page_prev,
					     merge_page + FIL_PAGE_PREV, 4));
			}
#endif /* UNIV_BTR_DEBUG */
			goto err_exit;
		}

		btr_search_drop_page_hash_index(block);

#ifdef UNIV_BTR_DEBUG
		if (merge_page_zip && left_page_no == FIL_NULL) {

			/* Restore FIL_PAGE_PREV in order to avoid an assertion
			failure in btr_level_list_remove(), which will set
			the field again to FIL_NULL.  Even though this makes
			merge_page and merge_page_zip inconsistent for a
			split second, it is harmless, because the pages
			are X-latched. */
			memcpy(merge_page + FIL_PAGE_PREV, fil_page_prev, 4);
		}
#endif /* UNIV_BTR_DEBUG */

		/* Remove the page from the level list */
		btr_level_list_remove(space, zip_size, page, index, mtr);

		/* Replace the address of the old child node (= page) with the
		address of the merge page to the right */
		btr_node_ptr_set_child_page_no(
			btr_cur_get_rec(&father_cursor),
			btr_cur_get_page_zip(&father_cursor),
			offsets, right_page_no, mtr);

		compressed = btr_cur_pessimistic_delete(&err, TRUE, &cursor2,
							BTR_CREATE_FLAG,
							RB_NONE, mtr);
		ut_a(err == DB_SUCCESS);

		if (!compressed) {
			btr_cur_compress_if_useful(&cursor2, FALSE, mtr);
		}

		lock_update_merge_right(merge_block, orig_succ, block);
	}

	btr_blob_dbg_remove(page, index, "btr_compress");

	if (!dict_index_is_clust(index) && page_is_leaf(merge_page)) {
		/* Update the free bits of the B-tree page in the
		insert buffer bitmap.  This has to be done in a
		separate mini-transaction that is committed before the
		main mini-transaction.  We cannot update the insert
		buffer bitmap in this mini-transaction, because
		btr_compress() can be invoked recursively without
		committing the mini-transaction in between.  Since
		insert buffer bitmap pages have a lower rank than
		B-tree pages, we must not access other pages in the
		same mini-transaction after accessing an insert buffer
		bitmap page. */

		/* The free bits in the insert buffer bitmap must
		never exceed the free space on a page.  It is safe to
		decrement or reset the bits in the bitmap in a
		mini-transaction that is committed before the
		mini-transaction that affects the free space. */

		/* It is unsafe to increment the bits in a separately
		committed mini-transaction, because in crash recovery,
		the free bits could momentarily be set too high. */

		if (zip_size) {
			/* Because the free bits may be incremented
			and we cannot update the insert buffer bitmap
			in the same mini-transaction, the only safe
			thing we can do here is the pessimistic
			approach: reset the free bits. */
			ibuf_reset_free_bits(merge_block);
		} else {
			/* On uncompressed pages, the free bits will
			never increase here.  Thus, it is safe to
			write the bits accurately in a separate
			mini-transaction. */
			ibuf_update_free_bits_if_full(merge_block,
						      UNIV_PAGE_SIZE,
						      ULINT_UNDEFINED);
		}
	}

	ut_ad(page_validate(merge_page, index));
#ifdef UNIV_ZIP_DEBUG
	ut_a(!merge_page_zip || page_zip_validate(merge_page_zip, merge_page,
						  index));
#endif /* UNIV_ZIP_DEBUG */

	/* Free the file page */
	btr_page_free(index, block, mtr);

	ut_ad(btr_check_node_ptr(index, merge_block, mtr));
func_exit:
	mem_heap_free(heap);

	if (adjust) {
		ut_ad(nth_rec > 0);
		btr_cur_position(
			index,
			page_rec_get_nth(merge_block->frame, nth_rec),
			merge_block, cursor);
	}

	MONITOR_INC(MONITOR_INDEX_MERGE_SUCCESSFUL);

	DBUG_RETURN(TRUE);

err_exit:
	/* We play it safe and reset the free bits. */
	if (zip_size
	    && merge_page
	    && page_is_leaf(merge_page)
	    && !dict_index_is_clust(index)) {
		ibuf_reset_free_bits(merge_block);
	}

	mem_heap_free(heap);
	DBUG_RETURN(FALSE);
}
```
### btr_can_merge_with_page() in btr_compress()

```bash
/**************************************************************//**
Checks if the page in the cursor can be merged with given page.
If necessary, re-organize the merge_page.
@return	TRUE if possible to merge. */
UNIV_INTERN
ibool
btr_can_merge_with_page(
/*====================*/
	btr_cur_t*	cursor,		/*!< in: cursor on the page to merge */
	ulint		page_no,	/*!< in: a sibling page */
	buf_block_t**	merge_block,	/*!< out: the merge block */
	mtr_t*		mtr)		/*!< in: mini-transaction */
{
	dict_index_t*	index;
	page_t*		page;
	ulint		space;
	ulint		zip_size;
	ulint		n_recs;
	ulint		data_size;
        ulint           max_ins_size_reorg;
	ulint		max_ins_size;
	buf_block_t*	mblock;
	page_t*		mpage;
	DBUG_ENTER("btr_can_merge_with_page");

	if (page_no == FIL_NULL) {
		goto error;
	}

	index = btr_cur_get_index(cursor);
	page  = btr_cur_get_page(cursor);
	space = dict_index_get_space(index);
        zip_size = dict_table_zip_size(index->table);

	mblock = btr_block_get(space, zip_size, page_no, RW_X_LATCH, index,
			       mtr);
	mpage = buf_block_get_frame(mblock);

        n_recs = page_get_n_recs(page);
        data_size = page_get_data_size(page);

        max_ins_size_reorg = page_get_max_insert_size_after_reorganize(
                mpage, n_recs);

	if (data_size > max_ins_size_reorg) {
		goto error;
	}

	/* If compression padding tells us that merging will result in
	too packed up page i.e.: which is likely to cause compression
	failure then don't merge the pages. */
	if (zip_size && page_is_leaf(mpage)
	    && (page_get_data_size(mpage) + data_size
		>= dict_index_zip_pad_optimal_page_size(index))) {

		goto error;
	}


	max_ins_size = page_get_max_insert_size(mpage, n_recs);

	if (data_size > max_ins_size) {

		/* We have to reorganize mpage */

		if (!btr_page_reorganize_block(
			    false, page_zip_level, mblock, index, mtr)) {

			goto error;
		}

		max_ins_size = page_get_max_insert_size(mpage, n_recs);

		ut_ad(page_validate(mpage, index));
		ut_ad(max_ins_size == max_ins_size_reorg);

		if (data_size > max_ins_size) {

			/* Add fault tolerance, though this should
			never happen */

			goto error;
		}
	}

	*merge_block = mblock;
	DBUG_RETURN(TRUE);

error:
	*merge_block = NULL;
	DBUG_RETURN(FALSE);
}

#endif /* !UNIV_HOTBACKUP */

```

### btr_can_merge_with_page()

```bash
/**************************************************************//**
Checks if the page in the cursor can be merged with given page.
If necessary, re-organize the merge_page.
@return	TRUE if possible to merge. */
UNIV_INTERN
ibool
btr_can_merge_with_page(
/*====================*/
	btr_cur_t*	cursor,		/*!< in: cursor on the page to merge */
	ulint		page_no,	/*!< in: a sibling page */
	buf_block_t**	merge_block,	/*!< out: the merge block */
	mtr_t*		mtr)		/*!< in: mini-transaction */
{
	dict_index_t*	index;
	page_t*		page;
	ulint		space;
	ulint		zip_size;
	ulint		n_recs;
	ulint		data_size;
    ulint           max_ins_size_reorg;
	ulint		max_ins_size;
	buf_block_t*	mblock;
	page_t*		mpage;
	DBUG_ENTER("btr_can_merge_with_page");

	if (page_no == FIL_NULL) {
		goto error;
	}

	index = btr_cur_get_index(cursor);
	page  = btr_cur_get_page(cursor);
	space = dict_index_get_space(index);
    zip_size = dict_table_zip_size(index->table);

	mblock = btr_block_get(space, zip_size, page_no, RW_X_LATCH, index,
			       mtr);
	mpage = buf_block_get_frame(mblock);

        n_recs = page_get_n_recs(page);
        data_size = page_get_data_size(page);

        max_ins_size_reorg = page_get_max_insert_size_after_reorganize(
                mpage, n_recs);

	if (data_size > max_ins_size_reorg) {
		goto error;
	}

	/* If compression padding tells us that merging will result in
	too packed up page i.e.: which is likely to cause compression
	failure then don't merge the pages. */
	if (zip_size && page_is_leaf(mpage)
	    && (page_get_data_size(mpage) + data_size
		>= dict_index_zip_pad_optimal_page_size(index))) {

		goto error;
	}


	max_ins_size = page_get_max_insert_size(mpage, n_recs);

	if (data_size > max_ins_size) {

		/* We have to reorganize mpage */

		if (!btr_page_reorganize_block(
			    false, page_zip_level, mblock, index, mtr)) {

			goto error;
		}

		max_ins_size = page_get_max_insert_size(mpage, n_recs);

		ut_ad(page_validate(mpage, index));
		ut_ad(max_ins_size == max_ins_size_reorg);

		if (data_size > max_ins_size) {

			/* Add fault tolerance, though this should
			never happen */

			goto error;
		}
	}

	*merge_block = mblock;
	DBUG_RETURN(TRUE);

error:
	*merge_block = NULL;
	DBUG_RETURN(FALSE);
}
```
# Reference
https://www.percona.com/blog/2017/04/10/innodb-page-merging-and-page-splitting/
