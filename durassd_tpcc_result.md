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
- **compare 15% free space and 4k # of delivery transaction.
- **compare free buffer wait of 4k, ns, and war

## COMPARE ORDER-LINE SPLIT


## Crucial Micron SSD(250G) Result

### Settings

- Memory 5G
- warehouse 1000 (100GB)
- TPC-C connection: 4
- data device: micron crucial SSD 250GB
- DBMS: mysql-5.6.26 / mysql-5.7.24

### 5.7 for 72h 

| Option   |  TPS | READ/S | WRITE/S  |Storage Change(GB)| 
|:----------:|-------------|-------------|-------------|-------------|
|default| 16 | 988  | 414 | 91-> 105 (14)  |
|log_size| 24 | 1104  | 743 |  91 -> 107 (16) |
|page_size| 38 |   1427 | 1046  |109 -> 127 (18)|
|non-split(15%)| 83 | 3450  | 2013 | 112 -> 147 (35) | 
|dwb-off | 137 |  4862 | 2418 | 112-> 154 | 

### 5.7 for 2h:

| Option   |  TPS | READ/S | WRITE/S  | Storage Change(GB)| 
|:----------:|-------------|-------------|-------------|-------------|
|default| 13 | 679  | 440  | 91-> 95  |
|log_size| 21 | 1067  | 489 | 91 -> 95 |
|page_size| 39 |  1485 | 829 | 109 -> 114|
|non-split(15%)| 77 | 1834  | 486 | 112 -> 112 | 
|dwb-off | 183 |  3907 | 906 | 112-> 113 | 

### 5.6 for 2h:

| Option   |  TPS | READ/S | WRITE/S  | Storage Change(GB)| 
|:----------:|-------------|-------------|-------------|-------------|
|default| 17 | 869 | 424   | 91-> 95  |
|log_size| 28 | 1381  | 579 | 91 -> 95 |
|page_size| 46 |  1726 | 871 | 109 -> 114|
|non-split| 70 | 2515 | 1241 | 113 -> 119 | 
|dwb-off | 138 |  4862 | 2418 |112-> 119 | 


