/* ***************************************************** **
   ch01_correlating_inline_views.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 1
   Correlating Inline Views
   
   To be executed in schema PRACTICAL
** ***************************************************** */

/* -----------------------------------------------------
   sqlcl formatting setup
   ----------------------------------------------------- */

set pagesize 80
set linesize 80
set sqlformat ansiconsole

/* -----------------------------------------------------
   Chapter 1 example code
   ----------------------------------------------------- */

-- Listing 1-1. The yearly sales of the 3 beers from Balthazar Brauerei

SELECT
   BP.BREWERY_NAME
 , BP.PRODUCT_ID AS P_ID
 , BP.PRODUCT_NAME
 , YS.YR
 , YS.YR_QTY
FROM PRACTICAL.BREWERY_PRODUCTS BP
JOIN PRACTICAL.YEARLY_SALES YS
   ON YS.PRODUCT_ID = BP.PRODUCT_ID
WHERE BP.BREWERY_ID = 518
ORDER BY BP.PRODUCT_ID, YS.YR;

/* For each beer brand Balthazar Brauerei company display the highest selling year and quantity of the year*/

SELECT
   BP.BREWERY_NAME
 , BP.PRODUCT_ID AS P_ID
 , BP.PRODUCT_NAME
 , (
      SELECT YS.YR
      FROM PRACTICAL.YEARLY_SALES YS
      WHERE YS.PRODUCT_ID = BP.PRODUCT_ID
      ORDER BY YS.YR_QTY DESC
      FETCH FIRST ROW ONLY
   ) AS YR
 , (
      SELECT YS.YR_QTY
      FROM PRACTICAL.YEARLY_SALES YS
      WHERE YS.PRODUCT_ID = BP.PRODUCT_ID
      ORDER BY YS.YR_QTY DESC
      FETCH FIRST ROW ONLY
   ) AS YR_QTY
FROM PRACTICAL.BREWERY_PRODUCTS BP
WHERE BP.BREWERY_ID = 518
ORDER BY BP.PRODUCT_ID;
--
-- Output 
/* 
BREWERY_NAME             P_ID PRODUCT_NAME             YR    YR_QTY
_____________________ _______ ___________________ _______ _________
Balthazar Brauerei       5310 Monks and Nuns         2017       582
Balthazar Brauerei       5430 Hercule Trippel        2018       451
Balthazar Brauerei       6520 Der Helle Kumpel       2017       458
*/

/* 
   The following query achieves the same result but unlike the above query 
   it does not access the YEARLY_SALES view twice in two scalar queries.
*/
SELECT
   BREWERY_NAME
 , PRODUCT_ID AS P_ID
 , PRODUCT_NAME
 , TO_NUMBER(
      SUBSTR(YR_QTY_STR, 1, INSTR(YR_QTY_STR, ';') - 1)
   ) AS YR
 , TO_NUMBER(
      SUBSTR(YR_QTY_STR, INSTR(YR_QTY_STR, ';') + 1)
   ) AS YR_QTY
FROM (
   SELECT
      BP.BREWERY_NAME
    , BP.PRODUCT_ID
    , BP.PRODUCT_NAME
    , (
         SELECT YS.YR || ';' || YS.YR_QTY
         FROM PRACTICAL.YEARLY_SALES YS
         WHERE YS.PRODUCT_ID = BP.PRODUCT_ID
         ORDER BY YS.YR_QTY DESC
         FETCH FIRST ROW ONLY
      ) AS YR_QTY_STR
   FROM PRACTICAL.BREWERY_PRODUCTS BP
   WHERE BP.BREWERY_ID = 518
)
ORDER BY PRODUCT_ID;
--
-- Listing 1-4. Using analytic function to be able to retrieve all columns if desired

SELECT
   BREWERY_NAME
 , PRODUCT_ID AS P_ID
 , PRODUCT_NAME
 , YR
 , YR_QTY
