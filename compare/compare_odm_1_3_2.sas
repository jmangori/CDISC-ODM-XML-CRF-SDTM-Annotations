/***********************************************************************************************/
/* Description: Compare 2 ODM-XML files by matching mandatory text values.                     */
/*              There are 3 categories of results when comparing:                              */
/*              - Records not matched (never displayed)                                        */
/*              - Records matched without change (display is governed by paramater EQUALS=Y/N) */
/*              - Records matched with change (always displayed)                               */
/***********************************************************************************************/
/* Disclaimer:  This program is the sole property of LEO Pharma A/S and may not be copied or   */
/*              made available to any third party without prior written consent from the owner */
/***********************************************************************************************/

%include "%str(&_SASWS_./leo/development/library/utilities/panic.sas)";
%include "%str(&_SASWS_./leo/development/library/utilities/relpath.sas)";
%include "%str(&_SASWS_./leo/development/library/metadata/odm_1_3_2.sas)";

options minoperator mindelimiter=',' msglevel=i;

%macro compare_odm_1_3_2(odm1=,     /* First ODM file to compare, full path  */
                         odm2=,     /* Second ODM file to compare, full path */
                     formedix=BOTH, /* ODMs in Formedix format? (0,1,2,both) */
                       equals=N,    /* Show equal values (y/n)               */
                         oids=Y,    /* Compare using OIDS, else names (y/n)  */
                      profile=D,    /* Show All/Dm/Pgm/ShrPt props. relevant */
                         lang=,     /* 2 letter Language code, if any        */
                        debug=);    /* If any value, preserve WORK etc.      */

  %if &debug ne %then %do;
    %put MACRO:    &sysmacroname;
    %put ODM1:     &odm1;
    %put ODM2:     &odm2;
    %put FORMEDIX: &formedix;
    %put EQUALS:   &equals;
    %put OIDS:     &oids;
    %put PROFILE:  &profile;
    %put LANG:     &lang;
    %put DEBUG:    &debug;
  %end;

  /* Validate arguments and setup default values */
  %let equals  = %qupcase(%qsysfunc(first(&equals)));
  %let oids    = %qupcase(%qsysfunc(first(&oids)));
  %let profile = %qupcase(%qsysfunc(first(&profile)));
  %if %nrquote(&odm1) =                   %then %panic(First ODM file is missing.);
  %if %sysfunc(fileexist("&odm1"))  = 0   %then %panic(First ODM file "&odm1" not found.);
  %if %nrquote(&odm2) =                   %then %panic(Second ODM file is missing.);
  %if %sysfunc(fileexist("&odm2")) = 0    %then %panic(Second ODM file "&odm2" not found.);
  %if %nrquote(&odm1) = %nrquote(&odm2)   %then %panic(No point in comparing an ODM file to itself.);
  %if %qupcase(&formedix) in (0,1,2,BOTH) %then; %else %panic(Formedix= must identify 0, 1, 2, or BOTH ODMs having Formedix tags);
  %if %nrquote(&equals) in (Y,N)          %then; %else %panic(%str(Equals must be %(Y%)es or %(N%)o, either case));
  %if %nrquote(&oids) in (Y,N)            %then; %else %panic(%str(OIDs must be %(Y%)es or %(N%)o, either case));
  %if %nrquote(&profile) in (A,D,P,S)     %then; %else %panic(%str(PROFILE="&profile" must be %(A%)ll, %(D%)ata Management, %(P%)rogramming, %(S%)harePoint, either case));
  %if %length(%nrquote(&lang)) = 0 or %length(%nrquote(&lang)) = 2 %then;
                                          %else %panic(Language "&lang" must be blank or a 2 letter code.);

        %if %nrquote(&oids)    = N %then %let profile = No OIDs;
  %else %if %nrquote(&profile) = D %then %let profile = Data Management;
  %else %if %nrquote(&profile) = P %then %let profile = Programming;
  %else %if %nrquote(&profile) = S %then %let profile = SharePoint;
  %else                                  %let profile = All;

/************************************************************************************************/
/* Set up which properties to display, depending on input files, options, profiles spread sheet */
/************************************************************************************************/
  /* Import display profiles spread sheet */
  proc import datafile="&_SASWS_./leo/development/library/metadata/Compare ODM Properties.xlsx"
                   out=odm_profiles (where=(never = '')) dbms=xlsx replace;
  run;

  /* Decide on which profile to use. Comparing without OIDs takes precedence */
  proc sql %if %nrquote(&debug) = %then noprint;;
    select distinct compress(subject)
      into :subject_dsn separated by ' '
      from odm_profiles;
    %let subjects = &sqlobs;
    %if %nrquote(&debug) ne %then %do;
      %put &=subjects;
      %put &=subject_dsn;
    %end;

    create table odm_properties as select distinct
           compress(subject) as subject,
           cats("'", upcase(property), "'") as property
      from odm_profiles
     where %if %nrquote(&oids)    = N %then No_OIDs;         %else
           %if %nrquote(&profile) = D %then Data_Management; %else
           %if %nrquote(&profile) = P %then Programming;     %else
           %if %nrquote(&profile) = S %then Sharepoint;      %else /* All */
           'X' = 'X';;
  quit;

  %do i = 1 %to &subjects;
    %symdel %scan(&subject_dsn, &i)_props / nowarn;
  %end;

  /* Bring all properties on the same observation as the subject dataset */
  proc transpose data=odm_properties out=odm_props (drop=_:);
    by subject;
    var property;
  run;

  /* Create a macro variable per subject dataset containing the properties to show */
  data _null_;
    set odm_props;
    array col [*] col1-col99;
    length temp $ 1000;
    do i = 1 to dim(col);
      if col[i] = '' then leave;
      temp = catx(' ', temp, col[i]);
    end;
    call symput(cats(subject, '_props'), temp);
    if "%nrquote(&debug)" ne "" then
      put subject +(-1) '_props = ' @20 temp;
  run;
