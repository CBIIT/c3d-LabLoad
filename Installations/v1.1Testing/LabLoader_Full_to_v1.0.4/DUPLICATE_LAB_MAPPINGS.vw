/* Formatted on 2005/12/09 15:31 (Formatter Plus v4.8.0) */
CREATE OR REPLACE FORCE VIEW duplicate_lab_mappings (study,
                                                           dci,
                                                           dcm,
                                                           subset_name,
                                                           repeat_sn,
                                                           default_value_text
                                                          )
AS
   SELECT DISTINCT sr.study, sr.dci, sr.dcm, sr.subset_name, sr.repeat_sn,
                   sr.default_value_text
              FROM study_repeat_defaults_vw sr,
                   (SELECT   study, book, default_value_text, COUNT (*)
                        FROM study_repeat_defaults_vw
                       WHERE question = 'LPARM'
                    GROUP BY study, book, default_value_text
                      HAVING COUNT (*) > 1) dup
             WHERE dup.study = sr.study
               AND dup.default_value_text = sr.default_value_text
               AND EXISTS (SELECT NULL
                             FROM c3d_accessible_studies_vw k
                            WHERE sr.study = k.study)
          ORDER BY 1, 6, 2, 3, 4;
