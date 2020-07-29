# multi tpcc-mysql testing: 

**:warning: experiment setup based on Ubuntu 16.04.**

## Device initialization and format

Before running tpcc benchmark, cleaning your device would be necessary for fair testing.

- initialize: below command line fills the whole device with zero, `status=progress` shows job progress. I recommend you to do this twice for perfect initalization.

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
In the case of the log device, we turned off the *write barrier* option to mitigate the overhead of `fsync()`. The detailed reasons are as follows:

> A **write barrier** is a kernel mechanism used to ensure that file system metadata is correctly written and ordered on persistent storage, even when storage devices with volatile write caches lose power. File systems with write barriers enabled also ensure that data transmitted via `fsync()` is persistent throughout a power loss.
> However, enabling write barriers incurs a substantial performance penalty for some applications. Specifically, applications that use `fsync()` heavily or create and delete many small files will likely run much slower.
> For devices with non-volatile, battery-backed write caches and those with write-caching disabled, you can safely disable write barriers at mount time using the `-o nobarrier` option for mount.

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

1. Download the source code of [MySQL 5.7 Community Server](https://dev.mysql.com/downloads/mysql/5.7.html#downloads) using `wget`:

```bash
$ wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.27.tar.gz
```

2. Extract the `mysql-5.7.27.tar.gz` file:

```bash
$ tar -xvzf mysql-5.7.27.tar.gz
$ cd mysql-5.7.27
```

3. In MySQL 5.7, the Boost library is required to build MySQL. Therefore, download it first:

```bash
$ cmake -DDOWNLOAD_BOOST=ON -DWITH_BOOST=/path/to/download/boost -DCMAKE_INSTALL_PREFIX=/path/to/dir
```

If you already have the Boost library, change the default installation directory:

```bash
$ cmake -DWITH_BOOST=/path/to/boost -DCMAKE_INSTALL_PREFIX=/path/to/dir
```

4. Then build and install the source code:
(8: # of cores in your machine)

```bash
$ make -j8 install
```

5. `mysqld --initialize` handles initialization tasks that must be performed before the MySQL server, mysqld, is ready to use:

- `--datadir` : the path to the MySQL data directory (e.g., `/home/mijin/test_data`)
- `--basedir` : the path to the MySQL installation directory (e.g., `/home/mijin/mysql-5.7.24`)

```bash
$ ./bin/mysqld --initialize --user=mysql --datadir=/path/to/datadir --basedir=/path/to/basedir
```

If you want to change the page size to 4K (default: 16K), add the `innodb_page_size` parameter. For example:

```bash
$ ./bin/mysqld --initialize --innodb_page_size=4k --user=mysql --datadir=/path/to/datadir --basedir=/path/to/basedir
```

6. Reset the root password:

```bash
$ ./bin/mysqld_safe --skip-grant-tables --datadir=/path/to/datadir

$ ./bin/mysql -uroot

root:(none)> use mysql;

root:mysql> update user set authentication_string=password('yourPassword') where user='root';
root:mysql> flush privileges;
root:mysql> quit;

$ ./bin/mysql -uroot -p

root:mysql> set password = password('yourPassword');
root:mysql> quit;
```

7. Open `.bashrc` and add MySQL to your path:

```bash
$ vi ~/.bashrc

export PATH=/path/to/basedir/bin:$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/path/to/basedir/lib/

$ source ~/.bashrc
```

8. Modify the configuration file (`my.cnf` in your `/path/to/datadir`) for your purpose. For example, create or modify the contents of the configuration file as follows:

```bash
$ vi my.cnf

#
# The MySQL database server configuration file.
#
[client]
user    = root
port    = 3306
socket  = /tmp/mysql.sock

[mysql]
prompt  = \u:\d>\_

[mysqld_safe]
socket  = /tmp/mysql.sock

[mysqld]
# Basic settings
default-storage-engine = innodb
pid-file        = /path/to/datadir/mysql.pid
socket          = /tmp/mysql.sock
port            = 3306
datadir         = /path/to/datadir/
log-error       = /path/to/datadir/mysql_error.log

#
# Innodb settings
#
# Page size
innodb_page_size=16KB

# file-per-table ON
innodb_file_per_table=1

# Buffer settings
innodb_buffer_pool_size=2G
innodb_buffer_pool_instances=8
innodb_lru_scan_depth=1024

# Transaction log settings
innodb_log_file_size=500M
innodb_log_files_in_group=3
innodb_log_buffer_size=32M

# Log group path (iblog0, iblog1)
innodb_log_group_home_dir=/path/to/logdir/

# Flush settings
# 0: every 1 seconds, 1: fsync on commits, 2: writes on commits
innodb_flush_log_at_trx_commit=0
innodb_flush_neighbors=0
innodb_flush_method=O_DIRECT

# Doublewrite buffer ON
innodb_doublewrite=ON

# Asynchronous I/O control
innodb_use_native_aio=true
```

9. Shut down and restart the MySQL server:

```bash
$ ./bin/mysqladmin -uroot -pyourPassword shutdown
$ ./bin/mysqld_safe --defaults-file=/path/to/my.cnf
```

10. You can shut down the server using the below command:

```bash
$ ./bin/mysqladmin -uroot -pyourPassword shutdown
```

## How to install tpcc-mysql

### Installation

1. Clone tpcc-mysql from [Percona GitHub repositories](https://github.com/Percona-Lab/tpcc-mysql):

```bash
$ git clone https://github.com/Percona-Lab/tpcc-mysql.git
```

2. Go to the tpcc-mysql directory and build binaries:

```bash
$ cd tpcc-mysql/src
$ make
```

3. Before running the benchmark, you should create a database for TPC-C test. Go to the MySQL base directory and run following commands:

```bash
[session 1]
$./bin/mysqld_safe --defaults-file=/path/to/my.cnf

[session 2]
$ ./bin/mysql -u root -p -e "CREATE DATABASE tpcc100;"
$ ./bin/mysql -u root -p tpcc100 < /path/to/tpcc-mysql/create_table.sql
$ ./bin/mysql -u root -p tpcc100 < /path/to/tpcc-mysql/add_fkey_idx.sql
```

4. Then go back to the tpcc-mysql directory and load data. Before running the script, change `LD_LIBRARY_PATH` and enter `yourPassword` in the `load.sh` file:

```bash
$ cd tpcc-mysql
$ vi load.sh

export LD_LIBRARY_PATH=/path/to/basedir/lib
...
./tpcc_load -h $HOST -d $DBNAME -u root -p "yourPassword" -w $WH -l 1 -m 1 -n $WH >> 1.out &
...
./tpcc_load -h $HOST -d $DBNAME -u root -p "yourPassword" -w $WH -l 2 -m $x -n $(( $x + $STEP - 1 ))  >> 2_$x.out &
./tpcc_load -h $HOST -d $DBNAME -u root -p "yourPassword" -w $WH -l 3 -m $x -n $(( $x + $STEP - 1 ))  >> 3_$x.out &
./tpcc_load -h $HOST -d $DBNAME -u root -p "yourPassword" -w $WH -l 4 -m $x -n $(( $x + $STEP - 1 ))  >> 4_$x.out &
...
```

5. Load data:

```bash
$ ./load.sh tpcc100 100
```

In this case, database size is about 10 GB (= 100 warehouses).

6. After loading, run tpcc-mysql test:

```bash
$ ./tpcc_start -h127.0.0.1 -S/tmp/mysql.sock -dtpcc100 -uroot -pyourPassword -w100 -c32 -r10 -l1200
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


### Output

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
