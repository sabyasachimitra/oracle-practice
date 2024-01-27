/* Using Index - Part - I */
/* In the following practice we will use GV$ views to obtain information about indexes */
--
/* Run the following query to obtain info about the existing indexes on the WAREHOUSES table */
--
col TABLE_NAME format a11
col INDEX_TYPE format a10
col INDEX_NAME format a15
col UNIQUENESS format a10
col VISIBILITY format a11
--
SELECT
    table_name,
    index_type,
    index_name,
    status,
    visibility,
    uniqueness
FROM
    user_indexes
WHERE
    table_name = 'WAREHOUSES';
--
/*
TABLE_NAME  INDEX_TYPE INDEX_NAME      STATUS   VISIBILITY  UNIQUENESS
----------- ---------- --------------- -------- ----------- ----------
WAREHOUSES  NORMAL     WHS_LOCATION_IX VALID    VISIBLE     NONUNIQUE
WAREHOUSES  NORMAL     WAREHOUSES_PK   VALID    VISIBLE     UNIQUE
*/
--
/* Run the following query to obtain information about the columns included in the indexes. */
--
col COLUMN_NAME format a15
col INDEX_NAME format a15
col COLUMN_POSITION format 9
--
SELECT
    index_name,
    column_name,
    column_position
FROM
    user_ind_columns
WHERE
    table_name = 'WAREHOUSES'
ORDER BY
    index_name,
    column_position;
--
INDEX_NAME      COLUMN_NAME     COLUMN_POSITION
--------------- --------------- ---------------
WAREHOUSES_PK   WAREHOUSE_ID                  1
WHS_LOCATION_IX LOCATION_ID                   1
--
--
/* Optimizer Access Paths used with B-tree Indexes */
--
/* Run the following commands to generate the executions plan */
--
EXPLAIN PLAN
    FOR
SELECT
    *
FROM
    warehouses
WHERE
    warehouse_id = 10;

SELECT
    *
FROM
    TABLE ( dbms_xplan.display(NULL, NULL, 'basic') );
--
-- The first query used Index Unique Scan because the equality predicate on an unique index
--
/*
PLAN_TABLE_OUTPUT
----------------------------------------------------------------
Plan hash value: 2784191864

-----------------------------------------------------
| Id  | Operation                   | Name          |
-----------------------------------------------------
|   0 | SELECT STATEMENT            |               |
|   1 |  TABLE ACCESS BY INDEX ROWID| WAREHOUSES    |
|   2 |   INDEX UNIQUE SCAN         | WAREHOUSES_PK |
-----------------------------------------------------
*/
--
--
EXPLAIN PLAN
    FOR
SELECT
    *
FROM
    warehouses
WHERE
    warehouse_id > 180;

SELECT
    *
FROM
    TABLE ( dbms_xplan.display(NULL, NULL, 'basic') );
--
-- The second query used Index Range Scan because the range predicate on an unique index
--
PLAN_TABLE_OUTPUT
------------------------------------------------------------------
Plan hash value: 1701859959

-------------------------------------------------------------
| Id  | Operation                           | Name          |
-------------------------------------------------------------
|   0 | SELECT STATEMENT                    |               |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| WAREHOUSES    |
|   2 |   INDEX RANGE SCAN                  | WAREHOUSES_PK |
-------------------------------------------------------------    
--
EXPLAIN PLAN
    FOR
SELECT /*+ no_parallel */
    warehouse_id
FROM
    warehouses
WHERE
    warehouse_id > 180;

SELECT
    *
FROM
    TABLE ( dbms_xplan.display(NULL, NULL, 'basic') );    
--
-- The third query used Index Fast Full Scan only warehouse_id is in the SELECT clause and the query 
-- can be served from the index alone withour referring to the underlying table
--
/*
PLAN_TABLE_OUTPUT
----------------------------------------------------
Plan hash value: 3095725505

----------------------------------------------
| Id  | Operation            | Name          |
----------------------------------------------
|   0 | SELECT STATEMENT     |               |
|   1 |  INDEX FAST FULL SCAN| WAREHOUSES_PK |
----------------------------------------------    
*/
--
--
/* Demonstrating the Benefit of Using Indexes */
--
-- In this practice you will you will measure the advantages and disadvantages 
-- of using indexes with high selective queries and low selective queries.
--
/* create index */
CREATE INDEX EMP_SALARY_IX ON EMP(
    SALARY
);
--
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
--
set linesize 180
set autot trace exp stat
SELECT
     /*+ FULL(EMP) */
    EMP_NO, ENAME, JOB_CODE, SALARY
