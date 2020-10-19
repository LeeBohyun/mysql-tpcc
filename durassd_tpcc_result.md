# MySQL/InnoDB TPC-C Result

## Settings

- Memory 20G
- Experiment for 1h
- warehouse 2000 (200GB)
- TPC-C connection: 4
- data device: DuraSSD 960GB
- DBMS: mysql-5.6.26


## MySQL-5.6  Result

| Option   |  TPS | READ/S | WRITE/S  | INCREASED STORAGE | SPLIT_NUM |
|:-----------:|:-----------:|:-----------:|:-----------:|:-----------:|:-----------:|
|default| 84 | 2757  | 2184 | 182 -> 190 | 226 454 |
|DWB OFF| 106 | 3324  | 2946 | 182 -> 190 | 252 017 |
| log size (5G) | 155 | 4557  | 2118 | 182 -> 191 | 311 305 |
|page_size (4k)| 317 | 6836 | 3815 |  220 -> 229 | 1193 292 |
|non-split(15%)| 319 | 6883  | 3824 | 223 -> 234 |  1212 570 |
|non-split(20%)| 318 | 6867  | 3816 | 226 -> 237 | 1220 958 |
|war | 321 | 6920 |3839 | 226 -> 237| 1227 888|

