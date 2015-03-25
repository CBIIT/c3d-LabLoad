/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Author: Patrick Conrad (Ekagra Software Technologies)                 */
/* Date:   Nov. 30, 2005                                                 */
/* Description: This is the installation script for the Message Log      */
/*              Utility. The message Log Utility is used by the various  */
/*              C3D Utilities for the recording of message and debug     */
/*              information.  The Log Utility consist of:                */
/*              LOG_UTIL - PL/SQL Package; Creates and maintains logs    */
/*              MESSAGE_LOGS - Table used to store the log.              */
/*              Each of these objects are PUBLIC.                        */
/*                                                                       */
/* EXECUTION NOTE:  The following files should be placed into the same   */
/*                  directory. Before this file is execute, the install  */
/*                  directory should be the default directory.           */
/*          FILES:                                                       */
/*                 Install_Log_Util.sql - This file                      */
/*                 Message_logs.sql - Database table, index, synonym.    */
/*                 Message_logs_Arch.sql - Archive table for messages    */
/*                 Log_Util.sql - Log Messaging package                  */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
/* Modification History:                                                 */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

-- Added condition to exit when error.  Just incase run accidently.
WHENEVER SQLERROR EXIT

Select to_char(sysdate,'MM/DD/YYYY HH24:MI:SS') "Execution Date", User "User"
  from dual;

-- Spool a log file
spool install_log_util.lst

--install the table, index and privs
Prompt ...Installing Table, Index, Synonym and Privileges.
@Message_logs.sql

--install the table, index and privs
Prompt ...Installing Archive Table, Index, Synonym and Privileges.
@Message_logs_ARCH.sql

-- Install Package
Prompt ...Installing Package, synonym and privileges
@LOG_Util.sql

spool off

PROMPT
PROMPT FINISHED!
PROMPT

