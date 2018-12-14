/*==========================================================================
 Macro:        Fetch_Log(Logfile)
 ---------------------------------------------------------------------------
 Description:  A macro that fetches the tau-ARGUS log file and includes 
               it in the SAS log.

 Parameters:   LOGFILE  - The name of the LOG-file        (fully qualified)

 Precondition: The LOGFILE should exist

 Comment:      After the log from tau-ARGUS is included in the SAS log it
               is easier to:
                 1. To be able to see the outcome of the last run of 
                    tau-ARGUS from "within" SAS.
                 2. If the log is saved then the whole context of the run 
                    is saved in one place.

 Note:         The idea is to run this when the flag DEBUG is set to 1 in
               SAS2ARGUS for a easy debugging.
 --------------------------------------------------------------------------*/
%macro Fetch_log(logfile)
   /Des="Includes tau-ARGUS LOG-file in SAS log";

   %local _notes;
   %let _notes=%sysfunc(getoption(notes));
   options &GLOBAL_NOTES.;

   /*=======================================================================
    Check first it the file exists
    -----------------------------------------------------------------------*/
   %let _fname=_temp;
   %let _rc=%sysfunc(filename(_fname,&logfile));
   %if  &_rc=0 and %sysfunc(fexist(&_fname)) %then %do;

      /*--------------------------------------------------------------------
       Keep the log clean if GLOBAL_NOTES=NONOTES;
       --------------------------------------------------------------------*/
      %if %upcase(&GLOBAL_NOTES.)=NOTES %then %do;
         data _null_;
            infile "&logfile" lrecl=200 pad end=_eof;
            input _logtext $Char200.;
            if _n_=1 then do;
               putlog "NOTE: ===========================================================================";
               putlog "NOTE: Macro: [&sysmacroname]";
               putlog "NOTE: ---------------------------------------------------------------------------";
               putlog "NOTE: Here follows the LOG-file from the last run of tau-ARGUS";
               putlog "NOTE: ===========================================================================";
            end;
            putlog _logtext;
            if _eof then do;
               putlog "NOTE: ===========================================================================";
               putlog "NOTE: END of tau-ARGUS LOG-file";
               putlog "NOTE: ===========================================================================";
            end;
         run;
      %end;
   %end;
   %else %do;
      %put NOTE: ===========================================================================;
      %put NOTE: Macro: [&sysmacroname];
      %put NOTE: ---------------------------------------------------------------------------;
      %put NOTE: The log file [&logfile] from Tau-Argus do not exist!;
      %put NOTE: ===========================================================================;
   %end;

   options &_notes.;
%mend Fetch_log;
