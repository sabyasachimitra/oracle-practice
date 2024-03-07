/* ***************************************************** **
   ch03_divide_and_conquer_with_subquery_factoring.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 3
   Divide and Conquer WITH Subquery Factoring
   
   To be executed in schema PRACTICAL
** ***************************************************** */

/* -----------------------------------------------------
   sqlcl formatting setup
   ----------------------------------------------------- */

set pagesize 80
set linesize 80
set sqlformat ansiconsole

/* -----------------------------------------------------
   Chapter 3 example code
   ----------------------------------------------------- */

SELECT * FROM PRACTICAL.PRODUCT_ALCOHOL;
--
/*
   PRODUCT_ID    SALES_VOLUME    ABV
_____________ _______________ ______
         4040             330    8.5
         4160             500      6
         4280             330      7
         5310             330      5
         5430             330    6.5
         6520             500    4.5
         6600             500      4
         7790             500    5.5
         7870             330    4.5
         7950             330      5
*/  
--
SELECT * FROM PRACTICAL.PRODUCTS;
--
/*
     ID NAME                   GROUP_ID
_______ ___________________ ___________
   4040 Coalminers Sweat            142
   4160 Reindeer Fuel               142
   4280 Hoppy Crude Oil             142
   5310 Monks and Nuns              152
   5430 Hercule Trippel             152
   6520 Der Helle Kumpel            202
   6600 Hazy Pink Cloud             202
   7790 Summer in India             232
   7870 Ghost of Hops               232
   7950 Pale Rider Rides            232
*/
--
 SELECT 
   PRODUCT_ID, 
   EXTRACT(YEAR FROM MTH) YEAR, 
   SUM(QTY) 
FROM 
   PRACTICAL.MONTHLY_SALES 
GROUP BY 
   PRODUCT_ID, EXTRACT(YEAR FROM MTH);
--
/*
 PRODUCT_ID    YEAR    SUM(QTY)
_____________ _______ ___________
         4040    2016         286
         4040    2017         227
         4040    2018         300
         4160    2016         331
         4160    2017         582
         4160    2018         691
         4280    2016          99
         4280    2017          72
         4280    2018         132
         5310    2016         478
         5310    2017         582
         5310    2018         425
         5430    2016         261
         5430    2017         344

   PRODUCT_ID    YEAR    SUM(QTY)
_____________ _______ ___________
         5430    2018         451
         6520    2016         415
         6520    2017         458
         6520    2018         357
         6600    2016         121
         6600    2017         105
         6600    2018          98
         7790    2016         377
         7790    2017         321
         7790    2018         263
         7870    2016         552
         7870    2017         482
         7870    2018         451
         7950    2016         182

   PRODUCT_ID    YEAR    SUM(QTY)
_____________ _______ ___________
         7950    2017         210
         7950    2018         491
*/         

-- Listing 3-1. Dividing the beers into alcohol class 1 and 2

SELECT
   PA.PRODUCT_ID AS P_ID
 , P.NAME        AS PRODUCT_NAME
 , PA.ABV
 , NTILE(2) OVER (
      ORDER BY PA.ABV
   ) AS ALC_CLASS
FROM PRACTICAL.PRODUCT_ALCOHOL PA
JOIN PRACTICAL.PRODUCTS P
   ON P.ID = PA.PRODUCT_ID
ORDER BY PA.ABV, PA.PRODUCT_ID;
--
/*
   P_ID PRODUCT_NAME           ABV    ALC_CLASS
_______ ___________________ ______ ____________
   6600 Hazy Pink Cloud          4            1
   6520 Der Helle Kumpel       4.5            1
   7870 Ghost of Hops          4.5            1
   5310 Monks and Nuns           5            1
   7950 Pale Rider Rides         5            1
   7790 Summer in India        5.5            2
   4160 Reindeer Fuel            6            2
   5430 Hercule Trippel        6.5            2
   4280 Hoppy Crude Oil          7            2
   4040 Coalminers Sweat       8.5            2
*/   

