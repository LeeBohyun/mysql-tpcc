# Analyze Page Space Util 

## AFTER DATA LOAD

### Vanilla
- secondary index page util: 66%
- pk page util: 91%

### Nonsplit only
- secondary index page util: 66%
- pk page util: 88%

### Redistribute(ol secondary index only) + Nonsplit(10%)
- secondary index page util: 83%
- pk page util: 89%

## AFTER RUNNING TPC-C TEST

### Vanilla Page Free Space

Order-Line PK Leaf Page
![ol-page-space](https://user-images.githubusercontent.com/55489991/126852515-fb80c77d-8aaa-4b47-ab3c-00eeb478ff15.png)
- avg space util: 62%

Order-Line Secondary Index Leaf Page
- avg util: 65%


### Nonsplit Page Util

Order-Line PK Leaf Page
- avg space util: 14896/16384 90%

Order-Line Secondary Index Leaf Page
- avg space util: 10804/16384 65%

### Redistribute only Page Util
Order-Line PK Leaf Page
- avg space util: 14690/16384 90%

Order-Line Secondary Index Leaf Page
- avg space util: 14084/16384 86%

Total
- avg space util: 14544/16384 : 88.7%

## Experiment Result

### Nonsplit Experiment Result

