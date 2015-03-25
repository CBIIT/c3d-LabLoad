CREATE OR REPLACE PACKAGE nci_lab_utility
IS                                                              
  FUNCTION get_grade (param IN VARCHAR2, unit IN VARCHAR, norm_high IN NUMBER, norm_low IN NUMBER, 
	              valuen IN NUMBER, indicator IN VARCHAR2) RETURN VARCHAR;   
   
  PRAGMA RESTRICT_REFERENCES (get_grade, WNDS );  
                              
                                                                                
END nci_lab_utility;        
/

SHOW ERROR
                                                                  
CREATE OR REPLACE PACKAGE BODY nci_lab_utility
IS 
  FUNCTION get_grade (param IN VARCHAR2, unit IN VARCHAR, norm_high IN NUMBER, norm_low IN NUMBER, 
       	              valuen IN NUMBER,indicator IN VARCHAR2) RETURN VARCHAR   
   
  IS     
    CTC_lab_grade VARCHAR(10);                                                                        
     
  BEGIN 
  
   
  /* CTC grading -- Lab parameter names */
 
    IF param = 'ALK_PHOS' THEN
       IF UPPER(unit) in ('U/L','UNITS/L') THEN
          IF valuen > norm_high AND valuen <= 2.5 * norm_high THEN
  	     	 	CTC_lab_grade := '1';
          ELSIF valuen > 2.5 * norm_high AND valuen <= 5.0 * norm_high THEN
     	        CTC_lab_grade := '2';
	  	  ELSIF valuen > 5.0 * norm_high AND valuen <= 20.0 * norm_high THEN
     			CTC_lab_grade := '3';
	      ELSIF valuen > 20.0 * norm_high THEN
		  		CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
          ELSIF valuen < norm_low THEN
		  		CTC_lab_grade := '-2';
          END IF;    

       ELSE
	   	   CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	   CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	   CTC_lab_grade := '0';
       END IF;
          
    ELSIF param = 'ALBUMIN_SERUM' THEN
       IF UPPER(unit) in ('G/DL','GM/DL') THEN
          IF valuen < norm_low AND valuen >= 3 THEN
     	     	CTC_lab_grade := '1';
	   	  ELSIF valuen BETWEEN 2.0 and 2.9 THEN
     			CTC_lab_grade := '2';
	      ELSIF valuen < 2.0 THEN
     			CTC_lab_grade := '3';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
	      ELSIF valuen > norm_high THEN
		  		CTC_lab_grade := '-2';
	      END IF;
		  
       ELSIF UPPER(unit) = 'G/L' THEN
          IF valuen < norm_low AND valuen >= 30 THEN
     	     	CTC_lab_grade := '1';
	   	  ELSIF valuen BETWEEN 20 and 29 THEN
     			CTC_lab_grade := '2';
	      ELSIF valuen < 20 THEN
     			CTC_lab_grade := '3';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
	      ELSIF valuen > norm_high THEN
		  		CTC_lab_grade := '-2';
	      END IF;
       ELSE
	   	   CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	  CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	  CTC_lab_grade := '0';
       END IF;
    
    ELSIF param = 'AMYLASE_SERUM' THEN
       IF UPPER(unit) in ('U/L','UNITS/L') THEN
          IF valuen > norm_high AND valuen <= 1.5 * norm_high THEN
    	     	CTC_lab_grade := '1';
          ELSIF valuen > 1.5 * norm_high AND valuen <= 2.0 * norm_high THEN
     			CTC_lab_grade := '2';
	      ELSIF valuen > 2.0 * norm_high AND valuen <= 5.0 * norm_high THEN
     			CTC_lab_grade := '3';
	  	  ELSIF valuen > 5.0 * norm_high THEN
     			CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
	      ELSIF valuen < norm_low THEN
		  		CTC_lab_grade := '-2';
	      END IF;
       ELSE
		   CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	   CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	   CTC_lab_grade := '0';
       END IF;
   
   ELSIF param = 'ANC' THEN
       IF UPPER(unit) in ('1000/MM3')  THEN
          IF valuen < 2.0 AND valuen >= 1.5 THEN
              	CTC_lab_grade := '1';
          ELSIF valuen < 1.5 AND valuen >= 1.0 THEN
              	CTC_lab_grade := '2';
          ELSIF valuen < 1.0 AND valuen >= 0.5 THEN
              	CTC_lab_grade := '3';
          ELSIF valuen < 0.5 THEN
            	CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
          ELSIF valuen > norm_high THEN
		  		CTC_lab_grade := '-2';
          END IF; 

       ELSIF UPPER(unit) in ('1000/MICROL','K/UL')  THEN
          IF valuen < 1.32 AND valuen >= 1.0 THEN
              	CTC_lab_grade := '2';
          ELSIF valuen < 1.0 AND valuen >= 0.5 THEN
              	CTC_lab_grade := '3';
          ELSIF valuen < 0.5 THEN
            	CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
          ELSIF valuen > norm_high THEN
		  		CTC_lab_grade := '-2';
          END IF;
          
       ELSE
	   	   CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	   CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	   CTC_lab_grade := '0';
       END IF;

   ELSIF param = 'BILIRUBIN_TOTAL' THEN
       IF UPPER(unit) in ('MG/DL','MMOL/L') THEN
          IF valuen > norm_high AND valuen <= 1.5 * norm_high THEN
     	     	CTC_lab_grade := '1';
          ELSIF valuen > 1.5 * norm_high AND valuen <= 3.0 * norm_high THEN
     			CTC_lab_grade := '2';
	      ELSIF valuen > 3.0 * norm_high AND valuen <= 10.0 * norm_high THEN
     			CTC_lab_grade := '3';
	      ELSIF valuen > 10.0 * norm_high THEN
     			CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
          ELSIF valuen < norm_low THEN
		  		CTC_lab_grade := '-2';
	      END IF;
	   	   
       ELSE
	   	   CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	   CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	   CTC_lab_grade := '0';
       END IF;
    
    ELSIF param = 'CALCIUM' THEN
      IF UPPER(unit) = 'MG/DL' THEN
          IF (valuen > norm_high AND valuen <= 11.5) OR (valuen < norm_low AND valuen >= 8.0) THEN
     	     	CTC_lab_grade := '1';
	  	  ELSIF (valuen > 11.5 AND valuen <= 12.5) OR (valuen < 8.0 AND valuen >= 7.0) THEN
     			CTC_lab_grade := '2';
	      ELSIF (valuen > 12.5 AND valuen <= 13.5) OR (valuen < 7.0 AND valuen >= 6.0) THEN
     			CTC_lab_grade := '3';
	      ELSIF valuen > 13.5 OR valuen < 6.0 THEN
     			CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
          END IF;
         
       ELSIF UPPER(unit) = 'MMOL/L' THEN
          IF (valuen > norm_high AND valuen <= 2.9) OR (valuen < norm_low AND valuen >= 2.0) THEN
     	     	CTC_lab_grade := '1';
	  	  ELSIF (valuen > 2.9 AND valuen <= 3.1) OR (valuen < 2.0 AND valuen >= 1.75) THEN
     			CTC_lab_grade := '2';
	      ELSIF (valuen > 3.1 AND valuen <= 3.4) OR (valuen < 1.75 AND valuen >= 1.5) THEN
     			CTC_lab_grade := '3';
	      ELSIF valuen > 3.4 OR valuen < 1.5 THEN
     			CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
          END IF;
		  
	   ELSIF UPPER(unit) in ('MEQ/L') THEN
          IF (valuen > norm_high AND valuen <= 5.8) OR (valuen < norm_low AND valuen >= 4.0) THEN
     	     	CTC_lab_grade := '1';
	  	  ELSIF (valuen > 5.8 AND valuen <= 6.2) OR (valuen < 4.0 AND valuen >= 3.5) THEN
     			CTC_lab_grade := '2';
	      ELSIF (valuen > 6.2 AND valuen <= 6.8) OR (valuen < 3.5 AND valuen >= 3.0) THEN
     			CTC_lab_grade := '3';
	      ELSIF valuen > 6.8 OR valuen < 3.0 THEN
     			CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
          END IF;

       ELSE
		  CTC_LAB_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	  CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	  CTC_lab_grade := '0';
       END IF;
    
    ELSIF param = 'CHOLESTEROL_TOTAL' THEN
       IF UPPER(unit) = 'MG/DL' THEN
          IF valuen > norm_high AND valuen <= 300 THEN
           	 	CTC_lab_grade := '1';
          ELSIF valuen > 300 AND valuen <= 400 THEN
           		CTC_lab_grade := '2';
          ELSIF valuen > 400 AND valuen <= 500 THEN
           		CTC_lab_grade := '3';
          ELSIF valuen > 500 THEN
           		CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
	      ELSIF valuen < norm_low THEN
		  		CTC_lab_grade := '-2';
          END IF;

       ELSIF UPPER(unit) = 'MMOL/L' THEN
          IF valuen > norm_high AND valuen <= 7.75 THEN
           	 	CTC_lab_grade := '1';
          ELSIF valuen > 7.75 AND valuen <= 10.34 THEN
           		CTC_lab_grade := '2';
          ELSIF valuen > 10.34 AND valuen <= 12.92 THEN
           		CTC_lab_grade := '3';
          ELSIF valuen > 12.92 THEN
           		CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
	      ELSIF valuen < norm_low THEN
		  		CTC_lab_grade := '-2';
          END IF;

       ELSE
          CTC_LAB_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	  CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	  CTC_lab_grade := '0';
       END IF;
    
    ELSIF param = 'BICARB_SERUM' THEN
       IF UPPER(unit) in ('MMOL/L','MEQ/L') THEN
          IF valuen < norm_low AND valuen >= 16 THEN
     	     	CTC_lab_grade := '1';
	      ELSIF valuen BETWEEN 11 and 15 THEN
     			CTC_lab_grade := '2';
          ELSIF valuen BETWEEN 8 and 10 THEN
     			CTC_lab_grade := '3';
	      ELSIF valuen < 8 THEN
     			CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
	      ELSIF valuen > norm_high THEN
		  		CTC_lab_grade := '-2';
	      END IF;

       ELSE
	   	   CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	   CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	   CTC_lab_grade := '0';
       END IF;

    ELSIF param = 'CPK' THEN
       IF UPPER(unit) in ('U/L','UNITS/L') THEN
          IF valuen > norm_high AND valuen <= 2.5 * norm_high THEN
     	     	CTC_lab_grade := '1';
          ELSIF valuen > 2.5 * norm_high AND valuen <= 5.0 * norm_high THEN
     			CTC_lab_grade := '2';
	      ELSIF valuen > 5.0 * norm_high AND valuen <= 10.0 * norm_high THEN
     			CTC_lab_grade := '3';
	      ELSIF valuen > 10.0 * norm_high THEN
     			CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		    	CTC_lab_grade := '-1';
	  	  ELSIF valuen < norm_low THEN
		  		CTC_lab_grade := '-2';
	  	  END IF;
       
       ELSE
	   	   CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	   CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	   CTC_lab_grade := '0';
       END IF;

    ELSIF param IN ('CREATININE','CREATININE_CLEARANCE','CREATININE_URINE') THEN
       IF UPPER(unit) in ('MG/DL','MMOL/L') THEN
          IF valuen > norm_high AND valuen <= 1.5 * norm_high THEN
     	     	CTC_lab_grade := '1';
          ELSIF valuen > 1.5 * norm_high AND valuen <= 3.0 * norm_high THEN
     			CTC_lab_grade := '2';
	      ELSIF valuen > 3.0 * norm_high AND valuen <= 6.0 * norm_high THEN
     			CTC_lab_grade := '3';
	      ELSIF valuen > 6.0 * norm_high THEN
     			CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
	      ELSIF valuen < norm_low THEN
		  		CTC_lab_grade := '-2';
	      END IF;
	          
       ELSE
	   	   CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	   CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	   CTC_lab_grade := '0';
       END IF;
    
 
    ELSIF param = 'FIBRINOGEN' THEN
       IF UPPER(unit) = 'MG/DL' THEN 
          IF valuen < 1.0 * norm_low AND valuen >= 0.75 * norm_low THEN
     	     	CTC_lab_grade := '1';
          ELSIF valuen < 0.75 * norm_low AND valuen >= 0.5 * norm_low THEN
     			CTC_lab_grade := '2';
          ELSIF valuen < 0.5 * norm_low AND valuen >= 0.25 * norm_low THEN
     			CTC_lab_grade := '3';
	      ELSIF valuen < 0.25 * norm_low THEN
     			CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		   		CTC_lab_grade := '-1';
	      ELSIF valuen > norm_high THEN
		  		CTC_lab_grade := '-2';
	      END IF;

       ELSE
  	   	  CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	  CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	  CTC_lab_grade := '0';
       END IF;
    
 
    ELSIF param in ('GLUCOSE','GLUC_FASTING','GLUC_NONFASTING') THEN
       IF UPPER(unit) = 'MG/DL' THEN
          IF (valuen > norm_high AND valuen <= 160) OR (valuen < norm_low AND valuen >= 55) THEN
     	  	 	CTC_lab_grade := '1';
	   ELSIF (valuen > 160 AND valuen <= 250) OR (valuen < 55 AND valuen >= 40) THEN
     	        CTC_lab_grade := '2';
	   ELSIF (valuen > 250 AND valuen <= 500) OR (valuen < 40 AND valuen >= 30) THEN
     		 	CTC_lab_grade := '3';
	   ELSIF valuen > 500 OR valuen < 30 THEN
     		 	CTC_lab_grade := '4';
       ELSIF indicator IN ('NORANG','NONNUM') THEN
			    CTC_lab_grade := '-1';
	   END IF;
          
       ELSIF UPPER(unit) = 'MMOL/L' THEN
          IF (valuen > norm_high AND valuen <= 8.9) OR (valuen < norm_low AND valuen >= 3.0) THEN
     	     	CTC_lab_grade := '1';
	      ELSIF (valuen > 8.9 AND valuen <= 13.9) OR (valuen < 3.0 AND valuen >= 2.2) THEN
     		    CTC_lab_grade := '2';
	      ELSIF (valuen > 13.9 AND valuen <= 27.8) OR (valuen < 2.2 AND valuen >= 1.7) THEN
     			CTC_lab_grade := '3';
	      ELSIF valuen > 27.8 OR valuen < 1.7 THEN
     			CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
	      END IF;
     
       ELSE
	   	   CTC_LAB_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	  CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	  CTC_lab_grade := '0';
       END IF;
    
        
    ELSIF param = 'HEMOGLOBIN' THEN 
       IF UPPER(unit) in ('G/DL','GM/DL') THEN
          IF valuen < norm_low AND valuen >= 10.0 THEN
              	CTC_lab_grade := '1';
          ELSIF valuen < 10.0 AND valuen >= 8.0 THEN
              	CTC_lab_grade := '2';
          ELSIF valuen < 8.0 AND valuen >= 6.5 THEN
            	CTC_lab_grade := '3';
          ELSIF valuen < 6.5 THEN
              	CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
          ELSIF valuen > norm_high THEN
		  		CTC_lab_grade := '-2';
          END IF;
          
       ELSIF UPPER(unit) in ('G/L','GM/L') THEN
          IF valuen < norm_low AND valuen >= 100 THEN
              	CTC_lab_grade := '1';
          ELSIF valuen < 100 AND valuen >= 80 THEN
              	CTC_lab_grade := '2';
          ELSIF valuen < 80 AND valuen >= 65 THEN
              	CTC_lab_grade := '3';
          ELSIF valuen < 65 THEN
              	CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
          ELSIF valuen > norm_high THEN
		  		CTC_lab_grade := '-2';
          END IF;

       ELSIF UPPER(unit) = 'MMOL/L' THEN
          IF valuen < norm_low AND valuen >= 6.2 THEN
            	CTC_lab_grade := '1';
          ELSIF valuen < 6.2 AND valuen >= 4.9 THEN
              	CTC_lab_grade := '2';
          ELSIF valuen < 4.9 AND valuen >= 4.0 THEN
              	CTC_lab_grade := '3';
          ELSIF valuen < 4.0 THEN
              	CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
	      ELSIF valuen > norm_high THEN
		  		CTC_lab_grade := '-2';
          END IF;

       ELSE
	   	   CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	   CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	   CTC_lab_grade := '0';
       END IF;
    
    ELSIF param = 'INORG_PHOS' THEN 
       IF UPPER(unit) = 'MG/DL' THEN
          IF valuen < norm_low AND valuen >= 2.5 THEN
              	CTC_lab_grade := '1';
          ELSIF valuen < 2.5 AND valuen >= 2.0 THEN
              	CTC_lab_grade := '2';
          ELSIF valuen < 2.0 AND valuen >= 1.0 THEN
            	CTC_lab_grade := '3';
          ELSIF valuen < 1.0 THEN
              	CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
          ELSIF valuen > norm_high THEN
		  		CTC_lab_grade := '-2';
          END IF;
          
       ELSIF UPPER(unit) = 'MMOL/L' THEN
          IF valuen < norm_low AND valuen >= 0.8 THEN
              	CTC_lab_grade := '1';
          ELSIF valuen < 0.8 AND valuen >= 0.6 THEN
              	CTC_lab_grade := '2';
          ELSIF valuen < 0.6 AND valuen >= 0.3 THEN
              	CTC_lab_grade := '3';
          ELSIF valuen < 0.3 THEN
              	CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
	      ELSIF valuen > norm_high THEN
		  		CTC_lab_grade := '-2';
          END IF;

       ELSE
	   	   CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	   CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	   CTC_lab_grade := '0';
       END IF;

    ELSIF param = 'LIPASE_SERUM' THEN
       IF UPPER(unit) in ('U/L','UNITS/L') THEN
          IF valuen > norm_high AND valuen <= 1.5 * norm_high THEN
     	     	CTC_lab_grade := '1';
          ELSIF valuen > 1.5 * norm_high AND valuen <= 2.0 * norm_high THEN
     			CTC_lab_grade := '2';
	      ELSIF valuen > 2.0 * norm_high AND valuen <= 5.0 * norm_high THEN
     			CTC_lab_grade := '3';
	      ELSIF valuen > 5.0 * norm_high THEN
     			CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
          ELSIF valuen < norm_low THEN
		  		CTC_lab_grade := '-2';
          END IF;

       ELSE
	   	   CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	   CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	   CTC_lab_grade := '0';
       END IF;

    ELSIF param = 'LYMPHOCYTES_ABS' THEN 
	   IF UPPER(unit) in ('1000/MICROL','K/UL') THEN
          IF valuen < norm_low THEN
              	CTC_lab_grade := '3';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
          ELSIF valuen > norm_high THEN
		  		CTC_lab_grade := '-2';
          END IF;
       
	   ELSIF UPPER(unit) = '1000/MM3' THEN
          IF valuen < norm_low AND valuen >= 1.0 THEN
              	CTC_lab_grade := '1';
          ELSIF valuen < 1.0 AND valuen >= 0.5 THEN
              	CTC_lab_grade := '2';
          ELSIF valuen < 0.5 THEN
            	CTC_lab_grade := '3';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
          ELSIF valuen > norm_high THEN
		  		CTC_lab_grade := '-2';
          END IF;
              
       ELSE
	   	   CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	   CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	   CTC_lab_grade := '0';
       END IF;
	   
	
    ELSIF param = 'MAGNESIUM' THEN
       IF UPPER(unit) = 'MG/DL' THEN
          IF (valuen > norm_high AND valuen <= 3.0) OR (valuen < norm_low AND valuen >= 1.2) THEN
   	     	 	CTC_lab_grade := '1';
          ELSIF (valuen < 0.9 AND valuen >= 1.2) THEN
     			CTC_lab_grade := '2';
          ELSIF (valuen > 3.0 AND valuen <= 8.0) OR (valuen < 0.9 AND valuen >= 0.7) THEN
     			CTC_lab_grade := '3';
	      ELSIF valuen > 8.0 OR valuen < 0.7 THEN
     			CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
	   END IF;
     
       ELSIF UPPER(unit) = 'MMOL/L' THEN
          IF (valuen > norm_high AND valuen <= 1.23) OR (valuen < norm_low AND valuen >= 0.5) THEN
     	     	CTC_lab_grade := '1';
	      ELSIF (valuen < 0.5 AND valuen >= 0.4) THEN
     		 	CTC_lab_grade := '2';
	      ELSIF (valuen > 1.23 AND valuen <= 3.30) OR (valuen < 0.4 AND valuen >= 0.3) THEN
     		 	CTC_lab_grade := '3';
	      ELSIF valuen > 3.30 OR valuen < 0.3 THEN
     		 	CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
			 	CTC_lab_grade := '-1';
          END IF;
		  
	   ELSIF UPPER(unit) = 'MEQ/L' THEN
          IF (valuen > norm_high AND valuen <= 2.46) OR (valuen < norm_low AND valuen >= 1.0) THEN
     	     	CTC_lab_grade := '1';
	      ELSIF (valuen < 1.0 AND valuen >= 0.8) THEN
     		 	CTC_lab_grade := '2';
	      ELSIF (valuen > 2.46 AND valuen <= 6.6) OR (valuen < 0.8 AND valuen >= 0.6) THEN
     		 	CTC_lab_grade := '3';
	      ELSIF valuen > 6.6 OR valuen < 0.6 THEN
     		 	CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
			 	CTC_lab_grade := '-1';
          END IF;

       ELSE
 	   	   CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	  CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	  CTC_lab_grade := '0';
       END IF;
 
    ELSIF param = 'PH' THEN
       IF UPPER(unit) IS NULL THEN
          IF (valuen < norm_low AND valuen >= 7.3) OR (valuen > norm_high AND valuen <= 7.5)  THEN
		  	 CTC_lab_grade := '1';
          ELSIF valuen < 7.3 OR valuen > 7.5 THEN
 		  	 CTC_lab_grade := '3';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  	 CTC_lab_grade := '-1';
          END IF;

       ELSE
	   	   CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	  CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	  CTC_lab_grade := '0';
       END IF;    
 
    ELSIF param = 'PLT' THEN 
       IF UPPER(unit) in ('1000/MICROL','1000/MM3','K/UL') THEN
          IF valuen < norm_low AND valuen >= 75.0 THEN
              	CTC_lab_grade := '1';
          ELSIF valuen < 75.0 AND valuen >= 50.0 THEN
              	CTC_lab_grade := '2';
          ELSIF valuen < 50.0 AND valuen >= 10.0 THEN
            	CTC_lab_grade := '3';
          ELSIF valuen < 10.0 THEN
              	CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
          ELSIF valuen > norm_high THEN
		  		CTC_lab_grade := '-2';
          END IF;
          
       ELSE
	   	   CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	  CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   		 CTC_lab_grade := '0';
       END IF;
    
       ELSIF param = 'POTASSIUM' THEN
       IF UPPER(unit) in ('MMOL/L','MEQ/L') THEN
          IF (valuen > norm_high AND valuen <= 5.5) OR (valuen < norm_low AND valuen >= 3.0) THEN
     	     	CTC_lab_grade := '1';
          ELSIF (valuen > 5.5 AND valuen <= 6.0) THEN
     			CTC_lab_grade := '2';
	      ELSIF (valuen > 6.0 AND valuen <= 7.0) OR (valuen < 3.0 AND valuen >= 2.5) THEN
     			CTC_lab_grade := '3';
	      ELSIF valuen > 7.0 OR valuen < 2.5 THEN
     			CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
          END IF;
 
       ELSE
  	   	   CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	   CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	   CTC_lab_grade := '0';
       END IF;    
