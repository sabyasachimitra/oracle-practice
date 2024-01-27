SET SERVEROUT ON
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
select * from tab_name;