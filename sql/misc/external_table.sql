select * from DBA_DIRECTORIES;
--
/* create a oracle directory - an underlying directory should be present in Linux */
create or replace directory ext_data as '/u02/ext_data';
--
drop table table_names;
--
/* create external table table_names */
create table table_names
(
    tab_name varchar2(40)
)
organization external (
    type oracle_loader
    default directory ext_data
    access parameters (
        records delimited by newline
        nologfile
        fields csv with embedded terminated by ',' optionally enclosed by '"'
        missing field values are null (
            tab_name
        )
    )
    location('xxx')
)
reject limit unlimited;
--
drop table f_names;
--
create table f_names
(
    f_name varchar2(10)
)
organization external (
    type oracle_loader
    default directory ext_data
    access parameters 
    (
        records delimited by newline
        MISSING FIELD VALUES ARE NULL
        (
            f_name char(10)
        )
    )
    location('files.dat')
)
reject limit unlimited;
--
select * from f_names;
--
/* get hr.csv data */
select * from table_names;
--
/* dynamically change the file name to sh.csv -- 19c onwards */
select * from table_names external modify (location('sh.csv'));
--
-- alternatively - this does not need any table to be created
select * from external (
    (line varchar2(40))
    type oracle_loader
    default directory ext_data
    access parameters (
        records delimited by newline
        nologfile nobadfile nodiscardfile
        fields(line char(20))
    )
    location('hr.csv')
    reject limit unlimited
);
--
/* Dynamically change the file name parameter */
drop table tab_name;
create table tab_name (t varchar2(40), file_name varchar2(10));
--
DECLARE
    filename varchar2(10) := 'hr.csv';
BEGIN
    insert into tab_name 
    select * from table_names external modify (location(filename));
END;
--output: this gives a error as variable cannot be used. It's a bug in oracle 19c.
/*
ERROR at line 55:
ORA-06550: line 5, column 65:
PL/SQL: ORA-00905: missing keyword
ORA-06550: line 4, column 5:
PL/SQL: SQL Statement ignored
*/
--
/* Solution: Dynamically change the file name parameter */
--
truncate table tab_name;
--
DECLARE
    filename varchar2(10) := 'hr.csv';
BEGIN
    execute immediate 'insert into tab_name 
    select * from table_names external modify (location(:b1))' using filename;
END;
--
select * from tab_name;
--
DECLARE
    filename varchar2(10) := 'sh.csv';
BEGIN
    execute immediate 'insert into tab_name 
    select * from table_names external modify (location(:b1))' using filename;
END;
--
select * from tab_name;
--
/* read file names from another external table and access them one by one */
--
select * from external (
    (line varchar2(10))
    type oracle_loader
    default directory ext_data
    access parameters (
        records delimited by newline
        nologfile nobadfile nodiscardfile
        fields(line char(10))
    )
    location('files.dat')
    reject limit unlimited
);
--
DECLARE
    type t_file_names is table of varchar2(10) INDEX BY PLS_INTEGER; 
    l_file_names t_file_names;
BEGIN
        select line BULK COLLECT INTO l_file_names
        from external (
        (line varchar2(10))
        type oracle_loader
        default directory ext_data
        access parameters (
            records delimited by newline
            nologfile nobadfile nodiscardfile
            fields(line char(10))
        )
            location('files.dat')
            reject limit unlimited
        );
    FOR indx in 1..l_file_names.count 
        LOOP
            DBMS_OUTPUT.PUT_LINE(l_file_names(indx));
    END LOOP;
END;
--
truncate table tab_name;
--

--
CREATE OR REPLACE PACKAGE pkg_dyna_ext_file_demo AS
    TYPE t_file_names IS TABLE OF varchar2(10) INDEX BY BINARY_INTEGER;
    PROCEDURE proc_dyna_ext_file_demo;
END;
--
CREATE OR REPLACE PACKAGE BODY pkg_dyna_ext_file_demo AS

    PROCEDURE proc_dyna_ext_file_demo IS
        l_file_names t_file_names;
    BEGIN

        SELECT line BULK COLLECT INTO l_file_names
        from external (
        (line varchar2(10))
        type oracle_loader
        default directory ext_data
        access parameters (
            records delimited by newline
            nologfile nobadfile nodiscardfile
            fields(line char(10))
        )
            location('files.dat')
            reject limit unlimited
        );
--        FOR cur_rec IN (SELECT * FROM TABLE (l_file_names))
--            LOOP
--                DBMS_OUTPUT.PUT_LINE(cur_rec.column_value);
--            END LOOP;
      NULL;
    END proc_dyna_ext_file_demo;
END pkg_dyna_ext_file_demo;
--
select * from tab_name;
--
CREATE OR REPLACE PACKAGE tkyte.test_api AS
  TYPE t_tab IS TABLE OF NUMBER
    INDEX BY BINARY_INTEGER;

  PROCEDURE test1;
END;
--
CREATE OR REPLACE PACKAGE BODY tkyte.test_api AS

  PROCEDURE test1 IS
  l_tab1 t_tab;
    BEGIN
        SELECT EMPLOYEE_ID
        BULK COLLECT INTO l_tab1
        FROM   HR.EMPLOYEES
        WHERE  DEPARTMENT_ID = 100;

        DBMS_OUTPUT.put_line('Loop Through Collection');
        FOR cur_rec IN (SELECT *
                        FROM   TABLE(l_tab1))
        LOOP
        DBMS_OUTPUT.put_line(cur_rec.column_value);
        END LOOP;
    END;
END;
--
SET SERVEROUT ON
TRUNCATE TABLE tab_name;
DECLARE
    filename varchar2(20) := 'XXX.csv';
BEGIN
    FOR cur_rec IN (
        SELECT f_line
            FROM 
        EXTERNAL (
            (
                f_line VARCHAR2(20)
            )
            TYPE oracle_loader
            DEFAULT DIRECTORY ext_data
            ACCESS PARAMETERS 
            (
                RECORDS DELIMITED BY NEWLINE
                BADFILE ext_data
                DISCARDFILE ext_data
                LOGFILE ext_data
                FIELDS
                MISSING FIELD VALUES ARE NULL
                (
                    f_line char(20)		
                )
        )
        LOCATION ('files.dat')
        REJECT LIMIT UNLIMITED
        )
    )
    LOOP
        DBMS_OUTPUT.PUT_LINE(cur_rec.f_line);
        filename := cur_rec.f_line;
        EXECUTE IMMEDIATE 'insert into tab_name (t, file_name)
        select tab_name, :b1 from table_names external modify (location(:b1))' USING filename, filename;
    END LOOP;
END; 
--
truncate table tab_name;
desc tab_name;
select * from tab_name;