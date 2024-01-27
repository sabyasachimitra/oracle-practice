/* Server Result Cache */
/* Run the following SQL and note the execution plan and query statistics */
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
SET AUTOT ON
SELECT SALES_REP_ID, SUM(ORDER_TOTAL) FROM ORDERS GROUP BY SALES_REP_ID;
SET AUTOT OFF
--
/* Consistent Gets: 18282 */
/* Physical Reads: 17684 */
/*
-----------------------------------------------------------------------------
| Id  | Operation          | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |        |   698 |  5584 |  4879   (2)| 00:00:01 |
|   1 |  HASH GROUP BY     |        |   698 |  5584 |  4879   (2)| 00:00:01 |
|   2 |   TABLE ACCESS FULL| ORDERS |  1352K|    10M|  4836   (1)| 00:00:01 |
-----------------------------------------------------------------------------

Statistics
----------------------------------------------------------
        313  recursive calls
          0  db block gets
      18282  consistent gets
      17684  physical reads
          0  redo size
      12318  bytes sent via SQL*Net to client
        899  bytes received via SQL*Net from client
         48  SQL*Net roundtrips to/from client
         67  sorts (memory)
          0  sorts (disk)
        699  rows processed
*/        

/* Run the following SQL with RESULT_CACHE hint, note the execution plan and query statistics, not section */
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
SET LINESIZE 180
SET AUTOT ON
SELECT /*+ RESULT_CACHE (NAME=RC_SALES) */ SALES_REP_ID, SUM(ORDER_TOTAL) FROM
ORDERS GROUP BY SALES_REP_ID;
--
/* Observe that a result cache has been created with its address. No change in query stat. */
/* Consistent Gets: 18738 */
/* Physical Reads: 17714 */
/*
--------------------------------------------------------------------------------------------------
| Id  | Operation           | Name                       | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT    |                            |   698 |  5584 |  4879   (2)| 00:00:01 |
|   1 |  RESULT CACHE       | dq5c6pn203sawd7g2rtm36fhpc |   698 |  5584 |  4879   (2)| 00:00:01 |
|   2 |   HASH GROUP BY     |                            |   698 |  5584 |  4879   (2)| 00:00:01 |
|   3 |    TABLE ACCESS FULL| ORDERS                     |  1352K|    10M|  4836   (1)| 00:00:01 |
--------------------------------------------------------------------------------------------------

Result Cache Information (identified by operation id):
------------------------------------------------------

   1 - column-count=2; dependencies=(SOE.ORDERS); name="RC_SALES"

Statistics
----------------------------------------------------------
        562  recursive calls
          0  db block gets
      18738  consistent gets
      17714  physical reads
          0  redo size
      12318  bytes sent via SQL*Net to client
        935  bytes received via SQL*Net from client
         48  SQL*Net roundtrips to/from client
        133  sorts (memory)
          0  sorts (disk)
        699  rows processed
*/        
--
/* Run the result-cache-based query again. Observe the changes on the statistics */
--
SELECT /*+ RESULT_CACHE (NAME=RC_SALES) */ SALES_REP_ID, SUM(ORDER_TOTAL) FROM
ORDERS GROUP BY SALES_REP_ID;
SET AUTOT OFF
--
/* Though there is no change in Execution plan, there is a huge improvement in query statistics: */
/* Consistent Gets: 0 */
/* Physical Reads: 0 */
/*
--------------------------------------------------------------------------------------------------
| Id  | Operation           | Name                       | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT    |                            |   698 |  5584 |  4879   (2)| 00:00:01 |
|   1 |  RESULT CACHE       | dq5c6pn203sawd7g2rtm36fhpc |   698 |  5584 |  4879   (2)| 00:00:01 |
|   2 |   HASH GROUP BY     |                            |   698 |  5584 |  4879   (2)| 00:00:01 |
|   3 |    TABLE ACCESS FULL| ORDERS                     |  1352K|    10M|  4836   (1)| 00:00:01 |
--------------------------------------------------------------------------------------------------

Result Cache Information (identified by operation id):
------------------------------------------------------

   1 - column-count=2; dependencies=(SOE.ORDERS); name="RC_SALES"


Statistics
----------------------------------------------------------
          0  recursive calls
          0  db block gets
          0  consistent gets
          0  physical reads
          0  redo size
      12318  bytes sent via SQL*Net to client
        935  bytes received via SQL*Net from client
         48  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
        699  rows processed
*/        
--
/* Obtain statistics about the result cache area contents */
/* Obtain the value of the result cache object id from the output of the preceding step */
--
SELECT ID, TYPE, BLOCK_COUNT, COLUMN_COUNT, PIN_COUNT, ROW_COUNT
FROM V$RESULT_CACHE_OBJECTS
WHERE CACHE_ID = '&Enter_ResultCache_ID';
--
/*
        ID TYPE       BLOCK_COUNT COLUMN_COUNT  PIN_COUNT  ROW_COUNT
---------- ---------- ----------- ------------ ---------- ----------
        45 Result               8            2          0        699
*/
--
/* Invalidating the Result cache */
/* Make the following update on the ORDERS table */
SET AUTOT OFF
UPDATE ORDERS SET ORDER_TOTAL=ORDER_TOTAL WHERE ORDER_ID=12030;
COMMIT;        
--
/* Run the query again and observe the output statistics */
--
SET AUTOT TRACE STAT
SELECT /*+ RESULT_CACHE (NAME=RC_SALES) */ SALES_REP_ID, SUM(ORDER_TOTAL) FROM
ORDERS GROUP BY SALES_REP_ID;
SET AUTOT OFF
--
/* As you can see we now see there are 17630 consistent gets because of the UPDATE */
/*
Statistics
----------------------------------------------------------
          0  recursive calls
          0  db block gets
      17630  consistent gets
          0  physical reads
          0  redo size
      12318  bytes sent via SQL*Net to client
        935  bytes received via SQL*Net from client
         48  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
        699  rows processed
*/        
--
/* Run the query again and observe the output statistics */
--
SET AUTOT TRACE STAT
SELECT /*+ RESULT_CACHE (NAME=RC_SALES) */ SALES_REP_ID, SUM(ORDER_TOTAL) FROM
ORDERS GROUP BY SALES_REP_ID;
SET AUTOT OFF
--
/* As you can see, consistent gets has become zero again */ 
/*
Statistics
----------------------------------------------------------
          0  recursive calls
          0  db block gets
          0  consistent gets
          0  physical reads
          0  redo size
      12318  bytes sent via SQL*Net to client
        935  bytes received via SQL*Net from client
         48  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
        699  rows processed
*/        
--
/* Using Result Cache Materialized View (RCMV) */
/* RCMV is useful when you cannot modify queries to apply the RESULT_CACHE hint */
/* It's a replacement to the Materialized View */
--
/* Execute the following command to create a RCMV */
--
BEGIN
    SYS.DBMS_ADVANCED_REWRITE.DECLARE_REWRITE_EQUIVALENCE (
        NAME => 'RCMV_SALARY',
        SOURCE_STMT =>'SELECT DEPT_NO, AVG(SALARY) FROM EMP GROUP BY DEPT_NO',
        DESTINATION_STMT =>'select * from
(SELECT /*+ RESULT_CACHE(NAME=CACHED_QUERY) */ DEPT_NO, AVG(SALARY) FROM
EMP GROUP BY DEPT_NO)',
        VALIDATE => FALSE,
        REWRITE_MODE => 'GENERAL'
    );