FROM (
   SELECT
      BP.BREWERY_NAME
    , BP.PRODUCT_ID
    , BP.PRODUCT_NAME
    , YS.YR
    , YS.YR_QTY
    , ROW_NUMBER() OVER (
         PARTITION BY BP.PRODUCT_ID
         ORDER BY YS.YR_QTY DESC
      ) AS RN
   FROM PRACTICAL.BREWERY_PRODUCTS BP
   JOIN PRACTICAL.YEARLY_SALES YS
      ON YS.PRODUCT_ID = BP.PRODUCT_ID
   WHERE BP.BREWERY_ID = 518
)
WHERE RN = 1
ORDER BY PRODUCT_ID;
--
/*
BREWERY_NAME             P_ID PRODUCT_NAME             YR    YR_QTY
_____________________ _______ ___________________ _______ _________
Balthazar Brauerei       5310 Monks and Nuns         2017       582
Balthazar Brauerei       5430 Hercule Trippel        2018       451
Balthazar Brauerei       6520 Der Helle Kumpel       2017       458
*/
--
/* if you run the inner SQL separetly you can understand how it extracts data */
--
SELECT
      BP.BREWERY_NAME
    , BP.PRODUCT_ID
    , BP.PRODUCT_NAME
    , YS.YR
    , YS.YR_QTY
    , ROW_NUMBER() OVER (
         PARTITION BY BP.PRODUCT_ID
         ORDER BY YS.YR_QTY DESC
      ) AS RN
   FROM PRACTICAL.BREWERY_PRODUCTS BP
   JOIN PRACTICAL.YEARLY_SALES YS
      ON YS.PRODUCT_ID = BP.PRODUCT_ID
   WHERE BP.BREWERY_ID = 518;
--
-- for each PRODUCT_ID and PRODUCT_NAME, the query ranks yearly sales and forms and window
-- and finally the outer query picks the rank 1 row from each window
/*
BREWERY_NAME             PRODUCT_ID PRODUCT_NAME             YR    YR_QTY    RN
_____________________ _____________ ___________________ _______ _________ _____
Balthazar Brauerei             5310 Monks and Nuns         2017       582     1
Balthazar Brauerei             5310 Monks and Nuns         2016       478     2
Balthazar Brauerei             5310 Monks and Nuns         2018       425     3
Balthazar Brauerei             5430 Hercule Trippel        2018       451     1
Balthazar Brauerei             5430 Hercule Trippel        2017       344     2
Balthazar Brauerei             5430 Hercule Trippel        2016       261     3
Balthazar Brauerei             6520 Der Helle Kumpel       2017       458     1
Balthazar Brauerei             6520 Der Helle Kumpel       2016       415     2
Balthazar Brauerei             6520 Der Helle Kumpel       2018       357     3
*/   
-- Listing 1-5. Achieving the same with a lateral inline view
-- CROSS JOIN lateral
SELECT
   BP.BREWERY_NAME
 , BP.PRODUCT_ID AS P_ID
 , BP.PRODUCT_NAME
 , TOP_YS.YR
 , TOP_YS.YR_QTY
FROM PRACTICAL.BREWERY_PRODUCTS BP
CROSS JOIN LATERAL(
   SELECT
      YS.YR
    , YS.YR_QTY
   FROM PRACTICAL.YEARLY_SALES YS
   WHERE YS.PRODUCT_ID = BP.PRODUCT_ID
   ORDER BY YS.YR_QTY DESC
   FETCH FIRST ROW ONLY
) TOP_YS
WHERE BP.BREWERY_ID = 518
ORDER BY BP.PRODUCT_ID;

-- Traditional style from clause without ANSI style cross join

SELECT
   BP.BREWERY_NAME
 , BP.PRODUCT_ID AS P_ID
 , BP.PRODUCT_NAME
 , TOP_YS.YR
 , TOP_YS.YR_QTY
FROM PRACTICAL.BREWERY_PRODUCTS BP
, LATERAL(
   SELECT
      YS.YR
    , YS.YR_QTY
   FROM PRACTICAL.YEARLY_SALES YS
   WHERE YS.PRODUCT_ID = BP.PRODUCT_ID
   ORDER BY YS.YR_QTY DESC
   FETCH FIRST ROW ONLY
) TOP_YS
WHERE BP.BREWERY_ID = 518
ORDER BY BP.PRODUCT_ID;

-- Combining both lateral and join predicates in the on clause

SELECT
   BP.BREWERY_NAME
 , BP.PRODUCT_ID AS P_ID
 , BP.PRODUCT_NAME
 , TOP_YS.YR
 , TOP_YS.YR_QTY