/************************************************************************************************/
/* End of setting up properties to be displayed. Empty properties are never shown ***************/
/************************************************************************************************/

  /* Repeat for ODM1 and ODM2: Translate the ODM to SAS, decide on current or original, create transposed datasets */
  %do i = 1 %to 2;
    %if %qupcase(&formedix)=BOTH or &formedix=&i %then %let fdx=_formedix; %else %let fdx=;

    /* Clean up any leftover datasets from previous iteration */
    proc datasets lib=work nolist;
      delete CRF_: ODM&i._ _TEMP_:;
    quit;

    /* Convert ODM-XML to SAS datasets. Debug option preserves datasets for further use */
    %odm_1_3_2(metalib=work,
                   odm=&&odm&i,
                xmlmap=%str(&_SASWS_./leo/development/library/metadata/odm_1_3_2&fdx..map),
                  lang=%nrquote(&lang),
                 debug=always);

    /* Add ODM1_/ODM2_ prefix to all datasets extracted from the ODM to distinguish the 2 ODMs */
    data _null_;
      set sashelp.vtable end=tail;
      where upcase(libname) = 'WORK' and upcase(memname) = :'CRF_';
      if _N_ = 1 then call execute('proc datasets lib=work nolist;');
      if not exist("ODM&i._" || memname) then
        call execute(catx('', 'change', memname, '=', "ODM&i._" || memname, ';'));
      if tail then call execute ('delete CRF_:;quit;');
    run;

    %if &i = 1 %then %let var = Original_Value;
               %else %let var = Current_Value;

     /* Create a dataset of keys identifying forms, section, questions relationships */
     %if %sysfunc(exist(odm&i._crf_forms))     or
         %sysfunc(exist(odm&i._crf_sections))  or
         %sysfunc(exist(odm&i._crf_questions)) %then %do;
      proc sql;
        create table odm&i.keys as select distinct
             %if %sysfunc(exist(odm&i._crf_forms)) %then %do;
               q.OID                           as FormOID,
               coalescec(Form, FormAlias)      as Form,
             %end;
             %if %sysfunc(exist(odm&i._crf_sections)) %then %do;
               ItemgroupOID as SectOID,
               coalescec(s.name, SectionAlias) as Section,
             %end;
             %if %sysfunc(exist(odm&i._crf_questions)) %then %do;
               ItemOID as QuestOID,
               coalescec(Question, q.Name)     as Question
             %end;
          from odm&i._CRF_Questions     q
          left join odm&i._CRF_Sections s
            on q.ItemGroupOID = s.OID
          left join odm&i._CRF_Forms    f
            on q.OID = f.OID;
      quit;
    %end;

    /* Create datasets per ODM in a uniform structure (_C suffix) */
    %compare_odm_1_3_2_trans(odm=odm&i, var=&var, dsn=crf_study,       key=FileOID);
    %compare_odm_1_3_2_trans(odm=odm&i, var=&var, dsn=crf_visits,      key=VisitOID Visit);
    %compare_odm_1_3_2_trans(odm=odm&i, var=&var, dsn=crf_forms,       key=OID);
    %compare_odm_1_3_2_trans(odm=odm&i, var=&var, dsn=crf_visitmatrix, key=VisitOID FormOID);
    %compare_odm_1_3_2_trans(odm=odm&i, var=&var, dsn=crf_questions,   key=ItemOID ItemGroupOID OID);
    %compare_odm_1_3_2_trans(odm=odm&i, var=&var, dsn=crf_sections,    key=OID);
    %compare_odm_1_3_2_trans(odm=odm&i, var=&var, dsn=crf_datasets,    key=Dataset);
    %compare_odm_1_3_2_trans(odm=odm&i, var=&var, dsn=crf_variables,   key=Dataset Variable);
    %compare_odm_1_3_2_trans(odm=odm&i, var=&var, dsn=crf_codelists,   key=ID Name Decoded_Value);
  %end;

  /* Merge each dataset by predefined fixed match criteria */
  %compare_odm_1_3_2_dataset(dsn=crf_study);
  %compare_odm_1_3_2_dataset(dsn=crf_visits);
  %compare_odm_1_3_2_dataset(dsn=crf_forms);
  %compare_odm_1_3_2_dataset(dsn=crf_visitmatrix);
  %compare_odm_1_3_2_dataset(dsn=crf_questions);
  %compare_odm_1_3_2_dataset(dsn=crf_sections);
  %compare_odm_1_3_2_dataset(dsn=crf_datasets);
  %compare_odm_1_3_2_dataset(dsn=crf_variables);
  %compare_odm_1_3_2_dataset(dsn=crf_codelists);

  /* When a form is deleted, don't repeat all the sub-properties also deleted */
  %if %nrquote(&profile) in (D,S) and %sysfunc(exist(crf_forms)) %then %do;
    %let deleted_forms = 0;
    /* Count and identify forms deleted */
    proc sql %if %nrquote(&debug) = %then noprint;;
      select distinct form1
        into :deleted_form_id separated by '¤'
        from crf_forms
       where upcase(compare) = 'DELETED';
      %let deleted_forms = &sqlobs;
    %if %nrquote(&debug) ne %then %do;
      %put &=deleted_forms &=deleted_form_id;
    %end;

    /* Count and identify sections of deleted forms (questions?) */
    %let deleted_sects = 0;
    %if %sysfunc(exist(crf_sections)) %then %do;
       select distinct sect1
         into :deleted_sect_id separated by '¤'
         from crf_forms f
        inner join crf_sections s
           on f.form1 = s.form1
        where upcase(f.compare) = 'DELETED';
        %let deleted_sects = &sqlobs;
      %if %nrquote(&debug) ne %then %do;
        %put &=deleted_sects &=deleted_sect_id;
      %end;
    %end;
    quit;

    /* Don't report sub-properties of deleted forms */
    proc sql;
      %do i = 1 %to &deleted_forms;
          delete from crf_forms
           where form1 = "%scan(%nrbquote(&deleted_form_id), &i, ¤)" and property ne 'Form';
        %if %sysfunc(exist(crf_sections)) %then %do;
          delete from crf_sections
           where form1 = "%scan(%nrbquote(&deleted_form_id), &i, ¤)";
        %end;
        %if %sysfunc(exist(crf_questions)) %then %do;
          delete from crf_questions
           where form1 = "%scan(%nrbquote(&deleted_form_id), &i, ¤)";
        %end;
      %end;

      /* Don't report deleted datasets from deleted forms' sections */
      %do i = 1 %to &deleted_sects;
        delete from crf_datasets where sect1 = "%scan(%nrbquote(&deleted_sect_id), &i, ¤)";
      %end;
    quit;
  %end;

