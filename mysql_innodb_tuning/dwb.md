# InnoDB DoubleWrite Buffer and Performance

:warning: NOTIFICATION: Tuning Project based on MySQL-5.7.24 and tested by TPC-C benchmark 

## TPC-C Testing Result

### 5.7 for 72h 

| Option   |  TPS | READ/S | WRITE/S  |Storage Change(GB)| 
|:----------:|-------------|-------------|-------------|-------------|
|default| 16 | 988  | 414 | 91-> 105 (14)  |
|log_size| 24 | 1104  | 743 |  91 -> 107 (16) |
|page_size| 38 |   1427 | 1046  |109 -> 127 (18)|
|non-split(15%)| 83 | 3450  | 2013 | 112 -> 147 (35) | 
|dwb-off | 137 |  4862 | 2418 | 112-> 154 | 

### 5.7 for 2h:

| Option   |  TPS | READ/S | WRITE/S  | Storage Change(GB)| 
|:----------:|-------------|-------------|-------------|-------------|
|default| 13 | 679  | 440 |  | 91-> 95  |
|log_size| 21 | 1067  | 489 | 91 -> 95 |
|page_size| 39 |  1485 | 829 | 109 -> 114|
|non-split(15%)| 77 | 1834  | 486 | 112 -> 112 | 
|dwb-off | 183 |  3907 | 906 | 112-> 113 | 

### 5.6 for 2h:

| Option   |  TPS | READ/S | WRITE/S  | Storage Change(GB)| 
|:----------:|-------------|-------------|-------------|-------------|
|default| 17 | 869 | 424 |  | 91-> 95  |
|log_size| 28 | 1381  | 579 | 91 -> 95 |
|page_size| 46 |  1726 | 871 | 109 -> 114|
|non-split| 70 | 2515 | 1241 | 113 -> 119 | 
|dwb-off | 138 |  4862 | 2418 |112-> 119 | 


## Background Info 

### InnoDB DoubleWrite Buffer
InnoDB storage engine has a unique feature called ***"doublewrite"***. InnoDB writes data twice when it performs table space writes, while performing write to log only once. Its purpose is to archive data safely in case of partial page writes.
Partial page writes occur when OS does not fully complete page write request. For instance, out of 16k InnoDB page only first 4K are updated and remaining 12K stays in their formal state. This usually occurs in the case of power failure or OS crash.   

### How Double Write Works
InnoDB flushes multiple pages from InnoDB buffer pool and so the pages will be written to double write buffer sequentially. First fsync() is called to make sure they make it to the disk, and the second fsync() writes pages to their real location. During recovery phase, InnoDB checks pages inside doublewrite buffer and their real location. If page is inconsistent in the tablespace, it is recovered from double write buffer.

### How Double Write Affects MySQL Performance
Although double write seems to make twice overhead since each page is written twice, sequential write makes it less expensive than it looks. In typcial situation, only 5 to 10 percent performance loss is expected. However if we change ```innodb_page_size``` to 4k we no longer need DWB, so in that case we can disable doublewrite by adjusting some variables in configuration file. 

### Variable Setting in MySQL Configuration File
MySQL 5.7 comes with the option ```innodb_doublewrite```, so you can set the variable to either ```ON``` or ```OFF```.

In your configuration file(my.cnf),
```bash
...
innodb_page_size=4k
innodb_doublewrite=OFF
...
```

## Reference
- https://www.percona.com/blog/2006/08/04/innodb-double-write/
