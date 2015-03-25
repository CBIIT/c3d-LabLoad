CREATE OR REPLACE PACKAGE automate_bdl
AS
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/*     Author: Original Unknown                                                      */
/*       Date: Original Unknown                                                      */
/*Description: Creates data file of labs for batch loading.                          */
/*             (Original Description Missing)                                        */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/*  Modification History                                                             */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
/* Author: Patrick Conrad                                                            */
/*   Date: 07/07/03                                                                  */
/*    Mod: Made formatting changes to make file more human readable.                 */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
/* Author: Patrick Conrad                                                            */
/*   Date: 07/07/03                                                                  */
/*    Mod: Found that the output file from the batch load was complaining about the  */
/*         reloadable file name:                                                     */
/*         "Cannot open reloadable file -                                            */
/*              /export/home/opapps/bdlLOAD_DLM_LABS_02_C_0241_r_FILE_0.dat.         */
/*                                     ^                                             */
/*         Found that the directory name passed to submit_psub_bdl from this routine */
/*         is misisng a '/'.  Was added.                                             */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
/* Author: Patrick Conrad                                                            */
/*   Date: 07/07/03                                                                  */
/*    Mod: Under Oracle 9.2, the UTL_FILE package changed in that there are now      */
/*         DIRECTORY objects.  A new directory object was created LAB_DIR that is a  */
/*         definition for the '/tmp' directory on the unix host.  The object is then */
/*         used by the UTL_FILE.FOPEN procedure.                                     */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
PROCEDURE create_dat_file;
PROCEDURE run_bdl (ip_file IN char);
PROCEDURE create_os_file (ip_datafile IN char);
PROCEDURE submit_psub_bdl (ip_file_id IN number, ip_directory_path IN char);
END automate_bdl;
/


