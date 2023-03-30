# How to Measure Transaction Lock Waits in MySQL/InnoDB

## Overview
- Drilldown the transaction wait event

## Related MySQL Source Code

### Query Graphs
```bash
A query graph consists of nodes linked to each other in various ways. The
execution starts at que_run_threads() which takes a que_thr_t parameter.
que_thr_t contains two fields that control query graph execution: run_node
and prev_node. run_node is the next node to execute and prev_node is the
last node executed.

Each node has a pointer to a 'next' statement, i.e., its brother, and a
pointer to its parent node. The next pointer is NULL in the last statement
of a block.

Loop nodes contain a link to the first statement of the enclosed statement
list. While the loop runs, que_thr_step() checks if execution to the loop
node came from its parent or from one of the statement nodes in the loop. If
it came from the parent of the loop node it starts executing the first
statement node in the loop. If it came from one of the statement nodes in
the loop, then it checks if the statement node has another statement node
following it, and runs it if so.

To signify loop ending, the loop statements (see e.g. while_step()) set
que_thr_t->run_node to the loop node's parent node. This is noticed on the
next call of que_thr_step() and execution proceeds to the node pointed to by
the loop node's 'next' pointer.
```
- que_node_t*	node : Gets information of an SQL query graph node.
- que_thr_move_to_run_state(): moves a thread state to QUE_THR_RUNNING state.
- que0que.cc : que_thr_end_lock_wait()

### Lock
- lock_grant()
- lock_trx_has_rec_x_lock()
- thd_report_row_lock_wait()

### Transaction
- trx0trx.h: Transaction lock wait
- QUE_THR_LOCK_WAIT
- 
```bash
/*******************************************************************//**
Latching protocol for trx_lock_t::que_state.  trx_lock_t::que_state
captures the state of the query thread during the execution of a query.
This is different from a transaction state. The query state of a transaction
can be updated asynchronously by other threads.  The other threads can be
system threads, like the timeout monitor thread or user threads executing
other queries. Another thing to be mindful of is that there is a delay between
when a query thread is put into LOCK_WAIT state and before it actually starts
waiting.  Between these two events it is possible that the query thread is
granted the lock it was waiting for, which implies that the state can be changed
asynchronously.

All these operations take place within the context of locking. Therefore state
changes within the locking code must acquire both the lock mutex and the
trx->mutex when changing trx->lock.que_state to TRX_QUE_LOCK_WAIT or
trx->lock.wait_lock to non-NULL but when the lock wait ends it is sufficient
to only acquire the trx->mutex.
To query the state either of the mutexes is sufficient within the locking
code and no mutex is required when the query thread is no longer waiting. */

/** The locks and state of an active transaction. Protected by
lock_sys->mutex, trx->mutex or both. */
struct trx_lock_t {
	ulint		n_active_thrs;	/*!< number of active query threads */

	trx_que_t	que_state;	/*!< valid when trx->state
					== TRX_STATE_ACTIVE: TRX_QUE_RUNNING,
					TRX_QUE_LOCK_WAIT, ... */

	lock_t*		wait_lock;	/*!< if trx execution state is
					TRX_QUE_LOCK_WAIT, this points to
					the lock request, otherwise this is
					NULL; set to non-NULL when holding
					both trx->mutex and lock_sys->mutex;
					set to NULL when holding
					lock_sys->mutex; readers should
					hold lock_sys->mutex, except when
					they are holding trx->mutex and
					wait_lock==NULL */
	ib_uint64_t	deadlock_mark;	/*!< A mark field that is initialized
					to and checked against lock_mark_counter
					by lock_deadlock_recursive(). */
	bool		was_chosen_as_deadlock_victim;
					/*!< when the transaction decides to
					wait for a lock, it sets this to false;
					if another transaction chooses this
					transaction as a victim in deadlock
					resolution, it sets this to true.
					Protected by trx->mutex. */
	time_t		wait_started;	/*!< lock wait started at this time,
					protected only by lock_sys->mutex */

	que_thr_t*	wait_thr;	/*!< query thread belonging to this
					trx that is in QUE_THR_LOCK_WAIT
					state. For threads suspended in a
					lock wait, this is protected by
					lock_sys->mutex. Otherwise, this may
					only be modified by the thread that is
					serving the running transaction. */

	lock_pool_t	rec_pool;	/*!< Pre-allocated record locks */

	lock_pool_t	table_pool;	/*!< Pre-allocated table locks */

	ulint		rec_cached;	/*!< Next free rec lock in pool */

	ulint		table_cached;	/*!< Next free table lock in pool */

	mem_heap_t*	lock_heap;	/*!< memory heap for trx_locks;
					protected by lock_sys->mutex */

	trx_lock_list_t trx_locks;	/*!< locks requested by the transaction;
					insertions are protected by trx->mutex
					and lock_sys->mutex; removals are
					protected by lock_sys->mutex */

	lock_pool_t	table_locks;	/*!< All table locks requested by this
					transaction, including AUTOINC locks */

	bool		cancel;		/*!< true if the transaction is being
					rolled back either via deadlock
					detection or due to lock timeout. The
					caller has to acquire the trx_t::mutex
					in order to cancel the locks. In
					lock_trx_table_locks_remove() we
					check for this cancel of a transaction's
					locks and avoid reacquiring the trx
					mutex to prevent recursive deadlocks.
					Protected by both the lock sys mutex
					and the trx_t::mutex. */
	ulint		n_rec_locks;	/*!< number of rec locks in this trx */

	/** The transaction called ha_innobase::start_stmt() to
	lock a table. Most likely a temporary table. */
	bool		start_stmt;
};
```


### Transaction Summary Tables



## Reference
- https://dev.mysql.com/blog-archive/innodb-data-locking-part-1-introduction/
- https://dev.mysql.com/blog-archive/innodb-data-locking-part-2-locks/
- https://dev.mysql.com/doc/mysql-perfschema-excerpt/8.0/en/performance-schema-transaction-summary-tables.html
- https://dev.mysql.com/doc/mysql-perfschema-excerpt/5.7/en/performance-schema-table-handles-table.html
- https://dev.mysql.com/doc/mysql-perfschema-excerpt/5.7/en/performance-schema-table-lock-waits-summary-by-table-table.html
