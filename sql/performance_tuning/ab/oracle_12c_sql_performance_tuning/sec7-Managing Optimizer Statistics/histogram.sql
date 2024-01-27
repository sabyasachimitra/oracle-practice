--get METHOD_OPT global setting
col METHOD_OPT format a30
SELECT DBMS_STATS.GET_PREFS(PNAME =>'METHOD_OPT') METHOD_OPT FROM DUAL;
--
SELECT DBMS_STATS.GET_PREFS(PNAME =>'ESTIMATE_PERCENT') METHOD_OPT FROM DUAL;
--
SELECT DBMS_STATS.GET_PREFS(PNAME =>'ESTIMATE_PERCENT', OWNNAME=>'SOE', TABNAME=>'ORDERS2') EST_PERCENT FROM DUAL;
--
--AUTO means Oracle will automatically determines the columns that need histograms based on the column usage 
--information (SYS.COL_USAGE$), and the presence of a data skew.
--An integer value indicates that a histogram will be created 
--with at most the specified number of buckets. Must be in the range [1,254]. 
--Note SIZE 1 means no histogram will be created.
METHOD_OPT
------------------------------
FOR ALL COLUMNS SIZE AUTO
--
--create ORDERS2 table, insert data and gather statistics
DROP TABLE SOE.ORDERS2 PURGE;
CREATE TABLE SOE.ORDERS2 
( 
	ORDER_ID NUMBER(12), 
	ORDER_DATE TIMESTAMP(6) WITH LOCAL TIME ZONE, 
	ORDER_TOTAL NUMBER(8,2),
	ORDER_MODE VARCHAR2(8), 
	CUSTOMER_ID NUMBER(12), 
	ORDER_STATUS NUMBER(2)
);
--
CREATE INDEX SOE.ORDERS2_TOTAL_IX ON SOE.ORDERS2(ORDER_TOTAL);
--
INSERT INTO SOE.ORDERS2 SELECT ORDER_ID, ORDER_DATE, ORDER_TOTAL, ORDER_MODE,
CUSTOMER_ID, ORDER_STATUS FROM SOE.ORDERS WHERE ORDER_TOTAL BETWEEN 10000 AND
15000;
--
COMMIT;
--
--CASCADE option determines whether index statistics are collected as part of
--gathering table statistics.
exec DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>'SOE', TABNAME=>'ORDERS2', CASCADE=>TRUE);
--check column statistics
@display_colstats
--
--
--DENSITY: If no Histogram is present for the column it is 1/NUM_DISTINCT
--No histogram was gathered because when the optimizer gathered the table statistics, 
--it did not find  any predicate saved for the table in SYS.COL_USAGE$
COLUMN_NAME     NUM_DISTINCT  NUM_NULLS HISTOGRAM          DENSITY NUM_BUCKETS
--------------- ------------ ---------- --------------- ---------- -----------
ORDER_ID              200096          0 NONE            4.9976E-06           1
ORDER_DATE            200048          0 NONE            4.9988E-06           1
ORDER_TOTAL             2600          0 NONE            .000384615           1
ORDER_MODE                 2       1807 NONE                    .5           1
CUSTOMER_ID            11136          0 NONE            .000089799           1
ORDER_STATUS              10          0 NONE                    .1           1
--
--execute the folloowing queries 
SELECT * FROM SOE.ORDERS2 WHERE ORDER_TOTAL =10050;
--
SELECT * FROM SOE.ORDERS2 WHERE ORDER_TOTAL <10050;
--
set linesize 180
--Now check if predicate information of the above queries have been saved or not.
--SYS.COL_USAGE$ gets refreshed by Oracle SMON background process every few minutes. To manually refresh it, execute 
--DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO.
exec DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO;
--
@display_preds
--
--Range predicate information is stored now. 
COLUMN_NAME    EQUIJOIN_PREDS NONEQUIJOIN_PREDS RANGE_PREDS LIKE_PREDS NULL_PREDS
-------------- -------------- ----------------- ----------- ---------- ----------
ORDER_TOTAL                 0                 0           1          0          0
--
--gather statistics again on the table
exec DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>'SOE', TABNAME=>'ORDERS2', CASCADE=>TRUE);
--
@display_colstats
--
--A Hybrid histogram is generated for the column ORDER_TOTAL. 
--No Histogram is generated for the other columns as they were not used in the queries yet.
COLUMN_NAME     NUM_DISTINCT  NUM_NULLS HISTOGRAM          DENSITY NUM_BUCKETS
--------------- ------------ ---------- --------------- ---------- -----------
ORDER_ID              200096          0 NONE            4.9976E-06           1
ORDER_DATE            200048          0 NONE            4.9988E-06           1
ORDER_TOTAL             2600          0 HYBRID             .000301         254
ORDER_MODE                 2       1807 NONE                    .5           1
CUSTOMER_ID            11136          0 NONE            .000089799           1
ORDER_STATUS              10          0 NONE                    .1           1
--
DROP TABLE SOE.ORDERS2 PURGE;
--
--Create a new table ORDERS2
CREATE TABLE SOE.ORDERS2 
( 
	ORDER_ID NUMBER(12), 
	ORDER_DATE TIMESTAMP(6) WITH LOCAL TIME ZONE, 
	ORDER_TOTAL NUMBER(8,2),
	ORDER_MODE VARCHAR2(8), 
	CUSTOMER_ID NUMBER(12), 
	ORDER_STATUS NUMBER(2), 
	SALES_REP_ID NUMBER(6)
);
--
INSERT INTO SOE.ORDERS2 SELECT ORDER_ID, ORDER_DATE, ORDER_TOTAL, ORDER_MODE,
CUSTOMER_ID, ORDER_STATUS, ROUND(SALES_REP_ID,-1) FROM SOE.ORDERS WHERE
(ORDER_TOTAL BETWEEN 8500 AND 15000) AND (SALES_REP_ID BETWEEN 100 AND 999);
--
COMMIT;
--
CREATE INDEX SOE.ORDERS2_SREP_IX ON SOE.ORDERS2(SALES_REP_ID);
--
exec DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>'SOE', TABNAME=>'ORDERS2', CASCADE=>TRUE);
--
--check distinct SALES_REP_ID
col DISTINCT_SL_REP_ID format 9999
SELECT COUNT(DISTINCT SALES_REP_ID) DISTINCT_SL_REP_ID FROM SOE.ORDERS2;
--
DISTINCT_SL_REP_ID
------------------
                67
