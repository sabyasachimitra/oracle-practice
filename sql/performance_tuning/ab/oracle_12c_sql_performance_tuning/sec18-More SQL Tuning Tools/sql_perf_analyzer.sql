/* Using SQL Performance Analyzer */
--
/* Assessing Workload SQL Statements Performance Before and After Upgrade */
--
/* In the following steps, you will capture a workload SQL statements 
/* that you want to assess their performance before and after the database upgrade.
/* This test is performed in a Simulated Environment where 
/* 
--
1) you first change the Optimizer feature to a previous database version.
2) create a SQL Tuning set.
3) run the SQL workload.
4) capture the SQL statements performance statistics in the SQL Tuning Set.  
6) create a stage table and pack (load) the SQL Tuning set into a stage table.
7) export the table to a data dump using the data pump utility.
--
/* Capturing SQL Workload */
-- login as sys 
-- set sqlprompt "ADMIN> "
show parameter OPTIMIZER_FEATURES_ENABLE
--
/*
NAME                                 TYPE        VALUE
------------------------------------ ----------- ----------
optimizer_features_enable            string      19.1.0
*/
--
ALTER SYSTEM SET OPTIMIZER_FEATURES_ENABLE='11.2.0.2' SCOPE=SPFILE;
--
/* Restart the Database server */
--
srvctl stop database -db cdb01
--
srvctl start database -db cdb01
--
show parameter OPTIMIZER_FEATURES_ENABLE
--
/*
NAME                                 TYPE        VALUE
------------------------------------ ----------- -------------
optimizer_features_enable            string      11.2.0.2
*/
--
/* Create a SQL tuning set owned by soe */
--
exec DBMS_SQLTUNE.CREATE_SQLSET ( SQLSET_NAME => 'SOE_WKLD_STS' , SQLSET_OWNER=>'SOE', DESCRIPTION => 'SQL to assess for upgrade' );
--
--open another sqlplus session and login with soe 
--
/* In the admin window, run the following code to capture the SQL statements that are parsed by 
/* soe from the cursor cache for one minute every three seconds. Go to the SOE session without waiting */
--
begin
DBMS_SQLTUNE.CAPTURE_CURSOR_CACHE_SQLSET( SQLSET_NAME => 'SOE_WKLD_STS', SQLSET_OWNER=>'SOE', TIME_LIMIT => 60, REPEAT_INTERVAL => 3, BASIC_FILTER =>' UPPER(PARSING_SCHEMA_NAME) = ''SOE''', CAPTURE_MODE => DBMS_SQLTUNE.MODE_REPLACE_OLD_STATS);
end;
/
--
/* In SOE Window */
--
@client_wrkld.sql
--
/* Wait for the capture process in the admin window to finish and exit from the client session */
--
/* Display the statements captured into the STS */
--
set long 1000
SELECT SQL_TEXT FROM DBA_SQLSET_STATEMENTS WHERE SQLSET_NAME='SOE_WKLD_STS';
--
/*
SQL_TEXT
--------------------------------------------------------------------------------
BEGIN :B1 := 4384; END;
SELECT PRODUCTS.PRODUCT_ID, PRODUCT_NAME, PRODUCT_DESCRIPTION, CATEGORY_ID, WEIG
HT_CLASS, WARRANTY_PERIOD, SUPPLIER_ID, PRODUCT_STATUS, LIST_PRICE, MIN_PRICE, C
ATALOG_URL, QUANTITY_ON_HAND FROM PRODUCTS, INVENTORIES WHERE PRODUCTS.PRODUCT_I
D = :B2 AND INVENTORIES.PRODUCT_ID = PRODUCTS.PRODUCT_ID AND ROWNUM < :B1

BEGIN :B2 := 15; END;
SELECT CARD_ID, CUSTOMER_ID, CARD_TYPE, CARD_NUMBER, EXPIRY_DATE, IS_VALID, SECU
RITY_CODE FROM CARD_DETAILS WHERE CUSTOMER_ID = :B2 AND ROWNUM < :B1

BEGIN :B1 := 16493; END;
BEGIN :B3 := 15; END;
SELECT QUANTITY_ON_HAND FROM PRODUCT_INFORMATION P, INVENTORIES I WHERE I.PRODUC
T_ID = :B2 AND I.PRODUCT_ID = P.PRODUCT_ID AND I.WAREHOUSE_ID = :B1

SELECT ORDER_ID, LINE_ITEM_ID, PRODUCT_ID, UNIT_PRICE, QUANTITY,DISPATCH_DATE, R
ETURN_DATE, GIFT_WRAP, CONDITION, SUPPLIER_ID, ESTIMATED_DELIVERY FROM ORDER_ITE
MS WHERE ORDER_ID = :B2 AND ROWNUM < :B1

SELECT ORDER_ID, ORDER_DATE, ORDER_MODE, CUSTOMER_ID, ORDER_STATUS, ORDER_TOTAL,
 SALES_REP_ID, PROMOTION_ID, WAREHOUSE_ID, DELIVERY_TYPE, COST_OF_DELIVERY, WAIT
_TILL_ALL_AVAILABLE, DELIVERY_ADDRESS_ID, CUSTOMER_CLASS, CARD_ID, INVOICE_ADDRE
SS_ID FROM ORDERS WHERE CUSTOMER_ID = :B2 AND ROWNUM < :B1

BEGIN :B1 := 77; END;
SELECT TT.ORDER_TOTAL, TT.SALES_REP_ID, TT.ORDER_DATE, CUSTOMERS.CUST_FIRST_NAME
, CUSTOMERS.CUST_LAST_NAME FROM (SELECT ORDERS.ORDER_TOTAL, ORDERS.SALES_REP_ID,
 ORDERS.ORDER_DATE, ORDERS.CUSTOMER_ID, RANK() OVER (ORDER BY ORDERS.ORDER_TOTAL
 DESC) SAL_RANK FROM ORDERS WHERE ORDERS.SALES_REP_ID = :B1 ) TT, CUSTOMERS WHER
E TT.SAL_RANK <= 10 AND CUSTOMERS.CUSTOMER_ID = TT.CUSTOMER_ID

BEGIN :B1 := 93198; END;
SELECT CUSTOMER_ID, CUST_FIRST_NAME, CUST_LAST_NAME, NLS_LANGUAGE, NLS_TERRITORY
, CREDIT_LIMIT, CUST_EMAIL, ACCOUNT_MGR_ID, CUSTOMER_SINCE, CUSTOMER_CLASS, SUGG
ESTIONS, DOB, MAILSHOT, PARTNER_MAILSHOT, PREFERRED_ADDRESS, PREFERRED_CARD FROM
 CUSTOMERS WHERE CUSTOMER_ID = :B2 AND ROWNUM < :B1

BEGIN :B1 := 11770; END;
BEGIN :B2 := 618; END;
SELECT ORDER_MODE, ORDERS.WAREHOUSE_ID, SUM(ORDER_TOTAL), COUNT(1) FROM ORDERS,
WAREHOUSES WHERE ORDERS.WAREHOUSE_ID = WAREHOUSES.WAREHOUSE_ID AND WAREHOUSES.WA
REHOUSE_ID = :B1 GROUP BY CUBE(ORDERS.ORDER_MODE, ORDERS.WAREHOUSE_ID)

SELECT ADDRESS_ID, CUSTOMER_ID, DATE_CREATED, HOUSE_NO_OR_NAME, STREET_NAME, TOW
N, COUNTY, COUNTRY, POST_CODE, ZIP_CODE FROM ADDRESSES WHERE CUSTOMER_ID = :B2 A
ND ROWNUM < :B1

BEGIN :B2 := 635; END;
BEGIN :B1 := 43; END;
SELECT PRODUCTS.PRODUCT_ID, PRODUCT_NAME, PRODUCT_DESCRIPTION, CATEGORY_ID, WEIG
HT_CLASS, WARRANTY_PERIOD, SUPPLIER_ID, PRODUCT_STATUS, LIST_PRICE, MIN_PRICE, C
ATALOG_URL, QUANTITY_ON_HAND FROM PRODUCTS, INVENTORIES WHERE PRODUCTS.CATEGORY_
ID = :B3 AND INVENTORIES.PRODUCT_ID = PRODUCTS.PRODUCT_ID AND INVENTORIES.WAREHO
USE_ID = :B2 AND ROWNUM < :B1

BEGIN :B1 := 754; END;
BEGIN :B1 := 584; END;
*/
--
/* Stage the STS into a table called SOE_WKLD_STS_TB */
--
exec DBMS_SQLTUNE.CREATE_STGTAB_SQLSET('SOE_WKLD_STS_TB','SOE');
--
exec DBMS_SQLTUNE.PACK_STGTAB_SQLSET('SOE_WKLD_STS','SOE','SOE_WKLD_STS_TB','SOE');
--
/* Using Data Pump Export utility, export the table to the default Data Pump directory */
--
-- login to Linux terminal and run data pump utility
--
expdp soe/oracle@db19c01 directory=DATA_PUMP_DIR dumpfile=SOE_WKLD_STS_TB.dmp tables=SOE_WKLD_STS_TB
--
/* check the Linux file system location of the Oracle Direcory */
--
select * from dba_directories where directory_name = 'DATA_PUMP_DIR';
/*
-- in this directory you'll see a file with .dmp extension - SOE_WKLD_STS_TB.dmp
/u01/app/oracle/admin/cdb01/dpdump/CBC7BE136B294E92E0536B38A8C04874
*/
/* Drop the STS and the staging table */
--
exec DBMS_SQLTUNE.DROP_SQLSET( SQLSET_NAME => 'SOE_WKLD_STS',SQLSET_OWNER=>'SOE');
--
DROP TABLE SOE.SOE_WKLD_STS_TB;
/* In a real life scenario, you would copy the generated dump 
file from the source database to the target testing database. */
--
/* Using Data Pump Import utility, import the staging table into the soe schema */
--
impdp soe/oracle@db19c01 directory=DATA_PUMP_DIR dumpfile=SOE_WKLD_STS_TB.dmp tables=SOE_WKLD_STS_TB
--
/* Create a SQL tuning set owned by soe to save the workload SQL statements in it */
--
exec DBMS_SQLTUNE.CREATE_SQLSET ( SQLSET_NAME => 'SOE_WKLD_STS' , SQLSET_OWNER=>'SOE', DESCRIPTION => 'SQL to assess for upgrade' );
--
/* Unpack the staging table into the STS */
--
exec DBMS_SQLTUNE.UNPACK_STGTAB_SQLSET('SOE_WKLD_STS','SOE',TRUE,'SOE_WKLD_STS_TB','SOE');
--
-- Verify
set long 1000
SELECT SQL_TEXT FROM DBA_SQLSET_STATEMENTS WHERE SQLSET_NAME='SOE_WKLD_STS';
--
/* Create a SQL performance analyzer task that is linked to 
/* the STS and save the returned task name into a variable */
--
VARIABLE v_task VARCHAR2(64)
exec :v_task := DBMS_SQLPA.CREATE_ANALYSIS_TASK(SQLSET_NAME => 'SOE_WKLD_STS', SQLSET_OWNER=>'SOE');
print :v_task
--
/*
V_TASK
-------------
TASK_196
*/
--
/* Execute the performance analyzer task to run the contents 
   of the STS against the current state of the database.
*/
BEGIN
    DBMS_SQLPA.EXECUTE_ANALYSIS_TASK(TASK_NAME => :v_task,EXECUTION_TYPE => 'TEST EXECUTE',EXECUTION_NAME => 'before');
