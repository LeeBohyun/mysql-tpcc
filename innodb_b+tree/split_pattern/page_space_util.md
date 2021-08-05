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


## Experiment Result

### Nonsplit Experiment Result

![ns_org_tps_size_per_time](https://user-images.githubusercontent.com/55489991/127618717-99438b22-cc3b-4e53-9611-365587a1bb9f.png)

![ns_org_running_waf](https://user-images.githubusercontent.com/55489991/127618740-088674e4-8300-4664-bc29-4d9af9f18876.png)