--
SELECT SALES_REP_ID SALES_REP_ID, COUNT(1) COUNT FROM SOE.ORDERS2 GROUP BY SALES_REP_ID ORDER BY SALES_REP_ID;
--
SALES_REP_ID      COUNT
------------ ----------
         110         17
         200         16
         210         33
         220         48
         230         66
         240        162
         250         99
         260         81
         270        165
         280        179
         290        181
         300        248
         310        280
         320        295
         330        296
         340        560
         350        462
         360        504
         370        526
         380        703
         390        788
         400        671
         410        864
         420       1036
         430       1053
         440       1217
         450       1253
         460       1019
         470       1302
         480       1250
         490       1086
         500       1111
         510       1300
         520       1071
         530       1216
         540       1096
         550       1219
         560        984
         570        922
         580       1069
         590        610
         600        725
         610        823
         620        757
         630        779
         640        491
         650        331
         660        526
         670        315
         680        247
         690        234
         700        228
         710        181
         720        133
         730        116
         740        116
         750        132
         760         49
         770         50
         780         17
         790         16
         800         16
         810         16
         820         17
         840         16
         850         34
         860         17
--
--Creating Frequency Histogram
--
exec DBMS_STATS.GATHER_TABLE_STATS ( OWNNAME => 'SOE', TABNAME => 'ORDERS2', METHOD_OPT => 'FOR COLUMNS SALES_REP_ID');
--
 @display_colstats
 --
 --A Frequency Histogram is gerenated.
 --Number of distinct values is equal to the number of buckets
 COLUMN_NAME     NUM_DISTINCT  NUM_NULLS HISTOGRAM          DENSITY NUM_BUCKETS
