/*==========================================================================
 Macro:        Write_Jobfile(Jobfile)
 ---------------------------------------------------------------------------
 Description:  A macro that writes the batch command file for tau-ARGUS 
               (suffix ARB) which describes the parameters and the work flow.

 Parameters:   JOBFILE  - Name of command file        (fully qualified)

 Precondition: The _VARIABLES_META dataset has to exist since we are using
               this to fetch the variable names for the EXPLANATORY variables.
               See also the comment.

 Comment:      This macro is depending on the context where it is executed
               since we assume the availability of SAS macro variables assigned
               in the moment we run this. Of course it is possible to assign
               all those macro variables manually and then run this macro.
 Note:         
 Change:       2012-10-23/ak Advice from Anco to not use the argument of 1
                             at card <READTABLE> in the ARB-file. 
                             If the (only) parameter is set to 1 the 
                             "compute missing totals" procedure will be used. 
                             Ie "T". 
               2013-06-11/ak The parameter "compute missing totals" is reset
 --------------------------------------------------------------------------*/

/*--------------------------------------------------------------------
CHANGES FOR VERSION 4.0

2016-11-09/L-E.A    Removed <LOGFILE> because it doesn´t work
                    Added compress in <SAFETYRULE>
                    Removed &_parm in the third parameter in <WRITEFILE>

CHANGES FOR VERSION 4.1
2016-12-19/L-E.A    <LOGFILE> works without "" round the file name.
                    Removed two "" round the path for <LOGFILE>.
 --------------------------------------------------------------------*/

