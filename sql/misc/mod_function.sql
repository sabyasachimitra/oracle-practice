/* 
    Modulus function in SQL
*/            
--
/* 
    How it works?
*/
select mod(5,1) from dual;
--
-- 5 divided by 1 equals 5, with a remainder of 0
/*
   MOD(5,1)
___________
          0
*/
--
/*
    The Modulo Operation Expressed As a Formula:
    a - (n * floor(a/n))
    where a is the dividend and n is divisor. 
    Floor function eturns the largest integer equal to or less than n.
*/
select 100 - (7 * floor(100/7)) modulus_formula from dual;
--
/*
   MODULUS_FORMULA
__________________
                 2
*/
--
/* 
    It's same as Modulus operator.
*/
select mod(100,7) "Modulus" from dual;    
--
/*
   Modulus
__________
         2
*/
--
/* 
    Modulus operator Use Case-1: Even / Odd and Alternating. 
    
    Example: x modulo 2 always return 0 or 2 -  Even numbers, because they are evenly  
    divisible by 2, always return 0, while odd numbers always return the remainder of 1.
*/             
--
--
select level "Number", 
case mod(level,2)
    when 0 
            then 'Even'
    when 1 
            then 'Odd'
end as "Even or Odd?" 
from dual connect by level <11;
--
/*
 Number Even or Odd?
_________ _______________
        1 Odd
        2 Even
        3 Odd
        4 Even
        5 Odd
        6 Even
        7 Odd
        8 Even
        9 Odd
       10 Even
*/        
--
/*
    Modulus operator Use Case-2: Restrict Number to Range.
    When you're using the modulus operator for even/odd alternation, you're actually taking advantage 
    of one of its more helpful properties.
     
    Here is the property: Here's the property: the range of x % n is between 0 and n - 1. In other words,
    the modulo operation will not return more than the divisor.
    
*/
--
select mod(level,5) from dual connect by level <= 10;
--
/* 
--
    The remainder is never greater than 5.
    A circular array is just an array used 
    in a circular way: when you get to the 
    end go back to the beginning. 
--
   MOD(LEVEL,5)
_______________
              1
              2
              3
              4
              0
              1
              2
              3
              4
              0
*/              

