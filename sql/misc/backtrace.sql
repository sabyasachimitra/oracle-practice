/*
    Backtrace shows a walk through the call stack from 
    the line where the exception was raised, to the last 
    call before the exception was trapped.
*/
--
/*
    Backtracing in Pre-12c Oracle databases: DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
*/
--
CREATE OR REPLACE PROCEDURE display_error_backtrace AS
BEGIN
    DBMS_OUTPUT.put_line('***** Backtrace Start *****');
    DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    DBMS_OUTPUT.put_line('***** Backtrace End *****');
END;
/
--
/* 
    Test Package to show a nested call: DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
*/
--
CREATE OR REPLACE PACKAGE display_error_backtrace_test_pkg AS
    PROCEDURE proc1;
    PROCEDURE proc2;
    PROCEDURE proc3;
END;
/
--
CREATE OR REPLACE PACKAGE BODY display_error_backtrace_test_pkg AS
    PROCEDURE proc1 AS
        BEGIN
            proc2;
        EXCEPTION
            WHEN OTHERS THEN
                display_error_backtrace;            
        END;
         
    PROCEDURE proc2 AS
        BEGIN
            proc3;
        END;
         
    PROCEDURE proc3 AS
        BEGIN
            RAISE NO_DATA_FOUND;
        END;
END;
/
--
/*
    Execute the package with anonymous block: DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
*/
BEGIN 
    display_error_stack_test_pkg.proc1;
END;
/
--
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
    Backtracing in Oracle 12c database onwards: UTL_CALL_STACK
*/
--
CREATE OR REPLACE PROCEDURE show_error_backtrace AS
    l_depth PLS_INTEGER;
BEGIN 
    l_depth := UTL_CALL_STACK.backtrace_depth;
    DBMS_OUTPUT.put_line('***** Backtrace Start *****');
    DBMS_OUTPUT.put_line('Depth     BTrace     BTrace');
    DBMS_OUTPUT.put_line('.         Line       Unit');
    DBMS_OUTPUT.put_line('--------- --------- --------------------');

    FOR i IN 1 .. l_depth LOOP
        DBMS_OUTPUT.PUT_LINE (
            RPAD(i,10) ||
            RPAD(TO_CHAR(UTL_CALL_STACK.backtrace_line(i),'99'),10) ||
            UTL_CALL_STACK.backtrace_unit(i)
        );
    END LOOP;
    DBMS_OUTPUT.put_line('***** Backtrace End *****');
END;
/
--
/* 
    Test Package to show a nested call: UTL_CALL_STACK
*/
--
CREATE OR REPLACE PACKAGE show_error_backtrace_test_pkg AS
    PROCEDURE proc1;
    PROCEDURE proc2;
    PROCEDURE proc3;
END;
/
--
CREATE OR REPLACE PACKAGE BODY show_error_backtrace_test_pkg AS
    PROCEDURE proc1 AS
        BEGIN
            proc2;
        EXCEPTION
            WHEN OTHERS THEN
                display_error_backtrace;            
        END;
         
    PROCEDURE proc2 AS
        BEGIN
            proc3;
        END;
         
    PROCEDURE proc3 AS
        BEGIN
            RAISE NO_DATA_FOUND;
        END;
END;
/
--
/*
    Execute the package with anonymous block: UTL_CALL_STACK
*/
BEGIN 
    show_error_backtrace_test_pkg.proc1;
END;
/
--
/*
***** Backtrace Start *****
ORA-06512: at "ORADEV21.SHOW_ERROR_BACKTRACE_TEST_PKG", line 17
ORA-06512: at "ORADEV21.SHOW_ERROR_BACKTRACE_TEST_PKG", line 12
ORA-06512: at "ORADEV21.SHOW_ERROR_BACKTRACE_TEST_PKG", line 4

***** Backtrace End *****
*/