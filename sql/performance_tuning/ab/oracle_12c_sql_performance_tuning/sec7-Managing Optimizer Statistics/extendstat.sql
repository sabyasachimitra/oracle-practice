--
ALTER SYSTEM FLUSH SHARED_POOL;
--
SHOW PARAMETER STATISTICS_LEVEL
--
--setting STATISTICS_LEVEL to all to make Optimizer to show the actual number of rows return in the execution plan (optional). 
ALTER SESSION SET STATISTICS_LEVEL = ALL;
--
--Gather Stat (Optional).
exec DBMS_STATS.GATHER_TABLE_STATS('SOE', 'CUSTOMERS');
--
--Enable Workload monitoring for 300 seconds (5 minutes).
exec DBMS_STATS.SEED_COL_USAGE(SQLSET_NAME=>NULL, OWNER_NAME=>NULL, TIME_LIMIT=>300);
--
--run the following query or generate the EXPLAIN PLAN
set linesize 200
SELECT * FROM SOE.CUSTOMERS WHERE NLS_LANGUAGE = 'us' AND NLS_TERRITORY='AMERICA';
--
3256 rows selected.
--
--Display the execution plan
SET LINESIZE 200 PAGESIZE 100
--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT=>'+ALLSTATS'));
--
--There is a huge difference (cradinality misestimate) between Estimated rows (E-Rows) and Actual rows returned (A-Rows).
-----------------------------------------------------------------------------------------
| Id  | Operation         | Name      | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-----------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |           |      1 |        |   3256 |00:00:00.01 |     979 |
|*  1 |  TABLE ACCESS FULL| CUSTOMERS |      1 |      1 |   3256 |00:00:00.01 |     979 |
-----------------------------------------------------------------------------------------
--
--Check the column usage information recorded for the SOE.CUSTOMERS table. 
--Observe the column groups returned by the query.
SET LONG 100000
SET LINES 120
SET PAGES 0
SELECT DBMS_STATS.REPORT_COL_USAGE(OWNNAME=>'SOE', TABNAME=>'CUSTOMERS') FROM DUAL;
--
LEGEND:
.......

EQ         : Used in single table EQuality predicate
RANGE      : Used in single table RANGE predicate
LIKE       : Used in single table LIKE predicate
NULL       : Used in single table is (not) NULL predicate
EQ_JOIN    : Used in EQuality JOIN predicate
NONEQ_JOIN : Used in NON EQuality JOIN predicate
FILTER     : Used in single table FILTER predicate
JOIN       : Used in JOIN predicate
GROUP_BY   : Used in GROUP BY expression
...............................................................................

###############################################################################

COLUMN USAGE REPORT FOR SOE.CUSTOMERS
.....................................

1. CUSTOMER_ID                         : RANGE EQ_JOIN
2. CUST_EMAIL                          : EQ
3. NLS_LANGUAGE                        : EQ
4. NLS_TERRITORY                       : EQ
5. (NLS_LANGUAGE, NLS_TERRITORY)       : FILTER
###############################################################################
--
-- Create column group for CUSTOMER table based on usage informtion captured during the monitoring:
--
-- Option 1:: Automatically create all the extensions (column group) detected during the monitoring session. 
-- Oracle will automatically detect the column group based on the column usage explained above.
SELECT DBMS_STATS.CREATE_EXTENDED_STATS(OWNNAME=>'SOE', TABNAME=>'CUSTOMERS') FROM DUAL;
--
-- Option 2:: Provide the extension (column group) explicitly you want to create.
-- This does not require Column usage Statistics.
SELECT DBMS_STATS.CREATE_EXTENDED_STATS(OWNNAME=>'SOE', TABNAME=>'CUSTOMERS', EXTENSION=>'(NLS_LANGUAGE, NLS_TERRITORY)') FROM DUAL;
--
--it will return the extension name.
SYS_STUYW6#GFCPQMT660UM0#5W#IN
--
--display extensions and their names.
@display_extensions.sql
--
--EXTENSION_NAME is the name of the Extension and EXTENSION is the Column group or Expression.
--
EXTENSION_NAME                      EXTENSION
----------------------------------- --------------------------------------------------
SYS_NC00017$                        (LOWER("CUST_LAST_NAME"))
SYS_NC00018$                        (LOWER("CUST_FIRST_NAME"))
SYS_STUYW6#GFCPQMT660UM0#5W#IN      ("NLS_LANGUAGE","NLS_TERRITORY")
--
--Gather table stats now to generate Column Group stats.
exec DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>'SOE', TABNAME=>'CUSTOMERS');
--OR -- If you want to create Histograms for Skewed columns.
exec DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>'SOE', TABNAME=>'CUSTOMERS', METHOD_OPT => 'FOR ALL COLUMNS SIZE SKEWONLY');
--
--Check column statistics
SET PAGES 15
col COLUMN_NAME format A20
SELECT COLUMN_NAME, NUM_DISTINCT, HISTOGRAM FROM DBA_TAB_COL_STATISTICS WHERE OWNER = 'SOE' AND TABLE_NAME = 'CUSTOMERS' ORDER BY 1;
--
COLUMN_NAME          NUM_DISTINCT HISTOGRAM
-------------------- ------------ ---------------
ACCOUNT_MGR_ID                706 HYBRID
CREDIT_LIMIT                 4883 HYBRID
CUSTOMER_CLASS                  4 FREQUENCY
CUSTOMER_ID                 45703 NONE
CUSTOMER_SINCE               4450 HYBRID
CUST_EMAIL                  45664 HYBRID
CUST_FIRST_NAME              5144 HYBRID
CUST_LAST_NAME              33840 HYBRID
DOB                         16241 NONE
MAILSHOT                        2 FREQUENCY
NLS_LANGUAGE                  683 HYBRID
NLS_TERRITORY                  88 FREQUENCY