/***********************************************************************************************/
/***********************************************************************************************/
/*** Begin create toc **************************************************************************/
/***********************************************************************************************/
/***********************************************************************************************/

  /* Reporting order of datasets */
  proc format;
    invalue hier
    'crf_study'       = 1
    'crf_visits'      = 2
    'crf_visitmatrix' = 3
    'crf_forms'       = 4
    'crf_sections'    = 5
    'crf_questions'   = 6
    'crf_datasets'    = 7
    'crf_variables'   = 8
    'crf_codelists'   = 9
    ;
  run;

  /* Identify items to be compared and create a dataset level TOC datasets */
  %let study1 = Unknown;
  %let study2 = Unknown;
  proc sql %if %nrquote(&debug) = %then noprint;;
  %if %sysfunc(exist(odm1_crf_study_c)) %then %do;
    select original_value
      into :study1 trimmed
      from odm1_crf_study_c
     where property in ('ProtocolName' 'StudyName')
       and original_value ne '';
  %end;
  %if %sysfunc(exist(odm2_crf_study_c)) %then %do;
    select current_value
      into :study2 trimmed
      from odm2_crf_study_c
     where property in ('ProtocolName' 'StudyName')
       and current_value ne '';
  %end;
  %if %qupcase(&study1) = %qupcase(Not applicable) %then
    %let study1 = %qsysfunc(scan(&odm1, -2, %str(./)));
  %if %qupcase(&study2) = %qupcase(Not applicable) %then
    %let study2 = %qsysfunc(scan(&odm2, -2, %str(./)));
  %if %nrquote(&debug) ne %then %put &=study1 &=study2;

    create table toc1 as select distinct
           input(lowcase(memname), hier.)      as seq,
           memname                             as dsn,
           cats(upcase(scan(memname, 2, '_'))) as id,
           propcase(scan(memname, 2, '_'))     as display,
           cats("<div style='display:inline-block;' class='d'><a style='display:inline-block;color:white;text-align:center;padding:9px 9px;text-decoration:none;' href='#",
                calculated id, "'>", calculated display, "</a>")
             as nav label='Main level' length=5000
      from dictionary.tables
     inner join odm_props
        on cats(upcase(scan(memname, 2, '_'))) = upcase(subject)
     where upcase(libname) = "WORK"
       and upcase(substr(memname, 1, 4)) = "CRF_"
       and input(lowcase(memname), hier.) between 1 and 9
     order by seq;

    select distinct dsn
      into :datasets separated by ' '
      from toc1;

    %let dsno = &sqlobs;
    %if %nrquote(&debug) ne %then %do;
      %put &=dsno;
      %put &=datasets;
    %end;
  quit;

  /* List of all properties per dataset */
  data toc_properties;
    length original_value current_value $ 5000;
    set &datasets indsname=dataset;
    dsn = upcase(scan(dataset, 2, '.'));
    if compare ne '';
    keep dsn property compare;
  run;

  /* Remove empty values and duplicates and count differences per comparison */
  proc sql;
    create table toc_propnums as select distinct
           dsn length=32,
           property,
           compare,
           count(distinct cats(compare, property)) as difs
      from toc_properties
     where dsn      ne ''
     group by dsn, property, compare;
  quit;

  /* Create Property level toc dataset */
  proc sql;
    create table toc2 as select distinct
           toc1.*,
           difs,
           case when property = ''
                  or upcase(toc1.dsn) in ('CRF_STUDY', 'CRF_VISITS', 'CRF_VSITMATRIX')
                  or ("&equals") = "N" and difs = 0
                then ''
                else cats(id, upcase(compare), upcase(property)) end as id2,
           case when property = ''
                  or upcase(toc1.dsn) in ('CRF_STUDY', 'CRF_VISITS', 'CRF_VSITMATRIX')
                  or ("&equals") = "N" and difs = 0
                then ''
                else catx(' - ', display, catx(' ', compare, property)) end as display2,
           property,
           compare
      from toc1
      join toc_propnums
        on toc1.dsn = toc_propnums.dsn
     order by seq, property;

     /* Cleanup properties where they are not to reported individually */
     update toc2 set property = '' where id2 = '';

     /* Find datasets where all properties have no differences */
     %let nochanges=;
     select cats('"', dsn, '"')
       into :nochanges separated by ' '
       from toc2
      group by dsn
     having sum(difs) = 0;

     /* Trim the TOC datasets for datasets to be skipped, if any */
    %if "&nochanges" ne "" %then %do;
      delete from toc1 where dsn in (&nochanges);
      delete from toc2 where dsn in (&nochanges);
      %let dsno = %eval(&dsno - %sysfunc(countw(&nochanges)));
    %end;
  quit;

  /* Flip the Property level toc for vertical menu items */
  data toc2_t (keep=col1-col&dsno);
    set toc2 end=tail;
    by seq;
    length col1-col&dsno $ 5000;
    retain col1-col&dsno "<div class='dc'>" ix 0;
    array cols [*] col1-col&dsno;
    if first.seq then ix = ix + 1;
    if property ne '' then do;
      cols[ix] = cats(cols[ix], "<a style='color:white;padding:9px 9px;text-decoration:none;display:block;text-align:left;' href='#",
                      id2, "'>", catx(' ', compare, property), "</a>");
    end;
    if tail then do;
      do i = 1 to dim(cols);
        cols[i] = cats(cols[i], "</div>");
      end;
      output;
    end;
  run;

  /* Flip the toc for horizontal menu items */
  proc transpose data=toc1 out=toc1_t (drop=_:);
    var nav;
  run;

  /* Combine toc levels into one dataset */
  data toc3 (keep=nav1-nav&dsno);
    set toc1_t toc2_t indsname=dsn end=tail;
    length nav1-nav&dsno $ 5000;
    retain nav1-nav&dsno '';
    array navs [*] nav1-nav&dsno;
    array cols [*] col1-col&dsno;
    if lowcase(scan(dsn, 2, '.')) = 'toc1_t' then
      do i = 1 to &dsno;
        navs[i] = cols[i];
      end;
    else
      do i = 1 to &dsno;
        navs[i] = catx('^n', navs[i], cols[i]);
      end;
    if tail then do;
      do i = 1 to &dsno;
        navs[i] = cats(navs[i], '</div>');
      end;
      output;
    end;
  run;