--------------- ------------ ---------- --------------- ---------- -----------
ORDER_ID               33412          0 NONE            .000029929           1
ORDER_DATE             33400          0 NONE             .00002994           1
ORDER_TOTAL             1414          0 NONE            .000707214           1
ORDER_MODE                 2       6673 NONE                    .5           1
CUSTOMER_ID             1976          0 NONE            .000506073           1
ORDER_STATUS               8          0 NONE                  .125           1
SALES_REP_ID              67          0 FREQUENCY       .000014952          67
--
@display_histo SALES_REP_ID
--
COLUMN_NAME     ENDPOINT_NUMBER ENDPOINT_VALUE ENDPOINT_REPEAT_COUNT
--------------- --------------- -------------- ---------------------
SALES_REP_ID                 17            110                     0
SALES_REP_ID                 33            200                     0
SALES_REP_ID                 66            210                     0
SALES_REP_ID                114            220                     0
SALES_REP_ID                180            230                     0
SALES_REP_ID                342            240                     0
SALES_REP_ID                441            250                     0
SALES_REP_ID                522            260                     0
SALES_REP_ID                687            270                     0
SALES_REP_ID                866            280                     0
SALES_REP_ID               1047            290                     0
SALES_REP_ID               1295            300                     0
SALES_REP_ID               1575            310                     0
SALES_REP_ID               1870            320                     0
SALES_REP_ID               2166            330                     0
SALES_REP_ID               2726            340                     0
SALES_REP_ID               3188            350                     0
SALES_REP_ID               3692            360                     0
SALES_REP_ID               4218            370                     0
SALES_REP_ID               4921            380                     0
SALES_REP_ID               5709            390                     0
SALES_REP_ID               6380            400                     0
SALES_REP_ID               7244            410                     0
SALES_REP_ID               8280            420                     0
SALES_REP_ID               9333            430                     0
SALES_REP_ID              10550            440                     0
SALES_REP_ID              11803            450                     0
SALES_REP_ID              12822            460                     0
SALES_REP_ID              14124            470                     0
SALES_REP_ID              15374            480                     0
SALES_REP_ID              16460            490                     0
SALES_REP_ID              17571            500                     0
SALES_REP_ID              18871            510                     0
SALES_REP_ID              19942            520                     0
SALES_REP_ID              21158            530                     0
SALES_REP_ID              22254            540                     0
SALES_REP_ID              23473            550                     0
SALES_REP_ID              24457            560                     0
SALES_REP_ID              25379            570                     0
SALES_REP_ID              26448            580                     0
SALES_REP_ID              27058            590                     0
SALES_REP_ID              27783            600                     0
SALES_REP_ID              28606            610                     0
SALES_REP_ID              29363            620                     0
SALES_REP_ID              30142            630                     0
SALES_REP_ID              30633            640                     0
SALES_REP_ID              30964            650                     0
SALES_REP_ID              31490            660                     0
SALES_REP_ID              31805            670                     0
SALES_REP_ID              32052            680                     0
SALES_REP_ID              32286            690                     0
SALES_REP_ID              32514            700                     0
SALES_REP_ID              32695            710                     0
SALES_REP_ID              32828            720                     0
SALES_REP_ID              32944            730                     0
SALES_REP_ID              33060            740                     0
SALES_REP_ID              33192            750                     0
SALES_REP_ID              33241            760                     0
SALES_REP_ID              33291            770                     0
SALES_REP_ID              33308            780                     0
SALES_REP_ID              33324            790                     0
SALES_REP_ID              33340            800                     0
SALES_REP_ID              33356            810                     0
SALES_REP_ID              33373            820                     0
SALES_REP_ID              33389            840                     0
SALES_REP_ID              33423            850                     0
SALES_REP_ID              33440            860                     0
--
--Top Frequency Histogram
--As the number of buckets is less than the NDV, the optimizer creates either top frequency OR hybrid histograms
--When Number of Distinct Values (NDV) is more than the Number of 
--Buckets in Histogram AND P value is less than the top distinct values.
--
--If we use 52 buckets instead of 67 (in the above example), our P value would be.
--p=(1-(1/n))*100=(1-(1/52))*100=98.077
--Now Let's calculate the percentage of top 52 distinct values in the ORDERS2 table. Since we are using 52 buckets, we will 
--take 52 as the number of distinct values.
--
--Total Number of Rows
SELECT COUNT(*) FROM SOE.ORDERS2; 
--
COUNT(*)
----------
33440
--
WITH SALES_REP_COUNT AS
	(
		SELECT 
			SALES_REP_ID, COUNT(*) N 
		FROM SOE.ORDERS2 
		GROUP BY SALES_REP_ID 
		ORDER BY COUNT(*) DESC FETCH FIRST 52 ROWS ONLY
	)
SELECT 
	SUM(N) 
