/*==========================================================================
 Macro:        SAS2Argus([Se below for description of parameters])
 ---------------------------------------------------------------------------
 Description:  A SAS Macro which is the manifest of a "bridge" from SAS to
               tau-Argus and reverse.

 Purpose:      To make it possible to run tau-Argus from SAS to make 
               disclosure of SAS dataset or any data in any format that can 
               be accessed thru engines from within SAS.

 Precondition: NONE - other then data have to be established in a fashion 
               that it will suite tau-ARGUS

 Usage:        Set parameters and execute

 Initial code: Anders Kraftling/Statistics Sweden/IT/1
 Revised code: 
 Date:         2011-03-23
 Comment:      
 ---------------------------------------------------------------------------
Changes:        2016-11-15  Changed possible values for parameter SAS:      Lars-Erik Almberg 
                SAS=1       HTML only
                SAS=2       back to SAS only
                SAS=3       HTML and back to SAS
 ==========================================================================*/

/*--------------------------------------------------------------------
CHANGES FOR VERSION 4.0

2016-11-09/L-E.A    Delete the permanent log, row 165

CHANGES FOR VERSION 4.1
2016-12-19/L-E.A    Removed the Delete the permanent log
 --------------------------------------------------------------------*/



/*==========================================================================
 SAS2Argus
 --------------------------------------------------------------------------*/
