/*==========================================================================
 Macro:        Write_Datafile(Dataset, Datafile, [Metafile])
 ---------------------------------------------------------------------------
 Description:  A macro that writes the SAS dataset to a comma separated (CSV)
               text file and also describes this data in a metadata file (RDA)
               that tau_Argus can interpretate.

 Parameters:   DATASET  - DATASET   to write          (fully qualified)
               DATAFILE - DATA file to write          (fully qualified path)
              [METAFILE]- Optional. Name of META FILE (fully qualified path)

 Precondition: The dataset _VARIABLE_META has to exist which is used to 
               evaluate which variables and which roles the file is intended
               to describe.

 Comment:      The dataset _Variable_Meta has to be establised descriping the
               roles of variables and meta data information needed. If no meta 
               file name given as argument, we use the name of the data file 
               and substitute any given file suffix with .RDA.

 Note:         The suffix (.RDA or .CSV) could be given in the argument of
               the filenames and the recommendation is to keep to the "standard" 
               i.e. <datafilename>.CSV for the data and 
                    <metafilename>.RDA for the meta data respectively.
 ---------------------------------------------------------------------------
 Changes:      2012-10-16/ak HierLevels now works even if entered numeric thou
                             TauArgus always expect it to be char. But only
                             for one occurcy of a HierLevels parameter.
 --------------------------------------------------------------------------*/

/*--------------------------------------------------------------------
CHANGES FOR VERSION 4.0

2016-11-09/L-E.A    Removed " around VarName, row 545
                    Removed _Varmiss (999999) as missing because we don´t need it. It only creates problems.

CHANGES FOR VERSION 4.1

2016-12-20/L-E.A    Removed <SHADOW> and <COST> in the metadata file when we use microdata
 --------------------------------------------------------------------*/


/*#########################################################################*/
%macro Write_Datafile(Dataset=, Datafile=, Metafile=)
   /Des="Exports a SAS-dataset to DATA text and a META DATA file";

   /*=======================================================================
    Declare local variabels
    -----------------------------------------------------------------------*/
   %local _totcode _error _option;

   /*-----------------------------------------------------------------------
    Quote DATASET since it maybe is holding a WHERE statement. This is a way
    to hide away parenthesis, commas and quotes (which could be there)
    -----------------------------------------------------------------------*/
   %let dataset=%bquote(&dataset);

   /*=======================================================================
    Check that there is a value for parameter DATASET (and that it exists).
    -----------------------------------------------------------------------*/
   %let _error=0;
   %if &Dataset=%str() %then %do;
      %let _option=%sysfunc(getoption(NOTES));
      option &GLOBAL_NOTES.;
      %put NOTE: ===========================================================================;
      %put NOTE: Macro: [&sysmacroname];
      %put NOTE: ---------------------------------------------------------------------------;
      %put NOTE: Value for parameter DATASET is missing;
      %put NOTE: ===========================================================================;
      option &_option;
      %goto exit;
   %end;

   /*-----------------------------------------------------------------------
    Does the dataset exist?
    Note: There could be a dataset option like WHERE, OBS, RENAME. Remove
          any eventuell dataset option from the argument before check of
          the existens of the dataset.
    -----------------------------------------------------------------------*/
   %else %do;
      %let _pos=%sysfunc(indexc(&dataset,'('));
      %if &_pos.>0 %then %let _dataset=%substr(%bquote(&dataset),1,%eval(&_pos-1));
      %else              %let _dataset=%bquote(&dataset);

      %if not %sysfunc(exist(&_dataset.)) %then %do;
         %put ERROR: ===========================================================================;
         %put ERROR: Macro: [&sysmacroname];
         %put ERROR: ---------------------------------------------------------------------------;
         %put ERROR: The Libname or the Dataset [&_dataset] do not exist;
         %put ERROR: ---------------------------------------------------------------------------;
         %let _error=1;
         %goto exit;
      %end;
   %end;


   /*=======================================================================
    Check that there is a value for parameter DATAFILE. Name of CSV-file
    -----------------------------------------------------------------------*/
   %if %nrstr(&Datafile.)=%str() %then %do;
      %let _option=%sysfunc(getoption(NOTES));
      option &GLOBAL_NOTES.;
      %put NOTE: ===========================================================================;
      %put NOTE: Macro: [&sysmacroname];
      %put NOTE: ---------------------------------------------------------------------------;
      %put NOTE: Value for parameter DATAFILE is missing;
         %put ERROR: ---------------------------------------------------------------------------;
      option &_option.;
      %goto exit;
   %end;

   /*-----------------------------------------------------------------------
    Check that there is a suffix (CSV or whatever). Otherwise add:
       CSV - for TABLE DATA
       ASC - for MICRO DATA
     ...according to some convention within Tau-ARGUS.
    -----------------------------------------------------------------------*/
   %else %do;
      %let _pos=%sysfunc(prxmatch(%str(/\.[a-zåäöÅÄÖ]+$/i),&Datafile));
      %if &_pos=0 %then %do;
         %let _Datafile=&Datafile..CSV;
