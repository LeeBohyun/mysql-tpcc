# Relation between InnoDB Redo Log Size and Performance

**:warning: Tuning Project based on MySQL-5.7.24 and tested by TPC-C benchmark **

## InnoDB Logging System
Since InnoDB keeps the working set in memory(buffer pool), changes made by transactions will occur in volatile memory and later be flushed to disk. So in case of volatile memory failure or power loss, InnoDB uses logging system to have consistent record of data. It ensures that when a transaction is committed, data is not lost in the event of crash or power loss.

## Transaction Log
The InnoDB transaction log handles REDO logging, which provides ACID(Atomic, Consistent, Durability). The transaction log keeps record of all the change that occurs to the pages inside the database. But instead of logging whole pages, InnoDB uses physicological logging by using double write buffer to ensure consistent page writes.

## How does Log File Size affect response time?
In order to keep ACID compliance, the transaction log must guarantee the logging action happens before the transaction is committed, this is known as write-ahead-logging. This essentially means that before an update can return it must be logged. As the time to log is added to every update it can become an important overhead to your response time. Indeed if InnoDB cannot log at all, your transaction will never complete.

## How does Log File Size affect throughput?
As the REDO log in InnoDB uses a fixed length circular transaction log, the speed of UPDATE is tightly linked to the speed at which check-pointing can occur. In order to insert a new record in the transaction log, InnoDB must ensure that the previously written record has been flushed to disk. This means that it can be beneficial to have very large transaction logs which allow a larger window between REDO logging and the checkpoint on disk.

## Variable Setting in my.cnf
Configuring InnoDB's redo space is crucial for write-intensive workloads. With additional redo log space, performance of write I/O will also increase. However, it also means longer recovery time when power loss or crash occurs. Consider these tradeoffs and add the configurations.

- ```innodb_log_file_size```(default 50M)
- ```innodb_log_files_in_group```(default 2): if total log size is over 1G, you should have more than 1 for this variable.

- ```innodb_flush_at_trx_commit = 0```: write log buffer to log about once a second and flush
- ```innodb_flush_at_trx_commit = 1```: write log buffer to log and flush to disk
- ```innodb_flush_at_trx_commit = 2```: write log buffer to log and flush about once a second 

```bash
# Transaction log settings
innodb_log_file_size=1G
innodb_log_files_in_group=3
innodb_log_buffer_size=32M

# Log group path (iblog0, iblog1)
innodb_log_group_home_dir=/home/lbh/test_log/org/

# Flush settings
# 0: every 1 seconds, 1: fsync on commits, 2: writes on commits
innodb_flush_log_at_trx_commit=0
innodb_flush_neighbors=0
```
## Reference
- https://www.percona.com/blog/2011/02/03/how-innodb-handles-redo-logging/
- 
