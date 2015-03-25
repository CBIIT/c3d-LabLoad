

-- Find the owner and possible synonyms for the CDW Data Load Tables.
--               1         2         3         4         5         6         7     
--      123456789012345678901234567890123456789012345678901234567890123456789012345

column text format a75 head ""
column owner format a10
column object_name format a25
column object_type format a20
column table_owner format a11
column table_name  format a25
column owner format a10
column object_name format a25
set lines 80 heading off echo off timing off feedback off

spool find_external_owners

select to_char(sysdate,'DD-MON-YYYY HH24:MI:SS') "Install Date",
       user "Install User"
from dual;

select '--Lab Loader Utility' text
  from dual;

set lines 80 heading on

select Owner, object_name, object_type 
  from dba_objects 
 where object_name in ('CDW_DATA_TRANSFER_V3')
order by owner, object_name, object_type
/

set lines 80 heading off

select '--CDW Data Load Utility' text
  from dual
/
  
select 'The following list contains ownership and synonym defintions for the CDW ' text,
       'Data Load Utility. If the table objects have the same owner as the Lab ' text,
       'Loader Utility above, then there is no need to apply public synonyms to' text, 
       'the CDW Data Load Tables. If, however the owners are different, and ' text,
       'synonyms do not exist for these objects, they must be created.' text
  from dual;

set lines 80 heading on

select Owner, object_name, object_type 
  from dba_objects 
 where object_name in ('MIS_LAB_RESULTS_HISTORY','MIS_CDR_TESTS',
                       'MIS_LAB_RESULTS_CURRENT','MIS_PATIENT_LIST',
                       'MIS_PROTOCOL_LIST',      'MIS_PROT_PAT_CDRLIST')
   and Object_type <> 'SYNONYM'
order by object_type, owner, object_name
/

set lines 80 heading off

select Distinct 'Synonyms, if they exist:' text
  from dba_synonyms 
 where synonym_name in 
       (select object_name
          from dba_objects 
         where object_name in ('MIS_LAB_RESULTS_HISTORY','MIS_CDR_TESTS',
                               'MIS_LAB_RESULTS_CURRENT','MIS_PATIENT_LIST',
                               'MIS_PROTOCOL_LIST',      'MIS_PROT_PAT_CDRLIST')
           and Object_type = 'SYNONYM')
/
set lines 80 heading on

select Owner, SYNONYM_NAME, TABLE_OWNER,TABLE_NAME                                                                  
  from dba_synonyms 
 where synonym_name in 
       (select object_name
          from dba_objects 
         where object_name in ('MIS_LAB_RESULTS_HISTORY','MIS_CDR_TESTS',
                               'MIS_LAB_RESULTS_CURRENT','MIS_PATIENT_LIST',
                               'MIS_PROTOCOL_LIST',      'MIS_PROT_PAT_CDRLIST')
           and Object_type = 'SYNONYM')
order by synonym_name, owner
/



set lines 80 heading off

select '--Miscellaneous Support Objects' text
  from dual
/

select 'The following list contains ownership and synonym defintions for additional' text,
       'objects that are used by the Lab Loader.  If the objects have the same     ' text,
       'owner as the Lab Loader Utility above, then there is no need to apply      ' text, 
       'public synonyms to them.  If, however the owners are different, and ' text,
       'synonyms do not exist for these objects, they must be created.' text
  from dual;

set lines 80 heading on

select Owner, object_name, object_type 
  from dba_objects 
 where object_name in ('DUPLICATE_LAB_MAPPINGS', 'LOG_UTIL')
   and Object_type <> 'SYNONYM'
order by object_type, owner, object_name
/

set lines 80 heading off

select 'Synonyms, if they exist:' text
  from dba_synonyms 
 where synonym_name in 
       (select object_name
          from dba_objects 
         where object_name in ('DUPLICATE_LAB_MAPPINGS', 'LOG_UTIL')
           and Object_type = 'SYNONYM')
order by synonym_name, owner
/
set lines 80 heading on

select Owner, SYNONYM_NAME, TABLE_OWNER,TABLE_NAME                                                                  
  from dba_synonyms 
 where synonym_name in 
       (select object_name
          from dba_objects 
         where object_name in ('DUPLICATE_LAB_MAPPINGS', 'LOG_UTIL')
           and Object_type = 'SYNONYM')
order by synonym_name, owner
/

spool off

