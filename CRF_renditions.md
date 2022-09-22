#### Table of Contents
* [CRF Renditions](#CRF_Renditions)
   * [CRF layout](#CRF_layout)
   * [Design choices](#Design_choices)
      * [SDTM Datasets and Variables](#SDTM_Datasets_and_Variables)
   * [Parameters](#Parameters)
   * [Creating PDF documents](#Creating_PDF_documents)

# CRF Renditions <a name="CRF_Renditions"/>
A short description of the CRF generated from the ODM-xml document.

## CRF layout <a name="CRF_layout"/>
The main feature of the CRF layout presented here is to put the SDTM annotations in a column adjacent to each question line. This way the SDTM annotations are displayed at the proper location, without the need to move boxes of annotations around inside and on top of CRF elements.

![Example CRF rendition from pure ODM-xml](images/CRF.png)

The CRF rendition consists of one table for each Form in the CRF, identified as **FormDef** tags, having the columns below.
1. A sequence number constructed from the **@OrderNumber** attributes of **ItemGroupRef** and **ItemRef** tags in the ODM-xml file. The number serves as a human reference when discussing and reviewing CRF content, as well as keeping track of the sorting of CRF elements. If a Form or a question has an implementation note, a hash sign (**#**) is shown next to the number, and the actual note in a footnote after the CRF page, referring to the number
2. The question from the CRF Forms identified as **Question/TranslatedText** tags. Any completion instruction in tag **Alias[@Context='completionInstructions']/@Name** is shown with the question
3. The answer to the question distinguised by **@DataType** attributes. Each data type is displayed as a browser specific interpretation of an HTML tag of the corresponding type. As no indication of multiple selects exist in the ODM definition, this data type is extracted from the text itself, triggered by the string **all that apply** within the tags
   * ItemDef/@Name
   * ItemDef/Question/TranslatedText
   * ItemDef/Description/TranslatedText
   * ItemDef/Alias[@Context='completionInstructions']/@Name
5. The SDTM annotation identified as **@SDSVarName** attributes. Additional information is added from **Alias/@Name** attributes having a **@Context='SDTM'** attribute as SDTM annotation marker. Each sentence separated by `'. '` (period blank) in the SDTM annotation is presented on a line of its own for readability. SDTM dataset names are extracted from either **ItemGroupDef/@Domain** or **ItemDef/@SDSVarName** attributes, where the latter may be a two-level name separated by a period `dataset.variable`

## Design choices <a name="Design_choices"/>
All vendor specific name spaces and XML addendums to the ODM-XML file are ignored.

The following assumptions regarding the specifics of the ODM-XML files XPATH are used:
CRF Element             | XPath                                                          | Comment
---                     | ---                                                            | ---
Form Title/Name         | FormDef/Description/TranslatedText                             | As it appears on the CRF
Section Title/Name      | Sections/ItemGroup/@Name                                       | Never displayed
Question Text           | ItemDef/Question/TranslatedText                                | As it appears on the CRF
Prompt                  | ItemDef/Alias[@Context="prompt"]/@Name                         | If present in ODM-XML
Completion Instructions | ItemDef/Alias[@Context="completionInstructions"]/@Name         | If present in ODM-XML
Implementation Notes    | ItemDef/Alias[@Context="implementationNotes"]/@Name            | If present in ODM-XML
Mapping Instructions    | ItemDef/Alias[@Context='mappingInstructions']/@Name            | If present in ODM-XML
CDASH                   | ItemDef/Alias[@Context="CDASH"]/@Name                          | Optional, controlled by a parameter
SDTM                    | ItemDef/@SDSVarName <br/> ItemDef/Alias[@Context="SDTM"]/@Name | When @Domain attribute not present, Dataset.Variable syntax is assumed

Great inspiration, as well as the CRF contents, is taken from the [eCRF portal on the CDISC website](https://www.cdisc.org/kb/ecrf). I have made very few changes of my own to the CRF contents to adapt it to my solution. These do include a cleanup of the SDTM annotations and choices, such as:
* All text constants are enclosed in quotation marks
* Consistent use of single quotation marks in the SDTM annotations
* Addition of a reference number for each CRF question. This has proved useful when reviewing CRFs
* Instructions/notes are written using a smaller font and in _italics_

### SDTM Datasets and Variables <a name="SDTM_Datasets_and_Variables"/>
Some debate has been encountered on how to capture Dataset name and Variable name for SDTM annotations in ODM-XML. Some ODM editing/generating systems use the **ItemGroupDef/@Domain** attribe to hold the Dataset name, some do not. Most seems to agree on **ItemDef/@SDSVarName** for the SDTM Variable name. I have chosen to support both, selecting **ItemGroupDef/@Domain** when present, but really encouraging using 2-level names in **ItemDef/@SDSVarName**.

The main reason for this is to remove the binding between CRF layout and SDTM annotations, imposed by having the Dataset name in the **@Domain** attribute on **@ItemGroupDef** level, and the Variable name in the **SDSVarName** attribute on **ItemDef** level. While this may seem logical by mimicking the tabular Dataset/Variable structure, it really serves no purpose beyond dictating that CRF Forms must be designed following SDTM dataset structure. Practical experience has shown that complex Forms (e.g. Adverse events) often annotate to different SDTM domains (e.g. AE and SUPPAE) in an alternating way, and thus dictates the change of **@ItemGroupDef** (sections) to change domain, serving only SDTM annotation purposes.

My [interim] solution is to have **SDSVarName** contain both Dataset name and Variable name separated by a period (e.g. AE.AETERM) in common SQL style. A better and more permanent solution is to advocate that [CDISC](https://www.cdisc.org/) moves the **@Domain** attribute to the **ItemDef** level i their ODM-XML specification. This will ensure that the Dataset name is specified at the same level as the Variable name, eliminating the need for the CRF sections to be structured after the SDTM annotations. Although this will call for redundant specification of Dataset names in an ODM file, systems ought to be able to populate this from SDTM specifications.

## Parameters <a name="Parameters"/>
Parameter | Description | Default value | Comment
---         | ---                                 | ---                        | ---
parmdisplay | Display mode                        | spec                       | spec: CRF specifcation with impleentation notes, SDTM annotations<br/>
                                                                                 bcrf: Blank CRF for submission<br/>
                                                                                 acrf: SDTM annotated CRF for submission<br/>
                                                                                 book: Complete CRF book with forms repeated by visit<br/>
parmstudy   | Name of study or standard           |                            | Can be derived from ODM file name
parmversion | Version of the ODM-XML file         |                            | Can be derived from ODM file name
parmstatus  | Status of the ODM-XML file          |                            | Can be derived from ODM file name
parmname    | Company name                        | My Company                 | User supplied
parmlogo    | Company logo file name              |                            | User supplied
parmlang    | Language of TranslatedText          | All, assuming one language | Future
parmcdash   | Display CDASH annotation from Alias | 1                          | If present, 0 or 1

Specification of the parmdisplay (Display mode) parameter
<dl>
  <dt>spec</dt>
  <dd>CRF specifcation with impleentation notes, SDTM annotations</dd>
  <dt>bcrf</dt>
  <dd>Blank CRF for submission</dd>
  <dt>acrf</dt>
  <dd>SDTM annotated CRF for submission</dd>
  <dt>book</dt>
  <dd>Complete CRF book with forms repeated by visit</dd>
</dl>

## Creating PDF documents <a name="Creating_PDF_documents"/>
In all browsers, print the CRF renditions as PDF documents on your disk as either [acrf](/examples/acrf.pdf) or [bcrf](/examples/bcrf.pdf) submission documents, respectively. Please note:
* The on-screen button is not included in PDF documents created by printing to a PDF file
* The TOC will work correctly as links within the PDF documents
* Form names in the visit matrix works (when present) as links as well, in addition to the TOC
* All space delimited words in the SDTM annotations have link targets, reachable from **define-xml**, provided that CRF origins in **define.xml** are created as named destinations to SDTM variables, and not as page numbers
* The yellow background color of the SDTM annotations requires printing of background graphics to be part of PDF documents
* Headers and footers, portrait versus landscape, and other document properties can be controlled within the printing dialog of your browser
* Different browsers may behave slightly different