FROM 
    EMP WHERE SALARY = 53800;
--    
-- the query returned just three row (highly selective) but it did not use index because of FULL hint
-- consistent get is 79 consistent gets 
--
/*
Execution Plan
----------------------------------------------------------
Plan hash value: 3956160932

--------------------------------------------------------------------------
| Id  | Operation         | Name | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |      |     3 |    87 |     5   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| EMP  |     3 |    87 |     5   (0)| 00:00:01 |
--------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("SALARY"=53800)

Statistics
----------------------------------------------------------
        319  recursive calls
          0  db block gets
        664  consistent gets
         81  physical reads
          0  redo size
        630  bytes sent via SQL*Net to client
        420  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
         67  sorts (memory)
          0  sorts (disk)
          3  rows processed
*/          
--    
-- run the query with the INDEX hint
--
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
--
--
SELECT /*+ INDEX(EMP EMP_SALARY_IX) */
    EMP_NO, ENAME, JOB_CODE, SALARY
FROM 
    EMP WHERE SALARY = 53800;
--
-- We don't see much difference in consistent get and in addition physical reads increased
-- so Optimizer 
--
/*
Execution Plan
----------------------------------------------------------
Plan hash value: 477867232

-----------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name          | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |               |     3 |    87 |     3   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP           |     3 |    87 |     3   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | EMP_SALARY_IX |     3 |       |     1   (0)| 00:00:01 |
-----------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("SALARY"=53800)

Statistics
----------------------------------------------------------
        319  recursive calls
          0  db block gets
        661  consistent gets
         97  physical reads
          0  redo size
        630  bytes sent via SQL*Net to client
        430  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
         67  sorts (memory)
          0  sorts (disk)
          3  rows processed    
*/          
--
set autot off    
--
DROP INDEX EMP_SALARY_IX;
--
/* Indexing Foreign Key Columns */
--
-- get non-indexed foreign keys
@report_noindex_fk.sql
--
-- No index on JOB_CODE foreign key
/*
CONS_NAME            TABLE_NAME      CONS_COLUMN     IND_COLUMN
-------------------- --------------- --------------- ---------------
JOBS_FK_EMP          EMP             JOB_CODE        NO INDEX
SYS_C007633          JOB_HISTORY     JOB_CODE        NO INDEX
*/
--
--
set autot off
SELECT
    JOB_CODE
FROM
    EMP
WHERE
    EMP_NO=634;
-- don't commit
DELETE EMP
WHERE
    EMP_NO=634;
--
-- open another session and issue the SQL
-- result of the SQL is zero as there is no record in JOB table with JOB_CODE = 'TS01'
-- observe that the session hangs after the delete even though there is no row with TS01
SELECT
    COUNT(*)
FROM
    EMP
WHERE
    JOB_CODE='TS01';
--
DELETE JOBS EMP
WHERE
    JOB_CODE='TS01';
--
-- go back to the previous session and ROLLBACK
--
ROLLBACK;
--
-- create an index 
CREATE INDEX EMP_JCODE_IX ON EMP(
    JOB_CODE
);
--
-- in one session, run the following:
DELETE EMP
WHERE
    EMP_NO=634;
-- in the other session, run the following:
-- you will observe that DELETE statement gets executed without hanging
--
DELETE JOBS EMP
WHERE
    JOB_CODE='TS01';
--
ROLLBACK
--
-- run the command and observe the cost 
set linesize 180
set autot trace exp
SELECT
    EMP_NO,
    ENAME,
    JOB_CODE
FROM
    EMP
WHERE
    JOB_CODE LIKE 'MG%';
