# Table of Contents
* [About The Project](#About_The_Project)
  * [Built With](#Built_With)
  * [Versions](#Versions)
* [Getting Started](#Getting_Started)
  * [Installation](#Installation)
  * [Prerequisites](#Prerequisites)
* [Usage](#Usage)
  * [crf_1_3_2.xsl](#crf_1_3_2_xsl)
  * [cdisc-xml.html](#cdisc_xml_html)
* [Roadmap](#Roadmap)
* [License](#License)
* [Contact](#Contact)
* [Acknowledgements](#Acknowledgements)

# About The Project <a name="About_The_Project"/>
This project is to exploit the CDISC ODM standard as 'a one source of truth' definition of a CRF specification, allowing

* Visual inspection of a CRF design directly from an ODM-xml file
* Documentation of the link between the CRF questions and the collected data points through SDTM annotations
* Creation of acrf.pdf and bcrf.pdf submission documents including link targets from define-xml
* The ODM-xml file to be used as an import specification to eCRF software

The solution is an XML translating style sheet allowing the ODM-xml file to be both human and machine readable without changing the content.

![Infographic about ODM stylesheet](/tree/master/images/odm_overview.png)

See the [CRF_renditions.md](CRF_renditions.md) document for details of the CRF itself.

## Built With <a name="Built_With"/>
The main component is an XSLT translating style sheet applied to an ODM-xml file of your own. The result is a webpage displaying the CRF pages, questions, and SDTM annotations. The web page page can be printed from the browser, also as PDF.

The secondary componant is an HTML file used to link the XML file to the XSL style sheet. The HTML file will run in modern browsers, NOT Internet Explorer.

## Versions <a name="Versions"/>
This project covers ODM version 1.3.2 only. Other version of ODM-xml files are not expected to work. ODM version 1.0.0 and ODM version 1.1.0 files have been tested, and they don't work.

Transformations are done using **<xsl:stylesheet version="1.0">** creating HTML 4.

# Getting Started <a name="Getting_Started"/>
Check out examples of [acrf](examples/acrf.pdf) and [bcrf](examples/bcrf.pdf) documents to see the results.

![Live version demo](odm2crf_demo.PNG)

Try a [live version](https://try2.info/cdisc-xml/cdisc-xml.html) to test your own ODM file, or my supplied [example](/examples) odm file.

## Installation <a name="Installation"/>
Download the files from the [xsl_files](/xsl_files) folder and place them in the same folder on your web server.

The XSL Style Sheet can work by itself together with any XSLT processor to render the CRF from an ODM-XML file. However, the HTML file requires that the components

* XSL Style sheet `crf_1_3_2.xsl`
* HTML file `cdisc-xml.html`
* ODM-xml file `odm-file-of-your-choise.xml`

are located __ON A WEB SERVER__ in the same folder. The HTML file will not run from a file folder without a web server.

# Usage <a name="Usage"/>
## crf_1_3_2.xsl <a name="crf_1_3_2_xsl"/>
This document is a piece of XSL-xml to display a valid CDISC ODM-xml file as an SDTM annotated CRF in a browser. The selected technology is supported in any modern browser (not Internet Explorer). The resulting web page can toggle various elements on and off, enabling printing of the CRF with and without these parts. Display of SDTM annotations and other elements  can also be controlled via parameters to the `crf_1_3_2.xsl` file. This way of displaying a CRF book with SDTM annotations is intended to serve as a visual representation of the ODM-xml file itself.

The intended procedure is to refresh the ODM-xml file on your server as it's development progresses, and then refresh the **cdisc-xml.html** file in the browser to see the rendition. Please notice in the image below that the CRF rendition contains a title page, a live table of contents (links preserved when printed as PDF), a visit matrix if visits are defined in the ODM-xml file, and a separate table per CRF form. When printing, page breaks separating each page and table exists.

## cdisc-xml.html <a name="cdisc_xml_html"/>
This document is a piece of HTML code containing only JavaScript to link a valid XSL Translating Style Sheet to a valid ODM-xml file without putting the style sheet link into the XML file itself. All XML and XSL files are supported. The resulting web page can serve as a CRF specification interpreting a valid ODM-xml file. This file needs to be placed on a web server in the same folder as your ODM-xml file and the `crf_1_3_2.xsl` XSL Translating Style Sheet. When opening the HTML file, the browser will perform the transformation of the XML file according to the programming in the XSL file. If the transformation is performed using a stand-alone XSL engine that is not a browser, the HTML file is not needed. I have tested that SAS PROC XSL can perform such a transformation and produce a simmilar result as the `cdisc-xml.html` file.

Please notice that file names may be case sensitive on your system too.

# Roadmap <a name="Roadmap"/>
It is my hope that this way of displaying annotations will catch on and eventually become wide spread throughout the pharma industry.

This is very much a work in progress, and I plan to make new versions of `crf_1_3_2.xsl` as new versions of ODM are released. XSL file names are planned to follow the ODM version.

At the same time I invite others to improve of my XSL programming, make suggestions to annotation conventions, and generally be involved and debate the use of ODM-xml in the way presented here.

# License <a name="License"/>
Distributed under the MIT License. See [LICENSE](https://github.com/jmangori/CDISC-ODM-and-Define-XML-tools/blob/master/LICENSE) for more information.

# Contact <a name="Contact"/>
Jørgen Mangor Iversen [jmi@try2.info](mailto:jmi@try2.info)

My [web page](http://www.try2.info) in danish unrelated to this project.

[Live version](https://try2.info/cdisc-xml/cdisc-xml.html) to demonstate the principle.

My [LinkedIn](https://www.linkedin.com/in/jørgen-iversen-ab5908b/) profile.

# Acknowledgements <a name="Acknowledgements"/>
Thanks to [Martin Honnen](https://github.com/martin-honnen/martin-honnen.github.io/blob/master/xslt/arcor-archive/2016/test2016081501.html) for code to execute asynchronous `XSLTProcessor()` clientside in the browser.

This software is made public with the explicit permission from LEO Pharma A/S.
