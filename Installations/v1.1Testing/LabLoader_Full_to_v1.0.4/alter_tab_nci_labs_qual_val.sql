Alter table nci_labs
add (qualifying_value varchar2(80));

COMMENT ON COLUMN NCI_LABS.QUALIFYING_VALUE 
        IS 'Used to pass QUALIFYING_VALUE to the DCM in C3D';