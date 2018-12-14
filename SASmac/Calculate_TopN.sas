/*==========================================================================
 Macro:        Calculate_TopN(Indata=, Outdata=, ClassVar=, Var=, TopN=)
 ---------------------------------------------------------------------------
 Description:  A SAS macro for calculation of TopN contributors (TOPN) for a 
               Response variable (VAR), by class (CLASSVAR) in dataset (INDATA) 
                  
 Parameters:   INDATA   - Name of dataset.         (Qualified)
              [OUTDATA] - Optional. Name of out dataset.
               CLASSVAR - Name of class variables. (Space separeted)
               VAR      - Name of response variable.
               TOPN     - Number of max contributors to the domain.

 Precondition: NONE
                               
 Comment:      A useful macro for preparing aggregation of data before
               disclosure by use of tau-ARGUS.

 Note:         Default name for created output dataset is <Indata>_Agg
               Default name for created variables for TopN is <Var>_TopN
 --------------------------------------------------------------------------*/
%macro Calculate_TopN(indata=, outdata=, classvar=, var=, topn=)
   /Des="Calculates TopN contributors by domain (class)";

   %if &outdata.=%str() %then %let outdata=&indata._Agg;

   /*-----------------------------------------------------------------------
    Aggregate and determine TopN contributors to each domain (class).
    Note: NWAY removed since TauArgus expect the table to be summarizeable
    -----------------------------------------------------------------------*/
   proc means data=&indata. Missing CompleteTypes /* NWay */  NoPrint;
      class &classvar.;
      var &var.;
      output out=&outdata.
             sum=&var. 
             idgroup(max(&var.) 
                     out[&topn.]
                    (&var.)=&var._TopN)/NoInherit;
   run;
%mend;
