--Examples:: Statistics Feedback and Dynamic Statistics
--
--Create sample table.
DROP TABLE SOE.CUSTOMERS2 PURGE;
CREATE TABLE SOE.CUSTOMERS2
(
	CUSTOMER_ID NUMBER(12) PRIMARY KEY,
	CUST_FIRST_NAME VARCHAR2(40),
	CUST_LAST_NAME VARCHAR2(40),
	NLS_LANGUAGE VARCHAR2(3),
	NLS_TERRITORY VARCHAR2(30),
	CREDIT_LIMIT NUMBER(9,2),
	CUST_EMAIL VARCHAR2(100),
	ACCOUNT_MGR_ID NUMBER(12),
	CUSTOMER_SINCE DATE,
	CUSTOMER_CLASS VARCHAR2(40),
	SUGGESTIONS VARCHAR2(40),
	DOB DATE,
	MAILSHOT VARCHAR2(1),
	PARTNER_MAILSHOT VARCHAR2(1),
	PREFERRED_ADDRESS NUMBER(12),
	PREFERRED_CARD NUMBER(12)
);
--
INSERT INTO SOE.CUSTOMERS2 SELECT * FROM SOE.CUSTOMERS;
COMMIT;
ALTER SYSTEM FLUSH SHARED_POOL;
--
--Display Child Cursors
col IS_RESOLVED_ADAPTIVE_PLAN format a25
col IS_REOPTIMIZABLE format a16
SELECT 
	SQL_ID, 
	CHILD_NUMBER, 
	PLAN_HASH_VALUE, 
	IS_RESOLVED_ADAPTIVE_PLAN IS_RESOLVED_ADAPTIVE_PLAN,
	IS_REOPTIMIZABLE IS_REOPTIMIZABLE
FROM 
	V$SQL 
WHERE SQL_ID='&v_sql_id' ORDER BY SQL_ID, CHILD_NUMBER;
--
--Demonstrating Statistics Feedback
--
SELECT NUM_ROWS, BLOCKS, LAST_ANALYZED FROM DBA_TAB_STATISTICS WHERE OWNER = 'SOE' AND TABLE_NAME='CUSTOMERS';
--
 NUM_ROWS     BLOCKS LAST_ANAL
---------- ---------- ---------
     45703        780 22-JUN-22
--
--Run the query
SET LINESIZE 200
set serveroutput off
SELECT /*+ GATHER_PLAN_STATISTICS */ * FROM SOE.CUSTOMERS WHERE NLS_LANGUAGE = 'us' AND NLS_TERRITORY='AMERICA';
--
--
SELECT * FROM table (DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));
--
--Demonstrating Dynamic Statistics
--
SELECT NUM_ROWS, BLOCKS, LAST_ANALYZED FROM DBA_TAB_STATISTICS WHERE TABLE_NAME='CUSTOMERS2';
--
show parameter OPTIMIZER_DYNAMIC_SAMPLING
--
NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
optimizer_dynamic_sampling           integer     2
--
SET LINESIZE 200
SELECT /*+ GATHER_PLAN_STATISTICS */ * FROM SOE.CUSTOMERS2 WHERE NLS_LANGUAGE = 'us' AND NLS_TERRITORY='AMERICA';
--
SELECT * FROM table (DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));
--
SQL_ID  dvzpsg6f05g16, child number 0
-------------------------------------
SELECT /*+ GATHER_PLAN_STATISTICS */ * FROM SOE.CUSTOMERS2 WHERE
NLS_LANGUAGE = 'us' AND NLS_TERRITORY='AMERICA'

Plan hash value: 1141662121

------------------------------------------------------------------------------------------
| Id  | Operation         | Name       | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |            |      1 |        |   3256 |00:00:00.01 |     968 |
|*  1 |  TABLE ACCESS FULL| CUSTOMERS2 |      1 |   1840 |   3256 |00:00:00.01 |     968 |
------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter(("NLS_LANGUAGE"='us' AND "NLS_TERRITORY"='AMERICA'))

Note
-----
   - dynamic statistics used: dynamic sampling (level=2)
--
col IS_RESOLVED_ADAPTIVE_PLAN format a25
col IS_REOPTIMIZABLE format a16
SELECT 
	SQL_ID, 
	CHILD_NUMBER, 
	PLAN_HASH_VALUE, 
	IS_RESOLVED_ADAPTIVE_PLAN IS_RESOLVED_ADAPTIVE_PLAN,
	IS_REOPTIMIZABLE IS_REOPTIMIZABLE
FROM 
	V$SQL 
