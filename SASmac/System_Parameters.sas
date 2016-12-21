/*==========================================================================
 Macro:        System_Parameters
 ---------------------------------------------------------------------------
 Description:  A macro that checks the initial parameters set before running
               SAS2ARGUS, namely PATH_EXE and PATH_TMP. The check the path to 
               tau-ARGUS EXE file and that the file do exist.
                  
 Parameters:   NONE

 Precondition: PATH_EXE assumed to be set before executing this macro.
                               
 Comment:      We also refer to the macro variable &_DATASET, that stores the
               name of the dataset, to eventually point out the dataset and
               the variables if variables can't be found.

 Note:         If PATH_TMP not set then we set the temporary workpath to the 
               same destination as SAS WORK. 
 --------------------------------------------------------------------------*/
%macro System_Parameters()
   /Des="Checks the initial argument to SAS2ARGUS";

   %global PATH_exe PATH_tmp;
   %local  _set _options;

   /*=======================================================================
    Check if the full PATH to tau-Argus exe is present so we can find it
    -----------------------------------------------------------------------*/
   %if %nrstr(&PATH_exe.)=%str() %then %do;
      %put ERROR: ===========================================================================;
      %put ERROR: Macro: [&sysmacroname];
      %put ERROR: ---------------------------------------------------------------------------;
      %put ERROR: Macro PATH_EXE is not set.;
      %put ERROR: PATH_EXE have to be set in order to find the tau-ARGUS executable;
      %put ERROR: ===========================================================================;
   %end;

   /*=======================================================================
    Check if the EXE file for tau-Argus is present so we can use it
    -----------------------------------------------------------------------*/
   %else %do;
      %if not %sysfunc(fileexist(%str(&PATH_exe))) %then %do;
         /*-----------------------------------------------------------------
          Check if we can find the exe in this location instead
          -----------------------------------------------------------------*/
	     %if %sysfunc(fileexist(%str(C:\Program Files (x86)\TauArgus\TauArgus.exe))) %then %do;
		    %let PATH_exe=C:\Program Files (x86)\TauArgus\TauArgus.exe;
			%let _notes=%sysfunc(getoption(NOTES));
		   options notes; 
		   %put NOTE: ===========================================================================;
		   %put NOTE: Macro: [&sysmacroname];
		   %put NOTE: ---------------------------------------------------------------------------;
		   %put NOTE: tau-ARGUS EXE_path is:;
		   %put NOTE:    &PATH_EXE.;
		   %put NOTE: ===========================================================================;
		   options &_notes.;
		 %end;
		 %else %do;
	         %put ERROR: ===========================================================================;
	         %put ERROR: Macro: [&sysmacroname];
	         %put ERROR: ---------------------------------------------------------------------------;
	         %put ERROR: Macro PATH_EXE is set but the EXE file for tau-ARGUS can not be found.;
	         %put ERROR: ===========================================================================;
		 %end;
      %end;
   %end;


   /*=======================================================================
    Is PATH_tmp (work path) set? 
    -----------------------------------------------------------------------*/
   %if not %symexist(PATH_tmp)         %then %let _set=1;
   %else %if %nrstr(&PATH_tmp.)=%str() %then %let _set=1;  

   /*-----------------------------------------------------------------------
    If not PATH_tmp not set => Set PATH_tmp to the same path as SAS work
    -----------------------------------------------------------------------*/
   %if &_set=1 %then %do;
      %let PATH_tmp=%sysfunc(pathname(WORK));
   %end;

   /*-----------------------------------------------------------------------
    Report the tau-ARGUS workpath and filenames to the log
    -----------------------------------------------------------------------*/
   %let _notes=%sysfunc(getoption(NOTES));
   options notes; 
   %put NOTE: ===========================================================================;
   %put NOTE: Macro: [&sysmacroname];
   %put NOTE: ---------------------------------------------------------------------------;
   %put NOTE: tau-ARGUS work path is:;
   %put NOTE:    &PATH_tmp;
   %put NOTE: ===========================================================================;
   options &_notes.;

%mend System_parameters;
