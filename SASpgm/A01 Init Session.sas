/*==========================================================================
 Program:      A01 Init Session.sas
 ---------------------------------------------------------------------------
 Description:  Initialise the SAS session

 Comment:      Sets up the session, initial path on disk, 
               Sets global system parameters
 
 Parameters:   Path_SAS - The path to the generic part
               Path_APP - The path to the application part 

 Purpose:      Maintenance

 Precondition: None

 Usage:        Set the initial path on disk for this session

 Initial code: Fredrik Bernström SCB/IT/1
 Revised code: Anders Kraftling  SCB/IT/1
 Date:         2010-08-27
 Comment:      
 ---------------------------------------------------------------------------
 Changes:      
 ==========================================================================*/


/*==========================================================================
 Full path to tau_Argus executable
 --------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------
%let PATH_exe=C:\Program\TauArgus\tauARGUS.exe;
 --------------------------------------------------------------------------*/


/*==========================================================================
 Path to location of SAS macros and SAS programs
 SYSpgm  = Where the generic SAS-programs are stored    (for include) 
 SYSmac  = Where the generic SAS-macros are to be found (for autosource)
 Note: Sysfunc used to get rid of the ERROR if rerun in the same session:
 ERROR: At least one file associated with fileref SYSMAC is still in use.
 ERROR: Error in the FILENAME statement.
 --------------------------------------------------------------------------*/
%macro Fileref/Des="Sets filename reference";
   %let _ref=SASpgm; %let _rc=%sysfunc(filename(_ref, &PATH_sys.\SASpgm));
   %let _ref=SASmac; %let _rc=%sysfunc(filename(_ref, &PATH_sys.\SASmac));
%mend;
%Fileref;
proc catalog cat=work.sasmacr; delete fileref.macro; run; quit; 


/*==========================================================================
 Macro options for both compiled macros and autosource. 
 Note: At the moment we just use the SAS autosource facility
 --------------------------------------------------------------------------*/
*libname  SASmac "&Path_sys.\SASmac" access=readonly;
*options mstored sasmstore=SASmac;
options mautosource sasautos=(SASAUTOS SASmac);







