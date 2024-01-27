--Sort Join - For large data sets with joins on inequality operators (<, > =<, <=) or when Index exists on Joining columns 
--and cost is cheaper than other join methods.
--
--It sorts the first dataset, if not indexed, and second dataset (always) and merge them together. Advantage over NL because
--datasets are stored in PGA and avoids latching in SGA (buffer cache). Used over Hash join when Hash table does not fit in memory.
--
EXPLAIN PLAN SET STATEMENT_ID = 'SORT_JOIN1' FOR
SELECT e.employee_id, e.last_name,
e.first_name,
e.department_id, d.department_name
FROM hr.employees e, hr.departments d
WHERE e.department_id = d.department_id
ORDER BY department_id;
--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(TABLE_NAME => NULL, STATEMENT_ID=> 'SORT_JOIN1', FORMAT=> 'ALL'));
--

--------------------------------------------------------------------------------------------
| Id  | Operation                    | Name        | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT             |             |   106 |  4028 |     6  (17)| 00:00:01 |
|   1 |  MERGE JOIN                  |             |   106 |  4028 |     6  (17)| 00:00:01 |
|   2 |   TABLE ACCESS BY INDEX ROWID| DEPARTMENTS |    27 |   432 |     2   (0)| 00:00:01 |
|   3 |    INDEX FULL SCAN           | DEPT_ID_PK  |    27 |       |     1   (0)| 00:00:01 |
|*  4 |   SORT JOIN                  |             |   107 |  2354 |     4  (25)| 00:00:01 |
|   5 |    TABLE ACCESS FULL         | EMPLOYEES   |   107 |  2354 |     3   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------
--
SELECT /*+ GATHER_PLAN_STATISTICS */
e.employee_id, e.last_name,
e.first_name,
e.department_id, d.department_name
FROM hr.employees e, hr.departments d
WHERE e.department_id = d.department_id
ORDER BY department_id;
--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format=> 'ALLSTATS LAST +cost +bytes +outline'));
--
------------------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                    | Name        | Starts | E-Rows |E-Bytes| Cost (%CPU)| A-Rows |   A-Time   | Buffers |  OMem |  1Mem | Used-Mem |
------------------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT             |             |      1 |        |       |     6 (100)|    106 |00:00:00.01 |      18 |       |       |          |
|   1 |  MERGE JOIN                  |             |      1 |    106 |  4028 |     6  (17)|    106 |00:00:00.01 |      18 |       |       |          |
|   2 |   TABLE ACCESS BY INDEX ROWID| DEPARTMENTS |      1 |     27 |   432 |     2   (0)|     27 |00:00:00.01 |      12 |       |       |          |
|   3 |    INDEX FULL SCAN           | DEPT_ID_PK  |      1 |     27 |       |     1   (0)|     27 |00:00:00.01 |       6 |       |       |          |
|*  4 |   SORT JOIN                  |             |     27 |    107 |  2354 |     4  (25)|    106 |00:00:00.01 |       6 | 18432 | 18432 |16384  (0)|
|   5 |    TABLE ACCESS FULL         | EMPLOYEES   |      1 |    107 |  2354 |     3   (0)|    107 |00:00:00.01 |       6 |       |       |          |
------------------------------------------------------------------------------------------------------------------------------------------------------

Outline Data
-------------

  /*+
      BEGIN_OUTLINE_DATA
      IGNORE_OPTIM_EMBEDDED_HINTS
      OPTIMIZER_FEATURES_ENABLE('19.1.0')
      DB_VERSION('19.1.0')
      ALL_ROWS
      OUTLINE_LEAF(@"SEL$1")
      INDEX(@"SEL$1" "D"@"SEL$1" ("DEPARTMENTS"."DEPARTMENT_ID"))
      FULL(@"SEL$1" "E"@"SEL$1")
      LEADING(@"SEL$1" "D"@"SEL$1" "E"@"SEL$1")
      USE_MERGE(@"SEL$1" "E"@"SEL$1")
      END_OUTLINE_DATA
  */