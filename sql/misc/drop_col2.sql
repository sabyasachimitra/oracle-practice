/*
Should we drop columns? The demo here shows why we should never drop columns 
from tables and instead make the column unused. There is no benefit in dropping 
unused column. 
--
Author: Sabyasachi Mitra
Date: 03/30/2024
Tested on: Oracle 21c
*/
--
CREATE TABLE PROC_TAB AS
SELECT * FROM DBA_PROCEDURES;
--
DESC PROC_TAB;
--
/*
Name              Null?    Type
_________________ ________ ________________
OWNER                      VARCHAR2(128)
OBJECT_NAME                VARCHAR2(128)
PROCEDURE_NAME             VARCHAR2(128)
OBJECT_ID                  NUMBER
SUBPROGRAM_ID              NUMBER
OVERLOAD                   VARCHAR2(40)
OBJECT_TYPE                VARCHAR2(13)
AGGREGATE                  VARCHAR2(3)
PIPELINED                  VARCHAR2(3)
IMPLTYPEOWNER              VARCHAR2(128)
IMPLTYPENAME               VARCHAR2(128)
PARALLEL                   VARCHAR2(3)
INTERFACE                  VARCHAR2(3)
DETERMINISTIC              VARCHAR2(3)
....
*/
--
SELECT BLOCKS, EMPTY_BLOCKS
FROM DBA_TABLES
WHERE TABLE_NAME = 'PROC_TAB';
--
/*
   BLOCKS    EMPTY_BLOCKS
_________ _______________
      452               0
*/
--
ALTER TABLE PROC_TAB SET UNUSED COLUMN OBJECT_NAME;
--
-- check how many columns are set to UNUSED in the table
--
SELECT COUNT(*) NUM_COL_UNUSED FROM DBA_UNUSED_COL_TABS WHERE TABLE_NAME = 'PROC_TAB';
--
/*
   NUM_COL_UNUSED
_________________
                1
*/                
--
--
-- one new column with HIDDEN_COLUMN = Y. When we set a column UNUSED, Oracle 
-- creates a row for it with column_name starting with SYS_* and hidden_column = Y.
--
SELECT TABLE_NAME, COLUMN_NAME, HIDDEN_COLUMN FROM DBA_TAB_COLS WHERE TABLE_NAME = 'PROC_TAB';
-- 
/*
TABLE_NAME    COLUMN_NAME                   HIDDEN_COLUMN
_____________ _____________________________ ________________
PROC_TAB      OWNER                         NO
PROC_TAB      SYS_C00002_24033015:53:12$    YES
PROC_TAB      PROCEDURE_NAME                NO
...
*/
-- gather stats
--
exec DBMS_STATS.GATHER_TABLE_STATS ('', 'PROC_TAB');
--
-- no change in number of blocks occupied by the table.
--
SELECT BLOCKS, EMPTY_BLOCKS
FROM DBA_TABLES
WHERE TABLE_NAME = 'PROC_TAB';
--
/*
   BLOCKS    EMPTY_BLOCKS
_________ _______________
      452               0
*/ 
--
-- drop the unused column
--
ALTER TABLE PROC_TAB DROP UNUSED COLUMNS;
--
-- unused column is gone
--
SELECT COUNT(*) NUM_COL_UNUSED FROM DBA_UNUSED_COL_TABS WHERE TABLE_NAME = 'PROC_TAB';
--
/*
   NUM_COL_UNUSED
_________________
                0
*/                
--
-- gather stats again
--
exec DBMS_STATS.GATHER_TABLE_STATS ('', 'PROC_TAB');
--
-- no change in number of block size
--
SELECT BLOCKS, EMPTY_BLOCKS
FROM DBA_TABLES
WHERE TABLE_NAME = 'PROC_TAB';
--
/*
   BLOCKS    EMPTY_BLOCKS
_________ _______________
      452               0
*/      
--
-- use MOVE to reorg the table (reorganize the segment)
--
ALTER TABLE PROC_TAB MOVE;
--
-- gather stats again
--
exec DBMS_STATS.GATHER_TABLE_STATS ('', 'PROC_TAB');
--
-- the block size has reduced. Oracle has reclaimed the space
-- consumed by the unused column after MOVE and gather_stats.
--
SELECT BLOCKS, EMPTY_BLOCKS
FROM DBA_TABLES
WHERE TABLE_NAME = 'PROC_TAB';
--
/*
   BLOCKS    EMPTY_BLOCKS
_________ _______________
      394               0
*/
--
-- clean up data
--
DROP TABLE PROC_TAB;      