/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Author: Patrick Conrad (Ekagra Software Technologies)                 */
/* Date:   Mar 18, 2013                                                  */
/* Description: This is a Post Re-Install for the CDW Lab Loader.        */
/*              It is intended to be used AFTER the Full Lab Loader      */
/*              installation (LabLoader_Full_to_v1.0.4) procedures to    */
/*              remove incorrectly added objects.                        */

Set Timing off verify off

-- Spool a log file
spool REMOVE_UNWANTED_OBJECTS.lst

Select to_char(sysdate,'MM/DD/YYYY HH24:MI:SS') "Execution Date", User "User"
  from dual;

-- DROP Bad Objects
Prompt ...Dropping Objects


DROP Table MIS_CDR_TESTS
/

DROP Table MIS_LAB_RESULTS_HISTORY
/

Drop Procedure SUBMIT_PSUB_LOAD
/

PROMPT
PROMPT FINISHED!
PROMPT

Spool off