CREATE OR REPLACE DIRECTORY CSV_INPUT AS '/home/emax/Public/CSV_INPUT';
/
grant read, write ON DIRECTORY CSV_INPUT to emax;
/

declare
BEGIN
update_bonus_from_file(
p_dir=>'CSV_INPUT',
p_file_name=>'premia.txt'
);
end;