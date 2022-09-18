# Monitoring Buffer Miss Scenario in MySQL/InnoDB

## LAB contents
- When the foreground thread requests page read but the according page is not found in the buffer cafche, MySQL/InnoDB takes 3 steps to read a page from the disk.
 
- This week, you are going to monitor how the victim page is selected upon buffer miss. 
- Measure the ratio of each step and investigate which step would be fatal to DBMS performance, and elaborate on the reason as well.

## How to add printf() in MySQL source code

1. Add a fprintf code to ```mysql-5.7.33/storage/innobase/buf/buf0lru.cc```
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
innodb_buffer_pool_size=100M
innodb_buffer_pool_instances=8
```

4. Reopen MySQL server
```bash
cd mysql-5.7.33
./bin/mysqld_safe --defaults-file=/path/to/my.cnf
```

5. Check ```mysql_error.log``` file if the modified codes are applied in the current MySQL server. If you see 
```bash
cd /path/to/test-data
cat mysql_error.log
```

6. Load and run TPC-C with 20 warehouses. 
```bash
cd tpcc-mysql

```
