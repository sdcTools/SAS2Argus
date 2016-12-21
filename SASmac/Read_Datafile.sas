/*==========================================================================
 Macro:        Read_Datafile(Datafile, [Dataset], [Metafile], [GetNames])
 ---------------------------------------------------------------------------
 Description:  A macro that reades a comma separated (CSV) text file with 
               help of the supplied metadata file (RDA) from tau-ARGUS.

 Parameters:   DATAFILE - DATA file to read                       (qualified path)
              [DATASET] - Optional. Name of DATASET to be created
              [METAFILE]- Optional. Name of META FILE             (qualified path)
              [GETNAMES]- Optional. Y => Get variable names from first row
                                    N => Default. No variable names in the 
                                         file

 Precondition: NONE - But files given as argument has to exist of course.

 Comment:      The suffix should be given in the argument of the filenames 
               and is of course neccesary if not according to the "standard" 
               i.e. <datafilename>.CSV for the data and 
                    <metafilename>.RDA for the meta data respectively.
               If no name is given for DATASET to be created  
               If no suffix given for DATAFILE => .CSV is assumed.
               If no name at all is given as argument for the METAFILE then 
               we use the name of the data file substituting any given file 
               suffix with .RDA.

 Change:       2012-11-20/ak Erased the default setting of GetNamed=NO since
                             it is handled within the macro.
               2012-11-27/ak BQUOTED every file reference since file paths
                             can have chars as commas or dots within the path
               2014-11-27/ak Included DSD in the infile _TAU_CSV statement to
                             fix a (randomly appearing) problem.
 --------------------------------------------------------------------------*/

/*--------------------------------------------------------------------
CHANGES FOR VERSION 4.0

2016-11-09/L-E.A    Included a counter for the number of explanatory so that we can name the variables with _Shadow and _Cost
                    to get the same naming as with tau-Argus version 3.5.0.
                    Included naming of _Shadow and _Cost
 --------------------------------------------------------------------*/


