/*==========================================================================
 Macro:        SAS2Argus_Help()
 ---------------------------------------------------------------------------
 Description:  A macro that boost information about the macro to the log

 Parameters:   NONE

 Precondition: NONE

 Comment:      Some documention of this macro.
 --------------------------------------------------------------------------*/
%macro SAS2Argus_Help();
   filename _help "&PATH_sys.\SASmac\SAS2Argus.txt";

   %let _notes=%sysfunc(getoption(NOTES));
   option &GLOBAL_NOTES.;

   data _null_;
      infile _help lrecl=80 pad end=_eof;
      input  _txt $Char80.;

      if _n_=1 then do;
         putlog "NOTE: ===========================================================================";
         putlog "NOTE: Macro: [&sysmacroname]";;
         putlog "NOTE: ---------------------------------------------------------------------------";
         putlog "NOTE: Help for SAS2ARGUS macro";
         putlog "NOTE: ===========================================================================";
      end;

      putlog _txt $Char80.;

      if _eof then do;
         putlog "NOTE: ===========================================================================";
         putlog "NOTE: Macro: [&sysmacroname]";;
         putlog "NOTE: ---------------------------------------------------------------------------";
         putlog "NOTE: End of help for SAS2ARGUS macro";
         putlog "NOTE: ===========================================================================";
      end;
   run;

   option &_notes;
%mend;
%SAS2Argus_Help();
