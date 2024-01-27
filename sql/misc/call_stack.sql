/*
    The call stack allows you to identify exactly where you are in the 
    currently running code, which includes information about nesting of subprogram calls
*/
--
/*
    Call stack before Oracle 12c: DBMS_UTILITY.FORMAT_CALL_STACK
*/
--
CREATE OR REPLACE PROCEDURE display_call_stack AS
BEGIN
    DBMS_OUTPUT.PUT_LINE ('**** Call Stack Start ****');
    DBMS_OUTPUT.PUT_LINE (DBMS_UTILITY.FORMAT_CALL_STACK);
    DBMS_OUTPUT.PUT_LINE ('**** Call Stack End ****');
END;
/
--
/* 
    Test Package to show a nested call
*/
--
CREATE OR REPLACE PACKAGE display_call_stack_test_pkg AS
    PROCEDURE proc1;
    PROCEDURE proc2;
    PROCEDURE proc3;
END;
/
--
CREATE OR REPLACE PACKAGE BODY display_call_stack_test_pkg AS
    PROCEDURE proc1 AS
        BEGIN
            proc2;
        END;
    PROCEDURE proc2 AS
        BEGIN
            proc3;
        END;
    PROCEDURE proc3 AS
        BEGIN
            display_call_stack;
        END;
END;
/
--
set serveroutput on
--
/*
    Execute the package with anonymous block
*/
BEGIN 
    display_call_stack_test_pkg.proc1;
END;
/
/*
**** Call Stack Start ****
----- PL/SQL Call Stack -----
  object      line  object
  handle    number  name
0x75a7c8d0         4  procedure ORADEV21.DISPLAY_CALL_STACK
0x63aff878        12  package body ORADEV21.DISPLAY_CALL_STACK_TEST_PKG.PROC3
0x63aff878         8  package body ORADEV21.DISPLAY_CALL_STACK_TEST_PKG.PROC2
0x63aff878         4  package body ORADEV21.DISPLAY_CALL_STACK_TEST_PKG.PROC1
0x70b46b98         2  anonymous block

**** Call Stack End ****
*/
--
/*
    Call stack Oracle 12c onwards: UTL_CALL_STACK package
    UTL_CALL_STACK provides APIs to display the contents 
    of the call stack in more readable format.    
*/
--
CREATE OR REPLACE PROCEDURE show_call_stack AS
    l_depth PLS_INTEGER;
BEGIN
    /*  dynamic_depth function: returns the number of subprograms in the 
        call stack starting from the current position in the call stack to the initital call.
    */
    l_depth := UTL_CALL_STACK.dynamic_depth;
    DBMS_OUTPUT.PUT_LINE ('***** Call Stack Start *****');
    DBMS_OUTPUT.PUT_LINE ('Depth     Lexical   Line      Owner     Edition   Name');
    DBMS_OUTPUT.PUT_LINE ('.         Depth     Number');
    DBMS_OUTPUT.PUT_LINE ('--------- --------- --------- --------- --------- --------------------');
    
    FOR i in 1 .. l_depth LOOP
        DBMS_OUTPUT.PUT_LINE (
            RPAD (i, 10) || 
            RPAD (UTL_CALL_STACK.lexical_depth(i),10) ||
            RPAD (TO_CHAR(UTL_CALL_STACK.unit_line(i),'99'),10) ||
            RPAD (NVL(UTL_CALL_STACK.owner(i), ' '),10) ||
            RPAD (NVL(UTL_CALL_STACK.owner(i), ' '),10) ||
            UTL_CALL_STACK.concatenate_subprogram(UTL_CALL_STACK.subprogram(i))
            );
    END LOOP;
    DBMS_OUTPUT.put_line('***** Call Stack End *****');
END;
/
--
/* 
    Test Package to show a nested call
*/
--
CREATE OR REPLACE PACKAGE show_call_stack_test_pkg AS
    PROCEDURE proc1;
    PROCEDURE proc2;
    PROCEDURE proc3;
END;
/
--
CREATE OR REPLACE PACKAGE BODY show_call_stack_test_pkg AS
    PROCEDURE proc1 AS
        BEGIN
            proc2;
        END;
    PROCEDURE proc2 AS
        BEGIN
            proc3;
        END;
    PROCEDURE proc3 AS
        BEGIN
            show_call_stack;
        END;
END;
/
--
 BEGIN 
    show_call_stack_test_pkg.proc1;
END;
/       
--
/*
***** Call Stack Start *****
Depth     Lexical   Line      Owner     Edition   Name
.         Depth     Number
--------- --------- --------- --------- --------- --------------------
1         0          14       ORADEV21  ORADEV21  SHOW_CALL_STACK
2         1          12       ORADEV21  ORADEV21  SHOW_CALL_STACK_TEST_PKG.PROC3
3         1           8       ORADEV21  ORADEV21  SHOW_CALL_STACK_TEST_PKG.PROC2
4         1           4       ORADEV21  ORADEV21  SHOW_CALL_STACK_TEST_PKG.PROC1
5         0           2                           __anonymous_block
***** Call Stack End *****
*/
--
/* 
    We can reverse the order of stack display
*/
--
CREATE OR REPLACE PROCEDURE show_call_stack AS
    l_depth PLS_INTEGER;
BEGIN
    /*  dynamic_depth function: returns the number of subprograms in the 
        call stack starting from the current position in the call stack to the initital call.
    */
    l_depth := UTL_CALL_STACK.dynamic_depth;
    DBMS_OUTPUT.PUT_LINE ('***** Call Stack Start *****');
    DBMS_OUTPUT.PUT_LINE ('Depth     Lexical   Line      Owner     Edition   Name');
    DBMS_OUTPUT.PUT_LINE ('.         Depth     Number');
    DBMS_OUTPUT.PUT_LINE ('--------- --------- --------- --------- --------- --------------------');
    
    FOR i in REVERSE 1 .. l_depth LOOP
        DBMS_OUTPUT.PUT_LINE (
            RPAD (i, 10) || 
            RPAD (UTL_CALL_STACK.lexical_depth(i),10) ||
            RPAD (TO_CHAR(UTL_CALL_STACK.unit_line(i),'99'),10) ||
            RPAD (NVL(UTL_CALL_STACK.owner(i), ' '),10) ||
            RPAD (NVL(UTL_CALL_STACK.owner(i), ' '),10) ||
            UTL_CALL_STACK.concatenate_subprogram(UTL_CALL_STACK.subprogram(i))
            );
    END LOOP;
    DBMS_OUTPUT.put_line('***** Call Stack End *****');
END;
/
--
 BEGIN 
    show_call_stack_test_pkg.proc1;
END;
/     
--
/*
***** Call Stack Start *****
Depth     Lexical   Line      Owner     Edition   Name
.         Depth     Number
--------- --------- --------- --------- --------- --------------------
5         0           2                           __anonymous_block
4         1           4       ORADEV21  ORADEV21  SHOW_CALL_STACK_TEST_PKG.PROC1
3         1           8       ORADEV21  ORADEV21  SHOW_CALL_STACK_TEST_PKG.PROC2
2         1          12       ORADEV21  ORADEV21  SHOW_CALL_STACK_TEST_PKG.PROC3
1         0          14       ORADEV21  ORADEV21  SHOW_CALL_STACK
***** Call Stack End *****
*/