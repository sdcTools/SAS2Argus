/*==========================================================================
 Macro:        Check_Outstring(Outstring)
 ---------------------------------------------------------------------------
 Description:  A macro that checks the argument given for out so we can
               be sure to interpret this correct.

 Parameters:   OUTSTRING - The sting given as argument for OUT

 Precondition: NONE

 Comment:      Neat to have checked this initially so we don't have to 
               bother furter down in the process
 Note:         Have to maintained according to possible output alternatives.
               Those are valid at the moment: 
                 TABLE, PIVOT, CODE, SBS, INTER or prefix T, P, C, S, I
 --------------------------------------------------------------------------*/
%macro Check_Outstring(outstring);

   %let _nr=1;
   %let _out=%upcase(%scan(&outstring,&_nr,%str( )));

   %do %until (&_out.=);
      %let _type=%sysfunc(prxchange(s/\(|\d+|\)//i,-1,%bquote(&_out)));

      %let _t=%substr(&_type,1,1);

      /*--------------------------------------------------------------------
       Is it a valid argument for output?
       --------------------------------------------------------------------*/
      %let _pos=%sysfunc(prxmatch(/TABLE|PIVOT|CODE|SBS|INTER/,&_type));
      %if &_pos=0 %then %do;
         %let _notes=%sysfunc(getoption(NOTES));
         option &GLOBAL_NOTES.;
         %put NOTE: ===========================================================================;
         %put NOTE: Macro: [sysmacroname];
         %put NOTE: ---------------------------------------------------------------------------;
         %put NOTE: Argument for OUT=&_OUT. which is invalid. Valid arguments for OUT is:;
         %put NOTE:      TABLE()  => Not used;
         %put NOTE:      PIVOT(0) => No status;
         %put NOTE:      PIVOT(1) => Status;
         %put NOTE:      CODE(0)  => None;
         %put NOTE:      CODE(1)  => Status;
         %put NOTE:      CODE(2)  => Supress empty cells;
         %put NOTE:      CODE(3)  => Status and supress empty cells;
         %put NOTE:      SBS()    => Not used;
         %put NOTE:      INTER(0) => Status only;
         %put NOTE:      INTER(1) => Also Top-N scores;
         %put NOTE: ===========================================================================;
         %put;
         option &_notes.;
      %end;

      %let _nr=%eval(&_nr+1);
      %let _out=%bquote(%upcase(%scan(&outstring,&_nr,%str( ))));
   %end;
%mend Check_Outstring;