/*--------------------------------------------------------------------------
         %if &_table. %then %let _Datafile=&Datafile..CSV;
                      %else %let _Datafile=&Datafile..ASC;
 --------------------------------------------------------------------------*/
      %end;   
      %else %let _Datafile=&Datafile;
   %end;


   /*=======================================================================
    Check if there is an explicit named META DATA file in the invocation.
    If not the assumtion is that the META DATA file is to be found in the 
    same folder and have the same name - but with suffix .RDA
    -----------------------------------------------------------------------*/
   %if &Metafile=%str() %then %do;

      /*--------------------------------------------------------------------
       Remove any suffix if present and add the suffix of RDA
       --------------------------------------------------------------------*/
      %let _Metafile=%sysfunc(prxchange(%str(s/\.[a-zåäöÅÄÖ]+$//i),1,&Datafile));
      %let _Metafile=&_Metafile..RDA;

   %end;
   %else %do;
      %let _Metafile=&Metafile;
   %end;


   /*-----------------------------------------------------------------------
    Check for the existence of the _VARIABLE_META dataset in work since we
    could not do without it in this context.
    -----------------------------------------------------------------------*/
   %if not %sysfunc(exist(WORK._variable_meta)) %then %do;
      %put ERROR: ===========================================================================;
      %put ERROR: Macro: [&sysmacroname];
      %put ERROR: ---------------------------------------------------------------------------;
      %put ERROR: The dataset WORK._VARIABLE_META has to exist and can not be found.;
      %put ERROR: ---------------------------------------------------------------------------;
      %goto exit;
   %end;


   /*-----------------------------------------------------------------------
    If the user has a code for TOTCODE => Use that. Otherwise we could 
    assume the value "T" to be used for TOTCODE i.e. code for total.
    Note: If there is no Totals in the file it should work anyway. tau-ARGUS
          calculates the totals for the EXPLANATORY variables since this is
          essential to have and play an important role in the structure of
          the table and also are important for the suppression models.
    -----------------------------------------------------------------------*/
   %if %symexist(TOTCODE) %then %do;
      %let _totcode=&TOTCODE.;
   %end;
   %else %do;
      %let _totcode=T;
   %end;


   /*=======================================================================
    Check if there is HierLevels defined => Calculate the length
    ------------------------------------------------------------------------
    2012-10-16/ak HierLevels can only be defined as char. The task added
                  here sums the levelpointers to a sum that should be the
                  very length of the variable seen as char (even if numeric)
    -----------------------------------------------------------------------*/
   %let _HierLen=0;
   data _null_;
      set WORK._variable_meta;
      
      if lengthn(HierLevels) then do;
          _HierLevels=translate(strip(HierLevels),',',' ');
          call symput('_HierLen',_HierLevels);
      end;
   run;

   /*-----------------------------------------------------------------------
    Sum the components to a sum that represents the total length
    -----------------------------------------------------------------------*/
   %if &_HierLen ^= 0 %then %do;
      data _null_;
         _HierLen=sum(&_HierLen.);
         call symput('_HierLen',_HierLen);
      run;
   %end;


   /*=======================================================================
    Create the METADATA FILE (RDA) that describes the datafile
    ========================================================================
    -----------------------------------------------------------------------*/
   filename _TAU_RDA "&_Metafile";

   data _null_;
      set  work._variable_meta;

      length _VarLen  $ 12
             /*_VarMiss $ 12*/;                                                         /* 4.0/L-E.A    Removed _Varmiss*/ 

      file _TAU_RDA;

      /*-----------------------------------------------------------------------
       Common meta
       Note: Description of status codes just relevant for TABLE DATA 
       -----------------------------------------------------------------------*/
      if _n_=1 then do;
         put "  <SEPARATOR> "",""";

         %if &_table. %then %do;
            put "  <SAFE>       S";
            put "  <UNSAFE>     U";
            put "  <PROTECT>    P";
         %end;
      end;

      /*--------------------------------------------------------------------
       Length and Missing
       Note: There is at the moment no waterproof solution in SAS2ARGUS how
             length and missing could automatic handled for numeric variables
             since both the value for missing and "length" is hard to tell
             from the data in SAS. Length is easy to handle for chars but
             even here it is hard in advance to forsee a viable value for 
             missing. We presume that the value of 9 could do by default.
             The user has the oppurtunity to edit the text files manually.
       2012-101-16/ak HierLevels is defined:
                      1. Char (always.. even if entered numeric)
                      2. The length is the sum of pointers in the definition
       2014-04-15/ak  Extented the length of _VARLEN from 10 to 15 since
                      huge numbers otherwise could be truncated.
       --------------------------------------------------------------------*/
      if lengthn(HierLevels) then do;
         _VarLen  = "&_HierLen";      /* Note: This is a calculated length */
         /*_VarMiss = substr('999999999999999',1,_VarLen);*/                        /* 4.0/L-E.A    Removed _Varmiss*/ 
      end;
      else if VarType='C' then do;
         _VarLen  = put(VarLen,best.); 
         /*_VarMiss = substr('999999999999999',1,VarLen);*/                         /* 4.0/L-E.A    Removed _Varmiss*/ 
      end;
      else do;
         _VarLen  = '15';
         /*_VarMiss = '';*/                                                         /* 4.0/L-E.A    Removed _Varmiss*/ 
      end;


      /*--------------------------------------------------------------------
       Variable names (SHADOW COST WEIGHT)
       ---------------------------------------------------------------------
       Note: VarLen and VarMiss is only declared for MICRO DATA
       --------------------------------------------------------------------*/
      if VarRole not in('SH','CO','WE') then do;
         %if %bquote(&intable.)=%str() %then %do;
            put VarNameTAU  +3 _VarLen /*+5 _VarMiss*/;                             /* 4.0/L-E.A    Removed _Varmiss*/ 
         %end;
         %else %do;
            put VarNameTAU;
         %end;
      end;

      /*--------------------------------------------------------------------
       Variables in "special roles" => Special names
       ---------------------------------------------------------------------
       Note: SHADOW and COST is included in definition of:
          <SPECIFYTABLE>"ExpVar1""ExpVar2"|RespVar|ShadowVar|CostVar,Lambda
       --------------------------------------------------------------------*/
      else do;
         /*----------------------------------------------------------------
          2013-04-09/LE.A  Så vi får length på WEIGHT, SHADOW och COST
         -----------------------------------------------------------------*/
         if VarRole='SH' then put "&Shadow" +3 _VarLen /*+5 _VarMiss*/;             /* 4.0/L-E.A    Removed _Varmiss*/ 
         if VarRole='CO' then put "&Cost"   +3 _VarLen /*+5 _VarMiss*/;             /* 4.0/L-E.A    Removed _Varmiss*/ 
         if VarRole='WE' then put "&Weight" +3 _VarLen /*+5 _VarMiss*/;             /* 4.0/L-E.A    Removed _Varmiss*/ 
      end;

      /*--------------------------------------------------------------------
       Attributes/Properties
       Note: Different attributes/properties for INTABLE and INDATA
       --------------------------------------------------------------------*/
      if VarRole='EX' then do;
                        put "  <RECODABLE>";

         /*-----------------------------------------------------------------
          InTable
          -----------------------------------------------------------------*/
         %if %bquote(&indata.)=%str() %then %do;
                        put "  <TOTCODE> &_totcode.";
         %end;

         /*-----------------------------------------------------------------
          InData and InTable 
          ------------------------------------------------------------------
          2012-10-16/ak Both types can be defined Hierarchical
          -----------------------------------------------------------------*/

         /*-----------------------------------------------------------------
          HierLevels
          -----------------------------------------------------------------*/
         if lengthn(HierLevels) then do;
                        put "  <HIERARCHICAL>";
                        put "  <HIERLEVELS>"     @20 HierLevels;
         end;

         /*-----------------------------------------------------------------
          HierCodeList
          Note: If the filename supplied is qualified with path then use that.
                If not add the path (default) to PATH_TMP. Tau-ARGUS don't
                find the file otherwise.
          -----------------------------------------------------------------*/
         else if lengthn(HierCodeList) then do;
                        put "  <HIERARCHICAL>";
            if countc(HierCodeList,'\/') then do; 
               HierCodeList=cats('"',HierCodeList,'"');
            end;
            else do;
               HierCodeList=cats('"',"&PATH_tmp.\",HierCodeList,'"');
            end;
                        put "  <HIERCODELIST>"   @20 HierCodeList;

            /*--------------------------------------------------------------
             HierLeadString
             Note: Second argument i options is charachter for defining 
                   "lead" (levels) in the hierarchy file. Default is "@".
             --------------------------------------------------------------*/
            if lengthn(HierLeadString) then do;
               _HierLeadString=cats('"',HierLeadString,'"');
            end;
            else do;
               _HierLeadString='"@"';
            end;
                        put "  <HIERLEADSTRING>" @20 _HierLeadString;
         end;

      end;

      /*--------------------------------------------------------------------
       INTABLE
       All other roles for variables. (Those are valid only for INTABLE)
       Note: The space between <NUMERIC> and <role> is essential/nessecery!
       --------------------------------------------------------------------*/
      %if %bquote(&indata.)=%str() %then %do;
         if VarRole='SH' then put "  <NUMERIC>  <SHADOW>";
         if VarRole='CO' then put "  <NUMERIC>  <COST>";  
         if VarRole='HO' then put "  <NUMERIC>  <HOLDING>";  
         if VarRole='WE' then put "  <NUMERIC>  <WEIGHT>";
         if VarRole='LO' then put "  <NUMERIC>  <LOWERPL>";
         if VarRole='UP' then put "  <NUMERIC>  <UPPERPL>";

         if VarRole='FR' then put "  <FREQUENCY>";
         if VarRole='MA' then put "  <MAXSCORE>";
         if VarRole='ST' then put "  <STATUS>";

         if VarRole='RE' then put "  <NUMERIC>";
      %end;

      /*--------------------------------------------------------------------
       INDATA
       Weight, Cost and Shadow could be used for INDATA
       2014-10-14/ak  Added DECIMALS so it "hits" all numeric roles
       --------------------------------------------------------------------*/
      %else %do;
         if VarRole='SH' then do;
                            put "  <NUMERIC> "/*<SHADOW>*/;                             /* 4.1/L-E.A    Removed <SHADOW> */ 
            if VarFmtD then put "  <DECIMALS>"    @20 VarFmtD;
         end;

         if VarRole='CO' then do;
                            put "  <NUMERIC> "/*<COST>*/;                               /* 4.1/L-E.A    Removed <COST> */ 
            if VarFmtD then put "  <DECIMALS>"    @20 VarFmtD;
         end;

         /*-----------------------------------------------------------------
          2014-12-15/lea  HOLDING should not have the card of <NUMERIC>
          -----------------------------------------------------------------*/
         if VarRole='HO' then put "  <HOLDING>";        

         /*-----------------------------------------------------------------
          2012-10-08/ka   Added DECIMALS here instead for the RDA-file
                          according to the instructions in the manual.
          -----------------------------------------------------------------*/
         if VarRole='WE' then do;
                                put "  <NUMERIC>";
            if VarFmtD > 0 then put "  <DECIMALS>"    @20 VarFmtD;
                                put "  <WEIGHT>";                     
         end;

         if VarRole='RE'  then do;
                                put "  <NUMERIC>";
            if VarFmtD > 0 then put "  <DECIMALS>"    @20 VarFmtD;
         end;

      %end;

   run;

   /*-----------------------------------------------------------------------
    Unassign
    -----------------------------------------------------------------------*/
   filename _TAU_RDA clear;
   /*-----------------------------------------------------------------------
    =======================================================================*/


   /*=======================================================================
    Create the DATA FILE (CSV) according to description above
    ========================================================================
    -----------------------------------------------------------------------*/
   filename _TAU_CSV "&_Datafile";


   /*-----------------------------------------------------------------------
    Create a list of all variables relevant to write in the textfile
    Note: The order of the variables is essential since this define the
          output from tau-Argus.
    -----------------------------------------------------------------------*/

/*--------------------------------------------------------------------------
   proc sql noprint;
      select VarName into :_Variables separated by ' '
      from work._Variable_Meta
      where VarName not in('1','-1','2','-2'); 
   quit;
 --------------------------------------------------------------------------*/


   /*-----------------------------------------------------------------------
    Since there can be a WHERE-statement to handle we solve that with
    a data step view where we subset the data. After that we create
    another view with SQL to reorder the variables.
    -----------------------------------------------------------------------*/

/*--------------------------------------------------------------------------
   data _dataset/view=_dataset; set %unquote(&dataset.); run;
 --------------------------------------------------------------------------*/


   /*-----------------------------------------------------------------------
    Create a SAS view to reorder the relevant variables in the chosen dataset.
    ------------------------------------------------------------------------
    Note: In _VARIABLES they are in correct order. But notice that in the 
          dataset they could be in any order... 
          The variable names has to be commaseparated in the SQL statement,
          which is accomplished with %CLEAN_PARAMETERS(&_VARIABLES,C).

          Since there can be a WHERE-statement to handle we solve that with
          a data step view where we subset the data. After that we create
          another view with SQL to reorder the variables.
    -----------------------------------------------------------------------*/

/*--------------------------------------------------------------------------
   %let _Vars=%clean_parameters(&_variables,c);
   proc sql noprint;
      create view _Variable_sorted as
         select &_Vars from _dataset;
   quit;
 --------------------------------------------------------------------------*/


   /*-----------------------------------------------------------------------
    Alternative 1   -  No variable values are quoted, only commaseparated.
    -----------------------------------------------------------------------*/
   /*-----------------------------------------------------------------------
   data _null_;
      set _Variable_sorted;
      file _TAU_CSV dlm=",";
      put (&_Variables.) (+0);
   run;
    -----------------------------------------------------------------------*/


   /*-----------------------------------------------------------------------
    Alternative 2   -  All variable values are quoted and commaseparated.
    -----------------------------------------------------------------------*/
   /*-----------------------------------------------------------------------
   data _null_;
      set _Variable_sorted;
      file _TAU_CSV;

      length _record $ 5000;
      _record=catq("ACT",&_Vars.);
      put _record;
   run;
    -----------------------------------------------------------------------*/


   /*-----------------------------------------------------------------------
    Alternative 3   -  Explanatory variables are qouted and all other
                       numeric variables are not quoted. Commasepared.
    -----------------------------------------------------------------------*/
   /*=======================================================================
    Construct the syntax for the PUT statement - as we use it to construct
    the CSV-file. This seems to be a solution that is close to "overkill", but
    since Tau-ARGUS is very demanding on how the textfile is presented especially
    for microdata. Columns suites best if the have a fix length. Explanatory
    variables is typically treated as text and so best presented in quotes. 
    Numeric variables has to be unquoted for MICRO DATA. For TABULAR DATA 
    Tau-ARGUS is more liberal thou. Then it works with explanatory variables 
    not quoted at all or all variables quoted - even numeric...

    But this will be a generic solution which produces usable textfiles from
    SAS for both TABLE DATA and MICRO DATA i Tau-ARGUS. This is a sample of code 
    constructed in a SAS Macro Variable (_SYNTAX) by this data _null_ step:

     length _record $ 5000;
     _record=catx(',',quote(strip(REGION)),quote(strip(AGE)),quote(strip(SEX)),RESP); 
     put _record;

    Note: That there could be constants as variable names for the role
          of COST for example. Avoid them here by a where statement...
    -----------------------------------------------------------------------*/
   data _null_;
      set _variable_meta(where=(VarName not in('1','-1','2','-2'))) end=_eof;
 
      length _syntax $ 5000;
      retain _syntax;

      /*--------------------------------------------------------------------
       Declare a variable and start up the syntax with:
       CATS (where we delcare comma as the separator) and start to build
       the syntax in the variable _SYNTAX.
       --------------------------------------------------------------------*/
      if _n_=1 then do;
         _syntax="length _record $ 5000;";
         _syntax=cats(strip(_syntax),"_record=catx(',',");
      end;

      /*--------------------------------------------------------------------
       If EXPLANATORY => Quote
       --------------------------------------------------------------------*/
      if VarRole='EX' then do;
         _syntax=cats(strip(_syntax),VarName,",");
         /*_syntax=cats(strip(_syntax),"quote(strip(",VarName,")),");*/                         /* 4.0/L-E.A    Removed " around VarName */
      end;

      /*--------------------------------------------------------------------
       All other roles (typically numeric) => No Quotes
       --------------------------------------------------------------------*/
      else do;
         _syntax=cats(strip(_syntax),VarName,",");
      end;

      /*--------------------------------------------------------------------
       If EndOfFile then substitute last "," with ");"
       --------------------------------------------------------------------*/
      if _eof then do;
         _syntax=cats(substr(_syntax,1,length(_syntax)-1),"); put _record;");
         call symput('_syntax',strip(_syntax));
      end;
      
   run;

   /*-----------------------------------------------------------------------
    Execute the constructed syntax and do write the CSV-file
    -----------------------------------------------------------------------*/
   data _null_;
      set &dataset.;
      file _TAU_CSV;

      &_syntax.;

   run;


   /*-----------------------------------------------------------------------
    Unassign
    -----------------------------------------------------------------------*/
   filename _TAU_CSV clear;
   /*-----------------------------------------------------------------------
    =======================================================================*/


   /*=======================================================================
    Exit
    -----------------------------------------------------------------------*/
   %exit:

   /*-----------------------------------------------------------------------
    Clean up the views
    -----------------------------------------------------------------------*/
   proc datasets lib=work NoList;
      delete _dataset/mtype=view; 
   run;quit;

%mend Write_Datafile;
/*#########################################################################*/
