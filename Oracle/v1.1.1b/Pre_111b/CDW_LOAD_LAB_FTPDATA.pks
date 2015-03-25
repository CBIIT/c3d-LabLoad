CREATE OR REPLACE PACKAGE OPS$BDL.cdw_load_lab_FTPdata AS

   -- Global Package Variables.

   X_Loaded         Number := 0;     -- Count of records Loaded
   X_Skipped        Number := 0;     -- Count of records Skipped

   Function Get_One_Tab_Field(IN_String in out Varchar2) Return Varchar2;

   Function Convert_Sydate_OCDate(IN_String in Varchar2) Return Varchar2;

   Procedure Parse_Check_Insert_Rec(Txt_String in Varchar2);

   Procedure Pre_Load_Setup;

   Procedure Load_Flat_File;

END cdw_load_lab_FTPdata;
/

