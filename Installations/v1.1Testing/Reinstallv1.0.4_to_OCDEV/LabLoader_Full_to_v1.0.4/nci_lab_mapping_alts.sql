
alter table NCI_LAB_MAPPING
add MAP_VERSION        VARCHAR2(10);

COMMENT ON COLUMN NCI_LAB_MAPPING.MAP_VERSION IS 'Version of Map';