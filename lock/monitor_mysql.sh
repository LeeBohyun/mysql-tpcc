#!/bin/bash

mysql_dir="/home/lbh/mysql-5.6.26"
result_dir="/home/lbh/result/lock"


end=$((SECONDS+1800))

# Write mutex information to file every second
while [ $SECONDS -lt $end ]
do
    # Get mutex information and write it to the result file
    ${mysql_dir}/bin/mysql -uroot -pxxxxxx\
        -e "SELECT EVENT_NAME, COUNT_STAR, SUM_TIMER_WAIT/1000000000 SUM_TIMER_WAIT_MS, \
            AVG_TIMER_WAIT/1000000000 AVG_TIMER_WAIT_MS \
            FROM performance_schema.events_waits_summary_global_by_event_name \
            ORDER BY SUM_TIMER_WAIT_MS DESC;" >> ${result_dir}/table_lock_wait.out

    
        ${mysql_dir}/bin/mysql -uroot -pxxxxxx\
                -e "SHOW STATUS LIKE '%row_lock%';" >> ${result_dir}/row_lock_wait.out


        ${mysql_dir}/bin/mysql -uroot -pxxxxxx\
            -e "SELECT EVENT_NAME, COUNT_STAR, SUM_TIMER_WAIT/1000000000 SUM_TIMER_WAIT_MS, \
            AVG_TIMER_WAIT/1000000000 AVG_TIMER_WAIT_MS \
            FROM performance_schema.events_waits_summary_global_by_event_name \
            WHERE SUM_TIMER_WAIT > 0 AND \
            EVENT_NAME LIKE 'wait/io/file/%' \
            ORDER BY SUM_TIMER_WAIT_MS DESC;" >> ${result_dir}/io_wait.out

        ${mysql_dir}/bin/mysql -uroot -pxxxxxx\
            -e "SELECT * \
            FROM performance_schema.events_transactions_summary_global_by_event_name \
            LIMIT 1;" >> ${result_dir}/transaction_summary.out

        ${mysql_dir}/bin/mysql -uroot -pxxxxxx\
            -e "SELECT * FROM INFORMATION_SCHEMA.INNODB_LOCK_WAITS;" >> ${result_dir}/transaction_lock_wait.out
    sleep 1
done
