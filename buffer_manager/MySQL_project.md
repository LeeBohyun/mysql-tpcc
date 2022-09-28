# Project 1 Assignment: Finding the ideal LRU_scan_depth

## UPATED INFO (2022.09.28)
- use the following format for the report file name.: **studentid_name_PA1.pdf**
- you don't have to include **hit ratio** for this project
- buf_LRU_free_from_common_LRU_list() -> buf_LRU_free_from_unzip_LRU_list() buf_LRU_free_from_common_LRU_list()

## Implications of ```innodb_lru_scan_depth```
- How does ```innodb_lru_scan_depth``` affect the operation method of buffer manager?
- Hint: Use grep command to find the location of ```srv_LRU_scan_depth``` in ```mysql-5.7.33```.


### ```srv_LRU_scan_depth``` in ```buf0lru.cc```

- In ```buf_LRU_get_free_block()```,  ```buf_LRU_scan_and_free_block(buf_pool, n_iterations > 0)``` is called.
```bash
if (buf_pool->try_LRU_scan || n_iterations > 0) {
		/* If no block was in the free list, search from the
		end of the LRU list and try to free a block there.
		If we are doing for the first time we'll scan only
		tail of the LRU list otherwise we scan the whole LRU
		list. */
		freed = buf_LRU_scan_and_free_block(buf_pool, n_iterations > 0);
	}

```

- In ```buf_LRU_scan_and_free_block(buf_pool, n_iterations > 0)```,  ```buf_LRU_free_from_common_LRU_list()``` is called.

```bash
UNIV_INTERN
ibool
buf_LRU_scan_and_free_block(
/*========================*/
	buf_pool_t*	buf_pool,	/*!< in: buffer pool instance */
	ibool		scan_all)	/*!< in: scan whole LRU list
					if TRUE, otherwise scan only
					'old' blocks. */
{
	ut_ad(buf_pool_mutex_own(buf_pool));

	return(buf_LRU_free_from_unzip_LRU_list(buf_pool, scan_all)
	       || buf_LRU_free_from_common_LRU_list(
			buf_pool, scan_all));
}

```

- In ```buf_LRU_free_from_unzip_LRU_list()```,  look how ```srv_LRU_scan_depth``` is applied.
```bashrc
UNIV_INLINE
ibool
static
bool
buf_LRU_free_from_unzip_LRU_list(
/*=============================*/
	buf_pool_t*	buf_pool,	/*!< in: buffer pool instance */
	bool		scan_all)	/*!< in: scan whole LRU list
					if true, otherwise scan only
					srv_LRU_scan_depth / 2 blocks. */
{
	ut_ad(buf_pool_mutex_own(buf_pool));

	if (!buf_LRU_evict_from_unzip_LRU(buf_pool)) {
		return(false);
	}

	ulint	scanned = 0;
	bool	freed = false;

	for (buf_block_t* block = UT_LIST_GET_LAST(buf_pool->unzip_LRU);
	     block != NULL
	     && !freed
	     && (scan_all || scanned < srv_LRU_scan_depth);
	     ++scanned) {

		buf_block_t*	prev_block;

		prev_block = UT_LIST_GET_PREV(unzip_LRU, block);

		ut_ad(buf_block_get_state(block) == BUF_BLOCK_FILE_PAGE);
		ut_ad(block->in_unzip_LRU_list);
		ut_ad(block->page.in_LRU_list);

		freed = buf_LRU_free_page(&block->page, false);

		block = prev_block;
	}

	if (scanned) {
		MONITOR_INC_VALUE_CUMULATIVE(
			MONITOR_LRU_UNZIP_SEARCH_SCANNED,
			MONITOR_LRU_UNZIP_SEARCH_SCANNED_NUM_CALL,
			MONITOR_LRU_UNZIP_SEARCH_SCANNED_PER_CALL,
			scanned);
	}

	return(freed);
}

static
bool
buf_LRU_free_from_common_LRU_list(
/*==============================*/
	buf_pool_t*	buf_pool,	/*!< in: buffer pool instance */
	bool		scan_all)	/*!< in: scan whole LRU list
					if true, otherwise scan only
					up to BUF_LRU_SEARCH_SCAN_THRESHOLD */
{
	ut_ad(buf_pool_mutex_own(buf_pool));

	ulint		scanned = 0;
	bool		freed = false;

	for (buf_page_t* bpage = buf_pool->lru_scan_itr.start();
	     bpage != NULL
	     && !freed
	     && (scan_all || scanned < BUF_LRU_SEARCH_SCAN_THRESHOLD);
	     ++scanned, bpage = buf_pool->lru_scan_itr.get()) {

		buf_page_t*	prev = UT_LIST_GET_PREV(LRU, bpage);
		BPageMutex*	mutex = buf_page_get_mutex(bpage);

		buf_pool->lru_scan_itr.set(prev);

		mutex_enter(mutex);

		ut_ad(buf_page_in_file(bpage));
		ut_ad(bpage->in_LRU_list);

		unsigned	accessed = buf_page_is_accessed(bpage);

		if (buf_flush_ready_for_replace(bpage)) {
			mutex_exit(mutex);
			freed = buf_LRU_free_page(bpage, true);
		} else {
			mutex_exit(mutex);
		}

		if (freed && !accessed) {
			/* Keep track of pages that are evicted without
			ever being accessed. This gives us a measure of
			the effectiveness of readahead */
			++buf_pool->stat.n_ra_pages_evicted;
		}

		ut_ad(buf_pool_mutex_own(buf_pool));
		ut_ad(!mutex_own(mutex));
	}

	if (scanned) {
		MONITOR_INC_VALUE_CUMULATIVE(
			MONITOR_LRU_SEARCH_SCANNED,
			MONITOR_LRU_SEARCH_SCANNED_NUM_CALL,
			MONITOR_LRU_SEARCH_SCANNED_PER_CALL,
			scanned);
	}

	return(freed);
}
```


