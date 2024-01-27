/* Section 15: Working with Tables for Performance */
/* Studying the Impact of Excess Blocks */
--connect as tkyte
/* Create test data */
/* Inserting rows into a table with PCTFREE equals to 80 makes 
/* the table blocks having high percentage of free space. */
--
/* In real life this could happen as a result of inserting rows using 
/* direct path load followed by deletions and batch deletions */
--
CREATE TABLE customers2
PCTFREE 80 PCTUSED 10
    AS
        SELECT
            *
        FROM
            customers;

EXEC dbms_stats.gather_table_stats(user, 'CUSTOMERS2', method_opt => 'FOR ALL COLUMNS SIZE SKEWONLY');
--
/* Retrieve the number of blocks in the table */
set autot off
SELECT
    blocks,
    empty_blocks
FROM
    user_tables
WHERE
    table_name = 'CUSTOMERS2';
--
    BLOCKS EMPTY_BLOCKS
---------- ------------
      3498            0    
--
/* observe the the total cost and 'consistent gets' */
--
set echo on
set autot trace
SELECT
    c.customer_id,
    cust_first_name,
    cust_last_name,
    order_id,
    order_date,
    order_mode,
    order_total,
    order_status
FROM
    customers2 c,
    orders
WHERE
        c.customer_id = orders.customer_id
    AND cust_last_name LIKE 'winkler%'
ORDER BY
    c.customer_id,
    order_date;
--
-- consistent gets = 4170 
Statistics
----------------------------------------------------------
        172  recursive calls
         17  db block gets
       4170  consistent gets
        421  physical reads
       3228  redo size
      13994  bytes sent via SQL*Net to client
        938  bytes received via SQL*Net from client
         29  SQL*Net roundtrips to/from client
         22  sorts (memory)
          0  sorts (disk)
        411  rows processed    
--
set autotrace off
--
/* Set the PCTFREE of the table to 10 then reorganize the table. */
/* If the table had indexes, it would have to be rebuilt after re-organizing the table. */
--
ALTER TABLE CUSTOMERS2 PCTFREE 10;
--
ALTER TABLE CUSTOMERS2 MOVE;
--
exec DBMS_STATS.GATHER_TABLE_STATS(USER,'CUSTOMERS2', METHOD_OPT => 'FOR ALL COLUMNS SIZE SKEWONLY');
--
/* The table has now fewer blocks. */
--
SELECT
    blocks,
    empty_blocks
FROM
    user_tables
WHERE
    table_name = 'CUSTOMERS2';
--
-- number of blocks significantly reduced
--
    BLOCKS EMPTY_BLOCKS
---------- ------------
       753            0
--
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
/* Re-run the same query and observe the the total cost and 'consistent gets', 
/* and compare them to the figures noted earlier. */
--
set echo on
set autot trace
SELECT
    c.customer_id,
    cust_first_name,
    cust_last_name,
    order_id,
    order_date,
    order_mode,
    order_total,
    order_status
FROM
    customers2 c,
    orders
WHERE
        c.customer_id = orders.customer_id
    AND cust_last_name LIKE 'winkler%'
ORDER BY
    c.customer_id,
    order_date;
--
-- consistent gets has now reduced by more than 100% to 1947
--
Statistics
----------------------------------------------------------
        380  recursive calls
          0  db block gets
       1947  consistent gets
       1225  physical reads
          0  redo size
      13994  bytes sent via SQL*Net to client
        938  bytes received via SQL*Net from client
         29  SQL*Net roundtrips to/from client
         92  sorts (memory)
          0  sorts (disk)
        411  rows processed    
--
set autotrace off
--
/* Clean Up */
DROP TABLE CUSTOMERS2 PURGE;
--
--
/* Impact of Compression and Direct Path Loading */
--
--
/* Create the following three testing tables, T1,T2 and T3 */
/* T1 does not have the compression enabled. T2 and T3 do have their compression enabled. */
--
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
--
DROP TABLE T1 PURGE;
DROP TABLE T2 PURGE;
DROP TABLE T3 PURGE;
--
CREATE TABLE t1
    AS
        SELECT
            *
        FROM
            user_objects
        WHERE
            1 = 2;
