# Monitoring Buffer Miss Scenario in MySQL/InnoDB

## LAB contents
- When the foreground thread requests page read but the according page is not found in the buffer cafche, MySQL/InnoDB takes 3 steps to read a page from the disk.
 
- This week, you are going to monitor how the victim page is selected upon buffer miss. 
- Measure the ratio of each step and investigate which step would be fatal to DBMS performance, and elaborate on the reason as well.

## How to add printf() in MySQL source 
0.Load TPC-C data with 20 warehouses.

1. Add a fprintf code to ```mysql-5.7.33/storage/innobase/buf/buf0lru.cc```. Refer to the lecture pdf to figure out where to add the fprintf code.
```bash
...
fprintf(stderr, "Get free block from free list\n");
...
fprintf(stderr, "Get free block by LRU scan\n");
...
fprintf(stderr, "Get free block by single page flush\n");
```

2. Rebuild MySQL source code
```bash
cd mysql-5.7.33
make -j install
```

3. Modify my.cnf file with the following content.
```bash
...
innodb_buffer_pool_size=100M
innodb_buffer_pool_instances=8
...
```

4. Reopen MySQL server
```bash
cd mysql-5.7.33
./bin/mysqld_safe --defaults-file=/path/to/my.cnf
```

5. Check ```mysql_error.log``` file if the modified codes are applied in the current MySQL server. If you see the logs in the mysql_error.log file, rebuilding is done successfully. Note that after running TPC-C benchmark, the size of the log file can increase up to 1G or more. Be sure to secure enough disk space.
```bash
cd /path/to/test-data
cat mysql_error.log
```

6. Run TPC-C with 20 warehouses. If the number of CPU cores are more than 8, change the option c into # of cores *4.
```bash
cd tpcc-mysql
./tpcc_start -h127.0.0.1 -S/tmp/mysql.sock -dtpcc -uroot -pyourPassword -w20 -c8 -r10 -l1200

```

7. After running TPCC benchmark, check the ratio of each steps by the following commands.
```bash
cd /path/to/test-data
echo "total request" 
grep -c "free block from free list" mysql_error.log
echo "lru scan" 
grep -c "lru scan" mysql_error.log
echo "single page flush" 
grep -c "single page flush" mysql_error.log
```

8. Submit the report with the following content.
- Investigate why the free buffer frames are acquired by these steps with the according ratio, step 1, step 2, and step 3 respectively. 
- Choose which step exacerbates the transaction throughput the most, and explain why.

