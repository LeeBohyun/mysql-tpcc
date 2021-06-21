# Secondary Index Access in Order_Line Table

## Data Load
### load.c
```bash
			    /*EXEC SQL INSERT INTO
				                order_line
				                values(:o_id,:o_d_id,:o_w_id,:ol,
						       :ol_i_id,:ol_supply_w_id, NULL,
						       :ol_quantity,:tmp_float,:ol_dist_info);*/
```
## Run Benchmark


### Order Status Trx

```bash
	/*EXEC_SQL DECLARE c_items CURSOR FOR
		SELECT ol_i_id, ol_supply_w_id, ol_quantity, ol_amount,
                       ol_delivery_d
		FROM order_line
	        WHERE ol_w_id = :c_w_id
		AND ol_d_id = :c_d_id
		AND ol_o_id = :o_id;*/
    
		/*EXEC_SQL FETCH c_items
			INTO :ol_i_id, :ol_supply_w_id, :ol_quantity,
			:ol_amount, :ol_delivery_d;*/
```

### Stock Level Trx

### Delivery Trx
```bash
		/*EXEC_SQL UPDATE order_line
		                SET ol_delivery_d = :datetime
		                WHERE ol_o_id = :no_o_id AND ol_d_id = :d_id AND
				ol_w_id = :w_id;*/

		/*EXEC_SQL UPDATE order_line
		                SET ol_delivery_d = :datetime
		                WHERE ol_o_id = :no_o_id AND ol_d_id = :d_id AND
				ol_w_id = :w_id;*/
```

### New Order Trx

```bash
		/*EXEC_SQL INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, 
						 ol_number, ol_i_id, 
						 ol_supply_w_id, ol_quantity, 
						 ol_amount, ol_dist_info)
			VALUES (:o_id, :d_id, :w_id, :ol_number, :ol_i_id,
				:ol_supply_w_id, :ol_quantity, :ol_amount,
				:ol_dist_info);*/
```
