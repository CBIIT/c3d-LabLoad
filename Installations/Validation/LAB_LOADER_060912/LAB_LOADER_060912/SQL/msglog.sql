REM CLEAR SCREEN

SET TIME OFF
SET HEADING ON
SET LINESIZE 125
SET PAGESIZE 52
SET TRIMOUT OFF
SET TRIMSPOOL OFF
SET PAUSE OFF
SET WRAP OFF
SET ECHO OFF
SET DOCUMENT OFF
SET VERIFY OFF
SET SHOW OFF
SET FEEDBACK OFF
SET NUMWIDTH 10

REM PRC Added 

COLUMN today            NOPRINT NEW_VALUE     	datevar
COLUMN logtext         	HEADING "Log Text"    	FORMAT A110 wrap  
COLUMN logdate         	HEADING "Log Date"     
COLUMN line	 	HEADING "Line"   	FORMAT A10     

SELECT TO_CHAR(SYSDATE,'DD-MON-YY') today FROM DUAL;

ACCEPT in_logname PROMPT "Enter log name: "

SPOOL &in_logname;

DEFINE studytitle =  "LAB LOADER Message Log &&in_logname"
TTITLE LEFT 'User: ' SQL.USER CENTER studytitle RIGHT datevar SKIP 2
BTITLE RIGHT 'Page:' FORMAT 09 SQL.PNO 

SELECT 
lpad(loglinenumber,5,'0') line, logtext
from message_logs
Where logname like '%&in_logname%'
order by 1,2;
spool off;

CLEAR COLUMNS

/


