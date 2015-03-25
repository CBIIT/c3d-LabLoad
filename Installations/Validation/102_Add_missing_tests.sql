PROMPT *This script will insert into the NCI_LABS table 3 the following
prompt *Blood Chemistry Lab Tests, GLOBULIN, GLUC_FASTING, and 5_NUCLEOTIDASE.
Prompt *These Lab Tests are used in testing item B.2
prompt *
ACCEPT patient_id PROMPT "Enter Patient ID: "
prompt *
ACCEPT patient_POS PROMPT "Enter Patient Position: "
prompt *
PROMPT *There are 8 days to choose from.  All are valid if using the 102 data sets
PROMPT *and will have a time of 10:05am
PROMPT *  1 = 1/14/2006       2 = 2/14/2006
PROMPT *  3 = 3/14/2006       4 = 4/14/2006
PROMPT *  5 = 9/14/2006       6 = 9/20/2006
PROMPT *  7 = 10/14/2006      8 = 10/20/2006
ACCEPT Date_Code PROMPT "Enter a Date Code (1-8): "

set verify off

INSERT INTO NCI_LABS 
   ( PATIENT_ID, OC_PATIENT_POS, SAMPLE_DATETIME, TEST_COMPONENT_ID, LABORATORY, RESULT, UNIT,
     NORMAL_VALUE, OC_STUDY, LOAD_FLAG ) VALUES 
   ('&&PATIENT_ID', '&&PATIENT_POS', 
    Decode('&&Date_Code', '1' ,'0114061005',
                          '2' ,'0214061005',
                          '3' ,'0314061005',
                          '4' ,'0414061005',
                          '5' ,'0914061005',
                          '6' ,'0920061005',
                          '7' ,'1014061005',
                          '8' ,'1020061005','0114061005'),
    '102001', 'CDW', '.1', 'Cells/microL', ' ', 'LAB_LOADER', 'N'); 

INSERT INTO NCI_LABS 
   ( PATIENT_ID, OC_PATIENT_POS, SAMPLE_DATETIME, TEST_COMPONENT_ID, LABORATORY, RESULT, UNIT,
     NORMAL_VALUE, OC_STUDY, LOAD_FLAG ) VALUES 
   ('&&PATIENT_ID', '&&PATIENT_POS', 
    Decode('&&Date_Code', '1' ,'0114061005',
                          '2' ,'0214061005',
                          '3' ,'0314061005',
                          '4' ,'0414061005',
                          '5' ,'0914061005',
                          '6' ,'0920061005',
                          '7' ,'1014061005',
                          '8' ,'1020061005','0114061005'),
    '102002', 'CDW', '.1', 'Cells/microL', ' ', 'LAB_LOADER', 'N'); 

INSERT INTO NCI_LABS 
   ( PATIENT_ID, OC_PATIENT_POS, SAMPLE_DATETIME, TEST_COMPONENT_ID, LABORATORY, RESULT, UNIT,
     NORMAL_VALUE, OC_STUDY, LOAD_FLAG ) VALUES 
   ('&&PATIENT_ID', '&&PATIENT_POS', 
    Decode('&&Date_Code', '1' ,'0114061005',
                          '2' ,'0214061005',
                          '3' ,'0314061005',
                          '4' ,'0414061005',
                          '5' ,'0914061005',
                          '6' ,'0920061005',
                          '7' ,'1014061005',
                          '8' ,'1020061005','0114061005'),
    '102003', 'CDW', '.1', 'Cells/microL', ' ', 'LAB_LOADER', 'N'); 

Undefine Date_Code
undefine PATIENT_ID
undefine PATIENT_POS
set verify on