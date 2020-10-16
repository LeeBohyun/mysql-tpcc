# MySQL/InnoDB vs MyRocks TPC-C Result

## 실험환경
- Buffer pool: 20G
- Experiment time: 1h
- warehouse: 2000
- TPC-C connection: 4
- data device: DuraSSD 960GB

## MySQL-5.6  Result

| Option   |  TPS | READ/S | WRITE/S  | INCREASED STORAGE | SPLIT_NUM |
|:----------:|-------------|-------------|-------------|-------------|-------------|
|default| 84 | 2757  | 2184 | 182 -> 190 | 226 454 |
|DWB OFF| 106 | 3324  | 2946 | 182 -> 190 | 252 017 |
|log_size (5G)| 155 | 4557  | 2118 |  182 -> 191 | 311 305 |
|page_size (4K) | 46 | 1726 | 871 | 109 -> 114 | 428 859 |
|non split (free space 15%)| | | 

