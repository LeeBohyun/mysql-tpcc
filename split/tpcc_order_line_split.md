# Order-Line Table Split 

## TPC-C Experiment on MySQL/InnoDB

### Settings

- DBMS : MySQL 5.6.26
- Origin(free space 6.25%) vs Tuned(free space 10%)
- buffer: 10G
- warehouse: 1000W(200G)
- page size:4k
- connection: 20
- time: 48h

### Result

| Split type   | Vanilla | Non-Split |
|:----------:|:-------------:|:-------------:|
|66 byte (delivery UPDATE)| 150,485 (2%)| 1,074 | 
|61 byte (new order INSERT)| 4,921,432 (67%)| 5,843,699  | 
|24 byte (internal page)| 23,815 |  25,481 | 
|20 byte (fkey_order_line_2)| 2,192,074 (30%)| 2,466,556  | 
|18 byte (internal page)| 71,365 |  70,430 | 
|total Order-Line split #| 7,359,171 (100%)| 8,407,240|
|TPS | 160 | 184|
|DB Size| 219 -> 268|221 -> 273|

## MySQL/InnoDB b+tree Split Algorithm

- mysql-5.6.26/storage/innobase/btr/btr0btr.cc : btr_page_split_and_insert()
```bash
/*************************************************************//**
Splits an index page to halves and inserts the tuple. It is assumed
that mtr holds an x-latch to the index tree. NOTE: the tree x-latch is
released within this function! NOTE that the operation of this
function must always succeed, we cannot reverse it: therefore enough
free disk space (2 pages) must be guaranteed to be available before
this function is called.

@return inserted record */
UNIV_INTERN
rec_t*
btr_page_split_and_insert(
/*======================*/
	ulint		flags,	/*!< in: undo logging and locking flags */
	btr_cur_t*	cursor,	/*!< in: cursor at which to insert; when the
				function returns, the cursor is positioned
				on the predecessor of the inserted record */
	ulint**		offsets,/*!< out: offsets on inserted record */
	mem_heap_t**	heap,	/*!< in/out: pointer to memory heap, or NULL */
	const dtuple_t*	tuple,	/*!< in: tuple to insert */
	ulint		n_ext,	/*!< in: number of externally stored columns */
	mtr_t*		mtr)	/*!< in: mtr */
	
```
0. try to insert to the next page if possible before split
1. Decide the split record
- (split_rec == NULL) means that the tuple to be inserted should be the first record on the upper half-page
	-  if (btr_page_get_split_rec_to_right(cursor, &split_rec)) : split at the current record near supremum (sequential insert)
	- else if (btr_page_get_split_rec_to_left(cursor, &split_rec)) : split at current record near infrimum
	- else : split at the middle record (page_get_middle_rec(page))
2. Allocate a new page to the index
3. Calculate the first record on the upper half-page, and the first record (move_limit) on original page which ends up on the upper half
4. Do first the modifications in the tree structure
5. Move then the records to the new page 
6. The split and the tree modification is now completed. Decide the page where the tuple should be inserted
7. Reposition the cursor for insert and try insertion
8. If insert did not fit, try page reorganization. For compressed pages, page_cur_tuple_insert() will have attempted this already
 
## Order-Line Table Split

### Order-Line Table Structure

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

- After Split

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

### ORIGIN:

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
### TUNED:
```bash
########## Before Split 8297780 ##########
#<Innodb::Page::Index:0x00000001219ed0>:

fil header:
{:checksum=>2702538639,
 :offset=>8297780,
 :prev=>8318108,
 :next=>8318916,
 :lsn=>135345957934,
 :type=>:INDEX,
 :flush_lsn=>0,
 :space_id=>12}

fil trailer:
{:checksum=>1706871241, :lsn_low32=>2201971758}

page header:
{:n_dir_slots=>34,
 :heap_top=>3980,
 :garbage_offset=>1946,
 :garbage_size=>100,
 :last_insert_offset=>2606,
 :direction=>:no_direction,
 :n_direction=>0,
 :n_recs=>188,
 :max_trx_id=>24189,
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

########## After Split 8297780 ##########
#<Innodb::Page::Index:0x000000015ff068>:

fil header:
{:checksum=>2140674822,
 :offset=>8297780,
 :prev=>8318108,
 :next=>8386162,
 :lsn=>135545611024,
 :type=>:INDEX,
 :flush_lsn=>0,
 :space_id=>12}

fil trailer:
{:checksum=>2308284478, :lsn_low32=>2401624848}

page header:
{:n_dir_slots=>17,
 :heap_top=>3980,
 :garbage_offset=>1206,
 :garbage_size=>1980,
 :last_insert_offset=>0,
 :direction=>:no_direction,
 :n_direction=>0,
 :n_recs=>94,
 :max_trx_id=>24189,
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
  free            2054
  used            2042
  record          1880
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
### TUNED
```bash
########## Before Split 4285699 ##########
#<Innodb::Page::Index:0x000000019c6ef8>:

