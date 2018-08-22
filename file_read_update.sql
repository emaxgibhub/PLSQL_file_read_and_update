/*
link to the task

https://sql-exercises.edu.pl/category/oracle-sql/zaawansowany-oracle/

*/CREATE OR REPLACE PROCEDURE update_bonus_from_file (
    p_dir         IN VARCHAR2,
    p_file_name   IN VARCHAR2,
    p_delimiter   IN CHAR DEFAULT ';'
) IS

   
    l_idx        BINARY_INTEGER := 0;
   
    TYPE file_record IS RECORD ( id_prac      t_pracownicy.id_prac%TYPE,
    new_premia   t_pracownicy.premia%TYPE );
    TYPE file_records IS
        TABLE OF file_record INDEX BY BINARY_INTEGER;
    l_records    file_records;--:= file_records() ;


/****used in only first part of program*****/
 l_in_file    utl_file.file_type;
 l_buffer     VARCHAR2(1000);
  TYPE tmp_str_tbl IS
        TABLE OF VARCHAR2(1000) INDEX BY BINARY_INTEGER;
    l_tmp_str    tmp_str_tbl;
    l_del_idx    BINARY_INTEGER := 0;
   

BEGIN
l_in_file := utl_file.fopen(p_dir,p_file_name,'r');
    LOOP
        BEGIN
            utl_file.get_line(l_in_file,l_buffer);
            
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

            BEGIN
                l_records(l_idx).id_prac := l_tmp_str(1);
                l_records(l_idx).new_premia := l_tmp_str(2);
            EXCEPTION
                WHEN value_error THEN
                    dbms_output.put_line('Error type convertion. Line '
                                           || l_idx
                                           || 'was not processed !');
                WHEN OTHERS THEN
                    RAISE;
            END;
            
/****************************************************************/
            dbms_output.put_line(l_buffer
                                   || '  - '
                                   || l_records(l_idx).id_prac
                                   || l_records(l_idx).new_premia);

            l_idx := l_idx + 1;
        EXCEPTION
            WHEN no_data_found THEN
                EXIT;
        END;
    END LOOP;
    utl_file.fclose ( l_in_file ); 
    
    /*all file lines are processed; now updating the table   */ 
    
  
    
    end update_bonus_from_file;