-- Listing 3-2. The next query shows the yearly quantity of less string beers (alcohol class 1)

SELECT
   PAC.PRODUCT_ID AS P_ID
 , EXTRACT(YEAR FROM MS.MTH) AS YR
 , SUM(MS.QTY) AS YR_QTY
FROM (
   SELECT
      PA.PRODUCT_ID
    , NTILE(2) OVER (
         ORDER BY PA.ABV
      ) AS ALC_CLASS
   FROM PRACTICAL.PRODUCT_ALCOHOL PA
) PAC
JOIN PRACTICAL.MONTHLY_SALES MS
   ON MS.PRODUCT_ID = PAC.PRODUCT_ID
WHERE PAC.ALC_CLASS = 1
GROUP BY
   PAC.PRODUCT_ID
 , EXTRACT(YEAR FROM MS.MTH)
ORDER BY P_ID, YR;
--
/*
   P_ID      YR    YR_QTY
_______ _______ _________
   5310    2016       478
   5310    2017       582
   5310    2018       425
   6520    2016       415
   6520    2017       458
   6520    2018       357
   6600    2016       121
   6600    2017       105
   6600    2018        98
   7870    2016       552
   7870    2017       482
   7870    2018       451
   7950    2016       182
   7950    2017       210

   P_ID      YR    YR_QTY
_______ _______ _________
   7950    2018       491
*/

-- Listing 3-3: The next query, which is built upom all the previou ones, displays the product ID of the beer, avg. 
-- of all the quantity sold of the beer and year of quantity sold in which the beer was sold more than
-- the average quantity sold of all the year. The beer is less strong (alocohol class = 1).

SELECT
   P_ID, YR, YR_QTY
 , ROUND(AVG_YR) AS AVG_YR
FROM (
   SELECT
      PAC.PRODUCT_ID AS P_ID
    , EXTRACT(YEAR FROM MS.MTH) AS YR
    , SUM(MS.QTY) AS YR_QTY
    , AVG(SUM(MS.QTY)) OVER (
         PARTITION BY PAC.PRODUCT_ID
      ) AS AVG_YR
   FROM (
      SELECT
         PA.PRODUCT_ID
       , NTILE(2) OVER (
            ORDER BY PA.ABV, PA.PRODUCT_ID
         ) AS ALC_CLASS
      FROM PRACTICAL.PRODUCT_ALCOHOL PA
   ) PAC
   JOIN PRACTICAL.MONTHLY_SALES MS
      ON MS.PRODUCT_ID = PAC.PRODUCT_ID
   WHERE PAC.ALC_CLASS = 1
   GROUP BY
      PAC.PRODUCT_ID
    , EXTRACT(YEAR FROM MS.MTH)
)
WHERE YR_QTY > AVG_YR
ORDER BY P_ID, YR;
--
/*
  P_ID      YR    YR_QTY    AVG_YR
_______ _______ _________ _________
   5310    2017       582       495
   6520    2016       415       410
   6520    2017       458       410
   6600    2016       121       108
   7870    2016       552       495
   7950    2018       491       294
*/   

-- Listing 3-4. Rewriting Listing 3-3 using subquery factoring

WITH PRODUCT_ALC_CLASS AS ( -- this with clause refers to the query in Listing 3-1
   SELECT
      PA.PRODUCT_ID
    , NTILE(2) OVER (
         ORDER BY PA.ABV, PA.PRODUCT_ID
      ) AS ALC_CLASS
   FROM PRACTICAL.PRODUCT_ALCOHOL PA
), CLASS_ONE_YEARLY_SALES AS ( -- this with clause refers to the query in Listing 3-2
   SELECT
      PAC.PRODUCT_ID AS P_ID
    , EXTRACT(YEAR FROM MS.MTH) AS YR
    , SUM(MS.QTY) AS YR_QTY
    , AVG(SUM(MS.QTY)) OVER (
         PARTITION BY PAC.PRODUCT_ID
      ) AS AVG_YR
   FROM PRODUCT_ALC_CLASS PAC
   JOIN PRACTICAL.MONTHLY_SALES MS
      ON MS.PRODUCT_ID = PAC.PRODUCT_ID
   WHERE PAC.ALC_CLASS = 1
   GROUP BY
      PAC.PRODUCT_ID
    , EXTRACT(YEAR FROM MS.MTH)
)
SELECT                        -- the final query refers to the query in Listing 3-3
   P_ID, YR, YR_QTY
 , ROUND(AVG_YR) AS AVG_YR