FROM 
	SALES_REP_COUNT;
--
  SUM(N)
----------
     33012
--Percentage of Top 52 distinct values is (33012/33440)*100 = 98.72. Since this is larger than P value AND NDV is greater
--than the Number of Buckets a Top Frequency Histogram should be created by the Optimizer.
--Gather stat with 52 buckets.
exec DBMS_STATS.GATHER_TABLE_STATS ( OWNNAME => 'SOE', TABNAME => 'ORDERS2', METHOD_OPT => 'FOR COLUMNS SALES_REP_ID SIZE 52');
--
@display_colstats /* display column statistics */
--
COLUMN_NAME     NUM_DISTINCT  NUM_NULLS HISTOGRAM          DENSITY NUM_BUCKETS
--------------- ------------ ---------- --------------- ---------- -----------
ORDER_ID               33412          0 NONE            .000029929           1
ORDER_DATE             33400          0 NONE             .00002994           1
ORDER_TOTAL             1414          0 NONE            .000707214           1
ORDER_MODE                 2       6673 NONE                    .5           1
CUSTOMER_ID             1976          0 NONE            .000506073           1
ORDER_STATUS               8          0 NONE                  .125           1
SALES_REP_ID              67          0 TOP-FREQUENCY   .000014952          52
--
@display_histo SALES_REP_ID /* Check Histogram buckets */
--
--ENDPOINT_NUMBER (which is cummulative frequency) has changed for many ENDPOINT_VALUE because there are 52 buckets now. 
--but frequency remain unchanged (difference of ENDPOINT_NUMBER of two consecutive buckets).
COLUMN_NAME     ENDPOINT_NUMBER ENDPOINT_VALUE ENDPOINT_REPEAT_COUNT
--------------- --------------- -------------- ---------------------
SALES_REP_ID                  1            110                     0
SALES_REP_ID                163            240                     0
SALES_REP_ID                328            270                     0
SALES_REP_ID                507            280                     0
SALES_REP_ID                688            290                     0
SALES_REP_ID                936            300                     0
SALES_REP_ID               1216            310                     0
SALES_REP_ID               1511            320                     0
SALES_REP_ID               1807            330                     0
SALES_REP_ID               2367            340                     0
SALES_REP_ID               2829            350                     0
SALES_REP_ID               3333            360                     0
SALES_REP_ID               3859            370                     0
SALES_REP_ID               4562            380                     0
SALES_REP_ID               5350            390                     0
SALES_REP_ID               6021            400                     0
SALES_REP_ID               6885            410                     0
SALES_REP_ID               7921            420                     0
SALES_REP_ID               8974            430                     0
SALES_REP_ID              10191            440                     0
SALES_REP_ID              11444            450                     0
SALES_REP_ID              12463            460                     0
SALES_REP_ID              13765            470                     0
SALES_REP_ID              15015            480                     0
SALES_REP_ID              16101            490                     0
SALES_REP_ID              17212            500                     0
SALES_REP_ID              18512            510                     0
SALES_REP_ID              19583            520                     0
SALES_REP_ID              20799            530                     0
SALES_REP_ID              21895            540                     0
SALES_REP_ID              23114            550                     0
SALES_REP_ID              24098            560                     0
SALES_REP_ID              25020            570                     0
SALES_REP_ID              26089            580                     0
SALES_REP_ID              26699            590                     0
SALES_REP_ID              27424            600                     0
SALES_REP_ID              28247            610                     0
SALES_REP_ID              29004            620                     0
SALES_REP_ID              29783            630                     0
SALES_REP_ID              30274            640                     0
SALES_REP_ID              30605            650                     0
SALES_REP_ID              31131            660                     0
SALES_REP_ID              31446            670                     0
SALES_REP_ID              31693            680                     0
SALES_REP_ID              31927            690                     0
SALES_REP_ID              32155            700                     0
SALES_REP_ID              32336            710                     0
SALES_REP_ID              32469            720                     0
SALES_REP_ID              32585            730                     0
SALES_REP_ID              32701            740                     0
SALES_REP_ID              32833            750                     0
SALES_REP_ID              32834            860                     0

