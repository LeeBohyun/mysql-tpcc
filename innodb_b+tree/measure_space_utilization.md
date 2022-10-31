# How to measure space amplification in MySQL/InnoDB

## Overview
Space amplification can be calculated by dividing DB size on file system / actual user data size.

## Prerequisites

### 1. Install `innodb_ruby`

```bash
$ sudo apt-get install gem
$ sudo apt-get install rubygems ruby-dev
```

```bash
$ sudo gem install rake
$ sudo gem install innodb_ruby -v 0.9.16
```

### 2. Load & Run TPC-C data with the following options.

Refer to the week 2 for TPC-C/MySQL testing guide.

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

./tpcc_load -h $HOST -d $DBNAME -u root -p "yourPassword" -P3306 -w $WH -l 1 -m 1 -n $WH >> 1.out &
x=1

while [ $x -le $WH ]
do
 echo $x $(( $x + $STEP - 1 ))
./tpcc_load -h $HOST -d $DBNAME -u root -p "yourPassword" -P3306 -w $WH -l 2 -m $x -n $(( $x + $STEP - 1 ))  >> 2_$x.out &
./tpcc_load -h $HOST -d $DBNAME -u root -p "yourPassword" -P3306 -w $WH -l 3 -m $x -n $(( $x + $STEP - 1 ))  >> 3_$x.out &
./tpcc_load -h $HOST -d $DBNAME -u root -p "yourPassword" -P3306 -w $WH -l 4 -m $x -n $(( $x + $STEP - 1 ))  >> 4_$x.out &
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
$ ./load.sh tpcc 20
```
- Run TPC-C Benchmark:
```bash
./tpcc_start -h 127.0.0.1 -S /tmp/mysql.sock -d tpcc -u root -p "yourPassword" -w 20 -c 8 -r 10 -l 1200 

```

### 3. Calculate User Data size in B+-tree nodes
Once the TPC-C benchmark is finished, run ``innodb_space`` command to each TPC-C tables. For instance, ```/path/to/test_data/tpcc/history.ibd``` indicates history.ibd table in the tpcc file located inside your ```test_data dir```.
Run the following command **for each of the TPC-C table**.
```bash
$ innodb_space -f /path/to/test_data/tpcc/history.ibd space-index-pages-summary 
page        index   level   data    free    records 
3           15      2       26      16226   2       
4           15      0       9812    6286    446     
5           15      0       15158   860     689     
6           15      0       10912   5170    496     
7           15      0       10670   5412    485     
8           15      0       12980   3066    590     
9           15      0       11264   4808    512     
10          15      0       4488    11690   204     
11          15      0       9680    6418    440     
...

```

After running ```innodb_space``` commands, calculate the actual data size in B+tree pages. The page size is 16K(16,384 bytes) and the user data of each pages are shown in ```data``` column in bytes.
Add all the data columns in all the TPC-C tables.

I recommend you to use ```awk``` for this task. Refer to this link for ```awk``` examples. [awk examples](https://www.geeksforgeeks.org/awk-command-unixlinux-examples/)

### 4. Calculate Space Amplification Factor

- Space amplification  = tpcc DB size / user data size
- Total DB size = number of pages * 16K

# References
- https://blog.jcole.us/2013/01/03/a-quick-introduction-to-innodb-ruby/
