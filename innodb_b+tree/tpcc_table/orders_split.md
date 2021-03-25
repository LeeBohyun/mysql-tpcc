# B+Tree Split in TPC-C NEW-ORDER Table

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
    <td colspan=4>Order Table Split</td>
  </tr>
   <tr>
    <td>Insert byte #</td>
    <td>Split type</td>
    <td>Split method</td>
    <td>Split #</td>
  </tr>
  <tr>
    <td>17 byte-1</td>
    <td>sec idx leaf split</td>
    <td>middle rec split</td>
    <td>41 489 (30%)</td>
  </tr>
  <tr>
    <td>17 byte-2</td>
    <td>PK internal split</td>
    <td>left rec split</td>
    <td>4</td>
  </tr>
  <tr>
    <td>37 byte</td>
    <td>primary key leaf split</td>
    <td>rightmost split</td>
    <td>96 334 (70%)</td>
  </tr>
  <tr>
    <td>38 byte</td>
    <td>primary key leaf split</td>
    <td>rightmost split</td>
    <td>764</td>
  </tr>
  <tr>
    <td>21 byte</td>
    <td>sec_idx internal split</td>
    <td>middle rec split</td>
    <td>7</td>
  </tr>
  <tr>
    <td colspan=3>Total # Split</td>
    <td>138 594</td>
  </tr>
   <tr>
    <td colspan=3>orders.ibd size</td>
    <td>6.9G -> 7.5G</td>
  </tr>
 </table>

## New-Order Table

- tpcc-mysql/create_table.sql
```bash
create table orders (
o_id int not null, 
o_d_id tinyint not null, 
o_w_id smallint not null,
o_c_id int,
o_entry_d datetime,
o_carrier_id tinyint,
o_ol_cnt tinyint, 
o_all_local tinyint,
PRIMARY KEY(o_w_id, o_d_id, o_id) ) Engine=InnoDB ;
```

- tpcc-mysql/add_fkey_idx.sql
```bash
...
CREATE INDEX idx_orders ON orders (o_w_id,o_d_id,o_c_id,o_id);
...
ALTER TABLE orders ADD CONSTRAINT fkey_orders_1 FOREIGN KEY(o_w_id,o_d_id,o_c_id) REFERENCES customer(c_w_id,c_d_id,c_id);

```
## Insert by New-Order Transaction

- tpcc-mysql/src/neword.c
```bash
...
	/*EXEC_SQL INSERT INTO orders (o_id, o_d_id, o_w_id, o_c_id,
			             o_entry_d, o_ol_cnt, o_all_local)
		VALUES(:o_id, :d_id, :w_id, :c_id, 
		       :datetime,
                       :o_ol_cnt, :o_all_local);*/

...
```

## Split Type and Query

### 17 byte-1 : sec_idx / leaf

```bash
[Note] InnoDB: Before Split (17): original =  310158 / 220 / 1 / 0 / 0 / idx_orders
[Note] InnoDB: btr_page_split_and_insert: page_get_n_recs(page) > 1: Split (17): original =  310158 / 220 / 1 / 0 / 0 / idx_orders
[Note] InnoDB: After Split (17): original =  310158 / 110 / 1, new =  1680011 / 111 / 1
```
### 17 byte-2 : PK / internal
```bash
[Note] InnoDB: Before Split (17): original =  584 / 226 / 0 / 1 / 2 / PRIMARY
[Note] InnoDB: btr_page_split_and_insert: btr_page_get_split_rec_to_left: Split (17): original =  584 / 226 / 0 / 1 / 2 / PRIMARY
[Note] InnoDB: After Split (17): original =  584 / 216 / 0, new =  1253004 / 11 / 0
```
### 21 byte : sec_idx / internal
```bash
[Note] InnoDB: Before Split (21): original =  998943 / 184 / 0 / 0 / 0 / idx_orders
[Note] InnoDB: btr_page_split_and_insert: page_get_n_recs(page) > 1: Split (21): original =  998943 / 184 / 0 / 0 / 0 / idx_orders
[Note] InnoDB: After Split (21): original =  998943 / 92 / 0, new =  1061953 / 93 / 0
```

### 37 byte: PK /leaf
```bash
[Note] InnoDB: Before Split (37): original =  1621563 / 98 / 1 / 1 / 2 / PRIMARY
[Note] InnoDB: btr_page_get_split_rec_to_right: sequential inserts
[Note] InnoDB: btr_page_split_and_insert: btr_page_get_split_rec_to_right: Split (37): original =  1621563 / 98 / 1 / 1 / 2 / PRIMARY
[Note] InnoDB: After Split (37): original =  1621563 / 96 / 1, new =  1690640 / 3 / 1
```

### 38 byte: PK / leaf
```bash
[Note] InnoDB: Before Split (38): original =  1270623 / 102 / 1 / 1 / 2 / PRIMARY
[Note] InnoDB: btr_page_split_and_insert: btr_page_get_split_rec_to_left: Split (38): original =  1270623 / 102 / 1 / 1 / 2 / PRIMARY
[Note] InnoDB: After Split (38): original =  1270623 / 3 / 1, new =  1571186 / 100 / 1
```
