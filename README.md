#### Table of Contents
* [About The Project](#About_The_Project)
  * [Built With](#Built_With)
  * [Versions](#Versions)
* [Getting Started](#Getting_Started)
  * [Installation](#Installation)
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
* Creation of [acrf](/examples/acrf.pdf) and [bcrf](/examples/bcrf.pdf) submission documents including link targets from define-xml

All this to encourage ODM-xml files to be used as an import specification to eCRF software.

The solution is an XML translating style sheet allowing the ODM-xml file to be both human and machine readable without changing the content.

See the [CRF_renditions.md](CRF_renditions.md) document for details of the CRF itself.

## Built With <a name="Built_With"/>
The main component is an XSLT translating style sheet applied to an ODM-xml file of your own. The result is a webpage displaying the CRF Forms, Questions, and SDTM annotations. The webpage can be printed from the browser, also as a PDF file.

The secondary component is an HTML file used to link the XML file to the XSL style sheet. The HTML file will run in modern browsers, NOT Internet Explorer. Two versions exist; one showing files residing on a web server, one uploading files and applying a **php** program.

## Versions <a name="Versions"/>
This project covers ODM version 1.3.2 only. Other version of ODM-xml files are not expected to work. ODM version 1.0.0 and ODM version 1.1.0 files have been tested, and they don't work.

Transformations are done using **<xsl:stylesheet version="1.0">** creating HTML 4.

# Getting Started <a name="Getting_Started"/>
Check out examples of [acrf](/examples/acrf.pdf) and [bcrf](/examples/bcrf.pdf) documents to see the results.

Try a [live version](https://try2.info/cdisc-xml/cdisc-xml.html) to test your own ODM file, or my supplied [example](/examples/CDISC_ODM_1.3.2_example.xml) ODM file.

## Installation <a name="Installation"/>
Download the files from the [files](/files) folder and place them in the same folder on your web server.

The XSL Style Sheet can work by itself together with any XSLT processor to render the CRF from an ODM-XML file. However, the HTML file requires that the components

* XSL Style sheet `crf_1_3_2.xsl`
* HTML file `cdisc-xml.html`
* ODM-xml file `odm-file-of-your-choise.xml`

are located __ON A WEB SERVER__ in the same folder. The HTML file will not apply the style sheet from a file folder without a web server, due to browser restrictions.

# Usage <a name="Usage"/>
## crf_1_3_2.xsl <a name="crf_1_3_2_xsl"/>
This document is a piece of XSL/XSLT to display a valid CDISC ODM-xml file as an SDTM annotated CRF. This technology is supported in any modern browser, and can be used by any command line XSLT processor. Display of SDTM annotations and other elements can be controlled via parameters to the `crf_1_3_2.xsl` file. This way of displaying a CRF (pages or a whole book) with SDTM annotations is intended to serve as a visual representation of the ODM-xml file itself.

The intended procedure is to refresh the ODM-XML file in your favourite ODM tool as it's development progresses, and then repeatedly apply the `crf_1_3_2.xsl` file to see the rendition. Please notice that the CRF rendition contains a title page, a live table of contents (links preserved when converted to PDF), a visit matrix if visits are defined in the ODM-xml file, and a separate table per CRF Form. When printing, page breaks separating title page, toc, visit matrix, and Forms, are created.

## cdisc-xml.html <a name="cdisc_xml_html"/>
This document is a piece of HTML code using JavaScript to link a valid XSL Translating Style Sheet to a valid ODM-xml file without putting the style sheet link into the XML file itself. All XML and XSL/XSLT files are supported. The resulting web page can serve as a CRF specification interpreting a valid ODM-xml file, or to display a define-xml file. The `cdisc-xml.html` file needs to be placed on a web server in the same folder as your ODM-xml file and the `crf_1_3_2.xsl` XSL Translating Style Sheet. When opening the HTML file, the browser will perform the transformation of the XML file according to the programming in the XSL file. If the transformation is performed using a stand-alone XSL engine locally, the HTML file is not needed.

Please notice that file names may be case sensitive on your system. And please observe that browsers may behave slightly different, even when sharing the same browser engine.

# Roadmap <a name="Roadmap"/>
It is my hope that this way of displaying annotations will catch on and eventually become wide spread throughout the pharma industry.

This is very much a work in progress, and I plan to make new versions of `crf_1_3_2.xsl` as new versions of ODM are released. XSL file names are planned to follow the ODM version.

At the same time I invite others to improve of my XSL programming, make suggestions to annotation conventions, and generally be involved and debate the use of ODM-xml in the way presented here.

# License <a name="License"/>
Distributed under the MIT License. See [LICENSE](https://github.com/jmangori/CDISC-ODM-and-Define-XML-tools/blob/master/LICENSE) for more information.

# Contact <a name="Contact"/>
Jørgen Mangor Iversen [jmi@try2.info](mailto:jmi@try2.info)

My [web page](https://www.try2.info) in Danish unrelated to this project.

[Live version](https://try2.info/cdisc-xml/cdisc-xml.html) to demonstrate the principle.

My [LinkedIn](https://www.linkedin.com/in/jørgen-iversen-ab5908b/) profile.

# Acknowledgements <a name="Acknowledgements"/>
Thanks to [Martin Honnen](https://github.com/martin-honnen/martin-honnen.github.io/blob/master/xslt/arcor-archive/2016/test2016081501.html) for code to execute asynchronous `XSLTProcessor()` client side in the browser.

This software is made public with the explicit permission from LEO Pharma A/S.
