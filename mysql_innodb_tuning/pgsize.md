# Relation between InnoDB Page Size and Performance

:warning: NOTIFICATION: Tuning Project based on MySQL-5.7.24 and tested by TPC-C benchmark 

## TPC-C Testing Result

| Option   |  TPS | READ/S | WRITE/S  |SSD WAF| Storage Change(GB)| 
|:----------:|-------------|-------------|-------------|-------------|-------------|
|default| 16 | 988  | 414 | 9.3 | 91-> 105 (14)  |
|log_size| 24 | 1104  | 743 |  7.1| 91 -> 107 (16) |
|page_size| 38 |   1427 | 1046  |  13? | 109 -> 127 (18)|
|non-split| 83 | 3450  | 2013 |6.2 | 112 -> 147 (35) | 

### Difference between **log_size** and **page_size**
- TPS : 1.6x
- write/s : 1.5x
- read/s : 1.3x

## Background Info 

### Write and Erase Transaction in SSD
Most solid state drives (SSDs) use 4K as an internal page size, and the InnoDB default page size is 16K. If we resize ```innodb_page_size``` to 4k, we can achieve higher throughput and I/O performance by increased hit ratio.  

### Variable Setting in MySQL Configuration File
MySQL 5.7 comes with the option innodb_page_size, so you can set different InnoDB page sizes than the standard 16KiB. If you want to set  ```innodb_page_size = 4k```, you need to re-initialize MySQL first.
```
$ ./bin/mysqld --initialize --innodb_page_size=4k --user=mysql --datadir=/home/lbh/test_data --basedir=/home/lbh/mysql-5.7.24
```bash

In your configuration file(my.cnf),
```bash
...
# Page size
innodb_page_size=4KB
# file-per-table ON
innodb_file_per_table=1
...
```

## Reference
- https://www.percona.com/blog/2016/08/10/small-innodb_page_size-performance-boost-ssd/
