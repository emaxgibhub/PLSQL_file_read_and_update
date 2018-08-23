/*
link to the task

https://sql-exercises.edu.pl/category/oracle-sql/zaawansowany-oracle/

*/
CREATE OR REPLACE PROCEDURE update_bonus_from_file (
    p_dir         IN VARCHAR2,
    p_file_name   IN VARCHAR2,
    p_delimiter   IN CHAR DEFAULT ';',
    p_log_file_name varchar2 DEFAULT 'import_log.txt'
) IS

    CURSOR cur IS SELECT
                     id_prac   id_prac,
                     premia    new_premia
                 FROM
                     t_pracownicy;

    SUBTYPE file_record IS cur%rowtype;
    temp_rec file_record ;
    TYPE file_records IS
        TABLE OF file_record INDEX BY BINARY_INTEGER;
    l_records   file_records;
    rec_idx BINARY_INTEGER :=0;
    SUBTYPE f_line IS VARCHAR2(1000);
    TYPE f_lines IS
        TABLE OF f_line INDEX BY BINARY_INTEGER;
    l_lines     f_lines;
    l_words     f_lines;
    
    in_file_not_exist EXCEPTION;
    
    l_log_file   utl_file.file_type;
    l_log_line f_line;


/******************LOGGING*****************************/
PROCEDURE log_message(p_message varchar2,
        p_log_file  utl_file.file_type DEFAULT l_log_file )
IS
begin

if utl_file.is_open(p_log_file) then 
utl_file.put_line(p_log_file,p_message); else 
dbms_output.put_line(p_message);
end if;
end ;

/**********CHECKING IF FILE EXISTS**************************/
FUNCTION fn_is_file_exist(
   p_dir         IN VARCHAR2,
        p_file_name   IN VARCHAR2
) RETURN boolean
IS 
l_fexists boolean;
l_file_length PLS_INTEGER;
   l_block_size PLS_INTEGER;
Begin
 UTL_FILE.fgetattr ( LOCATION         => p_file_name
                     , filename         =>  p_dir
                     , fexists          => l_fexists
                     , file_length      => l_file_length
                     , block_size       => l_block_size
                     );
                     
  IF l_fexists IS NULL AND l_file_length = 0 AND l_block_size = 0
   THEN
      RETURN FALSE;
   ELSE
      RETURN TRUE;
   END IF;
   
exception when others then
return false;
RAISE;
end;


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
                WHEN OTHERS THEN 
                 IF UTL_FILE.IS_OPEN(l_in_file ) THEN
                  UTL_FILE.FCLOSE (l_in_file );
                  END IF;
                RAISE;  
            END;
        END LOOP;

        utl_file.fclose(l_in_file);
        RETURN l_lines;
    END fn_file_to_lines;

/*******************FROM LINE TO ARRAY OF WORDS***********************/

    FUNCTION fn_line_to_words (
        p_line        f_line,
        p_words_nmb   BINARY_INTEGER,
        p_delimiter   CHAR DEFAULT ';'
    ) RETURN f_lines IS
        l_words     f_lines;
        l_buffer    f_line;
        l_del_idx   BINARY_INTEGER := 0;
    BEGIN
        l_buffer := p_line;
        FOR i IN 1..p_words_nmb LOOP
        -- dbms_output.put_line('l_buffer =' ||l_buffer);
            IF ( length(l_buffer) = 0 ) THEN
                l_words(i) := '';
                CONTINUE;
            END IF;

            l_del_idx := instr(l_buffer,p_delimiter,1);
            IF ( l_del_idx > 0 ) THEN
                l_words(i) := substr(l_buffer,1,l_del_idx - 1);
                IF ( l_del_idx + 1 < length(l_buffer) ) THEN
                    l_buffer := substr(l_buffer,l_del_idx + 1);
                ELSE
                    l_buffer := '';
                END IF;

            ELSE
                l_words(i) := l_buffer;
            END IF;

        END LOOP;

        RETURN l_words;
    END fn_line_to_words;

    FUNCTION fn_to_number (
        p_word f_line
    ) RETURN NUMBER IS
    BEGIN
        RETURN to_number(trim(p_word));
       
    EXCEPTION
        WHEN value_error THEN
            RETURN NULL;
    END;

BEGIN

   /*checking if file exists*/
    if  fn_is_file_exist(p_dir,p_file_name)=FALSE then 
    RAISE in_file_not_exist;
    end if ;
  
    l_lines := fn_file_to_lines(p_dir,p_file_name);
    rec_idx:=1; 
     
    /***open file for logging***************************/ 
    begin
    l_log_file := utl_file.fopen(p_dir,p_log_file_name,'A');
    EXCEPTION when others then
    dbms_output.put_line('Error occurred while creating log file. Logging into DBMS_OUTPUT....');   
    end; 
    
    if (utl_file.is_open(l_log_file)=false)
          then
          dbms_output.put_line('Error occurred while creating log file. Logging into DBMS_OUTPUT....');    
         end if;
         
     log_message('Import attemp started form file '||p_file_name||' on  '||to_char(SYSDATE,'yyyy-mm-dd hh24:mi:ss'));
     
    FOR i IN 1..l_lines.count LOOP
        l_words := fn_line_to_words(l_lines(i),2);
     
        temp_rec.id_prac :=  fn_to_number(l_words(1) );
        temp_rec.new_premia := fn_to_number(l_words(2) );
        
        if (temp_rec.id_prac Is NULL OR temp_rec.new_premia IS NULL) then
          l_log_line:='Line #' || i|| ' was ignored due to invalid type of data: '||l_lines(i)|| '.
          Check line and try again...';
          
          log_message(l_log_line );
          
        else 
        l_records (rec_idx):= temp_rec;
        l_log_line:='Line #' || rec_idx|| ' was processed: '||l_lines(i);
       
        log_message(l_log_line );
       
        rec_idx:=rec_idx+1;
        end if;
    END LOOP;
    
  
  
  FORALL i IN 1 .. l_records.COUNT
      UPDATE t_pracownicy SET premia = l_records (i).new_premia
       WHERE id_prac = l_records (i).id_prac;
       
        l_log_line:=SQL%ROWCOUNT || ' lines were updated from file ';
        
       log_message(l_log_line );
    commit;   
 
   utl_file.fclose(l_log_file)   ;
    
EXCEPTION

    WHEN utl_file.invalid_operation THEN log_message(SQLERRM); --log_message( 'The file could not be opened or operated on as requested');
     if utl_file.is_open(l_log_file) then
        utl_file.fclose(l_log_file) ;end if;
    WHEN in_file_not_exist then log_message('File for processing doesnt exist. Check the file path...');
     if utl_file.is_open(l_log_file) then
        utl_file.fclose(l_log_file) ;end if;
    WHEN OTHERS THEN
        ROLLBACK;
        l_log_line:='Error ' ||SQLERRM||' .File wasnt processed. Try again.... ';
        log_message(l_log_line);
        if utl_file.is_open(l_log_file) then
        utl_file.fclose(l_log_file) ;end if;
      
END update_bonus_from_file;