# Order-Line Table Split 

## TPC-C Experiment on MySQL/InnoDB

### Settings

- DBMS : MySQL 5.6.26
- Origin(free space 6.25%) vs Tuned(free space 10%)
- buffer: 10G
- warehouse: 1000W(200G)
- page size:4k
- connection: 20

### Result for 48h

| Split type   | Vanilla | Non-Split 10%|
|:----------:|:-------------:|:-------------:|
|66 byte (delivery UPDATE)| 150,485 (2%)| 1,074 | 
|61 byte (new order INSERT)| 4,921,432 (67%)| 5,843,699  | 
|24 byte (internal page)| 23,815 |  25,481 | 
|20 byte (fkey_order_line_2)| 2,192,074 (30%)| 2,466,556  | 
|18 byte (internal page)| 71,365 |  70,430 | 
|total Order-Line split #| 7,359,171 (100%)| 8,407,240|
|TPS | 160 | 184|
|DB Size| 219 -> 268|221 -> 273|

### Result for 10h
| Split type   | Vanilla | Non-Split 10% | Non-Split 15%|
|:----------:|:-------------:|:-------------:|:-------------:|
|66 byte (delivery UPDATE)| 53 774| 0 | 0|
|61 byte (new order INSERT)| 1 160 462| 1 346 667  | 1 419 846|
|24 byte (internal page)| 6 963|  6 149 | 6 977|
|20 byte (fkey_order_line_2)|500 761| 557 311  | 553 647|
|18 byte (internal page)| 21 751 |  21 074 | 21 242|
|total Order-Line split #| 1 743 711| 1 931 201| 1 931 201|


## Order-Line Table Split

### Order-Line Table Structure

- Order-Line is a growing table
- 
- tpcc-mysql/create_table.sql
 ```bash
create table order_line (
	ol_o_id int not null,
	ol_d_id tinyint not null,
	ol_w_id smallint not null,
	ol_number tinyint not null,
	ol_i_id int,
	ol_supply_w_id smallint,
	ol_delivery_d datetime,
	ol_quantity tinyint,
	ol_amount decimal(6,2),
	ol_dist_info char(24),
	PRIMARY KEY(ol_w_id, ol_d_id, ol_o_id, ol_number) ) Engine=InnoDB ;
 ```
 - tpcc-mysql/add_fkey_idx.sql
 ```bash
...
CREATE INDEX fkey_order_line_2 ON order_line (ol_supply_w_id,ol_i_id);
...
ALTER TABLE order_line ADD CONSTRAINT fkey_order_line_1 FOREIGN KEY(ol_w_id,ol_d_id,ol_o_id) REFERENCES orders(o_w_id,o_d_id,o_id);
ALTER TABLE order_line ADD CONSTRAINT fkey_order_line_2 FOREIGN KEY(ol_supply_w_id,ol_i_id) REFERENCES stock(s_w_id,s_i_id);
 ```
## Split Type:
- Delivery trx UPDATE (66 byte):
- 61 byte:
- 20 byte:
- 24 byte:
- 18 byte:

### 66 byte: Delivery trx UPDATE

```bash
########## Before Split 1751313 ##########
#<Innodb::Page::Index:0x0000000132f388>:

fil header:
{:checksum=>363859215,
 :offset=>1751313,
 :prev=>1751312,
 :next=>1751314,
 :lsn=>48142964723,
 :type=>:INDEX,
 :flush_lsn=>0,
 :space_id=>12}

fil trailer:
{:checksum=>4266385322, :lsn_low32=>898324467}

page header:
{:n_dir_slots=>16,
 :heap_top=>3780,
 :garbage_offset=>0,
 :garbage_size=>0,
 :last_insert_offset=>3725,
 :direction=>:right,
 :n_direction=>59,
 :n_recs=>60,
 :max_trx_id=>0,
 :level=>0,
 :index_id=>28,
 :n_heap=>62,
 :format=>:compact}

fseg header:
{:leaf=>nil, :internal=>nil}

sizes:
  header           120
  trailer            8
  directory         32
  free             276
  used            3820
  record          3660
  per record     61.00

########## After Split 1751313 ##########
#<Innodb::Page::Index:0x0000000187a978>:

fil header:
{:checksum=>457189067,
 :offset=>1751313,
 :prev=>1751312,
 :next=>8598597,
 :lsn=>135332841864,
 :type=>:INDEX,
 :flush_lsn=>0,
 :space_id=>12}

fil trailer:
{:checksum=>3466983454, :lsn_low32=>2188855688}

page header:
{:n_dir_slots=>9,
 :heap_top=>3989,
 :garbage_offset=>2040,
 :garbage_size=>1955,
 :last_insert_offset=>0,
 :direction=>:right,
 :n_direction=>58,
 :n_recs=>29,
 :max_trx_id=>0,
 :level=>0,
 :index_id=>28,
 :n_heap=>61,
 :format=>:compact}

fseg header:
{:leaf=>nil, :internal=>nil}

sizes:
  header           120
  trailer            8
  directory         18
  free            2036
  used            2060
  record          1914
  per record     66.00

page directory:
[99, 324, 588, 852, 1116, 1380, 1644, 1908, 112]

```
### 61 byte : New Order trx INSERT