%macro SAS2Argus(

   /*=======================================================================
    System parameters
    ------------------------------------------------------------------------
    Note: 
      JOBNAME   Name used as a prefix for all files created for tau-Argus 
                within a job. Default set to SAS2ARGUS if not set explicit. 
      RUNARGUS  This is an option to create text files for tau-Argus but NOT 
                to execute tau-ARGUS by setting RUNARGUS to 0 (zero). Default=1
      DEBUG     Boosts information to the SAS log if set to 1.
      HELP      Writes help for the macro to the SAS log when HELP=1
      SAS       Imports the HTML-report from tau-ARGUS to SAS internal
                browser and also imports output INTERMEDIATE to SAS.
    -----------------------------------------------------------------------*/
   JobName=SAS2ARGUS,
   RunArgus=1,
   Debug=0,
   Help=0,
   SAS=0,

   /*=======================================================================
    Input data to tau-ARGUS. 
    ------------------------------------------------------------------------
    Note: One of these two arguments are applicable. Either INDATA or INTABLE
    -----------------------------------------------------------------------*/
   InData=,
   InTable=,

   /*=======================================================================
    Variables and their roles
    ------------------------------------------------------------------------
    Note: Mandatory would be Explanatory and Response. All other are optional.
    -----------------------------------------------------------------------*/

   /*=======================================================================
    Risk assessment and eventually Secondary supression.
    ------------------------------------------------------------------------
    Note: If SUPRESS not set implies that only a risk assessment 
          being performed. If SAFETYRULE not set implies that STATUS is
          present. These are used in the batch command file.
    -----------------------------------------------------------------------*/
   SafetyRule=,
   Suppress=,

   /*-----------------------------------------------------------------------
    TABULAR DATA and MICRO DATA
    Five arguments used to build the <SPECIFYTABLE> in the batch command file.
    -----------------------------------------------------------------------*/
   Explanatory=,
   Response=,
   Shadow=,
   Cost=,
   Lambda=1,

   /*=======================================================================
    TABULAR DATA
    Note: To describe roles in the meta data file (RDA) for TABULAR DATA. 
    -----------------------------------------------------------------------*/
   Frequency=,
   LowerLevel=,
   UpperLevel=,
   MaxScore=,
   Status=,
   TotCode=T,

   /*=======================================================================
    MICRO DATA
    ------------------------------------------------------------------------
    Used to describe roles in the meta data file (RDA) for MICRO DATA.
    Note: The implementation of arguments for variable that defines hierarchi
          (as their roles) for micro data is communicated thru the parameter
          EXPLANATORY in the following way (sample):
             Alt. 1.    Region(2 2 0 0)           variable(HIERLEVELS)
             Alt. 2.    Region(Region.hrc @)      variable(HIERCODELIST [HIERLEADSTRING])

          Then we can derive the arguments (within the parentheses) from the 
          SAS macro (SAS2ARGUS) for the following tags i Tau-ARGUS:
            <HIERARCHICAL>      - The name of the variabel in the describing role
            <HIERLEVELS>        - Numbers defining hierachy within a string
            <HIERCODELIST>      - The name of the file defining hierarchy
            <HIERLEADSTRING>    - Charachter for defining levels in the file 

    The three remaining arguments left for micro data is then following and
    could be set during macro invocation:
            Weight              - <WEIGHT>
            Holding             - <HOLDING>
            Request             - <REQUEST>
    -----------------------------------------------------------------------*/
   Weight=,
   Holding=,
   Request=,

   /*=======================================================================
    Output data from tau-ARGUS
    ------------------------------------------------------------------------
    Note: If none is set. Nothing is produced from tau-ARGUS. Options are:
      TABLE()  => VarName delimiter(,) Primary(x)  Secondary(-) 
      PIVOT(0) => VarName                                          No Status
      PIVOT(1) => VarName                                          Status
      CODE(0)  => NoName  delimiter(,) Primary(-)   Secondary(x)   No status
      CODE(1)  => NoName  delimiter(,) Primary(del) Secondary(x)   No status
      CODE(2)  => NoName  delimiter(,) Primary(-)                  Status(1,5,11,14)  
      CODE(3)  => NoName  delimiter(,) Primary(del)                Status(1,11)   
      SBS()    => NoName  delimiter(,) Exp,0,Exp,0.. zero(deleted) Status(V,D,A)               
      INTER(0) => NoName  delimiter(;)                             Status only(S,M,U)
      INTER(1) => NoName  delimiter(;)                             Status(S,M,U)
    
    If SAS=2 or 3 then output is imported to SAS
    -----------------------------------------------------------------------*/
   Out=inter(1)

   )
   /Des="Bridge between SAS and tau-ARGUS";


   /*=======================================================================
    Global switch for NOTES - so we can minimize the log
    -----------------------------------------------------------------------*/
   %if not %symexist(GLOBAL_NOTES) %then %do;
      %global GLOBAL_NOTES;
      %let GLOBAL_NOTES=NOTES;
   %end;


   /*=======================================================================
    Need for help?
    -----------------------------------------------------------------------*/
   %if &help. %then %do;
      %SAS2Argus_help;
      %goto exit;
   %end;

   /*=======================================================================
    Start by putting a mark in the SAS log 
    (and at the same time force to set SYSERR=0 as we depend on that..)
    -----------------------------------------------------------------------*/
   data _null_; run;
   %let _notes=%sysfunc(getoption(NOTES));
   options &GLOBAL_NOTES.;
   %put NOTE: ===========================================================================;
   %put NOTE: Macro: [&sysmacroname];
   %put NOTE: ---------------------------------------------------------------------------;
   %put NOTE: Start executing with flags [RUNARGUS=&runargus, DEBUG=&debug, SAS=&sas];
   %put NOTE: ===========================================================================;
   %if &debug.=2 %then %put _local_;
   options &_notes;


   /*=======================================================================
    Declare variables
    _ERROR     - Error flag from subroutines so we can escape if we have to
    _DATASET   - The dataset given as argument (either INTABLE or INDATA)
    _TABLE     - 0 = Microdata,  1 = Aggregated data
    _DATAFILE  - The name on disk for DATA FILE 
    _METAFILE  - The name on disk for META FILE 
    -----------------------------------------------------------------------*/
   %local _error 
          _dataset 
          _table
          _datafile
          _metafile
   ;
   %let _error=0;


   /*=======================================================================
    "Clean" the parameters
    ------------------------------------------------------------------------
    Note:  Clean_Parameters(String,Type) 
           STRING - the string
           TYPE        Q => Each argument is quoted
                       C => Each argument is comma separated
                       N => Each argument is not separated at all (no space)
                       | => Each argument is vertical separated
                       P => Proper case
                       D => Remove double spaces
             No argument => Each argument is separated by a space
    -----------------------------------------------------------------------*/
   %let Explanatory = %Clean_Parameters(&Explanatory.,p);
   %let Response    = %Clean_Parameters(&Response,pd);
   %let Shadow      = %Clean_Parameters(&Shadow,pd);
   %let Cost        = %Clean_Parameters(&Cost,pd);
   %let Frequency   = %Clean_Parameters(&Frequency,pd);
   %let LowerLevel  = %Clean_Parameters(&LowerLevel,pd);
   %let UpperLevel  = %Clean_Parameters(&UpperLevel,pd);
   %let MaxScore    = %Clean_Parameters(&MaxScore);
   %let Status      = %Clean_Parameters(&Status);
   %let Weight      = %Clean_Parameters(&Weight,pd);
   %let Holding     = %Clean_Parameters(&Holding,pd);
   %let Request     = %Clean_Parameters(&Request,pd);


   /*-----------------------------------------------------------------------
    Handle the parameters SAFETYRULE and SUPPRESS => Upper case
    -----------------------------------------------------------------------*/
   %let SafetyRule  = %upcase(&SafetyRule);
   %let Suppress    = %upcase(&Suppress);


   /*-----------------------------------------------------------------------
    If FREQUENCY is set but not RESPONSE => Set RESPONSE=FREQUENCY
    -----------------------------------------------------------------------*/
   %if %length(&frequency.) and %length(&response.)=0 %then %let response=&frequency;

   /*-----------------------------------------------------------------------
    Handle the parameter COST - as is is used for both a variable name or the
    special argument of -1 or -2. We have to handle this before creating the
    meta data since a CONSTANT is not a variable name.

    If a CONSTANT is used  =>  Set COST to an empty string, since it is not a 
                               variable name. Set instead another flag _COSTBASE.
                               Remove also the minus sign here. Then both -1 and 1 
                               or -2 or 2 could be used as a allowable argument.
    Note: COST can be:
             VarName     - Name of variable used for COST (turnover e.g)
             -1          - Constant meaning that COST is based on FREQUENCY
             -2          - Constant meaning that COST is based on UNITY 
                           i.e. number of cells or domains

    It there is value assigned for COST and no Alpha => It is a constant.
    Eliminate the prefix of a minus sign (if present), so that both 1, -1,
    2 or -2 would do as argument for cost (instead of a variable name)
    -----------------------------------------------------------------------*/
   %if %length(&Cost.) %then %do;
      %if not %sysfunc(anyalpha(&Cost.)) %then %do;
         %let Cost=%sysfunc(translate(%str(&Cost),%str( ),%str(-)));
      %end;
   %end;


   /*=======================================================================
    Check parameters for data and that the dataset exists
    Note: Sets _DATASET - (with the name of either INDATA or INTABLE)
          Sets _TABLE=0 - (when micro data)
               _TABLE=1 - (when table)
          Sets _ERROR== - (no problems found)
               _ERROR=1 - (if there is an error which we can't handle)
    -----------------------------------------------------------------------*/
   %Check_parameters;
   %if &syserr. or &_error. %then %goto exit;


   /*=======================================================================
    If user has set empty arguments => Reset to defaults.
    Note: Defaults for parameters:
          JobName  => SAS2ARGUS (used as prefix for names on files created)
          RunArgus => 1         (do run tau-Argus)
          Debug    => 0         (don't show ARB and LOG files in the SAS log)
          SAS      => 0         (no import of text and HTML to SAS session)
          Help     => 0         (don't show HELP in the SAS log)
          Lambda   => 1         (default for Lambda, as it is also in tau-Argus)
          TotCode  => T         (totals assumed to be coded with T)
    -----------------------------------------------------------------------*/
   %if &jobname.  =%str()                 %then %let jobname=SAS2ARGUS;
   %if &runargus. =%str()                 %then %let runargus=1;
   %if &debug.    =%str()                 %then %let debug=0;
   %if &sas.      =%str()                 %then %let sas=0;
   %if &lambda.   =%str()                 %then %let lambda=1;
   %if &totcode.  =%str()                 %then %let totcode=T;

   %if %upcase(%substr(&runargus.,1,1))=Y %then %let runargus=1;
   %if %upcase(%substr(&runargus.,1,1))=R %then %let runargus=2;
   %if %upcase(%substr(&debug.,1,1))=Y    %then %let debug=1;
   %if %upcase(%substr(&sas.,1,1))=Y      %then %let sas=1;


   /*=======================================================================
    If parameter RUNARGUS is set to 2 => Rerun tau-Argus with already created
    files meaning that there is no need to establish any CSV or RDA or ARB-
    files. This is the scenario when the user could changed the status on
    certain domains (cells) from SAFE to UNSAFE or from UNSAFE to SAFE and
    with a new request to tau-Argus to handle secondary cell suppression.
    -----------------------------------------------------------------------*/
   %if &runargus. ne 2 %then %do;

      /*====================================================================
       Establish the Metadata for the ROLES OF VARIABLES at macro invocation.
       --------------------------------------------------------------------*/
      %Variable_Roles
      %if &syserr. %then %goto exit;


      /*====================================================================
       Establish the Metadata for the ACTUAL VARIABLES in the dataset given at
       macro invocation.
       --------------------------------------------------------------------*/
      %Variable_Properties(&_dataset.)
      %if &syserr. %then %goto exit;


      /*====================================================================
       Check conformity between designated variable roles and actual variables 
       in the dataset.
       --------------------------------------------------------------------*/
      %Variable_Meta(&_dataset.)
      %if &syserr. or &_error. %then %goto exit;


      /*====================================================================
       Check conformity between designated variable roles and actual variables 
       in the dataset.
       --------------------------------------------------------------------*/
      %Variable_Decimals(&_dataset.)
      %if &syserr. %then %goto exit;


      /*====================================================================
       Create the textfiles .RDA (meta) and .CSV (data ) according to the 
       information established so far and found in _Variable_Meta 
       ---------------------------------------------------------------------
       Macro:        Write_Datafile(Dataset=, Datafile=, Metafile=)
       ---------------------------------------------------------------------
       Description:  A macro that writes the SAS dataset to a comma separated (CSV)
                     text file and also describes this data in a metadata file (RDA)
                     that tau_Argus can interpretate.

       Parameters:   DATASET  - DATASET   to write          (fully qualified)
                     DATAFILE - DATA file to write          (fully qualified path)
                    [METAFILE]- Optional. Name of META FILE (fully qualified path)

       Note: PATH_TMP should be set initially when the SAS session is establised
             JOBNAME is an opportunity to assign a name used as a prefix to all 
             files created for tau-ARGUS to use (in one session/execution). If 
             not set it defaults to SAS2ARGUS. If PATH_TMP is not set it defaults
             to the same destination as SAS WORK.
       --------------------------------------------------------------------*/
      %Write_Datafile(Dataset=&_dataset.,
                      Datafile=%bquote(&PATH_tmp.\&jobname.))
      %if &syserr. or &_error. %then %goto exit;


      /*====================================================================
       Create the Command file (BAT) for tau-ARGUS as a manifest of what we
       want tau-ARGUS to do (suffix .ARB)
       --------------------------------------------------------------------*/
      %Write_Jobfile(Jobfile=%bquote(&PATH_tmp.\&jobname..ARB))
      %if &syserr. %then %goto exit;

   %end;
   %else %if &runargus.=2 %then %do;
      options &GLOBAL_NOTES.;
      %put NOTE: ===========================================================================;
      %put NOTE: Macro: [&sysmacroname];
      %put NOTE: ---------------------------------------------------------------------------;
      %put NOTE: No text files created. This run executing on existing files (RDA CSV and ARB);
      %put NOTE: ===========================================================================;
      options &_notes;
   %end;


   /*-----------------------------------------------------------------------
    If debug=1 then include the ARB-file in the SAS log
    -----------------------------------------------------------------------*/
   %if &debug. %then %do;
      %Fetch_Arb(Arbfile=%bquote(&PATH_tmp.\&jobname..ARB))
   %end;


   /*=======================================================================
    Execute tau-ARGUS
    ------------------------------------------------------------------------
    Note: NOXWAIT - Close the (DOS) command window automatic when finished.
          XSYNC   - Tell SAS to wait during execution before continuation.
          The log is specified as <LOGBOOK> in the ARB file 
    -----------------------------------------------------------------------*/
   %if &RunArgus. %then %do;

      options noxwait xsync;

      /*--------------------------------------------------------------------
       Remove the LOG for this "job"
       --------------------------------------------------------------------*/
      %Remove_File(Filename=%bquote(&PATH_tmp.\&jobname..LOG))


      /*--------------------------------------------------------------------
       Execute tau-ARGUS
       ---------------------------------------------------------------------
       Note: Watch out - there could be characters like comma in the path
             that can cause problems parsing the string
       --------------------------------------------------------------------*/
      data _null_;
        _exe = " ""%bquote(&PATH_exe)"" ";
        _job = " ""%bquote(&PATH_tmp.\&jobname..ARB)"" ";
        _cmd = _exe ||" "|| _job;

        call system(_cmd);
      run;
      %if &syserr. %then %goto exit;


      /*--------------------------------------------------------------------
       If SAS=1 then "import" both TEXT files and HTML files produced by 
       tau-ARGUS to this SAS-session.
       ---------------------------------------------------------------------
       ARGUS2SAS executes:
             READ_DATAFILE - A macro that reads delimited (CSV) text files 
                             with use of supplied metadata file (RDA) and
                             establish SAS datasets. 
             PRESENT_HTML  - A macro that presents the HTML-file produced by 
                             tau-ARGUS in the SAS internal browser.
       --------------------------------------------------------------------*/
      %if &SAS. %then %do;
         %Argus2SAS
      %end;


      /*--------------------------------------------------------------------
       If debug=1 then include the HTML-files from tau-ARGUS in the SAS 
       internal browser and the LOG-file from tau-ARGUS in the SAS log
       --------------------------------------------------------------------*/
      %if &debug. %then %do;
         %Fetch_Log(Logfile=%bquote(&PATH_tmp.\&jobname..LOG))
      %end;


      /*--------------------------------------------------------------------
       A macro that checks the TauArgus log to see that we really did run 
       the optimiser (Xpress)
       Note: Runs always independent of the setting of DEBUG.
       --------------------------------------------------------------------*/
      %Check_TauLog(Logfile=%bquote(&PATH_tmp.\&jobname..LOG))

   %end;


   /*-----------------------------------------------------------------------
    Exit
    -----------------------------------------------------------------------*/
   %exit:


   /*-----------------------------------------------------------------------
    Debug
    -----------------------------------------------------------------------*/
   %if &debug. %then %do;
   /*-----------------------------------------------------------------------
      %put _local_;
      %put _automatic_;
    -----------------------------------------------------------------------*/
      %if &syserr > 0 %then %do;
         %let _notes=%sysfunc(getoption(NOTES));
         options &GLOBAL_NOTES.;
         %put NOTE: ===========================================================================;
         %put NOTE: Macro: [&sysmacroname];
         %put NOTE: ---------------------------------------------------------------------------;
         %put NOTE: This run terminated with a SYSERR=&syserr.;
         %put NOTE: &syserrortext;
         %put NOTE: ===========================================================================;
         %if &debug.=1 %then %put _local_;
         options &_notes;
      %end;
   %end;

   /*-----------------------------------------------------------------------
    If no Debug => Clean up       
    -----------------------------------------------------------------------*/
   %else %do;
      proc datasets lib=work nolist;
         delete _Variable_: htmlout /mtype=data;
         delete _Variable_sorted:   /mtype=view;
      run; quit;
   %end;

%mend SAS2Argus;


