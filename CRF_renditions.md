# CRF Renditions
A short description of the CRF generated from the ODM-xml document.

## CRF layout
The main feature of the CRF layout presented here is to put the SDTM annotations in a column adjacent to each question line. This way, the SDTM annotations are displayed at the proper location, but without the need to move boxes of annotations around inside and on top of CRF elements.

## Design choises
All vendor specific name spaces and XML addendums to the ODM-XML file are ignored.

The following assumptions regarding the specifics of the ODM-XML file's XPATH's are in effect:
<dl>
  <dt>CRF instructions</dt>
  <dd>/ODM/Study/MetaDataVersion/FormDef/Description/TranslatedText</dd>
  <dt>Question instructions</dt>
  <dd>/ODM/Study/MetaDataVersion/ItemDef/Description/TranslatedText</dd>
  <dt>SDTM Annotations</dt>
  <dd>/ODM/Study/MetaDataVersion/ItemDef/Alias/@Name
    <p style="font-style:italic">
    where
    </p>
    /ODM/Study/MetaDataVersion/ItemDef/Alias/@Context='SDTM'</dd>
  </dl>
  
Groups (**ItemGroup** tags) in the ODM-xml are not displayed as part of the CRF rendition. They are used solely to cary the SDTM domain dataset name in the **@Domain** attribute.

The layout of the CRF is taken from the examples on the CDISC website. I have made very few design choises of my own. These do include a cleanup of the SDTM annotations, such as
* All text constants are enclosed in quotation marks.
* Consistent use of single quotation marks in the SDTM annotations.
* Ommision of table border for additions to the CRF itself.
* Addition of a reference number for each CRF question. This has proved usefull when revieving CRFs.
* Instructions/notes are written using a smaller font and in _italics_.

## Creating PDF documents
In all browsers, print the CRF renditions as PDF documents on your disk as either `bcrf.pdf` or `acrf.pdf` submission documents, respectively. Please note:
* The on-screen buttons are not included in PDF documents created by printing to a PDF file.
* The TOC will work correctly as links within the PDF documents.
* Form names in the visit matrix works as links as well.
* The yellow background color of the SDTM annotations requires printing of background graphics to be part of PDF documents.
* Headers and footers, portrait versus landscape, and other document properties can be controlled within the printing dialog of your browser.
