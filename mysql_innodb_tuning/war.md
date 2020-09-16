# WAR in InnoDB/MySQL

## Buffer Manager
In buffer pool, there are flusher(buf0flu.cc) and doublbewrite buffer(buf0dblwr.cc). Flusher works as dirty page writer and background flusher. Inside the buffer, there are lists of buffer blocks.
- **Free list**: contains free page franes to read currently non-present pages
- **LRU list**: contains all the blocks holding a file page 
-> holds flags wheter it is dirty or clean to decide which page to evict
- **Flush list**(least recently modified): contains the blocks holding file pages that have been modified in the memory but not on disk yet.

Flusher writes dirty pages to disk in background that had been buffered in a memory area. InnoDB has limited space in redo log and buffer pool. InnoDB flushes page continuously so that it can avoid synchronous I/O as many as possible, thus keeping reserved clean or free blocks that can be replaced without having to be flushed.  

## Page Cleaner Thread
Page cleaner thread handles all types of background flushing such as flushing pages from end of LRU list and flush list.  It wakes up once per second and sometimes user thread can also handle flusing. Multiple threads are available in MySQL5.7+.

## WAR
