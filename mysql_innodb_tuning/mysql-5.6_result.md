# MySQL/InnoDB TPC-C Result

## 실험환경
- Memory 5G
- Experiment for 2h
- warehouse 1000
- TPC-C connection: 4

## MySQL-5.6  Result

| Option   |  TPS | READ/S | WRITE/S  | 
|:----------:|-------------|-------------|-------------|
|default| 13 | 980  | 403 | 
|log_size| 21 | 1093  | 493 | 
|page_size| 32 |  1427 | 1046  | 
|non-split|57 |  2147 | 1044 | 
|dwb-off | 76 |  781  | 237 | 

## MySQL-5.7 Result

| Option   |  TPS | READ/S | WRITE/S  | 
|:----------:|-------------|-------------|-------------|
|default| 13 | 988  | 414 | 
|log_size| 21 | 1067  | 489 |  
|page_size| 39 | 1485 | 829  |  
|non-split| 86 | 2195  | 547 | 
|dwb-off | 326 | 6831  | 1281 |   

- ```page size=4k``` tuning 부터 5.7과 5.6 성능 격차 점점 벌어짐

## :warning: 추가 확인사항
-  dwb off 5.6 5.7 재실험 필요 
- myrocks TPC-C 결과와 비교