fil header:
{:checksum=>354921205,
 :offset=>4285699,
 :prev=>4285698,
 :next=>4285700,
 :lsn=>125557675051,
 :type=>:INDEX,
 :flush_lsn=>0,
 :space_id=>12}

fil trailer:
{:checksum=>2367395871, :lsn_low32=>1003623467}

page header:
{:n_dir_slots=>54,
 :heap_top=>3972,
 :garbage_offset=>0,
 :garbage_size=>0,
 :last_insert_offset=>3960,
 :direction=>:right,
 :n_direction=>213,
 :n_recs=>214,
 :max_trx_id=>0,
 :level=>2,
 :index_id=>28,
 :n_heap=>216,
 :format=>:compact}

fseg header:
{:leaf=>nil, :internal=>nil}

sizes:
  header           120
  trailer            8
  directory        108
  free               8
  used            4088
  record          3852
  per record     18.00
  
########## After Split 4285699 ##########
#<Innodb::Page::Index:0x0000000158f150>:

fil header:
{:checksum=>3320972312,
 :offset=>4285699,
 :prev=>6143263,
 :next=>9607680,
 :lsn=>135744718688,
 :type=>:INDEX,
 :flush_lsn=>0,
 :space_id=>12}

fil trailer:
{:checksum=>1930609154, :lsn_low32=>2600732512}

page header:
{:n_dir_slots=>28,
 :heap_top=>3972,
 :garbage_offset=>2610,
 :garbage_size=>1368,
 :last_insert_offset=>2592,
 :direction=>:no_direction,
 :n_direction=>0,
 :n_recs=>138,
 :max_trx_id=>0,
 :level=>2,
 :index_id=>28,
 :n_heap=>216,
 :format=>:compact}

fseg header:
{:leaf=>nil, :internal=>nil}

sizes:
  header           120
  trailer            8
  directory         56
  free            1428
  used            2668
  record          2484
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

### B+Tree Split Monitoring
- btr0btr.cc in /storage/innobase/btr/

