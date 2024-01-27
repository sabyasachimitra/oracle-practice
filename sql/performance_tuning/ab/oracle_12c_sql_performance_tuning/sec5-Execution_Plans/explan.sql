--DISPLAY STATISTICS AND EXPLAIN PLAN AND SUPRESS THE OUTPUT
SET AUTOT ON
--DISPLAY ONLY STAT
SET AUTOT ON STAT
--DISPLAY ONLY PLAN
SET AUTOT ON EXP
--DISPLAY PLAN AND STAT AND SUPRESS THE OUTPUT
SET AUTOT TRACE
--
--display explain plan
--generate explain plan
explain plan for 
select ename from soe.emp where emp_no = '200';
--display plan_table
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(TABLE_NAME => 'PLAN_TABLE', 
STATEMENT_ID=> NULL, FORMAT => 'ALL -projection -predicate', FILTER_PREDs => NULL))
--
EXPLAIN PLAN FOR 
SELECT 
	P.PRODUCT_NAME, 
	P.PRODUCT_ID, 
	OI.UNIT_PRICE, 
	OI.QUANTITY, 
	C.CUSTOMER_ID, 
	C.CUST_FIRST_NAME, 
	C.CUST_LAST_NAME,
	O.ORDER_STATUS
FROM
	SOE.PRODUCT_INFORMATION P
INNER JOIN 
	SOE.ORDER_ITEMS OI
ON OI.PRODUCT_ID = P.PRODUCT_ID
INNER JOIN 
	SOE.ORDERS O
ON O.ORDER_ID = OI.ORDER_ID 
INNER JOIN
	SOE.CUSTOMERS C
ON C.CUSTOMER_ID = O.CUSTOMER_ID;
--
--Deafult format is TYPICAL
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());
--
Plan hash value: 3868044217
 
----------------------------------------------------------------------------------------------------
| Id  | Operation            | Name                | Rows  | Bytes |TempSpc| Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT     |                     |  3735K|   277M|       | 19146   (1)| 00:00:01 |
|*  1 |  HASH JOIN           |                     |  3735K|   277M|       | 19146   (1)| 00:00:01 |
|   2 |   TABLE ACCESS FULL  | CUSTOMERS           | 45703 |   892K|       |   241   (1)| 00:00:01 |
|*  3 |   HASH JOIN          |                     |  3735K|   206M|       | 18892   (1)| 00:00:01 |
|   4 |    TABLE ACCESS FULL | PRODUCT_INFORMATION |  1000 | 27000 |       |    10   (0)| 00:00:01 |
|*  5 |    HASH JOIN         |                     |  3735K|   110M|    33M| 18870   (1)| 00:00:01 |
|   6 |     TABLE ACCESS FULL| ORDERS              |  1352K|    18M|       |  4825   (1)| 00:00:01 |
|   7 |     TABLE ACCESS FULL| ORDER_ITEMS         |  3735K|    60M|       |  7228   (1)| 00:00:01 |
----------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   1 - access("C"."CUSTOMER_ID"="O"."CUSTOMER_ID")
   3 - access("OI"."PRODUCT_ID"="P"."PRODUCT_ID")
   5 - access("O"."ORDER_ID"="OI"."ORDER_ID")
 
Note
-----
   - this is an adaptive plan
--BASIC FORMAT
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(TABLE_NAME => 'PLAN_TABLE', STATEMENT_ID=> NULL, FORMAT=> 'BASIC ROWS'));
--
                                              PLAN_TABLE_OUTPUT
_______________________________________________________________
Plan hash value: 3868044217

