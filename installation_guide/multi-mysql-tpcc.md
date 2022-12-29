# Multi TPC-C Testing in MySQL/InnoDB: 

**:warning: experiment setup based on Ubuntu 16.04.**

## Device initialization and format

Before running tpcc benchmark, cleaning your device would be necessary for fair testing.

- Initialize: below command line fills the whole device with `zero`(`random` also possible), `status=progress` shows job progress. I recommend you to do this twice for perfect initalization.

```bash
$ sudo dd if=/dev/zero of=/dev/sda status=progress
```
- make a new partition:

```bash
$ sudo fdisk dev/sda -> n -> w
$ reboot
```
- device format(make filesystem):

```bash
$ sudo mkfs.ext4 /dev/sda1
```
- or just initialize FTL information in SSD:

```bash
$ sudo blkdiscard /dev/sdc
```

## Mounting devices

In this experiment, we are going to use two devices for data(`/dev/sda`) and log(`/dev/sdc`) respectively.
Replace `lbh` with your username afterwards. 
`chown` command is giving r/w permission to `test_data` directory.

```bash
$ mkdir test_data
$ sudo mount /dev/sda1 test_data
$ sudo chown -R lbh:lbh test_data

$ mkdir test_log
$ sudo mount /dev/sdc1 -o nobarrier test_log
$ sudo chown-R lbh:lbh test_log
```
In the case of the log device, we turned off the *write barrier* option to mitigate the overhead of `fsync()`.

You can check the mounted device with the below command:

```bash
$ mount
...
/dev/sda1 on /home/lbh/test_data type ext4 (rw,relatime,data=ordered)
/dev/sdc1 on /home/lbh/test_log type ext4 (rw,relatime,nobarrier,data=ordered)
...
```

## How to install MySQL 5.7

Building MySQL 5.7 from the source code enables you to customize build parameters, compiler optimizations, and installation location.

### Prerequisites

- libreadline

```bash
$ sudo apt-get install libreadline6 libreadline6-dev
```

- libaio

```bash
$ sudo apt-get install libaio1 libaio-dev
```

- etc.

```bash
$ sudo apt-get install build-essential cmake libncurses5 libncurses5-dev bison
```

### Build and install

