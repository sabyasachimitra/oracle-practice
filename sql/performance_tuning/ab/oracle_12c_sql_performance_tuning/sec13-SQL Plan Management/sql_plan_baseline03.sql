--
-- Manually Loading Plans into SQL Plan Baselines
--
-- Manually loading the plans is independent of the automatic SQL plan capture. 
-- You can manually load SQL plans while the SQL plan even when SQL Plan capture is disabled.
--
-- In this demonstration we will create a STS (SQL Tuning Set) and load the SQL plan in STS into SQL Plan baseline.
-- You can also load SQL plans from AWR, shared SQL area, store outlines, or staging tables into SQL Plan baseline.
--
-- In SYS window (sqlplus sys/oracle@db19c01 as sysdba).
--
ALTER SYSTEM FLUSH SHARED_POOL;
--
ALTER SYSTEM FLUSH BUFFER_CACHE;
--
-- create SQL Tuning Set
--
VARIABLE STS_WORKLOAD VARCHAR2(255);
--
exec :STS_WORKLOAD := 'STS_CURSOR';
exec DBMS_SQLTUNE.CREATE_SQLSET(:STS_WORKLOAD, 'STS from Cursor Cache');
--
-- In client window (SOE): execute the SQL workload.
set linesize 180
--
@execute_workload.sql
--
-- In SYS window
-- load the SQL Tuning Set.
--
DECLARE
v_sts_cursor DBMS_SQLTUNE.SQLSET_CURSOR;
BEGIN
   OPEN v_sts_cursor FOR SELECT VALUE(P) FROM TABLE(DBMS_SQLTUNE.SELECT_CURSOR_CACHE) P WHERE PARSING_SCHEMA_NAME='SOE';
-- Load the statements into STS
   DBMS_SQLTUNE.LOAD_SQLSET(:STS_WORKLOAD, V_sts_cursor);
   CLOSE v_sts_cursor;
END;
/
--
-- check the SQL text in the SQL Tuning Set.
--
col SQL_TEXT format a150
SELECT SQL_TEXT FROM DBA_SQLSET_STATEMENTS WHERE SQLSET_NAME = :STS_WORKLOAD;
--
SQL_TEXT
-------------------------------------------------------------------------------------------------------
SELECT
        ORDER_ID,
        ORDER_DATE,
        ORDER_TOTAL
FROM ORDERS WHERE ORDER_DATE BETWEEN TO_DATE(:V1, 'DD-MON-YYYY') AND TO_DATE(:V2, 'DD-MON-YYYY')

SELECT
        E.ENAME, SUM(O.ORDER_TOTAL) ORDER_TOTALS, AVG(O.ORDER_TOTAL) AVERAGE_ORDER_TOTAL , COUNT(O.ORDER_ID) ORDERS_COUNT
FROM
        ORDERS O, EMP E
WHERE
        E.EMP_NO = O.SALES_REP_ID
GROUP BY E.ENAME
HAVING SUM(O.ORDER_TOTAL) > 10000
ORDER BY SUM(O.ORDER_TOTAL)

SELECT
        ORDER_ID,
        ORDER_DATE,
        ORDER_TOTAL,
        CUSTOMER_ID
FROM ORDERS WHERE ORDER_DATE BETWEEN TO_DATE(:V1, 'DD-MON-YYYY') AND TO_DATE(:V2, 'DD-MON-YYYY')

SELECT
        CUSTOMER_ID,
        CUST_FIRST_NAME,
        CUST_LAST_NAME,
        NLS_LANGUAGE,
        NLS_TERRITORY
FROM
        CUSTOMERS C WHERE NLS_LANGUAGE=:V1 AND NLS_TERRITORY=:V2
--
-- another possible query to use:
--
col SQL_ID format a13
col COMMAND_TYPE format 99
col SQL_TEXT format a70
SELECT SQL_ID, COMMAND_TYPE, SUBSTR(SQL_TEXT,1,70) SQL_TEXT FROM TABLE(
DBMS_SQLTUNE.SELECT_SQLSET( :STS_WORKLOAD ));
--
SQL_ID        COMMAND_TYPE SQL_TEXT
------------- ------------ ----------------------------------------------------------------------
1bd488zv13v2n            3 SELECT
                                ORDER_ID,
                                ORDER_DATE,
                                ORDER_TOTAL,
                                CUSTOMER_ID
                           FROM ORDERS

