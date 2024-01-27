/* Using Index - Part - II */
/* Index Compression */
/* Index Compression compress duplicate values, improves reading performance */
/* Best when the compressed columns have low cardinality (distinct) values */
--
/* Get the cardinality of the DELIVERY_TYPE column */
set linesize 180
set autot off
SELECT
    COUNT(*) TOTAL,
    COUNT(DISTINCT DELIVERY_TYPE) UNQ_DELIVERY_TYP
FROM
    ORDERS;
--
/*
    TOTAL UNQ_DELIVERY_TYP
---------- ----------------
   1352070                4
*/   
--   
/* Create uncompressed Index */
CREATE INDEX ORDERS_DELIVERYT_IX ON ORDERS (
    DELIVERY_TYPE
);
--
/* Obtain the size and no of leaf blocks of the new Index */
SELECT
    SUM(BYTES/1024) SIZE_IN_KB
FROM
    USER_EXTENTS
WHERE
    SEGMENT_NAME='ORDERS_DELIVERYT_IX';
--
/*
SIZE_IN_KB
----------
     31744   
*/     
--
col INDEX_NAME format a20
col COMPRESSION format a20
SELECT
    INDEX_NAME,
    LEAF_BLOCKS,
    COMPRESSION
FROM
    USER_INDEXES
WHERE
    INDEX_NAME='ORDERS_DELIVERYT_IX';
--
/*
INDEX_NAME           LEAF_BLOCKS COMPRESSION
-------------------- ----------- --------------------
ORDERS_DELIVERYT_IX         3777 DISABLED
*/
--
/* Run the following query and take note of the Plan */
--
set autot trace exp stat
SELECT /*+ INDEX( ORDERS ORDERS_DELIVERYT_IX) */
    ORDER_ID,
    ORDER_DATE,
    SALES_REP_ID,
    ORDER_TOTAL
FROM
    ORDERS
WHERE
    DELIVERY_TYPE='Collection';
set autot off
/* 
-----------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name                | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                     |   338K|    11M| 10457   (1)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| ORDERS              |   338K|    11M| 10457   (1)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | ORDERS_DELIVERYT_IX |   338K|       |   950   (1)| 00:00:01 |
-----------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("DELIVERY_TYPE"='Collection')
*/      
/* Rebuild the Index with Compress option */
/* Mention prefix_length after COMPRESS - For Non-Unique columns number of columns */
/* Mention prefix_length after COMPRESS - For Unique columns number of columns minus one */
ALTER INDEX ORDERS_DELIVERYT_IX REBUILD COMPRESS 1;
--
/* Obtain the size of the Index again */
SELECT
    SUM(BYTES/1024) KB
FROM
    USER_EXTENTS
WHERE
    SEGMENT_NAME='ORDERS_DELIVERYT_IX';
--
/*
KB
----------
     17408
*/     
--     
col INDEX_NAME format a20
SELECT
    INDEX_NAME,
    LEAF_BLOCKS,
    COMPRESSION
FROM
    USER_INDEXES
WHERE
    INDEX_NAME='ORDERS_DELIVERYT_IX';
--
/*
INDEX_NAME           LEAF_BLOCKS COMPRESSION
-------------------- ----------- --------------------
ORDERS_DELIVERYT_IX         2078 ENABLED
*/
--    
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
--
/* Run the Query again */
SET AUTOT TRACE EXP STAT
SELECT /*+ INDEX( ORDERS ORDERS_DELIVERYT_IX) */
    ORDER_ID,
    ORDER_DATE,
    SALES_REP_ID,
    ORDER_TOTAL
FROM
    ORDERS
WHERE
    DELIVERY_TYPE ='Collection';
--
set autot off    
--
/* The Cost has reduced by around 90% */
/*
-----------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name                | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                     |   338K|    11M| 10031   (1)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| ORDERS              |   338K|    11M| 10031   (1)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | ORDERS_DELIVERYT_IX |   338K|       |   524   (1)| 00:00:01 |
-----------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("DELIVERY_TYPE"='Collection')
*/      
--
/* Drop the Index */
DROP INDEX ORDERS_DELIVERYT_IX;
--
/* Implementing a Function-based Index */
--
/* Check the access path of the below query */
/* Order Date has an index named ORD_ORDER_DATE_IX but it is not used due to the function in predicate */
--
SET AUTOT TRACE EXP
SELECT
    *
FROM
    ORDERS
WHERE
    TO_CHAR(ORDER_DATE,
    'YYYY-MM')='2007-06';
