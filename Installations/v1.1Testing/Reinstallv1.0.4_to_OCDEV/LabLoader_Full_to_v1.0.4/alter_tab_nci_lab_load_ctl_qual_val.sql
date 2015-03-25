Alter table nci_lab_load_ctl
add (use_qualify_value varchar2(1));

COMMENT ON COLUMN NCI_LAB_LOAD_CTL.USE_QUALIFY_VALUE 
        IS 'Set to ''Y'' to have study use QUALIFYING_VALUE from NCI_LABS, set to ''N'' to leave QUALIFYING_VALUE blank';


