CREATE OR REPLACE PROCEDURE show_recm (
    in_task_name IN VARCHAR2
) IS

    CURSOR curs IS
    SELECT DISTINCT
        action_id,
        command,
        attr1,
        attr2,
        attr3,
        attr4
    FROM
        user_advisor_actions
    WHERE
        task_name = in_task_name
    ORDER BY
        action_id;

    v_action  NUMBER;
    v_command VARCHAR2(32);
    v_attr1   VARCHAR2(4000);
    v_attr2   VARCHAR2(4000);
    v_attr3   VARCHAR2(4000);
    v_attr4   VARCHAR2(4000);
    v_attr5   VARCHAR2(4000);
BEGIN
    OPEN curs;
    dbms_output.put_line('=========================================');
    dbms_output.put_line('Task_name = ' || in_task_name);
    LOOP
        FETCH curs INTO
            v_action,
            v_command,
            v_attr1,
            v_attr2,
            v_attr3,
            v_attr4;
        EXIT WHEN curs%notfound;
        dbms_output.put_line('Action ID: ' || v_action);
        dbms_output.put_line('Command : ' || v_command);
        dbms_output.put_line('Attr1 (name) : '
                             || substr(v_attr1, 1, 30));
        dbms_output.put_line('Attr2 (tablespace): '
                             || substr(v_attr2, 1, 30));
        dbms_output.put_line('Attr3 : '
                             || substr(v_attr3, 1, 30));
        dbms_output.put_line('Attr4 : ' || v_attr4);
        dbms_output.put_line('Attr5 : ' || v_attr5);
        dbms_output.put_line('----------------------------------------');
    END LOOP;

    CLOSE curs;
    dbms_output.put_line('=========END RECOMMENDATIONS============');
END show_recm;
/
set serveroutput on size 99999
EXECUTE show_recm(:V_TASK_NAME);