FROM PRACTICAL.BREWERY_PRODUCTS BP
JOIN LATERAL(
   SELECT
      YS.YR
    , YS.YR_QTY
   FROM PRACTICAL.YEARLY_SALES YS
   WHERE YS.PRODUCT_ID = BP.PRODUCT_ID
   ORDER BY YS.YR_QTY DESC
   FETCH FIRST ROW ONLY
) TOP_YS
   ON 1=1
WHERE BP.BREWERY_ID = 518
ORDER BY BP.PRODUCT_ID;

-- Listing 1-6. The alternative syntax cross apply

SELECT
   BP.BREWERY_NAME
 , BP.PRODUCT_ID AS P_ID
 , BP.PRODUCT_NAME
 , TOP_YS.YR
 , TOP_YS.YR_QTY
FROM PRACTICAL.BREWERY_PRODUCTS BP
CROSS APPLY(
   SELECT
      YS.YR
    , YS.YR_QTY
   FROM PRACTICAL.YEARLY_SALES YS
   WHERE YS.PRODUCT_ID = BP.PRODUCT_ID
   ORDER BY YS.YR_QTY DESC
   FETCH FIRST ROW ONLY
) TOP_YS
WHERE BP.BREWERY_ID = 518
ORDER BY BP.PRODUCT_ID;

/* All the above queries uses OREDER BY DESC and then FETCH FIRST ROW ONLY to identify the top yearly sale */

-- Listing 1-7. Using outer apply when you need outer join functionality

/* The below query uses LEFT OUTER JOIN using OUTER APPLY clause. 
   It left side pulls records from BREWERY_PRODUCTS table for BREWERY_ID = 518 
   and right side pulls records from YEARLY_SALES view with sales quality less than 400
   and do a LEFT OUTER join om Product ID.
*/
SELECT
   BP.BREWERY_NAME
 , BP.PRODUCT_ID AS P_ID
 , BP.PRODUCT_NAME
 , TOP_YS.YR
 , TOP_YS.YR_QTY
FROM PRACTICAL.BREWERY_PRODUCTS BP
OUTER APPLY(
   SELECT
      YS.YR
    , YS.YR_QTY
   FROM PRACTICAL.YEARLY_SALES YS
   WHERE YS.PRODUCT_ID = BP.PRODUCT_ID
   AND YS.YR_QTY < 400
   ORDER BY YS.YR_QTY DESC
   FETCH FIRST ROW ONLY
) TOP_YS
WHERE BP.BREWERY_ID = 518
ORDER BY BP.PRODUCT_ID;
--
-- PRODUCT_ID 5310 yearly sales quantity is NULL because none of its yearly sales quantity is less than 400
/*
BREWERY_NAME             P_ID PRODUCT_NAME             YR    YR_QTY
_____________________ _______ ___________________ _______ _________
Balthazar Brauerei       5310 Monks and Nuns
Balthazar Brauerei       5430 Hercule Trippel        2017       344
Balthazar Brauerei       6520 Der Helle Kumpel       2018       357
*/
--
 SELECT
      *
   FROM PRACTICAL.YEARLY_SALES YS
   WHERE YS.YR_QTY < 400
   ORDER BY YS.YR_QTY DESC;
--
/* As you can see 5310 does not appear in the output (its sales quantity is 478 and 582 for )
/*
     YR    PRODUCT_ID PRODUCT_NAME           YR_QTY
_______ _____________ ___________________ _________
   2016          7790 Summer in India           377
   2018          6520 Der Helle Kumpel          357
   2017          5430 Hercule Trippel           344
   2016          4160 Reindeer Fuel             331
   2017          7790 Summer in India           321
   2018          4040 Coalminers Sweat          300
   2016          4040 Coalminers Sweat          286
   2018          7790 Summer in India           263
   2016          5430 Hercule Trippel           261
   2017          4040 Coalminers Sweat          227
   2017          7950 Pale Rider Rides          210
   2016          7950 Pale Rider Rides          182
   2018          4280 Hoppy Crude Oil           132
   2016          6600 Hazy Pink Cloud           121

     YR    PRODUCT_ID PRODUCT_NAME          YR_QTY
_______ _____________ __________________ _________
   2017          6600 Hazy Pink Cloud          105
   2016          4280 Hoppy Crude Oil           99
   2018          6600 Hazy Pink Cloud           98
   2017          4280 Hoppy Crude Oil           72
*/   
--   
-- Listing 1-8. Outer join with the lateral keyword

