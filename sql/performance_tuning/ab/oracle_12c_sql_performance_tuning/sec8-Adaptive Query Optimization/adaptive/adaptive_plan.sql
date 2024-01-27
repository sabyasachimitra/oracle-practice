SELECT NUM_ROWS, BLOCKS, LAST_ANALYZED FROM DBA_TAB_STATISTICS WHERE OWNER = USER AND TABLE_NAME='COUNTRIES';
--
SELECT NUM_ROWS, BLOCKS, LAST_ANALYZED FROM DBA_TAB_STATISTICS WHERE OWNER = USER AND TABLE_NAME='SALES';
--
SELECT NUM_ROWS, BLOCKS, LAST_ANALYZED FROM DBA_TAB_STATISTICS WHERE OWNER = USER AND TABLE_NAME='CUSTOMERS';
--
SELECT NUM_ROWS, BLOCKS, LAST_ANALYZED FROM DBA_TAB_STATISTICS WHERE OWNER = USER AND TABLE_NAME='PRODUCTS';
---
EXPLAIN PLAN FOR 
SELECT * FROM 
    SALES S
INNER JOIN
    PRODUCTS P
ON S.PROD_ID = P.PROD_ID
INNER JOIN 
    CUSTOMERS C
ON C.CUST_ID = S.CUST_ID
INNER JOIN 
    COUNTRIES CO
ON CO.COUNTRY_ID = C.COUNTRY_ID
WHERE CO.COUNTRY_ID = 52790 AND S.AMOUNT_SOLD > 1000;
--
select * from table(dbms_xplan.display(format=>'allstats last'));
--
PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Plan hash value: 1269222378

----------------------------------------------------------------
| Id  | Operation                      | Name         | E-Rows |
----------------------------------------------------------------
|   0 | SELECT STATEMENT               |              |    310 |
|   1 |  NESTED LOOPS                  |              |    310 |
|*  2 |   HASH JOIN                    |              |    310 |
|   3 |    PARTITION RANGE ALL         |              |    310 |
|*  4 |     TABLE ACCESS FULL          | SALES        |    310 |
|   5 |    NESTED LOOPS                |              |     72 |
|   6 |     TABLE ACCESS BY INDEX ROWID| COUNTRIES    |      1 |
|*  7 |      INDEX UNIQUE SCAN         | COUNTRIES_PK |      1 |
|   8 |     TABLE ACCESS FULL          | PRODUCTS     |     72 |
|*  9 |   TABLE ACCESS BY INDEX ROWID  | CUSTOMERS    |      1 |
|* 10 |    INDEX UNIQUE SCAN           | CUSTOMERS_PK |      1 |
----------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("S"."PROD_ID"="P"."PROD_ID")
   4 - filter("S"."AMOUNT_SOLD">1000)
   7 - access("CO"."COUNTRY_ID"=52790)
   9 - filter("C"."COUNTRY_ID"=52790)
  10 - access("C"."CUST_ID"="S"."CUST_ID")

Note
-----
   - dynamic statistics used: dynamic sampling (level=2)
   - this is an adaptive plan
   - Warning: basic plan statistics not available. These are only collected when:
       * hint 'gather_plan_statistics' is used for the statement or
       * parameter 'statistics_level' is set to 'ALL', at session or system level
--
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
--
SELECT /*+ GATHER_PLAN_STATISTICS */ * FROM 
    SALES S
INNER JOIN
    PRODUCTS P
ON S.PROD_ID = P.PROD_ID
INNER JOIN 
    CUSTOMERS C
ON C.CUST_ID = S.CUST_ID
INNER JOIN 
    COUNTRIES CO
