CREATE OR REPLACE DIRECTORY CSVDIR AS 'd:\oracle\csvfiles';
/

CREATE OR REPLACE PROCEDURE export_supplier_to_csv
IS
   v_file     UTL_FILE.file_type;
   v_string   VARCHAR2 (4000);

   CURSOR cursor_supplier
   IS
      SELECT 
         name, 
         contact_name,
         address, 
         contact_number_1,
         contact_number_2,
         email
     FROM supplier;
BEGIN
   v_file := UTL_FILE.fopen ('CSVDIR', 'w', 1000);

   -- if you do not want heading then remove below two lines
   v_string := 'name, contact_name, address, contact_number_1, contact_number_2, email';
   UTL_FILE.put_line (v_file, v_string);

   FOR cur IN cursor_supplier
   LOOP
      v_string :=
            cur.name
         || ','
         || cur.contact_name
         || ','
         || cur.address
         || ','
         || cur.contact_number_1
         || ','
         || cur.contact_number_2
         || ','
         || cur.email;

      UTL_FILE.put_line (v_file, v_string);

   END LOOP;
   UTL_FILE.fclose (v_file);

EXCEPTION
   WHEN OTHERS
   THEN
      IF UTL_FILE.is_open (v_file)
      THEN
         UTL_FILE.fclose (v_file);
      END IF;
END;

BEGIN
	export_supplier_to_csv;
END