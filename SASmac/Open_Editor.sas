/*==========================================================================
 Macro:        OPEN_EDITOR(file)
 ---------------------------------------------------------------------------
 Description:  Utility macro for to open a file in enhanced editor with the 
               name of the argument.

 Parameters:   FILE - The name of the file

 Precondition: PATH_tmp has to be set since the macro is hard coded to this
               catalog.

 Comment:      Just an easy way to show files in the SAS session.

 Note:         Since tau-ARGUS works with text-files it is neat to be able
               to see them in the SAS session.
 --------------------------------------------------------------------------*/
%macro Open_editor(file)
   /Des="Opens a file in enhanced editor";
   dm "whostedit  ""&PATH_tmp.\&file.""";
%mend Open_editor;




