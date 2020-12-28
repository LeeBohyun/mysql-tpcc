# Micron MySQL/TPC-C Result

## 5.6 for 1h: **UPDATED VER(12.21)**

### Settings

- Bufferpool: 5G
- warehouse 1000 (100GB)
- TPC-C connection: 16
- data device: micron crucial SSD 250GB
- DBMS: mysql-5.6.26 / mysql-5.7.24

### Testing Result

| Option   |  TPS | READ/S | WRITE/S  | Storage Change(GB)| 
|:----------:|-------------|-------------|-------------|-------------|
|default| 19 | 869 | 424   | 91-> 95  |
|log_size| 28 | 1381  | 579 | 91 -> 95 |
|page_size(4k)| 46 |  1726 | 871 | 109 -> 113|
|non-split(15%)| 70 | 2515 | 1241 | 112 -> 116 | 
|war | 79 |  3152 | 1495 |112-> 116 | 
|dwb-off | 138 |  4862 | 2418 |112-> 116 | 

- nonsplit 4k 대비 **tps 1.5X** 증가

### connection: 4
- time: 1h

| Option   |  TPS | READ/S | WRITE/S  | Storage Change(GB)| 
|:----------:|-------------|-------------|-------------|-------------|
|page_size(4k)| 85 |  3191 | 1520 | 109 -> 113|
|non-split(15%)| 137 | 4850 | 2345 | 112 -> 117 | 
|war| 143 | 5469 | 2467 | 112 -> 117 | 

- time: 3h

| Option   |  TPS | READ/S | WRITE/S  | Storage Change(GB)| 
|:----------:|-------------|-------------|-------------|-------------|
|page_size(4k)| 58 |  2070 | 1070 | 109 -> 114|

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
