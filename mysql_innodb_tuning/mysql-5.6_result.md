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
|non-split|53 |  1922 | 977 |  111 -> 116 | 470 954 |
|dwb-off | 76 |  781  | 237 |  111 -> 116 | 614 585 |

## MySQL-5.7 Result

| Option   |  TPS | READ/S | WRITE/S  | INCREASED STORAGE | SPLIT_NUM |
|:----------:|-------------|-------------|-------------|-------------|-------------|
|default| 13 | 988  | 414 | 91 -> 95 | 95 822 |
|log_size| 21 | 1067  | 489 | 91 -> 95 | 116756 |
|page_size| 39 | 1485 | 829  |  109 -> 114 | 381 599 |
|non-split| 77 | 1834  | 486 | 112 -> 112 | 186 107 |
|dwb-off | 326 | 6831  | 1281 |   | |

- ```page size=4k``` tuning 부터 5.7과 5.6 성능 격차 점점 벌어짐

## :warning: 추가 확인사항
-  dwb off 5.6 5.7 재실험 필요 
- myrocks TPC-C 결과와 비교
