--Demonstrating Adaptive Plan
--
@setup_practice.sql
--Insert new records into SOE.ORDERS2 and SOE.ORDER_ITEMS2 tables.
--Doptimizer is not yet aware about this data change because the 
--statistics have not been gathered on the tables after inserting this new data
INSERT INTO SOE.ORDERS2 SELECT * FROM SOE.ORDERS WHERE ORDER_ID BETWEEN 20000 AND 30000;
INSERT INTO SOE.ORDER_ITEMS2 SELECT * FROM SOE.ORDER_ITEMS WHERE ORDER_ID BETWEEN 20000 AND 30000;
COMMIT;
--
show parameter OPTIMIZER_ADAPTIVE_PLANS
NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
optimizer_adaptive_plans             boolean     TRUE
--
show parameter OPTIMIZER_ADAPTIVE_STATISTICS
--
NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
optimizer_adaptive_statistics        boolean     FALSE
--
ALTER SYSTEM SET OPTIMIZER_ADAPTIVE_STATISTICS=TRUE;
--
@myplan.sql
--
SET AUTOT OFF
SET LINESIZE 200 PAGESIZE 100
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
--
--This is the EXPLAIN PLAN without ADAPTIVE and STATISTICS COLLECTOR. Optimizer is unaware of new data inserted.
------------------------------------------------------------------------------------------------
| Id  | Operation                    | Name            | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT             |                 |     1 |    36 |     4   (0)| 00:00:01 |
|   1 |  NESTED LOOPS                |                 |     1 |    36 |     4   (0)| 00:00:01 |
|   2 |   NESTED LOOPS               |                 |     3 |    36 |     4   (0)| 00:00:01 |
|*  3 |    TABLE ACCESS FULL         | ORDERS2         |     1 |    20 |     3   (0)| 00:00:01 |
|*  4 |    INDEX RANGE SCAN          | ORDER_ITEMS2_IX |     3 |       |     0   (0)| 00:00:01 |
|   5 |   TABLE ACCESS BY INDEX ROWID| ORDER_ITEMS2    |     3 |    48 |     1   (0)| 00:00:01 |
------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   3 - filter(TO_NUMBER(TO_CHAR(INTERNAL_FUNCTION("ORDER_DATE"),'YYYY'))=2010)
   4 - access("ORDERS2"."ORDER_ID"="ORDER_ITEMS2"."ORDER_ID")

Note
-----
   - this is an adaptive plan
--
--Run the following query.
@myquery.sql
--and get the execution plan
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR);
SELECT * FROM TABLE(DBMS_XPLAN.display_cursor(format=>'ALLSTATS LAST +PEEKED_BINDS +outline'));
--
--We see that the execution plan is different than the explain plan. 
--because ADAPTIVE PLAN is enabled and Optimizer collects the statistics 
--run time and compares it with current statistics. Since they are different
--Optimizer creates a new plan dynamically replaceing NESTED LOOP with HASH JOIN.
--Note:: the inactive plan is not shown here. It only shows the actual plan.
--
SQL_ID  c1xmjzntj9nhx
-----------------------------------------------------------------------------------
| Id  | Operation          | Name         | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |              |       |       |     4 (100)|          |
|*  1 |  HASH JOIN         |              |     1 |    36 |     4   (0)| 00:00:01 |
|*  2 |   TABLE ACCESS FULL| ORDERS2      |     1 |    20 |     3   (0)| 00:00:01 |
|   3 |   TABLE ACCESS FULL| ORDER_ITEMS2 |     3 |    48 |     1   (0)| 00:00:01 |
-----------------------------------------------------------------------------------
Note
-----
   - this is an adaptive plan
--
--note the SQL_ID and run the following command to generate the ADAPTIVE plan of the SQL.
define v_sql_id = 'd3arz2p4uhzcg'
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&v_sql_id',FORMAT=>'ADAPTIVE'));
--
--It will now generate the ADAPTIVE plan (actual as well as inactive). The steps marked with - 
--are inactive and we can see Optimizer marked NESTED LOOP inactive and replace it with HASH JOIN
--
Plan hash value: 3188328183

---------------------------------------------------------------------------------------------------
|   Id  | Operation                     | Name            | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------------------------
|     0 | SELECT STATEMENT              |                 |       |       |     4 (100)|          |
|  *  1 |  HASH JOIN                    |                 |     1 |    36 |     4   (0)| 00:00:01 |
|-    2 |   NESTED LOOPS                |                 |     1 |    36 |     4   (0)| 00:00:01 |
|-    3 |    NESTED LOOPS               |                 |     3 |    36 |     4   (0)| 00:00:01 |
|-    4 |     STATISTICS COLLECTOR      |                 |       |       |            |          |
|  *  5 |      TABLE ACCESS FULL        | ORDERS2         |     1 |    20 |     3   (0)| 00:00:01 |
|- *  6 |     INDEX RANGE SCAN          | ORDER_ITEMS2_IX |     3 |       |     0   (0)|          |
|-    7 |    TABLE ACCESS BY INDEX ROWID| ORDER_ITEMS2    |     3 |    48 |     1   (0)| 00:00:01 |
|     8 |   TABLE ACCESS FULL           | ORDER_ITEMS2    |     3 |    48 |     1   (0)| 00:00:01 |
---------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - access("ORDERS2"."ORDER_ID"="ORDER_ITEMS2"."ORDER_ID")
   5 - filter(TO_NUMBER(TO_CHAR(INTERNAL_FUNCTION("ORDER_DATE"),'YYYY'))=2010)
   6 - access("ORDERS2"."ORDER_ID"="ORDER_ITEMS2"."ORDER_ID")

