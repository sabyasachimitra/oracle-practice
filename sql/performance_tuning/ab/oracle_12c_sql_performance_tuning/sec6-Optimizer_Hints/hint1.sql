--Optimizer Hints
--
--Optimizer Goal: ALL_ROWS and FIRST_ROWS
--
SELECT /*+ FIRST_ROWS(10) */ EMP_NO, ENAME, SALARY, JOB_CODE 
FROM SOE.EMP WHERE HIRE_DATE <=SYSDATE-365;
--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format=> 'ALLSTATS LAST +cost +bytes +outline'));
--
----------------------------------------------------------------
| Id  | Operation         | Name | E-Rows |E-Bytes| Cost (%CPU)|
----------------------------------------------------------------
|   0 | SELECT STATEMENT  |      |        |       |     2 (100)|
|*  1 |  TABLE ACCESS FULL| EMP  |     10 |   370 |     2   (0)|
----------------------------------------------------------------

Outline Data
-------------

  /*+
      BEGIN_OUTLINE_DATA
      IGNORE_OPTIM_EMBEDDED_HINTS
      OPTIMIZER_FEATURES_ENABLE('19.1.0')
      DB_VERSION('19.1.0')
      FIRST_ROWS(10)
      OUTLINE_LEAF(@"SEL$1")
      FULL(@"SEL$1" "EMP"@"SEL$1")
      END_OUTLINE_DATA
  */
--
SELECT /*+ ALL_ROWS */ EMP_NO, ENAME, SALARY, JOB_CODE 
FROM SOE.EMP WHERE HIRE_DATE <=SYSDATE-365;
--
----------------------------------------------------------------
| Id  | Operation         | Name | E-Rows |E-Bytes| Cost (%CPU)|
----------------------------------------------------------------
|   0 | SELECT STATEMENT  |      |        |       |     5 (100)|
|*  1 |  TABLE ACCESS FULL| EMP  |    879 | 32523 |     5   (0)|
----------------------------------------------------------------

Outline Data
-------------

  /*+
      BEGIN_OUTLINE_DATA
      IGNORE_OPTIM_EMBEDDED_HINTS
      OPTIMIZER_FEATURES_ENABLE('19.1.0')
      DB_VERSION('19.1.0')
      ALL_ROWS
      OUTLINE_LEAF(@"SEL$1")
      FULL(@"SEL$1" "EMP"@"SEL$1")
      END_OUTLINE_DATA
  */
--
--Full Table Scan Hint - FULL
--Without FULL table hint
EXPLAIN PLAN FOR SELECT EMP_NO, ENAME, HIRE_DATE
FROM SOE.EMP
WHERE EMP_NO BETWEEN 100 AND 200;
--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(TABLE_NAME => 'PLAN_TABLE', 
STATEMENT_ID=> NULL, FORMAT => 'ALL', FILTER_PREDs => NULL));
--
--------------------------------------------------------------------------------------
| Id  | Operation                   | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT            |        |     1 |    28 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP    |     1 |    28 |     2   (0)| 00:00:01 |
|*  2 |   INDEX UNIQUE SCAN         | EMP_PK |     1 |       |     1   (0)| 00:00:01 |
--------------------------------------------------------------------------------------
--
--With FULL table hint
SET AUTOT TRACE
--
SELECT /*+ FULL(E) */ EMP_NO, ENAME, HIRE_DATE
FROM SOE.EMP E
WHERE EMP_NO BETWEEN 100 AND 200;
--
--------------------------------------------------------------------------
| Id  | Operation         | Name | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |      |     1 |    28 |     5   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| EMP  |     1 |    28 |     5   (0)| 00:00:01 |
--------------------------------------------------------------------------
--
--Index Hint
SELECT /*+ FULL (E) */ EMP_NO, ENAME, SALARY
FROM SOE.EMP E WHERE EMP_NO = 635;
--
--------------------------------------------------------------------------
| Id  | Operation         | Name | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |      |     1 |    24 |     5   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| EMP  |     1 |    24 |     5   (0)| 00:00:01 |
--------------------------------------------------------------------------
--
SELECT /*+ INDEX (E INDEX_PK) */ EMP_NO, ENAME, SALARY
FROM SOE.EMP E WHERE EMP_NO = 635;
--
--------------------------------------------------------------------------------------
| Id  | Operation                   | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT            |        |     1 |    24 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP    |     1 |    24 |     2   (0)| 00:00:01 |
|*  2 |   INDEX UNIQUE SCAN         | EMP_PK |     1 |       |     1   (0)| 00:00:01 |
--------------------------------------------------------------------------------------
--
