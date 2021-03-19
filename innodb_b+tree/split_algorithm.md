# MySQL/InnoDB B+Tree Split Algorithm

## Split Function

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
  