FROM CLASS_ONE_YEARLY_SALES
WHERE YR_QTY > AVG_YR
ORDER BY P_ID, YR;
--
/*
   P_ID      YR    YR_QTY    AVG_YR
_______ _______ _________ _________
   5310    2017       582       495
   6520    2016       415       410
   6520    2017       458       410
   6600    2016       121       108
   7870    2016       552       495
   7950    2018       491       294
*/   

-- Listing 3-5. Alternative rewrite using independent named subqueries
-- In the below query YEARLY_SALES is not dependent on PRODUCT_ALC_CLASS
-- and ALC_CLASS is filtered in the final query instead in YEARLY_SALES.

WITH PRODUCT_ALC_CLASS AS (
   SELECT
      PA.PRODUCT_ID
    , NTILE(2) OVER (
         ORDER BY PA.ABV, PA.PRODUCT_ID
      ) AS ALC_CLASS
   FROM PRACTICAL.PRODUCT_ALCOHOL PA
), YEARLY_SALES AS (
   SELECT
      MS.PRODUCT_ID
    , EXTRACT(YEAR FROM MS.MTH) AS YR
    , SUM(MS.QTY) AS YR_QTY
    , AVG(SUM(MS.QTY)) OVER (
         PARTITION BY MS.PRODUCT_ID
      ) AS AVG_YR
   FROM PRACTICAL.MONTHLY_SALES MS
   GROUP BY
      MS.PRODUCT_ID
    , EXTRACT(YEAR FROM MS.MTH)
)
SELECT
   PAC.PRODUCT_ID AS P_ID
 , YS.YR
 , YS.YR_QTY
 , ROUND(YS.AVG_YR) AS AVG_YR
FROM PRODUCT_ALC_CLASS PAC
JOIN YEARLY_SALES YS
   ON YS.PRODUCT_ID = PAC.PRODUCT_ID
WHERE PAC.ALC_CLASS = 1
AND YS.YR_QTY > YS.AVG_YR
ORDER BY P_ID, YR;
--
/*
   P_ID      YR    YR_QTY    AVG_YR
_______ _______ _________ _________
   5310    2017       582       495
   6520    2016       415       410
   6520    2017       458       410
   6600    2016       121       108
   7870    2016       552       495
   7950    2018       491       294
*/   
-- Listing 3-6. The same out but this time YEARLY_SALES subsquery picks products with lower % of alcohol.
-- The reason for filtering the alcohol class inside the subquery is sometime optimizer may not push the 
-- predicate inside the subquery. 

WITH PRODUCT_ALC_CLASS AS (
   SELECT
      PA.PRODUCT_ID
    , NTILE(2) OVER (
         ORDER BY PA.ABV, PA.PRODUCT_ID
      ) AS ALC_CLASS
   FROM PRACTICAL.PRODUCT_ALCOHOL PA
), YEARLY_SALES AS (
   SELECT
      MS.PRODUCT_ID
    , EXTRACT(YEAR FROM MS.MTH) AS YR
    , SUM(MS.QTY) AS YR_QTY
    , AVG(SUM(MS.QTY)) OVER (
         PARTITION BY MS.PRODUCT_ID
      ) AS AVG_YR
   FROM PRACTICAL.MONTHLY_SALES MS
   WHERE MS.PRODUCT_ID IN (
      SELECT PAC.PRODUCT_ID
      FROM PRODUCT_ALC_CLASS PAC
      WHERE PAC.ALC_CLASS = 1
   )
   GROUP BY
      MS.PRODUCT_ID
    , EXTRACT(YEAR FROM MS.MTH)
)
SELECT
   PAC.PRODUCT_ID AS P_ID
 , YS.YR
 , YS.YR_QTY
 , ROUND(YS.AVG_YR) AS AVG_YR
