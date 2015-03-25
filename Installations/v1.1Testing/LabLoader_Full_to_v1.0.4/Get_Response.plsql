CREATE OR REPLACE FUNCTION Get_Response_Value(p_Study in varchar2,
                                              p_Pt    in varchar2,
                                              p_DCM   in varchar2,
                                              p_Question in varchar2)
Return varchar2 is

   v_result                     varchar2(400);
   v_found                      boolean;


Begin

   cdw_data_transfer_v3.Get_Response(p_Study, p_PT, p_dcm, p_Question, v_result, v_found);

   If not v_found Then
      RETURN 'NULL';
   Else
      Return V_Result;
   End If;
End;
/

Show Errors;