------------------------------------------------------------
| Id  | Operation            | Name                | Rows  |
------------------------------------------------------------
|   0 | SELECT STATEMENT     |                     |  3735K|
|   1 |  HASH JOIN           |                     |  3735K|
|   2 |   TABLE ACCESS FULL  | CUSTOMERS           | 45703 |
|   3 |   HASH JOIN          |                     |  3735K|
|   4 |    TABLE ACCESS FULL | PRODUCT_INFORMATION |  1000 |
|   5 |    HASH JOIN         |                     |  3735K|
|   6 |     TABLE ACCESS FULL| ORDERS              |  1352K|
|   7 |     TABLE ACCESS FULL| ORDER_ITEMS         |  3735K|
------------------------------------------------------------
--
--With Statement ID
EXPLAIN PLAN SET STATEMENT_ID = 'EMP_QUERY' for
SELECT EMP_NO, ENAME, JOB_CODE FROM SOE.EMP WHERE DEPT_NO = 10;
--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(TABLE_NAME => NULL, STATEMENT_ID=> 'EMP_QUERY', FORMAT=> 'ALL'))
--Displaying Execution Plan
--
--DISPLAY_CURSOR ()
--
SELECT TABLE_NAME FROM DBA_SYNONYMS WHERE SYNONYM_NAME = 'V$SESSION';
GRANT SELECT ON V_$SQL_PLAN TO TKYTE;
GRANT SELECT ON V_$SESSION TO TKYTE;
GRANT SELECT ON V_$SQL_PLAN_STATISTICS_ALL TO TKYTE;
--
SELECT 
	P.PRODUCT_NAME, 
	P.PRODUCT_ID, 
	OI.UNIT_PRICE, 
	OI.QUANTITY, 
	C.CUSTOMER_ID, 
	C.CUST_FIRST_NAME, 
	C.CUST_LAST_NAME,
	O.ORDER_STATUS
FROM
	SOE.PRODUCT_INFORMATION P
INNER JOIN 
	SOE.ORDER_ITEMS OI
ON OI.PRODUCT_ID = P.PRODUCT_ID
INNER JOIN 
	SOE.ORDERS O
ON O.ORDER_ID = OI.ORDER_ID 
INNER JOIN
	SOE.CUSTOMERS C
ON C.CUSTOMER_ID = O.CUSTOMER_ID;
--
--Without SQL ID. By Default it shows only estimated number of rows (not actual number of rows returned)
set serveroutput off
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR());
--
--To get Estimated as well as Actual rows returned rows.
SELECT /*+ GATHER_PLAN_STATISTICS */
	P.PRODUCT_NAME, 
	P.PRODUCT_ID, 
	OI.UNIT_PRICE, 
	OI.QUANTITY, 
	C.CUSTOMER_ID, 
	C.CUST_FIRST_NAME, 
	C.CUST_LAST_NAME,
	O.ORDER_STATUS
FROM
	SOE.PRODUCT_INFORMATION P
INNER JOIN 
	SOE.ORDER_ITEMS OI
ON OI.PRODUCT_ID = P.PRODUCT_ID
INNER JOIN 
	SOE.ORDERS O
ON O.ORDER_ID = OI.ORDER_ID 
INNER JOIN
	SOE.CUSTOMERS C
ON C.CUSTOMER_ID = O.CUSTOMER_ID;
--
--ALLSTATS = 'IOSTATS MEMSTATS'
--LAST - only the statistics for the last execution
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format=> 'ALLSTATS LAST'));
--
SQL_ID  14ypzt0vv0ng6, child number 0
-------------------------------------
SELECT /*+ GATHER_PLAN_STATISTICS */  P.PRODUCT_NAME,   P.PRODUCT_ID,   
OI.UNIT_PRICE,   OI.QUANTITY,   C.CUSTOMER_ID,   C.CUST_FIRST_NAME,   
C.CUST_LAST_NAME,  O.ORDER_STATUS FROM  SOE.PRODUCT_INFORMATION P INNER 
JOIN   SOE.ORDER_ITEMS OI ON OI.PRODUCT_ID = P.PRODUCT_ID INNER JOIN   
SOE.ORDERS O ON O.ORDER_ID = OI.ORDER_ID  INNER JOIN  SOE.CUSTOMERS C 
ON C.CUSTOMER_ID = O.CUSTOMER_ID
 
Plan hash value: 3868044217
 