END;
/
--
select DBMS_SQLPA.REPORT_ANALYSIS_TASK(TASK_NAME => :v_task,TYPE=>'TEXT',SECTION=>'SUMMARY') from dual;
--
/*
DBMS_SQLPA.REPORT_ANALYSIS_TASK(TASK_NAME=>:V_TASK,TYPE=>'TEXT',SECTION=>'SUMMAR
--------------------------------------------------------------------------------
GENERAL INFORMATION SECTION
-------------------------------------------------------------------------------
Tuning Task Name                  : TASK_196
Tuning Task Owner                 : SYS
Workload Type                     : SQL Tuning Set
Execution Count                   : 1
Current Execution                 : before
Execution Type                    : TEST EXECUTE
Scope                             : COMPREHENSIVE
Completion Status                 : COMPLETED
Started at                        : 03/11/2023 01:56:47
Completed at                      : 03/11/2023 01:56:47
SQL Tuning Set (STS) Name         : SOE_WKLD_STS
SQL Tuning Set Owner              : SOE
Number of Statements in the STS   : 22
Number of SQLs Analyzed           : 22
Number of SQLs in the Report      : 22
Number of SQLs with Findings      : 12
*/
--
/* Change OPTIMIZER_FEATURES_ENABLE now to 19.1.0 */
--
show parameter OPTIMIZER_FEATURES_ENABLE
--
ALTER SYSTEM SET OPTIMIZER_FEATURES_ENABLE='19.1.0' SCOPE=SPFILE;
--
/* After applying the changes, re-execute the analyzer task using a new execution name */
--
BEGIN
DBMS_SQLPA.EXECUTE_ANALYSIS_TASK(TASK_NAME => 'TASK_196',EXECUTION_TYPE => 'TEST EXECUTE', EXECUTION_NAME => 'after');
END;
/
--
/* Execute a comparison task between the last two executions */
--
exec DBMS_SQLPA.EXECUTE_ANALYSIS_TASK(TASK_NAME => 'TASK_196', EXECUTION_TYPE => 'COMPARE PERFORMANCE');
--
set long 10000
set heading off
SPOOL report.html
select DBMS_SQLPA.REPORT_ANALYSIS_TASK(TASK_NAME => 'TASK_196', TYPE=>'HTML', SECTION=>'ALL') from dual;
SPOOL OFF