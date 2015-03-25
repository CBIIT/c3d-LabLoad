CREATE OR REPLACE Function Find_LabMap_Version2(i_StudyID in Varchar2, i_Laboratory in Varchar2) Return Varchar2
  is
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
  /*       Date: 12/06/2011                                                            */
  /*Description: This procedure is used to identify the Lab Mapping Version of the     */
  /*             passed study and Laboratory.                                          */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*  Modification History                                                             */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

     v_map_version      nci_lab_load_ctl.map_version%type;
     err_num            number;
     err_msg            varchar2(100);

  Begin
     Begin
        -- Get the Map Version from the Lab Load Study Control View for the study/laboratory passed in..
        SELECT MAP_VERSION
          into v_map_version
          FROM nci_lab_load_study_ctls_vw
         WHERE oc_study = i_StudyID
           and laboratory = i_Laboratory;

     Exception
        When No_Data_Found then
            -- Study not defined. This should not happen as all studies are
            v_map_version := NULL;
        When Others then
            v_map_version := NULL;
            Err_num := SQLCODE;
            err_msg := substr(sqlerrm,1,100);
            Log_Util.LogMessage('FNDLABMAP2 - Error during FIND_LABMAP_VERSION2');
            Log_Util.LogMessage('          - Study      = "'||i_StudyId||'".');
            Log_Util.LogMessage('          - Laboratory = "'||i_Laboratory||'".');
            Log_Util.LogMessage('          - ERROR: '||to_char(err_num)||' - "'||Err_msg||'".');
      End;
     Return v_map_version;
  End;
/

