# MySQL/InnoDB TPC-C Result

##  DuraSSD MySQL-5.6  Result

### Settings

- Memory 20G
- Experiment for 1h
- warehouse 2000 (200GB)
- TPC-C connection: 4
- data device: DuraSSD 960GB
- DBMS: mysql-5.6.26

### Result

| Option   |  TPS | READ/S | WRITE/S  | INCREASED STORAGE | SPLIT_NUM |
|:-----------:|:-----------:|:-----------:|:-----------:|:-----------:|:-----------:|
|default| 84 | 2757  | 2184 | 182 -> 190 | 226 454 |
|DWB OFF| 106 | 3324  | 2946 | 182 -> 190 | 252 017 |
| log size (5G) | 155 | 4557  | 2118 | 182 -> 191 | 311 305 |
|page_size (4k)| 317 | 6836 | 3815 |  220 -> 229 | 1193 292 |
|non-split(15%)| 319 | 6883  | 3824 | 223 -> 234 |  1212 570 |
|non-split(20%)| 318 | 6867  | 3816 | 226 -> 237 | 1220 958 |
|war | 321 | 6920 |3839 | 226 -> 237| 1227 888|

### Settings

- Memory 20G
- Experiment for 1h
- warehouse 5000 (500GB)
- TPC-C connection: 4
- data device: DuraSSD 960GB
- DBMS: mysql-5.6.26

### Result

| Option   |  TPS | READ/S | WRITE/S  | INCREASED STORAGE | SPLIT_NUM |
|:-----------:|:-----------:|:-----------:|:-----------:|:-----------:|:-----------:|
|page_size (4k)| 176 | 8596 | 3415 |  548 -> 569 | 1110 343 |
|non-split(20%)| 174 | 8405 | 3346 | 567 -> 590 | 1121 153 |

### Plan:
- need SSD initialization
- compare 15% free space and 4k # of **delivery transaction** : delivery transaction split confirmed.  
- **compare free buffer wait of 4k, ns, and war**

### ORDER-LINE SPLIT Result

| Split type   |  **ORG(6.25%)** | **TUNED(15%)** |
|:----------:|:-------------:|:-------------:|
|66 byte (delivery transaction)| 9863 | 0 | 
|61 byte (new order transaction)| 241 475 | 253 714  | 
|24 byte (internal)| 958 |  949 | 
|20 byte (fkey_order_line_2)| 88 793 | 83 018  | 
|18 byte (internal)| 21741 |  21 210 | 
|total Order-Line split#| 362 830 | 358 891|
|storage change | 219 -> 229 |224 ->234 |
|TPS | 355 | 336 |

### FREE BUFFER-WAIT Result
|buf0lru.cc|16k (dwb on) |16k(dwb off)| 4k  |+nonsplit(15%) |+war |
|:----------:|:-------------:|:-------------:|:-------------:|:-------------:|:-------------:|
|clean page|826 856|61 380|305 189|214 062|623 985| 
|spf mode|0|0|0 |0|0|
|background wait|66|0|0|0|0|
|try to get block|13 686 503|19 315 151|34 078 760|30 997 392|32 843 417|
|free block|12 859 581|19 253 771|33 760 077|30 783 552|32 198 730|
|no block|826 922|61 380|336 698|214 062|667 662|

### Settings
- log size: 5G
- 2000 warehouse
- time: 1h
- connection : 4
- bufferpool sz: 20G


my1.cnf(16k)
```bash
#
# The MySQL database server configuration file.//tuning factor: redo log file size
#
[client]
user    = root
port    = 3307
socket  = /tmp/mysql.sock1

[mysql]
prompt  = \u:\d>\_

[mysqld_safe]
port    = 3307
socket  = /tmp/mysql.sock1

[mysqld]
# Basic settings
default-storage-engine = innodb
pid-file        = /home/lbh/test_data/mysql.pid
socket          = /tmp/mysql.sock1
port            = 3307
datadir         = /home/lbh/test_data/
log-error       = /home/lbh/test_data/mysql_error.log
innodb_monitor_enable = module_index

#
# Innodb settings
#

# file-per-table ON
innodb_file_per_table=1

# Buffer settings
innodb_buffer_pool_size=20G
innodb_buffer_pool_instances=8
innodb_lru_scan_depth=1024

# Transaction log settings
innodb_log_file_size=1G
innodb_log_files_in_group=5
innodb_log_buffer_size=32M

# Log group path (iblog0, iblog1)
innodb_log_group_home_dir=/home/lbh/test_log/org/

# Doublewrite buffer ON
innodb_doublewrite=ON

# Flush settings
# 0: every 1 seconds, 1: fsync on commits, 2: writes on commits
innodb_flush_log_at_trx_commit=0
innodb_flush_neighbors=0
innodb_flush_method=O_DIRECT

```

