/*==========================================================================
 Macro:         Variable_Properties(Dataset)
 ---------------------------------------------------------------------------
 Description:   A macro that fetch detailed information about variables from 
                the dataset given as argument

 Parameters:    Dataset

 precondition: 

 Comment:     

 Note:        
 --------------------------------------------------------------------------*/
/*#########################################################################*/
%macro Variable_Properties(Dataset)
   /Des="Examines properties of variables in the dataset";

   data _Variable_Properties;
      set &Dataset.;

      length
         VarName  $  32
         VarType  $   1
         VarFmt   $  32
         VarFmtd  $   8
         VarLen       8 
         VarLabel $ 100
      ;
      keep VarName--VarLabel;

      array _Num  _numeric_;
      array _Char _character_;

      %macro examine_variables(_var)/Des="Variable properties";
         VarName  = upcase(vname(&_var.));
         VarType  = vtype       (&_var.);
         VarFmt   = vformat     (&_var.);
         VarFmtd  = vformatd    (&_var.);  /* Number of decimals according to format */
         VarLen   = vlength     (&_var.);  /* Number of bytes */
         VarLabel = vlabel      (&_var.);
         output;
      %mend; 

      do over _num;
         %examine_variables(_Num);
      end;
      do over _char;
         %examine_variables(_Char);
      end;

      stop;
   run;
%mend Variable_Properties;
/*#########################################################################*/