---------------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation            | Name                | Starts | E-Rows | A-Rows |   A-Time   | Buffers | Reads  | Writes |  OMem |  1Mem | Used-Mem |
---------------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT     |                     |      1 |        |     50 |00:00:01.42 |   18423 |  21368 |   3503 |       |       |          |
|*  1 |  HASH JOIN           |                     |      1 |   3735K|     50 |00:00:01.42 |   18423 |  21368 |   3503 |  3909K|  1896K| 3780K (0)|
|   2 |   TABLE ACCESS FULL  | CUSTOMERS           |      1 |  45703 |  45703 |00:00:00.01 |     763 |      0 |      0 |       |       |          |
|*  3 |   HASH JOIN          |                     |      1 |   3735K|     50 |00:00:01.41 |   17660 |  21368 |   3503 |  1298K|  1298K| 1497K (0)|
|   4 |    TABLE ACCESS FULL | PRODUCT_INFORMATION |      1 |   1000 |   1000 |00:00:00.01 |      27 |      0 |      0 |       |       |          |
|*  5 |    HASH JOIN         |                     |      1 |   3735K|     50 |00:00:01.41 |   17633 |  21368 |   3503 |    85M|  7720K|   79M (0)|
|   6 |     TABLE ACCESS FULL| ORDERS              |      1 |   1352K|   1352K|00:00:01.00 |   17630 |  17627 |      0 |       |       |          |
|   7 |     TABLE ACCESS FULL| ORDER_ITEMS         |      1 |   3735K|     50 |00:00:00.02 |       3 |    238 |      0 |       |       |          |
---------------------------------------------------------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   1 - access("C"."CUSTOMER_ID"="O"."CUSTOMER_ID")
   3 - access("OI"."PRODUCT_ID"="P"."PRODUCT_ID")
   5 - access("O"."ORDER_ID"="OI"."ORDER_ID")
 
Note
-----
   - this is an adaptive plan
--
--to get cost and bytes columns back
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format=> 'ALLSTATS LAST +cost +bytes'));
--
--with OUTLINE - important to get join order of tables (LEADING in OUTLINE)
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format=> 'ALLSTATS LAST +cost +bytes +outline'));
--
Plan hash value: 3868044217
 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation            | Name                | Starts | E-Rows |E-Bytes|E-Temp | Cost (%CPU)| A-Rows |   A-Time   | Buffers | Reads  |  OMem |  1Mem | Used-Mem |
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT     |                     |      1 |        |       |       | 19146 (100)|     50 |00:00:00.71 |   18423 |    238 |       |       |          |
|*  1 |  HASH JOIN           |                     |      1 |   3735K|   277M|       | 19146   (1)|     50 |00:00:00.71 |   18423 |    238 |  3909K|  1896K| 3637K (0)|
|   2 |   TABLE ACCESS FULL  | CUSTOMERS           |      1 |  45703 |   892K|       |   241   (1)|  45703 |00:00:00.03 |     763 |      0 |       |       |          |
|*  3 |   HASH JOIN          |                     |      1 |   3735K|   206M|       | 18892   (1)|     50 |00:00:00.70 |   17660 |    238 |  1298K|  1298K| 1584K (0)|
|   4 |    TABLE ACCESS FULL | PRODUCT_INFORMATION |      1 |   1000 | 27000 |       |    10   (0)|   1000 |00:00:00.01 |      27 |      0 |       |       |          |
|*  5 |    HASH JOIN         |                     |      1 |   3735K|   110M|    33M| 18870   (1)|     50 |00:00:00.70 |   17633 |    238 |    85M|  7720K|   80M (0)|
|   6 |     TABLE ACCESS FULL| ORDERS              |      1 |   1352K|    18M|       |  4825   (1)|   1352K|00:00:00.32 |   17630 |      0 |       |       |          |
|   7 |     TABLE ACCESS FULL| ORDER_ITEMS         |      1 |   3735K|    60M|       |  7228   (1)|     50 |00:00:00.01 |       3 |    238 |       |       |          |
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
Outline Data
-------------
 
  /*+
      BEGIN_OUTLINE_DATA
      IGNORE_OPTIM_EMBEDDED_HINTS
      OPTIMIZER_FEATURES_ENABLE('19.1.0')
      DB_VERSION('19.1.0')
      ALL_ROWS
      OUTLINE_LEAF(@"SEL$EE94F965")
      MERGE(@"SEL$9E43CB6E" >"SEL$4")
      OUTLINE(@"SEL$4")
      OUTLINE(@"SEL$9E43CB6E")
      MERGE(@"SEL$58A6D7F6" >"SEL$3")
      OUTLINE(@"SEL$3")
      OUTLINE(@"SEL$58A6D7F6")
      MERGE(@"SEL$1" >"SEL$2")
      OUTLINE(@"SEL$2")
      OUTLINE(@"SEL$1")
      FULL(@"SEL$EE94F965" "O"@"SEL$2")
      FULL(@"SEL$EE94F965" "OI"@"SEL$1")
      FULL(@"SEL$EE94F965" "P"@"SEL$1")
      FULL(@"SEL$EE94F965" "C"@"SEL$3")
      LEADING(@"SEL$EE94F965" "O"@"SEL$2" "OI"@"SEL$1" "P"@"SEL$1" "C"@"SEL$3")
      USE_HASH(@"SEL$EE94F965" "OI"@"SEL$1")
      USE_HASH(@"SEL$EE94F965" "P"@"SEL$1")
      USE_HASH(@"SEL$EE94F965" "C"@"SEL$3")
      SWAP_JOIN_INPUTS(@"SEL$EE94F965" "P"@"SEL$1")
      SWAP_JOIN_INPUTS(@"SEL$EE94F965" "C"@"SEL$3")
      END_OUTLINE_DATA
  */
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   1 - access("C"."CUSTOMER_ID"="O"."CUSTOMER_ID")
   3 - access("OI"."PRODUCT_ID"="P"."PRODUCT_ID")
   5 - access("O"."ORDER_ID"="OI"."ORDER_ID")
 
