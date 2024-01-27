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

-- Listing 1-3. Using just a single scalar subquery and value concatenation

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
   JOIN YEARLY_SALES YS
      ON YS.PRODUCT_ID = BP.PRODUCT_ID
   WHERE BP.BREWERY_ID = 518
)
WHERE RN = 1
ORDER BY PRODUCT_ID;

-- Listing 1-5. Achieving the same with a lateral inline view

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

-- Listing 1-7. Using outer apply when you need outer join functionality

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

-- Listing 1-8. Outer join with the lateral keyword

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

/* ***************************************************** */
