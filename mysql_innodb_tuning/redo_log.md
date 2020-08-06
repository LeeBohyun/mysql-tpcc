# Relation between InnoDB Redo Log Size and Performance

**:warning: Tuning Project based on MySQL-5.7.24 and tested by TPC-C benchmark **

## Redo Log

## Variable Setting in my.cnf
- default ```innodb_log_file_size``` is 32M and default ```innodb_log_files_in_group``` is 2. 

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