FROM PRODUCT_ALC_CLASS PAC
JOIN YEARLY_SALES YS
   ON YS.PRODUCT_ID = PAC.PRODUCT_ID
WHERE YS.YR_QTY > YS.AVG_YR
ORDER BY P_ID, YR;
--
/*
P_ID      YR    YR_QTY    AVG_YR 
_______ _______ _________ _________
   5310    2017       582       495
   6520    2016       415       410
   6520    2017       458       410
   6600    2016       121       108
   7870    2016       552       495
   7950    2018       491       294
*/   
--
-- EXPLAIN PLAN
--
/*
-------------------------------------------------------------------------------------------------
| Id  | Operation                  | Name               | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT           |                    |   255 | 11985 |     9  (34)| 00:00:01 |
|   1 |  SORT ORDER BY             |                    |   255 | 11985 |     9  (34)| 00:00:01 |
|   2 |   NESTED LOOPS             |                    |   255 | 11985 |     8  (25)| 00:00:01 |
|*  3 |    VIEW                    |                    |   255 | 10965 |     8  (25)| 00:00:01 |
|   4 |     WINDOW BUFFER          |                    |   255 |  4845 |     8  (25)| 00:00:01 |
|   5 |      SORT GROUP BY         |                    |   255 |  4845 |     8  (25)| 00:00:01 |
|*  6 |       HASH JOIN RIGHT SEMI |                    |   360 |  6840 |     7  (15)| 00:00:01 |
|   7 |        VIEW                | VW_NSO_1           |    10 |    40 |     4  (25)| 00:00:01 |
|*  8 |         VIEW               |                    |    10 |   260 |     4  (25)| 00:00:01 |
|   9 |          WINDOW SORT       |                    |    10 |    80 |     4  (25)| 00:00:01 |
|  10 |           TABLE ACCESS FULL| PRODUCT_ALCOHOL    |    10 |    80 |     3   (0)| 00:00:01 |
|  11 |        TABLE ACCESS FULL   | MONTHLY_SALES      |   360 |  5400 |     3   (0)| 00:00:01 |
|* 12 |    INDEX UNIQUE SCAN       | PRODUCT_ALCOHOL_PK |     1 |     4 |     0   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   3 - filter("YS"."YR_QTY">"YS"."AVG_YR")
   6 - access("MS"."PRODUCT_ID"="PRODUCT_ID")
   8 - filter("PAC"."ALC_CLASS"=1)
  12 - access("YS"."PRODUCT_ID"="PA"."PRODUCT_ID")
*/
-- Undocumented hint to force materializing as adhoc temporary table
-- Optimizer can treat Subquery factoring (WITH clause) in two ways:
--
-- It can treat them just like views, meaning that the SQL of the na-
-- -med subqueries is basically substituted each place that they are 
-- queried.
--
-- It can also decide to execute the SQL of a named subquery only once
-- ,storing the results in a temporary table it creates on the fly and
-- then accessing this temporary table each place that the named subqu-
-- -ery is queried. 
--
-- With optimizer hint MATERIALIZE optimizer choose the second method. 


WITH PRODUCT_ALC_CLASS AS (
   SELECT /*+ MATERIALIZE */
      PA.PRODUCT_ID
    , NTILE(2) OVER (
         ORDER BY PA.ABV, PA.PRODUCT_ID
      ) AS ALC_CLASS
   FROM PRACTICAL.PRODUCT_ALCOHOL PA
), YEARLY_SALES AS (
   SELECT
      MS.PRODUCT_ID
    , EXTRACT(YEAR FROM MS.MTH) AS YR
    , SUM(MS.QTY) AS YR_QTY
    , AVG(SUM(MS.QTY)) OVER (
         PARTITION BY MS.PRODUCT_ID
      ) AS AVG_YR
   FROM PRACTICAL.MONTHLY_SALES MS
   WHERE MS.PRODUCT_ID IN (
      SELECT PAC.PRODUCT_ID
      FROM PRODUCT_ALC_CLASS PAC
      WHERE PAC.ALC_CLASS = 1
   )
   GROUP BY
      MS.PRODUCT_ID
    , EXTRACT(YEAR FROM MS.MTH)
)
SELECT
   PAC.PRODUCT_ID AS P_ID
 , YS.YR
 , YS.YR_QTY
 , ROUND(YS.AVG_YR) AS AVG_YR
