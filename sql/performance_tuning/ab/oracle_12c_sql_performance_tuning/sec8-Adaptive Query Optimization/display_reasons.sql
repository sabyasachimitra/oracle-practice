SET SERVEROUTPUT ON
DECLARE
	c NUMBER;
	col_cnt NUMBER(10);
	col_rec DBMS_SQL.DESC_TAB;
	col_value VARCHAR2(4000);
	ret_val NUMBER;
BEGIN
	c := DBMS_SQL.OPEN_CURSOR;
	DBMS_SQL.PARSE(c, 'SELECT substr(q.sql_text,1,30) sql_text, s.* FROM V$SQL_SHARED_CURSOR S, V$SQL q
					   WHERE s.sql_id = q.sql_id AND s.child_number = q.child_number AND q.sql_id = ''&v_sql_id''', DBMS_SQL.NATIVE);
	DBMS_SQL.DESCRIBE_COLUMNS(c, col_cnt, col_rec);
	FOR idx IN 1 .. col_cnt 
		LOOP
			DBMS_SQL.DEFINE_COLUMN(c, idx, col_value, 4000);
		END LOOP;
	ret_val := DBMS_SQL.EXECUTE(c);
	WHILE(DBMS_SQL.FETCH_ROWS(c) > 0) 
		LOOP
			FOR idx in 1 .. col_cnt LOOP
				DBMS_SQL.COLUMN_VALUE(c, idx, col_value);
				IF col_rec(idx).col_name in ('SQL_ID', 'ADDRESS','CHILD_ADDRESS', 'CHILD_NUMBER', 'SQL_TEXT', 'REASON') THEN
					DBMS_OUTPUT.PUT_LINE(RPAD(col_rec(idx).col_name, 30) || ' = ' || col_value);
				ELSIF col_value = 'Y' THEN
					DBMS_OUTPUT.PUT_LINE(RPAD(col_rec(idx).col_name, 30) || ' = '|| col_value);
				END IF;
			END LOOP;
			DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
	END LOOP;
	DBMS_SQL.CLOSE_CURSOR(c);
END;
/
SET SERVEROUTPUT OFF