# Relation between InnoDB Redo Log Size and Performance

**:warning: Tuning Project based on MySQL-5.7.24 and tested by TPC-C benchmark **

## InnoDB Logging System
Since InnoDB keeps the working set in memory(buffer pool), changes made by transactions will occur in volatile memory and later be flushed to disk. So in case of volatile memory failure or power loss, InnoDB uses logging system to have consistent record of data. It ensures that when a transaction is committed, data is not lost in the event of crash or power loss.

## Redo Log


## Variable Setting in my.cnf
Configuring InnoDB's redo space is crucial for write-intensive workloads. With additional redo log space, performance of write I/O will also increase. However, it also means longer recovery time when power loss or crash occurs. Consider these trade offs and add configurations.

- ```innodb_log_file_size```(default 32M)
- ```innodb_log_files_in_group```(default 2) 

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
