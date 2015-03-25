CREATE OR REPLACE PROCEDURE Flag_Dup_Lab_Results AS
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*     Author: Patrick Conrad                                                        */
  /*       Date: 04/07/2004                                                            */
  /*Description: This code is used to mark duplicates within the Lab Records waiting to*/
  /*             to be loaded.                                                         */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*  Modification History                                                             */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* PRC - 10/27/04 : Rewrote this routine.  Now it is Much more straight forward      */
  /*                  Get all "NEW" lab results, order them by                         */
  /*                  study/patient/sample/question; loop through if last = current    */
  /*                  then mark current as dup.                                        */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

  R_Count       Number := 0;

  last_study           nci_labs.oc_study%type;
  last_pat_pos         nci_labs.oc_Patient_Pos%type;
  last_sample_datetime nci_labs.sample_datetime%type;
  last_lab_question    nci_labs.oc_lab_question%type;
  last_record_id       nci_labs.Record_ID%type;

   CURSOR c1 is
      SELECT record_id
             ,sample_datetime
             ,result
             ,unit
             ,oc_lab_question
             ,oc_patient_pos
             ,oc_study
             ,nvl(cdw_result_id,record_id)
        FROM nci_labs n
       WHERE LOAD_FLAG IN ('N', 'R')
       ORDER BY oc_study
                ,oc_patient_pos
                ,sample_datetime
                ,oc_lab_question
                ,nvl(cdw_result_id,record_id);

   c1_record c1%ROWTYPE;

BEGIN
  
   If Log_Util.Log$LogName is null Then 
      Log_Util.LogSetName('FNDDUP_' || to_char(sysdate, 'YYYYMMDD-HH24MI'),'LABLOAD'); 
   End If;
   Log_Util.LogMessage('FDLLP - Flag Duplicate load lab results Starting');

   last_study           := '~';
   last_pat_pos         := 0;
   last_sample_datetime := '~';
   Last_lab_question    := '~';
   Last_record_id       := 0;
   
   R_Count := 0;

   OPEN c1;
   LOOP
      FETCH c1 INTO c1_record;
      EXIT WHEN c1%NOTFOUND;
  
      If (Last_study           = c1_Record.oc_study) AND
         (Last_pat_pos         = c1_Record.oc_patient_pos) and
         (Last_Sample_datetime = c1_Record.Sample_datetime) and
         (Last_lab_Question    = c1_Record.Oc_Lab_Question) 
      Then
         update nci_labs
            set load_flag = 'D', 
                error_reason = 'Study/Patient/DateTime/Question Duplicate (UPDATE) ['||Last_Record_id||']'
          where oc_study = c1_record.oc_study
            and record_id = c1_record.record_id;
                
         R_count := R_Count + 1;
      else
         null;
      end if;
  
      Last_study           := c1_Record.oc_study;
      Last_pat_pos         := c1_Record.oc_patient_pos;
      Last_Sample_datetime := c1_Record.Sample_datetime;
      Last_lab_Question    := c1_Record.Oc_Lab_Question;
      Last_record_id       := c1_Record.Record_ID;
    
   END LOOP;

   Log_Util.LogMessage('FDLLR - '||to_char(R_Count)||' records marked for Lab Panel/Subset/Pt/DtTm/Q Duplicate');

   CLOSE c1;

   Log_Util.LogMessage('FDLLP - Flag Duplicate load lab results FINISHED');

END; -- Flag_Dup_Load_Lab_Results
/