```bash
/*EXEC_SQL INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, 
				 ol_number, ol_i_id, 
				 ol_supply_w_id, ol_quantity, 
				 ol_amount, ol_dist_info)
	VALUES (:o_id, :d_id, :w_id, :ol_number, :ol_i_id,
		:ol_supply_w_id, :ol_quantity, :ol_amount,
		:ol_dist_info);*/
```

### ORIGIN:

```bash
########## Before Split 1119255 ##########
#<Innodb::Page::Index:0x000000015de6b0>:

fil header:
{:checksum=>4174380471,
 :offset=>1119255,
 :prev=>1119254,
 :next=>1119256,
 :lsn=>30783903950,
 :type=>:INDEX,
 :flush_lsn=>0,
 :space_id=>12}

fil trailer:
{:checksum=>3548367127, :lsn_low32=>719132878}

page header:
{:n_dir_slots=>15,
 :heap_top=>3778,
 :garbage_offset=>126,
 :garbage_size=>66,
 :last_insert_offset=>0,
 :direction=>:right,
 :n_direction=>56,
 :n_recs=>57,
 :max_trx_id=>0,
 :level=>0,
 :index_id=>28,
 :n_heap=>60,
 :format=>:compact}

fseg header:
{:leaf=>nil, :internal=>nil}

sizes:
  header           120
  trailer            8
  directory         30
  free             346
  used            3750
  record          3592
  per record     63.00

########## After Split 1119255 ##########
#<Innodb::Page::Index:0x0000000280ded0>:

fil header:
{:checksum=>1405956453,
 :offset=>1119255,
 :prev=>1119254,
 :next=>8591872,
 :lsn=>135121870749,
 :type=>:INDEX,
 :flush_lsn=>0,
 :space_id=>12}

fil trailer:
{:checksum=>2563061524, :lsn_low32=>1977884573}

page header:
{:n_dir_slots=>12,
 :heap_top=>3778,
 :garbage_offset=>3058,
 :garbage_size=>786,
 :last_insert_offset=>2992,
 :direction=>:right,
 :n_direction=>10,
 :n_recs=>47,
 :max_trx_id=>0,
 :level=>0,
 :index_id=>28,
 :n_heap=>60,
 :format=>:compact}

fseg header:
{:leaf=>nil, :internal=>nil}

sizes:
  header           120
  trailer            8
  directory         24
  free            1072
  used            3024
  record          2872
  per record     61.00

```
## 24 byte : internal split


```bash
########## Before Split 3507536 ##########
#<Innodb::Page::Index:0x00000002667568>:

fil header:
{:checksum=>3562222154,
 :offset=>3507536,
 :prev=>3507480,
 :next=>3507459,
 :lsn=>102102561547,
 :type=>:INDEX,
 :flush_lsn=>0,
 :space_id=>12}

fil trailer:
{:checksum=>1792382319, :lsn_low32=>3318313739}

page header:
{:n_dir_slots=>23,
 :heap_top=>3984,
 :garbage_offset=>0,
 :garbage_size=>0,
 :last_insert_offset=>3966,
 :direction=>:no_direction,
 :n_direction=>0,
 :n_recs=>161,
 :max_trx_id=>0,
 :level=>1,
 :index_id=>34,
 :n_heap=>163,
 :format=>:compact}

fseg header:
{:leaf=>nil, :internal=>nil}

sizes:
  header           120
  trailer            8
  directory         46
  free              58
  used            4038
  record          3864
  per record     24.00

########## After Split 3507536 ##########
#<Innodb::Page::Index:0x00000001a8f010>:

fil header:
{:checksum=>1910501960,
 :offset=>3507536,
 :prev=>3507480,
 :next=>7454343,
 :lsn=>135149265913,
 :type=>:INDEX,
 :flush_lsn=>0,
 :space_id=>12}

fil trailer:
{:checksum=>1265107060, :lsn_low32=>2005279737}

page header:
{:n_dir_slots=>12,
 :heap_top=>3984,
 :garbage_offset=>2526,
 :garbage_size=>1944,
 :last_insert_offset=>0,
 :direction=>:no_direction,
 :n_direction=>0,
 :n_recs=>80,
 :max_trx_id=>0,
 :level=>1,
 :index_id=>34,
 :n_heap=>163,
 :format=>:compact}

fseg header:
{:leaf=>nil, :internal=>nil}

sizes:
  header           120
  trailer            8
  directory         24
  free            2024
  used            2072
  record          1920
  per record     24.00
```

