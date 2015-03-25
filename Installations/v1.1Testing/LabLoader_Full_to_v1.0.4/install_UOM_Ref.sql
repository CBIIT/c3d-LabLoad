/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Author: Patrick Conrad (Ekagra Software Technologies)                 */
/* Date:   Dec. 12, 2005                                                 */
/* Description: This is the installation script for the Unit of Measure  */
/*              Reference table.  This table under the legacy C3D arena  */
/*              is normal owned by RXC.  This script allows for the      */
/*              table to be created under the Lab Loader umbrella.       */
/*                                                                       */
/* NOTE:  The following files should be placed into the same             */
/*                  directory. Before this file is execute, the install  */
/*                  directory should be the default directory.           */
/* FILES:                                                                */
/*        Install_UOM_Ref.sql - This file.                               */
/*        NCI_UOM_MAIN.sql - The primary Unit of Measure Table           */
/*        NCI_UOM_MAIN_DATA.SQL - The Unit of Measure Data               */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
/* Modification History:                                                 */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

-- Added condition to exit when error.  Just incase run accidently.
WHENEVER SQLERROR EXIT

-- Spool a log file
spool install_UOM_Ref.lst

Select to_char(sysdate,'MM/DD/YYYY HH24:MI:SS') "Execution Date", User "User"
  from dual;
  
--install the primary table
Prompt ...Installing Primary UOM Table
@NCI_UOM_MAIN.sql

-- Load Primary Table with data
Prompt ...Installing Primary UOM Data
@NCI_UOM_MAIN_DATA.sql

spool off

PROMPT
PROMPT FINISHED!
PROMPT