### ```srv_LRU_scan_depth``` in ```buf0flu.cc```
- ```buf_do_LRU_batch()``` is called by page cleaner thread (```pc_flush_slot()```).

- In ```buf_do_LRU_batch()```, ```buf_flush_LRU_list_batch()``` is called.
```bashrc
static
ulint
buf_do_LRU_batch(
/*=============*/
	buf_pool_t*	buf_pool,	/*!< in: buffer pool instance */
	ulint		max)		/*!< in: desired number of
					blocks in the free_list */
{
	ulint	count = 0;

	if (buf_LRU_evict_from_unzip_LRU(buf_pool)) {
		count += buf_free_from_unzip_LRU_list_batch(buf_pool, max);
	}

	if (max > count) {
		count += buf_flush_LRU_list_batch(buf_pool, max - count);
	}

	return(count);
}

```

- See how ```srv_lru_scan_depth``` works in  ```buf_flush_LRU_list_batch()```.
```bashrc
static
ulint
buf_flush_LRU_list_batch(
/*=====================*/
	buf_pool_t*	buf_pool,	/*!< in: buffer pool instance */
	ulint		max)		/*!< in: desired number of
					blocks in the free_list */
{
	buf_page_t*	bpage;
	ulint		scanned = 0;
	ulint		evict_count = 0;
	ulint		count = 0;
	ulint		free_len = UT_LIST_GET_LEN(buf_pool->free);
	ulint		lru_len = UT_LIST_GET_LEN(buf_pool->LRU);
	ulint		withdraw_depth = 0;

	ut_ad(buf_pool_mutex_own(buf_pool));

	if (buf_pool->curr_size < buf_pool->old_size
	    && buf_pool->withdraw_target > 0) {
		withdraw_depth = buf_pool->withdraw_target
				 - UT_LIST_GET_LEN(buf_pool->withdraw);
	}

	for (bpage = UT_LIST_GET_LAST(buf_pool->LRU);
	     bpage != NULL && count + evict_count < max
	     && free_len < srv_LRU_scan_depth + withdraw_depth
	     && lru_len > BUF_LRU_MIN_LEN;
	     ++scanned,
	     bpage = buf_pool->lru_hp.get()) {

		buf_page_t* prev = UT_LIST_GET_PREV(LRU, bpage);
		buf_pool->lru_hp.set(prev);

		BPageMutex*	block_mutex = buf_page_get_mutex(bpage);

		mutex_enter(block_mutex);

		if (buf_flush_ready_for_replace(bpage)) {
			/* block is ready for eviction i.e., it is
			clean and is not IO-fixed or buffer fixed. */
			mutex_exit(block_mutex);
			if (buf_LRU_free_page(bpage, true)) {
				++evict_count;
			}
		} else if (buf_flush_ready_for_flush(bpage, BUF_FLUSH_LRU)) {
			/* Block is ready for flush. Dispatch an IO
			request. The IO helper thread will put it on
			free list in IO completion routine. */
			mutex_exit(block_mutex);
			buf_flush_page_and_try_neighbors(
				bpage, BUF_FLUSH_LRU, max, &count);
		} else {
			/* Can't evict or dispatch this block. Go to
			previous. */
			ut_ad(buf_pool->lru_hp.is_hp(prev));
			mutex_exit(block_mutex);
		}

		ut_ad(!mutex_own(block_mutex));
		ut_ad(buf_pool_mutex_own(buf_pool));

		free_len = UT_LIST_GET_LEN(buf_pool->free);
		lru_len = UT_LIST_GET_LEN(buf_pool->LRU);
	}

	buf_pool->lru_hp.set(NULL);

	/* We keep track of all flushes happening as part of LRU
	flush. When estimating the desired rate at which flush_list
	should be flushed, we factor in this value. */
	buf_lru_flush_page_count += count;

	ut_ad(buf_pool_mutex_own(buf_pool));

	if (evict_count) {
		MONITOR_INC_VALUE_CUMULATIVE(
			MONITOR_LRU_BATCH_EVICT_TOTAL_PAGE,
			MONITOR_LRU_BATCH_EVICT_COUNT,
			MONITOR_LRU_BATCH_EVICT_PAGES,
			evict_count);
	}

	if (scanned) {
		MONITOR_INC_VALUE_CUMULATIVE(
			MONITOR_LRU_BATCH_SCANNED,
			MONITOR_LRU_BATCH_SCANNED_NUM_CALL,
			MONITOR_LRU_BATCH_SCANNED_PER_CALL,
			scanned);
	}

	return(count);
}
```

