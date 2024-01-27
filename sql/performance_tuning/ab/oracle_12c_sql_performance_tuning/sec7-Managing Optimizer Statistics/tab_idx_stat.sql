--Table Statistics
--
SELECT NUM_ROWS, BLOCKS, LAST_ANALYZED
FROM DBA_TAB_STATISTICS
WHERE OWNER = 'SOE' AND TABLE_NAME = 'EMP';
--
--Create a new table EMP2
CREATE TABLE SOE.EMP2
( EMP_NO NUMBER(4), ENAME VARCHAR2(20),
HIRE_DATE DATE, DEPT_NO NUMBER(2),
JOB_CODE CHAR(4), SALARY NUMBER(8,2),
MGR_ID NUMBER(4), TERMINATED CHAR(1), NOTES VARCHAR2(1000));
--
--No statistics is gathered
SELECT NUM_ROWS, BLOCKS, LAST_ANALYZED
FROM DBA_TAB_STATISTICS
WHERE OWNER = 'SOE' AND TABLE_NAME = 'EMP2';
--Insert records into EMP2 from EMP
INSERT INTO SOE.EMP2 SELECT * FROM SOE.EMP;
--
--But No statistics is gathered
SELECT NUM_ROWS, BLOCKS, LAST_ANALYZED
FROM DBA_TAB_STATISTICS
WHERE OWNER = 'SOE' AND TABLE_NAME = 'EMP2';
--
--Insert records into EMP2 with APPEND hint (Direct Path Insert).
INSERT INTO SOE.EMP2 SELECT /*+ APPEND */ * FROM SOE.EMP;
--
SELECT NUM_ROWS, BLOCKS, LAST_ANALYZED
FROM DBA_TAB_STATISTICS
WHERE OWNER = 'SOE' AND TABLE_NAME = 'EMP2';
--
--You'll see Statistics is generated. Starting 12c Oracle generates statistics while INSERT INTO...SELECT with Direct Path Insert
--or CREATE TABLE..SELCT
 NUM_ROWS     BLOCKS LAST_ANAL
---------- ---------- ---------
       879        100 14-MAY-22
--
CREATE TABLE SOE.EMP2 AS SELECT * FROM SOE.EMP;
--Statistics is generated.
SELECT NUM_ROWS, BLOCKS, LAST_ANALYZED
FROM DBA_TAB_STATISTICS
WHERE OWNER = 'SOE' AND TABLE_NAME = 'EMP2';
--
--Index Statistics
CREATE TABLE SOE.EMP2
( EMP_NO NUMBER(4), ENAME VARCHAR2(20),
HIRE_DATE DATE, DEPT_NO NUMBER(2),
JOB_CODE CHAR(4), SALARY NUMBER(8,2),
MGR_ID NUMBER(4), TERMINATED CHAR(1), NOTES VARCHAR2(1000));
--
INSERT INTO SOE.EMP2
SELECT * FROM SOE.EMP;
--
--No Stat
SELECT NUM_ROWS, BLOCKS, AVG_ROW_LEN, LAST_ANALYZED
FROM DBA_TAB_STATISTICS
WHERE OWNER = 'SOE' AND TABLE_NAME = 'EMP2';
--
--Create a New Index
CREATE UNIQUE INDEX SOE.EMP2_EMPNO_UQ
ON SOE.EMP2(EMP_NO) TABLESPACE SOETBS;
--
--Display Index Statistics
SELECT BLEVEL, LEAF_BLOCKS AS "LEAFBLK", DISTINCT_KEYS AS "DIST_KEY",
AVG_LEAF_BLOCKS_PER_KEY AS "LEAFBLK_PER_KEY",
AVG_DATA_BLOCKS_PER_KEY AS "DATABLK_PER_KEY"
FROM DBA_IND_STATISTICS
WHERE OWNER = 'SOE' AND INDEX_NAME = 'EMP2_EMPNO_UQ';
--
--Starting Oracle 12c Index Stat is automatically generated when you create an Index.
    BLEVEL    LEAFBLK   DIST_KEY LEAFBLK_PER_KEY DATABLK_PER_KEY
---------- ---------- ---------- --------------- ---------------
         1          2        879               1               1
--
SET AUTOT TRACE EXP
SELECT * FROM SOE.EMP2 WHERE EMP_NO=641;
SET AUTOT OFF
--
--Optimizer is using the Index
---------------------------------------------------------------------------------------------
| Id  | Operation                   | Name          | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT            |               |     1 |   584 |     1   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP2          |     1 |   584 |     1   (0)| 00:00:01 |
|*  2 |   INDEX UNIQUE SCAN         | EMP2_EMPNO_UQ |     1 |       |     1   (0)| 00:00:01 |
---------------------------------------------------------------------------------------------
--
--Generate Table stats
exec DBMS_STATS.GATHER_TABLE_STATS('SOE','EMP2');
--
--Stat is generated
SELECT NUM_ROWS, BLOCKS, AVG_ROW_LEN, LAST_ANALYZED
FROM DBA_TAB_STATISTICS
WHERE OWNER = 'SOE' AND TABLE_NAME = 'EMP2';
--