CREATE OR REPLACE PACKAGE BODY automate_bdl
AS
   PROCEDURE create_dat_file
   IS
      vfile_type     UTL_FILE.FILE_TYPE;
      ofile_name  varchar2(30);
      odatarec    varchar2(800);
      oip_file    varchar2(80);

      CURSOR c1 is
         select INVESTIGATOR ||'|'||
           NULL ||'|'||  -- prc 10/21/04 Testing (NULL was SITE)
                PATIENT ||'|'||
           DOCUMENT_NO ||'|'||
           PLANNED_EVENT ||'|'||
           SUBEVENT_NO ||'|'||
           DCI_DATE ||'|'||
           DCI_TIME ||'|'||
           DCI_NAME ||'|'||
           DCM_NAME ||'|'||
           DCM_SUBSET ||'|'||
           DCM_QUESGRP ||'|'||
           DCM_QUES ||'|'||
           DCM_OCCUR ||'|'||
           REPEAT_SN ||'|'||
           VALUETEXT ||'|'||
           DATA_COMMENT ||'|'||
           QUALIFYING_VALUE ||'|'||
           STUDY             data_record
           from bdl_temp_files
          order by study, id, patient, subevent_no, dci_date, dci_time; -- prc 10/20/04 added subevent_no

      /*  -- prc 10/21/04 Testing (NULL was SITE) VV
      CURSOR c2 is
         select INVESTIGATOR ||'|'||
           NULL ||'|'||  -- prc 10/21/04 Testing (NULL was SITE)
                PATIENT ||'|'||
           DOCUMENT_NO ||'|'||
           PLANNED_EVENT ||'|'||
           SUBEVENT_NO ||'|'||
           DCI_DATE ||'|'||
           DCI_TIME ||'|'||
           DCI_NAME ||'|'||
           DCM_NAME ||'|'||
           DCM_SUBSET ||'|'||
           DCM_QUESGRP ||'|'||
           DCM_QUES ||'|'||
           DCM_OCCUR ||'|'||
           REPEAT_SN ||'|'||
           VALUETEXT ||'|'||
           DATA_COMMENT ||'|'||
           QUALIFYING_VALUE ||'|'||
           STUDY             data_record
           from bdl_temp_files
           where SITE = 'U'
          order by study, id, patient, subevent_no, dci_date, dci_time; -- prc 10/20/04 added subevent_no
       -- prc 10/21/04 Testing (NULL was SITE) ^^*/

      c1_rec c1%ROWTYPE;
      /*c2_rec c2%ROWTYPE;   -- prc 10/21/04 Testing (NULL was SITE)*/

   begin

      If Log_Util.Log$LogName is null Then
         Log_Util.LogSetName('AUTOBDL_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD');
      End If;
      Log_Util.LogMessage('AUTOCDF - automate_bdl.create_dat_file Started');


      select 'lab_'|| to_char(sysdate,'mmdd_hh24miss') ||'.dat'
        into ofile_name
        from dual;

      Log_Util.LogMessage('AUTOCDF - Creating and Opening OS Lab File "'||ofile_name||'".');

      vfile_type := UTL_FILE.FOPEN ('LAB_DIR',ofile_name,'a'); -- prc 03/05/2004 9.2 needs it this way

      if UTL_FILE.IS_OPEN (vfile_type) then
         dbms_output.put_line('OS File is open.');
         Log_Util.LogMessage('AUTOCDF - OS File is open.');

     else
         dbms_output.put_line('OS File is not open.');
         Log_Util.LogMessage('AUTOCDF - OS File is NOT open.');

     end if;

      Log_Util.LogMessage('AUTOCDF - opening cursor file writing loop.');
      OPEN c1;
      LOOP
         FETCH c1 INTO c1_rec;
         EXIT WHEN c1%NOTFOUND;

         utl_file.put_line(vfile_type,c1_rec.data_record);
      END LOOP;
      Log_Util.LogMessage('AUTOCDF - finished cursor file writing loop.');

      utl_file.fclose(vfile_type);
      Log_Util.LogMessage('AUTOCDF - closing file.');

      oip_file := '/tmp/' || ofile_name;
      Log_Util.LogMessage('AUTOCDF - about to call run_bld with file "'||oip_file||'".');

      automate_bdl.run_bdl(oip_file);

      Log_Util.LogMessage('AUTOCDF - completed run_bld.');

      CLOSE c1;

      /*-- prc 10/21/04 Testing (NULL was SITE) VV
      select 'labu_'|| to_char(sysdate,'mmdd_hh24miss') ||'.dat'
        into ofile_name
        from dual;

      vfile_type := UTL_FILE.FOPEN ('LAB_DIR',ofile_name,'a'); -- prc 03/05/2004 9.2 needs it this way

      if UTL_FILE.IS_OPEN (vfile_type) then
         dbms_output.put_line('OS File is open.');
      else
         dbms_output.put_line('OS File is not open.');
      end if;

      OPEN c2;
      LOOP
         FETCH c2 INTO c2_rec;
         EXIT WHEN c2%NOTFOUND;

         utl_file.put_line(vfile_type,c2_rec.data_record);
      END LOOP;

      utl_file.fclose(vfile_type);
      oip_file := '/tmp/' || ofile_name;

      automate_bdl.run_bdl(oip_file);

      CLOSE c2;
      -- prc 10/21/04 Testing (NULL was SITE) ^^ */

   END create_dat_file;

   PROCEDURE run_bdl (ip_file IN char)
   IS

      ip_id   number;

   BEGIN
      create_os_file (ip_file);

      BEGIN

         SELECT os_file_id
         INTO  ip_id
         FROM  os_files
         WHERE status_code = 'RECEIVED'
         AND   name = 'LOAD_DLM_LABS'
         and FILE_NAME = ip_file;

      END;

      Log_Util.LogMessage('AUTRBDL - about to call submit_psub_bdl.');

      --submit_psub_bdl (ip_id, '/export/home/opapps/bdl');
      --PRC 07/07/03: Reloadable file name is not right. Added '/'
      --PRC 07/08/03: Reloadable file name is not right. Changed to '/export/home/bdl/log/'
      submit_psub_bdl (ip_id, '/export/home/bdl/log/');

      Log_Util.LogMessage('AUTRBDL - completed submit_psub_bdl.');

   END run_bdl;

   PROCEDURE create_os_file (ip_datafile IN char)
   IS

   BEGIN

      Log_Util.LogMessage('AUTOCOFL - inserting OS_FILE record.');

      INSERT INTO os_files (
        OS_FILE_ID,
        NAME,
        FILE_NAME,
        MASK_ID,
        STATUS_CODE,
        CREATED_BY,
        CREATION_TS,
        PRODUCTION_FLAG,
        LAB_ID,
        CHARACTER_SET)
      VALUES
        ( os_file_seq.nextval ,
        'LOAD_DLM_LABS',
        ip_datafile,
        2001,
        'RECEIVED',
        user,
        sysdate,
        'Y',
        101,
        'SINGLE_BYTE');

      COMMIT;

      Log_Util.LogMessage('AUTOCOFL - created OS_FILE record.');

   END create_os_file;

   PROCEDURE submit_psub_bdl (ip_file_id IN number, ip_directory_path IN char)
   IS

   BEGIN
      Log_Util.LogMessage('AUTOSPSUBB - about to call submit_psub_load.');

      submit_psub_load (ip_file_id, ip_directory_path);
      null;
      Log_Util.LogMessage('AUTOSPSUBB - completed call to submit_psub_load.');
   END submit_psub_bdl;

END automate_bdl;
/


