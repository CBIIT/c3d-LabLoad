/* PRC 11/21/2005:                                  */
/* Updated script to include PUBLIC role and grants */

CREATE OR REPLACE PACKAGE LOG_UTIL AS

  -- Global Package Variables.

  Log$LogName     Varchar2(30) := Null;
  Log$LogType     Varchar2(30) := Null;
  Log$LogLineSeq  Number := 1;

  Procedure LogSetName(LogName in Varchar2, 
                       LogType in Varchar2);

  Procedure LogMessage(InText in Varchar2);

  Procedure LogClearLog(LogName in Varchar2, 
                        LogType in Varchar2, 
                        LogIt in Boolean Default FALSE);
  Procedure LogPurgePrior(p_LogName in Varchar2, 
                          p_LogType in Varchar2, 
                          p_LogDate In Date, 
                          p_LogIt in Boolean Default FALSE);

END Log_Util;
/

Show Error

CREATE OR REPLACE PACKAGE BODY Log_Util AS
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*     Author: Patrick COnrad                                                        */
  /*       Date: 7/28/2003                                                             */
  /*Description: This package will assist in creating a log file (stored in table      */
  /*             Message_Logs).  These utilities can be used to record Debug messages  */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /*  Modification History                                                             */
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /* prc 08/17/04: Added "insert into message_logs_arch" at every point where a delete */
  /*               occurs against MESSAGE_LOGS.  It was requested that intead of       */
  /*               removing the logs, they should be archived.                         */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */


  Procedure LogSetName(LogName in Varchar2, 
                       LogType in Varchar2) is
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
    /*       Date: 07/14/2003                                                            */
    /*Description: This procedure is used to set-up a new message log                    */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*  Modification History                                                             */
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
    /* PRC 10/29/03: Corrected error in LogName numbering. a to_char(x,'099') is actually*/
    /*               4 characters long, causing the entire string length to possibly     */
    /*               exceed the 30 character length limit of the variable.  Changed it   */
    /*               '099' format to 'FM099'                                             */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    v_Found   Number := 1;
    v_HoldLN  Varchar2(30);
    v_HoldLT  Varchar2(30);
    v_Counter Number := 0;

  Begin
    V_HoldLN := Nvl(Upper(Substr(LogName, 1, 30)),'GenericLog');
    V_HoldLT := Nvl(Upper(Substr(LogType, 1, 30)),'GenericLog');

    While v_Found <> 0 Loop
      select Count(*)
        Into v_Found
        from Message_Logs
       where LOGNAME like v_HoldLN
         and LOGType like v_HoldLT;

      If v_Found > 0 Then
        v_HoldLN  := Upper(SubStr(LogSetName.LogName, 1, 27)) ||
                     to_char(v_Counter, 'FM099');
        v_Counter := v_Counter + 1;
      End if;
    End Loop;

    Log$LogName     := v_HoldLN;
    Log$LogType     := v_HoldLT;
    Log$LogLineSeq  := 1;

    If LogName <> Log$LogName Then
      Log_Util.LogMessage('Specified Log Name "' || LogName || '" changed to "' ||
                   Log$LogName || '".');
      Commit;
    End If;
    If LogType <> Log$LogType Then
      Log_Util.LogMessage('Specified Log Type "' || LogType || '" changed to "' ||
                   Log$LogType || '".');
      Commit;
    End If;

  End;

  Procedure LogInsertRow(v_logName    in message_logs.LogName%type,
                         v_logType    in message_logs.LogType%type,
                         v_logLineSeq in message_logs.LogLineNumber%type,
                         v_LogText    in message_logs.LogText%type,
                         v_logDate    in message_logs.LogDate%type,
                         v_logUser    in message_logs.LogUser%type) Is
  PRAGMA AUTONOMOUS_TRANSACTION;                         
  Begin                         
  
     Insert into Message_Logs
         (LogName, LogType, LogLineNumber, LogText, LogDate, LogUser)
       values
         (v_LogName, v_LogType, v_LogLineSeq, v_LogText, v_LogDate, v_LogUser);
         
      Commit;
   
  End;



  Procedure LogMessage(InText in Varchar2) is
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
    /*       Date: 07/28/2003                                                            */
    /*Description: This procedure is used to insert a message into the log table and     */
    /*             increment the message line counter.                                   */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  Begin
    If Log$LogName is null Then
       LogSetName('NONE SPECIFIED',NULL);
    End If;

    LogInsertRow(Log$LOGNAME, Log$LogType, Log$LogLineSeq, InText, Sysdate, User);

    Log$LogLineSeq := Log$LogLineSeq + 1;

  End;

  Procedure LogClearLog(LogName in Varchar2, LogType in Varchar2, LogIt in Boolean Default FALSE) is
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
    /*       Date: 07/28/2003                                                            */
    /*Description: This procedure is used to insert a message into the log table and     */
    /*             increment the message line counter.                                   */
    /*  Modification History                                                             */
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
    /* prc 08/17/04: Added "insert into message_logs_arch" at every point where a delete */
    /*               occurs against MESSAGE_LOGS.  It was requested that intead of       */
    /*               removing the logs, they should be archived.                         */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    v_HoldLN Varchar2(30);
    v_HoldLT Varchar2(30);

  Begin
    If LogIt Then
       LogSetName('LogClearLog', 'LogMaintenance');
       Log_Util.LogMessage('LogClearLog initiated by '||User);
    End If;

    v_HoldLN := LogName;
    v_HoldLT := LogType;

    If v_HoldLN is null Then
      v_HoldLN := '%';
    End If;

    If v_HoldLT is null Then
      v_HoldLT := '%';
    End If;

    If LogIt Then
       Log_Util.LogMessage('  Log Clear Values: LogName = "'||v_HoldLN||'".');
       Log_Util.LogMessage('  Log Clear Values: LogType = "'||v_HoldLT||'".');
       
       -- prc 08/17/04: Insert into ARCHIVE table prior to delete
       Insert into message_logs_arch (LOGNAME, LOGTYPE, LOGLINENUMBER, LOGTEXT, LOGDATE, LOGUSER, ARCHDATE, ARCHUSER)
       select LOGNAME, LOGTYPE, LOGLINENUMBER, LOGTEXT, LOGDATE, LOGUSER, sysdate, user
         from Message_Logs 
        where LOGNAME like v_HoldLN
          and LogType Like v_HoldLT
          and (logname <> Log$LogName);
 
       Delete from Message_Logs 
        where LOGNAME like v_HoldLN
          and LogType Like v_HoldLT
          and (logname <> Log$LogName);
    Else
       -- prc 08/17/04: Insert into ARCHIVE table prior to delete
       Insert into message_logs_arch (LOGNAME, LOGTYPE, LOGLINENUMBER, LOGTEXT, LOGDATE, LOGUSER, ARCHDATE, ARCHUSER)
       select LOGNAME, LOGTYPE, LOGLINENUMBER, LOGTEXT, LOGDATE, LOGUSER, sysdate, user
         from Message_Logs 
        where LOGNAME like v_HoldLN
          and LogType Like v_HoldLT;
          
       Delete from Message_Logs 
        where LOGNAME like v_HoldLN
          and LogType Like v_HoldLT;

    End If;

    If LogIt Then
      Log_Util.LogMessage('  '||to_char(SQL%RowCount)||' rows successfully deleted from Message_Logs.');
      Log_Util.LogMessage('LogClearLog completed '||to_char(sysdate,'DD-MON-YYYY HH24:MI:SS'));
    End If;

    Commit;

  End;

  Procedure LogPurgePrior(p_LogName in Varchar2, p_LogType in Varchar2, 
                          p_LogDate In Date, p_LogIt in Boolean Default FALSE) is
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*     Author: Patrick Conrad - Ekagra Software Technologies                         */
    /*       Date: 06/14/2004                                                            */
    /*Description: This procedure is used to Purge Logs Since a given Date.  If not date */
    /*             is given, then all logs matching the criteria specified by LogName    */
    /*             and LogType will be used.                                             */
    /*  Modification History                                                             */
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
    /* prc 08/17/04: Added "insert into message_logs_arch" at every point where a delete */
    /*               occurs against MESSAGE_LOGS.  It was requested that intead of       */
    /*               removing the logs, they should be archived.                         */
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    v_HoldLN Varchar2(30);
    v_HoldLT Varchar2(30);

  Begin
    If p_LogIt Then
       LogSetName('LogPurgeSince', 'LogMaintenance');
       Log_Util.LogMessage('LPS - LogPurgeSince Initiated by '||User);
    End If;

    v_HoldLN := nvl(p_LogName,'%');
    v_HoldLT := nvl(p_LogType,'%');

    If p_LogIt Then
       Log_Util.LogMessage('LPS - Paremeter  LogName = "'||v_HoldLN||'".');
       Log_Util.LogMessage('LPS - Paremeter  LogType = "'||v_HoldLT||'".');
       Log_Util.LogMessage('LPS - Paremeter  LogDate = "'||to_Char(p_LogDate,'DD-MON-YYYY HH24:MI:SS')||'".');
 
       -- prc 08/17/04: Insert into ARCHIVE table prior to delete
       Insert into message_logs_arch (LOGNAME, LOGTYPE, LOGLINENUMBER, LOGTEXT, LOGDATE, LOGUSER, ARCHDATE, ARCHUSER)
       select LOGNAME, LOGTYPE, LOGLINENUMBER, LOGTEXT, LOGDATE, LOGUSER, sysdate, user
         from Message_Logs 
        where LOGNAME like v_HoldLN
          and LogType Like v_HoldLT
          and LogDate <= nvl(p_LogDate,Sysdate-1000)
          and (logname <> Log$LogName);
          
       Delete from Message_Logs 
        where LOGNAME like v_HoldLN
          and LogType Like v_HoldLT
          and LogDate <= nvl(p_LogDate,Sysdate-1000)
          and (logname <> Log$LogName);
    Else

       -- prc 08/17/04: Insert into ARCHIVE table prior to delete
       Insert into message_logs_arch (LOGNAME, LOGTYPE, LOGLINENUMBER, LOGTEXT, LOGDATE, LOGUSER, ARCHDATE, ARCHUSER)
       select LOGNAME, LOGTYPE, LOGLINENUMBER, LOGTEXT, LOGDATE, LOGUSER, sysdate, user
         from Message_Logs 
        where LOGNAME like v_HoldLN
          and LogType Like v_HoldLT
          and LogDate <= nvl(p_LogDate,Sysdate-1000);
          
       Delete from Message_Logs 
        where LOGNAME like v_HoldLN
          and LogType Like v_HoldLT
          and LogDate <= nvl(p_LogDate,Sysdate-1000);

    End If;

    If p_LogIt Then
      Log_Util.LogMessage('LPS - '||to_char(SQL%RowCount)||' rows successfully deleted from Message_Logs.');
      Log_Util.LogMessage('LPS - LogPurgeSince completed '||to_char(sysdate,'DD-MON-YYYY HH24:MI:SS'));
    End If;

    Commit;

  End;

END Log_Util;
/

Show Error

Create public synonym log_Util for Log_Util
/

grant execute on log_util to public
/
