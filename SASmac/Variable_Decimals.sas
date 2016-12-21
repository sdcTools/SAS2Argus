/*==========================================================================
 Program:      Variable_Decimals
 ---------------------------------------------------------------------------
 Purpose:      Find out actual number of decimals in data
 Precondition: This is executed in the Variable Meta context
 Parameters:   DS -  Dataset
 In:           Variable_Meta
 Out:          Variable_Meta (updated with decimals)
 Usage:        
 Comment:      
 ---------------------------------------------------------------------------               
 Initial code: Anders Kraftling
 Date:         2014-11-20
 Revised code: 
 Date:         2014-xx-xx
 ---------------------------------------------------------------------------
 Changes:      2014-12-16/ak Only interested in RESPONSE and WEIGHT
 ==========================================================================*/

/*==========================================================================
 Create a dataset with variables and their actual used number of decimals
 --------------------------------------------------------------------------*/
/*#########################################################################*/
%macro Variable_Decimals(ds);

   /*-----------------------------------------------------------------------
    Find out which Variabel Roles is NUMERIC variables
    -----------------------------------------------------------------------*/
   proc sql NoPrint;
      select distinct VarName 
      into :_Vars separated by ' '
      from _Variable_Meta
      where VarType='N' and VarName not in('VARLEN','VARNAME','VARTYPE','VARFMT','VARFMTD','VARLABEL');
   quit;

   /*-----------------------------------------------------------------------
    As we collect the result in a new dataset => Initially delete it here
    -----------------------------------------------------------------------*/
   %if %sysfunc(exist(WORK._Variable_Decimals)) %then %do;
      proc delete data=WORK._Variable_Decimals; run;
   %end;

   /*-----------------------------------------------------------------------
    Loop thru all variables and "look into" the (used) dataset
    -----------------------------------------------------------------------*/
   %local _Nr _Var;
   %let _Nr=1;
   %let _Var=%upcase(%scan(&_Vars, &_Nr));

   %do %while (%length(&_Var.));

      /*--------------------------------------------------------------------
       There is only two interesting variables to look at RESPONSE and WEIGHT
       --------------------------------------------------------------------*/
      %if &_Var. = %upcase(&Response.) or &_Var. = %upcase(&Weight.) %then %do;

        /*-------------------------------------------------------------------
         %put #######################################??;
         %put _Var=&_Var.;
         %put #######################################??;
        --------------------------------------------------------------------*/


         /*-----------------------------------------------------------------
          Is there a format associated with this variable? It could be a 
          format defined by the user telling us how many decimals to deal with.
          -----------------------------------------------------------------*/
         data _null_;
            set &ds.(keep=&_Var. obs=1);
            _fmt=vformat(&_Var.);
            call symput('_Fmt',strip(_fmt));
         run;

         /*-----------------------------------------------------------------
          Open the dataset and actually find out how many decimals the variable
          is using. But we do respect any explicit format associated. If no 
          explicit format assigned the default format (BEST12.) still delivers 
          actual used decimals in the dataset.
          ------------------------------------------------------------------
          Not: If it is Microdata, we assume that 5000 rows is enough to examine
               to gain time
          -----------------------------------------------------------------*/
         data _Decimals;
            /* We only need the variable name and its decimals */
            length 
               VarName $ 32
               Decimals   8
            ;
            keep VarName Decimals;

            set &ds.(keep=&_Var. obs=5000) end=_eof;
            retain Decimals 0;

            /* Max decimals used => Length of string behind decimal separator */
            Decimals=max(Decimals,lengthn(scan(strip(put(&_Var.,&_Fmt.)),2,".")));
            if _eof then do;
               VarName="&_Var.";
              output;
            end;
         run;

         /*-----------------------------------------------------------------
          Collect the results in a dataset (_Variable_Decimals)
          -----------------------------------------------------------------*/
         proc append 
            base=_Variable_Decimals
            data=_Decimals;
         run;

      %end;

      /*--------------------------------------------------------------------
       Next variable
       --------------------------------------------------------------------*/

      %let _Nr=%eval(&_Nr + 1);
      %let _Var=%scan(&_Vars, &_Nr);
   %end;


   /*-----------------------------------------------------------------------
    Join _VARIABLE_DECIMALS with _VARIABLE_META and update with used decimals
    -----------------------------------------------------------------------*/
   %if %sysfunc(exist(WORK._Variable_Decimals)) %then %do;

      /*--------------------------------------------------------------------
       The merge needs sorted data => Introduce sorted views
       --------------------------------------------------------------------*/
      proc sql;
         create view _t1 as select * from _Variable_Meta     order by VarName;
         create view _t2 as select * from _Variable_Decimals order by VarName;
      quit;

      /*--------------------------------------------------------------------
       Merge actual used number of decimals in the data to _VARIABLE_META
       --------------------------------------------------------------------*/
      data _Variable_Meta;
         merge _t1    (in=a)
               _t2;
         by VarName;

         if n(Decimals) then VarFmtD=Decimals;
         drop Decimals;
         if a then output;
      run;

      proc sort data=_Variable_Meta; by SortOrder; run;

      /*--------------------------------------------------------------------
       Now add the number of decimals of RESPONSE and WEIGHT variables since 
       TauArgus needs the sum of decimals to keep/reach the precision. Optimal 
       suppress methods in TauArgus do not work if the table don't sum.
       ---------------------------------------------------------------------
       Not: Works even if no WEIGHT is present
       --------------------------------------------------------------------*/
      proc sql NoPrint;
         select max(0,sum(input(VarFmtd,10.))) into :_WeightDec
         from _Variable_Meta
         where VarRole in('WE')
         ;

         update _Variable_Meta
            set VarFmtd = put(input(VarFmtd,best.) + &_WeightDec.,8.)
            where VarRole in('RE')
         ;
      quit;

      /*--------------------------------------------------------------------
       Clean up
       --------------------------------------------------------------------*/
      proc datasets library=work NoList;
         delete _Decimals 
                _Variable_Decimals /mt=data;
         delete _t1 _t2            /mt=view;
      run; quit;
   %end;

%mend Variable_Decimals;
/*#########################################################################*/

