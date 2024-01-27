/* Using Index - Part - III */
/* Using Bitmap Index */
/* Comparative Analysis (Single equi-condition): B-Tree Index and Bitmap Index */
/* Size and Efficiency */
--
/* Create a B-Tree Index */
--
CREATE INDEX ORDERS_MODE_IX ON ORDERS(
    ORDER_MODE
);
--
/* Check B-Tree Index Size */
--
SELECT
    'Segment Name: ' || SEGMENT_NAME || ' - size: ' || ROUND(BYTES/1024) || '
KB' AS SEGMENT_SIZE
FROM
    USER_SEGMENTS
WHERE
    SEGMENT_NAME IN ('ORDERS',
    'ORDERS_MODE_IX');
/*

SEGMENT_SIZE
--------------------------------------------
Segment Name: ORDERS - size: 147456 KB

Segment Name: ORDERS_MODE_IX - size: 26624 KB
*/    
--
/* Run the following Query */
--
SET LINESIZE 180
SET AUTOT TRACE EXP STAT
SELECT 
    *
FROM
    ORDERS
WHERE
    ORDER_MODE = 'direct';
--
/*
------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name           | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                |   629K|    52M| 13838   (1)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| ORDERS         |   629K|    52M| 13838   (1)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | ORDERS_MODE_IX |   629K|       |  1589   (1)| 00:00:01 |
------------------------------------------------------------------------------------------------------
*/
SET AUTOT OFF
/* Drop B-Tree Index */
DROP INDEX ORDERS_MODE_IX;
--
/* Create a Bitmap Index on ORDER.ORDER_MODE column */
--
CREATE BITMAP INDEX ORDERS_MODE_BIX ON ORDERS(
    ORDER_MODE
);
--
SELECT
    'Segment Name: ' || SEGMENT_NAME || ' - size: ' || ROUND(BYTES/1024) || '
KB' AS SEGMENT_SIZE
FROM
    USER_SEGMENTS
WHERE
    SEGMENT_NAME IN ('ORDERS',
    'ORDERS_MODE_BIX');
--
/* Bitmap Index size is far lower than that of B-Tree Index */
/*
SEGMENT_SIZE
-------------------------------------------------
Segment Name: ORDERS - size: 147456 KB

Segment Name: ORDERS_MODE_BIX - size: 512 KB
*/
SET AUTOT TRACE EXP STAT
SELECT /*+ INDEX(ORDERS ORDERS_MODE_BIX)*/
    *
FROM
    ORDERS
WHERE
    ORDER_MODE = 'direct';
--
SET AUTOT OFF
/* We can see using B-Tree Index is more efficient than Bitmap Index when used with single equi-condition */
/*
-------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name            | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                 |   629K|    52M| 15079   (1)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| ORDERS          |   629K|    52M| 15079   (1)| 00:00:01 |
|   2 |   BITMAP CONVERSION TO ROWIDS       |                 |       |       |            |          |
|*  3 |    BITMAP INDEX SINGLE VALUE        | ORDERS_MODE_BIX |       |       |            |          |
-------------------------------------------------------------------------------------------------------
*/
--
/* Comparative Analysis (Multiple condition): B-Tree Index and Bitmap Index */
--
/* Create two more Bitmap Indexes on DELIVERY_TYPE AND CUSTOMER_CLASS columns */
--
DROP INDEX ORDERS_DT_IX;
--
DROP INDEX ORDERS_CC_IX;
--
DROP INDEX ORDERS_MODE_IX;
--
CREATE BITMAP INDEX ORDERS_DT_BIX ON ORDERS(
    DELIVERY_TYPE
);

CREATE BITMAP INDEX ORDERS_CC_BIX ON ORDERS(
    CUSTOMER_CLASS
);
--
CREATE BITMAP INDEX ORDERS_MODE_BIX ON ORDERS(
    ORDER_MODE
);
--
set autot trace exp
SELECT /*+ INDEX(ORDERS ORDERS_MODE_BIX ORDERS_DT_BIX ORDERS_CC_BIX) */
    *
FROM
    ORDERS
WHERE
    ORDER_MODE = 'direct'
    AND DELIVERY_TYPE='Express'
    AND CUSTOMER_CLASS='Occasional';