2dcy83yp334fy            3 SELECT
                                ORDER_ID,
                                ORDER_DATE,
                                ORDER_TOTAL
                           FROM ORDERS WHERE ORDER_DA

6bawcpnrt76va            3 SELECT
                                E.ENAME, SUM(O.ORDER_TOTAL) ORDER_TOTALS, AVG(O.ORDER_TOTAL) A

f38v4m07d3zhf            3 SELECT
                                CUSTOMER_ID,
                                CUST_FIRST_NAME,
                                CUST_LAST_NAME,
                                NLS_LANGUAGE,
--
-- load the plans from the STS into SQL Plan Baseline.
-- the function DBMS_SPM.LOAD_PLANS_FROM_SQLSET accepts also the parameter
-- BASIC_FILTER, which is used if you want to apply a filter to select which plans to load.
--
set serveroutput on
DECLARE
v_plan_cnt NUMBER;
BEGIN
   v_plan_cnt := DBMS_SPM.LOAD_PLANS_FROM_SQLSET( SQLSET_NAME => :STS_WORKLOAD);
   DBMS_OUTPUT.PUT_LINE('Number of Loaded Plans: ' || v_plan_cnt );
END;
/                                
-- As expected.
Number of Loaded Plans: 4
--
-- verify if the plans are loaded
--
@display_soe_baselines.sql
-- 
-- check the ORIGIN. It's MANUAL-LOAD-FROM-STS instead of AUTO-CAPTURE (previously).
-- also all SQL plans are accepted in the SQL Plan Baseline.
--
SQL_HANDLE           SQL_TEXT                                           ENA ACC FIX  COST DISK_READS BUFFER_GETS    FETCHES ELAPSED_TIME ORIGIN
-------------------- -------------------------------------------------- --- --- --- ----- ---------- ----------- ---------- ------------ -----------------------------
SQL_89b76415724b04a5 SELECT                                             YES YES NO    214        800        2200          4        ##### MANUAL-LOAD-FROM-STS
                        CUSTOMER_ID,
                        CUST_FIRST_NAME,
                        CUST_LAST_NAME,
                        NLS_LANGUAGE,
                        NLS_TERRITORY
                     FROM
                        CUSTOMERS C WHERE NLS_LANGUAGE=:V1 AND NLS_TERRIT
                     ORY=:V2

SQL_7200042bbd33328d SELECT                                             YES YES NO   4915          0       #####       7503        ##### MANUAL-LOAD-FROM-STS
                        ORDER_ID,
                        ORDER_DATE,
                        ORDER_TOTAL
                     FROM ORDERS WHERE ORDER_DATE BETWEEN TO_DATE(:V1,
                     'DD-MON-YYYY') AND TO_DATE(:V2, 'DD-MON-YYYY')

SQL_1c420c270e9af177 SELECT                                             YES YES NO   4872      #####       #####         48        ##### MANUAL-LOAD-FROM-STS
                        E.ENAME, SUM(O.ORDER_TOTAL) ORDER_TOTALS, AVG(O.O
                     RDER_TOTAL) AVERAGE_ORDER_TOTAL , COUNT(O.ORDER_ID
                     ) ORDERS_COUNT
                     FROM
                        ORDERS O, EMP E
                     WHERE
                        E.EMP_NO = O.SALES_REP_ID
                     GROUP BY E.ENAME
                     HAVING SUM(O.ORDER_TOTAL) > 10000
                     ORDER BY SUM(O.ORDER_TOTAL)

SQL_0692bd3e196ddb0b SELECT                                             YES YES NO   4908      #####       #####       6683        ##### MANUAL-LOAD-FROM-STS
                        ORDER_ID,
                        ORDER_DATE,
                        ORDER_TOTAL,
                        CUSTOMER_ID
                     FROM ORDERS WHERE ORDER_DATE BETWEEN TO_DATE(:V1,
                     'DD-MON-YYYY') AND TO_DATE(:V2, 'DD-MON-YYYY')