- Download the source code of [MySQL 5.7 Community Server](https://dev.mysql.com/downloads/mysql/5.7.html#downloads):

```bash
$ wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.24.tar.gz
$ wget https://downloads.mysql.com/archives/get/p/23/file/mysql-5.6.26.tar.gz
```

- Extract the `mysql-5.7.24.tar.gz` file:

```bash
$ tar -xvzf mysql-5.7.24.tar.gz
$ cd mysql-5.7.27
```

- Download BOOST library to build MySQL:

```bash
$ cmake -DDOWNLOAD_BOOST=ON -DWITH_BOOST=/home/lbh/mysql-5.7.24 -DCMAKE_INSTALL_PREFIX=/home/lbh/mysql-5.7.24
```

- Build and install the source code:
(8: # of cores in your machine)

```bash
$ make -j8 install
```

- MySQL initialization:
`mysqld --initialize` handles initialization tasks that must be performed before the MySQL server, mysqld, is ready to use.
`datadir` and `logdir` must be empty for initialization.

- for mysql-5.7:

```bash
$ ./bin/mysqld --initialize --user=mysql --datadir=/home/lbh/test_data --basedir=/home/lbh/mysql-5.7.24

or if you want to change innodb_page_size to 4k
$ ./bin/mysqld --initialize --innodb_page_size=4k --user=mysql --datadir=/home/lbh/test_data --basedir=/home/lbh/mysql-5.7.24
```
- for mysql-5.6:
```bash
$ scripts/mysql_install_db --user=mysql --defaults-file=/home/lbh/scripts/my1.cnf
```

- Set the MySQL root password:

```bash
$ ./bin/mysqld_safe --defaults-file=/home/lbh/my.cnf --skip-grant-tables --datadir=/home/lbh/test_data
$ ./bin/mysql -uroot -S/tmp/mysql.sock -P3306

root:(none)> use mysql;
root:mysql> update user set authentication_string=password('yourPassword') where user='root';
root:mysql> flush privileges;
root:mysql> quit;

$ ./bin/mysql -uroot -p

root:mysql> set password = password('yourPassword');
root:mysql> quit;
```

- Open `.bashrc` and add MySQL to your path by below lines:

```bash
$ vi ~/.bashrc

export PATH=/home/lbh/mysql-5.7.24/bin:$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/lbh/mysql-5.7.24/lib/

$ source ~/.bashrc
```

- Modify the configuration file (`my.cnf`) for your purpose:
For multiple tpcc testing, each test basedir should have different port(`3307`), socket number(`/tmp/mysql.sock1`).
```bash
$ vi my.cnf

my.cnf examples are in the same directory. 
```

- Shut down and restart the MySQL server:

```bash
$ ./bin/mysqladmin -uroot -p shutdown
```

or if you want to kill all mysqld server

```bash
$ killall mysqld
```

- how to restart server with my.cnf
```bash
$ ./bin/mysqld_safe --defaults-file=/home/lbh/my.cnf
```
- mysql connection
```bash
$ ./bin/mysql -uroot -pyourPassword -S/tmp/mysql.sock -P3306
```

## How to install TPC-C benchmark

### Installation

- Clone tpcc-mysql from [Percona GitHub repositories](https://github.com/Percona-Lab/tpcc-mysql):

```bash
$ git clone https://github.com/Percona-Lab/tpcc-mysql.git
```

- Go to the tpcc-mysql directory and build binaries:

```bash
$ cd tpcc-mysql/src
$ make
```

### Load TPC-C data

- Create a database for TPC-C test. 

```bash
[terminal session 1]
$./bin/mysqld_safe --defaults-file=/home/lbh/my.cnf

[terminal session 2]
$ ./bin/mysql -u root -p -e "CREATE DATABASE tpcc1000;"
$ ./bin/mysql -u root -p tpcc1000 < /home/lbh/mysql-5.7.24/tpcc-mysql/create_table.sql
$ ./bin/mysql -u root -p tpcc1000 < /home/lbh/mysql-5.7.24/tpcc-mysql/add_fkey_idx.sql
```
-Change `load.sh`:
Before running the script, change `LD_LIBRARY_PATH` and enter `yourPassword` in the `load.sh` file:

```bash
$ cd tpcc-mysql
$ vi load.sh

export LD_LIBRARY_PATH=/home/lbh/mysql-5.7.24/lib
DBNAME=$1
WH=$2
HOST=127.0.0.1
STEP=100

./tpcc_load -h $HOST -d $DBNAME -u root -p "evia6587" -P3306 -w $WH -l 1 -m 1 -n $WH >> 1.out &
x=1

while [ $x -le $WH ]
do
 echo $x $(( $x + $STEP - 1 ))
./tpcc_load -h $HOST -d $DBNAME -u root -p "evia6587" -P3306 -w $WH -l 2 -m $x -n $(( $x + $STEP - 1 ))  >> 2_$x.out &
./tpcc_load -h $HOST -d $DBNAME -u root -p "evia6587" -P3306 -w $WH -l 3 -m $x -n $(( $x + $STEP - 1 ))  >> 3_$x.out &
./tpcc_load -h $HOST -d $DBNAME -u root -p "evia6587" -P3306 -w $WH -l 4 -m $x -n $(( $x + $STEP - 1 ))  >> 4_$x.out &
 x=$(( $x + $STEP ))
done

for pid in `jobs -p`
do
	echo wait for $pid
	wait $pid
done

$ sudo chmod 777 load.sh
```

- Load data:

```bash
$ ./load.sh tpcc1000 1000
```

In this case, database size is about 100 GB (= 1000 warehouses).

### Run TPC-C benchmark

- Go to tpcc-mysql directory and run `./tpcc_start` program.

```bash
$ ./tpcc_start -h127.0.0.1 -S/tmp/mysql.sock -dtpcc1000 -uroot -pyourPassword -w100 -c32 -r10 -l1200
```

It means:

- Host: 127.0.0.1
- MySQL Socket: /tmp/mysql.sock
- DB: tpcc100
- User: root
- Password: yourPassword
- Warehouse: 100
- Connection: 32
- Rampup time: 10 (sec)
- Measure: 1200 (sec)

if you want to save TPC-C output, run below command.

```bash
$ ./tpcc_start -h127.0.0.1 -S/tmp/mysql.sock -dtpcc1000 -uroot -pyourPassword -w100 -c32 -r10 -l1200 |tee /home/lbh/result/tpcc.txt
```

### TPC-C Result

With the defined interval (`-i` option), the tool will produce the following output:

```bash
10, trx: 12920, 95%: 9.483, 99%: 18.738, max_rt: 213.169, 12919|98.778, 1292|101.096, 1293|443.955, 1293|670.842
20, trx: 12666, 95%: 7.074, 99%: 15.578, max_rt: 53.733, 12668|50.420, 1267|35.846, 1266|58.292, 1267|37.421
30, trx: 13269, 95%: 6.806, 99%: 13.126, max_rt: 41.425, 13267|27.968, 1327|32.242, 1327|40.529, 1327|29.580
40, trx: 12721, 95%: 7.265, 99%: 15.223, max_rt: 60.368, 12721|42.837, 1271|34.567, 1272|64.284, 1272|22.947
50, trx: 12573, 95%: 7.185, 99%: 14.624, max_rt: 48.607, 12573|45.345, 1258|41.104, 1258|54.022, 1257|26.626
```

Where:

- `10` - the seconds from the start of the benchmark
- `95%: 9.483:` - The 95% Response time of New Order transactions per given interval. In this case it is 9.483 sec
- `99%: 18.738:` - The 99% Response time of New Order transactions per given interval. In this case it is 18.738 sec
- `max_rt: 213.169:` - The Max Response time of New Order transactions per given interval. In this case it is 213.169 sec
- `12919|98.778, 1292|101.096, 1293|443.955, 1293|670.842` - throughput and max response time for the other kind of transactions and can be ignored

### REFERENCE
- https://github.com/Percona-Lab/tpcc-mysql
- https://github.com/meeeejin/til


## Error Handling

- No shared library libsomysql...related
```bash
# cat /etc/ld.so.conf
include ld.so.conf.d/*.conf
/home/lbh/mysql-5.6.26/ <— add 

$ ldconfig

# vim /root/.bash_profile
export PATH=/home/lbh/mysql-5.6.26/lib/

$source /root/.bash_profile
```
