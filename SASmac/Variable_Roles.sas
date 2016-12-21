/*==========================================================================
 Macro:         Variable_Roles
 ---------------------------------------------------------------------------
 Description:   A macro that creates a table that contains all variables 
                supplied in the macro invocation and their roles, one row for 
                each variable.

 Parameters:    NONE

 Preconditions: The macro variables we "examine" have to be established local
                (or global).

 Comment:       There is a special solution for to handle possible options for 
                EXPLANATORY variables describing hiearchies (which can be 
                numbers or a file name). 

 Note:          To keep variables and possible options in "tandem". We are 
                rebuilding the string in the way that we hide space within 
                parentheses (by use of a substitution char "Ã"). In this manner
                the variable name and eventually any options are keept together
                as we separete different arguments with a space.
 ---------------------------------------------------------------------------
 Change:        2012-11-15/ak The rules for adding an own definition of a 
                              HierLeadString was to simple. It's not enough 
                              with just a blankspace, since filenames can 
                              include 1 or more spaces. The solution for now 
                              is to set a constant.
 --------------------------------------------------------------------------*/
%macro Variable_Roles
   /Des="Creates table with variables and roles";

   /*-----------------------------------------------------------------------
    Create the meta data table describing the Variables and their roles
    Note: HierCodeList could be a whole qualified path to the file => $ 200.
    -----------------------------------------------------------------------*/
   data _Variable_Roles;

      length _Variables     $ 2000
             _String        $ 2000
             VarName        $   32
             _VarName       $  200
             VarNameTAU     $   32
             VarRole        $    2 
             _Option        $  250
             HierLevels     $   32
             HierCodeList   $  200
             HierLeadString $    1
      ;

      /*--------------------------------------------------------------------
       Macro EXAMINE_ROLE
       --------------------------------------------------------------------*/
      %macro Examine_role(_Var)/Des="Examines the variable roles";
         if symexist("&_Var") then do;
            _Variables = symget("&_Var");
            VarRole    = upcase(substr("&_Var",1,2));
            if _Variables ne '' then link VarSplit;
         end;
      %mend;

      /*--------------------------------------------------------------------
       Variables
       --------------------------------------------------------------------*/
      %Examine_role(Explanatory)
      %Examine_role(Response)
      %Examine_role(MaxScore)
      %Examine_role(Holding)
      %Examine_role(Shadow)
      %Examine_role(Weight)
      %Examine_role(Cost)
      %Examine_role(Frequency)
      %Examine_role(LowerLevel)
      %Examine_role(UpperLevel)

      return;

      /*--------------------------------------------------------------------
       Drop all temporary variables (i.e. starting with a underscore)
       --------------------------------------------------------------------*/
    /* drop _:; */

      /*--------------------------------------------------------------------
       Sub routine that decompose array of arguments (variables) to rows
       ---------------------------------------------------------------------
       Note: Don't remove commas if they exist as they can be part of pathnames
             Don't remove consecutive blanks if they exist in the parameter
       --------------------------------------------------------------------*/
      VARSPLIT:
      /* _Variables=tranwrd(_Variables,',',' '); */
      /* _Variables=compbl(_Variables);          */


         /*-----------------------------------------------------------------
          A special solution for to handle possible options for EXPLANATORY 
          variables describing hiearchies (which can be by numbers or a file name).
          This is revealed if there is parentheses within the string.
          ------------------------------------------------------------------
          Note: Build a string that hides space within parentheses (by use of 
                a temporary substitution char "Ã").
          -----------------------------------------------------------------*/
         if VarRole="EX" then do;
            _paren=0;
            do _i = 1 to length(_Variables);
               _token=substr(_Variables,_i,1);

               if _token='(' then _paren=1;
               if _token=')' then _paren=0;

               if _paren then do;
                  if _token=' ' then _token='Ã';
               end;
               else do;
                  if _token=' ' then _token='Æ';
               end;

               _String=cats(_String,_token);
            end;

            _Variables=translate(strip(_String),' ','Æ');
         end;


         /*-----------------------------------------------------------------
          Until no more value in the parameter
          ------------------------------------------------------------------
          Note: Increase counter. Read variable name in parameter
          -----------------------------------------------------------------*/
         _i=0;
         do until(_VarName='');                             
            _i+1;                                       
            _VarName = upcase(scan(_Variables,_i,' '));  

            /*--------------------------------------------------------------
             If there was a value (i.e. not yet read through all values)
             ---------------------------------------------------------------
             Note: Save variable name. Introduce alternative names to 
                   use. Increase Total counter and output values.
             --------------------------------------------------------------*/
            if _VarName ^= '' then do;                      

               /*-----------------------------------------------------------
                Special case when EXPLANATORY since here we can have options
                describing hierachies within parentheses (Numbers/Filename)
                -----------------------------------------------------------*/
               if VarRole='EX' then do;

                  HierLevels='';
                  HierCodeList='';
                  HierLeadString='';

                  /*--------------------------------------------------------
                   Split Varable name [VarName] and Options [VarOption]
                   --------------------------------------------------------*/
                  _Pos=indexc(_VarName,'(');
                  if _Pos then do;
                     _Option  =translate(substr(_VarName,_pos),'','()'); 
                     _VarName =substr(_VarName,1,_pos-1);
                     _Test    =compress(translate(_Option,'','Ã'));

                     /*-----------------------------------------------------
                      Not only numbers => A filename => <HIERCODELIST>
                      -----------------------------------------------------*/
                     if anyalpha(_Test) then do;

                        /*--------------------------------------------------
                         Assign <HIERCODELIST> and default <HIERLEADSTRING>
                         --------------------------------------------------*/
                        HierCodeList=propcase(strip(translate(_Option,' ','Ã')));
                        HierLeadString="@";

                        /*-----------------------------------------------------
                         Check if the user definied an alternative <HIERLEADSTRING>
                         That should be the last single character in HierCodeList
                         Clean in that case the path/filename for the HierCodeList
                         -----------------------------------------------------*/
                         _Pos=length(HierCodeList);
                         if _Pos > 3 then do;
                            if substr(HierCodeList,_Pos-1,1)=' ' and substr(HierCodeList,_pos,1)>' ' then do;
                               HierLeadString=substr(HierCodeList,_Pos,1);
                               HierCodeList=trim(substr(HierCodeList,1,_Pos-2));
                            end;
                         end;
                     end;

                     /*-----------------------------------------------------
                      Only numbers => Not a filename => <HIERLEVELS>
                      -----------------------------------------------------*/
                     else do;
                        HierLevels=strip(translate(_Option,' ','Ã'));
                     end;
                  end;
                  else _Option='';

               end;

               /*--------------------------------------------------------------
                Save variable name. Introduce alternative names to use. 
                --------------------------------------------------------------*/
               VarName    = strip(_VarName);
               VarNameTAU = propcase(strip(VarName));
               if VarRole = 'FR' then VarNameTAU="FreqVar";
               if VarRole = 'SH' then VarNameTAU="ShadowVar";
               if VarRole = 'CO' then VarNameTAU="CostVar";
               if VarRole = 'WE' then VarNameTAU="WeightVar";

               /*--------------------------------------------------------------
                Save argument as observation to table
                --------------------------------------------------------------*/
               SortOrder+1;
               output;
            end;
         end;
      return;

   run;
%mend Variable_Roles;