52 rows selected.
--
SET AUTOTRACE TRACEONLY 
SELECT COUNT(*) FROM SOE.ORDERS2 WHERE SALES_REP_ID=340;
--
--The cardinality is correctly calculated which is 560. There is a bucket for 340 in the Histogram.
-------------------------------------------------------------------------------------
| Id  | Operation         | Name            | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |                 |     1 |     4 |     2   (0)| 00:00:01 |
|   1 |  SORT AGGREGATE   |                 |     1 |     4 |            |          |
|*  2 |   INDEX RANGE SCAN| ORDERS2_SREP_IX |   560 |  2240 |     2   (0)| 00:00:01 |
-------------------------------------------------------------------------------------
--
SELECT COUNT(*) FROM SOE.ORDERS2 WHERE SALES_REP_ID=230;
--
--This time cardinality is not correctly calculated (66 vs 40) because there is no bucket for 230 in the Histogram.
-------------------------------------------------------------------------------------
| Id  | Operation         | Name            | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |                 |     1 |     4 |     1   (0)| 00:00:01 |
|   1 |  SORT AGGREGATE   |                 |     1 |     4 |            |          |
|*  2 |   INDEX RANGE SCAN| ORDERS2_SREP_IX |    40 |   160 |     1   (0)| 00:00:01 |
-------------------------------------------------------------------------------------
--
--Height-Balanced Histogram
--
--Height Balanced Histogram is a legacy Histogram (obsolete after 11g). If NDV is greater than the number of buckets AND
--ESTIMATE_PERCENT is NOT AUTO_SAMPLE_SIZE, Optimizer creates Height Balanced Histogram. 
--
--gather statistiscs
exec DBMS_STATS.GATHER_TABLE_STATS ( OWNNAME => 'SOE', TABNAME => 'ORDERS2', METHOD_OPT => 'FOR COLUMNS SALES_REP_ID SIZE 52', 
	ESTIMATE_PERCENT => 100);
--
@display_colstats
--
COLUMN_NAME     NUM_DISTINCT  NUM_NULLS HISTOGRAM          DENSITY NUM_BUCKETS
--------------- ------------ ---------- --------------- ---------- -----------
ORDER_ID               33412          0 NONE            .000029929           1
ORDER_DATE             33400          0 NONE             .00002994           1
ORDER_TOTAL             1414          0 NONE            .000707214           1
ORDER_MODE                 2       6673 NONE                    .5           1
CUSTOMER_ID             1976          0 NONE            .000506073           1
ORDER_STATUS               8          0 NONE                  .125           1
SALES_REP_ID              67          0 HEIGHT BALANCED .019192162          52
--
@display_histo SALES_REP_ID
--
-- We can see though the ENDPOINT_NUMBER of the last bucket is 52, the many ENDPOINT_VALUES are missing. For example, we can only
-- see 720 ENDPOINT_VALUE. The reason is in Height Balanced Histogram several values are compressed into one bucket. Values up to
-- 720 are compressed in bucket with ENDPOINT_VALUE as 720 and remaining values are all squeezed into bucket with ENDPOINT_VALUE
-- as 860. So though the ENDPOINT_VALUE of the last bucket is 52, there are only 39 buckets created instead of 52.
-- In Height Balanced Histogram a popular value may span two buckets and Optimizer cannot calculate the cardinality correctly.
-- 
COLUMN_NAME     ENDPOINT_NUMBER ENDPOINT_VALUE ENDPOINT_REPEAT_COUNT
--------------- --------------- -------------- ---------------------
SALES_REP_ID                  0            110                     0
SALES_REP_ID                  1            270                     0
SALES_REP_ID                  2            300                     0
SALES_REP_ID                  3            330                     0
SALES_REP_ID                  4            340                     0
SALES_REP_ID                  5            360                     0
SALES_REP_ID                  6            370                     0
SALES_REP_ID                  7            380                     0
SALES_REP_ID                  8            390                     0
SALES_REP_ID                  9            400                     0
SALES_REP_ID                 11            410                     0
SALES_REP_ID                 12            420                     0
SALES_REP_ID                 14            430                     0
SALES_REP_ID                 16            440                     0
SALES_REP_ID                 18            450                     0
SALES_REP_ID                 19            460                     0
SALES_REP_ID                 21            470                     0
SALES_REP_ID                 23            480                     0
SALES_REP_ID                 25            490                     0
SALES_REP_ID                 27            500                     0
SALES_REP_ID                 29            510                     0
SALES_REP_ID                 31            520                     0
SALES_REP_ID                 32            530                     0
SALES_REP_ID                 34            540                     0
SALES_REP_ID                 36            550                     0
SALES_REP_ID                 38            560                     0
SALES_REP_ID                 39            570                     0
SALES_REP_ID                 41            580                     0
SALES_REP_ID                 42            590                     0
SALES_REP_ID                 43            600                     0
SALES_REP_ID                 44            610                     0
SALES_REP_ID                 45            620                     0
SALES_REP_ID                 46            630                     0
SALES_REP_ID                 47            640                     0
SALES_REP_ID                 48            650                     0
SALES_REP_ID                 49            670                     0
SALES_REP_ID                 50            690                     0
SALES_REP_ID                 51            720                     0
SALES_REP_ID                 52            860                     0