--
----------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name         | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |              |    42 |  1050 |     3   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP          |    42 |  1050 |     3   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | EMP_JCODE_IX |    42 |       |     2   (0)| 00:00:01 |
----------------------------------------------------------------------------------------------------
--
-- drop the index and run the same sql again and compare the cost 
DROP INDEX EMP_JCODE_IX;
--
-- cost is higher
/*
--------------------------------------------------------------------------
| Id  | Operation         | Name | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |      |    42 |  1050 |     5   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| EMP  |    42 |  1050 |     5   (0)| 00:00:01 |
--------------------------------------------------------------------------
*/
--
/* Using Concatenated Indexes */
--
-- create a composite indexL first column is CUST_LAST_NAME and second CUST_FIRST_NAME
--
CREATE INDEX CUST_FNAME_IX ON CUSTOMERS(
    CUST_LAST_NAME,
    CUST_FIRST_NAME
);
--
EXEC DBMS_STATS.GATHER_INDEX_STATS(USER, 'CUST_FNAME_IX');
--
-- We want to study if the order of the columns in the 
-- where condition has any impact on using the concatenated index.
--
-- Execute the following queries and check if there is any difference in the cost.
--
-- The conclusion is regardless of the order of the columns the concatenated index is equally used
--
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
--
set autot trace exp
SELECT
    CUST_FIRST_NAME FNAME,
    CUST_LAST_NAME  LNAME,
    NLS_LANGUAGE    LANG,
    NLS_TERRITORY   TERRITORY,
    CREDIT_LIMIT
FROM
    CUSTOMERS
WHERE
    CUST_FIRST_NAME LIKE 'gr%'
    AND CUST_LAST_NAME LIKE 'sq%';
--
set autot off
--
/*
-------------------------------------------------------------------------------
| Id  | Operation         | Name      | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |           |     1 |    31 |   214   (1)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| CUSTOMERS |     1 |    31 |   214   (1)| 00:00:01 |
-------------------------------------------------------------------------------
*/
--
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
--
set autot trace exp
--
SELECT
    CUST_FIRST_NAME FNAME,
    CUST_LAST_NAME  LNAME,
    NLS_LANGUAGE    LANG,
    NLS_TERRITORY   TERRITORY,
    CREDIT_LIMIT
FROM
    CUSTOMERS
WHERE
    CUST_LAST_NAME LIKE 'sq%'
    AND CUST_FIRST_NAME LIKE 'gr%';
--
/*
-------------------------------------------------------------------------------
| Id  | Operation         | Name      | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |           |     1 |    31 |   214   (1)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| CUSTOMERS |     1 |    31 |   214   (1)| 00:00:01 |
-------------------------------------------------------------------------------
*/
--
set autot off
--
/* we want to study the difference between retrieving the data based on the */
/* leading column in a concatenated index and based on a single-column index. */
--
set autot off
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
set autot trace exp stat
--
SELECT
    CUST_FIRST_NAME FNAME,
    CUST_LAST_NAME  LNAME,
    NLS_LANGUAGE    LANG,
    NLS_TERRITORY   TERRITORY,
    CREDIT_LIMIT
FROM
    CUSTOMERS
WHERE
    CUST_LAST_NAME LIKE 'sq%';
/* 
-------------------------------------------------------------------------------
| Id  | Operation         | Name      | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |           |    43 |  1333 |   214   (1)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| CUSTOMERS |    43 |  1333 |   214   (1)| 00:00:01 |
-------------------------------------------------------------------------------
*/
--
-- create a single column index on customer last name
--
set autot off
--
CREATE INDEX CUST_LNAME_IX ON CUSTOMERS(
    CUST_LAST_NAME
);
--
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
--
set autot trace exp stat
--
SELECT 
    CUST_FIRST_NAME FNAME,
    CUST_LAST_NAME  LNAME,
    NLS_LANGUAGE    LANG,
    NLS_TERRITORY   TERRITORY,
    CREDIT_LIMIT
FROM
    CUSTOMERS
WHERE
    CUST_LAST_NAME LIKE 'sq%';
