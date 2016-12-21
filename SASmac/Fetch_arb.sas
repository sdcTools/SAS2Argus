/*==========================================================================
 Macro:        Fetch_Arb(Arbfile)
 ---------------------------------------------------------------------------
 Description:  A macro that fetches the tau-ARGUS commandg file and includes 
               it in the SAS log.

 Parameters:   ARBFILE  - The name of the ARB-file        (fully qualified)

 Precondition: The ARBFILE should exist

 Comment:      After the ARB-file for tau-ARGUS is included in the SAS log it
               is easier to:
                 1. To be able to see the outcome of the last run of 
                    constructing the file for tau-ARGUS from "within" SAS.
                 2. If the SAS log is saved then the whole context of the run 
                    is saved in one place.

 Note:         The idea is to run this when the flag DEBUG is set to 1 in
               SAS2ARGUS for a easy debugging.
 --------------------------------------------------------------------------*/
%macro Fetch_arb(arbfile)
   /Des="Includes tau-ARGUS ARB-file in SAS log";

   %local _notes;
   %let _notes=%sysfunc(getoption(notes));
   options &GLOBAL_NOTES.;

   /*-----------------------------------------------------------------------
    Keep the log clean if GLOBAL_NOTES=NONOTES;
    -----------------------------------------------------------------------*/
   %if %upcase(&GLOBAL_NOTES.)=NOTES %then %do;
      data _null_;
         infile "&arbfile" lrecl=200 pad end=_eof;
         input _logtext $Char200.;
         if _n_=1 then do;
            putlog "NOTE: ===========================================================================";
            putlog "NOTE: Macro: [&sysmacroname]";
            putlog "NOTE: ---------------------------------------------------------------------------";
            putlog "NOTE: Here follows the established ARB-file for tau-ARGUS";
            putlog "NOTE: ===========================================================================";
         end;
         putlog _logtext;
         if _eof then do;
            putlog "NOTE: ===========================================================================";
            putlog "NOTE: END of tau-ARGUS ARB-file";
            putlog "NOTE: ===========================================================================";
         end;
      run;
   %end;

   options &_notes.;
%mend Fetch_arb;
