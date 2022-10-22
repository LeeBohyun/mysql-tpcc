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
```bash
./load.sh tpcc 20
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
You can get TPC-C DB size by the following command.
```bash
$ du -sh /path/to/test_data/tpcc/
```

# References
- https://blog.jcole.us/2013/01/03/a-quick-introduction-to-innodb-ruby/