--
set autot off
--
/*
-------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name            | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                 |  7711 |   662K|  1404   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| ORDERS          |  7711 |   662K|  1404   (0)| 00:00:01 |
|   2 |   BITMAP CONVERSION TO ROWIDS       |                 |       |       |            |          |
|   3 |    BITMAP AND                       |                 |       |       |            |          |
|*  4 |     BITMAP INDEX SINGLE VALUE       | ORDERS_DT_BIX   |       |       |            |          |
|*  5 |     BITMAP INDEX SINGLE VALUE       | ORDERS_MODE_BIX |       |       |            |          |
|*  6 |     BITMAP INDEX SINGLE VALUE       | ORDERS_CC_BIX   |       |       |            |          |
-------------------------------------------------------------------------------------------------------
*/
/* Drop the Bitmap Index and create the following B-Tree Index on the same columns */
--
DROP INDEX ORDERS_MODE_BIX;
--
DROP INDEX ORDERS_DT_BIX;
--
DROP INDEX ORDERS_CC_BIX;
--
CREATE INDEX ORDERS_MODE_IX ON ORDERS(
    ORDER_MODE
);

CREATE INDEX ORDERS_DT_IX ON ORDERS(
    DELIVERY_TYPE
);

CREATE INDEX ORDERS_CC_IX ON ORDERS(
    CUSTOMER_CLASS
);
--
set autot trace exp
SELECT /*+ INDEX(ORDERS ORDERS_MODE_IX ORDERS_DT_IX ORDERS_CC_IX) */
    *
FROM
    ORDERS
WHERE
    ORDER_MODE = 'direct'
    AND DELIVERY_TYPE='Express'
    AND CUSTOMER_CLASS='Occasional';
--
set autot off
/* There is now significant improvement in cost of the plan when using Bitmap Index */
/*
----------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name         | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |              |  7711 |   662K|  2053   (1)| 00:00:01 |
|*  1 |  TABLE ACCESS BY INDEX ROWID BATCHED| ORDERS       |  7711 |   662K|  2053   (1)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | ORDERS_DT_IX | 66274 |       |   188   (0)| 00:00:01 |
----------------------------------------------------------------------------------------------------
*/
--
/* Drop Indexes - except DELIVERY TYPE index because it did exist even before */
--
DROP INDEX ORDERS_CC_IX;
--
DROP INDEX ORDERS_MODE_IX;
--
/* Using Bitmap Join Index */
--
/* Run the following query and observe its total cost in the output execution plan. */
--
set autot trace exp
SELECT
    ORDER_ID
FROM
    CUSTOMERS
    INNER JOIN ORDERS
    ON (CUSTOMERS.CUSTOMER_ID = ORDERS.CUSTOMER_ID)
WHERE
    CUST_FIRST_NAME LIKE 'malcom%';
/*
------------------------------------------------------------------------------------------------
| Id  | Operation                    | Name            | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT             |                 |   601 | 13823 |   499   (0)| 00:00:01 |
|   1 |  NESTED LOOPS                |                 |   601 | 13823 |   499   (0)| 00:00:01 |
|   2 |   NESTED LOOPS               |                 |   612 | 13823 |   499   (0)| 00:00:01 |
|*  3 |    TABLE ACCESS FULL         | CUSTOMERS       |     9 |   108 |   214   (1)| 00:00:01 |
|*  4 |    INDEX RANGE SCAN          | ORD_CUSTOMER_IX |    68 |       |     2   (0)| 00:00:01 |
|   5 |   TABLE ACCESS BY INDEX ROWID| ORDERS          |    68 |   748 |    70   (0)| 00:00:01 |
------------------------------------------------------------------------------------------------
*/
--
/* Create a bitmap join index on ORDERS and CUSTOMERS tables */
/* We consider ORDERS as fact table and CUSTOMERS as dimension table */
/* CUSTOMERS.CUST_FIRST_NAME is the key column of the Index. It must be from the Dimension table */
--
CREATE BITMAP INDEX ORDS_CUSTS_BIX ON ORDERS(
    CUSTOMERS.CUST_FIRST_NAME
) FROM ORDERS,
CUSTOMERS WHERE CUSTOMERS.CUSTOMER_ID = ORDERS.CUSTOMER_ID;
--
/* Run the query again to get the cost */
set autot trace exp
SELECT
    ORDER_ID
FROM
    CUSTOMERS
    INNER JOIN ORDERS
    ON (CUSTOMERS.CUSTOMER_ID = ORDERS.CUSTOMER_ID)
WHERE
    CUST_FIRST_NAME LIKE 'malcom%';
