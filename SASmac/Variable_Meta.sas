/*==========================================================================
 Macro:        Variable_Meta
 ---------------------------------------------------------------------------
 Description:  A macro that checks that all variables given roles at the 
               macro invocation of SAS2ARGUS do exists in the dataset by 
               combining variable roles with variables in the dataset.

 Parameters:   DATASET - The name of the dataset given as argument

 Precondition: WORK._VARIABLE_ROLES      and 
               WORK._VARIABLE_PROPERTIES has to exists before running. 
                               
 Comment:      We alse refer to the macro variable &_DATASET, that stores the
               name of the dataset, to eventually point out the dataset and
               the variables if variables can't be found.  
 --------------------------------------------------------------------------*/
%macro Variable_Meta(dataset)
   /Des="Check that all roles exists in dataset";

   /*-----------------------------------------------------------------------
    Merge _Variable_Roles with _Variable_Properties to see that all
    variable assigned for roles do exists
    -----------------------------------------------------------------------*/
   proc sql noprint;
      create table _variable_meta as
         select t1.SortOrder,  t1.VarName,

                t2.VarType,    t2.VarFmt,       t2.VarFmtd,        
                t2.VarLen,     t2.VarLabel,

                t1.VarNameTAU, t1.VarRole,
                t1.HierLevels, t1.HierCodeList, t1.HierLeadString,
         case
            when missing(t2.VarLen) and 
                 t1.VarName not in('1','2','-1','-2') then 1
                                                      else 0
         end as Missing

         from work._Variable_Roles      as t1 left join
              work._Variable_Properties as t2 on
              t1.VarName = t2.VarName

         order by t1.SortOrder;

      /*--------------------------------------------------------------------
       Check
       --------------------------------------------------------------------*/
      select sum(missing) into :_Missing 
      from work._variable_meta;

      %if &_Missing. > 0 %then %do;
         select distinct VarName into :_MissingVars separated by ' '
            from work._variable_meta
            where Missing=1;
      %end;
   quit;

   /*-----------------------------------------------------------------------
    Alert user that not all variables exists
    -----------------------------------------------------------------------*/
   %if &_missing. > 0 %then %do;
      %put ERROR: ===========================================================================;
      %put ERROR: Macro: [&sysmacroname];
      %put ERROR: ---------------------------------------------------------------------------;
      %put ERROR: Following variables can not be found in dataset [&dataset]:;
      %put ERROR: &_MissingVars;
      %put ERROR: ===========================================================================;
      %let _error=1;
   %end;

%mend Variable_Meta;