set autot off      
--
/*
----------------------------------------------------------------------------
| Id  | Operation         | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |        | 13521 |  1161K|  4856   (1)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| ORDERS | 13521 |  1161K|  4856   (1)| 00:00:01 |
----------------------------------------------------------------------------
*/
--
/* Craete a Functional Index on ORDER_DATE */
--
CREATE INDEX ORDERS_YYYYMM_IX ON ORDERS (
    TO_CHAR(ORDER_DATE, 'YYYY-MM')
);
--
/* Run the same query and check access path */
--
SET AUTOT TRACE EXP
SELECT
    *
FROM
    ORDERS
WHERE
    TO_CHAR(ORDER_DATE,
    'YYYY-MM')='2007-06';
set autot off   
--
/*
--------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name             | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                  | 13521 |  1161K|   116   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| ORDERS           | 13521 |  1161K|   116   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | ORDERS_YYYYMM_IX |  5408 |       |    34   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------------------
*/
--
/* Drop the Index */
DROP INDEX ORDERS_YYYYMM_IX ;
--
--
/* Indexing a Virtual Column */
--
/* Indexing virtual column is an alternative solution to creating function based Index */
--
/* Add a Vairtual column to the Order Table */
ALTER TABLE ORDERS ADD (YEAR_MONTH GENERATED ALWAYS AS (TO_CHAR(ORDER_DATE, 'YYYY-MM')) VIRTUAL);
--
/* Check the definition of the virtual column */
--
col DATA_DEFAULT format a50
SELECT
    COLUMN_NAME,
    DATA_DEFAULT
FROM
    USER_TAB_COLUMNS
WHERE
    TABLE_NAME = 'ORDERS'
    AND COLUMN_NAME='YEAR_MONTH';
--
/* Create an Index on virtual column */
--
CREATE INDEX ORDERS_YM_IX ON ORDERS (YEAR_MONTH);
--
/* Display Virtual Column Index */
--
SET LONG 5000
SELECT
    INDEX_NAME,
    COLUMN_EXPRESSION
FROM
    USER_IND_EXPRESSIONS
WHERE
    INDEX_NAME='ORDERS_YM_IX';
--
/*
INDEX_NAME
--------------------------------------
COLUMN_EXPRESSION
--------------------------------------
ORDERS_YM_IX
TO_CHAR("ORDER_DATE",'YYYY-MM')    
*/
--
/* Run the query and see if the Index is used */
set autot trace exp
SELECT *
FROM ORDERS
WHERE TO_CHAR(ORDER_DATE,'YYYY-MM')='2012-05';
--
/*
----------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name         | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |              | 13521 |  1161K|   116   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| ORDERS       | 13521 |  1161K|   116   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | ORDERS_YM_IX |  5408 |       |    34   (0)| 00:00:01 |
----------------------------------------------------------------------------------------------------
*/    
--
/* Run the same query after a little modification */
SELECT *
FROM ORDERS
WHERE TO_CHAR(ORDER_DATE,'yyyy-mm')='2012-05';
set autot off   
--
/* The Index is not used any more because the condition must literally match */
/*
----------------------------------------------------------------------------
| Id  | Operation         | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |        | 13521 |  1161K|  4856   (1)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| ORDERS | 13521 |  1161K|  4856   (1)| 00:00:01 |
----------------------------------------------------------------------------
*/
/* Clean Up */
DROP INDEX ORDERS_YM_IX;
ALTER TABLE ORDERS DROP (YEAR_MONTH);
--
--
/* Using Invisible Indexes */
/* Invisible indexes are used to test the impact of an index before you make it available to users */
/* When an Index is invisible it is not used by the Optimizer */
--
/* Creating an Invisible */
--
set autot off
CREATE INDEX ORDERS_TOTAL_IX ON ORDERS (
    ORDER_TOTAL
) INVISIBLE;
--
/* Obtain information about Invisible Index */ 
SELECT
    INDEX_NAME,
    STATUS,
    VISIBILITY
FROM
    USER_INDEXES
WHERE
    INDEX_NAME='ORDERS_TOTAL_IX';
--
/* Run the following query and check if the Index is used */
--
set autot trace exp
SELECT
    *
FROM
    ORDERS
WHERE
    ORDER_TOTAL BETWEEN 14700
    AND 14800;
--
-- Query is not using the Index
/*
----------------------------------------------------------------------------
| Id  | Operation         | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |        |  3157 |   271K|  4838   (1)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| ORDERS |  3157 |   271K|  4838   (1)| 00:00:01 |
----------------------------------------------------------------------------
*/
--
/* 
Use the following hint and run the SQL 
an alternative solution is to set the parameter 
OPTIMIZER_USE_INVISIBLE_INDEXES to
TRUE at the session level.
*/
--
SELECT /*+ USE_INVISIBLE_INDEXES */
    *
FROM
    ORDERS
WHERE
    ORDER_TOTAL BETWEEN 14700
    AND 14800;