FROM PRODUCT_ALC_CLASS PAC
JOIN YEARLY_SALES YS
   ON YS.PRODUCT_ID = PAC.PRODUCT_ID
WHERE YS.YR_QTY > YS.AVG_YR
ORDER BY P_ID, YR;
--
-- SYS_TEMP_0FD9D663B_7DF1F7 temporary table is created for the 
-- result of PRODUCT_ALC_CLASS named subquery with predicate ALC_CLASS=1
/*
----------------------------------------------------------------------------------------------------------------------
| Id  | Operation                                | Name                      | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                         |                           |   255 | 11985 |    13  (24)| 00:00:01 |
|   1 |  TEMP TABLE TRANSFORMATION               |                           |       |       |            |          |
|   2 |   LOAD AS SELECT (CURSOR DURATION MEMORY)| SYS_TEMP_0FD9D663B_7DF1F7 |       |       |            |          |
|   3 |    WINDOW SORT                           |                           |    10 |    80 |     4  (25)| 00:00:01 |
|   4 |     TABLE ACCESS FULL                    | PRODUCT_ALCOHOL           |    10 |    80 |     3   (0)| 00:00:01 |
|   5 |   SORT ORDER BY                          |                           |   255 | 11985 |     9  (23)| 00:00:01 |
|*  6 |    HASH JOIN                             |                           |   255 | 11985 |     8  (13)| 00:00:01 |
|   7 |     VIEW                                 |                           |    10 |    40 |     2   (0)| 00:00:01 |
|   8 |      TABLE ACCESS FULL                   | SYS_TEMP_0FD9D663B_7DF1F7 |    10 |    80 |     2   (0)| 00:00:01 |
|*  9 |     VIEW                                 |                           |   255 | 10965 |     6  (17)| 00:00:01 |
|  10 |      WINDOW BUFFER                       |                           |   255 |  4845 |     6  (17)| 00:00:01 |
|  11 |       SORT GROUP BY                      |                           |   255 |  4845 |     6  (17)| 00:00:01 |
|* 12 |        HASH JOIN RIGHT SEMI              |                           |   360 |  6840 |     5   (0)| 00:00:01 |
|  13 |         VIEW                             | VW_NSO_1                  |    10 |    40 |     2   (0)| 00:00:01 |
|* 14 |          VIEW                            |                           |    10 |   260 |     2   (0)| 00:00:01 |
|  15 |           TABLE ACCESS FULL              | SYS_TEMP_0FD9D663B_7DF1F7 |    10 |    80 |     2   (0)| 00:00:01 |
|  16 |         TABLE ACCESS FULL                | MONTHLY_SALES             |   360 |  5400 |     3   (0)| 00:00:01 |
----------------------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   6 - access("YS"."PRODUCT_ID"="PAC"."PRODUCT_ID")

PLAN_TABLE_OUTPUT
________________________________________________
   9 - filter("YS"."YR_QTY">"YS"."AVG_YR")
  12 - access("MS"."PRODUCT_ID"="PRODUCT_ID")
  14 - filter("PAC"."ALC_CLASS"=1)
  --
  */
