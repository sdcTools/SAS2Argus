/*==========================================================================
 Macro:        Open_Excel(Filename)
 ---------------------------------------------------------------------------
 Description:  Opens a file in Excel - that is if it has a suffix that 
               associates it with Excel as .CSV, .XLS, .XLSX

 Parameters:   FILENAME - The file to open

 Precondition: NONE but the file has to exist

 Comment:      If the argument set is qualified with path - we use that. 
               Otherwise we assume that the file is in the path of PATH_tmp.

 Note:         Just a utility macro in the context of SAS2ARGUS so it should
               be easy to examine files produced by Tau-ARGUS
 --------------------------------------------------------------------------*/
%macro open_excel(filename)/
   Des="Opens a file in Excel";
   options xwait noxsync;

   %if %index(&filename.,%str(\)) %then %do;
      x " ""&filename."" ";
   %end;
   %else %do;
      x " ""&PATH_tmp.\&filename."" ";
   %end;
%mend;