--
/*
-------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name            | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                 |  3157 |   271K|  3040   (1)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| ORDERS          |  3157 |   271K|  3040   (1)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | ORDERS_TOTAL_IX |  3157 |       |     9   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------------------
*/    
/* You can now make the index visible */
ALTER INDEX ORDERS_TOTAL_IX VISIBLE;
--
/* Run the same query again */
set autot trace exp
SELECT * FROM ORDERS WHERE ORDER_TOTAL BETWEEN 14700 AND 14800;
--
/* Drop Index */
DROP INDEX ORDERS_TOTAL_IX;
--
/* Index Suppression : Cases where Index will not be used by the Optimizer */
--
/* Run the following two queries */
/* First one will use index despite not equal operator because of COUNT(*) */
/* Second one will not use index because it's using not equal operator */
set autot trace exp
SELECT
    COUNT(*)
FROM
    EMP
WHERE
    EMP_NO <>634;
--
/*
--------------------------------------------------------------------------------
| Id  | Operation             | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------
|   0 | SELECT STATEMENT      |        |     1 |     4 |     2   (0)| 00:00:01 |
|   1 |  SORT AGGREGATE       |        |     1 |     4 |            |          |
|*  2 |   INDEX FAST FULL SCAN| EMP_PK |   878 |  3512 |     2   (0)| 00:00:01 |
--------------------------------------------------------------------------------
*/
SELECT
    ENAME
FROM
    EMP
WHERE
    EMP_NO <>634;
--
/*
--------------------------------------------------------------------------
| Id  | Operation         | Name | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |      |   878 | 17560 |     5   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| EMP  |   878 | 17560 |     5   (0)| 00:00:01 |
--------------------------------------------------------------------------
*/    
set autot off
CREATE INDEX EMP_MGR_IX ON EMP(MGR_ID);
--
/* Check if the following queries use the Index */
/* The query returns the employees who do not report to any manager */
--
set autot trace exp
SELECT
    *
FROM
    EMP
WHERE
    MGR_ID IS NULL;
--
SELECT /*+ INDEX(EMP EMP_MGR_IX) */
    *
FROM
    EMP
WHERE
    MGR_ID IS NULL;
--    
/* The index is not used since the query is referring to NULL value and Index cannot contain NULL */
/*
--------------------------------------------------------------------------
| Id  | Operation         | Name | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |      |     1 |    46 |     5   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| EMP  |     1 |    46 |     5   (0)| 00:00:01 |
--------------------------------------------------------------------------
*/
--
/* When Indexes are suppressed we can rewrite the WHERE predicate to use the Index */
/* This method does not require creation of Virtual column or Function-based Index */
--
set autot trace exp
SELECT * FROM ORDERS WHERE ORDER_DATE + 30 > TRUNC(SYSDATE);
--
/* The index, ORD_ORDER_DATE_IX, is not used since an expresssion is on the indexed column */
--
/*
----------------------------------------------------------------------------
| Id  | Operation         | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |        | 67604 |  5809K|  4923   (3)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| ORDERS | 67604 |  5809K|  4923   (3)| 00:00:01 |
----------------------------------------------------------------------------
*/
--
--
SELECT * FROM OE.ORDERS WHERE ORDER_DATE > TRUNC(SYSDATE) - 30;
--
/* The index, ORD_ORDER_DATE_IX, is used because the expression is shifted from the indexed column */
--
/*
---------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name              | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                   |     1 |    37 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| ORDERS            |     1 |    37 |     2   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | ORD_ORDER_DATE_IX |     1 |       |     1   (0)| 00:00:01 |
---------------------------------------------------------------------------------------------------------
*/
set autot off
--
set autot trace exp
SELECT * FROM HR.EMPLOYEES WHERE LAST_NAME LIKE '%K%';
--
/* Index is not used since the value is not provided to the LIKE operator */
/*
-------------------------------------------------------------------------------
| Id  | Operation         | Name      | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |           |     5 |   345 |     3   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| EMPLOYEES |     5 |   345 |     3   (0)| 00:00:01 |
-------------------------------------------------------------------------------
*/
--
SELECT * FROM HR.EMPLOYEES WHERE LAST_NAME LIKE '%K';
/*
-------------------------------------------------------------------------------
| Id  | Operation         | Name      | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |           |     5 |   345 |     3   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| EMPLOYEES |     5 |   345 |     3   (0)| 00:00:01 |
-------------------------------------------------------------------------------
*/
--
SELECT * FROM HR.EMPLOYEES WHERE LAST_NAME LIKE 'K%';
--
/* Index is used since the value is provided first to the LIKE operator */
/*
---------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name        | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |             |     5 |   345 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMPLOYEES   |     5 |   345 |     2   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | EMP_NAME_IX |     5 |       |     1   (0)| 00:00:01 |
---------------------------------------------------------------------------------------------------
*/
