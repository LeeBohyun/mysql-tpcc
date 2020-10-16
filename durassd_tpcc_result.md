# MySQL/InnoDB TPC-C Result

## Settings

- Memory 20G
- Experiment for 1h
- warehouse 2000 (200GB)
- TPC-C connection: 4
- data device: DuraSSD 960GB
- DBMS: mysql-5.6.26


## MySQL-5.6  Result

| Option   |  TPS | READ/S | WRITE/S  | INCREASED STORAGE | SPLIT_NUM |z
|default| 13 | 988  | 414 | 182 -> 95 | 95 822 |
|DWB OFF| 21 | 1067  | 489 | 91 -> 95 | 116 756 |
| log size (5G) | 155 | 4557  | 2118 | 182 -> 191 | 311 305 |
|page_size (4k)| 39 | 1485 | 829  |  109 -> 114 | 381 599 |
|non-split(15%)| 77 | 1834  | 486 | 112 -> 112 | 186 107 |
|war | | | | |