--
/* 
-----------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name          | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |               |    43 |  1333 |    46   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| CUSTOMERS     |    43 |  1333 |    46   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | CUST_LNAME_IX |    43 |       |     2   (0)| 00:00:01 |
-----------------------------------------------------------------------------------------------------
*/ 
set autot off
--
DROP INDEX CUST_LNAME_IX;    
--
/* 
we want to study the difference between retrieving the data based on the 
nonleading column in a concatenated index and based on a single-column index.
*/
CREATE INDEX CUST_FNAME_IX ON CUSTOMERS(
    CUST_LAST_NAME,
    CUST_FIRST_NAME
);
--
EXEC DBMS_STATS.GATHER_INDEX_STATS(USER, 'CUST_FNAME_IX');
--
set autot trace exp stat
SELECT 
    CUST_FIRST_NAME FNAME,
    CUST_LAST_NAME  LNAME,
    NLS_LANGUAGE    LANG,
    NLS_TERRITORY   TERRITORY,
    CREDIT_LIMIT
FROM
    SOE.CUSTOMERS
WHERE
    CUST_FIRST_NAME = 'graham';
--
-- Index Skip Scan is used since CUST_FIRST_NAME is not the leading column
/*
-----------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name          | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |               |     9 |   279 |   174   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| CUSTOMERS     |     9 |   279 |   174   (0)| 00:00:01 |
|*  2 |   INDEX SKIP SCAN                   | CUST_FNAME_IX |     9 |       |   165   (0)| 00:00:01 |
-----------------------------------------------------------------------------------------------------
*/
--
set autot off
--
CREATE INDEX CUST_FIRSTNAME_IX ON CUSTOMERS(
    CUST_FIRST_NAME
);
--
set autot trace exp stat
--
SELECT /*+ INDEX(CUSTOMERS CUST_FIRSTNAME_IX) */
    CUST_FIRST_NAME FNAME,
    CUST_LAST_NAME  LNAME,
    NLS_LANGUAGE    LANG,
    NLS_TERRITORY   TERRITORY,
    CREDIT_LIMIT
FROM
    CUSTOMERS
WHERE
    CUST_FIRST_NAME = 'graham';
--
-- Index Range scan is used and the cost is far less than the Index Skip Scan with composite Index.
/*
---------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name              | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                   |     9 |   279 |    10   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| CUSTOMERS         |     9 |   279 |    10   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | CUST_FIRSTNAME_IX |     9 |       |     1   (0)| 00:00:01 |
---------------------------------------------------------------------------------------------------------
*/
set autot off    
--
DROP INDEX CUST_FIRSTNAME_IX;
DROP INDEX CUST_FNAME_IX;
--
/* Index Join (Index-Merge) Scan */
--
CREATE INDEX EMP_ENAME_IX ON EMP(
    ENAME
);

CREATE INDEX EMP_JOB_CODE_IX ON EMP(
    JOB_CODE
);
--
set autot trace exp stat
SELECT /*+ INDEX_JOIN(EMP EMP_ENAME_IX EMP_JOB_CODE_IX) */
    ENAME,
    JOB_CODE,
    SALARY
FROM
    EMP
WHERE
    ENAME LIKE 'Z%'
    AND JOB_CODE LIKE 'SL%';
--
-- In Index Join Scan, the table is not accessed at all. Each of the two indexes are range scanned 
-- and joined together using Hash Join and produce the result set. This is because the Indexed columns
-- are present in the Indexes.
/*
---------------------------------------------------------------------------------------
| Id  | Operation          | Name             | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |                  |    34 |   714 |     5   (0)| 00:00:01 |
|*  1 |  VIEW              | index$_join$_001 |    34 |   714 |     5   (0)| 00:00:01 |
|*  2 |   HASH JOIN        |                  |       |       |            |          |
|*  3 |    INDEX RANGE SCAN| EMP_ENAME_IX     |    34 |   714 |     2   (0)| 00:00:01 |
|*  4 |    INDEX RANGE SCAN| EMP_JOB_CODE_IX  |    34 |   714 |     3   (0)| 00:00:01 |
---------------------------------------------------------------------------------------
*/    
set autot off
--
DROP INDEX EMP_ENAME_IX;
DROP INDEX EMP_JOB_CODE_IX;