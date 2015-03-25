/* Formatted on 2005/12/09 15:37 (Formatter Plus v4.8.0) */
CREATE OR REPLACE FORCE VIEW labtests (NAME,
                                           intent,
                                           domain,
                                           question_status_code
                                          )
AS
   SELECT NAME, intent, domain, question_status_code
     FROM questions
    WHERE que_sub_type_code = 'LAB TEST'
      AND question_status_code <> 'R'
      AND NAME NOT LIKE 'LAB_%'
      AND NAME <> 'LPARM';

Grant select on labtests to public;