WHERE SQL_ID='dvzpsg6f05g16' ORDER BY SQL_ID, CHILD_NUMBER;   
--
SQL_ID        CHILD_NUMBER PLAN_HASH_VALUE IS_RESOLVED_ADAPTIVE_PLAN IS_REOPTIMIZABLE
------------- ------------ --------------- ------------------------- ----------------
dvzpsg6f05g16            0      1141662121                           N
--
--No SQL Plan Directives are created.
--
SELECT TO_CHAR(D.DIRECTIVE_ID) DIR_ID, D.REASON
FROM DBA_SQL_PLAN_DIRECTIVES D, DBA_SQL_PLAN_DIR_OBJECTS O
WHERE D.DIRECTIVE_ID=O.DIRECTIVE_ID
AND O.OWNER = 'SOE' AND O.OBJECT_NAME='CUSTOMERS2'
ORDER BY 1;
--
--
ALTER SESSION SET OPTIMIZER_DYNAMIC_SAMPLING=11;
--
SELECT /*+ GATHER_PLAN_STATISTICS */ * FROM SOE.CUSTOMERS2 WHERE NLS_LANGUAGE = 'us' AND NLS_TERRITORY='AMERICA';
--
SELECT * FROM table (DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));
--
SQL_ID  dvzpsg6f05g16, child number 1
-------------------------------------
SELECT /*+ GATHER_PLAN_STATISTICS */ * FROM SOE.CUSTOMERS2 WHERE
NLS_LANGUAGE = 'us' AND NLS_TERRITORY='AMERICA'

Plan hash value: 1141662121

------------------------------------------------------------------------------------------
| Id  | Operation         | Name       | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |            |      1 |        |   3256 |00:00:00.01 |     968 |
|*  1 |  TABLE ACCESS FULL| CUSTOMERS2 |      1 |   3256 |   3256 |00:00:00.01 |     968 |
------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter(("NLS_LANGUAGE"='us' AND "NLS_TERRITORY"='AMERICA'))

Note
-----
   - dynamic statistics used: dynamic sampling (level=AUTO)
--
col IS_RESOLVED_ADAPTIVE_PLAN format a25
col IS_REOPTIMIZABLE format a16
SELECT 
	SQL_ID, 
	CHILD_NUMBER, 
	PLAN_HASH_VALUE, 
	IS_RESOLVED_ADAPTIVE_PLAN IS_RESOLVED_ADAPTIVE_PLAN,
	IS_REOPTIMIZABLE IS_REOPTIMIZABLE
FROM 
	V$SQL 
WHERE SQL_ID='dvzpsg6f05g16' ORDER BY SQL_ID, CHILD_NUMBER;  
--
SQL_ID        CHILD_NUMBER PLAN_HASH_VALUE IS_RESOLVED_ADAPTIVE_PLAN IS_REOPTIMIZABLE
------------- ------------ --------------- ------------------------- ----------------
dvzpsg6f05g16            0      1141662121                           N
dvzpsg6f05g16            1      1141662121                           N
--
--Check again if SQL Plan directives are created
SELECT TO_CHAR(D.DIRECTIVE_ID) DIR_ID, D.REASON
FROM DBA_SQL_PLAN_DIRECTIVES D, DBA_SQL_PLAN_DIR_OBJECTS O
WHERE D.DIRECTIVE_ID=O.DIRECTIVE_ID
AND O.OWNER = 'SOE' AND O.OBJECT_NAME='CUSTOMERS2'
ORDER BY 1;
--
DIR_ID                                   REASON
---------------------------------------- ------------------------------------
13278133533659450199                     VERIFY CARDINALITY ESTIMATE
2069099808222886906                      VERIFY CARDINALITY ESTIMATE
--
--Delete SQL Plan directives generated.
--
BEGIN
	FOR R IN ( SELECT D.DIRECTIVE_ID FROM DBA_SQL_PLAN_DIRECTIVES D, DBA_SQL_PLAN_DIR_OBJECTS O 
			 WHERE D.DIRECTIVE_ID=O.DIRECTIVE_ID AND O.OWNER = 'SOE' AND O.OBJECT_NAME='CUSTOMERS2' ) 
	LOOP
		DBMS_SPD.DROP_SQL_PLAN_DIRECTIVE(R.DIRECTIVE_ID);
	END LOOP;
END;
/
--
--Demonstrating the DYNAMIC_SAMPLING Hint
--
ALTER SESSION SET OPTIMIZER_DYNAMIC_SAMPLING=2;
--
SELECT /*+ DYNAMIC_SAMPLING(S, 4) */
* FROM SOE.CUSTOMERS2 S WHERE NLS_LANGUAGE = 'us' AND NLS_TERRITORY='AMERICA';
--
SELECT * FROM table (DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));