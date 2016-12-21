/*==========================================================================
 Macro:        Present_HTML(Htmlfile)
 ---------------------------------------------------------------------------
 Description:  A macro that presents the HTML-file produced by tau-ARGUS in
               the SAS internal browser. 

 Parameters:   HTMLFILE - The name of the HTML file (qualified path)

 Precondition: File reference APPTMP and SASMAC has be assigned and files 
               referenced has to exist of course

 Comment:      A convenient way so the user don't have to leave the
               SAS session to examine those out in the file system.

 Note:         A quit "clumsy" solution - but there is not open ways to
               "reach" the SAS internal browsern from the "outside", a fact
               confirmed by SAS Institute support, Sweden. 

 Changes:      2016-11-15/ak   The old code didn´t work any more. A new macro was created and the old one was named %macro _comment.
                               The new macro export the HTML-report to the web browser.
 --------------------------------------------------------------------------*/

/*====================================================================
 Easy solution to just route the HTML-file to an external browser
 --------------------------------------------------------------------*/
%macro Present_HTML(Htmlfile)
   /Des="Presents tau-ARGUS HTML-file in the External Browser";

    option NOxwait NOXSYNC;
    data _null_;
       DM "wbrowse ""&htmlfile."" ";
    run;

%mend Present_HTML;



%macro _comment(Htmlfile)
   /Des="Presents tau-ARGUS HTML-file in the SAS Browser";

   %local _Htmlpath _Htmlfile;

   /*-----------------------------------------------------------------------
    Remove the suffix (if any) and add the .HTML suffix instead.
    -----------------------------------------------------------------------*/
   %let _Htmlfile=%sysfunc(prxchange(%str(s/\.[a-zåäöÅÄÖ]+$//i),1,&Htmlfile));
   %let _Htmlfile=&_Htmlfile..HTML;


   /*-----------------------------------------------------------------------
    Filename to the HTML file on disk and open a temporary file for SAS syntax
    -----------------------------------------------------------------------*/
   filename html_in  "&_Htmlfile.";
   filename html_cmd temp;


   /*-----------------------------------------------------------------------
    Does this file exists => If so  - Move it "into SAS browser"
                             It not - Leave 
    -----------------------------------------------------------------------*/
    %let _exist=%sysfunc(fexist(HTML_IN));
    %if &_exist=0 %then %goto exit;


   /*==========================================================================
    Create the syntax. 
    Note: ODS MARKUP TEXT demands a quoted string in its syntax. Therefore!!
    --------------------------------------------------------------------------*/
   data _null_;
      infile html_in lrecl=2500 truncover;
      input _row $2500.;
      file html_cmd;

      if findc(_row,"'") then _row=tranwrd(_row,"'","''");

      _row=cat("ods markup text='",strip(_row),"';");
      put _row;
   run;


   /*-----------------------------------------------------------------------
    A destination to write to and titles (for the Result explorer)
    Note: SCAN finds the last argument after chars / or \ => Filename
          as the second argument -1 does perform the scan backwords.
          WARNING: ODS NEWFILE= option is not supported in conjunction with 
                   BODY=fileref. => We don't use a fileref for the output
                   destination.
    -----------------------------------------------------------------------*/
   %let _Htmlpath=%sysfunc(pathname(WORK));
   %let _Htmlout=%scan(&_Htmlfile.,-1,\/);


   /*-----------------------------------------------------------------------
    SAS result don't "wake up" before it gets a proc result to route.
    Therefore a dummy datastep!!
    -----------------------------------------------------------------------*/
   options nocenter;
   title1 c=blue  f="Arial" H=1 "&_Htmlout.";
   title2 c=blue  bc=lightgrey f="Arial" bold H=4 "Executed by SAS2ARGUS-bridge between SAS and tau-Argus";
   data htmlout; 
      SAS2ARGUS="%sysfunc(pathname(SASmac))";
   run;


   /*-----------------------------------------------------------------------
    Route this to SAS internal browser.
    -----------------------------------------------------------------------*/
   %let _source =%sysfunc(getoption(source));
   %let _source2=%sysfunc(getoption(source2));
   %let _mprint =%sysfunc(getoption(mprint));
   options nosource nosource2 nomprint;

   ODS markup file="%bquote(&_Htmlpath.\&_Htmlout.)" newfile=NONE /* html_out */;
      proc print data=htmlout noobs label; run;
      %include html_cmd;
   ODS markup close;

   options &_source. &_source2. &_mprint.;;

   /*-----------------------------------------------------------------------
    Unassign
    -----------------------------------------------------------------------*/
   filename html_in  clear; 
   filename html_cmd clear;
   

   /*-----------------------------------------------------------------------
    Exit
    -----------------------------------------------------------------------*/
   %exit:
   title1;

%mend _comment;


