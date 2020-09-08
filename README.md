# About The Project
This project is to exploit the CDISC ODM standard as a one source of truth definition of a CRF specification, allowing both visual inspection of a proposed CRF, definition and documentation of the link between the CRF questions and the collected data points through SDTM annotations, and an import specification to eCRF software in one blow. The solution is a fairly simple style sheet allowing the ODM-xml file to be both human and machine readable without changing the content.

![Infographic about ODM stylesheet](images/odm_overview.png)

## Built With
The XSL style sheet and accompanying HTML file for rendering an ODM-xml file as a CRF book in the browser is made using a simple text editor. The result is a webpage displaying the CRF pages, questions, SDTM annotations, and controlled terminology as HTML. The HTML page can be printed from the browser, should anyone still live in a paper based world. The HTML file used to link the XML file to the XSL style sheet will run in modern browsers, NOT Internet Explorer.

#### Versions covered are:
* ODM version 1.3.2 

# Getting Started
Download the documents and place them at the location where they are needed.

## XSL Style Sheet
The XSL Style Sheet can work by itself together with any XSLT processor to render the CRF from an ODM-XML file. However, the HTML file requires that all components; HTML file, ODM-xml file, and XSL Style sheet are located on a webserver in the same folder. It will not run from a file folder without a web server. The XSL Style Sheet file has some hardcoding of file names for ODM-xml file and the XSL Style Sheet file. These can be changed in the HTML file. The HTML file has an initial prompt for the name of the ODM-xml file, which can easily be replaced with a hardcoding of the file name, and subsequently removal of the prompt.

## Prerequisites
* Access to a web server for the HTML file to run. You can create a local webserver with [XAMPP](https://www.apachefriends.org/index.html).

* Access to an XSLT processor to perform the transformation of an ODM-XML file to HTML using the XSL Style Sheet. SAS PROC XSL will do the job correctly.

These options are mutually exclusive.

# Usage
### crf_1_3_2.xsl
This document is a piece of XSL:XML to display a valid CDISC ODM-xml file as an SDTM annotated CRF in a browser. The selected technology is supported in any modern browser (not Internet Explorer). The resulting HTML page can toggle annotations and editorial notes on and off, enabling printing of the CRF with and without these parts. The document can be used as a stand-alone XSL style sheet when linked to a valid ODM-xml file. This way of displaying a CRF book with SDTM annotaitons is intended to serve as a visual representation of the ODM-xml file itself.

It might seem counterintuitive, but the intended procedure is to refresh the ODM-xml file on your server as it's development progresses, and then click/refresh the **crf_specification.htm** file in the browser to see the rendition. Please notice in the image below that the CRF rendition contains a title page, a live table of contents (links preserved when printed as PDF), and a separate table per CRF form. When printing, page breaks separating each page and table exists.

The CRF rendition consists of one table for each form in the CRF identified as **FormDef** tags.
* The first column is the question from the CRF forms identified as **Question/TranslatedText** tags. If any **Description/TranslatedText** tag exists, the contents is added as an editorial remark in _italics_.
* The second column is the answer to the question distinguised by **DataType** attributes. Each data type is displayed as a browser specific interpretation of an HTML <input> tag of the corresponding type.
* The third column is the SDTM annotation identified as **SDSVarName** attributes. Additional information is added from **Alias/Name** attributes.
* The fourth column is any code lists attached to the question identified by **CodeListItem** tags. A small inline table documents the correlation between CRF code list values and annotation values to be expected in the SDTM datasets. If any **Description/TranslatedText** tag exists, the contents is added as an editorial remark in _italics_.

Please note that the editorial remarks are identical in the questions and in the remarks.

![Simple CRF ecample](images/CRF.png)

### crf_specification.htm
This document is a piece of HTML code containing only JavaScript to link a valid XSL Translating Style Sheet to a valid ODM-xml file without putting the style sheet link into the XML file itself. All XML and XSL files are supported, although some file names are hard coded. The resulting HTML page can serve as a CRF specification interpreting a valid ODM-xml file. This file needs to be placed on a web server in the same folder as your ODM-xml file and the **crf_1_3_2.xsl** XSL Translating Style Sheet. When clicking this file, the browser will perform the transformation of the XML file according to the programming in the XSL file. If the transformation is performed using a stand-alone XSL engine that is not a browser, this file is not needed. I have tested that SAS PROC XSL can perform such a transformation and produce a simmilar result as the **htm** file.

##### Modifications
The file **crf_specification.htm** contains a HTML prompt to ask for the name of the ODM-xml file to be processed. If this is to changed, you may do the following:
* If the default name is to be changed, simply replace the name of the ODM-xml file. Likewise the name of the XSL file can be changed as they both are simple hard codings. Furthermore, either file name can be prepended with folder paths referring to locations on whichever server hosts the files.
* If the prompt is to be removed, simply replace the prompt function call in the parameter to the **displayResult()** function with a text constant containing the name. You may go all the way and remove the parameter to **displayResult()** all together, leaving a text constant as the parameter to the first call to the **loadXMLDoc()** function.

Please notice that file names may be case sensitive on your system too.

# Roadmap
This is very much a work in progress. I will consider displaying editorial (and other) remarks as part of either the CRF itself or the annotations. It is my hope that this way of displaying annotations will catch on and eventually become wide spread throughout the pharma industry. I will also consider to include other (CDASH) annotations, if I am lead to believe this is a general desire.

# License
Distributed under the MIT License. See [LICENSE](https://github.com/jmangori/CDISC-ODM-and-Define-XML-tools/blob/master/LICENSE) for more information.

# Contact
Jørgen Mangor Iversen [jmi@try2.info](mailto:jmi@try2.info)

[My web page in danish](http://www.try2.info) unrelated to this project.

[My LinkedIn profile](https://www.linkedin.com/in/jørgen-iversen-ab5908b/)
