CREATE OR REPLACE PACKAGE insert_lab_data
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/*     Author: Original Unknown                                                      */
/*       Date: Original Unknown                                                      */
/*Description: Creates Batch Data Load records into a table.                         */
/*             (Original Description Missing)                                        */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/*  Modification History                                                             */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
AS
PROCEDURE insert_record (
  investigator IN char
, site IN char
, patient IN char
, document_no IN char
, planned_event IN char
, subevent_no IN number
, dci_date IN char
, dci_time IN char
, dci_name IN char
, dcm_name IN char
, dcm_subset IN char
, dcm_quesgrp IN char
, dcm_ques IN char
, repeat_sn IN number
, valuetext IN char
, study IN char
, tableid IN char);

PROCEDURE save_repeat (
repeat_sn IN number);

PROCEDURE insert_missing_responses (
  investigator IN char
, site IN char
, patient IN char
, document_no IN char
, planned_event IN char
, subevent_no IN number
, dci_date IN char
, dci_time IN char
, dci_name IN char
, ipdcm_name IN char
, dcm_subset IN char
, dcm_quesgrp IN char
, dcm_ques IN char
, repeat_sn IN number
, valuetext IN char
, ipstudy IN char
, tableid IN char);

PROCEDURE insert_missing_DCMS;

PROCEDURE delete_repeats;

END insert_lab_data;
/

