/*==========================================================================
 Macro:       Check_TauLog.sas
 ---------------------------------------------------------------------------
 Description: A macro that checks the TauArgus log to see that we really 
              did run the optimiser (Xpress)

 Parameters:  The log

 Comment:     Assigns the value XPRESS=0 if all went good
              Assigns the value XPRESS=1 if we were't able to run Xpress
 
 Note:        
 ---------------------------------------------------------------------------
 Changes:     
 --------------------------------------------------------------------------*/
%macro Check_TauLog(Logfile);

   %let _notes=%sysfunc(getoption(NOTES));
   %let _source=%sysfunc(getoption(SOURCE));

   /*=======================================================================
    Check first it the file exists
    -----------------------------------------------------------------------*/
   %let _fname=_log;
   %let _rc=%sysfunc(filename(_fname,&Logfile));
   %if  &_rc=0 and %sysfunc(fexist(&_fname)) %then %do;
      options nonotes nosource;
      data _null_;
         infile  _log lrecl=250 pad end=eof;

         retain Xpress "0";
         retain Abend  "0";

         input txt $250.;

        /*--------------------------------------------------------------------
         Check for Xpress errors
         --------------------------------------------------------------------*/
         if indexw(_infile_,"Unable to initialize XPress")   then Xpress="1";

        /*--------------------------------------------------------------------
         Check for other errors
         --------------------------------------------------------------------*/
         if indexw(_infile_,"Program abnormally terminated") then Abend="1";

         if eof then do;
            call symput('XPress',Xpress);
            call symput('Abend',Abend);
         end;

      run;
      option &_notes;

      %if &Xpress. %then %do;
         %put ERROR: ===========================================================================;
         %put ERROR: Macro: [&sysmacroname];
         %put ERROR: ---------------------------------------------------------------------------;
         %put ERROR: Note that TauArgus was unable to initialize XPress;
         %put ERROR: More active users then the licence admit;
         %put ERROR: ===========================================================================;
      %end;

      %if &Abend. %then %do;
         %put ERROR: ===========================================================================;
         %put ERROR: Macro: [&sysmacroname];
         %put ERROR: ---------------------------------------------------------------------------;
         %put ERROR: Note that TauArgus was unable to finish the job without errors;
         %put ERROR: Check the TauArgus log;
         %put ERROR: ===========================================================================;
      %end;

      %symdel Xpress/NoWarn;
      %symdel Abend/NoWarn;

      option &_source;

   %end;

%mend Check_TauLog;

