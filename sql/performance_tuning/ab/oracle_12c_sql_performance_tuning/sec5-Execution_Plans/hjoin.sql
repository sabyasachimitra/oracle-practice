--Hash Join - Used when equality operator is used in Join condition. Optimizer uses smaller of two datasets to build the hash table.
--It's effective when smaller dataset (hash table) fits in the memory. Hash table is stored in PGA (instead of SGA) so Oracle 
--can access rows without latching them. This saves logical I/O. It performs the best (over NL and Sort Join) when the 
--hash table (smaller dataset) fits in the memory.
--
EXPLAIN PLAN SET STATEMENT_ID='HASH_JOIN' FOR 
SELECT O.ORDER_ID, O.ORDER_STATUS, OL.PRODUCT_ID, OL.UNIT_PRICE, OL.QUANTITY
FROM SOE.ORDERS O
INNER JOIN
SOE.ORDER_ITEMS OL
ON O.ORDER_ID = OL.ORDER_ID;
--
------------------------------------------------------------------------------------------
| Id  | Operation          | Name        | Rows  | Bytes |TempSpc| Cost (%CPU)| Time     |
------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |             |  3735K|    92M|       | 18536   (1)| 00:00:01 |
|*  1 |  HASH JOIN         |             |  3735K|    92M|    27M| 18536   (1)| 00:00:01 |
|   2 |   TABLE ACCESS FULL| ORDERS      |  1352K|    11M|       |  4825   (1)| 00:00:01 |
|   3 |   TABLE ACCESS FULL| ORDER_ITEMS |  3735K|    60M|       |  7214   (1)| 00:00:01 |
------------------------------------------------------------------------------------------
--
SELECT /*+ GATHER_PLAN_STATISTICS */ 
O.ORDER_ID, O.ORDER_STATUS, OL.PRODUCT_ID, OL.UNIT_PRICE, OL.QUANTITY
FROM SOE.ORDERS O
INNER JOIN
SOE.ORDER_ITEMS OL
ON O.ORDER_ID = OL.ORDER_ID;
--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format=> 'ALLSTATS LAST +cost +bytes +outline'));
--
-------------------------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation          | Name        | Starts | E-Rows |E-Bytes|E-Temp | Cost (%CPU)| A-Rows |   A-Time   | Buffers | Reads  |  OMem |  1Mem | Used-Mem |
-------------------------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |             |      1 |        |       |       | 18536 (100)|     50 |00:00:00.38 |   17633 |    238 |       |       |          |
|*  1 |  HASH JOIN         |             |      1 |   3735K|    92M|    27M| 18536   (1)|     50 |00:00:00.38 |   17633 |    238 |    77M|  8580K|   73M (0)|
|   2 |   TABLE ACCESS FULL| ORDERS      |      1 |   1352K|    11M|       |  4825   (1)|   1352K|00:00:00.12 |   17630 |      0 |       |       |          |
|   3 |   TABLE ACCESS FULL| ORDER_ITEMS |      1 |   3735K|    60M|       |  7214   (1)|     50 |00:00:00.01 |       3 |    238 |       |       |          |
-------------------------------------------------------------------------------------------------------------------------------------------------------------
 
Outline Data
-------------
 
  /*+
      BEGIN_OUTLINE_DATA
      IGNORE_OPTIM_EMBEDDED_HINTS
      OPTIMIZER_FEATURES_ENABLE('19.1.0')
      DB_VERSION('19.1.0')
      ALL_ROWS
      OUTLINE_LEAF(@"SEL$58A6D7F6")
      MERGE(@"SEL$1" >"SEL$2")
      OUTLINE(@"SEL$2")
      OUTLINE(@"SEL$1")
      FULL(@"SEL$58A6D7F6" "O"@"SEL$1")
      FULL(@"SEL$58A6D7F6" "OL"@"SEL$1")
      LEADING(@"SEL$58A6D7F6" "O"@"SEL$1" "OL"@"SEL$1")
      USE_HASH(@"SEL$58A6D7F6" "OL"@"SEL$1")
      END_OUTLINE_DATA
  */
--
  