```bash
##############added code /* lbh */ or /* mijin */ ... /* end */##############
UNIV_INTERN
rec_t*
btr_page_split_and_insert{
...
	/* mijin : page split monitoring */

	if (buf_block_get_space(block) == srv_ol_space_id) {
		ib_logf(IB_LOG_LEVEL_INFO, "Before Split (%lu): original =  %lu / %lu / %d / %lu / %lu / %s\n", rec_get_converted_size(cursor->index, tuple, n_ext), buf_block_get_page_no(block), page_get_n_recs(page), page_is_leaf(page), dict_index_is_clust(cursor->index), dict_index_is_unique(cursor->index), cursor->index->name);
}
	/* end */

	page_no = buf_block_get_page_no(block);

	/* 1. Decide the split record; split_rec == NULL means that the
	tuple to be inserted should be the first record on the upper
	half-page */
	insert_left = FALSE;

	if (n_iterations > 0) {
		direction = FSP_UP;
		hint_page_no = page_no + 1;
		split_rec = btr_page_get_split_rec(cursor, tuple, n_ext);
		/* lbh */
		if(buf_block_get_space(block) == srv_ol_space_id){
			ib_logf(IB_LOG_LEVEL_INFO, "btr_page_split_and_insert: n_iterations > 0: Split (%lu): original =  %lu / %lu / %d / %lu / %lu / %s\n", rec_get_converted_size(cursor->index, tuple, n_ext), buf_block_get_page_no(block), page_get_n_recs(page), page_is_leaf(page), dict_index_is_clust(cursor->index), dict_index_is_unique(cursor->index), cursor->index->name);
		/* end */}

		if (split_rec == NULL) {
			insert_left = btr_page_tuple_smaller(
				cursor, tuple, offsets, n_uniq, heap);
		}
	} else if (btr_page_get_split_rec_to_right(cursor, &split_rec)) {
		direction = FSP_UP;
		hint_page_no = page_no + 1;

		/* lbh */
		if(buf_block_get_space(block) == srv_ol_space_id){
			ib_logf(IB_LOG_LEVEL_INFO, "btr_page_split_and_insert: btr_page_get_split_rec_to_right: Split (%lu): original =  %lu / %lu / %d / %lu / %lu / %s",rec_get_converted_size(cursor->index, tuple, n_ext), buf_block_get_page_no(block), page_get_n_recs(page), page_is_leaf(page), dict_index_is_clust(cursor->index), dict_index_is_unique(cursor->index), cursor->index->name);
		/* end */}
	} else if (btr_page_get_split_rec_to_left(cursor, &split_rec)) {
		direction = FSP_DOWN;
		hint_page_no = page_no - 1;

		/* lbh */
		if(buf_block_get_space(block) == srv_ol_space_id){
			ib_logf(IB_LOG_LEVEL_INFO, "btr_page_split_and_insert: btr_page_get_split_rec_to_left: Split (%lu): original =  %lu / %lu / %d / %lu / %lu / %s\n",rec_get_converted_size(cursor->index, tuple, n_ext), buf_block_get_page_no(block), page_get_n_recs(page), page_is_leaf(page), dict_index_is_clust(cursor->index), dict_index_is_unique(cursor->index), cursor->index->name);
		/* end */}
		ut_ad(split_rec);
	} else {
		direction = FSP_UP;
		hint_page_no = page_no + 1;

		/* If there is only one record in the index page, we
		cannot split the node in the middle by default. We need
		to determine whether the new record will be inserted
		to the left or right. */

		if (page_get_n_recs(page) > 1) {
			/* lbh */
			if(buf_block_get_space(block) == srv_ol_space_id && page_is_leaf(page)){
				ib_logf(IB_LOG_LEVEL_INFO, "btr_page_split_and_insert: page_get_n_recs(page) > 1: Split (%lu): original =  %lu / %lu / %d / %lu / %lu / %s\n",rec_get_converted_size(cursor->index, tuple, n_ext), buf_block_get_page_no(block), page_get_n_recs(page), page_is_leaf(page), dict_index_is_clust(cursor->index), dict_index_is_unique(cursor->index), cursor->index->name);

				
				//last_rec = page_rec_get_prev(page_get_supremum_rec(page));
				//last_last_rec = page_rec_get_prev(last_rec);
				//split_rec = page_rec_get_prev(last_last_rec);
				
				split_rec = page_get_middle_rec(page);
			}/* end */else{
				split_rec = page_get_middle_rec(page);
			}
		} else if (btr_page_tuple_smaller(cursor, tuple,
						  offsets, n_uniq, heap)) {
			split_rec = page_rec_get_next(
				page_get_infimum_rec(page));
		} else {
			split_rec = NULL;
		}
	}

	/* 2. Allocate a new page to the index */
	new_block = btr_page_alloc(cursor->index, hint_page_no, direction,
				   btr_page_get_level(page, mtr), mtr, mtr);
	new_page = buf_block_get_frame(new_block);
	new_page_zip = buf_block_get_page_zip(new_block);
	btr_page_create(new_block, new_page_zip, cursor->index,
			btr_page_get_level(page, mtr), mtr);

	/* 3. Calculate the first record on the upper half-page, and the
	first record (move_limit) on original page which ends up on the
	upper half */

	if (split_rec) {
		first_rec = move_limit = split_rec;

		*offsets = rec_get_offsets(split_rec, cursor->index, *offsets,
					   n_uniq, heap);

		insert_left = cmp_dtuple_rec(tuple, split_rec, *offsets) < 0;

		if (!insert_left && new_page_zip && n_iterations > 0) {
			/* If a compressed page has already been split,
			avoid further splits by inserting the record
			to an empty page. */
			split_rec = NULL;
			goto insert_empty;
		}
	} else if (insert_left) {
		ut_a(n_iterations > 0);
		first_rec = page_rec_get_next(page_get_infimum_rec(page));
		move_limit = page_rec_get_next(btr_cur_get_rec(cursor));
	} else {
insert_empty:
		ut_ad(!split_rec);
		ut_ad(!insert_left);
		buf = (byte*) mem_alloc(rec_get_converted_size(cursor->index,
							       tuple, n_ext));

		first_rec = rec_convert_dtuple_to_rec(buf, cursor->index,
						      tuple, n_ext);
		move_limit = page_rec_get_next(btr_cur_get_rec(cursor));
	}

	/* 4. Do first the modifications in the tree structure */

	btr_attach_half_pages(flags, cursor->index, block,
			      first_rec, new_block, direction, mtr);

	/* If the split is made on the leaf level and the insert will fit
	on the appropriate half-page, we may release the tree x-latch.
	We can then move the records after releasing the tree latch,
	thus reducing the tree latch contention. */

	if (split_rec) {
		insert_will_fit = !new_page_zip
			&& btr_page_insert_fits(cursor, split_rec,
						offsets, tuple, n_ext, heap);
	} else {
		if (!insert_left) {
			mem_free(buf);
			buf = NULL;
		}

		insert_will_fit = !new_page_zip
			&& btr_page_insert_fits(cursor, NULL,
						offsets, tuple, n_ext, heap);
	}

	if (insert_will_fit && page_is_leaf(page)
	    && !dict_index_is_online_ddl(cursor->index)) {

		mtr_memo_release(mtr, dict_index_get_lock(cursor->index),
				 MTR_MEMO_X_LOCK);
	}

	/* 5. Move then the records to the new page */
	if (direction == FSP_DOWN) {
		/*		fputs("Split left\n", stderr); */

		if (0
#ifdef UNIV_ZIP_COPY
		    || page_zip
#endif /* UNIV_ZIP_COPY */
		    || !page_move_rec_list_start(new_block, block, move_limit,
						 cursor->index, mtr)) {
			/* For some reason, compressing new_page failed,
			even though it should contain fewer records than
			the original page.  Copy the page byte for byte
			and then delete the records from both pages
			as appropriate.  Deleting will always succeed. */
			ut_a(new_page_zip);

			page_zip_copy_recs(new_page_zip, new_page,
					   page_zip, page, cursor->index, mtr);
			page_delete_rec_list_end(move_limit - page + new_page,
						 new_block, cursor->index,
						 ULINT_UNDEFINED,
						 ULINT_UNDEFINED, mtr);

			/* Update the lock table and possible hash index. */

			lock_move_rec_list_start(
				new_block, block, move_limit,
				new_page + PAGE_NEW_INFIMUM);

			btr_search_move_or_delete_hash_entries(
				new_block, block, cursor->index);

			/* Delete the records from the source page. */

			page_delete_rec_list_start(move_limit, block,
						   cursor->index, mtr);
		}

		left_block = new_block;
		right_block = block;

		lock_update_split_left(right_block, left_block);
	} else {
		/*		fputs("Split right\n", stderr); */

		if (0
#ifdef UNIV_ZIP_COPY
		    || page_zip
#endif /* UNIV_ZIP_COPY */
		    || !page_move_rec_list_end(new_block, block, move_limit,
					       cursor->index, mtr)) {
			/* For some reason, compressing new_page failed,
			even though it should contain fewer records than
			the original page.  Copy the page byte for byte
			and then delete the records from both pages
			as appropriate.  Deleting will always succeed. */
			ut_a(new_page_zip);

			page_zip_copy_recs(new_page_zip, new_page,
					   page_zip, page, cursor->index, mtr);
			page_delete_rec_list_start(move_limit - page
						   + new_page, new_block,
						   cursor->index, mtr);

			/* Update the lock table and possible hash index. */

			lock_move_rec_list_end(new_block, block, move_limit);

			btr_search_move_or_delete_hash_entries(
				new_block, block, cursor->index);

			/* Delete the records from the source page. */

			page_delete_rec_list_end(move_limit, block,
						 cursor->index,
						 ULINT_UNDEFINED,
						 ULINT_UNDEFINED, mtr);
		}

		left_block = block;
		right_block = new_block;

		lock_update_split_right(right_block, left_block);
	}

#ifdef UNIV_ZIP_DEBUG
	if (page_zip) {
		ut_a(page_zip_validate(page_zip, page, cursor->index));
		ut_a(page_zip_validate(new_page_zip, new_page, cursor->index));
	}
#endif /* UNIV_ZIP_DEBUG */

	/* At this point, split_rec, move_limit and first_rec may point
	to garbage on the old page. */

	/* 6. The split and the tree modification is now completed. Decide the
	page where the tuple should be inserted */

	if (insert_left) {
		insert_block = left_block;
	} else {
		insert_block = right_block;
	}

	/* 7. Reposition the cursor for insert and try insertion */
	page_cursor = btr_cur_get_page_cur(cursor);

	page_cur_search(insert_block, cursor->index, tuple,
			PAGE_CUR_LE, page_cursor);

	rec = page_cur_tuple_insert(page_cursor, tuple, cursor->index,
				    offsets, heap, n_ext, mtr);

#ifdef UNIV_ZIP_DEBUG
	{
		page_t*		insert_page
			= buf_block_get_frame(insert_block);

		page_zip_des_t*	insert_page_zip
			= buf_block_get_page_zip(insert_block);

		ut_a(!insert_page_zip
		     || page_zip_validate(insert_page_zip, insert_page,
					  cursor->index));
	}
#endif /* UNIV_ZIP_DEBUG */

	if (rec != NULL) {

		goto func_exit;
	}

	/* 8. If insert did not fit, try page reorganization.
	For compressed pages, page_cur_tuple_insert() will have
	attempted this already. */

	if (page_cur_get_page_zip(page_cursor)
	    || !btr_page_reorganize(page_cursor, cursor->index, mtr)) {

		goto insert_failed;
	}

	rec = page_cur_tuple_insert(page_cursor, tuple, cursor->index,
				    offsets, heap, n_ext, mtr);

	if (rec == NULL) {
		/* The insert did not fit on the page: loop back to the
		start of the function for a new split */
insert_failed:
		/* We play safe and reset the free bits */
		if (!dict_index_is_clust(cursor->index)) {
			ibuf_reset_free_bits(new_block);
			ibuf_reset_free_bits(block);
		}

		/* fprintf(stderr, "Split second round %lu\n",
		page_get_page_no(page)); */
		n_iterations++;
		ut_ad(n_iterations < 2
		      || buf_block_get_page_zip(insert_block));
		ut_ad(!insert_will_fit);

		goto func_start;
	}

func_exit:
	/* Insert fit on the page: update the free bits for the
	left and right pages in the same mtr */

	if (!dict_index_is_clust(cursor->index) && page_is_leaf(page)) {
		ibuf_update_free_bits_for_two_pages_low(
			buf_block_get_zip_size(left_block),
			left_block, right_block, mtr);
	}

#if 0
	fprintf(stderr, "Split and insert done %lu %lu\n",
		buf_block_get_page_no(left_block),
		buf_block_get_page_no(right_block));
#endif
	/* mijin */
	if (buf_block_get_space(block) == srv_ol_space_id) {
		ib_logf(IB_LOG_LEVEL_INFO, "After Split (%lu): original =  %lu / %lu / %d, new =  %lu / %lu / %d\n", rec_get_converted_size(cursor->index, tuple, n_ext), (ulint)buf_block_get_page_no(block), page_get_n_recs(page), page_is_leaf(page), (ulint)buf_block_get_page_no(new_block), page_get_n_recs(new_page), page_is_leaf(new_page));
	}
	/* end */

...
}
```

### mysql_ruby
```bash
lbh@lbh-Z170X-UD5:~/test_data1$ innodb_space -f tpcc1000/order_line.ibd space-indexes

id          name                            root        fseg        fseg_id     used        allocated   fill_factor 
28                                          3           internal    1           36073       41248       87.45%      
28                                          3           leaf        2           5437329     6214176     87.50%      
34                                          4           internal    3           20470       23583       86.80%      
34                                          4           leaf        4           2278982     2604576     87.50%   

```

## Reference
- https://gist.github.com/meeeejin/e4630dc9e54bb85a7438c225ecaad743#file-no-fkey-results-md (mysql-5.7)
- https://meeeejin.github.io/posts/a-quick-introduction-to-innodb-ruby/
