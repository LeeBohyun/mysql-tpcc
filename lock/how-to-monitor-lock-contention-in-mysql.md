# Monitoring Lock Contention in MySQL

## Overview 
- Monitor transaction lock wait in MySQL while varying the buffer pool size
- Drilldown the lock contentcion to find out which TPC-C transaction worsens the tail latency 

## Instructions

1. Add the lines below in ``my.cnf`` file
```bash
innodb_monitor_enable = module_index
performance-schema-instrument='wait/synch/mutex/innodb/%=ON'
performance-schema-instrument='wait/synch/sxlock/innodb/%=ON'
performance-schema-instrument='wait/io/file/%=ON'
performance-schema-instrument='wait/lock/%=ON'
performance-schema-instrument='transaction=ON'
performance-schema-consumer-events-transactions-current=ON
performance-schema-consumer-events-transactions-history=ON
performance-schema-consumer-events-transactions-history-long=ON
```
- Set the ``innodb_buffer_pool_size`` variable into 20% of your DB size


2. Start MySQL server (you can use the command below to run mysql server in the background) and run the TPC-C benchmark
```bash
$ ./bin/mysqld --defaults-file=/path/to/my.cnf & >/dev/null &disown 
$ ./tpcc_start -h127.0.0.1 -S/tmp/mysql.sock -P3306 -dtpcc1000 -uroot -pxxxxxx -w1000 -c32 -r10 -l1800 | tee tpcc_result.out
```

3. While running the TPC-C benchmark, execute ``iostat`` and ``monitor_mysql.sh`` file 
```bash
$ iostat -x 1 >> iostat.out &
$ ./monitor_mysql.sh &
```
