# MySQL/InnoDB TPC-C Result

## 실험환경
- Memory 5G
- Experiment for 2h
- warehouse 1000
- TPC-C connection: 4

## MySQL-5.6  Result


| Option   |  TPS | READ/S | WRITE/S  | INCREASED STORAGE | SPLIT_NUM |
|:----------:|-------------|-------------|-------------|-------------|-------------|
|default| 21 | 1100  | 604 | 91 -> 95 | 119 008 |
|log_size| 21 | 1093  | 493 |  91 -> 95 | 118 180 |
|page_size| 32 |  1427 | 1046 | 109 -> 114 | 328 762 |

### free space 15%

| Option   |  TPS | READ/S | WRITE/S  | INCREASED STORAGE | SPLIT_NUM |
|:----------:|-------------|-------------|-------------|-------------|-------------|
|non-split|53 |  1922 | 977 |  111 -> 116 | 470 954 |
|dwb-off | 64 |  2298  | 1142 |  111 -> 116 | 542 317 |

### **free space 20%**

| Option   |  TPS | READ/S | WRITE/S  | INCREASED STORAGE | SPLIT_NUM |
|:----------:|-------------|-------------|-------------|-------------|-------------|
|**update non-split** | 71 |  2525  | 1241 |  113 -> 119 | 586 674|
|**update dwb-off** | 138 |  4862  | 2418 |  113 -> 119 | 987 046|

## MySQL-5.7 Result

| Option   |  TPS | READ/S | WRITE/S  | INCREASED STORAGE | SPLIT_NUM |
|:----------:|-------------|-------------|-------------|-------------|-------------|
|default| 13 | 988  | 414 | 91 -> 95 | 95 822 |
|log_size| 21 | 1067  | 489 | 91 -> 95 | 116 756 |
|page_size| 39 | 1485 | 829  |  109 -> 114 | 381 599 |
|non-split| 77 | 1834  | 486 | 112 -> 112 | 186 107 |
| dwb-off | 229 | 4507  | 906 | 112 -> 113 | 300 223 |

## MyRocks Result

| Option   |  TPS | READ/S | WRITE/S  | INCREASED STORAGE | 
|:----------:|-------------|-------------|-------------|-------------|
|default| 79 | 1303 | 8 | 158 -> 168 | 