/* Date and timestamp basics in Oracle Database */
--
/* There are differences between Date and Timestamp data types */
/* The maximum precision for timestamp is the nanosecond; the granularity of dates is the second */
/* Timestamps can store time zone information; dates cannot */
/* The units for dates are the number of days, timestamps use intervals */
--
/* Date and Timestamp - Mix and match data types */
--
/* 
Date +/- interval => timestamp
Timestamp +/- number => timestamp
Date – timestamp => number (of days)
Timestamp – date => number (of days)
Many datetime functions always return a date, 
even if the input is a timestamp. For example, trunc, add_months, and last_day.
*/
--
/* Substracting one date from another */
/* When you subtract one date from another in Oracle Database the result is the number of days between 
/* them. To see this as the number of days, hours, minutes, and seconds pass this to numtodstinterval with 
/* the units day. This returns a day to second interval, which is in the format DD HH24:MI:SS: */

select numtodsinterval (
         to_date ( '31-MAY-2023 12:34:56', 'DD-MON-YYYY HH24:MI:SS' ) 
           - date '2023-03-21',
         'day'
       ) interval_diff
from   dual;
-- output
/* +000000071 12:34:56.000000000 */
--
/* To get each unit difference separately we can pass each unit sepeartely */
--
with rws as (
  select numtodsinterval (
           to_date ( '31-MAY-2023 12:34:56', 'DD-MON-YYYY HH24:MI:SS' ) 
             - date '2023-03-21',
           'day'
         ) interval_diff
  from   dual
)
  select extract ( day from interval_diff ) days,
         extract ( hour from interval_diff ) hours,
         extract ( minute from interval_diff ) minutes,
         extract ( second from interval_diff ) seconds
  from   rws;
--
-- output
/*
DAYS,   HOURS,  MINUTES,    SECONDS
71,     12,     34,         56
*/
--
/* Difference between two timestamp values is always a day to second interval */
--
select to_timestamp ( '31-MAY-2023 12:34:56', 'DD-MON-YYYY HH24:MI:SS' ) 
         - timestamp '2024-05-31 00:00:00' interval_diff
from   dual;
--
-- output
/* -000000365 11:25:04.000000000 */
--
/* Get the number of hours between two dates */
/* As the difference between dates is the number of days, all you need to do is 
/* multiply the result by how many of the unit you want in there are in a day:
/* 
Days to hours => 24
Days to minutes => 24 hours * 60 minutes => 1,440
Days to seconds => 1,440 minutes * 60 seconds => 86,400
*/
with rws as (
  select
    to_date ( '19-APR-2023 12:00:00', 'DD-MON-YYYY HH24:MI:SS' )
      - date'2023-04-17' day_diff
  from   dual
)
  select round ( day_diff * 24 ) hours_diff,
         round ( day_diff * 1440 ) minutes_diff,
         round ( day_diff * 86400 ) seconds_diff 
  from   rws;
--
--output
/*
HOURS_DIFF, MINUTES_DIFF,   SECONDS_DIFF
60,         3600,           216000
*/