COLUMN_NAME          NUM_DISTINCT HISTOGRAM
-------------------- ------------ ---------------
PARTNER_MAILSHOT                2 FREQUENCY
PREFERRED_ADDRESS           40372 NONE
PREFERRED_CARD              40604 NONE
SUGGESTIONS                    13 FREQUENCY
SYS_NC00017$                33840 HYBRID
SYS_NC00018$                 5144 HYBRID
SYS_STUYW6#GFCPQMT66        16658 HYBRID /* column group extension */
0UM0#5W#IN
--
--run the query again.
ALTER SYSTEM FLUSH SHARED_POOL;
SELECT * FROM SOE.CUSTOMERS WHERE NLS_LANGUAGE = 'us' AND NLS_TERRITORY='AMERICA';
--
--and generate the execution plan.
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT=>'+ALLSTATS'));
--
--Now you can see the E-Rows and A-Rows are almost matching since Extended statistics is generated.
-----------------------------------------------------------------------------------------
| Id  | Operation         | Name      | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-----------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |           |      1 |        |   3256 |00:00:00.01 |     979 |
|*  1 |  TABLE ACCESS FULL| CUSTOMERS |      1 |   3208 |   3256 |00:00:00.01 |     979 |
-----------------------------------------------------------------------------------------
--
--Delete a specific extension
exec DBMS_STATS.DROP_EXTENDED_STATS ( OWNNAME=>'SOE', TABNAME=>'CUSTOMERS', EXTENSION=>'(NLS_LANGUAGE,NLS_TERRITORY)');
--
@display_extensions.sql
--
EXTENSION_NAME                      EXTENSION
----------------------------------- --------------------------------------------------
SYS_NC00017$                        (LOWER("CUST_LAST_NAME"))
SYS_NC00018$                        (LOWER("CUST_FIRST_NAME"))
--
--To delete all extensions of a table.
BEGIN
	FOR R IN (SELECT EXTENSION FROM DBA_STAT_EXTENSIONS WHERE
			TABLE_NAME='CUSTOMERS' AND DROPPABLE='YES') LOOP
			DBMS_STATS.DROP_EXTENDED_STATS ( OWNNAME=>'SOE', TABNAME=>'CUSTOMERS', EXTENSION=>R.EXTENSION);
	END LOOP;
END;
/
--Manually gathering Column Group Statistics
--
--This will create a Column Group on NLS_LANGUAGE and NLS_TERRITORY and a Histogram on it and Histogram on all skewed columns
BEGIN
	DBMS_STATS.GATHER_TABLE_STATS( 'SOE','CUSTOMERS', METHOD_OPT => 'FOR ALL COLUMNS SIZE SKEWONLY ' ||
	'FOR COLUMNS SIZE SKEWONLY (NLS_LANGUAGE,NLS_TERRITORY)' );
