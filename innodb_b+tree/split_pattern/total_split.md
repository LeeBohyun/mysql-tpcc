# TPC-C Table Leaf Page Split Pattern and Size

## Split #
| Split Table |Split Type | # of Splits | %|
|:----------:|:-------------:|:-------------:|:-------------:|
|Order-Line |66 byte (delivery UPDATE)| 2 946 119 | 38% | 
|Order-Line |61 byte (new order INSERT)|3 369 985 | 43% | 
|Order-Line |20 byte (fkey_order_line_2)| 1 448 773 | 19% |
|Order-Line total|leaf split|7 764 877|100% |
|History| 15 byte|  117 261| 21% | 
|History| 19 byte (sec idx)| 142 303| 26%|
|History| n>55 byte| 290 742|53%|
|History total|leaf split|550 306|100% |
|Orders| 17 byte (sec idx)| 126 769| 23%| 
|Orders| 37, 38 byte| 421 484|77%|
|Orders total|leaf split|548 253|100% |

## Size
- Order-Line: 60GB -> 194GB
- History: 6.7GB -> 17GB
- Orders: 4.1GB -> 11GB

## Vanilla Page Free Space

### Order-Line PK Leaf Page
![ol-page-space](https://user-images.githubusercontent.com/55489991/126852515-fb80c77d-8aaa-4b47-ab3c-00eeb478ff15.png)
- avg space util: 62%

### Order-Line Secondary Index Leaf Page
- avg util: 65%


## Nonsplit Page Util

### Order-Line PK Leaf Page
- avg space util: 14896/16384 90%

### Order-Line Secondary Index Leaf Page
- avg space util: 10804/16384 65%

### Nonsplit Experiment Result

![ns_org_tps_size_per_time](https://user-images.githubusercontent.com/55489991/127618717-99438b22-cc3b-4e53-9611-365587a1bb9f.png)

![ns_org_running_waf](https://user-images.githubusercontent.com/55489991/127618740-088674e4-8300-4664-bc29-4d9af9f18876.png)

