/*==========================================================================
 Macro:        ARGUS2SAS()
 ---------------------------------------------------------------------------
 Description:  A macro that determines which text files that are appropriate 
               to import to SAS as SAS datasets. Also "imports" the associated
               HTML reports produced tau-ARGUS by putting them in SAS internal
               browser.

 Parameters:   NONE

 Precondition: No parameters for this macro but this macro make use of 
               parameters that should be assigned in the context where it is
               executed as:
                 OUT      - User request for output from tau-ARGUS
                 JOBNAME  - Users name for this run
                 PATH_TMP - Path to where to find the results

 Comment:      This is the inverse after running tau-Argus from SAS.
               It fetches the text files produced by tau-Argus and establish
               them a SAS-dataset (if appropriate).

 Note:         This macro is a contextual macro as it uses the values of 
               parameters OUT JOBNAME and PATH_TMP

 Changes:      2012-11-20/ak Eliminated the argument GetNames=NO from the
                             call to %READ_DATAFILE since it is not
                             neccesary as the default behavior is NO.
 --------------------------------------------------------------------------*/
%macro Argus2SAS()
   /Des="Determines if the DATA textfiles is to be imported as SAS-datasets";

   /*--------------------------------------------------------------------
    Output
    ---------------------------------------------------------------------
    Note: Loop thru all arguments assigned in OUT so we can accomplish 
          the output the user ask for. At this moment the string supplied 
          have been checked for accuracy by the macro CHECK_PARAMETERS. 
    --------------------------------------------------------------------*/
   %let _nr=1;
   %let _out=%upcase(%scan(&OUT.,&_nr.,%str( )));

   %do %until (&_out=);

      /*-----------------------------------------------------------------
       Reveal the TYPE
       Not: Remove the option argument togheter with parenthesis i.e. '(1)'  
       -----------------------------------------------------------------*/
      %let _type=%sysfunc(prxchange(s/\(|\d+|\)//i,-1,%bquote(&_out)));

      /*-----------------------------------------------------------------
       Reveal the PARM       
       -----------------------------------------------------------------*/
      %let _pos =%sysfunc(prxmatch(/\d+/, &_out));
      %if &_pos > 1 %then %let _parm=%substr(&_out,&_pos,1);
                    %else %let _parm=0;

      /*-----------------------------------------------------------------
       Execute READ_DATAFILE and PRESENT_HTML
       -----------------------------------------------------------------*/
      %if &SAS.=1 or &SAS.=2 %then %do;
         %if &_type.=TABLE %then %do;
            /* Not suitable for SAS as it is an inconsistence matrix according
               to variable names and data within the file. 
               It suites a spreadsheet like Excel better */
            %Present_HTML (Htmlfile=%bquote(&PATH_tmp.\&jobname._Out_1_&_parm..html))
         %end;

         %else %if &_type.=PIVOT %then %do;
            *%Read_Datafile(Datafile=%bquote(&PATH_tmp.\&jobname._Out_2_&_parm..csv),GetNames=YES);
            %Present_HTML (Htmlfile=%bquote(&PATH_tmp.\&jobname._Out_2_&_parm..html))
         %end;

         %else %if &_type.=CODE %then %do;
            *%Read_Datafile(Datafile=%bquote(&PATH_tmp.\&jobname._Out_3_&_parm..csv),GetNames=NO);
            %Present_HTML (Htmlfile=%bquote(&PATH_tmp.\&jobname._Out_3_&_parm..html))
         %end;

         %else %if &_type.=SBS %then %do;
            *%Read_Datafile(Datafile=%bquote(&PATH_tmp.\&jobname._Out_4_&_parm..csv),GetNames=NO);
            %Present_HTML (Htmlfile=%bquote(&PATH_tmp.\&jobname._Out_4_&_parm..html))
         %end;

         /*-----------------------------------------------------------------
          This is the only format worth importing back to SAS
          -----------------------------------------------------------------*/
         %else %if &_type.=INTER %then %do;
            %if &SAS=2 %then %do;
               /* Change: No optional argument as GETNAMES=NO since default from here */
               %Read_Datafile(Datafile=%bquote(&PATH_tmp.\&jobname._Out_5_&_parm..csv));
            %end;
            %Present_HTML (Htmlfile=%bquote(&PATH_tmp.\&jobname._Out_5_&_parm..html))
         %end;

         %let _nr=%eval(&_nr+1);
         %let _out=%bquote(%upcase(%scan(&OUT,&_nr,%str( ))));

      %end;

   %end;

%mend Argus2SAS;