--    
/* More than 7 times reduction in cost as the customer is not accessed at all */
/*
------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name           | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                |   263 |  2893 |    60   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| ORDERS         |   263 |  2893 |    60   (0)| 00:00:01 |
|   2 |   BITMAP CONVERSION TO ROWIDS       |                |       |       |            |          |
|*  3 |    BITMAP INDEX RANGE SCAN          | ORDS_CUSTS_BIX |       |       |            |          |
------------------------------------------------------------------------------------------------------
*/    
/* Drop Index */
DROP INDEX ORDS_CUSTS_BIX;
--
/* Bitmap Join Index: Partial Use */
--
/* Run the following query and observe the cost */
--
set autot trace exp
SELECT
    ORDER_ID,
    ORDERS.CUSTOMER_ID,
    ORDER_TOTAL,
    CUST_FIRST_NAME,
    CUST_LAST_NAME
FROM
    CUSTOMERS
    INNER JOIN ORDERS
    ON (CUSTOMERS.CUSTOMER_ID = ORDERS.CUSTOMER_ID)
WHERE
    CUST_FIRST_NAME LIKE 'malcom%'
    AND ORDER_DATE BETWEEN TO_DATE('01-01-2007',
    'DD-MM-YYYY')
    AND TO_DATE('31-12-
2007',
    'DD-MM-YYYY');
--
/*
-------------------------------------------------------------------------------------------------
| Id  | Operation                     | Name            | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT              |                 |     1 |    47 |   499   (0)| 00:00:01 |
|*  1 |  FILTER                       |                 |       |       |            |          |
|   2 |   NESTED LOOPS                |                 |     1 |    47 |   499   (0)| 00:00:01 |
|   3 |    NESTED LOOPS               |                 |   612 |    47 |   499   (0)| 00:00:01 |
|*  4 |     TABLE ACCESS FULL         | CUSTOMERS       |     9 |   180 |   214   (1)| 00:00:01 |
|*  5 |     INDEX RANGE SCAN          | ORD_CUSTOMER_IX |    68 |       |     2   (0)| 00:00:01 |
|*  6 |    TABLE ACCESS BY INDEX ROWID| ORDERS          |     1 |    27 |    70   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------------
*/
--
/* Create a Bitmpa Join Index */
--
CREATE BITMAP INDEX ORDS_CUSTS_BIX ON ORDERS(
    CUSTOMERS.CUST_FIRST_NAME
) FROM ORDERS,
CUSTOMERS WHERE CUSTOMERS.CUSTOMER_ID = ORDERS.CUSTOMER_ID; 
--
/* Run the query again - the query does refer to columns in facts and dimension */
/* tables which are not referenced in the Bitmap Index */
--
set autot trace exp
SELECT
    ORDER_ID,
    ORDERS.CUSTOMER_ID,
    ORDER_TOTAL,
    CUST_FIRST_NAME,
    CUST_LAST_NAME
FROM
    CUSTOMERS
    INNER JOIN ORDERS
    ON (CUSTOMERS.CUSTOMER_ID = ORDERS.CUSTOMER_ID)
WHERE
    CUST_FIRST_NAME LIKE 'malcom%'
    AND ORDER_DATE BETWEEN TO_DATE('01-01-2007',
    'DD-MM-YYYY')
    AND TO_DATE('31-12-
2007',
    'DD-MM-YYYY');
--
/* You can observe that the query is using Bitmap Index partially and accessing the B-Tree index also */
/*
---------------------------------------------------------------------------------------------------------
| Id  | Operation                              | Name           | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                       |                |     1 |    47 |    61   (0)| 00:00:01 |
|*  1 |  FILTER                                |                |       |       |            |          |
|   2 |   NESTED LOOPS                         |                |     1 |    47 |    61   (0)| 00:00:01 |
|   3 |    NESTED LOOPS                        |                |     1 |    47 |    61   (0)| 00:00:01 |
|*  4 |     TABLE ACCESS BY INDEX ROWID BATCHED| ORDERS         |     1 |    27 |    60   (0)| 00:00:01 |
|   5 |      BITMAP CONVERSION TO ROWIDS       |                |       |       |            |          |
|*  6 |       BITMAP INDEX RANGE SCAN          | ORDS_CUSTS_BIX |       |       |            |          |
|*  7 |     INDEX UNIQUE SCAN                  | CUSTOMERS_PK   |     1 |       |     0   (0)| 00:00:01 |
|*  8 |    TABLE ACCESS BY INDEX ROWID         | CUSTOMERS      |     1 |    20 |     1   (0)| 00:00:01 |
---------------------------------------------------------------------------------------------------------
*/    
--
/* Drop Index */
DROP INDEX ORDS_CUSTS_BIX;
--
