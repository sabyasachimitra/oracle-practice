--Access Paths
--Index Range Scan Examples
--Sl_No#1
EXPLAIN PLAN SET STATEMENT_ID = 'EMP_QUERY' for
SELECT EMP_NO, ENAME, JOB_CODE FROM SOE.EMP WHERE DEPT_NO = 10;
--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(TABLE_NAME => NULL, STATEMENT_ID=> 'EMP_QUERY', FORMAT=> 'ALL'));
--
--DEPT_NO has a non-unique index.
--
-----------------------------------------------------------------------------------------------
| Id  | Operation                           | Name    | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |         |   113 |  3164 |     3   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP     |   113 |  3164 |     3   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | DEPT_IX |   113 |       |     1   (0)| 00:00:01 |
-----------------------------------------------------------------------------------------------
--
--Sl_No#2
EXPLAIN PLAN SET STATEMENT_ID = 'IDX_RANGE_1' FOR SELECT EMP_NO, ENAME, JOB_CODE FROM SOE.EMP WHERE EMP_NO BETWEEN 10 AND 200;
--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(TABLE_NAME => NULL, STATEMENT_ID=> 'IDX_RANGE_1', FORMAT=> 'ALL'));
--BETWEEN oprator is used
----------------------------------------------------------------------------------------------
| Id  | Operation                           | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |        |   147 |  3675 |     5   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP    |   147 |  3675 |     5   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | EMP_PK |   147 |       |     2   (0)| 00:00:01 |
----------------------------------------------------------------------------------------------
--
--Index Range Scan Descending
--
EXPLAIN PLAN SET STATEMENT_ID = 'IDX_RANGE_3' FOR SELECT EMP_NO, ENAME, JOB_CODE FROM SOE.EMP 
WHERE EMP_NO BETWEEN 10 AND 200 ORDER BY EMP_NO DESC;
--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(TABLE_NAME => NULL, STATEMENT_ID=> 'IDX_RANGE_3', FORMAT=> 'ALL'));
--
---------------------------------------------------------------------------------------
| Id  | Operation                    | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT             |        |   147 |  3675 |     5   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID | EMP    |   147 |  3675 |     5   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN DESCENDING| EMP_PK |   147 |       |     2   (0)| 00:00:01 |
---------------------------------------------------------------------------------------
--
--Index Full Scan - When Order By is used with an Indexed Non-Nullable Column(s)
--
EXPLAIN PLAN SET STATEMENT_ID = 'IDX_RANGE_4' FOR SELECT * FROM SOE.EMP ORDER BY EMP_NO;
--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(TABLE_NAME => NULL, STATEMENT_ID=> 'IDX_RANGE_4', FORMAT=> 'ALL'));
--
--Index Fast Full Scan - When Only Index can be used to get all the attributes in SELECT without accessing the TABLE.
--This is a Multi-block read Index Access.
--
EXPLAIN PLAN SET STATEMENT_ID = 'IDX_RANGE_5' FOR SELECT COUNT(*) FROM SOE.EMP;
--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(TABLE_NAME => NULL, STATEMENT_ID=> 'IDX_RANGE_5', FORMAT=> 'ALL'));
--
--Index Skip Scan - Leading column in a composite Index is skipped. Used when leading column is not specified in predicate and 
--Leading column has fewer distinct values - low cardinality.
--
CREATE INDEX SOE.CUST_EMAIL_CLASS_IX ON SOE.CUSTOMERS(CUSTOMER_CLASS, CUST_EMAIL);
--
--Gather Stat:
exec DBMS_STATS.GATHER_TABLE_STATS(owner=>'SOE', tabname=> 'CUSTOMERS', cascade=>TRUE, estimate_percent=>DBMS_STATS.AUTO_SAMPLE_SIZE, method_opt=> 'for all indexed columns size auto', granularity =>'ALL', degree=>1);
--
exec DBMS_STATS.GATHER_TABLE_STATS('SOE', 'CUSTOMERS', method_opt => 'FOR ALL INDEXED COLUMNS SIZE AUTO');
--
--Make the existing Index on Email columns invisible otherwise Optimizer will use that Index instead of our new Index.
ALTER INDEX SOE.CUST_EMAIL_IX INVISIBLE;
--
EXPLAIN PLAN SET STATEMENT_ID = 'IDX_RANGE_6' FOR SELECT * FROM SOE.CUSTOMERS WHERE CUST_EMAIL = 'myemail@******.com';
--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(TABLE_NAME => NULL, STATEMENT_ID=> 'IDX_RANGE_6', FORMAT=> 'ALL'));
--
-----------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name                | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                     |     1 |   114 |     6   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| CUSTOMERS           |     1 |   114 |     6   (0)| 00:00:01 |
|*  2 |   INDEX SKIP SCAN                   | CUST_EMAIL_CLASS_IX |     1 |       |     5   (0)| 00:00:01 |
-----------------------------------------------------------------------------------------------------------
--
ALTER INDEX SOE.CUST_EMAIL_IX VISIBLE;