ON CO.COUNTRY_ID = C.COUNTRY_ID
WHERE CO.COUNTRY_ID = 52790 AND S.AMOUNT_SOLD > 1000;
--
SELECT * FROM table (DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST +adaptive'));
--
SQL_ID  9gnxdy16vjxnf, child number 0
-------------------------------------
SELECT /*+ GATHER_PLAN_STATISTICS */ * FROM     SALES S INNER JOIN
PRODUCTS P ON S.PROD_ID = P.PROD_ID INNER JOIN     CUSTOMERS C ON
C.CUST_ID = S.CUST_ID INNER JOIN     COUNTRIES CO ON CO.COUNTRY_ID =
C.COUNTRY_ID WHERE CO.COUNTRY_ID = 52790 AND S.AMOUNT_SOLD > 1000

Plan hash value: 1269222378

-------------------------------------------------------------------------------------------------------------------------------------------------
|   Id  | Operation                        | Name         | Starts | E-Rows | A-Rows |   A-Time   | Buffers | Reads  |  OMem |  1Mem | Used-Mem |
-------------------------------------------------------------------------------------------------------------------------------------------------
|     0 | SELECT STATEMENT                 |              |      1 |        |  16696 |00:00:00.95 |   71235 |   6389 |       |       |          |
|- *  1 |  HASH JOIN                       |              |      1 |    310 |  16696 |00:00:00.95 |   71235 |   6389 |  2091K|   905K|          |
|     2 |   NESTED LOOPS                   |              |      1 |    310 |  16696 |00:00:01.29 |   71235 |   6389 |       |       |          |
|-    3 |    STATISTICS COLLECTOR          |              |      1 |        |  32640 |00:00:00.24 |    4802 |   4731 |       |       |          |
|  *  4 |     HASH JOIN                    |              |      1 |    310 |  32640 |00:00:00.23 |    4802 |   4731 |  3484K|  1549K| 4161K (0)|
|     5 |      PARTITION RANGE ALL         |              |      1 |    310 |  32640 |00:00:00.01 |    4784 |   4720 |       |       |          |
|  *  6 |       TABLE ACCESS FULL          | SALES        |     28 |    310 |  32640 |00:00:00.14 |    4784 |   4720 |       |       |          |
|     7 |      NESTED LOOPS                |              |      1 |     72 |     72 |00:00:00.01 |      18 |     11 |       |       |          |
|     8 |       TABLE ACCESS BY INDEX ROWID| COUNTRIES    |      1 |      1 |      1 |00:00:00.01 |       2 |      6 |       |       |          |
|  *  9 |        INDEX UNIQUE SCAN         | COUNTRIES_PK |      1 |      1 |      1 |00:00:00.01 |       1 |      1 |       |       |          |
|    10 |       TABLE ACCESS FULL          | PRODUCTS     |      1 |     72 |     72 |00:00:00.01 |      16 |      5 |       |       |          |
|  * 11 |    TABLE ACCESS BY INDEX ROWID   | CUSTOMERS    |  32640 |      1 |  16696 |00:00:00.34 |   66433 |   1658 |       |       |          |
|  * 12 |     INDEX UNIQUE SCAN            | CUSTOMERS_PK |  32640 |      1 |  32640 |00:00:00.09 |   33793 |    189 |       |       |          |
|- * 13 |   TABLE ACCESS FULL              | CUSTOMERS    |      0 |      1 |      0 |00:00:00.01 |       0 |      0 |       |       |          |
-------------------------------------------------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - access("C"."CUST_ID"="S"."CUST_ID")
   4 - access("S"."PROD_ID"="P"."PROD_ID")
   6 - filter("S"."AMOUNT_SOLD">1000)
   9 - access("CO"."COUNTRY_ID"=52790)
  11 - filter("C"."COUNTRY_ID"=52790)
  12 - access("C"."CUST_ID"="S"."CUST_ID")
  13 - filter("C"."COUNTRY_ID"=52790)

Note
-----
   - dynamic statistics used: dynamic sampling (level=2)
   - this is an adaptive plan (rows marked '-' are inactive)
--
--
col IS_RESOLVED_ADAPTIVE_PLAN format a25
col IS_REPOTIMIZABLE format a20
select sql_id, is_resolved_adaptive_plan IS_RESOLVED_ADAPTIVE_PLAN, is_reoptimizable IS_REPOTIMIZABLE
from v$sql where sql_id = '9gnxdy16vjxnf';
--
SQL_ID        IS_RESOLVED_ADAPTIVE_PLAN IS_REPOTIMIZABLE
------------- ------------------------- --------------------
9gnxdy16vjxnf Y                         Y
--
--Run the query for the 2nd time
--
SELECT /*+ GATHER_PLAN_STATISTICS */ * FROM 
    SALES S
INNER JOIN
    PRODUCTS P
ON S.PROD_ID = P.PROD_ID
INNER JOIN 
    CUSTOMERS C
ON C.CUST_ID = S.CUST_ID
INNER JOIN 
    COUNTRIES CO
ON CO.COUNTRY_ID = C.COUNTRY_ID
WHERE CO.COUNTRY_ID = 52790 AND S.AMOUNT_SOLD > 1000;
--
SELECT * FROM table (DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST +adaptive'));
--
SQL_ID  9gnxdy16vjxnf, child number 1
-------------------------------------
SELECT /*+ GATHER_PLAN_STATISTICS */ * FROM     SALES S INNER JOIN
PRODUCTS P ON S.PROD_ID = P.PROD_ID INNER JOIN     CUSTOMERS C ON
C.CUST_ID = S.CUST_ID INNER JOIN     COUNTRIES CO ON CO.COUNTRY_ID =
C.COUNTRY_ID WHERE CO.COUNTRY_ID = 52790 AND S.AMOUNT_SOLD > 1000

Plan hash value: 4078956316

---------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                      | Name         | Starts | E-Rows | A-Rows |   A-Time   | Buffers | Reads  |  OMem |  1Mem | Used-Mem |
---------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT               |              |      1 |        |  16696 |00:00:00.08 |    7344 |    107 |       |       |          |
|*  1 |  HASH JOIN                     |              |      1 |  32638 |  16696 |00:00:00.08 |    7344 |    107 |   785K|   785K| 1282K (0)|
|   2 |   TABLE ACCESS FULL            | PRODUCTS     |      1 |     72 |     72 |00:00:00.01 |       7 |      0 |       |       |          |
|*  3 |   HASH JOIN                    |              |      1 |  32638 |  16696 |00:00:00.06 |    7277 |    100 |  3484K|  1549K| 4648K (0)|
|   4 |    PARTITION RANGE ALL         |              |      1 |  32640 |  32640 |00:00:00.01 |    4784 |      0 |       |       |          |
|*  5 |     TABLE ACCESS FULL          | SALES        |     28 |  32640 |  32640 |00:00:00.01 |    4784 |      0 |       |       |          |
|   6 |    NESTED LOOPS                |              |      1 |  12962 |  18520 |00:00:00.04 |    2493 |    100 |       |       |          |
|   7 |     TABLE ACCESS BY INDEX ROWID| COUNTRIES    |      1 |      1 |      1 |00:00:00.01 |       2 |      0 |       |       |          |
|*  8 |      INDEX UNIQUE SCAN         | COUNTRIES_PK |      1 |      1 |      1 |00:00:00.01 |       1 |      0 |       |       |          |
|*  9 |     TABLE ACCESS FULL          | CUSTOMERS    |      1 |  12962 |  18520 |00:00:00.03 |    2491 |    100 |       |       |          |
---------------------------------------------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - access("S"."PROD_ID"="P"."PROD_ID")
   3 - access("C"."CUST_ID"="S"."CUST_ID")
   5 - filter("S"."AMOUNT_SOLD">1000)
   8 - access("CO"."COUNTRY_ID"=52790)
   9 - filter("C"."COUNTRY_ID"=52790)

Note
-----
   - dynamic statistics used: dynamic sampling (level=2)
   - statistics feedback used for this statement
--
col IS_RESOLVED_ADAPTIVE_PLAN format a25
col IS_REPOTIMIZABLE format a20
select sql_id, is_resolved_adaptive_plan IS_RESOLVED_ADAPTIVE_PLAN, is_reoptimizable IS_REPOTIMIZABLE
from v$sql where sql_id = '9gnxdy16vjxnf';
--
SQL_ID        IS_RESOLVED_ADAPTIVE_PLAN IS_REPOTIMIZABLE
------------- ------------------------- --------------------
9gnxdy16vjxnf Y                         Y
9gnxdy16vjxnf                           N
--