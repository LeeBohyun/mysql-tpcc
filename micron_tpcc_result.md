# Micron MySQL/TPC-C Result


## Settings

- Memory 5G
- warehouse 1000 (100GB)
- TPC-C connection: 4
- data device: micron crucial SSD 250GB
- DBMS: mysql-5.6.26 / mysql-5.7.24


## 5.6 for 2h: **UPDATED VER(12.21)**

| Option   |  TPS | READ/S | WRITE/S  | Storage Change(GB)| 
|:----------:|-------------|-------------|-------------|-------------|
|default| 21 | 869 | 424   | 91-> 95  |
|log_size| 28 | 1381  | 579 | 91 -> 95 |
|page_size| 46 |  1726 | 871 | 109 -> 114|
|non-split| 70 | 2515 | 1241 | 112 -> 116 | 
|war | 84 |  3152 | 1495 |112-> 116 | 
|dwb-off | 138 |  4862 | 2418 |112-> 116 | 


## 5.7 Result
### 5.7 for 72h:

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