/***********************************************************************************************/
/***********************************************************************************************/
/*** End create toc ****************************************************************************/
/***********************************************************************************************/
/***********************************************************************************************/

  title;

  ods listing close;
  ods escapechar='^';

  filename odscomp "%relpath/compare_odm_%trim(&study1)_%trim(&study2).html" new;
  ods html file=odscomp (no_bottom_matter title="Comparing %trim(&study1) to %trim(&study2)") style=EGDefault /* Normal EGDefault Default Daisy BarrettsBlue */
      headtext="<style>ol{position:fixed;top:0;}li{float:left}.d:hover .dc{display:block;}.dc{display:none;position:absolute;background-color:#888;color=black;-z-index:1;}@media print{.list{display:none;}}</style>";
      /* Headtext has a limit of 265 bytes */
  
  ods html close;
  filename odscomp "%relpath/compare_odm_%trim(&study1)_%trim(&study2).html" mod;
  ods html file=odscomp (no_top_matter no_bottom_matter);

  /* Print the TOC as a drop down menu fixed at the top */
  proc odslist data=toc3;
    item / style = { liststyletype=none };
      p 'Navigation' / style = { liststyletype=none color=transparent };
      list / style = { liststyletype=none margin=0 padding=0 backgroundcolor=#333 };
        /* First menu item is always scroll to top */
        item '<a style="display:inline-block;color:white;text-align:center;padding:9px 9px;text-decoration:none;" onClick="document.documentElement.scrollTop = 0" href="#">TOP</a>' / style = { liststyletype=none };
        %do i = 1 %to &dsno;
          item nav&i / style = { liststyletype=none };
        %end;
      end;
    end;
  run;

  ods html close;
  filename odscomp "%relpath/compare_odm_%trim(&study1)_%trim(&study2).html" mod;
  ods html file=odscomp (no_top_matter);

  /* Print the comparisons */
  title1 "Comparing %trim(&study1) to %trim(&study2)";
  proc sort data=toc2 nodupkey;
    by seq compare property;
  run;
  data _null_;
    set toc2;
    call execute(cats('%compare_odm_1_3_2_report(dsn=', dsn, ',id=', id, ',display=', display,
                      ',property=', property, ',compare=', compare, ',id2=', id2, ',display2=', display2, ');'));
  run;

  ods html close;
  ods listing;
  filename odscomp clear;

  /* Clean-up */
  %if %nrquote(&debug) = %then %do;
    proc datasets lib=work nolist;
      delete odm: crf: toc: _temp_: _tokens;
    quit;

    libname  odm clear;
    filename odm clear;
  %end;
%mend;

/* Transpose datasets to be compared */
%macro compare_odm_1_3_2_trans(odm=, var=, dsn=, key=);
  %if %nrquote(&debug) ne %then %do;
    %put MACRO: &sysmacroname;
    %put ODM:   &odm;
    %put VAR:   &var;
    %put DSN:   &dsn;
    %put KEY:   &key;
  %end;

  %if %sysfunc(exist(&odm._&dsn)) = 0 %then %return;

  /* Get list of variables that are NOT keys */
  %let vars=;
  %let nobs=0;
  proc sql %if %nrquote(&debug) = %then noprint;;
    select distinct name
      into :vars separated by ' '
      from dictionary.columns
     where upcase(libname) = "WORK"
       and upcase(memname) = "%upcase(&odm._&dsn)"
       and indexw("%upcase(&key)", upcase(name)) = 0;

    select distinct nobs
      into :nobs
      from dictionary.tables
     where upcase(libname) = "WORK"
       and upcase(memname) = "%upcase(&odm._&dsn)";
  quit;
  %if %nrquote(&debug) ne %then %put &=vars;

  %if %qupcase(&dsn) = CRF_STUDY %then %do;
    proc transpose data=&odm._&dsn
                    out=&odm._&dsn._c (rename=(_NAME_=Property COL1=&var));
      var &key &vars;
    run;
    %return;
  %end;

  %if %sysfunc(exist(&odm._&dsn)) = 0 or &nobs = 0 %then %do;
    /* If dataset don't exist, create empty comparison to catch both additions and deletions */
    data &odm._&dsn._t;
      length &key Property $ 200 &var $ 5000;
      stop;
    run;
  %end; %else %if &dsn = crf_datasets %then %do; /* Datasets */
    data &odm._&dsn._t;
      length OID &key Property $ 200 &var $ 5000;
      set &odm._&dsn;
      OID      = &key;
      &key     = &key;
      Property = "Dataset";
      &var     = &key;
    run;
  %end; %else %do;
    /* Copy and sort by the individual key */
    proc sort data=&odm._&dsn;
      by &key;
    run;

    /* Remove any labes for all variables */
    proc datasets lib=work nolist;
      modify &odm._&dsn;
        attrib _all_ label=' ';
      run;
    quit;

    /* Transpose all variables to observations */
    proc transpose data=&odm._&dsn
                    out=&odm._&dsn._t (rename=(_NAME_=Property COL1=&var));
      by  &key;
      var &vars;
    run;
  %end;
  
  %if %qupcase(&dsn) = CRF_VISITS and %qsysfunc(exist(&odm._&dsn._c)) = 0 %then %do;
    proc datasets lib=work nolist;
      change &odm._&dsn._t = &odm._&dsn._c;
    quit;
  %end;

  %else %if %qupcase(&dsn) = CRF_FORMS %then %do;
    proc sql;
      create table &odm._&dsn._c as select distinct
             t.*,
             Form
        from &odm._&dsn._t t
        left join &odm.keys k
          on t.OID = k.FormOID;
    quit;
  %end;

  %else %if %qupcase(&dsn) = CRF_VISITMATRIX %then %do;
    proc sql;
      create table &odm._&dsn._v as select distinct
             t.*,
         %if %qsysfunc(exist(&odm._crf_visits_c)) = 0 %then ''; %else 
             upcase(compress(visit)); as vmatch&odm,
         %if %qsysfunc(exist(&odm._crf_visits_c)) = 0 %then ''; %else 
             visit;                   as visit&odm
        from &odm._&dsn._t t
         %if %qsysfunc(exist(&odm._crf_visits_c)) %then %do;
        left join &odm._crf_visits_c v
          on t.VisitOID = v.VisitOID
         %end;
             ;

      create table &odm._&dsn._c as select distinct
             v.*,
             upcase(compress(Form)) as fmatch&odm,
             Form                   as form&odm
        from &odm._&dsn._v v
        left join &odm.keys k
          on v.FormOID = k.FormOID;
    quit;
  %end;

  %else %if %qupcase(&dsn) = CRF_SECTIONS %then %do;
    proc sql;
      create table &odm._&dsn._c as select distinct
             t.*,
             upcase(compress(Section)) as smatch&odm,
             Section                   as sect&odm,
             upcase(compress(Form))    as fmacth&odm,
             Form                      as form&odm,
             SectOID,
             FormOID
        from &odm._&dsn._t t
        left join &odm.keys k
          on t.OID = k.SectOID;
    quit;
  %end;

  %else %if %qupcase(&dsn) = CRF_QUESTIONS %then %do;
    proc sql;
      create table &odm._&dsn._c as select distinct
             t.*,
             upcase(compress(Question)) as qmatch&odm,
             Question                   as quest&odm,
             upcase(compress(section))  as smatch&odm,
             Section                    as sect&odm,
             upcase(compress(Form))     as fmatch&odm,
             Form                       as form&odm,
             SectOID,
             FormOID
        from &odm._&dsn._t t
        left join &odm.keys k
          on t.ItemOID = k.QuestOID;
    quit;
    %return;
  %end;

  %if %qupcase(&dsn) = CRF_DATASETS %then %do;
    proc sql;
      /* Find datasets from annotations where dataset ne domain (additional SUPPs) */
      create table &odm._&dsn._b as select distinct
             t.*
        from &odm._&dsn._t t
        left join &odm._crf_sections s
          on dataset = domain
       where s.name = '';

      /* Find which section the aliases questions are in via lookup in the ODM */
      create table &odm._&dsn._s as select distinct
             s.Domain                    as dataset,
             property,
             b.dataset                   as &var,
             k.SectOID                   as OID,
             upcase(compress(k.Section)) as smatch&odm,
             k.Section                   as sect&odm
        from &odm._&dsn._b b
        join ODM.ItemDefAlias a
          on indexw(Name, dataset, ' .')
        left join &odm.keys k
          on a.OID = k.QuestOID
        left join &odm._crf_sections s
          on k.SectOID = s.OID;

      /* Finalize and append into one dataset */
      create table &odm._&dsn._c as select distinct
             t.*,
             OID,
             upcase(compress(name)) as smatch&odm,
             name                   as sect&odm
        from &odm._&dsn._t (drop=OID) t
        left join &odm._crf_sections s
          on dataset = domain
       where name ne ''
       union select *
        from &odm._&dsn._s;
    quit;
  %end;

  %else %if %qupcase(&dsn) = CRF_VARIABLES %then %do;
    proc sql;
      create table &odm._&dsn._c as select distinct
             *,
             upcase(compress(cats(Dataset, '.', Variable))) as vmatch&odm,
             cats(Dataset, '.', Variable)                   as var&odm
        from &odm._&dsn._t;
    quit;

    /* Place a newline between each codelist entry for readability */
    data &odm._&dsn._c;
      set &odm._&dsn._c;
      if property = 'CodeListOID' then do;
        _temp = &var;
        &var = '';
        do _i = 1 to countw(_temp, ' ');
          &var = cats(&var, scan(_temp, _i, ' '), '^n');
        end;
      end;
      drop _:;
    run;
  %end;

  %else %if %qupcase(&dsn) = CRF_CODELISTS %then %do;
    proc sql;
      create table &odm._&dsn._c as select distinct
             t.*,
             upcase(compress(Name || Decoded_Value)) as cmatch&odm,
             Decoded_Value                           as code&odm
        from &odm._&dsn._t t;
    quit;
  %end;
%mend;

/* Merge dataset by designated match variables */
%macro compare_odm_1_3_2_dataset(dsn=);
  %if %nrquote(&debug) ne %then %do;
    %put MACRO: &sysmacroname;
    %put DSN:   &dsn;
  %end;

  %if %qsysfunc(exist(odm1_&dsn._c)) = 0 or %qsysfunc(exist(odm2_&dsn._c)) = 0 %then %return;

  %if %qsysfunc(exist(odm1_&dsn._c)) and %qsysfunc(exist(odm2_&dsn._c)) = 0 %then %do;
    %let names2=;
    proc sql %if %nrquote(&debug) = %then noprint;;
      create table odm2_&dsn._c
        like odm1_&dsn._c (rename=(Original_Value=Current_Value));
      select name
        into :names2 separated by ' '
        from dictionary.columns
       where upcase(libname) = 'WORK'
         and upcase(memname) = "%qupcase(odm2_&dsn._c)"
         and first(left(reverse(name))) = '1';
    quit;
    %if %nrquote(&debug) ne %then %put &=names2;
    %if &names2 ne %then %do;
      proc datasets lib=work nolist;
        modify odm2_&dsn._c;
          %do i = 1 %to %qsysfunc(countw(&names2));
            rename %qscan(&names2, &i) = %qsysfunc(translate(%qscan(&names2, &i), 2, 1));
          %end;
        run;
      quit;
    %end;
  %end;
  %if %qsysfunc(exist(odm1_&dsn._c)) = 0 and %qsysfunc(exist(odm2_&dsn._c)) %then %do;
    %let names1=;
    proc sql %if %nrquote(&debug) = %then noprint;;
      create table odm1_&dsn._c
        like odm2_&dsn._c (rename=(Current_Value=Original_Value));
      select name
        into :names1 separated by ' '
        from dictionary.columns
       where upcase(libname) = 'WORK'
         and upcase(memname) = "%qupcase(odm2_&dsn._c)"
         and first(left(reverse(name))) = '2';
    quit;
    %if %nrquote(&debug) ne %then %put &=names1;
    %if &names1 ne %then %do;
      proc datasets lib=work nolist;
        modify odm1_&dsn._c;
          %do i = 1 %to %qsysfunc(countw(&names2));
             rename %qscan(&names1, &i) = %qsysfunc(translate(%qscan(&names1, &i), 1, 2));
          %end;
        run;
      quit;
    %end;
  %end;

  %if %qupcase(&dsn) = CRF_STUDY %then %do;
    proc sql;
      create table &dsn as select coalescec(odm1.property, odm2.property) as Property,
             original_value,
             current_value,
             case when original_value eq '' and current_value ne '' then 'New'
                  when original_value ne '' and current_value eq '' then 'Deleted'
                  when original_value ne        current_value       then 'Changed'
                  else ''
             end as Compare length=20
        from odm1_&dsn._c odm1
        full outer join
             odm2_&dsn._c odm2
          on odm1.property = odm2.property
     %if %symexist(study_props) %then %do;
       where upcase(calculated property) in (&study_props)
     %end;
       order by compare, calculated property;
    quit;
  %end;

  %else %if %qupcase(&dsn) = CRF_VISITS %then %do;
    proc sql;
      create table &dsn as select
             odm1.visit as visit1,
             odm2.visit as visit2,
             coalescec(odm1.property, odm2.property) as Property,
             original_value,
             current_value,
             case when original_value eq '' and current_value ne '' then 'New'
                  when original_value ne '' and current_value eq '' then 'Deleted'
                  when original_value ne        current_value       then 'Changed'
                  else ''
             end as Compare length=20
        from odm1_&dsn._c odm1
        full outer join
             odm2_&dsn._c odm2
          on odm1.property = odm2.property
       %if %nrquote(&oids) = Y %then %do;
         and odm1.VisitOID = odm2.VisitOID
       %end; %else %do;
         and upcase(compress(odm1.visit)) =* upcase(compress(odm2.visit))
       %end;
     %if %symexist(visits_props) %then %do;
       where upcase(calculated property) in (&visits_props)
     %end;
       order by odm1.visit, odm2.visit, compare, calculated property;
    quit;
  %end;

  %else %if %qupcase(&dsn) = CRF_FORMS %then %do;
    proc sql;
      create table &dsn as select
             case when cats(odm1.oid, odm1.form) = '' then ''
                  else catx('^n', 'OID=' || odm1.oid, odm1.form)
             end as form1 length=500,
             case when cats(odm2.oid, odm2.form) = '' then ''
                  else catx('^n', 'OID=' || odm2.oid, odm2.form)
             end as form2 length=500,
             coalescec(odm1.property, odm2.property) as Property,
             original_value,
             current_value,
             case when original_value eq '' and current_value ne '' then 'New'
                  when original_value ne '' and current_value eq '' then 'Deleted'
                  when original_value ne        current_value       then 'Changed'
                  else ''
             end as Compare length=20
        from odm1_&dsn._c odm1
        full outer join
             odm2_&dsn._c odm2
          on odm1.property = odm2.property
       %if %nrquote(&oids) = Y %then %do;
         and odm1.OID = odm2.OID
       %end; %else %do;
        and upcase(compress(odm1.form)) =* upcase(compress(odm2.form))
       %end;
     %if %symexist(forms_props) %then %do;
       where upcase(calculated property) in (&forms_props)
     %end;
       order by odm1.form, odm2.form, compare, calculated property;
    quit;
  %end;

  %else %if %qupcase(&dsn) = CRF_VISITMATRIX %then %do;
    proc sql;
      create table &dsn as select
             visitodm1,
             formodm1,
             visitodm2,
             formodm2,
             coalescec(odm1.property, odm2.property) as Property,
             original_value,
             current_value,
             case when original_value eq '' and current_value ne '' then 'New'
                  when original_value ne '' and current_value eq '' then 'Deleted'
                  when original_value ne        current_value       then 'Changed'
                  else ''
             end as Compare length=20
        from odm1_&dsn._c odm1
        full outer join
             odm2_&dsn._c odm2
          on odm1.property = odm2.property
       %if %nrquote(&oids) = Y %then %do;
         and odm1.VisitOID = odm2.VisitOID
         and odm1.FormOID  = odm2.FormOID
       %end; %else %do;
         and vmatchodm1   =* vmatchodm2
         and fmatchodm1   =* fmatchodm2
       %end;
     %if %symexist(visitmatrix_props) %then %do;
       where upcase(calculated property) in (&visitmatrix_props)
     %end;
       order by visitodm1, visitodm2, formodm1, formodm2, compare, calculated property;
    quit;
  %end;

  %else %if %qupcase(&dsn) = CRF_SECTIONS %then %do;
    proc sql;
      create table &dsn as select
             case when cats(odm1.FormOID, formodm1) = '' then ''
                  else catx('^n', 'OID=' || odm1.FormOID, formodm1)
             end as form1 length=500,
             case when cats(odm1.SectOID, sectodm1) = '' then ''
                  else catx('^n', 'OID=' || odm1.SectOID, sectodm1)
             end as sect1 length=500,
             case when cats(odm2.FormOID, formodm2) = '' then ''
                  else catx('^n', 'OID=' || odm2.FormOID, formodm2)
             end as form2 length=500,
             case when cats(odm2.FormOID, sectodm2) = '' then ''
                  else catx('^n', 'OID=' || odm2.SectOID, sectodm2)
             end as sect2 length=500,
             coalescec(odm1.property, odm2.property) as Property,
             original_value,
             current_value,
             case when original_value eq '' and current_value ne '' then 'New'
                  when original_value ne '' and current_value eq '' then 'Deleted'
                  when original_value ne        current_value       then 'Changed'
                  else ''
             end as Compare length=20
        from odm1_&dsn._c odm1
        full outer join
             odm2_&dsn._c odm2
          on odm1.property = odm2.property
       %if %nrquote(&oids) = Y %then %do;
         and odm1.FormOID  = odm2.FormOID
         and odm1.SectOID  = odm2.SectOID
       %end; %else %do;
         and fmacthodm1   =* fmacthodm2
         and smatchodm1   =* smatchodm2
       %end;
     %if %symexist(sections_props) %then %do;
       where upcase(calculated property) in (&sections_props)
     %end;
       order by formodm1, formodm2, sectodm1, sectodm1, compare, calculated property;
    quit;
  %end;

  %else %if %qupcase(&dsn) = CRF_QUESTIONS %then %do;
    proc sql;
      create table &dsn as select
             case when cats(odm1.FormOID, formodm1) = '' then ''
                  else catx('^n', 'OID=' || odm1.FormOID, formodm1)
             end as form1 length=500,
             case when cats(odm1.SectOID, sectodm1) = '' then ''
                  else catx('^n', 'OID=' || odm1.SectOID, sectodm1)
             end as sect1 length=500,
             case when cats(odm1.ItemOID, questodm1) = '' then ''
                  else catx('^n', 'OID=' || odm1.ItemOID, questodm1)
             end as quest1 length=500,
             case when cats(odm2.FormOID, formodm2) = '' then ''
                  else catx('^n', 'OID=' || odm2.FormOID, formodm2)
             end as form2 length=500,
             case when cats(odm2.SectOID, sectodm2) = '' then ''
                  else catx('^n', 'OID=' || odm2.SectOID, sectodm2)
             end as sect2 length=500,
             case when cats(odm2.ItemOID, questodm2) = '' then ''
                  else catx('^n', 'OID=' || odm2.ItemOID, questodm2)
             end as quest2 length=500,
             coalescec(odm1.property, odm2.property) as Property,
             original_value,
             current_value,
             case when original_value eq '' and current_value ne '' then 'New'
                  when original_value ne '' and current_value eq '' then 'Deleted'
                  when original_value ne        current_value       then 'Changed'
                  else ''
             end as Compare length=20
        from odm1_&dsn._c odm1
        full outer join
             odm2_&dsn._c odm2
          on odm1.property = odm2.property
       %if %nrquote(&oids) = Y %then %do;
         and odm1.FormOID  = odm2.FormOID
         and odm1.SectOID  = odm2.SectOID
         and odm1.ItemOID  = odm2.ItemOID
       %end; %else %do;
         and qmatchodm1   =* qmatchodm2
         and smatchodm1   =* smatchodm2
         and fmatchodm1   =* fmatchodm2
       %end;
     %if %symexist(questions_props) %then %do;
       where upcase(calculated property) in (&questions_props)
     %end;
       order by formodm1, formodm2, sectodm1, sectodm1, questodm1, questodm2, compare, calculated property;
    quit;
  %end;

  %else %if %qupcase(&dsn) = CRF_DATASETS %then %do;
    proc sql;
      create table &dsn as select
             case when cats(odm1.OID, sectodm1) = '' then ''
                  else catx('^n', 'OID=' || odm1.OID, sectodm1)
             end as sect1 length=500,
             case when cats(odm2.OID, sectodm2) = '' then ''
                  else catx('^n', 'OID=' || odm2.OID, sectodm2)
             end as sect2 length=500,
             coalescec(odm1.property, odm2.property) as Property,
             original_value,
             current_value,
             case when original_value eq '' and current_value ne '' then 'New'
                  when original_value ne '' and current_value eq '' then 'Deleted'
                  when original_value ne        current_value       then 'Changed'
                  else ''
             end as Compare length=20,
             count(distinct(cats(calculated sect1, calculated sect2))) as OID_cardinal
        from odm1_&dsn._c odm1
        full outer join
             odm2_&dsn._c odm2
          on odm1.property = odm2.property
       %if %nrquote(&oids) = Y %then %do;
         and odm1.OID = odm2.OID
       %end; %else %do;
         and smatchodm1 =* smatchodm2
       %end;
     %if %symexist(datasets_props) %then %do;
       where upcase(calculated property) in (&datasets_props)
     %end;
       group by sectodm1, sectodm2, compare, calculated property
       order by sect1,    sect2,    compare, calculated property;
    quit;
    /* Find pairs of datasets where original and current values are crossed */
    data odm_datasets_cardinals;
      set &dsn;
      by  sect1;
      length original1 original2 current1 current2 $ 5000;
      retain original1 original2 current1 current2 '';
      where OID_cardinal = 2 and Compare = 'Changed';
      if first.sect1 then do;
        original1 = original_value;
        current1  = current_value;
      end;
      if last.sect1 then do;
        original2 = original_value;
        current2  = current_value;
      end;
      if last.sect1;
      if original1 = current2 and original2 = current1;
    run;
    /* Remove duplicates when Alias contains datasets beyond Domain */
    proc sql noprint;
      delete
        from &dsn a
       where exists (select *
                       from odm_datasets_cardinals b
                      where a.sect1 = b.sect1
                        and a.sect2 = b.sect2);
       alter table &dsn drop OID_cardinal;
      select distinct * from &dsn; /* Set &sqlobs for later */
    quit;
  %end;

  %else %if %qupcase(&dsn) = CRF_VARIABLES %then %do;
    proc sql;
      create table &dsn as select
             varodm1,
             varodm2,
             coalescec(odm1.property, odm2.property) as Property,
             original_value,
             current_value,
             case when original_value eq '' and current_value ne '' then 'New'
                  when original_value ne '' and current_value eq '' then 'Deleted'
                  when original_value ne        current_value       then 'Changed'
                  else ''
             end as Compare length=20
        from odm1_&dsn._c odm1,
             odm2_&dsn._c odm2
       where odm1.property = odm2.property
         and vmatchodm1 = vmatchodm2
     %if %symexist(variables_props) %then %do;
         and upcase(calculated property) in (&variables_props)
     %end;
       order by varodm1, varodm2, compare, calculated property;
    quit;
  %end;

  %else %if %qupcase(&dsn) = CRF_CODELISTS %then %do;
    proc sql;
      create table &dsn as select
             odm1.name as name1,
             odm2.name as name2,
             codeodm1,
             codeodm2,
             coalescec(odm1.property, odm2.property) as Property,
             original_value,
             current_value,
             case when original_value eq '' and current_value ne '' then 'New'
                  when original_value ne '' and current_value eq '' then 'Deleted'
                  when original_value ne        current_value       then 'Changed'
                  else ''
             end as Compare length=20
        from odm1_&dsn._c odm1,
             odm2_&dsn._c odm2
       where odm1.property = odm2.property
         and cmatchodm1    = cmatchodm2
     %if %symexist(variables_props) %then %do;
         and upcase(calculated property) in (&variables_props)
     %end;
       order by codeodm1, codeodm2, compare, calculated property;
    quit;
  %end;

  /* Remove any duplicates generated by carthesian products */
  /* Remove Property = Order/OrderNumber as they are not maintained consistently */
  proc sort data=&dsn nodup;
    by _ALL_;
    where property not in ('Order', 'OrderNumber');
  run;

  /* Delete empty datasets */
  %if &sqlobs = 0 %then %do;
    proc datasets lib=work nolist;
      delete &dsn;
    quit;
  %end;
%mend;

/* Print comparison by property
%macro compare_odm_1_3_2_report(dsn=, id=, display=, property=, compare=, id2=, display2=);
  %if %nrquote(&debug) ne %then %do;
    %put MACRO:    &sysmacroname;
    %put DSN:      &dsn;
    %put ID:       &id;
    %put DISPLAY:  &display;
    %put PROPERTY: &property;
    %put COMPARE:  &compare;
    %put ID2:      &id2;
    %put DISPLAY2: &display2;
  %end;

  title2 "^{raw <a id='&id'/><a id='&id2'>&display2 property</a>}";

  proc print data=&dsn noobs label style(table)=[HTMLCLASS='data'];
    label original_value="&study1" current_value="&study2";
  %if %qupcase(&dsn) = CRF_STUDY %then %do;
    var property original_value current_value;
    %if %nrquote(&equals) = N %then where original_value ne current_value;;
  %end; %else %if %qupcase(&dsn) = CRF_VISITS %then %do;
    label visit1="&study1 Visit" visit2="&study2 Visit";
    var visit1 visit2 property original_value current_value;
    %if %nrquote(&equals) = N %then where original_value ne current_value;;
  %end; %else %if %qupcase(&dsn) = CRF_FORMS %then %do;
    label form1="&study1 Form" form2="&study2 Form";
    var form1 form2 property original_value current_value;
    where property = "&property" and compare = "&compare"
    %if %nrquote(&equals) = N %then and original_value ne current_value;;
  %end; %else %if %qupcase(&dsn) in (CRF_VISITMATRIX) %then %do;
    label visitodm1="&study1 Visit" formodm1="&study1 Form" visitodm2="&study2 Visit" formodm2="&study2 Form";
    var visitodm1 formodm1 visitodm2 formodm2 property original_value current_value;
    where property = "&property" and compare = "&compare"
    %if %nrquote(&equals) = N %then and original_value ne current_value;;
  %end; %else %if %qupcase(&dsn) = CRF_SECTIONS %then %do;
    label form1="&study1 Form" sect1="&study1 Section" form2="&study2 Form" sect2="&study2 Section";
    var form1 sect1 form2 sect2 property original_value current_value;
    where property = "&property" and compare = "&compare"
    %if %nrquote(&equals) = N %then and original_value ne current_value;;
  %end; %else %if %qupcase(&dsn) = CRF_QUESTIONS %then %do;
    label form1="&study1 Form" sect1="&study1 Section" quest1="&study1 Question"
          form2="&study2 Form" sect2="&study2 Section" quest2="&study2 Question";
    var form1 sect1 quest1 form2 sect2 quest2 property original_value current_value;
    where property = "&property" and compare = "&compare"
    %if %nrquote(&equals) = N %then and original_value ne current_value;;
  %end; %else %if %qupcase(&dsn) = CRF_DATASETS %then %do;
    label sect1="&study1 Section" sect2="&study2 Section";
    var sect1 sect2 property original_value current_value;
    where property = "&property" and compare = "&compare"
    %if %nrquote(&equals) = N %then and original_value ne current_value;;
  %end; %else %if %qupcase(&dsn) = CRF_VARIABLES %then %do;
    label varodm1="&study1 Variable" varodm2="&study2 Variable";
    var varodm1 varodm2 property original_value current_value;
    where property = "&property" and compare = "&compare"
    %if %nrquote(&equals) = N %then and original_value ne current_value;;
  %end; %else %if %qupcase(&dsn) = CRF_CODELISTS %then %do;
    label codeodm1="&study1 CodeList Item" codeodm2="&study2 CodeList Item" name1="&study1 CodeList Name" name2="&study2 CodeList Name";
    var name1 codeodm1 name2 codeodm2 property original_value current_value;
    where property = "&property" and compare = "&compare"
    %if %nrquote(&equals) = N %then and original_value ne current_value;;
  %end;
  run;
%mend;
 */
/* Tabulate comparison by property
%macro compare_odm_1_3_2_report(dsn=, id=, display=, property=, compare=, id2=, display2=);
  %if %nrquote(&debug) ne %then %do;
    %put MACRO:    &sysmacroname;
    %put DSN:      &dsn;
    %put ID:       &id;
    %put DISPLAY:  &display;
    %put PROPERTY: &property;
    %put COMPARE:  &compare;
    %put ID2:      &id2;
    %put DISPLAY2: &display2;
  %end;

  title2 "^{raw <a id='&id'/><a id='&id2'>&display2 property</a>}";

  %let where = 1=1;
  %if %nrquote(&equals) = N %then %let where = &where. and original_value ne current_value;
  %if %qupcase(&dsn) in (CRF_STUDY, CRF_VISITS) %then;
  %else %let where = &where and property = "&property" and compare = "&compare";

  proc tabulate data=&dsn style=[HTMLCLASS='data'];
    where &where;;
    label original_value="&study1" current_value="&study2";
    class original_value current_value;

  %if %qupcase(&dsn) = CRF_STUDY %then %do;
    class property;
    table property original_value current_value;
  %end; %else %if %qupcase(&dsn) = CRF_VISITS %then %do;
    label visit1="&study1 Visit" visit2="&study2 Visit";
    class visit1 visit2 property;
    table visit1 visit2, property original_value current_value;
  %end; %else %if %qupcase(&dsn) = CRF_FORMS %then %do;
    label form1="&study1 Form" form2="&study2 Form";
    class form1 form2 property;
    table form1 form2, property original_value current_value;
  %end; %else %if %qupcase(&dsn) in (CRF_VISITMATRIX) %then %do;
    label visitodm1="&study1 Visit" formodm1="&study1 Form" visitodm2="&study2 Visit" formodm2="&study2 Form";
    class visitodm1 formodm1 visitodm2 formodm2 property;
    table visitodm1 formodm1 visitodm2 formodm2, property original_value current_value;
  %end; %else %if %qupcase(&dsn) = CRF_SECTIONS %then %do;
    label form1="&study1 Form" sect1="&study1 Section" form2="&study2 Form" sect2="&study2 Section";
    class form1 sect1 form2 sect2 property;
    table form1 sect1 form2 sect2, property original_value current_value;
  %end; %else %if %qupcase(&dsn) = CRF_QUESTIONS %then %do;
    label form1="&study1 Form" sect1="&study1 Section" quest1="&study1 Question"
          form2="&study2 Form" sect2="&study2 Section" quest2="&study2 Question";
    class form1 sect1 quest1 form2 sect2 quest2 property;
    table form1 sect1 quest1 form2 sect2 quest2, property original_value current_value;
  %end; %else %if %qupcase(&dsn) = CRF_DATASETS %then %do;
    label sect1="&study1 Section" sect2="&study2 Section";
    class sect1 sect2 property;
    table sect1 sect2, property original_value current_value;
  %end; %else %if %qupcase(&dsn) = CRF_VARIABLES %then %do;
    label varodm1="&study1 Variable" varodm2="&study2 Variable";
    class varodm1 varodm2 property;
    table varodm1 varodm2, property original_value current_value;
  %end; %else %if %qupcase(&dsn) = CRF_CODELISTS %then %do;
    label codeodm1="&study1 CodeList Item" codeodm2="&study2 CodeList Item" name1="&study1 CodeList Name" name2="&study2 CodeList Name";
    class name1 codeodm1 name2 codeodm2 property;
    table name1 codeodm1 name2 codeodm2, property original_value current_value;
  %end;
  run;
%mend;
 */
/* Report comparison by property */
%macro compare_odm_1_3_2_report(dsn=, id=, display=, property=, compare=, id2=, display2=);
  %if %nrquote(&debug) ne %then %do;
    %put MACRO:    &sysmacroname;
    %put DSN:      &dsn;
    %put ID:       &id;
    %put DISPLAY:  &display;
    %put PROPERTY: &property;
    %put COMPARE:  &compare;
    %put ID2:      &id2;
    %put DISPLAY2: &display2;
  %end;

  title2 "^{raw <a id='&id'/><a id='&id2'>&display2 property</a>}";

  %let where = 1=1;
  %if %nrquote(&equals) = N %then %let where = &where. and original_value ne current_value;
  %if %qupcase(&dsn) in (CRF_STUDY, CRF_VISITS) %then;
  %else %let where = &where and property = "&property" and compare = "&compare";

  proc report data=&dsn style=[HTMLCLASS='data'];
    where &where;;

    label original_value='Original Value' current_value='Current Value';
    %if %qupcase(&dsn) = CRF_STUDY %then %do;
    %end; %else %if %qupcase(&dsn) = CRF_VISITS %then %do;
      label visit1='Visit' visit2='Visit';
    %end; %else %if %qupcase(&dsn) = CRF_FORMS %then %do;
      label form1='Form' form2='Form';
    %end; %else %if %qupcase(&dsn) in (CRF_VISITMATRIX) %then %do;
      label visitodm1='Visit' formodm1='Form' visitodm2='Visit' formodm2='Form';
    %end; %else %if %qupcase(&dsn) = CRF_SECTIONS %then %do;
      label form1='Form' sect1='Section' form2='Form' sect2='Section';
    %end; %else %if %qupcase(&dsn) = CRF_QUESTIONS %then %do;
      label form1='Form' sect1='Section' quest1='Question' form2='Form' sect2='Section' quest2='Question';
    %end; %else %if %qupcase(&dsn) = CRF_DATASETS %then %do;
      label sect1='Section' sect2='Section';
    %end; %else %if %qupcase(&dsn) = CRF_VARIABLES %then %do;
      label varodm1='Variable' varodm2='Variable';
    %end; %else %if %qupcase(&dsn) = CRF_CODELISTS %then %do;
      label codeodm1='CodeList Item' name1='CodeList Name' codeodm2='CodeList Item' name2='CodeList Name';
    %end;

    column ('Keys'
    %if %qupcase(&dsn) = CRF_STUDY %then %do;
    %end; %else %if %qupcase(&dsn) = CRF_VISITS %then %do;
      ("&study1" visit1) ("&study2" visit2)
    %end; %else %if %qupcase(&dsn) = CRF_FORMS %then %do;
      ("&study1" form1) ("&study2" form2)
    %end; %else %if %qupcase(&dsn) in (CRF_VISITMATRIX) %then %do;
      ("&study1" visitodm1 formodm1) ("&study2" visitodm2 formodm2)
    %end; %else %if %qupcase(&dsn) = CRF_SECTIONS %then %do;
      ("&study1" form1 sect1) ("&study2" form2 sect2)
    %end; %else %if %qupcase(&dsn) = CRF_QUESTIONS %then %do;
      ("&study1" form1 sect1 quest1) ("&study2" form2 sect2 quest2)
    %end; %else %if %qupcase(&dsn) = CRF_DATASETS %then %do;
      ("&study1" sect1) ("&study2" sect2)
    %end; %else %if %qupcase(&dsn) = CRF_VARIABLES %then %do;
      ("&study1" varodm1) ("&study2" varodm2)
    %end; %else %if %qupcase(&dsn) = CRF_CODELISTS %then %do;
      ("&study1" name1 codeodm1) ("&study2" name2 codeodm2)
    %end;
    ) ('Values' ("&study1" original_value) ("&study2" current_value));

/*
    %if %qupcase(&dsn) = CRF_STUDY %then %do;
    %end; %else %if %qupcase(&dsn) = CRF_VISITS %then %do;
      define visit1    / order;
      define visit2    / order;
    %end; %else %if %qupcase(&dsn) = CRF_FORMS %then %do;
      define form1     / order;
      define form2     / order;
    %end; %else %if %qupcase(&dsn) in (CRF_VISITMATRIX) %then %do;
      define visitodm1 / order;
      define formodm1  / order;
      define visitodm2 / order;
      define formodm2  / order;
    %end; %else %if %qupcase(&dsn) = CRF_SECTIONS %then %do;
      define form1     / order;
      define sect1     / order;
      define form2     / order;
      define sect2     / order;
    %end; %else %if %qupcase(&dsn) = CRF_QUESTIONS %then %do;
      define form1     / order;
      define sect1     / order;
      define quest1    / order;
      define form2     / order;
      define sect2     / order;
      define quest2    / order;
    %end; %else %if %qupcase(&dsn) = CRF_DATASETS %then %do;
      define sect1     / order;
      define sect2     / order;
    %end; %else %if %qupcase(&dsn) = CRF_VARIABLES %then %do;
      define varodm1   / order;
      define varodm2   / order;
    %end; %else %if %qupcase(&dsn) = CRF_CODELISTS %then %do;
      define name1     / order;
      define codeodm1  / order;
      define name2     / order;
      define codeodm2  / order;
    %end;
*/
  run;
%mend;

/*
%compare_odm_1_3_2(odm1=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/LEO Common CRF Version 18 Production.xml),debug=x,profile=s,
                   odm2=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/LEO Common CRF Version 21 Production.xml));

%compare_odm_1_3_2(odm1=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/LEO Common CRF Version 21 Draft.xml),debug=x,
                   odm2=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/Z Development CRF Version 1 Draft.xml));

%compare_odm_1_3_2(odm1=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/1401 CRF Version 7 Draft.xml),
                   odm2=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/1402 CRF Version 2 Draft.xml));
%compare_odm_1_3_2(odm1=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/1401 CRF Version 7 Draft.xml),
                   odm2=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/LP0133-1401 - Metdata Version 297.xml),
               formedix=1, lang=en, oids=n, debug=x);

%compare_odm_1_3_2(odm1=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/LP0133-1528 Version 4 ODM JMIDK.xml),formedix=2,oids=n,lang=en,
                   odm2=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/1528 CRF Version 1 Draft.xml));

%compare_odm_1_3_2(odm1=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/NCI CT.xml),
                   odm2=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/LEO CT.xml), debug=x);
*/