%macro Write_Jobfile(Jobfile)
   /Des="Defines and writes the tau-Argus command file (ARB)";

   %local _Explanatory 
          _Respons
          _Shadow
          _Cost    
          _Lambda
          _SafetyRule
          _Secondary;


   /*=======================================================================
    Prepare for to build <SPECIFYTABLE>
    ------------------------------------------------------------------------
    Find out what variables we have definied for roles i _VARIABLES_META
    so we can specify the table in the command file in the tag <SPECIFYTABLE>
    Note: The specification for <SPECIFYTABLE> is:

          "ExpVar1""ExpVar2""ExpVar3"|RespVar|ShadowVar|CostVar

          where ShadowVar and CostVar is OPTIONAL. If not set then those
          are the same as the RespVar. Another scenario is that no Response
          variable is given but Frequency, then Response=Frequency. This
          is checked in Check_Parameters that we have at least one of those.

          COST can be:
             VarName     - Name of variable used for cost (turnover e.g)
             -1          - Constant meaning that cost is based on FREQUENCY
             -2          - Constant meaning that cost is based on UNITY 
                           i.e. number of cells or domains
          if COST is a CONSTANT then we have set _COSTBASE earlier so we
          are able to handle that fact here.
    -----------------------------------------------------------------------*/
   %if &response.=%str() %then %let _Response = &Frequency;
                         %else %let _Response = &Response;

   %if &shadow.  =%str() %then %let _Shadow   = &_Response;                         
                         %else %let _Shadow   = &Shadow;

   %if &cost.    =%str() %then %let _Cost     = &_Response;                           
                         %else %let _Cost     = &Cost;

   %if &lambda.  =%str() %then %let _Lambda   = 1;
                         %else %let _Lambda   = &Lambda;

   /*-----------------------------------------------------------------------
    Even thou tau-ARGUS don't seem to complain. Add the minus-sign again 
    here (according to the syntax) if it is missing.
    -----------------------------------------------------------------------*/
   %if &_Cost=1 %then %let _Cost = -1;
   %if &_Cost=2 %then %let _Cost = -2;

   /*-----------------------------------------------------------------------
    Get the variable names for EXPLANATORY from _VARIABLES_META
    -----------------------------------------------------------------------*/
   proc sql noprint;
      select VarNameTAU into :_Explanatory separated by ' '
         from work._Variable_Meta
         where VarRole="EX";
   quit;

   /*-----------------------------------------------------------------------
    Quote the arguments for <SPECIFYTABLE>
    -----------------------------------------------------------------------*/
   %let _Explanatory = %clean_parameters(&_Explanatory,qn);
   %let _Response    = %clean_parameters(&_Response,qn);
   %let _Shadow      = %clean_parameters(&_Shadow,qn);
   %let _Cost        = %clean_parameters(&_Cost,qn);


   /*=======================================================================
    Write the ARB file for tau-ARGUS
    -----------------------------------------------------------------------*/
   filename _TAU_ARB "&PATH_tmp.\&jobname..ARB";
   data _null_;

      /*--------------------------------------------------------------------
       <SPECIFYTABLE>
       --------------------------------------------------------------------*/
      _explanatory  = compress(symget('_Explanatory'));
      _response     = compress(symget('_Response'));
      _shadow       = compress(symget('_Shadow'));
      _cost         = compress(symget('_Cost'));
      _specifytable = cats(_explanatory,'|',_response,'|',_shadow,'|',_cost,',',&_lambda);

      file _TAU_ARB;
         put @1 "//===============================================================================";
         put @1 "// This job based on dataset: &_dataset";
         put @1 "//-------------------------------------------------------------------------------";


         put @1 "<LOGBOOK>"         @18 "&PATH_tmp.\&jobname..LOG";                   /* 4.1/L-E.A    Removed two "" round the path */  
         /*put @1 "<LOGBOOK>"         @18 """&PATH_tmp.\&jobname..LOG""";*/           /* Alternative */

      /*--------------------------------------------------------------------
       <OPENMICRODATA> or <OPENTABLEDATA> 
       --------------------------------------------------------------------*/
      %if &_table. %then %do;
         put @1 "<OPENTABLEDATA>"   @18 """&PATH_tmp.\&jobname..CSV""";
      %end;
      %else %do;
         put @1 "<OPENMICRODATA>"   @18 """&PATH_tmp.\&jobname..CSV""";
      %end;


      /*--------------------------------------------------------------------
       <OPENMETADATA>
       --------------------------------------------------------------------*/
         put @1 "<OPENMETADATA>"    @18 """&PATH_tmp.\&jobname..RDA""";
         put;


      /*--------------------------------------------------------------------
       <SPECIFYTABLE>. No safetyrole set => A secondary suppression request
       --------------------------------------------------------------------*/
         put @1 "<SPECIFYTABLE>"    @18 _specifytable;
         put;


      /*--------------------------------------------------------------------
       <SAFETYRULE>. No safetyrole set => A secondary suppression request
       Note: First two P-rules for entities. Third is for the holding 
       --------------------------------------------------------------------*/
      %if %length(&safetyrule.) %then %do;
         put @1 "<SAFETYRULE>"      @18 %sysfunc(compress("&Safetyrule"));                          /* 4.0/L-E.A    Added compress */
      %end;


      /*--------------------------------------------------------------------
       <READTABLE>
       Change 2012-10-23/ak Advice from Anco to not use the argument of
                            table number. If the (only) parameter is set to 
                            1 the "compute missing totals" procedure will be 
                            used. Ie "T". 
       Change 2013-06-11/ak The parameter "compute missing totals" is reset
       --------------------------------------------------------------------*/
      %if &_table. %then %do;
         put @1 "<READTABLE>      1";
      /* put @1 "<READTABLE>";  */  
      %end;
      %else %do;
         put @1 "<READMICRODATA>";
      %end;


      /*--------------------------------------------------------------------
       <SUPPRESS>
       --------------------------------------------------------------------*/
      %if %length(&suppress.) %then %do;
         put @1 "<SUPPRESS>"        @18 "&Suppress";
         put;
      %end;


      /*--------------------------------------------------------------------
       Output
       ---------------------------------------------------------------------
       Note: Loop thru all arguments assigned in OUT so we can accomplish 
             the output the user ask for. At this moment the string supplied 
             have been checked for accurancy by the macro CHECK_PARAMETERS. 
       --------------------------------------------------------------------*/
      %let _nr=1;
      %let _out=%upcase(%scan(&OUT.,&_nr.,%str( )));

      %do %until (&_out=);
         /*-----------------------------------------------------------------
          Reveal the TYPE       
          -----------------------------------------------------------------*/
         %let _type=%sysfunc(prxchange(s/\(|\d+|\)//i,-1,%bquote(&_out)));

         /*-----------------------------------------------------------------
          Reveal the PARM       
          -----------------------------------------------------------------*/
         %let _pos =%sysfunc(prxmatch(/\d+/, &_out));
         %if &_pos > 1 %then %let _parm=%substr(&_out,&_pos,1);
                       %else %let _parm=0;

         /*-----------------------------------------------------------------
          <WRITETABLE>
          -----------------------------------------------------------------*/
         %if &_type.=TABLE %then %do;
            put @1 "<WRITETABLE>"   @18 "(1,1,,""" "&PATH_tmp.\&jobname._Out_1_&_parm..csv" '")';                       /* 4.0/L-E.A    Removed &_parm */
         %end;
         %if &_type.=PIVOT %then %do;
            put @1 "<WRITETABLE>"   @18 "(1,2,,""" "&PATH_tmp.\&jobname._Out_2_&_parm..csv" '")';                       /* 4.0/L-E.A    Removed &_parm */
         %end;
         %if &_type.=CODE %then %do;
            put @1 "<WRITETABLE>"   @18 "(1,3,,""" "&PATH_tmp.\&jobname._Out_3_&_parm..csv" '")';                       /* 4.0/L-E.A    Removed &_parm */
         %end;
         %if &_type.=SBS %then %do;
            put @1 "<WRITETABLE>"   @18 "(1,4,,""" "&PATH_tmp.\&jobname._Out_4_&_parm..csv" '")';                       /* 4.0/L-E.A    Removed &_parm */
         %end;
         %if &_type.=INTER %then %do;
            put @1 "<WRITETABLE>"   @18 "(1,5,,""" "&PATH_tmp.\&jobname._Out_5_&_parm..csv" '")';                       /* 4.0/L-E.A    Removed &_parm */
         %end;

         %let _nr=%eval(&_nr+1);
         %let _out=%bquote(%upcase(%scan(&OUT,&_nr,%str( ))));

      %end;

/*--------------------------------------------------------------------------
         put @1 "<WRITETABLE>"      @18 "(1,1,1,""" "&PATH_tmp.\&jobname._Out_1_1.csv" '")';
         put @1 "<WRITETABLE>"      @18 "(1,5,1,""" "&PATH_tmp.\&jobname._Out_5_1.csv" '")';
 --------------------------------------------------------------------------*/

   run;

%mend Write_Jobfile;
