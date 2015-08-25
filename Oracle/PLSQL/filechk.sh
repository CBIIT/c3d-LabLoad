#!/bin/csh
set filedt=`ls -l /share/ocdata/CDWDATA/CDWDATA/NCIC3D_cdr.vw_lab_results_current.txt | awk '{print $6$7}'`
#echo filedt $filedt
set filecrdt=`ls -l /share/ocdata/CDWDATA/CDWDATA/NCIC3D_cdr.vw_lab_results_current.txt | awk '{print $6, $7, $8}'`
set now=`date | awk '{print $2$3}'`
set runtime=`date`
#echo now $now
set lastjobrundt=`cat /share/ocdata/CDWDATA/CDWDATA/datejobrun.log`
#echo lastjobrundt $lastjobrundt
if ($now != $filedt) then
	echo "Today's File generation not complete"
else 
	if ($now != $lastjobrundt) then
		echo Running Job
		echo $now > /share/ocdata/CDWDATA/CDWDATA/datejobrun.log
                cp /share/ocdata/CDWDATA/CDWDATA/NCIC3D_cdr.vw_lab_results_current.txt /share/ocdata/CDWDATA/CDWDATA/NCIC3D_cdr.vw_lab_results_current$now.txt 
		echo "Lab Loader file created at $filecrdt. Lab loader Job started at $runtime..." | mailx -s "Lab Loader Job Started" milind.bendigeri@nih.gov katie.grant@nih.gov 
		echo exit | sqlplus /@ocprod.nci.nih.gov @/share/ocdata/CDWDATA/CDWDATA/submitjob.sql
                
                echo "Sending Error Report"
                cat /tmp/ErrRpt.txt | mailx -s "Lab Loader Report" milind.bendigeri@nih.gov katie.grant@nih.gov liul@mail.nih.gov andonyac@mail.nih.gov liusi@mail.nih.gov
        else
		echo Job Already run
	endif
endif
