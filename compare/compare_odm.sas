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

%include "%str(&_SASWS_./leo/development/library/metadata/compare_odm_1_3_2.sas)";

%compare_odm_1_3_2(odm1=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/LEO Common CRF Version 21 Draft.xml),debug=x,
                   odm2=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/Z Development CRF Version 1 Draft.xml));
%compare_odm_1_3_2(odm1=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/1401 CRF Version 7 Draft.xml),
                   odm2=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/1402 CRF Version 2 Draft.xml));
%compare_odm_1_3_2(odm1=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/1401 CRF Version 7 Draft.xml),
                   odm2=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/1403 CRF Version 2 Draft.xml));
%compare_odm_1_3_2(odm1=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/1402 CRF Version 2 Draft.xml),
                   odm2=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/1403 CRF Version 2 Draft.xml));
%compare_odm_1_3_2(odm1=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/LP0133-1528.xml),lang=en,oids=n,formedix=2,debug=x,
                   odm2=%str(&_SASWS_./leo/clinical/lp9999/8888/metadata/1528 CRF Version 1 Draft.xml));