END;
/
--
/* Run the following query and verify that it has been rewritten */
--
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
ALTER SESSION SET QUERY_REWRITE_INTEGRITY = STALE_TOLERATED;
SET AUTOT ON
SELECT
    DEPT_NO,
    AVG(SALARY)
FROM
    EMP
GROUP BY
    DEPT_NO;
SET AUTOT OFF
--
/* Consistent Get: 1227. */
/* Physical Read: 50 */
/*
---------------------------------------------------------------------------------------------------
| Id  | Operation            | Name                       | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT     |                            |     6 |   156 |     6  (17)| 00:00:01 |
|   1 |  VIEW                |                            |     6 |   156 |     6  (17)| 00:00:01 |
|   2 |   RESULT CACHE       | 0n8gxuf5dc9a0ajfgknuakq7ps |     6 |    42 |     6  (17)| 00:00:01 |
|   3 |    HASH GROUP BY     |                            |     6 |    42 |     6  (17)| 00:00:01 |
|   4 |     TABLE ACCESS FULL| EMP                        |   879 |  6153 |     5   (0)| 00:00:01 |
---------------------------------------------------------------------------------------------------

Result Cache Information (identified by operation id):
------------------------------------------------------

   2 - column-count=2; dependencies=(SOE.EMP); name="CACHED_QUERY"

Statistics
----------------------------------------------------------
        630  recursive calls
          0  db block gets
       1227  consistent gets
         50  physical reads
          0  redo size
        593  bytes sent via SQL*Net to client
        391  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
         69  sorts (memory)
          0  sorts (disk)
          6  rows processed
*/          
--
/* Re-run the same query again and observe that the 'consistent gets' is now zero */
--
SET AUTOT ON
SELECT
    DEPT_NO,
    AVG(SALARY)
FROM
    EMP