--
CREATE TABLE t2
COMPRESS
    AS
        SELECT
            *
        FROM
            user_objects
        WHERE
            1 = 2;
--
CREATE TABLE t3
COMPRESS
    AS
        SELECT
            *
        FROM
            user_objects
        WHERE
            1 = 2;
--
/* Populate the tables with rows as follows. Compare between the time taken by each INSERT */
--
set autot off
set timing on
INSERT INTO t1
    SELECT
        a.*
    FROM
        user_objects a,
        user_objects b,
        user_objects c,
        (
            SELECT
                1
            FROM
                dual
            CONNECT BY
                level <= 20
        )            d;
--
5492500 rows created.
Elapsed: 00:00:32.64
--        
set timing off
COMMIT;
--
set timing on
INSERT INTO t2
    SELECT
        *
    FROM
        t1;
set timing off
COMMIT;
--
5492500 rows created.
Elapsed: 00:00:36.72
--
set timing on
INSERT /*+ APPEND */ INTO t3
    SELECT
        *
    FROM
        t1;
--
set timing off
COMMIT;
--
5492500 rows created.
Elapsed: 00:00:06.84
--
/* gather table stats */
--
exec DBMS_STATS.GATHER_TABLE_STATS(USER,'T1');
exec DBMS_STATS.GATHER_TABLE_STATS(USER,'T2');
exec DBMS_STATS.GATHER_TABLE_STATS(USER,'T3');
--
/* In the following commands, you will run three code blocks. */
/* Each code block retrieves the same data from each table. */
/* note the output statistics */
--
/* observe that the data retrieved from T3 with much less time 
/* than the other tables, fewer "consistent gets" and fewer "physical reads". */
/* Retrieving from T2 was a little bit better than retrieving the data from T1. */
--
/* Compressed table populated with direct path loading method provides performance gain in retrieving the data*/
--
-- code block 1: Table T1 (non-compressed and loaded with conventional method)
--
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
--
SET TIMING ON
SET AUTOT TRACE STAT
SELECT
    COUNT(*)
FROM
    t1;
--
SET AUTOT OFF
SET TIMING OFF
--
Elapsed: 00:00:01.34

Statistics
----------------------------------------------------------
        189  recursive calls
          0  db block gets
      81548  consistent gets
      81283  physical reads
          0  redo size
        361  bytes sent via SQL*Net to client
        353  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
         43  sorts (memory)
          0  sorts (disk)
          1  rows processed
--
-- code block 2: Table T2 (compressed and loaded with conventional method)
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
--
SET TIMING ON
SET AUTOT TRACE STAT
SELECT
    COUNT(*)
FROM
    t2;
--
SET AUTOT OFF
SET TIMING OFF
--
Elapsed: 00:00:01.18

Statistics
----------------------------------------------------------
        176  recursive calls
          0  db block gets
      73388  consistent gets
      73123  physical reads
          0  redo size
        361  bytes sent via SQL*Net to client
        353  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
         43  sorts (memory)
          0  sorts (disk)
          1  rows processed
--
-- code block 3 Table T3 (compressed and loaded with direct loading method)
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
SET TIMING ON
SET AUTOT TRACE STAT
SELECT
    COUNT(*)
FROM
    t3;
--
set autot off
set timing off
--
Elapsed: 00:00:00.24

Statistics
----------------------------------------------------------
        176  recursive calls
          0  db block gets
       8121  consistent gets
       7852  physical reads
          0  redo size
        361  bytes sent via SQL*Net to client
        353  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
         43  sorts (memory)
          0  sorts (disk)
          1  rows processed
--
/* clean up */
DROP TABLE T1 PURGE;
DROP TABLE T2 PURGE;
DROP TABLE T3 PURGE;