## Experiment Guide
### Configure LRU scan depth
Modify ```my.cnf``` file and vary ```innodb_lru_scan_depth``` configuration variable : 128 256 512 1024 2048 4096 8192. Refer to the [mysql document](https://dev.mysql.com/doc/refman/5.7/en/innodb-parameters.html#sysvar_innodb_lru_scan_depth) for more information.

### Run TPC-C benchmark
Run TPC-C benchmark with the same configuration  with [week 4](https://github.com/LeeBohyun/mysql-tpcc/blob/master/buffer_manager/buffer_miss_scenario_monitoring.md) while monitoring IOPS and CPU utilization with ```iostat``` at the same time. Also, check the hit ratio and the ratio of step 1, 2, and 3 after benchmarking.


## Report Submission Guide

- The report should include the following contents.
  - Summarize & analyze the ```innodb_lru_scan_depth```-related mysql source code (``buf0lru.cc``, ``buf0flu.cc``)
  - How TpmC and read write IOPS changes when varying ```innodb_lru_scan_depth```:128 256 512 1024 2048 4096 8192.  (In a graph or a table)
  - How the ratio of Step 1, 2, 3 of the victim selection policy changes when varying ```innodb_lru_scan_depth```
  - The TpmC gap between the default ```innodb_lru_scan_depth (1024)``` and the ideal ```innodb_lru_scan_depth```
  
- The report should answer to the following questions.
  - Question 1) How does ```innodb_lru_scan_depth``` affect the operation method of buffer manager? 
  - Question 2) Among values of 128, 256, 512, 1024, 2048, 4096, and 8192, which value is the ideal ```innodb_lru_scan_depth```? Explain the reason why in terms of transaction throughput.

- Refer to the report submission guide for the format.