/*
    ELSIF param = 'PROTEIN' THEN
       IF UPPER(unit) = 'MG/24 HR' THEN
          IF (valuen > norm_high AND valuen <= 1000) OR (valuen = '1+') THEN
     	     	CTC_lab_grade := '1';
          ELSIF (valuen > 1000 * norm_high AND valuen <= 3500 * norm_high) OR (valuen IN ('2+','3+')) THEN
     		CTC_lab_grade := '2';
	  ELSIF valuen > 3500 OR (valuen = '4+') THEN
     		CTC_lab_grade := '3';
	  ELSIF indicator IN ('NORANG','NONNUM') THEN
		CTC_lab_grade := '-1';
	  ELSIF valuen < norm_low THEN
		CTC_lab_grade := '0';
	  END IF;
          
       ELSE
	  CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	  CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	  CTC_lab_grade := '0';
       END IF;
*/
    ELSIF param = 'PT' THEN
       IF UPPER(unit) = 'SEC' THEN
          IF valuen > norm_high AND valuen <= 1.5 * norm_high THEN
     	     	CTC_lab_grade := '1';
          ELSIF valuen > 1.5 * norm_high AND valuen <= 2.0 * norm_high THEN
     			CTC_lab_grade := '2';
	      ELSIF valuen > 2.0 * norm_high THEN
     			CTC_lab_grade := '3';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
 	      ELSIF valuen < norm_low THEN
		  		CTC_lab_grade := '-2';
	      END IF;

       ELSE
	   	   CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	  CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	  CTC_lab_grade := '0';
       END IF;    

    ELSIF param = 'PTT' THEN
       IF UPPER(unit) = 'SEC' THEN
          IF valuen > norm_high AND valuen <= 1.5 * norm_high THEN
     	     	CTC_lab_grade := '1';
	      ELSIF valuen > 1.5 * norm_high AND valuen <= 2.0 * norm_high THEN
     			CTC_lab_grade := '2';
	      ELSIF valuen > 2.0 * norm_high THEN
     			CTC_lab_grade := '3';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
	      ELSIF valuen < norm_low THEN
		  		CTC_lab_grade := '-2';
          END IF;
 
       ELSE
  	   	   CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	  CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	  CTC_lab_grade := '0';
       END IF;    
     
    ELSIF param = 'SGGT' THEN
       IF UPPER(unit) in ('U/L','UNITS/L') THEN
          IF valuen > norm_high AND valuen <= 2.5 * norm_high THEN
     	     	CTC_lab_grade := '1';
          ELSIF valuen > 2.5 * norm_high AND valuen <= 5.0 * norm_high THEN
     			CTC_lab_grade := '2';
	      ELSIF valuen > 5.0 * norm_high AND valuen <= 20.0 * norm_high THEN
     			CTC_lab_grade := '3';
	      ELSIF valuen > 20.0 * norm_high THEN
     			CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
	      ELSIF valuen < norm_low THEN
		  		CTC_lab_grade := '-2';
	   END IF;
          
       ELSE
	   	   CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	   CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	   CTC_lab_grade := '0';
       END IF;
    
    ELSIF param = 'SGOT_AST' THEN
       IF UPPER(unit) in ('U/L','UNITS/L') THEN
          IF (valuen > norm_high AND valuen <= 2.5 * norm_high) THEN
     	     	CTC_lab_grade := '1';
          ELSIF (valuen > 2.5 * norm_high AND valuen <= 5.0 * norm_high) THEN
     			CTC_lab_grade := '2';
	      ELSIF (valuen > 5.0 * norm_high AND valuen <= 20.0 * norm_high) THEN
     			CTC_lab_grade := '3';
	      ELSIF valuen > 20.0 * norm_high THEN
     			CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
	      ELSIF valuen < norm_low THEN
		  		CTC_lab_grade := '-2';
          END IF;

       ELSE
	   	   CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	   CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	   CTC_lab_grade := '0';
       END IF;    

    ELSIF param = 'SGPT_ALT' THEN
       IF UPPER(unit) in ('U/L','UNITS/L') THEN
          IF (valuen > norm_high AND valuen <= 2.5 * norm_high) THEN
     	     	CTC_lab_grade := '1';
          ELSIF (valuen > 2.5 * norm_high AND valuen <= 5.0 * norm_high) THEN
     			CTC_lab_grade := '2';
	      ELSIF (valuen > 5.0 * norm_high AND valuen <= 20.0 * norm_high) THEN
     			CTC_lab_grade := '3';
	      ELSIF valuen > 20.0 * norm_high THEN
     			CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
	      ELSIF valuen < norm_low THEN
				CTC_lab_grade := '-2';
          END IF;

       ELSE
	   	   CTC_lab_grade := '-1';
       END IF; 

       IF indicator IS NULL THEN
	   	   CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	   CTC_lab_grade := '0';
       END IF;   

    ELSIF param = 'SODIUM' THEN
       IF UPPER(unit) in ('MMOL/L','MEQ/L') THEN
          IF (valuen > norm_high AND valuen <= 150) OR (valuen < norm_low AND valuen >= 130) THEN
     	     	CTC_lab_grade := '1';
	      ELSIF (valuen > 150 AND valuen <= 155) THEN
     			CTC_lab_grade := '2';
	      ELSIF (valuen > 155 AND valuen <= 160) OR (valuen < 130 AND valuen >= 120) THEN
     			CTC_lab_grade := '3';
	      ELSIF valuen > 160 OR valuen < 120 THEN
     			CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
	      END IF;
           
       ELSE
	   	  CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	  CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	  CTC_lab_grade := '0';
       END IF;
 
    ELSIF param = 'TRIGLYCERIDES' THEN
       IF UPPER(unit) in ('MG/DL','MMOL/L') THEN
          IF valuen > norm_high AND valuen <= 2.5 * norm_high THEN
     	     	CTC_lab_grade := '1';
          ELSIF valuen > 2.5 * norm_high AND valuen <= 5.0 * norm_high THEN
     			CTC_lab_grade := '2';
	  	  ELSIF valuen > 5.0 * norm_high AND valuen <= 10.0 * norm_high THEN
     			CTC_lab_grade := '3';
	      ELSIF valuen > 10.0 * norm_high THEN
     			CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
	      ELSIF valuen < norm_low THEN
		  		CTC_lab_grade := '-2';
	      END IF;

       ELSE
		    CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	  CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	  CTC_lab_grade := '0';
       END IF;    
 
    ELSIF param = 'URIC_ACID' THEN
       IF UPPER(unit) = 'MG/DL' THEN
          IF valuen > norm_high AND valuen <= 10.0 THEN
     	     	CTC_lab_grade := '1';
          ELSIF valuen > 10.0 THEN
     			CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
	      ELSIF valuen < norm_low THEN
		  		CTC_lab_grade := '-2';
          END IF;

       ELSIF UPPER(unit) = 'MMOL/L' THEN
          IF valuen > norm_high AND valuen <= 0.59 THEN
     	     	CTC_lab_grade := '1';
          ELSIF valuen > 0.59 THEN
     			CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
          ELSIF valuen < norm_low THEN
		  		CTC_lab_grade := '-2';
	  	  END IF;
       ELSE 
	   	  CTC_lab_grade := '-1';
       END IF;

       IF indicator IS NULL THEN
	   	  CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	  CTC_lab_grade := '0';
       END IF;
 
    ELSIF param = 'WBC_SERUM' THEN
       IF UPPER(unit) in ('1000/MICROL','1000/MM3','K/UL') THEN
          IF valuen < norm_low AND valuen >= 3.0 THEN
              	CTC_lab_grade := '1';
          ELSIF valuen < 3.0 AND valuen >= 2.0 THEN
              	CTC_lab_grade := '2';
          ELSIF valuen < 2.0 AND valuen >= 1.0 THEN
              	CTC_lab_grade := '3';
          ELSIF valuen < 1.0 THEN
              	CTC_lab_grade := '4';
          ELSIF indicator IN ('NORANG','NONNUM') THEN
		  		CTC_lab_grade := '-1';
	      ELSIF valuen > norm_high THEN
		  		CTC_lab_grade := '-2';
          END IF;
       
       ELSE
       	  CTC_lab_grade := '-1';

       END IF;

       IF indicator IS NULL THEN
	   	  CTC_lab_grade := NULL;
       ELSIF indicator = 'NORMAL' THEN
	   	  CTC_lab_grade := '0';
       END IF;    
 
    ELSE
       CTC_lab_grade := NULL; 

    END IF; /* CTC grading -- Lab parameter names */ 
  
  
  RETURN (CTC_lab_grade);
  	
  EXCEPTION
     WHEN OTHERS THEN
       RETURN (NULL); 
  
  END;

END nci_lab_utility;
/                                                            

SHOW ERROR