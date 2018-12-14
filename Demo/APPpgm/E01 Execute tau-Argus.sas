/*==========================================================================
 Program:      E01 Execute tau-ARGUS.sas
 ---------------------------------------------------------------------------
 Description:  Initialize the SAS session

 Comment:      Sets up the session, initial path on disk, 
               Sets global system parameters
 
 Parameters:   PATH_SAS - The path to the generic part
               PATH_TMP - The path to tau-ARGUS files
               PATH_APP - The path to the application part 

 Purpose:      Maintenance

 Precondition: NONE

 Usage:        Set the initial path on disk for this session

 Initial code: Fredrik Bernström SCB/IT/1
 Revised code: Anders Kraftling  SCB/IT/1
 Date:         2011-04-14
 Comment:      
 ---------------------------------------------------------------------------
 Changes:      Lars-Erik Almberg SCB/PMU/MFÖ    Changed data and shorten the code to just four examples     18-07-25
 ==========================================================================*/


/*==========================================================================
 Here follows the generic part - the system part of the SAS2ARGUS concept.
 ==========================================================================*/

/*==========================================================================
 Initial path location on disk (if useful)
 --------------------------------------------------------------------------*/
%let PATH_ini=\\SCB\program\Gemensamma\Net apps\StatProd\SAS2Argus;

/*==========================================================================
 Path to the generic part and version and the application part. Also give 
 the full path to tau_Argus executable [PATH_exe]
 --------------------------------------------------------------------------*/
%let PATH_sys=&Path_ini.\1.3;
%let PATH_app=&Path_ini.\Demo\Appdat;
%let PATH_tmp=&Path_ini.\Demo\Apptmp;
%let PATH_exe=C:\Program\TauArgus\tauARGUS.exe;


/*==========================================================================
 Init the SAS session
 Note: Sets up the searchpath for generic SAS programs and SAS macro. For
       SAS macros the AutoSource option is used.
 --------------------------------------------------------------------------*/
options notes nomprint nomlogic;
filename SASpgm "&PATH_sys.\SASpgm";
%include SASpgm("A01 Init Session.sas");


/*==========================================================================
 Macro:      System_Parameters
 ---------------------------------------------------------------------------
   Checks if:  
      - full PATH to tau-Argus exe is present so we can find it
      - EXE file for tau-Argus is present so we can use it
      - PATH_tmp is set explicit. Otherwise we route to SAS WORK-path 
   and reports finally the used tau-ARGUS work path to the SAS log
 --------------------------------------------------------------------------*/
%System_parameters;

/*==========================================================================
 Here ends the initialisation of the SAS session for use of the bridge
 between SAS and tau-ARgus
 ==========================================================================*/




/*==========================================================================
 Here beneth follows the specific part - the production part of the concept.
 ==========================================================================*/

/*==========================================================================
 Libname to data
 --------------------------------------------------------------------------*/
libname APPdat "&PATH_app";


/*==========================================================================
 EXAMPLE 1 – Micro data
 ---------------------------------------------------------------------------
 Magnitude table
 Primary and secondary suppressed table built from micro data
 --------------------------------------------------------------------------*/
%sas2argus(InData      = APPdat.TauMicro,
           Jobname     = Example1, 
           Explanatory = age omk, 
           Response    = Resp,
           SafetyRule  = P(20,1), 
		   Suppress    = OPT(1,2),
           Out         = inter(1), 
           RunArgus    = 1,
           SAS         = 2,
           Debug       = 1
)



/*--------------------------------------------------------------------------
 EXAMPLE 2 – Micro data - HIERARCHY
 Magnitude table
 Primary and secondary suppressed table built from micro data
--------------------------------------------------------------------------*/
%sas2argus(InData      = APPdat.Population,
           Jobname     = Example2, 
           Explanatory = Region (2 2 2) Age(&PATH_app\Age.hrc) Sex,
           Response    = Resp, 
           SafetyRule  = NK(1,50)|NK(2,80),
           Suppress    = GH(1,40,0), 
           Out         = inter(1), 
           RunArgus    = 1,
           SAS         = 2,
           Debug       = 1
)





/*--------------------------------------------------------------------------
 EXAMPLE 3 – Micro data - HIERARCHY
 Frequency table
 Primary and secondary suppressed table built from micro data
--------------------------------------------------------------------------*/
%sas2argus(InData      = APPdat.Population,
           Jobname     = Example3, 
           Explanatory = Region(2 2 2) Age(&PATH_app\Age.hrc) Sex,
           Response    = Count, 
           SafetyRule  = FREQ(3,30),
           Suppress    = GH(1,40,0),
           Out         = table() inter(1), 
           RunArgus    = 1,
           SAS         = 2,
           Debug       = 1
)



/*==========================================================================
 EXAMPLE 4 - 
 Magnitude table 
 Primary and secondary suppressed table built from aggregated table
 --------------------------------------------------------------------------*/
%sas2argus(InTable     = APPdat.TAUmicro_agg,
           Jobname     = Example4,
           Explanatory = Age Omk, 
           Response    = Resp,   
           MaxScore    = Top1 Top2,
           SafetyRule  = P(20,1),
           Suppress    = MOD(1,1),     
           Out         = inter(1),
           RunArgus    = 1,
           SAS         = 2,
           Debug       = 1
)



/*--------------------------------------------------------------------------
%open_editor(Example4.arb)
%open_editor(Example4.rda)
%open_editor(Example4.csv)
%open_editor(Example4.*)
%open_editor(Example4_out_5_1.csv)
%open_editor(Example4_out_5_1.rda)
 --------------------------------------------------------------------------*/


