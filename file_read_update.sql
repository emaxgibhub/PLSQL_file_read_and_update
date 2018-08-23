/*
link to the task

https://sql-exercises.edu.pl/category/oracle-sql/zaawansowany-oracle/

*/
CREATE OR REPLACE PROCEDURE update_bonus_from_file (
    p_dir         IN VARCHAR2,
    p_file_name   IN VARCHAR2,
    p_delimiter   IN CHAR DEFAULT ';'
) IS

    CURSOR cur IS
    SELECT id_prac id_prac
    , premia new_premia
    FROM t_pracownicy;
    
   -- TYPE file_record cur%ROWTYPE;

      /* TYPE file_record IS RECORD ( id_prac      t_pracownicy.id_prac%TYPE,
    new_premia   t_pracownicy.premia%TYPE );
 TYPE file_records IS
        TABLE OF file_record INDEX BY BINARY_INTEGER;
    l_records    file_records;*/
   -- fr           file_record;
   
   SUBTYPE file_record IS cur%ROWTYPE;
   
   fr file_record;
    
    
   SUBTYPE file_line IS VARCHAR2(1000);
    TYPE file_lines IS
        TABLE OF file_line INDEX BY BINARY_INTEGER;
    l_lines      file_lines;

/*********FROM FILE TO COLLECTION OF LINES **********************/

    FUNCTION fn_file_to_lines (
        p_dir         IN VARCHAR2,
        p_file_name   IN VARCHAR2
    ) RETURN file_lines IS
        l_lines     file_lines;
        l_in_file   utl_file.file_type;
    BEGIN
        l_in_file := utl_file.fopen(p_dir,p_file_name,'r');
        LOOP
            BEGIN
                utl_file.get_line(l_in_file,l_lines(l_lines.count + 1) );
            EXCEPTION
                WHEN no_data_found THEN
                    EXIT;
            END;
        END LOOP;

        utl_file.fclose(l_in_file);
        RETURN l_lines;
    END fn_file_to_lines;


/******************FROM LINE TO RECORD*******************************/


    FUNCTION fn_line_to_record (
        p_line        file_line,
        p_line_idx    BINARY_INTEGER,
        p_delimiter   CHAR DEFAULT ';'
    ) RETURN file_record IS

        fr          file_record;
        l_buffer    file_line;
        l_del_idx   BINARY_INTEGER := 0;
        TYPE tmp_str_tbl IS
            TABLE OF VARCHAR2(1000) INDEX BY BINARY_INTEGER;
        l_tmp_str   tmp_str_tbl;
    BEGIN
        l_buffer := p_line;
    --       /*finding the two first words separated by ;*/
        FOR i IN 1..2 LOOP
            l_del_idx := instr(l_buffer,p_delimiter,1);
            IF ( l_del_idx > 0 ) THEN
                l_tmp_str(i) := substr(l_buffer,1,l_del_idx - 1);
                IF ( l_del_idx + 1 < length(l_buffer) ) THEN
                    l_buffer := substr(l_buffer,l_del_idx + 1);
                END IF;

            ELSE
                l_tmp_str(i) := l_buffer;
            END IF;

        END LOOP;
     /*type convertion -- need to make it a subprogram*/

        fr.id_prac := l_tmp_str(1);
        fr.new_premia := l_tmp_str(2);
        RETURN fr;
    EXCEPTION
        WHEN value_error THEN
            dbms_output.put_line('Error type convertion. Line '
                                   || p_line_idx
                                   || 'was not processed !');
              --  WHEN OTHERS THEN
                --    RAISE;
        
  
    --EXCEPTION
    END fn_line_to_record;

BEGIN
    l_lines := fn_file_to_lines(p_dir,p_file_name);
    
    
    FOR i IN 1..l_lines.count LOOP
        fr := fn_line_to_record(l_lines(i),i);
        
        /* now updating the table   */
        UPDATE t_pracownicy p
        SET
            premia = fr.new_premia
        WHERE
            p.id_prac = fr.id_prac;
            
            dbms_output.put_line( fr.id_prac || ' '|| fr.new_premia);
   END LOOP;
    
    commit;

/***
  FORALL idx IN 1 .. l_list.COUNT
      UPDATE employees SET salary = l_list (idx).salary
       WHERE employee_id = l_list (idx).employee_id;
/***

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        dbms_output.put_line('File wasnt processed. Try again.... ');
END update_bonus_from_file;