## 20 byte: fkey_order_line_2 / leaf 

### ORIGIN:

```bash
########## Before Split 7659060 ##########
#<Innodb::Page::Index:0x000000016706f0>:

fil header:
{:checksum=>2336888544,
 :offset=>7659060,
 :prev=>7659118,
 :next=>7659112,
 :lsn=>129921815105,
 :type=>:INDEX,
 :flush_lsn=>0,
 :space_id=>12}

fil trailer:
{:checksum=>2879051758, :lsn_low32=>1072796225}

page header:
{:n_dir_slots=>34,
 :heap_top=>3980,
 :garbage_offset=>3666,
 :garbage_size=>100,
 :last_insert_offset=>3266,
 :direction=>:no_direction,
 :n_direction=>0,
 :n_recs=>188,
 :max_trx_id=>23891,
 :level=>0,
 :index_id=>34,
 :n_heap=>195,
 :format=>:compact}

fseg header:
{:leaf=>nil, :internal=>nil}

sizes:
  header           120
  trailer            8
  directory         68
  free             140
  used            3956
  record          3760
  per record     20.00

########## After Split 7659060 ##########
#<Innodb::Page::Index:0x00000000bf86f0>:

fil header:
{:checksum=>390383528,
 :offset=>7659060,
 :prev=>7659118,
 :next=>7659186,
 :lsn=>135122226958,
 :type=>:INDEX,
 :flush_lsn=>0,
 :space_id=>12}

fil trailer:
{:checksum=>2362717488, :lsn_low32=>1978240782}

page header:
{:n_dir_slots=>17,
 :heap_top=>3980,
 :garbage_offset=>606,
 :garbage_size=>1960,
 :last_insert_offset=>586,
 :direction=>:no_direction,
 :n_direction=>0,
 :n_recs=>95,
 :max_trx_id=>25470,
 :level=>0,
 :index_id=>34,
 :n_heap=>195,
 :format=>:compact}

fseg header:
{:leaf=>nil, :internal=>nil}

sizes:
  header           120
  trailer            8
  directory         34
  free            2034
  used            2062
  record          1900
  per record     20.00
```

### 18 byte

before split
```bash
########## Before Split 8035948 ##########
#<Innodb::Page::Index:0x00000000a77088>:

fil header:
{:checksum=>2910901315,
 :offset=>8035948,
 :prev=>8035947,
 :next=>8035949,
 :lsn=>134009674649,
 :type=>:INDEX,
 :flush_lsn=>0,
 :space_id=>12}

fil trailer:
{:checksum=>3074977223, :lsn_low32=>865688473}

page header:
{:n_dir_slots=>54,
 :heap_top=>3972,
 :garbage_offset=>126,
 :garbage_size=>18,
 :last_insert_offset=>0,
 :direction=>:right,
 :n_direction=>212,
 :n_recs=>213,
 :max_trx_id=>0,
 :level=>1,
 :index_id=>28,
 :n_heap=>216,
 :format=>:compact}

fseg header:
{:leaf=>nil, :internal=>nil}

sizes:
  header           120
  trailer            8
  directory        108
  free              26
  used            4070
  record          3834
  per record     18.00


########## After Split 8035948 ##########
#<Innodb::Page::Index:0x0000000124eea0>:

fil header:
{:checksum=>1999141218,
 :offset=>8035948,
 :prev=>8035947,
 :next=>8591104,
 :lsn=>135121820123,
 :type=>:INDEX,
 :flush_lsn=>0,
 :space_id=>12}

fil trailer:
{:checksum=>3910895838, :lsn_low32=>1977833947}

page header:
{:n_dir_slots=>28,
 :heap_top=>3972,
 :garbage_offset=>2070,
 :garbage_size=>1926,
 :last_insert_offset=>2052,
 :direction=>:no_direction,
 :n_direction=>0,
 :n_recs=>107,
 :max_trx_id=>0,
 :level=>1,
 :index_id=>28,
 :n_heap=>216,
 :format=>:compact}

fseg header:
{:leaf=>nil, :internal=>nil}

sizes:
  header           120
  trailer            8
  directory         56
  free            1986
  used            2110
  record          1926
  per record     18.00

```