39 rows selected.
--
SET AUTOTRACE TRACEONLY 
SELECT COUNT(*) FROM SOE.ORDERS2 WHERE SALES_REP_ID = 730;
--
--Cardinality is calculated as 291 whereas the actual cardinality is 116.
-------------------------------------------------------------------------------------
| Id  | Operation         | Name            | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |                 |     1 |     4 |     1   (0)| 00:00:01 |
|   1 |  SORT AGGREGATE   |                 |     1 |     4 |            |          |
|*  2 |   INDEX RANGE SCAN| ORDERS2_SREP_IX |   291 |  1164 |     1   (0)| 00:00:01 |
-------------------------------------------------------------------------------------
--
SELECT COUNT(*) FROM SOE.ORDERS2 WHERE SALES_REP_ID = 480;
--Actual Cardinality is 1250.
-------------------------------------------------------------------------------------
| Id  | Operation         | Name            | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |                 |     1 |     4 |     3   (0)| 00:00:01 |
|   1 |  SORT AGGREGATE   |                 |     1 |     4 |            |          |
|*  2 |   INDEX RANGE SCAN| ORDERS2_SREP_IX |  1286 |  5144 |     3   (0)| 00:00:01 |
-------------------------------------------------------------------------------------
-- Note that we cannot calculate the frequency of a value in a bucket by the difference between two consecutive ENDPOINT_NUMBERS.
--
-- Hybrid Histogram:: As of Oracle 12c.
-- Hybrid Histogram:: Combines the characteristics of Height Balanced and Frequency Histogram.
-- Hybrid Histogram:: NDV is greater than number of buckets specified in GATHER_STAT.
-- Hybrid Histogram:: P value is greater than the percentage of top n (number of buckets) distinct values.
-- Hybrid Histogram:: The ESTIMATE_PERCENT is AUTO_SAMPLE_SIZE.
-- Hybrid Histogram:: In Height Balanced Histogram Endpoint Value of a bucket may span into another bucket. In Hybrid Histogram
-- Hybrid Histogram:: no value occupies more than one bucket. For each Endpoint Value it stores ENDPOINT_REPEAT_COUNT which is 
-- Hybrid Histogram:: the number of times the endpoint value is repeated in a bucket. Using this value Optimizer can estimate
-- Hybrid Histogram:: for almost all popular values.
--
-- Test Case:: We are taking 40 buckets which is less than NDV (67). 
-- P value is (1-(1/n))*100=(1-(1/40))*100 = 97.5. 
--
--Let's calculate the percentage of top 40 distinct values
--Total Number of Rows
SELECT COUNT(*) FROM SOE.ORDERS2; 
--
COUNT(*)
----------
33440
--
WITH SALES_REP_COUNT AS
	(
		SELECT 
			SALES_REP_ID, COUNT(*) N 
		FROM SOE.ORDERS2 
		GROUP BY SALES_REP_ID 
		ORDER BY COUNT(*) DESC FETCH FIRST 40 ROWS ONLY
	)
SELECT 
	TRUNC((SUM(N) / 33440) * 100, 2) TOP_40_VAL_PCT
FROM 
	SALES_REP_COUNT;
--
TOP_40_VAL_PCT
--------------
         93.41
