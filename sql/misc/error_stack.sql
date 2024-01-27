/*
    The error stack allows you to display chains of errors, 
    making it easier to determine the real cause of the issue.
*/
--
/*
    Error stack in Pre-12c Oracle databases: DBMS_UTILITY.FORMAT_ERROR_STACK
*/
--
CREATE OR REPLACE PROCEDURE display_error_stack AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('***** Error Stack Start *****');
    DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_STACK);
    DBMS_OUTPUT.PUT_LINE('***** Error Stack End *****');
END;
/
--
/* 
    Test Package to show a nested call: DBMS_UTILITY.FORMAT_ERROR_STACK
*/
--
CREATE OR REPLACE PACKAGE display_error_stack_test_pkg AS
    PROCEDURE proc1;
    PROCEDURE proc2;
    PROCEDURE proc3;
END;
/
--
CREATE OR REPLACE PACKAGE BODY display_error_stack_test_pkg AS
    PROCEDURE proc1 AS
        BEGIN
            proc2;
        EXCEPTION
            WHEN OTHERS THEN
                display_error_stack;            
        END;
         
    PROCEDURE proc2 AS
        BEGIN
            proc3;
        EXCEPTION
            WHEN OTHERS THEN
            RAISE DUP_VAL_ON_INDEX;
        END;
         
    PROCEDURE proc3 AS
        BEGIN
            RAISE NO_DATA_FOUND;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE TOO_MANY_ROWS;
        END;
END;
/
--
/*
    Execute the package with anonymous block: DBMS_UTILITY.FORMAT_ERROR_STACK
*/
BEGIN 
    display_error_stack_test_pkg.proc1;
END;
/
--
/*
    The error stack is a stack data structure which is LIFO or FILO. 
    The first exception inserted in the stack is ORA-01403 (no data found)
    hence it was popped out first (see from the below). Then ORA-01422 which was next
    and finally the ORA-00001 error.
/*
***** Error Stack Start *****
ORA-00001: unique constraint (.) violated
ORA-06512: at "ORADEV21.DISPLAY_ERROR_STACK_TEST_PKG", line 15
ORA-01422: exact fetch returns more than requested number of rows
ORA-06512: at "ORADEV21.DISPLAY_ERROR_STACK_TEST_PKG", line 23
ORA-01403: no data found
ORA-06512: at "ORADEV21.DISPLAY_ERROR_STACK_TEST_PKG", line 20
ORA-06512: at "ORADEV21.DISPLAY_ERROR_STACK_TEST_PKG", line 12

***** Error Stack End *****
*/
--
/*
    One problem with FORMAT_ERROR_STACK is it does not 
    let you control the display of the stack.
    Error stack after Oracle 12c onwards: UTL_CALL_STACK
*/
--
CREATE OR REPLACE PROCEDURE show_error_stack AS
    l_depth PLS_INTEGER;
BEGIN
    /* error_depth: number of errors in the error stack */
    l_depth := UTL_CALL_STACK.error_depth;
    DBMS_OUTPUT.put_line('***** Error Stack Start *****');

    DBMS_OUTPUT.put_line('Depth     Error     Error');
    DBMS_OUTPUT.put_line('.         Code      Message');
    DBMS_OUTPUT.put_line('--------- --------- --------------------');
    /* error_number: error number associated with the current line in the error stack */
    /* error_msg: error message associated with the current line in the error stack */
    FOR i IN 1 .. l_depth LOOP
        DBMS_OUTPUT.PUT_LINE (
            RPAD(i,10) || 
            RPAD ('ORA-' || LPAD(UTL_CALL_STACK.error_number(i),5,'0'),10) ||
            UTL_CALL_STACK.error_msg(i)
        );
    END LOOP;
    DBMS_OUTPUT.put_line('***** Error Stack End *****');
END;
/
--
/* 
    Test Package to show a nested call: UTL_CALL_STACK
*/
--
CREATE OR REPLACE PACKAGE show_error_stack_test_pkg AS
    PROCEDURE proc1;
    PROCEDURE proc2;
    PROCEDURE proc3;
END;
/
--
CREATE OR REPLACE PACKAGE BODY show_error_stack_test_pkg AS
    PROCEDURE proc1 AS
        BEGIN
            proc2;
        EXCEPTION
            WHEN OTHERS THEN
                show_error_stack;            
        END;
         
    PROCEDURE proc2 AS
        BEGIN
            proc3;
        EXCEPTION
            WHEN OTHERS THEN
            RAISE DUP_VAL_ON_INDEX;
        END;
         
    PROCEDURE proc3 AS
        BEGIN
            RAISE NO_DATA_FOUND;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE TOO_MANY_ROWS;
        END;
END;
/
--
/*
    Execute the package with anonymous block: UTL_CALL_STACK
*/
BEGIN 
    show_error_stack_test_pkg.proc1;
END;
/
--
/*
    Notice that not only the error stack contains the error number and message 
    but also the line number (generic ORA-6512) where the exception with the error 
    number has occured.
*/
--
/*
***** Error Stack Start *****
Depth     Error     Error
.         Code      Message
--------- --------- --------------------
1         ORA-00001 unique constraint (.) violated
2         ORA-06512 at "ORADEV21.SHOW_ERROR_STACK_TEST_PKG", line 15
3         ORA-01422 exact fetch returns more than requested number of rows
4         ORA-06512 at "ORADEV21.SHOW_ERROR_STACK_TEST_PKG", line 23
5         ORA-01403 no data found
6         ORA-06512 at "ORADEV21.SHOW_ERROR_STACK_TEST_PKG", line 20
7         ORA-06512 at "ORADEV21.SHOW_ERROR_STACK_TEST_PKG", line 12
***** Error Stack End *****
*/
--
