# MySQL/InnoDB B+Tree Split Algorithm

## Split Function

### btr_cur_pessimistic_insert()
- btr0cur.cc btr_cur_pessimistic_insert() : calls btr_page_split_and_insert()
```bash
/*************************************************************//**
Performs an insert on a page of an index tree. It is assumed that mtr
holds an x-latch on the tree and on the cursor page. If the insert is
made on the leaf level, to avoid deadlocks, mtr must also own x-latches
to brothers of page, if those brothers exist.
@return	DB_SUCCESS or error number */
UNIV_INTERN
dberr_t
btr_cur_pessimistic_insert(
/*=======================*/
	ulint		flags,	/*!< in: undo logging and locking flags: if not
				zero, the parameter thr should be
				specified; if no undo logging is specified,
				then the caller must have reserved enough
				free extents in the file space so that the
				insertion will certainly succeed */
	btr_cur_t*	cursor,	/*!< in: cursor after which to insert;
				cursor stays valid */
	ulint**		offsets,/*!< out: offsets on *rec */
	mem_heap_t**	heap,	/*!< in/out: pointer to memory heap
				that can be emptied, or NULL */
	dtuple_t*	entry,	/*!< in/out: entry to insert */
	rec_t**		rec,	/*!< out: pointer to inserted record if
				succeed */
	big_rec_t**	big_rec,/*!< out: big rec vector whose fields have to
				be stored externally by the caller, or
				NULL */
	ulint		n_ext,	/*!< in: number of externally stored columns */
	que_thr_t*	thr,	/*!< in: query thread or NULL */
	mtr_t*		mtr)	/*!< in/out: mini-transaction */
{
	dict_index_t*	index		= cursor->index;
	ulint		zip_size	= dict_table_zip_size(index->table);
	big_rec_t*	big_rec_vec	= NULL;
	dberr_t		err;
	ibool		inherit = FALSE;
	ibool		success;
	ulint		n_reserved	= 0;

	ut_ad(dtuple_check_typed(entry));

	*big_rec = NULL;

	ut_ad(mtr_memo_contains(mtr,
				dict_index_get_lock(btr_cur_get_index(cursor)),
				MTR_MEMO_X_LOCK));
	ut_ad(mtr_memo_contains(mtr, btr_cur_get_block(cursor),
				MTR_MEMO_PAGE_X_FIX));
	ut_ad(!dict_index_is_online_ddl(index)
	      || dict_index_is_clust(index)
	      || (flags & BTR_CREATE_FLAG));

	cursor->flag = BTR_CUR_BINARY;

	/* Check locks and write to undo log, if specified */

	err = btr_cur_ins_lock_and_undo(flags, cursor, entry,
					thr, mtr, &inherit);

	if (err != DB_SUCCESS) {

		return(err);
	}

	if (!(flags & BTR_NO_UNDO_LOG_FLAG)) {
		/* First reserve enough free space for the file segments
		of the index tree, so that the insert will not fail because
		of lack of space */

		ulint	n_extents = cursor->tree_height / 16 + 3;

		success = fsp_reserve_free_extents(&n_reserved, index->space,
						   n_extents, FSP_NORMAL, mtr);
		if (!success) {
			return(DB_OUT_OF_FILE_SPACE);
		}
	}

	if (page_zip_rec_needs_ext(rec_get_converted_size(index, entry, n_ext),
				   dict_table_is_comp(index->table),
				   dtuple_get_n_fields(entry),
				   zip_size)) {
		/* The record is so big that we have to store some fields
		externally on separate database pages */

		if (UNIV_LIKELY_NULL(big_rec_vec)) {
			/* This should never happen, but we handle
			the situation in a robust manner. */
			ut_ad(0);
			dtuple_convert_back_big_rec(index, entry, big_rec_vec);
		}

		big_rec_vec = dtuple_convert_big_rec(index, entry, &n_ext);

		if (big_rec_vec == NULL) {

			if (n_reserved > 0) {
				fil_space_release_free_extents(index->space,
							       n_reserved);
			}
			return(DB_TOO_BIG_RECORD);
		}
	}

	if (dict_index_get_page(index)
	    == buf_block_get_page_no(btr_cur_get_block(cursor))) {

		/* The page is the root page */
		*rec = btr_root_raise_and_insert(
			flags, cursor, offsets, heap, entry, n_ext, mtr);
	} else {
		*rec = btr_page_split_and_insert(
			flags, cursor, offsets, heap, entry, n_ext, mtr);
	}

	ut_ad(page_rec_get_next(btr_cur_get_rec(cursor)) == *rec);

	if (!(flags & BTR_NO_LOCKING_FLAG)) {
		/* The cursor might be moved to the other page,
		and the max trx id field should be updated after
		the cursor was fixed. */
		if (!dict_index_is_clust(index)) {
			page_update_max_trx_id(
				btr_cur_get_block(cursor),
				btr_cur_get_page_zip(cursor),
				thr_get_trx(thr)->id, mtr);
		}
		if (!page_rec_is_infimum(btr_cur_get_rec(cursor))
		    || btr_page_get_prev(
			buf_block_get_frame(
				btr_cur_get_block(cursor)), mtr)
		       == FIL_NULL) {
			/* split and inserted need to call
			lock_update_insert() always. */
			inherit = TRUE;
		}
	}

#ifdef BTR_CUR_ADAPT
	btr_search_update_hash_on_insert(cursor);
#endif
	if (inherit && !(flags & BTR_NO_LOCKING_FLAG)) {

		lock_update_insert(btr_cur_get_block(cursor), *rec);
	}

	if (n_reserved > 0) {
		fil_space_release_free_extents(index->space, n_reserved);
	}

	*big_rec = big_rec_vec;

	return(DB_SUCCESS);
}
```

