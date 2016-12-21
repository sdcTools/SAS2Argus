/*==========================================================================
 Macro:       Check_Parameters
 ---------------------------------------------------------------------------
 Description: A macro that checks parameters given in the invocation of
              Sas2Argus macro

 Parameters:  NONE

 Comment:     Collected here as a SAS macro for easy maintability

 Note:        Two useful macro variables assign here in this macro:
                 _DATASET - the name of the dataset to read
                 _TABLE   - a boolean 1=Aggregated data, 0=Micro data
 Changes:     2012-10-16/ak You can now subset both INDATA and INTABLE by
                            use of a dataset options ie. 
                            DS.SAMPLE(where=(sex=1)) or any other option.
 --------------------------------------------------------------------------*/
%macro Check_parameters
   /Des="Checks parameters assign to Sas2Argus";

   %let _error=0;

   /*-----------------------------------------------------------------------
    Check if any dataset (microdata or tabledata) is given as argument
    -----------------------------------------------------------------------*/
   %if %bquote(&InTable.)=%str() and %bquote(&InData.)=%str() %then %do;
      %put ERROR: ===========================================================================;
      %put ERROR: Macro: [&sysmacroname];
      %put ERROR: ---------------------------------------------------------------------------;
      %put ERROR: No dataset is given as argument;
      %put ERROR: ===========================================================================;
      %let _error=1;
   %end;


   /*-----------------------------------------------------------------------
    Check if both dataset (microdata and tabledata) is given as argument
    -----------------------------------------------------------------------*/
   %else %if %bquote(&InTable.)>%str() and %bquote(&InData.)>%str() %then %do;
      %put ERROR: ===========================================================================;
      %put ERROR: Macro: [&sysmacroname];
      %put ERROR: ---------------------------------------------------------------------------;
      %put ERROR: Both MICRODATA and TABLEDATA is given as arguments which is incorrecly;
      %put ERROR: ===========================================================================;
      %let _error=1;
   %end;


   /*-----------------------------------------------------------------------
    Check if the dataset INTABLE exists
    ------------------------------------------------------------------------
    Note: There could be a dataset option like WHERE, OBS, RENAME. Remove
          any eventuell dataset option from the argument before check of
          the existens of the dataset.
    -----------------------------------------------------------------------*/
   %if %bquote(&InTable.) ^= %str() %then %do;
      %let _pos=%sysfunc(indexc(&InTable,'('));
      %if &_pos.>0 %then %let _intable=%substr(%bquote(&InTable),1,%eval(&_pos-1));
      %else              %let _intable=%bquote(&InTable);

      %if not %sysfunc(exist(&_intable.)) %then %do;
         %put ERROR: ===========================================================================;
         %put ERROR: Macro: [&sysmacroname];
         %put ERROR: ---------------------------------------------------------------------------;
         %put ERROR: The libname or the dataset [&_InTable] do not exist;
         %put ERROR: ===========================================================================;
         %let _error=1;
      %end;
      %else %do;
         %let _dataset=&InTable;
         %let _table=1;
      %end;
   %end;

   /*-----------------------------------------------------------------------
    Check if the dataset INDATA exists
    ------------------------------------------------------------------------
    Note: There could be a dataset option like WHERE, OBS, RENAME. Remove
          any eventuell dataset option from the argument before check of
          the existens of the dataset.
    -----------------------------------------------------------------------*/
   %else %if %bquote(&InData.) ^= %str() %then %do;
      %let _pos=%sysfunc(indexc(&InData,'('));
      %if &_pos.>0 %then %let _indata=%substr(%bquote(&InData),1,%eval(&_pos-1));
      %else              %let _indata=%bquote(&InData);

      %if not %sysfunc(exist(&_indata.)) %then %do;

         %put ERROR: ===========================================================================;
         %put ERROR: Macro: [&sysmacroname];
         %put ERROR: ---------------------------------------------------------------------------;
         %put ERROR: The libname or the dataset [&_InData] do not exist;
         %put ERROR: ===========================================================================;
         %let _error=1;
      %end;
      %else %do;
         %let _dataset=&InData;
         %let _table=0;
      %end;
   %end;


   /*-----------------------------------------------------------------------
    Check that at least EXPLANATORY and RESPONSE or FREQUENCY is given as argument
    -----------------------------------------------------------------------*/
   %if %bquote(&explanatory.)=%str() or 
      (%bquote(&response.)=%str() and %bquote(&frequency.)=%str()) %then %do;
      %put ERROR: ===========================================================================;
      %put ERROR: Macro: [&sysmacroname];
      %put ERROR: ---------------------------------------------------------------------------;
      %put ERROR: At least EXPLANATORY and RESPONSE or FREQUENCY has to be set at macro invocation;
      %put ERROR: ===========================================================================;
      %let _error=1;
   %end;


   /*-----------------------------------------------------------------------
    Check that at least a SAFETYRULE or SUPPRESS is given as argument
    -----------------------------------------------------------------------*/
   %if %bquote(&safetyrule.)=%str() and %bquote(&suppress.)=%str() %then %do;
      %put ERROR: ===========================================================================;
      %put ERROR: Macro: [&sysmacroname];
      %put ERROR: ---------------------------------------------------------------------------;
      %put ERROR: At least a SAFETYRULE or SUPPRESS method should be set at macro invocation;
      %put ERROR: ===========================================================================;
      %let _error=1;
   %end;


   /*-----------------------------------------------------------------------
    Check if FREQ() is given as a SAFETYRULE and no FREQUENCY variable is 
    set at all when operating on already aggregated data (INTABLE), since 
    this can produce very strange results.
    -----------------------------------------------------------------------*/
   %if %length(&InTable.) %then %do;
      %if %index(%bquote(&safetyrule.),%str(FREQ)) and &frequency.=%str() %then %do;
         %put WARNING: ===========================================================================;
         %put WARNING: Macro: [&sysmacroname];
         %put WARNING: ---------------------------------------------------------------------------;
         %put WARNING: FREQ is requested as a SAFETYRULE but no FREQUENCY variable is specified;
         %put WARNING: ===========================================================================;
      %end;
   %end;


   /*-----------------------------------------------------------------------
    Check that no arguments is given that is irrelevant for INDATA
    -----------------------------------------------------------------------*/
   %if %length(&InData.) %then %do;
      %if %sysfunc(compress(%bquote(&Frequency. &LowerLevel. &UpperLevel. &MaxScore. &Status.))) ^= %str() %then %do;
         %put ERROR: ===========================================================================;
         %put ERROR: Macro: [&sysmacroname];
         %put ERROR: ---------------------------------------------------------------------------;
         %put ERROR: There is parameter set that is irrelevant for descriping MICRO DATA.;
         %put ERROR: Like: Frequency, LowerLevel, UpperLevel, MaxScore or Status.;
         %put ERROR: ===========================================================================;
         %let _error=1;
      %end;
   %end;


   /*-----------------------------------------------------------------------
    Check that no arguments is given that is irrelevant for INTABLE
    -----------------------------------------------------------------------*/
   %if %length(&InTable.) %then %do;
      %if %sysfunc(compress(%bquote(&Weight. &Holding. &Request.))) ^= %str() %then %do;
         %put ERROR: ===========================================================================;
         %put ERROR: Macro: [&sysmacroname];
         %put ERROR: ---------------------------------------------------------------------------;
         %put ERROR: There is parameter set that is irrelevant for descriping TABLE DATA.;
         %put ERROR: Like: Weight, Holding or Request.;
         %put ERROR: ===========================================================================;
         %let _error=1;
      %end;
   %end;


   /*-----------------------------------------------------------------------
    Check the string given as argument for OUT i.e. result from tau-ARGUS
    Note: PRXCHANGE eliminates all parentheses and digits from the argument.
    -----------------------------------------------------------------------*/
   %let _nr=1;
   %let _out=%upcase(%scan(&OUT,&_nr,%str( )));

   %do %until (&_out.=);
      %let _type=%sysfunc(prxchange(s/\(|\d+|\)//i,-1,%bquote(&_out)));

      /*--------------------------------------------------------------------
       Is it a valid argument for output?
       --------------------------------------------------------------------*/
      %let _pos=%sysfunc(prxmatch(/TABLE|PIVOT|CODE|SBS|INTER/,&_type));
      %if &_pos=0 %then %do;
         
         %let _notes=%sysfunc(getoption(NOTES)); 
         option &GLOBAL_NOTES.;
         %put NOTE: ===========================================================================;
         %put NOTE: Macro: [&sysmacroname];
         %put NOTE: ---------------------------------------------------------------------------;
         %put NOTE: Argument for OUT=&_OUT. which is invalid. Valid arguments for OUT is:;
         %put NOTE:      TABLE()  => Parm not used;
         %put NOTE:      PIVOT(0) => No status;
         %put NOTE:      PIVOT(1) => Status;
         %put NOTE:      CODE(0)  => None;
         %put NOTE:      CODE(1)  => Status;
         %put NOTE:      CODE(2)  => Supress empty cells;
         %put NOTE:      CODE(3)  => Status and supress empty cells;
         %put NOTE:      SBS()    => Parm not used;
         %put NOTE:      INTER(0) => Status only;
         %put NOTE:      INTER(1) => Also Top-N scores;
         %put NOTE: ===========================================================================;
         %put;
         %let _error=1;
         option &_notes.;
      %end;

      /*--------------------------------------------------------------------
       Reveal the PARM and check that to
       Note: When no Parm is given we assign it the value of 0
             PRXMATCH searches for the first position of a digit in the string
       --------------------------------------------------------------------*/
      %else %do;

         %let _pos =%sysfunc(prxmatch(/\d+/, &_out));
         %if &_pos > 1 %then %let _parm=%substr(&_out,&_pos,1);
                       %else %let _parm=0;

         /*-----------------------------------------------------------------
          Check the PARM
          -----------------------------------------------------------------*/
         %let _parmerr=0;
         %if (&_type.=TABLE and not (&_parm.=0))              %then %let _parmerr=1;
         %if (&_type.=PIVOT and not (&_parm.=0 or &_parm.=1)) %then %let _parmerr=1;
         %if (&_type.=CODE  and not (&_parm.=0 or &_parm.=1 or &_parm.=2 or &_parm.=3)) 
                                                              %then %let _parmerr=1;
         %if (&_type.=SBS   and not (&_parm.=0))              %then %let _parmerr=1;
         %if (&_type.=INTER and not (&_parm.=0 or &_parm.=1)) %then %let _parmerr=1;

         %if &_parmerr.=1 %then %do;
              %let _notes=%sysfunc(getoption(NOTES)); 
            option &GLOBAL_NOTES.;
            %put NOTE: ===========================================================================;
            %put NOTE: Macro: [&sysmacroname];
            %put NOTE: ---------------------------------------------------------------------------;
            %put NOTE: Argument OUT [&_type.] is correct but not the PARM [&_parm.];
            %put NOTE: Valid arguments for PARM is:;
            %put NOTE:      TABLE()  => Parm not used;
            %put NOTE:      PIVOT(0) => No status;
            %put NOTE:      PIVOT(1) => Status;
            %put NOTE:      CODE(0)  => None;
            %put NOTE:      CODE(1)  => Status;
            %put NOTE:      CODE(2)  => Supress empty cells;
            %put NOTE:      CODE(3)  => Status and supress empty cells;
            %put NOTE:      SBS()    => Parm not used;
            %put NOTE:      INTER(0) => Status only;
            %put NOTE:      INTER(1) => Also Top-N scores;
            %put NOTE: ===========================================================================;
            %put;
            %let _error=1;
            options &_notes.;
         %end;

      %end;

      %let _nr=%eval(&_nr+1);
      %let _out=%bquote(%upcase(%scan(&OUT,&_nr,%str( ))));
   %end;

%mend Check_parameters;
