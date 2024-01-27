/* Using SQL Access Advisor with SQL Tuning Set */
/* We will use the SQL Access Advisor to tune a set of provided SQL statements of a workload */ 
/* by workload we mean the set of SQL statements that when are executed together, they perform */
/* specific business function. */
--
/* High Level Steps */

/* 1) Create a new SQL Tuning Set (provide workload name)
   2) Store SQL statements that you want to tune in a table and load them into Tuning set from the table 
      referenced by the workload. 
   3) Create a SQL Access Advisor Task and set parameters if required.
   4) Link the task to the Workload. 
   5) Execute the workload
   6) Check recommendation and generate recommendation script (if required). 
   7) Identify the benefits each workload SQL statement gains
*/   
-- connect as soe user
/* Create SQL set */
--
set serveroutput on
VARIABLE TASK_ID NUMBER;
VARIABLE STS_WRKLD_NAME VARCHAR2(255);
exec :STS_WRKLD_NAME := 'MY_STS_WORKLOAD';
exec DBMS_SQLTUNE.CREATE_SQLSET(:STS_WRKLD_NAME, 'for testing');
--
/* verify if SQL set is created */
--
col NAME format a20
col DESCRIPTION format a20
--
SELECT
    name,
    description
FROM
    user_sqlset;
--
NAME                 DESCRIPTION
-------------------- --------------------
MY_STS_WORKLOAD      for testing    
--
/* create SOE.SOE_WORKLOAD to store the workload SQL statements */
--
DROP TABLE soe.soe_workload;

