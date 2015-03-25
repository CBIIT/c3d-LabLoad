LOAD DATA

INFILE 'GTown_Labs.dat'
BADFILE 'GTown_Labs.bad'
DISCARDFILE 'GTown_Labs.dsc'

REPLACE

INTO TABLE GU_LAB_RESULTS_HOLD
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
MRN,
C3D_Lab_Name,
GU_Lab_ID,
Short_Name,
Long_Name,
Sample_Date_raw,
Sample_Time_raw,
Result,
Hi_Low,
Range,
Units_raw
)