END;
/
--Check Column Statistics
col COLUMN_NAME format a35
col NUM_DISTINCT format 99999
col HISTOGRAM format a20
col NOTES format a30
SELECT COLUMN_NAME, NUM_DISTINCT, HISTOGRAM, NOTES FROM DBA_TAB_COL_STATISTICS WHERE TABLE_NAME = 'CUSTOMERS' ORDER BY 1;
--
SELECT EXTENSION_NAME, EXTENSION, DROPPABLE FROM DBA_STAT_EXTENSIONS WHERE TABLE_NAME='CUSTOMERS' AND OWNER = 'SOE';
--
EXTENSION_NAME                      EXTENSION                                          DRO
----------------------------------- -------------------------------------------------- ---
SYS_NC00017$                        (LOWER("CUST_LAST_NAME"))                          NO
SYS_NC00018$                        (LOWER("CUST_FIRST_NAME"))                         NO
SYS_STUYW6#GFCPQMT660UM0#5W#IN      ("NLS_LANGUAGE","NLS_TERRITORY")                   YES
--
--You can also get the Extension Name using SHOW_EXTENDED_STATS_NAME and passing the Column Group as parameter.
col COL_GRP_NAME format a40
SELECT SYS.DBMS_STATS.SHOW_EXTENDED_STATS_NAME( 'SOE','CUSTOMERS', '(NLS_LANGUAGE,NLS_TERRITORY)' ) COL_GRP_NAME FROM DUAL;
--
COL_GRP_NAME
----------------------------------------
SYS_STUYW6#GFCPQMT660UM0#5W#IN
--
-- Gather Expression Statistics
-- Unless a function based index exists, optimizer cannot calculate the cardinality correctly.
-- Extended extended Statistics helps the Optimizer calculate the cardinality of such function wrapped columns.
--
ALTER SESSION SET STATISTICS_LEVEL = ALL;
--
SELECT COUNT(*) FROM SOE.CUSTOMERS WHERE UPPER(NLS_LANGUAGE) = 'US';
--
--and generate the execution plan.
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT=>'+ALLSTATS'));
--
--E-Rows: 457 A-Rows: 3286
------------------------------------------------------------------------------------------
| Id  | Operation          | Name      | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |           |      1 |        |      1 |00:00:00.01 |     763 |
|   1 |  SORT AGGREGATE    |           |      1 |      1 |      1 |00:00:00.01 |     763 |
|*  2 |   TABLE ACCESS FULL| CUSTOMERS |      1 |    457 |   3286 |00:00:00.01 |     763 |
------------------------------------------------------------------------------------------
--
--Create Extended Statistics
BEGIN
	DBMS_STATS.GATHER_TABLE_STATS( 'SOE', 'CUSTOMERS', METHOD_OPT => 'FOR ALL COLUMNS SIZE SKEWONLY FOR COLUMNS (UPPER(NLS_LANGUAGE)) SIZE SKEWONLY');
END;
/
--
@display_extensions.sql
--
--A new Expression statistics has been created (SYS_STUI2#9QBDSQ30HN_TXYAJQHFQ)
EXTENSION_NAME                      EXTENSION                                          DRO
----------------------------------- -------------------------------------------------- ---
SYS_NC00017$                        (LOWER("CUST_LAST_NAME"))                          NO
SYS_NC00018$                        (LOWER("CUST_FIRST_NAME"))                         NO
SYS_STUI2#9QBDSQ30HN_TXYAJQHFQ      (UPPER("NLS_LANGUAGE"))                            YES
SYS_STUYW6#GFCPQMT660UM0#5W#IN      ("NLS_LANGUAGE","NLS_TERRITORY")                   YES
--
--Get Histogram and Extension information
SELECT e.EXTENSION, c.NUM_DISTINCT, c.HISTOGRAM
FROM DBA_STAT_EXTENSIONS e, DBA_TAB_COL_STATISTICS c
WHERE e.EXTENSION_NAME=c.COLUMN_NAME
AND e.TABLE_NAME=c.TABLE_NAME
AND c.TABLE_NAME='CUSTOMERS';
--
EXTENSION                                          NUM_DISTINCT HISTOGRAM
-------------------------------------------------- ------------ ---------------
(LOWER("CUST_LAST_NAME"))                                 33840 HYBRID
(LOWER("CUST_FIRST_NAME"))                                 5144 HYBRID
(UPPER("NLS_LANGUAGE"))                                     679 HYBRID
("NLS_LANGUAGE","NLS_TERRITORY")                          16658 HYBRID
(LOWER("CUST_LAST_NAME"))                                     1 NONE
(LOWER("CUST_FIRST_NAME"))                                    1 NONE
(UPPER("CUST_LAST_NAME"))                                   176 NONE
(UPPER("CUST_FIRST_NAME"))                                  170 NONE
--
SELECT COUNT(*) FROM SOE.CUSTOMERS WHERE UPPER(NLS_LANGUAGE) = 'US';
--and generate the execution plan.
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT=>'+ALLSTATS'));
--
--Cardinality has improved to a great extent now. A-Rows 3082 Vs E-Rows 3286
------------------------------------------------------------------------------------------
| Id  | Operation          | Name      | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |           |      1 |        |      1 |00:00:00.01 |     763 |
|   1 |  SORT AGGREGATE    |           |      1 |      1 |      1 |00:00:00.01 |     763 |
|*  2 |   TABLE ACCESS FULL| CUSTOMERS |      1 |   3082 |   3286 |00:00:00.01 |     763 |
------------------------------------------------------------------------------------------
--
--Drop the Expression Stat.
exec DBMS_STATS.DROP_EXTENDED_STATS( 'SOE', 'CUSTOMERS', '(UPPER(NLS_LANGUAGE))');