GROUP BY
    DEPT_NO;
SET AUTOT OFF
--
/* Consistent Get: 1227. */
/* Physical Read: 50     */
/*
---------------------------------------------------------------------------------------------------
| Id  | Operation            | Name                       | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT     |                            |     6 |   156 |     6  (17)| 00:00:01 |
|   1 |  VIEW                |                            |     6 |   156 |     6  (17)| 00:00:01 |
|   2 |   RESULT CACHE       | 0n8gxuf5dc9a0ajfgknuakq7ps |     6 |    42 |     6  (17)| 00:00:01 |
|   3 |    HASH GROUP BY     |                            |     6 |    42 |     6  (17)| 00:00:01 |
|   4 |     TABLE ACCESS FULL| EMP                        |   879 |  6153 |     5   (0)| 00:00:01 |
---------------------------------------------------------------------------------------------------

Result Cache Information (identified by operation id):
------------------------------------------------------

   2 - column-count=2; dependencies=(SOE.EMP); name="CACHED_QUERY"

Statistics
----------------------------------------------------------
          0  recursive calls
          0  db block gets
          0  consistent gets
          0  physical reads
          0  redo size
        593  bytes sent via SQL*Net to client
        391  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          6  rows processed
*/          
/* Delete the created RCMV */
begin
sys.DBMS_ADVANCED_REWRITE.DROP_REWRITE_EQUIVALENCE('SOE.RCMV_SALARY');
end;
/
--
/* Using Result Cache in PL/SQL Functions */
--
/* Create the following PL/SQL function */
--
CREATE OR REPLACE FUNCTION GET_RSALES (
    P_SALES_REP_ID NUMBER,
    P_YEAR NUMBER
) RETURN NUMBER IS
    N NUMBER;
BEGIN
    SELECT
        SUM(ORDER_TOTAL) INTO N
    FROM
        ORDERS
    WHERE
        SALES_REP_ID=P_SALES_REP_ID
        AND ORDER_DATE BETWEEN TO_DATE('01-01-'|| P_YEAR,'DD-MM-YYYY')
        AND TO_DATE('31-12-' || P_YEAR || ' 23:59:59','DD-MM-YYYY HH24:MI:SS');
 -- emulate some processing time:
    DBMS_LOCK.SLEEP(DBMS_RANDOM.VALUE(2, 10));
    RETURN (N);
END;
/
--
/* Run the following code and observe the execution time of each select statement */
/* Every select statement takes a few seconds to execute */
--
SET TIMING ON
SELECT GET_RSALES(488,2007) S FROM DUAL;
SELECT GET_RSALES(488,2007) S FROM DUAL;
SELECT GET_RSALES(488,2007) S FROM DUAL;
SELECT GET_RSALES(488,2007) S FROM DUAL;
SET TIMING OFF
--
/*
Elapsed: 00:00:03.53
Elapsed: 00:00:08.42
Elapsed: 00:00:08.14
Elapsed: 00:00:07.98
*/
--
/* Re-create the function using the result cache option */
--
CREATE OR REPLACE FUNCTION GET_RSALES (
    P_SALES_REP_ID NUMBER,
    P_YEAR NUMBER
) RETURN NUMBER RESULT_CACHE RELIES_ON (ORDERS) IS
    N NUMBER;
BEGIN
    SELECT
        SUM(ORDER_TOTAL) INTO N
    FROM
        ORDERS
    WHERE
        SALES_REP_ID=P_SALES_REP_ID
        AND ORDER_DATE BETWEEN TO_DATE('01-01-'
            || P_YEAR,
        'DD-MM-YYYY')
        AND TO_DATE('31-12-'
            || P_YEAR
            || ' 23:59:59',
        'DD-MM-YYYY HH24:MI:SS');
 -- emulate some processing time:
    DBMS_LOCK.SLEEP(DBMS_RANDOM.VALUE(2, 10));
    RETURN (N);
END;
/
--
/* Run the queries again and observe their execution time */
--
SET TIMING ON
SELECT GET_RSALES(488,2007) S FROM DUAL;
SELECT GET_RSALES(488,2007) S FROM DUAL;
SELECT GET_RSALES(488,2007) S FROM DUAL;
SELECT GET_RSALES(488,2007) S FROM DUAL;
SET TIMING OFF
/*
Elapsed: 00:00:07.92 -- takes much time
--
Elapsed: 00:00:00.00 -- Takes no time as result is fetched from function result cache
--
Elapsed: 00:00:00.00 -- Takes no time as result is fetched from function result cache
--
Elapsed: 00:00:00.00 -- Takes no time as result is fetched from function result cache
--
*/
/* Clean up */
DROP FUNCTION GET_RSALES;