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
    
   SUBTYPE file_record IS cur%ROWTYPE;
   
   TYPE file_records IS
        TABLE OF file_record INDEX BY BINARY_INTEGER;
    l_records    file_records;
   

    
   SUBTYPE f_line IS VARCHAR2(1000);
   
 
    TYPE f_lines  IS
        TABLE OF f_line INDEX BY BINARY_INTEGER;
    l_lines      f_lines;
    l_words f_lines;

/*********FROM FILE TO COLLECTION OF LINES **********************/

    FUNCTION fn_file_to_lines (
        p_dir         IN VARCHAR2,
        p_file_name   IN VARCHAR2
    ) RETURN f_lines IS
        l_lines     f_lines;
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


/*******************FROM LINE TO ARRAY OF WORDS***********************/
 FUNCTION fn_line_to_words(
        p_line        f_line,
        p_words_nmb    BINARY_INTEGER,
        p_delimiter   CHAR DEFAULT ';'
    ) RETURN f_lines IS

        l_words f_lines;
        l_buffer    f_line;
        l_del_idx   BINARY_INTEGER := 0;
     
    BEGIN
        l_buffer := p_line;
   
        FOR i IN 1..p_words_nmb 
         LOOP
          if (length(l_buffer)=0) THEN 
          l_words(i):=''; 
          continue;
          end if;
          
          l_del_idx := instr(l_buffer,p_delimiter,1);
            IF ( l_del_idx > 0 ) THEN
                l_words(i) := substr(l_buffer,1,l_del_idx - 1);
                IF ( l_del_idx + 1 < length(l_buffer) ) THEN
                    l_buffer := substr(l_buffer,l_del_idx + 1);
                END IF;

            ELSE
               l_words(i) := l_buffer;
            END IF;

        END LOOP;
   
        RETURN  l_words;
   
    END fn_line_to_words;




BEGIN
    l_lines := fn_file_to_lines(p_dir,p_file_name);
    
    
    FOR i IN 1..l_lines.count LOOP
    l_words :=fn_line_to_words (l_lines(i),2);

    
    l_records(i).id_prac:=l_words(1);
    l_records(i).new_premia:=l_words(2);
 
   dbms_output.put_line(  l_records(i).id_prac || ' '||  l_records(i).new_premia);
   END LOOP;
    
  
  FORALL i IN 1 .. l_records.COUNT
      UPDATE t_pracownicy SET premia = l_records (i).new_premia
       WHERE id_prac = l_records (i).id_prac;
       
     commit;   


EXCEPTION
/*
  EXCEPTION
        WHEN value_error THEN
            dbms_output.put_line('Error type convertion. Line '
                                   || p_line_idx
                                   || 'was not processed !');
*/
    WHEN OTHERS THEN
        ROLLBACK;
        dbms_output.put_line('File wasnt processed. Try again.... ');
END update_bonus_from_file;