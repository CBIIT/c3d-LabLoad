/* Formatted on 2005/12/09 15:31 (Formatter Plus v4.8.0) */
CREATE OR REPLACE FORCE VIEW nci_uoms (VALUE, meaning, type_labtest)
AS
   SELECT VALUE, meaning, type_labtest
     FROM nci_uom_main
    WHERE type_labtest = 'Lab Test';