## Setup

Setup based on this page: [MySQL-5.7 TPC-C Order-Line table split](https://gist.github.com/meeeejin/e4630dc9e54bb85a7438c225ecaad743#file-no-fkey-results-md) and mijin herself

### B+Tree Changing Free Space only on Order-Line

- fil0fil.cc in /storage/innobase/fil/
```bash
	/* mijin */
	if (strcmp(node->name, "./tpcc2000/order_line.ibd") == 0) {
		srv_ol_space_id = space->id;
		fprintf(stderr, "setting %s to %lu\n", node->name, srv_ol_space_id);
	}
	fprintf(stderr, "%s = %lu\n", node->name, space->id);
	/* end */
```

- btr0cur.cc in /storage/innobase/btr/
```bash
...
/* mijin */
#include "srv0srv.h"
/*end*/

...

/*************************************************************//**
Tries to perform an insert to a page in an index tree, next to cursor.
It is assumed that mtr holds an x-latch on the page. The operation does
not succeed if there is too little space on the page. If there is just
one record on the page, the insert will always succeed; this is to
prevent trying to split a page with just one record.
@return	DB_SUCCESS, DB_WAIT_LOCK, DB_FAIL, or error number */
UNIV_INTERN
dberr_t
btr_cur_optimistic_insert(
/*======================*/
	ulint		flags,	/*!< in: undo logging and locking flags: if not
				zero, the parameters index and thr should be
				specified */
	btr_cur_t*	cursor,	/*!< in: cursor on page after which to insert;
				cursor stays valid */
	ulint**		offsets,/*!< out: offsets on *rec */
	mem_heap_t**	heap,	/*!< in/out: pointer to memory heap, or NULL */
	dtuple_t*	entry,	/*!< in/out: entry to insert */
	rec_t**		rec,	/*!< out: pointer to inserted record if
				succeed */
	big_rec_t**	big_rec,/*!< out: big rec vector whose fields have to
				be stored externally by the caller, or
				NULL */
	ulint		n_ext,	/*!< in: number of externally stored columns */
	que_thr_t*	thr,	/*!< in: query thread or NULL */
	mtr_t*		mtr)	/*!< in/out: mini-transaction;
				if this function returns DB_SUCCESS on
				a leaf page of a secondary index in a
				compressed tablespace, the caller must
				mtr_commit(mtr) before latching
				any further pages */
{

...

/* mijin */

	if (index->space == srv_ol_space_id) {
		if (leaf && !zip_size && dict_index_is_clust(index)
	    && page_get_n_recs(page) >= 2
	    && (dict_index_get_space_reserve() + rec_size) > max_size //(UNIV_PAGE_SIZE*3/20)
	    && (btr_page_get_split_rec_to_right(cursor, &dummy)
		|| btr_page_get_split_rec_to_left(cursor, &dummy))) {
		goto fail; 
	}
	/* end */

	} 
	else {
		if (leaf && !zip_size && dict_index_is_clust(index)
	    && page_get_n_recs(page) >= 2
	    && dict_index_get_space_reserve() + rec_size > max_size
	    && (btr_page_get_split_rec_to_right(cursor, &dummy)
		|| btr_page_get_split_rec_to_left(cursor, &dummy))) {
		goto fail;
	}

	}
	/* end */
```


## What I've Found Until Now...

- ``fkey_order_line_2`` leaf page split (20byte) better with middle page split than rightmost split
- free space 10% is enough


## Reference
- https://gist.github.com/meeeejin/e4630dc9e54bb85a7438c225ecaad743#file-no-fkey-results-md (mysql-5.7)
- https://meeeejin.github.io/posts/a-quick-introduction-to-innodb-ruby/
