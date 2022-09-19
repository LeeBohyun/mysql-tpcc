# Project 1 Assignment: Finding the ideal LRU_scan_depth

## Implications of ```innodb_lru_scan_depth```
- How does ```innodb_lru_scan_depth``` affect the operation method of buffer manager?
- Hint: Use grep command to find the location of ```srv_LRU_scan_depth``` in ```mysql-5.7.33```.


## Experiment Guide
### Configure LRU scan depth
Modify ```my.cnf``` file and vary ```innodb_lru_scan_depth``` configuration variable : 128 256 512 1024 2048 4096 8192. Refer to the [mysql document](https://dev.mysql.com/doc/refman/5.7/en/innodb-parameters.html#sysvar_innodb_lru_scan_depth) for more information.

### Run TPC-C benchmark
Run TPC-C benchmark with the same configuration  with [week 4](https://github.com/LeeBohyun/mysql-tpcc/blob/master/buffer_manager/buffer_miss_scenario_monitoring.md) while monitoring IOPS and CPU utilization with ```iostat``` at the same time. Also, check the hit ratio and the ratio of step 1, 2, and 3 after benchmarking.


## Report Submission Guide

- The report should include the following contents.
  - Summarize & analyze the ```innodb_lru_scan_depth```-related mysql source code (``buf0lru.cc``, ``buf0flu.cc``)
  - How TpmC, read write IOPS, and hit ratio changes when varying ```innodb_lru_scan_depth```:128 256 512 1024 2048 4096 8192.  (In a graph or a table)
  - How the ratio of Step 1, 2, 3 of the victim selection policy changes when varying ```innodb_lru_scan_depth```
  - The TpmC gap between the default ```innodb_lru_scan_depth (1024)``` and the ideal ```innodb_lru_scan_depth``
  
- The report should answer to the following questions.
  - Question 1) How does ```innodb_lru_scan_depth``` affect the operation method of buffer manager? 
  - Question 2) Among values of 128, 256, 512, 1024, 2048, 4096, and 8192, which value is the ideal ```innodb_lru_scan_depth```? Explain the reason why in terms of transaction throughput.

- Refer to the report submission guide for the format.
