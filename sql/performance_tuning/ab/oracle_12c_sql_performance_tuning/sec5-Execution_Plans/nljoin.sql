--Nested Loop Join
--
EXPLAIN PLAN SET STATEMENT_ID='NL_JOIN_1' 
	FOR 
		SELECT 
			ENAME, DNAME 
		FROM
			SOE.DEPT D
		INNER JOIN 
			SOE.EMP E
		ON E.DEPT_NO = E.DEPT_NO
		AND D.DEPT_NO = 10;
--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(TABLE_NAME => 'PLAN_TABLE', STATEMENT_ID=> 'NL_JOIN_1', FORMAT=> 'ALL'));
--
------------------------------------------------------------------------------------------------
| Id  | Operation                            | Name    | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                     |         |   879 | 28128 |    12   (0)| 00:00:01 |
|   1 |  NESTED LOOPS                        |         |   879 | 28128 |    12   (0)| 00:00:01 |
|   2 |   TABLE ACCESS BY INDEX ROWID        | DEPT    |     1 |    13 |     1   (0)| 00:00:01 |
|*  3 |    INDEX UNIQUE SCAN                 | DEPT_PK |     1 |       |     0   (0)| 00:00:01 |
|   4 |   TABLE ACCESS BY INDEX ROWID BATCHED| EMP     |   879 | 16701 |    11   (0)| 00:00:01 |
|*  5 |    INDEX FULL SCAN                   | DEPT_IX |   879 |       |     3   (0)| 00:00:01 |
------------------------------------------------------------------------------------------------
--
--
SELECT /*+ GATHER_PLAN_STATISTICS */
	ENAME, DNAME 
FROM
	SOE.EMP E	
INNER JOIN 
	SOE.DEPT D
ON E.DEPT_NO = E.DEPT_NO
AND D.DEPT_NO = 10;
--		
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format=> 'ALLSTATS LAST +cost +bytes +outline'));
--
