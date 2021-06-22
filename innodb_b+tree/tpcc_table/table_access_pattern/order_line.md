# Access Patterns in Order_Line Table

## Table Access Patterns:
- U(x): uniform access
- A(x): x tuples are appended
- P(x): x tuples are selected, which were recently accessed by other transactions (temporal locality)

## Order_Line Table
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
 
## Data Load
### load.c
```bash
			    /*EXEC SQL INSERT INTO
				                order_line
				                values(:o_id,:o_d_id,:o_w_id,:ol,
						       :ol_i_id,:ol_supply_w_id, NULL,
						       :ol_quantity,:tmp_float,:ol_dist_info);*/
```
## Running Benchmark

### New Order Trx
- write: A(10)
```bash
		/*EXEC_SQL INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, 
						 ol_number, ol_i_id, 
						 ol_supply_w_id, ol_quantity, 
						 ol_amount, ol_dist_info)
			VALUES (:o_id, :d_id, :w_id, :ol_number, :ol_i_id,
				:ol_supply_w_id, :ol_quantity, :ol_amount,
				:ol_dist_info);*/
```
### Order Status Trx
- read: P(10)
- read by secondary index

```bash
	/*EXEC_SQL DECLARE c_items CURSOR FOR
		SELECT **ol_i_id, ol_supply_w_id,** ol_quantity, ol_amount, ol_delivery_d
		FROM order_line
	        WHERE ol_w_id = :c_w_id
		AND ol_d_id = :c_d_id
		AND ol_o_id = :o_id;*/
    
		/*EXEC_SQL FETCH c_items
			INTO :ol_i_id, :ol_supply_w_id, :ol_quantity,
			:ol_amount, :ol_delivery_d;*/
```
### Delivery Trx
- p(100)
- write: Update(100)
- read: Select(100)
```bash
		/*EXEC_SQL UPDATE order_line
		                SET ol_delivery_d = :datetime
		                WHERE ol_o_id = :no_o_id AND ol_d_id = :d_id AND
				ol_w_id = :w_id;*/
```
### Stock Level Trx
- read : P(200)
- read by secondary index
```bash
	/* find the most recent 20 orders for this district */
	/*EXEC_SQL DECLARE ord_line CURSOR FOR
	                SELECT DISTINCT **ol_i_id**
	                FROM order_line
	                WHERE ol_w_id = :w_id
			AND ol_d_id = :d_id
			AND ol_o_id < :d_next_o_id
			AND ol_o_id >= (:d_next_o_id - 20);

	EXEC_SQL OPEN ord_line;

	EXEC SQL WHENEVER NOT FOUND GOTO done;*/
```

## From the Point of Secondary Index B+Tree ...
- nonclustered key inserted by new order trx and never updated
- stock trx and order status reads from sec idx 


