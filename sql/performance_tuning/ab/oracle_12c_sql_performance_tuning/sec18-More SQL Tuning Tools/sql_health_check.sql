--
/* SQL Tuning Health-Check Script is a scropt developed by the Oracle Server Technologies Center of Expertise */
/* The tool, known as SQLHC, is used to diagnose performance issues on a single specific query */
/* It checks the environment in which a single SQL Statement runs, the cost-based optimizer (CBO) */
/* statistics schema object metadata, configuration parameters and other elements that may influence SQL performance */
/* The tool can be downloaded from Oracle support Doc ID 1366133.1 */
/* It's a zip file of three SQL files which together constitue the SQLHC tool */
--
--login as soe/oracle
--
/* Run the following SQL query */
--
SELECT /* my query */
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
/* Retrieve the statement SQL_ID and take a note of it */
--
COL SQL_COMMAND FORMAT A50
SELECT
    SUBSTR(SQL_TEXT,
    1,
    50) SQL_COMMAND,
    SQL_ID
FROM
    V$SQL
WHERE
    SQL_TEXT LIKE 'SELECT /* my query */%';
--
/*
SQL_COMMAND                                        SQL_ID
-------------------------------------------------- -------------
SELECT /* my query */     CUST_FIRST_NAME FNAME,   bry2uqc28yzfn
*/
--
/* login in a seprate session as sys and run sqlhc.sql script */
/* when prompts to enter value for 1, enter  ‘T’ */
/* when prompts to enter value for 2, enter the value of the SQL ID and wait for the script to finish */    
/* This would generate a zip file in which you will file the analysis report */
--
@sqlhc.sql
--

