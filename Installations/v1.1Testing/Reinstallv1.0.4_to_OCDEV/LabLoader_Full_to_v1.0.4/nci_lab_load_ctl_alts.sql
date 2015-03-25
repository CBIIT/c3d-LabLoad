
alter table NCI_LAB_LOAD_CTL
   add  MAP_VERSION                VARCHAR2(10);

alter table NCI_LAB_LOAD_CTL
   add  ALLOW_MULT_PATIENTS        VARCHAR2(1);

alter table NCI_LAB_LOAD_CTL
   add  FIND_EVENT                 VARCHAR2(1);

COMMENT ON COLUMN NCI_LAB_LOAD_CTL.ALLOW_MULT_PATIENTS IS 
      '"Y" allows patients to be on study more than once; "N" does not.';

COMMENT ON COLUMN NCI_LAB_LOAD_CTL.MAP_VERSION IS 
      'Version of Lab Mapping Map to use when identifying OC Lab Questions';

COMMENT ON COLUMN NCI_LAB_LOAD_CTL.FIND_EVENT IS 
      '"Y"=Find Event from OC; "N"=Use Event as Given.'