SELECT
   BP.BREWERY_NAME
 , BP.PRODUCT_ID AS P_ID
 , BP.PRODUCT_NAME
 , TOP_YS.YR
 , TOP_YS.YR_QTY
FROM PRACTICAL.BREWERY_PRODUCTS BP
LEFT JOIN LATERAL(
   SELECT
      YS.YR
    , YS.YR_QTY
   FROM PRACTICAL.YEARLY_SALES YS
   WHERE YS.PRODUCT_ID = BP.PRODUCT_ID
   ORDER BY YS.YR_QTY DESC
   FETCH FIRST ROW ONLY
) TOP_YS
   ON TOP_YS.YR_QTY < 400
WHERE BP.BREWERY_ID = 518
ORDER BY BP.PRODUCT_ID;

-- Output: This time we have moved the LEFT JOIN query condition from right to left query and result is changed
-- Why? Because in previous qurery, top sales quantiy less 400 along with their year of sales were extracted from 
-- YEARLY_SALES first and then the result set was LEFT JOINed with the outer query using OUTER APPLY.
-- In the second query, top sales quantity (all are greater than 400) along with their year of sales were 
-- extracted and then was LEFT JOINed with LATERAL clause so right side table produced NULL values for its
-- columns.

/*
BREWERY_NAME             P_ID PRODUCT_NAME           YR    YR_QTY
_____________________ _______ ___________________ _____ _________
Balthazar Brauerei       5310 Monks and Nuns
Balthazar Brauerei       5430 Hercule Trippel
Balthazar Brauerei       6520 Der Helle Kumpel
*/
--
SELECT
   BP.BREWERY_NAME
 , BP.PRODUCT_ID AS P_ID
 , BP.PRODUCT_NAME
 , TOP_YS.YR
 , TOP_YS.YR_QTY
FROM PRACTICAL.BREWERY_PRODUCTS BP
LEFT OUTER JOIN LATERAL(
   SELECT
      YS.YR
    , YS.YR_QTY
   FROM PRACTICAL.YEARLY_SALES YS
   WHERE YS.PRODUCT_ID = BP.PRODUCT_ID
   ORDER BY YS.YR_QTY DESC
   FETCH FIRST ROW ONLY
) TOP_YS
   ON TOP_YS.YR_QTY < 500
WHERE BP.BREWERY_ID = 518
ORDER BY BP.PRODUCT_ID;
--
-- Output: This the sales and year value for two products were not NULL because we changed the sales qty. to 500.
/*
BREWERY_NAME             P_ID PRODUCT_NAME             YR    YR_QTY
_____________________ _______ ___________________ _______ _________
Balthazar Brauerei       5310 Monks and Nuns
Balthazar Brauerei       5430 Hercule Trippel        2018       451
Balthazar Brauerei       6520 Der Helle Kumpel       2017       458
*/
--
--
/* 
   CROSS APPLY Vs OUTER APPLY
*/
--
-- OUTER APPLY 
--
SELECT
   BP.BREWERY_NAME
 , BP.PRODUCT_ID AS P_ID
 , BP.PRODUCT_NAME
 , TOP_YS.YR
 , TOP_YS.YR_QTY
FROM PRACTICAL.BREWERY_PRODUCTS BP
OUTER APPLY(
   SELECT
      YS.YR
    , YS.YR_QTY
   FROM PRACTICAL.YEARLY_SALES YS
   WHERE YS.PRODUCT_ID = BP.PRODUCT_ID
   AND YS.YR_QTY < 400
   ORDER BY YS.YR_QTY DESC
   FETCH FIRST ROW ONLY
) TOP_YS
WHERE BP.BREWERY_ID = 518
ORDER BY BP.PRODUCT_ID;
--
/*
BREWERY_NAME             P_ID PRODUCT_NAME             YR    YR_QTY
_____________________ _______ ___________________ _______ _________
Balthazar Brauerei       5310 Monks and Nuns
Balthazar Brauerei       5430 Hercule Trippel        2017       344
Balthazar Brauerei       6520 Der Helle Kumpel       2018       357
*/
--
-- CROSS APPLY
--
SELECT
   BP.BREWERY_NAME
 , BP.PRODUCT_ID AS P_ID
 , BP.PRODUCT_NAME
 , TOP_YS.YR
 , TOP_YS.YR_QTY