--
-- You may want to avoid MATERIALIZE hint because it's undocumented. Another way 
-- to force Optimizer to store subquery results into temporary table is to use row-
-- -num in the subquery. 
--
WITH PRODUCT_ALC_CLASS AS (
   SELECT
      PA.PRODUCT_ID
    , NTILE(2) OVER (
         ORDER BY PA.ABV, PA.PRODUCT_ID
      ) AS ALC_CLASS
   FROM PRACTICAL.PRODUCT_ALCOHOL PA
   WHERE ROWNUM >= 1
), YEARLY_SALES AS (
   SELECT
      MS.PRODUCT_ID
    , EXTRACT(YEAR FROM MS.MTH) AS YR
    , SUM(MS.QTY) AS YR_QTY
    , AVG(SUM(MS.QTY)) OVER (
         PARTITION BY MS.PRODUCT_ID
      ) AS AVG_YR
   FROM PRACTICAL.MONTHLY_SALES MS
   WHERE MS.PRODUCT_ID IN (
      SELECT PAC.PRODUCT_ID
      FROM PRODUCT_ALC_CLASS PAC
      WHERE PAC.ALC_CLASS = 1
   )
   GROUP BY
      MS.PRODUCT_ID
    , EXTRACT(YEAR FROM MS.MTH)
)
SELECT
   PAC.PRODUCT_ID AS P_ID
 , YS.YR
 , YS.YR_QTY
 , ROUND(YS.AVG_YR) AS AVG_YR
FROM PRODUCT_ALC_CLASS PAC
JOIN YEARLY_SALES YS
   ON YS.PRODUCT_ID = PAC.PRODUCT_ID
WHERE YS.YR_QTY > YS.AVG_YR
ORDER BY P_ID, YR;
--
-- You can see that using MATERIALIZE hint or ROWNUM actually increases the query cost.  
--
/*
----------------------------------------------------------------------------------------------------------------------
| Id  | Operation                                | Name                      | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                         |                           |   255 | 11985 |    13  (24)| 00:00:01 |
|   1 |  TEMP TABLE TRANSFORMATION               |                           |       |       |            |          |
|   2 |   LOAD AS SELECT (CURSOR DURATION MEMORY)| SYS_TEMP_0FD9D661C_7EB361 |       |       |            |          |
|   3 |    WINDOW SORT                           |                           |    10 |    80 |     4  (25)| 00:00:01 |
|   4 |     COUNT                                |                           |       |       |            |          |
|*  5 |      FILTER                              |                           |       |       |            |          |
|   6 |       TABLE ACCESS FULL                  | PRODUCT_ALCOHOL           |    10 |    80 |     3   (0)| 00:00:01 |
|   7 |   SORT ORDER BY                          |                           |   255 | 11985 |     9  (23)| 00:00:01 |
|*  8 |    HASH JOIN                             |                           |   255 | 11985 |     8  (13)| 00:00:01 |
|   9 |     VIEW                                 |                           |    10 |    40 |     2   (0)| 00:00:01 |
|  10 |      TABLE ACCESS FULL                   | SYS_TEMP_0FD9D661C_7EB361 |    10 |    80 |     2   (0)| 00:00:01 |
|* 11 |     VIEW                                 |                           |   255 | 10965 |     6  (17)| 00:00:01 |
|  12 |      WINDOW BUFFER                       |                           |   255 |  4845 |     6  (17)| 00:00:01 |
|  13 |       SORT GROUP BY                      |                           |   255 |  4845 |     6  (17)| 00:00:01 |
|* 14 |        HASH JOIN RIGHT SEMI              |                           |   360 |  6840 |     5   (0)| 00:00:01 |
|  15 |         VIEW                             | VW_NSO_1                  |    10 |    40 |     2   (0)| 00:00:01 |
|* 16 |          VIEW                            |                           |    10 |   260 |     2   (0)| 00:00:01 |
|  17 |           TABLE ACCESS FULL              | SYS_TEMP_0FD9D661C_7EB361 |    10 |    80 |     2   (0)| 00:00:01 |
|  18 |         TABLE ACCESS FULL                | MONTHLY_SALES             |   360 |  5400 |     3   (0)| 00:00:01 |
----------------------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

PLAN_TABLE_OUTPUT
______________________________________________________

   5 - filter(ROWNUM>=1)
   8 - access("YS"."PRODUCT_ID"="PAC"."PRODUCT_ID")
  11 - filter("YS"."YR_QTY">"YS"."AVG_YR")
  14 - access("MS"."PRODUCT_ID"="PRODUCT_ID")
  16 - filter("PAC"."ALC_CLASS"=1)
*/
--
-- Listing 3-7. Specifying column names list instead of column aliases