CREATE TABLE soe.soe_workload (
    username            VARCHAR2(128), /* User who executes statement */
    module              VARCHAR2(64), /* Application module name */
    action              VARCHAR2(64), /* Application action name */
    elapsed_time        NUMBER, /* Elapsed time for query */
    cpu_time            NUMBER, /* CPU time for query */
    buffer_gets         NUMBER, /* Buffer gets consumed by query */
    disk_reads          NUMBER, /* Disk reads consumed by query */
    rows_processed      NUMBER, /* # of rows processed by query */
    executions          NUMBER, /* # of times query executed */
    optimizer_cost      NUMBER, /* Optimizer cost for query */
    priority            NUMBER, /* User-priority (1,2 or 3) */
    last_execution_date DATE, /* Last time query executed */
    stat_period         NUMBER, /* Window exec time in seconds */
    sql_text            CLOB /* Full SQL Text */
);
--
/* load the SOE_WORKLOAD table with the workload queries */
--
INSERT INTO soe_workload (
    username,
    module,
    action,
    priority,
    sql_text
) 
VALUES (
    'SOE',
    'BATCH_MOD',
    'PROCESS_ORDERS',
    2,
    'SELECT
    e.ename,
    SUM(o.order_total) order_totals,
    AVG(o.order_total) average_order_total,
    COUNT(o.order_id)  orders_count
FROM
    orders o,
    emp    e
WHERE
    e.emp_no = o.sales_rep_id
GROUP BY
    e.ename
HAVING
    SUM(o.order_total) > 10000
ORDER BY
    sum( o.order_total)'
);
--
INSERT INTO soe_workload (
    username,
    module,
    action,
    priority,
    sql_text
) 
VALUES (
    'SOE',
    'BATCH_MOD ',
    'PROCESS_ORDERS',
    2,
    'SELECT
        *
    FROM
        orders 
    WHERE 
    order_date BETWEEN to_date(''01-JAN-2010'', ''DDMON-YYYY'') 
    AND 
    TO_DATE(''31-DEC-2010'', '' dd - mon - yyyy '' ) '
);
--
INSERT INTO soe_workload (
    username,
    module,
    action,
    priority,
    sql_text
) VALUES (
    'SOE',
    'BATCH_MOD ',
    'PROCESS_ORDERS',
    2,
    'SELECT
        customer_id,
        cust_first_name,
        cust_last_name,
        nls_language,
        nls_territory
FROM
    customers2 c
WHERE
    nls_language = ''IA'' AND
NLS_TERRITORY= '' new york'''
);

COMMIT;
--
/* Execute the following PL/SQL program to fill the cursor with rows from the
   SOE_WORKLOAD table and then load the contents of the cursor into the STS. */
--
DECLARE
    v_sqlset_cur dbms_sqltune.sqlset_cursor;
BEGIN
    OPEN v_sqlset_cur FOR
-- create a row of SQLSET object type and load SQL statements from workload table
     SELECT
          sqlset_row(NULL, NULL, sql_text, NULL, NULL,
                     'SOE', module, 'Action', 0, 0,
                     0, 0, 0, 1, 0,
                     1, 0, 0, NULL, 2,
                     3, sysdate, 0, 0, NULL,
                     0, NULL, NULL)
      FROM
          soe_workload;
-- populate the SQL tunning set
    dbms_sqltune.load_sqlset(:sts_wrkld_name, v_sqlset_cur);
END;
/
--
/* display information about the SQL statements loaded into the SQL tuning set */
--
set linesize 180
col SQL_ID format a13
col SCHEMA format a5
col COMMAND_TYPE format 99
col PRIORITY format 9
col SQL_TEXT format a50
--
SELECT
    sql_id,
    parsing_schema_name     schema,
    command_type,
    priority,
    substr(sql_text, 1, 50) sql_text
FROM
    TABLE ( dbms_sqltune.select_sqlset(:sts_wrkld_name) );
--
SQL_ID        SCHEM COMMAND_TYPE PRIORITY SQL_TEXT
------------- ----- ------------ -------- --------------------------------------------------
27gpdxccjdac3 SOE              3        2 SELECT
                                                  customer_id,
                                                  cust_first_nam

2k0xjna2gw32s SOE              3        2 SELECT
                                                  *
                                              FROM
                                                  orders
                                              WHERE

5fca0zd0pr4qa SOE              3        2 SELECT
                                              e.ename,
                                              SUM(o.order_total) order_t    
--
/* create SQL access Advisor task */
--
VARIABLE V_TASK_NAME VARCHAR2(20)
exec :V_TASK_NAME := 'SAA_TASK';
VARIABLE TASK_ID VARCHAR2(50)
--
exec DBMS_ADVISOR.CREATE_TASK(ADVISOR_NAME=>'SQL Access Advisor', TASK_ID=>:TASK_ID, TASK_NAME=>:V_TASK_NAME, TASK_DESC=>'A task to test using the SQL Access Advisor');
--
print :v_task_name
--
V_TASK_NAME
--------------
SAA_TASK
--
/* display the task parameters and their values */
--
col PARAMETER_NAME format a22
col VALUE format a15
col DEF format a2
col DESCRIPTION format a50
SELECT
    parameter_name,
    parameter_value value,
    is_default      def,
    description
FROM
    user_advisor_parameters
WHERE
    task_name = :v_task_name;
--
/* change task parameter (optional) */
-- changing the time limit or how long the advisor task will run 
-- maximum value ADVISOR_UNLIMITED, which is technically equivalent to 10000 (one week)
--
exec DBMS_ADVISOR.SET_TASK_PARAMETER(TASK_NAME=>:V_TASK_NAME, PARAMETER=>'TIME_LIMIT', VALUE=>30);
--
/* link the task to the worklload - this step is special for SQL Access Advisor. It was not required SQL Tuning Advisor */
--
exec DBMS_ADVISOR.ADD_STS_REF(:V_TASK_NAME, 'SOE', :STS_WRKLD_NAME);
--
/* execute the task and not down the task name */
exec DBMS_ADVISOR.EXECUTE_TASK(:V_TASK_NAME);
--
/* check the status of the task */
col TASK_ID FORMAT 9999
col TASK_NAME FORMAT a25
col STATUS_MESSAGE FORMAT a40
--
SELECT
    task_id,
    task_name,
    status,
    status_message
FROM
    user_advisor_log
WHERE
    task_name = :v_task_name;
--
TASK_ID TASK_NAME                 STATUS      STATUS_MESSAGE
------- ------------------------- ----------- ----------------------------------------
    140 SAA_TASK                  COMPLETED   Access advisor execution completed
--
/* to view the recommendations of the SQL Advisor Task */
@display_myrecommendations.sql
--
Procedure created.

=========================================
Task_name = SAA_TASK
Action ID: 1
Command : CREATE MATERIALIZED VIEW LOG
Attr1 (name) : "SOE"."EMP"
Attr2 (tablespace):
Attr3 : ROWID, SEQUENCE
Attr4 :  INCLUDING NEW VALUES
Attr5 :
----------------------------------------
Action ID: 3
Command : CREATE MATERIALIZED VIEW LOG
Attr1 (name) : "SOE"."ORDERS"
Attr2 (tablespace):
Attr3 : ROWID, SEQUENCE
Attr4 :  INCLUDING NEW VALUES
Attr5 :
----------------------------------------
Action ID: 5
Command : CREATE MATERIALIZED VIEW LOG
Attr1 (name) : "SOE"."CUSTOMERS2"
Attr2 (tablespace):
Attr3 : ROWID
Attr4 :
Attr5 :
----------------------------------------
Action ID: 7
Command : CREATE MATERIALIZED VIEW
Attr1 (name) : "SOE"."MV$$_008C0000"
Attr2 (tablespace):
Attr3 : REFRESH FAST WITH ROWID
Attr4 : ENABLE QUERY REWRITE
Attr5 :
----------------------------------------
Action ID: 8
Command : GATHER TABLE STATISTICS
Attr1 (name) : "SOE"."MV$$_008C0000"
Attr2 (tablespace):
Attr3 : -1
Attr4 :
Attr5 :
----------------------------------------
Action ID: 9
Command : CREATE MATERIALIZED VIEW
Attr1 (name) : "SOE"."MV$$_008C0001"
Attr2 (tablespace):
Attr3 : REFRESH FAST WITH ROWID
Attr4 : ENABLE QUERY REWRITE
Attr5 :
----------------------------------------
Action ID: 10
Command : GATHER TABLE STATISTICS
Attr1 (name) : "SOE"."MV$$_008C0001"
Attr2 (tablespace):
Attr3 : -1
Attr4 :
Attr5 :
----------------------------------------
Action ID: 11
Command : CREATE INDEX
Attr1 (name) : "SOE"."MV$$_008C0001_IDX$$_008
Attr2 (tablespace):
Attr3 : "SOE"."MV$$_008C0001"
Attr4 : BTREE
Attr5 :
----------------------------------------
=========END RECOMMENDATIONS============"
--
/* Identify which query benefits from which recommendation. */
SELECT
    sql_id,
    rec_id,
    precost,
    postcost,
    ( precost - postcost ) * 100 / precost AS percent_benefit,
    substr(sql_text, 1, 100)               sql_text
FROM
    user_advisor_sqla_wk_stmts
WHERE
        task_name = :v_task_name
    AND workload_name = :sts_wrkld_name
ORDER BY
    percent_benefit DESC;
--
SQL_ID            REC_ID    PRECOST   POSTCOST PERCENT_BENEFIT SQL_TEXT
------------- ---------- ---------- ---------- --------------- --------------------------------------------------
5fca0zd0pr4qa          2       4873          3      99.9384363 SELECT
                                                                   e.ename,
                                                                   SUM(o.order_total) order_totals,
                                                                   AVG(o.order_total) average_order_total,

27gpdxccjdac3          1         93          3      96.7741935 SELECT
                                                                       customer_id,
                                                                       cust_first_name,
                                                                       cust_last_name,
                                                                       nls_language,


2k0xjna2gw32s          0       4904       4904               0 SELECT
                                                                       *
                                                                   FROM
                                                                       orders
                                                                   WHERE
                                                                   order_date BETWEEN to_date('01-JAN-2010', 'DD'    
--
/* generate the script to implement the advisor recommendations */
-- use sqlplus spool command to save the script in a .sql file
--
@display_task_script.sql
--
SCRIPT
--------------------------------------------------------------------------------
Rem  SQL Access Advisor: Version 19.0.0.0.0 - Production
Rem
Rem  Username:        SOE
Rem  Task:            SAA_TASK
Rem  Execution date:
Rem

CREATE MATERIALIZED VIEW LOG ON
    "SOE"."EMP"
    WITH ROWID, SEQUENCE("EMP_NO","ENAME")
    INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW LOG ON
    "SOE"."ORDERS"
    WITH ROWID, SEQUENCE("ORDER_ID","ORDER_TOTAL","SALES_REP_ID")
    INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW LOG ON
    "SOE"."CUSTOMERS2"
    WITH ROWID ;

CREATE MATERIALIZED VIEW "SOE"."MV$$_008C0000"
    REFRESH FAST WITH ROWID
    ENABLE QUERY REWRITE
    AS SELECT "SOE"."CUSTOMERS2"."CUSTOMER_ID" M1, "SOE"."CUSTOMERS2"."CUST_FIRS
T_NAME"
       M2, "SOE"."CUSTOMERS2"."CUST_LAST_NAME" M3, "SOE"."CUSTOMERS2"."NLS_LANGU
AGE"
       M4, "SOE"."CUSTOMERS2"."NLS_TERRITORY" M5 FROM "SOE"."CUSTOMERS2" WHERE
       ("SOE"."CUSTOMERS2"."NLS_LANGUAGE" = 'IA') AND ("SOE"."CUSTOMERS2"."NLS_T
ERRITORY"
       = ' new york');

begin
  dbms_stats.gather_table_stats('"SOE"','"MV$$_008C0000"',NULL,dbms_stats.auto_s
ample_size);
end;
/

CREATE MATERIALIZED VIEW "SOE"."MV$$_008C0001"
    REFRESH FAST WITH ROWID
    ENABLE QUERY REWRITE
    AS SELECT "SOE"."EMP"."ENAME" C1, COUNT("SOE"."ORDERS"."ORDER_ID") M1, SUM("
SOE"."ORDERS"."ORDER_TOTAL")
       M2, COUNT("SOE"."ORDERS"."ORDER_TOTAL") M3, COUNT(*) M4 FROM "SOE"."EMP",

       "SOE"."ORDERS" WHERE "SOE"."ORDERS"."SALES_REP_ID" = "SOE"."EMP"."EMP_NO"

       GROUP BY "SOE"."EMP"."ENAME";

begin
  dbms_stats.gather_table_stats('"SOE"','"MV$$_008C0001"',NULL,dbms_stats.auto_s
ample_size);
end;
/

CREATE INDEX "SOE"."MV$$_008C0001_IDX$$_008C0000"
    ON "SOE"."MV$$_008C0001"
    ("M2")
    COMPUTE STATISTICS;
--
--
/* if you want to reexecute the task follow the below steps */    
--
-- Reset the task and then link the workload to the task again.
exec DBMS_ADVISOR.RESET_TASK(:V_TASK_NAME);
--
set serveroutput on
DECLARE
    n NUMBER;
BEGIN
    SELECT
        COUNT(*)
    INTO n
    FROM
        user_advisor_sqla_wk_map
    WHERE
            task_name = :v_task_name
        AND workload_name = :sts_wrkld_name;

    IF n > 0 THEN
        dbms_advisor.delete_sqlwkld_ref(:v_task_name, :sts_wrkld_name, 1);
        dbms_output.put_line('Link deleted.');
    END IF;

END;
/
--
-- Get Advisor task information from Oracle
--
SELECT
    *
FROM
    dba_advisor_tasks
WHERE
    owner = 'SOE'
ORDER BY
    created DESC;
--
--
SELECT
    *
FROM
    dba_sqlset
WHERE
    owner = 'SOE';
--
--
/* To cleanup, delete the task and its linked STS */
exec DBMS_ADVISOR.DELETE_TASK(:V_TASK_NAME);
-- this command deletes the SQL in the STS but not the STS itself.
exec DBMS_SQLTUNE.DELETE_SQLSET(:STS_WRKLD_NAME);
-- this command deletes the STS
exec DBMS_SQLTUNE.DROP_SQLSET(:STS_WRKLD_NAME);