%macro Read_Datafile(Datafile=, Dataset=, Metafile=, GetNames=)
   /Des="Imports a DATA text file to a SAS-dataset with use of the META file";

   %local _Filename 
          _Dataset
          _Metafile
          _notes
          _Library;

   /*-----------------------------------------------------------------------
    Argument Datafile is mandatory => Check
    -----------------------------------------------------------------------*/
   %if &Datafile.=%str() %then %do;
      %let _notes=%sysfunc(getoption(NOTES)); 
      options &GLOBAL_NOTES.;
      %put NOTE: ===========================================================================;
      %put NOTE: Macro: [&sysmacroname];
      %put NOTE: ---------------------------------------------------------------------------;
      %put NOTE: The parameter DATAFILE (name of textfile) is mandatory and is missing.;
      %put NOTE: ===========================================================================;
      options &_notes.;
      %goto exit;
   %end;

   /*-----------------------------------------------------------------------
    Does this file exists => Check
    -----------------------------------------------------------------------*/
   %else %do;
      /*filename _TAU_CSV "&PATH_tmp.\&jobname._Out_5_&_parm..csv";
      %let _exist=%sysfunc(fexist(_TAU_CSV));*/
      filename _TAU_CSV "&datafile";
      %let _exist=%sysfunc(fexist(_TAU_CSV));

      %if &_exist=0 %then %do;
         %let _notes=%sysfunc(getoption(NOTES)); 
         options &GLOBAL_NOTES.;
         %put NOTE: ===========================================================================;
         %put NOTE: Macro: [&sysmacroname];
         %put NOTE: ---------------------------------------------------------------------------;
         %put NOTE: Parameter DATAFILE is assigned, but the file can not be found.;
         %put NOTE: [&Datafile];
         %put NOTE: ===========================================================================;
         options &_notes;
         %goto exit;
      %end;
   %end;


   /*-----------------------------------------------------------------------
    Remove the suffix
    ------------------------------------------------------------------------
    Note: Regular expression - PRXCHANGE
             change                          => s/
             a dot followed by               => \.
             and 1 or more                   => {1,} 
             characters                      => [a-z]
             found in the end of the string  => $/
             with no regard to case          => /i
             to nothing                      => //
             but just one occurency          => ,1,
             in the string given as argument => &Datafile.
    -----------------------------------------------------------------------*/
   %let _Filename=%sysfunc(prxchange(%str(s/\.[a-zåäöÅÄÖ]+$//i),1,&Datafile));


   /*-----------------------------------------------------------------------
    GETNAMNE - Should we get names from the row 1 in the file
    Default: GETNAMES=NO
    -----------------------------------------------------------------------*/
   %if %length(&getnames.) %then %do;
      %if %substr(%upcase(&getnames.),1,1)=Y %then %let getnames=YES;
                                             %else %let getnames=NO;
   %end;
   %else %do;
      %let getnames=NO;
   %end;


   /*-----------------------------------------------------------------------
    Determine if there is a comma or semicolon used as separator
    ------------------------------------------------------------------------
    Note: Most common is comma but if we read one observation we could find
          out and don't have to bother, or introduce an additional parameter
    ------------------------------------------------------------------------
    Change: Code revisited 2014-11-27/ak Included DSD to fix a random problem
    -----------------------------------------------------------------------*/
   filename _TAU_CSV "%bquote(&Datafile)";

   /*-----------------------------------------------------------------------
    Default = ;
    -----------------------------------------------------------------------*/
   %let _delimiter=";";

   data _null_;
      infile _TAU_CSV lrecl=2000 dsd;
      input _row $300.;                                         /* 16-11-15 tagit bort : framför $300   L-E.A */      

      _comma=countc(_row,',');
      _semi =countc(_row,';');

      if _comma > 0 and _comma > _semi  then call symput('_delimiter','","');
      if _semi  > 0 and _semi  > _comma then call symput('_delimiter','";"'); 

      if _n_=2 then stop;
   run;


   /*-----------------------------------------------------------------------
    Unassign
    -----------------------------------------------------------------------*/
   filename _TAU_CSV clear;


   /*-----------------------------------------------------------------------
    If no argument DATASET => Use FILENAME (without suffix) for the name on
    the dataset.
    -----------------------------------------------------------------------*/
   %if &Dataset.=%str() %then %let _Dataset=&_Filename;
                        %else %let _Dataset=&Dataset;


   /*-----------------------------------------------------------------------
    Extract the filename from the string. -1 => The last argument after \/ 
    Try to avoid letters not accepted in SAS dataset names
    -----------------------------------------------------------------------*/
   %let _Dataset=%scan(%bquote(&_Dataset),-1,\/);
   %let _Dataset=%sysfunc(translate(%bquote(&_Dataset),_______,!@#¤£$+));


   /*-----------------------------------------------------------------------
    Import text file with DATA from Tau-ARGUS
    Note: With this technique we thrust SAS that SAS will interpret the file 
          correct. The experience is that this is a good choice. The drawback 
          is that we don't introduce variable names since there is no variable 
          names within the file. => VAR1 VAR2 VAR3...
          We choose to rename variable in the next step instead.
    -----------------------------------------------------------------------*/
   filename _RDtemp temp;
   proc printto log=_RDtemp; run;
   proc import 
      out       = &_Dataset. 
      datafile  = "&Datafile" 
      dbms      = dlm replace;
      delimiter = &_delimiter.;
      getnames  = &getnames.;
   run;
   proc printto; run;
   filename _RDtemp clear;


   /*-----------------------------------------------------------------------
    If GETNAMES=YES => We are finished => Exit.
    -----------------------------------------------------------------------*/
   %if &getnames.=YES %then %goto exit;


   /*=======================================================================
    Check if there is an explicit named META DATA file in the invocation.
    If not the assumtion is that the META DATA file is to be found in the 
    same folder and have the same name - but with suffix .RDA. Use the
    macro variabel _FILENAME which is the argument FILENAME without suffix.
    Or if there is an explicit named Meta file => Use that instead.
    -----------------------------------------------------------------------*/
   %if &Metafile=%str() %then %do;
      %let _Metafile=%bquote(&_Filename..RDA);
   %end;
   %else %do;
      %let _Metafile=%bquote(&Metafile.);
   %end;


   /*-----------------------------------------------------------------------
    Check that this RDA-file exists before we continue
    -----------------------------------------------------------------------*/
   %if not %sysfunc(fileexist(&_Metafile.)) %then %do;
      %let _notes=%sysfunc(getoption(NOTES)); 
      options &GLOBAL_NOTES.;
      %put NOTE: ===========================================================================;
      %put NOTE: Macro: [&sysmacroname];
      %put NOTE: ---------------------------------------------------------------------------;
      %put NOTE: No associated RDA-file could be found for:;
      %put NOTE: [&Datafile].;
      %put NOTE: ===========================================================================;
      options &_notes;
      %goto exit;
   %end;
   
   /*-----------------------------------------------------------------------
    2. Tau-ARGUS names the FREQUENCY column in the output to <freq> under 
       some circumstances. As not even Tau-ARGUS can handle this as a variable 
       name we rename it to _freq_. This makes it possible to reopen the 
       associated CSV-file in Tau-ARGUS. 
    -----------------------------------------------------------------------*/
   filename _TAU_RDA "&_Metafile";
   data _null_;
      infile _TAU_RDA truncover;
      input _txt :$400;
      file   _TAU_RDA;

      if strip(_infile_)="<freq>" then _infile_="_freq_";
      put _infile_;
   run;
   filename _TAU_RDA clear;

   /*-----------------------------------------------------------------------
    3. Import the text file now with METADATA from Tau-ARGUS
    Note: First  FILENAME is a pointer to the text file to read
          Second FILENAME is a pointer to a temporary file to write the
          syntax for a rename statement.
    -----------------------------------------------------------------------*/
   filename _TAU_RDA "&_Metafile";
   filename _rename temp;

   /*--------------------------------------------------------------------
    4.0/L-E.A  Included a counter for the number of explanatory so that we can name the variables with _Shadow and _Cost
    to get the same naming as with tau-Argus version 3.5.0.
     --------------------------------------------------------------------*/
   data _null_;
      set _variable_meta end=eof;
      if VarRole='EX' then antal_exp + 1;
      if eof then call symputx('antal_exp', antal_exp);
   run;

   data _null_;
      length _text $ 200;
      infile _TAU_RDA truncover; /* The Meta Data file describing the data */
      file _rename;              /* Temporary file for the rename syntax   */

      /*--------------------------------------------------------------------
       Read the METADATA file and create a syntax for rename
       --------------------------------------------------------------------*/
      input _chr $1-1 @;                        /* Read the first position */

      if _chr ne '' then do;  /* If there is "something" in first position */
         input @1 _row : $100.;        /* Read the the Row from position 1 */
         VarName=scan(_row,1);         /* Read the actual variable name    */
         if upcase(VarName)="SEPARATOR>" then delete;
         else do;
            _nr+1;
            OldName=cats('VAR',_nr);   /* Construct the "old name"         */
         /* VarName=prxchange('s/<freq>/_freq_/',-1,Varname);    Change    */
            if _nr=&antal_exp + 3       then VarName=cats(propcase(VarName), '_Shadow');                        /* 4.0/L-E.A    included */
            else if _nr=&antal_exp + 4  then VarName=cats(propcase(VarName), '_Cost');                          /* 4.0/L-E.A    included */
            else VarName=propcase(VarName); /* Variable name in proper case     */
            output;
            _text = cats(OldName,"=",VarName); 
            put _text;                 /* Write to temp file (for include) */
         end;
      end;
      drop _:;
   run;


   /*-----------------------------------------------------------------------
    Now just rename the variables in the created dataset 
    -----------------------------------------------------------------------*/
   %if %index(&_dataset,%str(.)) %then %do;
      %let _library=%scan(&_dataset,1);
      %let _dataset=%scan(&_dataset,2);
   %end;
   %else %do;
      %let _library=work;
      %let _dataset=&_dataset;
   %end;

   proc datasets library=&_library. nolist;
      modify &_dataset.;
      rename
         %include _rename;
      ;
   run; quit;


   /*-----------------------------------------------------------------------
    Unassign
    -----------------------------------------------------------------------*/
   filename _rename  clear;
   filename _TAU_RDA clear;


   /*-----------------------------------------------------------------------
    Exit
    -----------------------------------------------------------------------*/
   %exit:

%mend Read_Datafile;