WITH PRODUCT_ALC_CLASS (
   PRODUCT_ID, ALC_CLASS
) AS (
   SELECT
      PA.PRODUCT_ID
    , NTILE(2) OVER (
         ORDER BY PA.ABV, PA.PRODUCT_ID
      )
   FROM PRODUCT_ALCOHOL PA
), YEARLY_SALES (
   PRODUCT_ID, YR, YR_QTY, AVG_YR
) AS (
   SELECT
      MS.PRODUCT_ID
    , EXTRACT(YEAR FROM MS.MTH)
    , SUM(MS.QTY)
    , AVG(SUM(MS.QTY)) OVER (
         PARTITION BY MS.PRODUCT_ID
      )
   FROM MONTHLY_SALES MS
   WHERE MS.PRODUCT_ID IN (
      SELECT PAC.PRODUCT_ID
      FROM PRODUCT_ALC_CLASS PAC
      WHERE PAC.ALC_CLASS = 1
   )
   GROUP BY
      MS.PRODUCT_ID
    , EXTRACT(YEAR FROM MS.MTH)
)
SELECT
   PAC.PRODUCT_ID AS P_ID
 , YS.YR
 , YS.YR_QTY
 , ROUND(YS.AVG_YR) AS AVG_YR
FROM PRODUCT_ALC_CLASS PAC
JOIN YEARLY_SALES YS
   ON YS.PRODUCT_ID = PAC.PRODUCT_ID
WHERE YS.YR_QTY > YS.AVG_YR
ORDER BY P_ID, YR;

-- Listing 3-8. �Overloading� a table with test data in a with clause

WITH PRODUCT_ALCOHOL (
   PRODUCT_ID, SALES_VOLUME, ABV
) AS (
   SELECT 4040, 330, 4.5 FROM DUAL UNION ALL
   SELECT 4160, 500, 7.0 FROM DUAL UNION ALL
   SELECT 4280, 330, 8.0 FROM DUAL UNION ALL
   SELECT 5310, 330, 4.0 FROM DUAL UNION ALL
   SELECT 5430, 330, 8.5 FROM DUAL UNION ALL
   SELECT 6520, 500, 6.5 FROM DUAL UNION ALL
   SELECT 6600, 500, 5.0 FROM DUAL UNION ALL
   SELECT 7790, 500, 4.5 FROM DUAL UNION ALL
   SELECT 7870, 330, 6.5 FROM DUAL UNION ALL
   SELECT 7950, 330, 6.0 FROM DUAL UNION ALL
   SELECT 8976, 430, 7.0 FROM DUAL
) SELECT
   PA.PRODUCT_ID AS P_ID
 , P.NAME        AS PRODUCT_NAME
 , PA.ABV
 , NTILE(2) OVER (
      ORDER BY PA.ABV, PA.PRODUCT_ID
   ) AS ALC_CLASS
FROM PRODUCT_ALCOHOL PA
JOIN PRACTICAL.PRODUCTS P
   ON P.ID = PA.PRODUCT_ID
ORDER BY PA.ABV, PA.PRODUCT_ID;
--
/*
   P_ID PRODUCT_NAME           ABV    ALC_CLASS
_______ ___________________ ______ ____________
   5310 Monks and Nuns           4            1
   4040 Coalminers Sweat       4.5            1
   7790 Summer in India        4.5            1
   6600 Hazy Pink Cloud          5            1
   7950 Pale Rider Rides         6            1
   6520 Der Helle Kumpel       6.5            2
   7870 Ghost of Hops          6.5            2
   4160 Reindeer Fuel            7            2
   4280 Hoppy Crude Oil          8            2
   5430 Hercule Trippel        8.5            2
*/   
/* ***************************************************** */
