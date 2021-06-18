```bash
#0  0x00007ffff6946438 in __GI_raise (sig=sig@entry=6)
    at ../sysdeps/unix/sysv/linux/raise.c:54
#1  0x00007ffff694803a in __GI_abort () at abort.c:89
#2  0x0000000000b08fef in fil_io (type=type@entry=10, sync=sync@entry=true, 
    space_id=space_id@entry=57, zip_size=0, block_offset=1749741161, 
    byte_offset=0, len=4096, buf=0x7ffde3534000, message=0x7ffdcd07b200)
    at /home/lbh/mysql-5.6.26/storage/innobase/fil/fil0fil.cc:5617
#3  0x0000000000ad3920 in buf_read_page_low (mode=132, offset=1768842857, 
    tablespace_version=<optimized out>, unzip=0, zip_size=0, space=57, 
    sync=true, err=0x7ffa30389054)
    at /home/lbh/mysql-5.6.26/storage/innobase/buf/buf0rea.cc:191
#4  buf_read_page (space=space@entry=57, zip_size=zip_size@entry=0, 
    offset=offset@entry=1768842857)
    at /home/lbh/mysql-5.6.26/storage/innobase/buf/buf0rea.cc:411
#5  0x0000000000abac0a in buf_page_get_gen (space=space@entry=57, zip_size=zip_size@entry=0, offset=offset@entry=1768842857, rw_latch=rw_latch@entry=2, guess=<optimized out>, guess@entry=0x0, mode=<optimized out>, file=<optimized out>, line=<optimized out>, 
    mtr=<optimized out>) at /home/lbh/mysql-5.6.26/storage/innobase/buf/buf0buf.cc:2665
#6  0x0000000000aa1932 in btr_cur_search_to_nth_level (index=index@entry=0x7ffa10036e68, level=level@entry=0, tuple=tuple@entry=0x7ffa100f58e8, mode=mode@entry=4, latch_mode=<optimized out>, latch_mode@entry=514, cursor=cursor@entry=0x7ffa303896c0, 
    has_search_latch=0, file=0xd2ac60 "/home/lbh/mysql-5.6.26/storage/innobase/row/row0ins.cc", line=2648, mtr=0x7ffa30389820) at /home/lbh/mysql-5.6.26/storage/innobase/btr/btr0cur.cc:616
#7  0x0000000000a2d08e in row_ins_sec_index_entry_low (flags=flags@entry=0, mode=mode@entry=2, index=index@entry=0x7ffa10036e68, offsets_heap=<optimized out>, offsets_heap@entry=0x7ffa10105f70, heap=heap@entry=0x7ffa10101570, entry=entry@entry=0x7ffa100f58e8, 
    trx_id=<optimized out>, thr=<optimized out>) at /home/lbh/mysql-5.6.26/storage/innobase/row/row0ins.cc:2648
#8  0x0000000000a2f42d in row_ins_sec_index_entry (index=0x7ffa10036e68, entry=0x7ffa100f58e8, thr=0x7ffa1006c0f0) at /home/lbh/mysql-5.6.26/storage/innobase/row/row0ins.cc:2941
#9  0x0000000000a2f8af in row_ins_index_entry (thr=0x7ffa1006c0f0, entry=<optimized out>, index=<optimized out>) at /home/lbh/mysql-5.6.26/storage/innobase/row/row0ins.cc:2983
---Type <return> to continue, or q <return> to quit---return
#10 row_ins_index_entry_step (thr=0x7ffa1006c0f0, node=<optimized out>) at /home/lbh/mysql-5.6.26/storage/innobase/row/row0ins.cc:3058
#11 row_ins (thr=<optimized out>, node=<optimized out>) at /home/lbh/mysql-5.6.26/storage/innobase/row/row0ins.cc:3198
#12 row_ins_step (thr=thr@entry=0x7ffa1006c0f0) at /home/lbh/mysql-5.6.26/storage/innobase/row/row0ins.cc:3323
#13 0x0000000000a3ac27 in row_insert_for_mysql (mysql_rec=mysql_rec@entry=0x7ffa1006adb8 "\211\275\v", prebuilt=<optimized out>) at /home/lbh/mysql-5.6.26/storage/innobase/row/row0mysql.cc:1363
#14 0x00000000009b1791 in ha_innobase::write_row (this=0x7ffa1006aaf0, record=0x7ffa1006adb8 "\211\275\v") at /home/lbh/mysql-5.6.26/storage/innobase/handler/ha_innodb.cc:6633
#15 0x00000000005a3832 in handler::ha_write_row (this=0x7ffa1006aaf0, buf=0x7ffa1006adb8 "\211\275\v") at /home/lbh/mysql-5.6.26/sql/handler.cc:7273
#16 0x00000000006c7b05 in write_record (thd=0x14985a0, table=0x7ffa1006a200, info=0x7ffa3038a180, update=0x7ffa3038a200) at /home/lbh/mysql-5.6.26/sql/sql_insert.cc:1921
#17 0x00000000006cd9f1 in mysql_insert (thd=thd@entry=0x14985a0, table_list=0x7ffa10064aa0, fields=..., values_list=..., update_fields=..., update_values=..., duplic=DUP_ERROR, ignore=false) at /home/lbh/mysql-5.6.26/sql/sql_insert.cc:1072
#18 0x00000000006e6356 in mysql_execute_command (thd=thd@entry=0x14985a0) at /home/lbh/mysql-5.6.26/sql/sql_parse.cc:3448
#19 0x00000000006fc447 in Prepared_statement::execute (this=this@entry=0x7ffa100600c0, expanded_query=expanded_query@entry=0x7ffa3038b500, open_cursor=open_cursor@entry=false) at /home/lbh/mysql-5.6.26/sql/sql_prepare.cc:4056
#20 0x00000000006fc64a in Prepared_statement::execute_loop (this=0x7ffa100600c0, expanded_query=0x7ffa3038b500, open_cursor=<optimized out>, packet=<optimized out>, packet_end=<optimized out>) at /home/lbh/mysql-5.6.26/sql/sql_prepare.cc:3688
#21 0x00000000006fc950 in mysqld_stmt_execute (thd=thd@entry=0x14985a0, packet_arg=packet_arg@entry=0x8873aec1 "\t", packet_length=packet_length@entry=87) at /home/lbh/mysql-5.6.26/sql/sql_prepare.cc:2700
#22 0x00000000006e924b in dispatch_command (command=COM_STMT_EXECUTE, thd=0x14985a0, packet=0x8873aec1 "\t", packet_length=87) at /home/lbh/mysql-5.6.26/sql/sql_parse.cc:1283
#23 0x00000000006eb524 in do_command (thd=<optimized out>) at /home/lbh/mysql-5.6.26/sql/sql_parse.cc:1037
#24 0x00000000006aea75 in do_handle_one_connection (thd_arg=thd_arg@entry=0x14985a0) at /home/lbh/mysql-5.6.26/sql/sql_connect.cc:982
#25 0x00000000006aeac9 in handle_one_connection (arg=arg@entry=0x14985a0) at /home/lbh/mysql-5.6.26/sql/sql_connect.cc:898
#26 0x000000000098cfa0 in pfs_spawn_thread (arg=0x886b4380) at /home/lbh/mysql-5.6.26/storage/perfschema/pfs.cc:1860
#27 0x00007ffff75836ba in start_thread (arg=0x7ffa3038c700) at pthread_create.c:333
#28 0x00007ffff6a1851d in clone () at ../sysdeps/unix/sysv/linux/x86_64/clone.S:109
```
```bash
#0  0x00007ffff6946438 in __GI_raise (sig=sig@entry=6) at ../sysdeps/unix/sysv/linux/raise.c:54
#1  0x00007ffff694803a in __GI_abort () at abort.c:89
#2  0x0000000000b0908f in fil_io (type=type@entry=10, sync=sync@entry=true, space_id=space_id@entry=57, 
    zip_size=0, block_offset=1749738089, byte_offset=0, len=4096, buf=0x7ffdde076000, 
    message=0x7ffdcc889500) at /home/lbh/mysql-5.6.26/storage/innobase/fil/fil0fil.cc:5617
#3  0x0000000000ad39c0 in buf_read_page_low (mode=132, offset=1768842857, 
    tablespace_version=<optimized out>, unzip=0, zip_size=0, space=57, sync=true, err=0x7ffa30389054)
    at /home/lbh/mysql-5.6.26/storage/innobase/buf/buf0rea.cc:191
#4  buf_read_page (space=space@entry=57, zip_size=zip_size@entry=0, offset=offset@entry=1768842857)
    at /home/lbh/mysql-5.6.26/storage/innobase/buf/buf0rea.cc:411
#5  0x0000000000abacaa in buf_page_get_gen (space=space@entry=57, zip_size=zip_size@entry=0, 
    offset=offset@entry=1768842857, rw_latch=rw_latch@entry=2, guess=<optimized out>, guess@entry=0x0, 
---Type <return> to continue, or q <return> to quit---return
    mode=<optimized out>, file=<optimized out>, line=<optimized out>, mtr=<optimized out>)
    at /home/lbh/mysql-5.6.26/storage/innobase/buf/buf0buf.cc:2665
#6  0x0000000000aa19d2 in btr_cur_search_to_nth_level (index=index@entry=0x7ffa10036e68, 
    level=level@entry=0, tuple=tuple@entry=0x7ffa100f9088, mode=mode@entry=4, 
    latch_mode=<optimized out>, latch_mode@entry=514, cursor=cursor@entry=0x7ffa303896c0, 
    has_search_latch=0, file=0xd2ad00 "/home/lbh/mysql-5.6.26/storage/innobase/row/row0ins.cc", 
    line=2648, mtr=0x7ffa30389820) at /home/lbh/mysql-5.6.26/storage/innobase/btr/btr0cur.cc:616
#7  0x0000000000a2d08e in row_ins_sec_index_entry_low (flags=flags@entry=0, mode=mode@entry=2, 
    index=index@entry=0x7ffa10036e68, offsets_heap=<optimized out>, offsets_heap@entry=0x7ffa101098c0, 
    heap=heap@entry=0x7ffa100fd2a0, entry=entry@entry=0x7ffa100f9088, trx_id=<optimized out>, 
    thr=<optimized out>) at /home/lbh/mysql-5.6.26/storage/innobase/row/row0ins.cc:2648
#8  0x0000000000a2f42d in row_ins_sec_index_entry (index=0x7ffa10036e68, entry=0x7ffa100f9088, 
---Type <return> to continue, or q <return> to quit---return
    thr=0x7ffa1006c358) at /home/lbh/mysql-5.6.26/storage/innobase/row/row0ins.cc:2941
#9  0x0000000000a2f8af in row_ins_index_entry (thr=0x7ffa1006c358, entry=<optimized out>, 
    index=<optimized out>) at /home/lbh/mysql-5.6.26/storage/innobase/row/row0ins.cc:2983
#10 row_ins_index_entry_step (thr=0x7ffa1006c358, node=<optimized out>)
    at /home/lbh/mysql-5.6.26/storage/innobase/row/row0ins.cc:3058
#11 row_ins (thr=<optimized out>, node=<optimized out>)
    at /home/lbh/mysql-5.6.26/storage/innobase/row/row0ins.cc:3198
#12 row_ins_step (thr=thr@entry=0x7ffa1006c358)
    at /home/lbh/mysql-5.6.26/storage/innobase/row/row0ins.cc:3323
#13 0x0000000000a3ac27 in row_insert_for_mysql (mysql_rec=mysql_rec@entry=0x7ffa1006adb8 "\211\272\v", 
    prebuilt=<optimized out>) at /home/lbh/mysql-5.6.26/storage/innobase/row/row0mysql.cc:1363
#14 0x00000000009b1791 in ha_innobase::write_row (this=0x7ffa1006aaf0, 
---Type <return> to continue, or q <return> to quit---return
    ) at /home/lbh/mysql-5.6.26/storage/innobase/handler/ha_innodb.cc:6633
#15 0x00000000005a3832 in handler::ha_write_row (this=0x7ffa1006aaf0, buf=0x7ffa1006adb8 "\211\272\v") at /home/lbh/mysql-5.6.26/sql/handler.cc:7273
#16 0x00000000006c7b05 in write_record (thd=0x14985a0, table=0x7ffa1006a200, info=0x7ffa3038a180, update=0x7ffa3038a200) at /home/lbh/mysql-5.6.26/sql/sql_insert.cc:1921
#17 0x00000000006cd9f1 in mysql_insert (thd=thd@entry=0x14985a0, table_list=0x7ffa10064aa0, fields=..., values_list=..., update_fields=..., update_values=..., duplic=DUP_ERROR, ignore=false) at /home/lbh/mysql-5.6.26/sql/sql_insert.cc:1072
#18 0x00000000006e6356 in mysql_execute_command (thd=thd@entry=0x14985a0) at /home/lbh/mysql-5.6.26/sql/sql_parse.cc:3448
#19 0x00000000006fc447 in Prepared_statement::execute (this=this@entry=0x7ffa100600c0, expanded_query=expanded_query@entry=0x7ffa3038b500, open_cursor=open_cursor@entry=false) at /home/lbh/mysql-5.6.26/sql/sql_prepare.cc:4056
#20 0x00000000006fc64a in Prepared_statement::execute_loop (this=0x7ffa100600c0, expanded_query=0x7ffa3038b500, open_cursor=<optimized out>, packet=<optimized out>, packet_end=<optimized out>) at /home/lbh/mysql-5.6.26/sql/sql_prepare.cc:3688
#21 0x00000000006fc950 in mysqld_stmt_execute (thd=thd@entry=0x14985a0, packet_arg=packet_arg@entry=0x8873b221 "\t", packet_length=packet_length@entry=87) at /home/lbh/mysql-5.6.26/sql/sql_prepare.cc:2700
#22 0x00000000006e924b in dispatch_command (command=COM_STMT_EXECUTE, thd=0x14985a0, packet=0x8873b221 "\t", packet_length=87) at /home/lbh/mysql-5.6.26/sql/sql_parse.cc:1283
#23 0x00000000006eb524 in do_command (thd=<optimized out>) at /home/lbh/mysql-5.6.26/sql/sql_parse.cc:1037
#24 0x00000000006aea75 in do_handle_one_connection (thd_arg=thd_arg@entry=0x14985a0) at /home/lbh/mysql-5.6.26/sql/sql_connect.cc:982
#25 0x00000000006aeac9 in handle_one_connection (arg=arg@entry=0x14985a0) at /home/lbh/mysql-5.6.26/sql/sql_connect.cc:898
#26 0x000000000098cfa0 in pfs_spawn_thread (arg=0x886b46e0) at /home/lbh/mysql-5.6.26/storage/perfschema/pfs.cc:1860
#27 0x00007ffff75836ba in start_thread (arg=0x7ffa3038c700) at pthread_create.c:333
#28 0x00007ffff6a1851d in clone () at ../sysdeps/unix/sysv/linux/x86_64/clone.S:109
```
