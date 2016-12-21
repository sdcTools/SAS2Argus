/*==========================================================================
 Macro:        Remove_File(Filename)
 ---------------------------------------------------------------------------
 Description:  A macro that can remove (clean up disk) files

 Parameters:   FILENAME - The name of the file to remove (fully qualified)

 Precondition: NONE
 --------------------------------------------------------------------------*/
%macro Remove_File(FileName)
   /Des="Removes file with name of the arg from disk";
   data _null_;
       _file=" ""%bquote(&FileName.)"" "; 
       fname="_temp";
       rc=filename(fname,_file);
       if rc = 0 and fexist(fname) then
          rc=fdelete(fname);
       rc=filename(fname);
   run;
%mend Remove_File;
