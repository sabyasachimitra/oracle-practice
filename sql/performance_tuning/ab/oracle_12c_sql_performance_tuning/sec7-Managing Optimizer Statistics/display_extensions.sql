set linesize 180
col EXTENSION_NAME format a35
col EXTENSION FORMAT a50
SELECT EXTENSION_NAME, EXTENSION, DROPPABLE FROM DBA_STAT_EXTENSIONS WHERE TABLE_NAME='CUSTOMERS' AND OWNER = 'SOE';