FROM PRACTICAL.BREWERY_PRODUCTS BP
CROSS APPLY(
   SELECT
      YS.YR
    , YS.YR_QTY
   FROM PRACTICAL.YEARLY_SALES YS
   WHERE YS.PRODUCT_ID = BP.PRODUCT_ID
   AND YS.YR_QTY < 400
   ORDER BY YS.YR_QTY DESC
   FETCH FIRST ROW ONLY
) TOP_YS
WHERE BP.BREWERY_ID = 518
ORDER BY BP.PRODUCT_ID;
--
--
-- In CROSS APPLY we are getting two rows because the unmatched row is eliminated.
-- CROSS APPLY works same way as INNER JOIN with left coorelation lateral 
/*
BREWERY_NAME             P_ID PRODUCT_NAME             YR    YR_QTY
_____________________ _______ ___________________ _______ _________
Balthazar Brauerei       5430 Hercule Trippel        2017       344
Balthazar Brauerei       6520 Der Helle Kumpel       2018       357
*/
--
--
/*
   OUTER APPLY Vs OUTER JOIN LATERAL
*/
--
-- LEFT OUTER JOIN LATERAL
--
-- Problem: For each beer (product id) display the best-selling 
-- year and quantity if that year sold less than 500 bottles.
--
SELECT
   BP.BREWERY_NAME
 , BP.PRODUCT_ID AS P_ID
 , BP.PRODUCT_NAME
 , TOP_YS.YR
 , TOP_YS.YR_QTY
FROM PRACTICAL.BREWERY_PRODUCTS BP
LEFT OUTER JOIN LATERAL(
   SELECT
      YS.YR
    , YS.YR_QTY
   FROM PRACTICAL.YEARLY_SALES YS
   WHERE YS.PRODUCT_ID = BP.PRODUCT_ID
   ORDER BY YS.YR_QTY DESC
   FETCH FIRST ROW ONLY
) TOP_YS
   ON TOP_YS.YR_QTY < 500
WHERE BP.BREWERY_ID = 518
ORDER BY BP.PRODUCT_ID;
--
--
/*
BREWERY_NAME             P_ID PRODUCT_NAME             YR    YR_QTY
_____________________ _______ ___________________ _______ _________
Balthazar Brauerei       5310 Monks and Nuns
Balthazar Brauerei       5430 Hercule Trippel        2018       451
Balthazar Brauerei       6520 Der Helle Kumpel       2017       458
*/
--
-- OUTER APPLY 
-- For each beer (product ID), display best-selling year and 
-- quantiy out of those years that sold less than 500 bottles
--
SELECT
   BP.BREWERY_NAME
 , BP.PRODUCT_ID AS P_ID
 , BP.PRODUCT_NAME
 , TOP_YS.YR
 , TOP_YS.YR_QTY
FROM PRACTICAL.BREWERY_PRODUCTS BP
OUTER APPLY (
   SELECT
      YS.PRODUCT_ID,
      YS.YR
    , YS.YR_QTY
   FROM PRACTICAL.YEARLY_SALES YS
   WHERE YS.PRODUCT_ID = BP.PRODUCT_ID AND YS.YR_QTY < 500
   ORDER BY YS.YR_QTY DESC
   FETCH FIRST ROW ONLY
) TOP_YS
WHERE BP.BREWERY_ID = 518
ORDER BY BP.PRODUCT_ID;
--
/*
BREWERY_NAME             P_ID PRODUCT_NAME             YR    YR_QTY
_____________________ _______ ___________________ _______ _________
Balthazar Brauerei       5310 Monks and Nuns         2016       478
Balthazar Brauerei       5430 Hercule Trippel        2018       451
Balthazar Brauerei       6520 Der Helle Kumpel       2017       458
*/
/* ***************************************************** */


