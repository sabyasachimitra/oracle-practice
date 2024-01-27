--
-- Tracing using 10046 (unsupported).
--
ALTER SESSION SET EVENTS '10046 trace name context forever, level 12';
--
-- Run the SQL
VARIABLE month_year VARCHAR2(7)
EXEC :month_year := '01-2010'
SELECT /* my query2 */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL FROM
SOE.ORDERS WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') =:month_year;
--
-- Turn off tracing
--
ALTER SESSION SET EVENTS='10046 trace name context off';
--
-- Get the trace file name and location
--
SELECT P.TRACEFILE FROM V$SESSION S JOIN V$PROCESS P ON S.PADDR = P.ADDR
WHERE S.AUDSID = SYS_CONTEXT('USERENV', 'SESSIONID');
--
TRACEFILE
-----------------------------------------------------------------
/u01/app/oracle/diag/rdbms/cdb01/cdb01/trace/cdb01_ora_8470.trc
--
tkprof /u01/app/oracle/diag/rdbms/cdb01/cdb01/trace/cdb01_ora_8470.trc /u01/app/oracle/diag/rdbms/cdb01/cdb01/trace/sec10.log SYS=no waits=yes aggregate=yes sort="(exeela,prsela,fchela)"
--