Note
-----
   - this is an adaptive plan (rows marked '-' are inactive)
--
--Demonstrating Adaptive Plan Cursors:: Cursors created for the Adaptive Plan
--
ALTER SYSTEM FLUSH SHARED_POOL;
--
@setup_practice.sql 
--
@myquery.sql
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR);
--
SQL_ID  c1xmjzntj9nhx, child number 0
-----------------------------------------------------------------------------------
| Id  | Operation          | Name         | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |              |       |       |     4 (100)|          |
|*  1 |  HASH JOIN         |              |     1 |    36 |     4   (0)| 00:00:01 |
|*  2 |   TABLE ACCESS FULL| ORDERS2      |     1 |    20 |     3   (0)| 00:00:01 |
|   3 |   TABLE ACCESS FULL| ORDER_ITEMS2 |     3 |    48 |     1   (0)| 00:00:01 |
-----------------------------------------------------------------------------------
--
SELECT '&v_sql_id' FROM DUAL;
--
@display_cursors.sql
--
SQL_ID        CHILD_NUMBER PLAN_HASH_VALUE IS_RESOLVED_ADAPTIVE_PLAN IS_REOPTIMIZABLE
------------- ------------ --------------- ------------------------- ----------------
c1xmjzntj9nhx            0      3188328183 Y                         N
--
INSERT INTO SOE.ORDERS2 SELECT * FROM SOE.ORDERS WHERE ORDER_ID BETWEEN 20000 AND 30000;
INSERT INTO SOE.ORDER_ITEMS2 SELECT * FROM SOE.ORDER_ITEMS WHERE ORDER_ID BETWEEN 20000 AND 30000;
COMMIT;
--
--run the the script twice.
@myquery.sql
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR);
--
--Plan has changed now and instead of HASH JOIN Optimizer opted for MERGE JOIN and Child Number 1 was used.
SQL_ID  c1xmjzntj9nhx, child number 1
---------------------------------------------------------------------------------------------
| Id  | Operation                    | Name         | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT             |              |       |       |    71 (100)|          |
|   1 |  MERGE JOIN                  |              | 31034 |  1091K|    71   (2)| 00:00:01 |
|*  2 |   TABLE ACCESS BY INDEX ROWID| ORDERS2      | 10011 |   195K|     2   (0)| 00:00:01 |
|   3 |    INDEX FULL SCAN           | ORDERS2_PK   |    10 |       |     1   (0)| 00:00:01 |
|*  4 |   SORT JOIN                  |              |    31 |   496 |    69   (2)| 00:00:01 |
|   5 |    TABLE ACCESS FULL         | ORDER_ITEMS2 |    31 |   496 |    68   (0)| 00:00:01 |
---------------------------------------------------------------------------------------------
--
@display_cursors.sql
--
SQL_ID        CHILD_NUMBER PLAN_HASH_VALUE IS_RESOLVED_ADAPTIVE_PLAN IS_REOPTIMIZABLE
------------- ------------ --------------- ------------------------- ----------------
c1xmjzntj9nhx            0      3188328183 Y                         Y
c1xmjzntj9nhx            1       598654830                           N
--
DELETE SOE.ORDER_ITEMS2 WHERE ORDER_ID BETWEEN 20000 AND 30000;
DELETE SOE.ORDERS2 WHERE ORDER_ID BETWEEN 20000 AND 30000;
COMMIT;
--
@myquery.sql
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&v_sql_id'));
--
SQL_ID  c1xmjzntj9nhx, child number 0
-----------------------------------------------------------------------------------
| Id  | Operation          | Name         | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |              |       |       |     4 (100)|          |
|*  1 |  HASH JOIN         |              |     1 |    36 |     4   (0)| 00:00:01 |
|*  2 |   TABLE ACCESS FULL| ORDERS2      |     1 |    20 |     3   (0)| 00:00:01 |
|   3 |   TABLE ACCESS FULL| ORDER_ITEMS2 |     3 |    48 |     1   (0)| 00:00:01 |
-----------------------------------------------------------------------------------
--
SQL_ID        CHILD_NUMBER PLAN_HASH_VALUE IS_RESOLVED_ADAPTIVE_PLAN IS_REOPTIMIZABLE
------------- ------------ --------------- ------------------------- ----------------
c1xmjzntj9nhx            0      3188328183 Y                         Y
c1xmjzntj9nhx            1       598654830                           N