# Relation between InnoDB Redo Log Size and Performance

:warning: NOTIFICATION: Tuning Project based on MySQL-5.7.24 and tested by TPC-C benchmark 

## TPC-C Testing Result

| Option   |  TPS | READ/S | WRITE/S  | 
|:----------:|-------------|-------------|-------------|
|default| 16 | 988  | 414 | 
|log_size| 24 | 1104  | 743 | 
|page_size|  |    |   |
|non-split| 83 | 3450  | 2013 |

### Difference between **default** and **log_size**
- TPS : 1.5x
- write/s : 2x 

## Background Info 

### InnoDB Logging System
Since InnoDB keeps the working set in memory(buffer pool), changes made by transactions will occur in volatile memory and later be flushed to disk. So in case of volatile memory failure, InnoDB uses logging system to have consistent record of data in database. 

### Transaction Log
The InnoDB transaction log handles REDO logging, which provides ACID(Atomic, Consistent, Durability). The transaction log keeps record of all the change that occurs to the pages inside the database. But instead of logging whole pages, InnoDB uses physicological logging by using double write buffer to ensure consistent page writes.

### How does Log File Size Affect Response Time?
In order to keep ACID compliance, the transaction log must guarantee the logging action happens before the transaction is committed, which is known as write-ahead-logging(WAL). As the time to log is added to every update it can become an important overhead to your response time. Configuring ```innodb_flush_at_trx_commit``` can reduce overhead by flushing less frequently.

### How does Log File Size Affect Throughput?
As the REDO log in InnoDB uses a fixed length circular transaction log, the speed of UPDATE is tightly linked to the speed at which check-pointing can occur. In order to insert a new record in the transaction log, InnoDB must ensure that the previously written record has been flushed to disk. This means that it can be beneficial to have very large transaction logs which allow a larger window between REDO logging and the checkpoint on disk.

### Variable Setting in MySQL Configuration File
In conclusion, configuring InnoDB's redo space is crucial for write-intensive workloads. With additional redo log space, performance of write I/O will also increase. However, it also means longer recovery time when power loss or crash occurs. Consider these tradeoffs and add the configurations.

- ```innodb_log_file_size```(default 50M)
- ```innodb_log_files_in_group```(default 2): if total log size is over 1G, you should have more than 1 for this variable.

- ```innodb_flush_at_trx_commit = 0```: write log buffer to log about once a second and flush
- ```innodb_flush_at_trx_commit = 1```: write log buffer to log and flush to disk
- ```innodb_flush_at_trx_commit = 2```: write log buffer to log and flush about once a second 

```bash
...
# Transaction log settingsords to the transaction l
innodb_log_file_size=1G
innodb_log_files_in_group=3
innodb_log_buffer_size=32M

# Log group path (iblog0, iblog1, iblog2)
innodb_log_group_home_dir=/home/lbh/test_log/org/

# Flush settings
# 0: every 1 seconds, 1: fsync on commits, 2: writes on commits
innodb_flush_log_at_trx_commit=0
innodb_flush_neighbors=0
innodb_flush_method=O_DIRECT
...
```

## Reference
- https://www.percona.com/blog/2011/02/03/how-innodb-handles-redo-logging/
