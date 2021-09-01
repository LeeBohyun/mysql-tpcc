# LinkBench Split Pattern in MySQL/InnoDB

refer to https://github.com/meeeejin/til/blob/master/benchmark/summary-of-linkbench-for-mysql.md for linkbench summary

## Split Pattern 

### Nodetable
- no secondary index
- append only table
- page space util over 90%

### Counttable
- page space util around 50%

### Linktable
- many secondary index
- divided into 16 tables

## Page Space Util per Table

### Nodetable
- total: 14765/16384
- no secondary index

### Counttable
- total: 9649/16384
- no secondary index

### Linktable
- total: 11254/16384 : 65~69%
- secondary index primary key similar page space util
- #of page secondary index: pk = 69434: 42724
