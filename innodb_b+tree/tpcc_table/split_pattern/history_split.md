# Split on TPC-C History Table

## TPC-C Experiment on MySQL/InnoDB

### Settings

- DBMS : MySQL 5.6.26
- buffer: 10G
- warehouse: 2000W(200G)
- page size:4k
- connection: 20
- time: 10h

### Experiment Result 
<table style="text-align: center" >
  <tr style="text-align: center">
    <td colspan=4>History Table Split</td>
  </tr>
   <tr>
    <td>Insert byte #</td>
    <td>Split type</td>
    <td>Split method</td>
    <td>Split #</td>
  </tr>
  <tr>
    <td>23 byte</td>
    <td>sec idx(fkey_history_1) internal split</td>
    <td>middle rec split</td>
    <td>3 638</td>
  </tr>
  <tr>
    <td>19 byte-1</td>
    <td>sec idx(fkey_history_1) leaf split</td>
    <td>middle rec split</td>
    <td>297 073 (60%)</td>
  </tr>
  <tr>
    <td>19 byte-2</td>
    <td>sec idx(fkey_history_2) internal split</td>
    <td>midddle rec split</td>
    <td>1185</td>
  </tr>
  <tr>
    <td>15 byte</td>
    <td>sec idx(fkey_history_2) leaf split</td>
    <td>middle rec split</td>
    <td>69 924</td>
  </tr>
  <tr>
    <td>16 byte</td>
    <td>PK internal split</td>
    <td>rightmost split</td>
    <td>496</td>
  </tr>
  <tr>
    <td>n byte > 55</td>
    <td>PK leaf split</td>
    <td>rightmost split</td>
    <td>118 579</td>
  </tr>
  <tr>
    <td colspan=3>Total # Split</td>
    <td>490 895</td>
  </tr>
   <tr>
    <td colspan=3>history.ibd size</td>
    <td>8G -> 10G</td>
  </tr>
 </table>

## History Table

- tpcc-mysql/create_table.sql
```bash
create table history (
h_c_id int, 
h_c_d_id tinyint, 
h_c_w_id smallint,
h_d_id tinyint,
h_w_id smallint,
h_date datetime,
h_amount decimal(6,2), 
h_data varchar(24) ) Engine=InnoDB;
```

- tpcc-mysql/add_fkey_idx.sql
```bash
...
ALTER TABLE history  ADD CONSTRAINT fkey_history_1 FOREIGN KEY(h_c_w_id,h_c_d_id,h_c_id) REFERENCES customer(c_w_id,c_d_id,c_id);
ALTER TABLE history  ADD CONSTRAINT fkey_history_2 FOREIGN KEY(h_w_id,h_d_id) REFERENCES district(d_w_id,d_id);
```
- insert by payment.c
```bash
	/*EXEC_SQL INSERT INTO history(h_c_d_id, h_c_w_id, h_c_id, h_d_id,
			                   h_w_id, h_date, h_amount, h_data)
	                VALUES(:c_d_id, :c_w_id, :c_id, :d_id,
		               :w_id, 
			       :datetime,
			       :h_amount, :h_data);*/
```

## Split Details

### 15byte : sec_idx leaf page (fkey_history_2)
```bash
2021-03-25 17:47:26 25950 [Note] InnoDB: Before Split (15): original =  983417 / 254 / 1 / 0 / 0 / fkey_history_2

2021-03-25 17:47:26 25950 [Note] InnoDB: btr_page_split_and_insert: page_get_n_recs(page) > 1: Split (15): original =  983417 / 254 / 1 / 0 / 0 / fkey_history_2

2021-03-25 17:47:26 25950 [Note] InnoDB: After Split (15): original =  983417 / 127 / 1, new =  1910528 / 128 / 1

```
### 19byte: sec_idx internal page (fkey_history_2)
```bash
2021-03-25 17:47:26 25950 [Note] InnoDB: Before Split (19): original =  860829 / 202 / 0 / 0 / 0 / fkey_history_2

2021-03-25 17:47:26 25950 [Note] InnoDB: btr_page_split_and_insert: page_get_n_recs(page) > 1: Split (19): original =  860829 / 202 / 0 / 0 / 0 / fkey_history_2

2021-03-25 17:47:26 25950 [Note] InnoDB: After Split (19): original =  860829 / 102 / 0, new =  1600570 / 101 / 0

```
### 19byte: sec_idx leaf page (fkey_history_1)
```bash
2021-03-25 17:47:26 25950 [Note] InnoDB: Before Split (19): original =  1337733 / 202 / 1 / 0 / 0 / fkey_history_1

2021-03-25 17:47:26 25950 [Note] InnoDB: btr_page_split_and_insert: page_get_n_recs(page) > 1: Split (19): original =  1337733 / 202 / 1 / 0 / 0 / fkey_history_1

2021-03-25 17:47:26 25950 [Note] InnoDB: After Split (19): original =  1337733 / 101 / 1, new =  1913600 / 102 / 1
```

### 23byte: sec_idx internal page (fkey_history_1)
```bash
2021-03-25 17:47:26 25950 [Note] InnoDB: Before Split (23): original =  1054597 / 167 / 0 / 0 / 0 / fkey_history_1

2021-03-25 17:47:26 25950 [Note] InnoDB: btr_page_split_and_insert: page_get_n_recs(page) > 1: Split (23): original =  1054597 / 167 / 0 / 0 / 0 / fkey_history_1

2021-03-25 17:47:26 25950 [Note] InnoDB: After Split (23): original =  1054597 / 83 / 0, new =  1527446 / 85 / 0
```
### 16byte: PK internal page
```bash
2021-03-25 17:47:54 25950 [Note] InnoDB: Before Split (16): original =  1638773 / 240 / 0 / 1 / 0 / GEN_CLUST_INDEX

2021-03-25 17:47:54 25950 [Note] InnoDB: btr_page_get_split_rec_to_right: sequential inserts

2021-03-25 17:47:54 25950 [Note] InnoDB: btr_page_get_split_rec_to_right: sequential inserts: page_rec_is_supremum

2021-03-25 17:47:54 25950 [Note] InnoDB: btr_page_split_and_insert: btr_page_get_split_rec_to_right: Split (16): original =  1638773 / 240 / 0 / 1 / 0 / GEN_CLUST_INDEX

021-03-25 17:47:54 25950 [Note] InnoDB: After Split (16): original =  1638773 / 240 / 0, new =  1638774 / 1 / 0

```

### 57 < nbyte: PK leaf page
```bash
2021-03-25 17:47:26 25950 [Note] InnoDB: Before Split (58): original =  1619051 / 60 / 1 / 1 / 0 / GEN_CLUST_INDEX

2021-03-25 17:47:26 25950 [Note] InnoDB: btr_page_get_split_rec_to_right: sequential inserts

2021-03-25 17:47:26 25950 [Note] InnoDB: btr_page_get_split_rec_to_right: sequential inserts: page_rec_is_supremum

2021-03-25 17:47:26 25950 [Note] InnoDB: btr_page_split_and_insert: btr_page_get_split_rec_to_right: Split (58): original =  1619051 / 60 / 1 / 1 / 0 / GEN_CLUST_INDEX

2021-03-25 17:47:26 25950 [Note] InnoDB: After Split (58): original =  1619051 / 60 / 1, new =  1619052 / 1 / 1

```