--
-- if you want to display the plan of any of the SQL statements in the baseline, run the below SQL
--
SELECT PLAN_TABLE_OUTPUT
FROM DBA_SQL_PLAN_BASELINES B,
TABLE(
DBMS_XPLAN.DISPLAY_SQL_PLAN_BASELINE(B.SQL_HANDLE,B.PLAN_NAME,'BASIC') ) T
WHERE SQL_HANDLE='&_ENTER_SQL_HANDLE'
ORDER BY B.SIGNATURE;                     
--
SQL handle: SQL_89b76415724b04a5
SQL text: SELECT        CUSTOMER_ID,    CUST_FIRST_NAME,        CUST_LAST_NAME,
                NLS_LANGUAGE,   NLS_TERRITORY FROM      CUSTOMERS C WHERE
          NLS_LANGUAGE=:V1 AND NLS_TERRITORY=:V2
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
Plan name: SQL_PLAN_8mdv42pt4q15564541f84         Plan id: 1683234692
Enabled: YES     Fixed: NO      Accepted: YES     Origin: MANUAL-LOAD-FROM-STS
Plan rows: From dictionary
--------------------------------------------------------------------------------

Plan hash value: 2008213504

---------------------------------------
| Id  | Operation         | Name      |
---------------------------------------
|   0 | SELECT STATEMENT  |           |
|   1 |  TABLE ACCESS FULL| CUSTOMERS |
---------------------------------------
--
-- in the SOE window run the SQL to verify if it's using the corresponding SQL Plan baseline
--
VARIABLE V1 VARCHAR2(15);
VARIABLE V2 VARCHAR2(15);
exec :V1:='KG'
exec :V2:='Florida'
set autot on
SELECT CUSTOMER_ID, CUST_FIRST_NAME, CUST_LAST_NAME, NLS_LANGUAGE, NLS_TERRITORY
FROM CUSTOMERS C WHERE NLS_LANGUAGE=:V1 AND NLS_TERRITORY=:V2;
set autot off
--
Execution Plan
----------------------------------------------------------
Plan hash value: 2008213504

-------------------------------------------------------------------------------
| Id  | Operation         | Name      | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |           |     3 |    96 |   214   (1)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| CUSTOMERS |     3 |    96 |   214   (1)| 00:00:01 |
-------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("NLS_LANGUAGE"=:V1 AND "NLS_TERRITORY"=:V2)

Note
-----
   - SQL plan baseline "SQL_PLAN_8mdv42pt4q15564541f84" used for this statement
--
--
-- Transporting the Plan Baselines :: we will pack the SQL Plan Baseline into a stage table and unpack it into another table
-- in another database. This is useful when you want to transfer SQL Plan baselines from one database to another.
--
-- create a baseline staging table.
--
exec DBMS_SPM.CREATE_STGTAB_BASELINE( TABLE_NAME => 'BASELINES_TAB', TABLE_OWNER=>'SOE');
--
-- Pack the SQL plan baselines you want to export from the SQL management base into the staging table.
-- The function DBMS_SPM.PACK_STGTAB_BASELINE provides parameters to pack specific plan in the Baseline.
--
set serveroutput on
DECLARE
v_plan_cnt NUMBER;
BEGIN
   v_plan_cnt := DBMS_SPM.PACK_STGTAB_BASELINE( TABLE_NAME => 'BASELINES_TAB', TABLE_OWNER=>'SOE');
   DBMS_OUTPUT.PUT_LINE('Number of Packed SQL Plan Baselines: ' || v_plan_cnt );
END;
/
Number of Packed SQL Plan Baselines: 4
--
-- In Real life scenario you export the table and import it into a different database through data dump and then Unpack it.
-- In this example, we will unpack the table in the same database.
-- 
DECLARE
v_plan_cnt NUMBER;
BEGIN
   v_plan_cnt := DBMS_SPM.UNPACK_STGTAB_BASELINE ( TABLE_NAME => 'BASELINES_TAB', TABLE_OWNER=>'SOE');
   DBMS_OUTPUT.PUT_LINE('Number of Unpacked SQL Plan Baselines: ' || v_plan_cnt );
END;
/
--
Number of Unpacked SQL Plan Baselines: 4
--
--
-- Clean up
--
VARIABLE STS_WORKLOAD VARCHAR2(255);
exec :STS_WORKLOAD := 'STS_CURSOR';
DROP TABLE SOE.BASELINES_TAB;
exec DBMS_SQLTUNE.DROP_SQLSET(:STS_WORKLOAD)
@drop_baselines.sql
--
