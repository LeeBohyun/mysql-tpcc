# B+Tree Split Monitoring

`warning` Mysql version: mysql-5.6.26

- btr0btr.cc in /storage/innobase/btr/

```bash
##############added code /* lbh */ or /* mijin */ ... /* end */##############
UNIV_INTERN
rec_t*
btr_page_split_and_insert{
...
	/* mijin : page split monitoring */

	if (buf_block_get_space(block) == srv_ol_space_id) {
		ib_logf(IB_LOG_LEVEL_INFO, "Before Split (%lu): original =  %lu / %lu / %d / %lu / %lu / %s\n", rec_get_converted_size(cursor->index, tuple, n_ext), buf_block_get_page_no(block), page_get_n_recs(page), page_is_leaf(page), dict_index_is_clust(cursor->index), dict_index_is_unique(cursor->index), cursor->index->name);
}
	/* end */

	page_no = buf_block_get_page_no(block);

	/* 1. Decide the split record; split_rec == NULL means that the
	tuple to be inserted should be the first record on the upper
	half-page */
	insert_left = FALSE;

	if (n_iterations > 0) {
		direction = FSP_UP;
		hint_page_no = page_no + 1;
		split_rec = btr_page_get_split_rec(cursor, tuple, n_ext);
		/* lbh */
		if(buf_block_get_space(block) == srv_ol_space_id){
			ib_logf(IB_LOG_LEVEL_INFO, "btr_page_split_and_insert: n_iterations > 0: Split (%lu): original =  %lu / %lu / %d / %lu / %lu / %s\n", rec_get_converted_size(cursor->index, tuple, n_ext), buf_block_get_page_no(block), page_get_n_recs(page), page_is_leaf(page), dict_index_is_clust(cursor->index), dict_index_is_unique(cursor->index), cursor->index->name);
		/* end */}

		if (split_rec == NULL) {
			insert_left = btr_page_tuple_smaller(
				cursor, tuple, offsets, n_uniq, heap);
		}
	} else if (btr_page_get_split_rec_to_right(cursor, &split_rec)) {
		direction = FSP_UP;
		hint_page_no = page_no + 1;

		/* lbh */
		if(buf_block_get_space(block) == srv_ol_space_id){
			ib_logf(IB_LOG_LEVEL_INFO, "btr_page_split_and_insert: btr_page_get_split_rec_to_right: Split (%lu): original =  %lu / %lu / %d / %lu / %lu / %s",rec_get_converted_size(cursor->index, tuple, n_ext), buf_block_get_page_no(block), page_get_n_recs(page), page_is_leaf(page), dict_index_is_clust(cursor->index), dict_index_is_unique(cursor->index), cursor->index->name);
		/* end */}
	} else if (btr_page_get_split_rec_to_left(cursor, &split_rec)) {
		direction = FSP_DOWN;
		hint_page_no = page_no - 1;

		/* lbh */
		if(buf_block_get_space(block) == srv_ol_space_id){
			ib_logf(IB_LOG_LEVEL_INFO, "btr_page_split_and_insert: btr_page_get_split_rec_to_left: Split (%lu): original =  %lu / %lu / %d / %lu / %lu / %s\n",rec_get_converted_size(cursor->index, tuple, n_ext), buf_block_get_page_no(block), page_get_n_recs(page), page_is_leaf(page), dict_index_is_clust(cursor->index), dict_index_is_unique(cursor->index), cursor->index->name);
		/* end */}
		ut_ad(split_rec);
	} else {
		direction = FSP_UP;
		hint_page_no = page_no + 1;

		/* If there is only one record in the index page, we
		cannot split the node in the middle by default. We need
		to determine whether the new record will be inserted
		to the left or right. */

		if (page_get_n_recs(page) > 1) {
			/* lbh */
			if(buf_block_get_space(block) == srv_ol_space_id && page_is_leaf(page)){
				ib_logf(IB_LOG_LEVEL_INFO, "btr_page_split_and_insert: page_get_n_recs(page) > 1: Split (%lu): original =  %lu / %lu / %d / %lu / %lu / %s\n",rec_get_converted_size(cursor->index, tuple, n_ext), buf_block_get_page_no(block), page_get_n_recs(page), page_is_leaf(page), dict_index_is_clust(cursor->index), dict_index_is_unique(cursor->index), cursor->index->name);

				
				//last_rec = page_rec_get_prev(page_get_supremum_rec(page));
				//last_last_rec = page_rec_get_prev(last_rec);
				//split_rec = page_rec_get_prev(last_last_rec);
				
				split_rec = page_get_middle_rec(page);
			}/* end */else{
				split_rec = page_get_middle_rec(page);
			}
		} else if (btr_page_tuple_smaller(cursor, tuple,
						  offsets, n_uniq, heap)) {
			split_rec = page_rec_get_next(
				page_get_infimum_rec(page));
		} else {
			split_rec = NULL;
		}
	}

	/* 2. Allocate a new page to the index */
	new_block = btr_page_alloc(cursor->index, hint_page_no, direction,
				   btr_page_get_level(page, mtr), mtr, mtr);
	new_page = buf_block_get_frame(new_block);
	new_page_zip = buf_block_get_page_zip(new_block);
	btr_page_create(new_block, new_page_zip, cursor->index,
			btr_page_get_level(page, mtr), mtr);

	/* 3. Calculate the first record on the upper half-page, and the
	first record (move_limit) on original page which ends up on the
	upper half */

	if (split_rec) {
		first_rec = move_limit = split_rec;

		*offsets = rec_get_offsets(split_rec, cursor->index, *offsets,
					   n_uniq, heap);

		insert_left = cmp_dtuple_rec(tuple, split_rec, *offsets) < 0;

		if (!insert_left && new_page_zip && n_iterations > 0) {
			/* If a compressed page has already been split,
			avoid further splits by inserting the record
			to an empty page. */
			split_rec = NULL;
			goto insert_empty;
		}
	} else if (insert_left) {
		ut_a(n_iterations > 0);
		first_rec = page_rec_get_next(page_get_infimum_rec(page));
		move_limit = page_rec_get_next(btr_cur_get_rec(cursor));
	} else {
insert_empty:
		ut_ad(!split_rec);
		ut_ad(!insert_left);
		buf = (byte*) mem_alloc(rec_get_converted_size(cursor->index,
							       tuple, n_ext));

		first_rec = rec_convert_dtuple_to_rec(buf, cursor->index,
						      tuple, n_ext);
		move_limit = page_rec_get_next(btr_cur_get_rec(cursor));
	}

	/* 4. Do first the modifications in the tree structure */

	btr_attach_half_pages(flags, cursor->index, block,
			      first_rec, new_block, direction, mtr);

	/* If the split is made on the leaf level and the insert will fit
	on the appropriate half-page, we may release the tree x-latch.
	We can then move the records after releasing the tree latch,
	thus reducing the tree latch contention. */

	if (split_rec) {
		insert_will_fit = !new_page_zip
			&& btr_page_insert_fits(cursor, split_rec,
						offsets, tuple, n_ext, heap);
	} else {
		if (!insert_left) {
			mem_free(buf);
			buf = NULL;
		}

		insert_will_fit = !new_page_zip
			&& btr_page_insert_fits(cursor, NULL,
						offsets, tuple, n_ext, heap);
	}

	if (insert_will_fit && page_is_leaf(page)
	    && !dict_index_is_online_ddl(cursor->index)) {

		mtr_memo_release(mtr, dict_index_get_lock(cursor->index),
				 MTR_MEMO_X_LOCK);
	}

	/* 5. Move then the records to the new page */
	if (direction == FSP_DOWN) {
		/*		fputs("Split left\n", stderr); */

		if (0
#ifdef UNIV_ZIP_COPY
		    || page_zip
#endif /* UNIV_ZIP_COPY */
		    || !page_move_rec_list_start(new_block, block, move_limit,
						 cursor->index, mtr)) {
			/* For some reason, compressing new_page failed,
			even though it should contain fewer records than
			the original page.  Copy the page byte for byte
			and then delete the records from both pages
			as appropriate.  Deleting will always succeed. */
			ut_a(new_page_zip);

			page_zip_copy_recs(new_page_zip, new_page,
					   page_zip, page, cursor->index, mtr);
			page_delete_rec_list_end(move_limit - page + new_page,
						 new_block, cursor->index,
						 ULINT_UNDEFINED,
						 ULINT_UNDEFINED, mtr);

			/* Update the lock table and possible hash index. */

			lock_move_rec_list_start(
				new_block, block, move_limit,
				new_page + PAGE_NEW_INFIMUM);

			btr_search_move_or_delete_hash_entries(
				new_block, block, cursor->index);

			/* Delete the records from the source page. */

			page_delete_rec_list_start(move_limit, block,
						   cursor->index, mtr);
		}

		left_block = new_block;
		right_block = block;

		lock_update_split_left(right_block, left_block);
	} else {
		/*		fputs("Split right\n", stderr); */

		if (0
#ifdef UNIV_ZIP_COPY
		    || page_zip
#endif /* UNIV_ZIP_COPY */
		    || !page_move_rec_list_end(new_block, block, move_limit,
					       cursor->index, mtr)) {
			/* For some reason, compressing new_page failed,
			even though it should contain fewer records than
			the original page.  Copy the page byte for byte
			and then delete the records from both pages
			as appropriate.  Deleting will always succeed. */
			ut_a(new_page_zip);

			page_zip_copy_recs(new_page_zip, new_page,
					   page_zip, page, cursor->index, mtr);
			page_delete_rec_list_start(move_limit - page
						   + new_page, new_block,
						   cursor->index, mtr);

			/* Update the lock table and possible hash index. */

			lock_move_rec_list_end(new_block, block, move_limit);

			btr_search_move_or_delete_hash_entries(
				new_block, block, cursor->index);

			/* Delete the records from the source page. */

			page_delete_rec_list_end(move_limit, block,
						 cursor->index,
						 ULINT_UNDEFINED,
						 ULINT_UNDEFINED, mtr);
		}

		left_block = block;
		right_block = new_block;

		lock_update_split_right(right_block, left_block);
	}

#ifdef UNIV_ZIP_DEBUG
	if (page_zip) {
		ut_a(page_zip_validate(page_zip, page, cursor->index));
		ut_a(page_zip_validate(new_page_zip, new_page, cursor->index));
	}
#endif /* UNIV_ZIP_DEBUG */

	/* At this point, split_rec, move_limit and first_rec may point
	to garbage on the old page. */

	/* 6. The split and the tree modification is now completed. Decide the
	page where the tuple should be inserted */

	if (insert_left) {
		insert_block = left_block;
	} else {
		insert_block = right_block;
	}

	/* 7. Reposition the cursor for insert and try insertion */
	page_cursor = btr_cur_get_page_cur(cursor);

	page_cur_search(insert_block, cursor->index, tuple,
			PAGE_CUR_LE, page_cursor);

	rec = page_cur_tuple_insert(page_cursor, tuple, cursor->index,
				    offsets, heap, n_ext, mtr);

#ifdef UNIV_ZIP_DEBUG
	{
		page_t*		insert_page
			= buf_block_get_frame(insert_block);

		page_zip_des_t*	insert_page_zip
			= buf_block_get_page_zip(insert_block);

		ut_a(!insert_page_zip
		     || page_zip_validate(insert_page_zip, insert_page,
					  cursor->index));
	}
#endif /* UNIV_ZIP_DEBUG */

	if (rec != NULL) {

		goto func_exit;
	}

	/* 8. If insert did not fit, try page reorganization.
	For compressed pages, page_cur_tuple_insert() will have
	attempted this already. */

	if (page_cur_get_page_zip(page_cursor)
	    || !btr_page_reorganize(page_cursor, cursor->index, mtr)) {

		goto insert_failed;
	}

	rec = page_cur_tuple_insert(page_cursor, tuple, cursor->index,
				    offsets, heap, n_ext, mtr);

	if (rec == NULL) {
		/* The insert did not fit on the page: loop back to the
		start of the function for a new split */
insert_failed:
		/* We play safe and reset the free bits */
		if (!dict_index_is_clust(cursor->index)) {
			ibuf_reset_free_bits(new_block);
			ibuf_reset_free_bits(block);
		}

		/* fprintf(stderr, "Split second round %lu\n",
		page_get_page_no(page)); */
		n_iterations++;
		ut_ad(n_iterations < 2
		      || buf_block_get_page_zip(insert_block));
		ut_ad(!insert_will_fit);

		goto func_start;
	}

func_exit:
	/* Insert fit on the page: update the free bits for the
	left and right pages in the same mtr */

	if (!dict_index_is_clust(cursor->index) && page_is_leaf(page)) {
		ibuf_update_free_bits_for_two_pages_low(
			buf_block_get_zip_size(left_block),
			left_block, right_block, mtr);
	}

#if 0
	fprintf(stderr, "Split and insert done %lu %lu\n",
		buf_block_get_page_no(left_block),
		buf_block_get_page_no(right_block));
#endif
	/* mijin */
	if (buf_block_get_space(block) == srv_ol_space_id) {
		ib_logf(IB_LOG_LEVEL_INFO, "After Split (%lu): original =  %lu / %lu / %d, new =  %lu / %lu / %d\n", rec_get_converted_size(cursor->index, tuple, n_ext), (ulint)buf_block_get_page_no(block), page_get_n_recs(page), page_is_leaf(page), (ulint)buf_block_get_page_no(new_block), page_get_n_recs(new_page), page_is_leaf(new_page));
	}
	/* end */

...
}
```