--
--This the above value is less than the P vale Optimizer should create a Hybrid Histogram
exec DBMS_STATS.GATHER_TABLE_STATS ( OWNNAME => 'SOE', TABNAME => 'ORDERS2', METHOD_OPT => 'FOR COLUMNS SALES_REP_ID SIZE 40');
--
@display_colstats
--
COLUMN_NAME     NUM_DISTINCT  NUM_NULLS HISTOGRAM          DENSITY NUM_BUCKETS
--------------- ------------ ---------- --------------- ---------- -----------
ORDER_ID               33412          0 NONE            .000029929           1
ORDER_DATE             33400          0 NONE             .00002994           1
ORDER_TOTAL             1414          0 NONE            .000707214           1
ORDER_MODE                 2       6673 NONE                    .5           1
CUSTOMER_ID             1976          0 NONE            .000506073           1
ORDER_STATUS               8          0 NONE                  .125           1
SALES_REP_ID              67          0 HYBRID               .0125          40
--
@display_histo SALES_REP_ID
--
--ENDPOINT_REPEAT_COUNT represents the cardinality of each ENDPOINT_VALUE.
--
COLUMN_NAME     ENDPOINT_NUMBER ENDPOINT_VALUE ENDPOINT_REPEAT_COUNT
--------------- --------------- -------------- ---------------------
SALES_REP_ID                  2            110                     2
SALES_REP_ID                112            270                    23
SALES_REP_ID                218            300                    43
SALES_REP_ID                317            320                    57
SALES_REP_ID                457            340                    98
SALES_REP_ID                608            360                    82
SALES_REP_ID                794            380                   115
SALES_REP_ID                920            390                   126
SALES_REP_ID               1154            410                   144
SALES_REP_ID               1326            420                   172
SALES_REP_ID               1510            430                   184
SALES_REP_ID               1715            440                   205
SALES_REP_ID               1948            450                   233
SALES_REP_ID               2142            460                   194
SALES_REP_ID               2329            470                   187
SALES_REP_ID               2557            480                   228
SALES_REP_ID               2742            490                   185
SALES_REP_ID               2923            500                   181
SALES_REP_ID               3141            510                   218
SALES_REP_ID               3316            520                   175
SALES_REP_ID               3540            530                   224
SALES_REP_ID               3724            540                   184
SALES_REP_ID               3942            550                   218
SALES_REP_ID               4101            560                   159
SALES_REP_ID               4266            570                   165
SALES_REP_ID               4437            580                   171
SALES_REP_ID               4631            600                    99
SALES_REP_ID               4784            610                   153
SALES_REP_ID               4915            620                   131
SALES_REP_ID               5048            630                   133
SALES_REP_ID               5173            650                    49
SALES_REP_ID               5319            670                    54
SALES_REP_ID               5435            700                    35
SALES_REP_ID               5547            750                    16
SALES_REP_ID               5562            790                     3
SALES_REP_ID               5565            800                     3
SALES_REP_ID               5567            810                     2
SALES_REP_ID               5569            820                     2
SALES_REP_ID               5574            850                     5
SALES_REP_ID               5577            860                     3

40 rows selected.
--
SET AUTOTRACE TRACEONLY 
SELECT COUNT(*) FROM SOE.ORDERS2 WHERE SALES_REP_ID = 700;
--
--Actual Cardinality is 228, close to estimated cardinality.
-------------------------------------------------------------------------------------
| Id  | Operation         | Name            | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |                 |     1 |     4 |     1   (0)| 00:00:01 |
|   1 |  SORT AGGREGATE   |                 |     1 |     4 |            |          |
|*  2 |   INDEX RANGE SCAN| ORDERS2_SREP_IX |   210 |   840 |     1   (0)| 00:00:01 |
-------------------------------------------------------------------------------------
--
--Comparison between Height Balanced and Hybrid Histogram
--
--get count of SALES_REP_ID > 720
SELECT COUNT(*) FROM SOE.ORDERS2 WHERE SALES_REP_ID>720;
--
  COUNT(*)
----------
       612