Note
-----
   - this is an adaptive plan
--Leading shows that the first table to be picked up is ORDER, followed by ORDER_ITEMS, PRODUCT_INFORMATION and CUSTOMERS.
--
SELECT /*+ GATHER_PLAN_STATISTICS */
	E.ENAME,
	D.DNAME
FROM
	SOE.EMP E, SOE.DEPT D 
WHERE E.DEPT_NO = D.DEPT_NO 
AND E.DEPT_NO = 50;
--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format=> 'ALLSTATS LAST +cost +bytes +outline'));
--
SQL_ID  3cvnw12924wuq, child number 0
-------------------------------------
SELECT /*+ GATHER_PLAN_STATISTICS */  E.ENAME,  D.DNAME FROM  SOE.EMP 
E, SOE.DEPT D  WHERE E.DEPT_NO = D.DEPT_NO  AND E.DEPT_NO = 50
 
Plan hash value: 1706465873
 
-------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                            | Name    | Starts | E-Rows |E-Bytes| Cost (%CPU)| A-Rows |   A-Time   | Buffers |
-------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                     |         |      1 |        |       |     3 (100)|     23 |00:00:00.01 |       5 |
|   1 |  NESTED LOOPS                        |         |      1 |     23 |   736 |     3   (0)|     23 |00:00:00.01 |       5 |
|   2 |   TABLE ACCESS BY INDEX ROWID        | DEPT    |      1 |      1 |    13 |     1   (0)|      1 |00:00:00.01 |       2 |
|*  3 |    INDEX UNIQUE SCAN                 | DEPT_PK |      1 |      1 |       |     0   (0)|      1 |00:00:00.01 |       1 |
|   4 |   TABLE ACCESS BY INDEX ROWID BATCHED| EMP     |      1 |     23 |   437 |     2   (0)|     23 |00:00:00.01 |       3 |
|*  5 |    INDEX RANGE SCAN                  | DEPT_IX |      1 |     23 |       |     1   (0)|     23 |00:00:00.01 |       2 |
-------------------------------------------------------------------------------------------------------------------------------
 
Outline Data
-------------
 
  /*+
      BEGIN_OUTLINE_DATA
      IGNORE_OPTIM_EMBEDDED_HINTS
      OPTIMIZER_FEATURES_ENABLE('19.1.0')
      DB_VERSION('19.1.0')
      ALL_ROWS
      OUTLINE_LEAF(@"SEL$1")
      INDEX_RS_ASC(@"SEL$1" "D"@"SEL$1" ("DEPT"."DEPT_NO"))
      INDEX_RS_ASC(@"SEL$1" "E"@"SEL$1" ("EMP"."DEPT_NO"))
      BATCH_TABLE_ACCESS_BY_ROWID(@"SEL$1" "E"@"SEL$1")
      LEADING(@"SEL$1" "D"@"SEL$1" "E"@"SEL$1")
      USE_NL(@"SEL$1" "E"@"SEL$1")
      END_OUTLINE_DATA
  */
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   3 - access("D"."DEPT_NO"=50)
   5 - access("E"."DEPT_NO"=50)

--
