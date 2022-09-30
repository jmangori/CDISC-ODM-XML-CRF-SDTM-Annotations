#### Table of Contents
* [About The Project](#About_The_Project)
  * [Built With](#Built_With)
  * [Versions](#Versions)
* [Getting Started](#Getting_Started)
  * [Installation](#Installation)
     * [Client side rendition](#Client_side)
     * [Server side rendition](#Server_side)
  * [crf_1_3_2.xsl](#crf_1_3_2_xsl)
* [Usage](#Usage)
* [Roadmap](#Roadmap)
* [License](#License)
* [Contact](#Contact)
* [Acknowledgements](#Acknowledgements)

# About The Project <a name="About_The_Project"/>
This project is to exploit the CDISC ODM standard as [a single source of truth](https://en.wikipedia.org/wiki/Single_source_of_truth) definition of a CRF specification, allowing

* Visual inspection of a CRF design directly from an ODM-xml file
* Documentation of the link between the CRF questions and the collected data points through SDTM annotations of the CRF Forms
* Creation of [acrf](/examples/acrf.pdf) and [bcrf](/examples/bcrf.pdf) submission documents including link targets from define-xml
* Elimination of the labor intensive task of manually moving text boxes of SDTM annotations around on the [acrf](/examples/acrf.pdf) document
* Elimination of the even more labor intensive task of identifying CRF page numbers on the [acrf](/examples/acrf.pdf) document for referencing from define-xml, by replacing them with targets for the links from define.xml
* Encouraging ODM-xml files to be used as an import specification to eCRF software

The solution is an XML translating style sheet allowing any valid ODM-xml file to be both human and machine readable, without changing the content.

See the [CRF_renditions.md](CRF_renditions.md) document for details of the style sheet itself.

## Built With <a name="Built_With"/>
The main component is an XSLT translating style sheet applied to any ODM-xml file of your own. The result is a webpage displaying the CRF Forms, Questions, data to be collected, and SDTM annotations. The webpage can be printed from the browser, also as a PDF file.

The secondary component is an HTML file used to link the XML file to the XSL style sheet. The HTML file will run in modern browsers, NOT Internet Explorer. Two versions exist; one showing files residing on a web server, one uploading files and applying a `php` program. Both version apply the same style sheet to the same ODM-xml file, resulting in the same CRF rendition.

## Versions <a name="Versions"/>
This project covers ODM version 1.3.2 only. Other version of ODM-xml files are not expected to work. ODM version 1.0.0 and ODM version 1.1.0 files have been tested, and they don't work.

Transformations are done using **<xsl:stylesheet version="1.0">** creating HTML 4.

# Getting Started <a name="Getting_Started"/>
Check out examples of [acrf](/examples/acrf.pdf) and [bcrf](/examples/bcrf.pdf) documents to see the results.

Try a [live version](https://try2.info/cdisc-xml/cdisc-xml.html) to test your own ODM file, or my supplied [example](/examples/CDISC_ODM_1.3.2_example.xml) ODM file.

## Installation <a name="Installation"/>
Download the files from the [files](/files) folder and place them in the same folder on your web server.

To set up the style sheet, you have to decide whether to perform the transformations on the client or on a server.

### Client side rendition <a name="Client_side"/>
The `cdisc xml.html` (no hyphen) file must be placed on a web server in the same folder as your ODM-xml file and the `crf_1_3_2.xsl` translating style sheet. Other XSL/XSLT files can be used as well, particular `define2-0-0.xsl` for displaying define-xml. This file must be obtained from [CDISC](https://www.cdisc.org/). When adding you own XSL/XSLT files to your server, simply add them as an `<option>` line to the `<select>` tag specifying style sheets within the HTML code.

### Server side rendition <a name="Server_side"/>
The `cdisc-xml.html` (with a hyphen) file and the `cdisc-xml.php` file must be placed in the same folder on a webserver. Together these files can apply any XSL/XSLT translating style sheet to any XML file, including, but not limited to, ODM-xml and define-xml.

## crf_1_3_2.xsl <a name="crf_1_3_2_xsl"/>
This document is the central XSL/XSLT translating style sheet to display a valid CDISC ODM-xml file as an SDTM annotated CRF. This technology is supported in any modern browser, and can be used by any XSLT processor supporting XSLT version 1.0. Display of SDTM annotations and other elements can be controlled via parameters to the `crf_1_3_2.xsl` file.

# Usage <a name="Usage"/>
The intended procedure is to refresh the ODM-XML file in your favorite ODM tool as it's development progresses, and then repeatedly apply the `crf_1_3_2.xsl` file to see the rendition progress. Please notice that the CRF rendition contains a title page, a live table of contents (links preserved when converted to PDF), a visit matrix if visits are defined in the ODM-xml file, and a separate table per CRF Form. When printing, page breaks separating title page, toc, visit matrix, and Forms, are created.

Please notice that file names may be case sensitive on your system. And please observe that browsers may behave slightly different, even when sharing the same browser engine.

# Roadmap <a name="Roadmap"/>
It is my hope that this way of displaying annotations will catch on and eventually become wide spread throughout the pharma industry.

This is very much a work in progress, and I plan to make new versions of `crf_1_3_2.xsl` as new versions of ODM are released. XSL file names are planned to follow the ODM version.

At the same time I invite others to improve of my XSL programming, make suggestions to annotation conventions, and generally be involved and debate the use of ODM-xml in the way presented here.

# License <a name="License"/>
Distributed under the MIT License. See [LICENSE](https://github.com/jmangori/CDISC-ODM-and-Define-XML-tools/blob/master/LICENSE) for more information.

# Contact <a name="Contact"/>
Jørgen Mangor Iversen [jmi@try2.info](mailto:jmi@try2.info)

[Live version](https://try2.info/cdisc-xml/cdisc-xml.html) to demonstrate the principle.

My [LinkedIn](https://www.linkedin.com/in/jørgen-iversen-ab5908b/) profile.

# Acknowledgements <a name="Acknowledgements"/>
Thanks to [Martin Honnen](https://github.com/martin-honnen/martin-honnen.github.io/blob/master/xslt/arcor-archive/2016/test2016081501.html) for code to execute asynchronous `XSLTProcessor()` client side in the browser.

This software is made public with the explicit permission from LEO Pharma A/S.