### btr_page_split_and_insert()
- mysql-5.6.26/storage/innobase/btr/btr0btr.cc : ``btr_page_split_and_insert()``

```bash
/*************************************************************//**
Splits an index page to halves and inserts the tuple. It is assumed
that mtr holds an x-latch to the index tree. NOTE: the tree x-latch is
released within this function! NOTE that the operation of this
function must always succeed, we cannot reverse it: therefore enough
free disk space (2 pages) must be guaranteed to be available before
this function is called.

@return inserted record */
UNIV_INTERN
rec_t*
btr_page_split_and_insert(
/*======================*/
	ulint		flags,	/*!< in: undo logging and locking flags */
	btr_cur_t*	cursor,	/*!< in: cursor at which to insert; when the
				function returns, the cursor is positioned
				on the predecessor of the inserted record */
	ulint**		offsets,/*!< out: offsets on inserted record */
	mem_heap_t**	heap,	/*!< in/out: pointer to memory heap, or NULL */
	const dtuple_t*	tuple,	/*!< in: tuple to insert */
	ulint		n_ext,	/*!< in: number of externally stored columns */
	mtr_t*		mtr)	/*!< in: mtr */
	
```
0. try to insert to the next page if possible before split
1. Decide the split record
- ``split_rec == NULL`` means that the tuple to be inserted should be the first record on the upper half-page
	-  ``if (btr_page_get_split_rec_to_right(cursor, &split_rec))`` : split at the current record near supremum (sequential insert)
	- ``else if (btr_page_get_split_rec_to_left(cursor, &split_rec))`` : split at current record near infrimum
	- ``else (page_get_middle_rec(page))``: split at the middle record 
2. Allocate a new page to the index
3. Calculate the first record on the upper half-page, and the first record (move_limit) on original page which ends up on the upper half
4. Do first the modifications in the tree structure
5. Move then the records to the new page 
6. The split and the tree modification is now completed. Decide the page where the tuple should be inserted
7. Reposition the cursor for insert and try insertion
8. If insert did not fit, try page reorganization. For compressed pages, page_cur_tuple_insert() will have attempted this already

## Function Call in Steps
1. row insert(row0ins.cc) : ``row_ins_clust_index_entry_low()`` ``row_ins_sec_index_entry_low()`` 
2. for non-leaf split : ``btr_insert_on_non_leaf_level_func()``
3. optimistic insert(btr0cur.cc) : ``btr_cur_optimistic_insert()`` 
4. pessimistic insert(btr0cur.cc): `` btr_cur_pessimistic_insert()``
  - if root: ``btr_root_raise_and_insert()`` -> ``btr_page_split_and_insert()``
  - else: ``btr_page_split_and_insert()``
  