--Gather statistics with 40 buckets and ESTIMATE_PERCENT = 100.
--
exec DBMS_STATS.GATHER_TABLE_STATS ( OWNNAME => 'SOE', TABNAME => 'ORDERS2', METHOD_OPT => 'FOR COLUMNS SALES_REP_ID SIZE 40', ESTIMATE_PERCENT => 100);
--
@display_colstats
--
COLUMN_NAME     NUM_DISTINCT  NUM_NULLS HISTOGRAM          DENSITY NUM_BUCKETS
--------------- ------------ ---------- --------------- ---------- -----------
ORDER_ID               33412          0 NONE            .000029929           1
ORDER_DATE             33400          0 NONE             .00002994           1
ORDER_TOTAL             1414          0 NONE            .000707214           1
ORDER_MODE                 2       6673 NONE                    .5           1
CUSTOMER_ID             1976          0 NONE            .000506073           1
ORDER_STATUS               8          0 NONE                  .125           1
SALES_REP_ID              67          0 HEIGHT BALANCED .023895482          40
--
SET AUTOT ON
SET LINESIZE 180
ALTER SYSTEM FLUSH SHARED_POOL;
SELECT COUNT(*) FROM SOE.ORDERS2 WHERE SALES_REP_ID>720;
--
--Actual count is 620 while estimated count is 780. Around 27% deviation (with Height Balanced Histogram).
-------------------------------------------------------------------------------------
| Id  | Operation         | Name            | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |                 |     1 |     4 |     3   (0)| 00:00:01 |
|   1 |  SORT AGGREGATE   |                 |     1 |     4 |            |          |
|*  2 |   INDEX RANGE SCAN| ORDERS2_SREP_IX |   780 |  3120 |     3   (0)| 00:00:01 |
-------------------------------------------------------------------------------------
--
SET AUTOT OFF
--
--Gather statistics with 40 buckets and ESTIMATE_PERCENT = AUTO_SAMPLE_SIZE.
exec DBMS_STATS.GATHER_TABLE_STATS ( OWNNAME => 'SOE', TABNAME => 'ORDERS2', METHOD_OPT => 'FOR COLUMNS SALES_REP_ID SIZE 40');
--
COLUMN_NAME     NUM_DISTINCT  NUM_NULLS HISTOGRAM          DENSITY NUM_BUCKETS
--------------- ------------ ---------- --------------- ---------- -----------
ORDER_ID               33412          0 NONE            .000029929           1
ORDER_DATE             33400          0 NONE             .00002994           1
ORDER_TOTAL             1414          0 NONE            .000707214           1
ORDER_MODE                 2       6673 NONE                    .5           1
CUSTOMER_ID             1976          0 NONE            .000506073           1
ORDER_STATUS               8          0 NONE                  .125           1
SALES_REP_ID              67          0 HYBRID             .012821          40
--
SET AUTOT ON
ALTER SYSTEM FLUSH SHARED_POOL;
SELECT COUNT(*) FROM SOE.ORDERS2 WHERE SALES_REP_ID>720;
--
--Deviation (Hybrid Histogram) between Actual (612) and estimated (689) cardinality is 12.5%
-------------------------------------------------------------------------------------
| Id  | Operation         | Name            | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |                 |     1 |     4 |     3   (0)| 00:00:01 |
|   1 |  SORT AGGREGATE   |                 |     1 |     4 |            |          |
|*  2 |   INDEX RANGE SCAN| ORDERS2_SREP_IX |   689 |  2756 |     3   (0)| 00:00:01 |
-------------------------------------------------------------------------------------
--
SET AUTOT OFF
--
-- SKEWONLY option:: If you don't know how the data is distributed in table columns, 
-- SKEWONLY option:: in GATHER_STATS to generate Histograms for columns whose data is skewed.
--
exec DBMS_STATS.GATHER_TABLE_STATS ( OWNNAME => 'SOE', TABNAME => 'ORDERS2', METHOD_OPT => 'FOR ALL COLUMNS SIZE SKEWONLY');
--
COLUMN_NAME     NUM_DISTINCT  NUM_NULLS HISTOGRAM          DENSITY NUM_BUCKETS
--------------- ------------ ---------- --------------- ---------- -----------
ORDER_ID               33412          0 HYBRID              .00003         254
ORDER_DATE             33400          0 HYBRID              .00003         254
ORDER_TOTAL             1414          0 HYBRID             .000698         254
ORDER_MODE                 2       6673 FREQUENCY        .00001868           2
CUSTOMER_ID             1976          0 NONE            .000506073           1
ORDER_STATUS               8          0 FREQUENCY       .000014952           8
SALES_REP_ID              67          0 FREQUENCY       .000014952          67
--
col ORDER_MODE format a15
SELECT COUNT(*), ORDER_MODE FROM SOE.ORDERS2 GROUP BY ORDER_MODE;
--
--So a Frequency Histogram with two buckets are created for online and direct order mode.
 COUNT(*) ORDER_MODE
---------- ---------------
      6673
     12966 online
     13801 direct
--
