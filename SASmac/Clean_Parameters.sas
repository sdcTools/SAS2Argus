/*==========================================================================
 Macro:       Clean_Parameters(String,Type) 
 ---------------------------------------------------------------------------
 Description: A function used for to "Clean" the parameters

 Parameters:  STRING - The string to be "cleaned"

              TYPE   - No argument => Each argument is space separated 
                       Q => Each argument is quoted
                       C => Each argument is comma separated
                       N => Each argument is not separated at all (no space)
                       | => Each argument is vertical separated
                       P => Proper case
                       D => Remove double spaces
                   
 Comment:     The second argument for TYPE can be combined with Q for:
                      QC => Quoted and commaseparated
                      QN => Quoted and no space between arguments
                      Q| => Quoted and vertical separated (|)

                      P and D can be used independently  

 --------------------------------------------------------------------------
 Change:      2012-12-12/ak There can be comma in the path for HierCodeFile,
                            so we can't clean for commas. There can also be
                            white space, so we can't clean for double spaces.
                            So there is now a new TYPE=D, for a choice of
                            removing double spaces.
 --------------------------------------------------------------------------*/
%macro Clean_Parameters(string,type)
   /Des="Function for to 'clean' the parameters";

   %local _string;
   %let _string=&string;
   %let type=%upcase(&type);

   /*--------------------------------------------------------------------
    Change 2012-12-12/ak There can be comma in the path for HierCodeFile 
                         so we can't clean for commas. There can alse be
                         white space so we can't clean for double spaces
                         as a general "cleaning" approach.
    --------------------------------------------------------------------*/
   %if %length(&_string) %then %do;

   /* %let _string=%sysfunc(translate(&_string,%str(   ),%str(,;/))); */
      %let _string=%sysfunc(translate(&_string,%str(   ),%str(;/)));
      %if %index(&type.,D) %then %do;
         %let _string=%sysfunc(compbl(&_string));
      %end;

      /*-----------------------------------------------------------------
       Proper Case?
       -----------------------------------------------------------------*/
      %if %index(&type.,P) %then %do;
         %let _string=%sysfunc(propcase(&_string));
      %end;

      /*-----------------------------------------------------------------
       Quoted?
       -----------------------------------------------------------------*/
      %if %index(&type.,Q) %then %do;
         %let _string=%sysfunc(compbl(&_string));
         %let _string=%sysfunc(translate(&_string,%str(   ),%str(,;/)));
         %let _string=%sysfunc(translate(&_string,%str(,),%str( )));
         %let _string=%sysfunc(catq(%str(AT),&_string));
         %let _string=%sysfunc(translate(&_string,%str(),%str(,)));
      %end;

      /*-----------------------------------------------------------------
       Comma separated?
       -----------------------------------------------------------------*/
      %if %index(&type.,C) %then %do;
         %let _string=%sysfunc(translate(&_string,%str(   ),%str(,;/)));
         %let _string=%sysfunc(compbl(&_string));
         %let _string=%sysfunc(translate(&_string,%str(,),%str( )));
      %end;

      /*-----------------------------------------------------------------
       No space between arguments? (Only for Quoted strings)
       -----------------------------------------------------------------*/
      %if %index(&type.,N) and %index(&type.,Q) %then %do;
         %let _string=%sysfunc(tranwrd(&_string,%str(" "),%str("")));
      %end;

      /*-----------------------------------------------------------------
       Vertical separator between arguments?
       -----------------------------------------------------------------*/
      %if %index(&type.,|) %then %do;
         %let _string=%sysfunc(compbl(&_string));
         %let _string=%sysfunc(translate(&_string,%str(|),%str( )));
      %end;

      /*-----------------------------------------------------------------
       Compress eventually parentheses and arguments within EXPLANATORY
       -----------------------------------------------------------------*/
      %let _string=%sysfunc(tranwrd(%bquote(&_string),%str( %(),%str(%()));
      %let _string=%sysfunc(tranwrd(%bquote(&_string),%str(%( ),%str(%()));

   %end;
 
   &_string /* Return the string */

%mend Clean_Parameters;
