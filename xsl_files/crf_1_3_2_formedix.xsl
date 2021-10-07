<?xml version="1.0" encoding="UTF-8"?>
<!--
  Copyright (c) 2021 Jørgen Mangor Iversen

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:odm="http://www.cdisc.org/ns/odm/v1.3"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:def="http://www.cdisc.org/ns/def/v2.0"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:arm="http://www.cdisc.org/ns/arm/v1.0"
                xmlns:fdx="http://www.formedix.com/Schemas/OriginCustomAttributes/1"
                version="1.0"
                xml:lang="en"
                exclude-result-prefixes="def xlink odm xsi arm">
  <xsl:output   method="html"
                indent="yes"
                encoding="utf-8"
                doctype-system="http://www.w3.org/TR/html4/strict.dtd"
                doctype-public="-//W3C//DTD HTML 4.01//EN"
                version="4.0"/>

  <!-- Parameter passed from outside. Default is a blank CRF with addendums:
         bcrf: Blank CRF for submission
         acrf: SDTM annotated CRF for submission with SDTM annotations
         spec: CRF specifcation with selection buttons, LEO notes, SDTM annotations
         book: Complete CRF book with forms repeated by visit
         data: Final CRF ready for data collection
  -->
  <xsl:param name="parmdisplay"/>

  <!-- Keys to sort forms in the order of visit schedule, if present -->
  <xsl:key name="by_StudyEventRef" match="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:Protocol/odm:StudyEventRef" use="@StudyEventOID"/>
  <xsl:key name="by_FormRef"       match="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:StudyEventDef/odm:FormRef"  use="@FormOID"/>

  <!-- Special characters in a variables for enhanced readability -->
  <xsl:variable name="checkmark" select="'&#10004;'"/> <!-- ✔ -->
  <xsl:variable name="infinity"  select="'&#8734;'"/>  <!-- ∞ -->

  <xsl:template match="/">
    <html>
      <head>
        <title><xsl:call-template name="identifier"/></title>
        <meta http-equiv="Content-Type"    content="text/html;charset=utf-8"/>
        <meta http-equiv="X-UA-Compatible" content="IE=9"/>
        <meta http-equiv="cache-control"   content="no-cache"/>
        <meta http-equiv="pragma"          content="no-cache"/>
        <meta http-equiv="expires"         content="0"/>
        <meta name="Author"                content="Jørgen Mangor Iversen"/>
        <style>
          html          { margin:  1em 1em 1em 1em; }
          *             { font-family: Helvetica, Arial, sans-serif !important; }
          h1, h2, h3, p { text-align: center; }
          a:link        { color: black; background-color: transparent; text-decoration: none; }
          a:visited     { color: black; background-color: transparent; text-decoration: none; }
          a:hover       { color: blue;  background-color: transparent; text-decoration: underline; }
          .nohover      { pointer-events: none; }
          table         { solid DarkGrey; border-spacing: 0; border-collapse: collapse; page-break-inside: auto; }
          tr            { page-break-inside:avoid; page-break-after:auto; }
          th, td        { border-left:   1px solid DarkGrey;
                          border-right:  1px solid DarkGrey;
                          border-top:    1px solid DarkGrey;
                          border-bottom: 1px solid DarkGrey; padding: 0.1em; }
          @media print  { .noprint { display: none; } }
          .noprint      { position: fixed; bottom: 0.5em; right: 0.5em; z-index: 99; }
          .rotate span  { writing-mode: vertical-rl; transform: rotate(180deg); padding: 0.2em; }
          .noborder     { border: none; }
          .center       { margin-left: auto; margin-right: auto; }
          .matrix       { text-align: center; }
          .check        { color: DarkGreen; }
          .hidden       { visibility: hidden; display: none; }
          .maintable    { border: 1px; width: 100%; }
          .crfhead      { background-color: Gainsboro; }
          .left         { text-align: left; }
          .formtitle    { font-style: bold;   font-weight: bold;   font-size: 1.2em; }
          .note         { font-style: italic; font-weight: normal; font-size: 0.8em; }
          <xsl:choose>
            <xsl:when test="$parmdisplay = 'spec' or $parmdisplay = 'acrf'">
              .anno     { background-color: LightYellow; }
              .seqw     { width: 5em; }
              .quew     { width: 30%; }
              .answ     { width: 25%; }
              .annw     { width: 40%; }
              .desw     { width: 60%; }
            </xsl:when>
            <xsl:otherwise>
              .anno     { visibility: hidden; display: none; }
              .seqw     { width:  5em; }
              .quew     { width:  50%; }
              .answ     { width:  45%; }
              .desw     { width: 100%; }
            </xsl:otherwise>
          </xsl:choose>
          <xsl:if test="$parmdisplay != 'spec'">
              #internal { visibility: hidden; display: none; }
          </xsl:if>
        </style>
      </head>
      <body>
        <xsl:call-template name="buttons"/>
        <xsl:apply-templates select="/odm:ODM/odm:Study[1]/odm:GlobalVariables"/>
        <xsl:apply-templates select="/odm:ODM"/>
        <p style="page-break-after: always"/>

        <!-- Either Toc or Visit Matrix for navigation -->
        <xsl:if test="not(/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:StudyEventDef)">
          <xsl:call-template name="toc"/>
        </xsl:if>
        <xsl:if test="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:StudyEventDef">
          <xsl:call-template name="visit_matrix"/>
        </xsl:if>
        <p style="page-break-after: always"/>

        <!-- One table per form becomes one form per page -->
        <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:FormDef">
          <!-- If visit structure is not present, forms will be sorted in FormDef tag order -->
          <xsl:sort select="key('by_StudyEventRef', key('by_FormRef', @OID)/../@OID)/@OrderNumber" data-type="number"/>
          <xsl:sort select="key('by_FormRef', @OID)/@OrderNumber" data-type="number"/>

          <table class="maintable">
            <xsl:call-template name="table_head"/>
            <tbody>
              <xsl:for-each select="odm:ItemGroupRef">
                <xsl:sort select="@OrderNumber" data-type="number"/>
                <xsl:variable name="group" select="@ItemGroupOID"/>
                <xsl:variable name="gnum"  select="@OrderNumber"/>
                <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:ItemGroupDef[@OID=$group]">
                  <xsl:variable name="domain" select="@Domain"/>
                  <xsl:for-each select="odm:ItemRef">
                    <xsl:sort select="@OrderNumber" data-type="number"/>
                    <xsl:variable name="item" select="@ItemOID"/>
                    <xsl:variable name="inum" select="@OrderNumber"/>
                    <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:ItemDef[@OID=$item]">
                      <xsl:call-template name="notes_above"/>
                      <tr>
                        <td class="seqw">
                          <xsl:call-template name="sequence_number">
                            <xsl:with-param name="major"    select="$gnum"/>
                            <xsl:with-param name="minor"    select="$inum"/>
                            <xsl:with-param name="has_note" select="normalize-space(fdx:CustomAttributeSet/fdx:CustomAttribute[@Name = 'DesignNotes']/fdx:Value) != ''"/>
                          </xsl:call-template>
                        </td>
                        <td class="quew">
                          <xsl:call-template name="question"/>
                        </td>
                        <td class="answ">
                          <xsl:call-template name="answer"/>
                        </td>
                        <td id="anno" class="annw anno">
                          <xsl:call-template name="annotation">
                            <xsl:with-param name="domain" select="$domain"/>
                          </xsl:call-template>
                        </td>
                      </tr>
                    </xsl:for-each>
                  </xsl:for-each>
                </xsl:for-each>
              </xsl:for-each>
            </tbody>
          </table>

          <xsl:call-template name="form_notes"/>
          <xsl:call.template name="question_notes"/>

          <p style="page-break-after: always"/>
        </xsl:for-each>
      </body>
    </html>
  </xsl:template>

  <!-- Non printable buttons to turn elements off and on.
       In-line JavaScript as SCRIPT sections will not execute and onload() will not fire -->
  <xsl:template name="buttons">
    <table class="noprint">
      <tr>
        <xsl:if test="$parmdisplay = 'spec'">
          <td class="noborder">
            <button onClick="for(var element of document.querySelectorAll('[id=anno]'))     element.style.visibility = (element.style.visibility == 'collapse') ? 'visible' : 'collapse';">
              Annotations Off and On
            </button>
          </td>
          <td class="noborder">
            <button onClick="for(var element of document.querySelectorAll('[id=internal]')) element.style.visibility = (element.style.visibility == 'collapse') ? 'visible' : 'collapse';">
              LEO notes Off and On
            </button>
          </td>
        </xsl:if>
        <td class="noborder">
          <button onClick="document.documentElement.scrollTop = 0">
            Scroll to the top
          </button>
        </td>
      </tr>
    </table>
  </xsl:template>

  <!-- Identifier for title and name -->
  <xsl:template name="identifier">
    <xsl:choose>
      <xsl:when test="normalize-space(/odm:ODM/odm:Study[1]/odm:GlobalVariables/odm:StudyName) = 'Not applicable'">
        Standard
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="/odm:ODM/odm:Study[1]/odm:GlobalVariables/odm:StudyName"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

 <!-- Title Page -->
  <xsl:template match="/odm:ODM/odm:Study[1]/odm:GlobalVariables">
    <h1>CRF Specification for <xsl:call-template name="identifier"/></h1>
    <xsl:if test="normalize-space(odm:StudyDescription) != 'Not applicable'">
      <p><xsl:value-of select="odm:StudyDescription"/></p>
    </xsl:if>
    <xsl:if test="normalize-space(odm:StudyName) != normalize-space(odm:ProtocolName) and normalize-space(odm:ProtocolName) != 'Not applicable' and normalize-space(odm:ProtocolName) != ''">
      <h2>Protocol Name: <xsl:value-of select="/odm:ProtocolName"/></h2>
    </xsl:if>
  </xsl:template>

  <!-- Title Dates -->
  <xsl:template match="/odm:ODM">
    <xsl:if test="normalize-space(@CreationDateTime) != ''">
      <p>Creation date: <xsl:value-of select="@CreationDateTime"/></p>
    </xsl:if>
    <xsl:if test="normalize-space(@AsOfDateTime) != ''">
      <p>Valid from date: <xsl:value-of select="@AsOfDateTime"/></p>
    </xsl:if>
  </xsl:template>

  <!-- Toc, Alfabetic sorting of Forms by name -->
  <xsl:template name="toc">
    <h2>Table of Contents</h2>
    <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:FormDef">
      <xsl:sort select="@Name" data-type="text"/>
      <xsl:sort select="fdx:CustomAttributeSet/fdx:CustomAttribute[@Name = 'Title']/fdx:Value" data-type="text"/>
      <p>
        <xsl:call-template name="form_link">
          <xsl:with-param name="title" select="fdx:CustomAttributeSet/fdx:CustomAttribute[@Name = 'Title']/fdx:Value"/>
          <xsl:with-param name="name"  select="@Name"/>
          <xsl:with-param name="oid"   select="@OID"/>
        </xsl:call-template>
      </p>
    </xsl:for-each>
  </xsl:template>

  <!-- Vist Matrix -->
  <xsl:template name="visit_matrix">
    <h2><a class="nohover" id="visit_matrix">Visit Matrix</a></h2>
    <table class="center">
      <thead>
        <tr>
          <th class="left crfhead">Event/<br/>Form</th>
          <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:Protocol/odm:StudyEventRef">
            <xsl:sort select="@OrderNumber" data-type="number"/>
            <xsl:variable name="visithead" select="@StudyEventOID"/>
            <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:StudyEventDef[@OID=$visithead]">
              <th class="crfhead rotate"><span><xsl:value-of select="@Name"/></span></th>
            </xsl:for-each>
          </xsl:for-each>
        </tr>
      </thead>
      <tbody>
        <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:FormDef">
          <xsl:sort select="key('by_StudyEventRef', key('by_FormRef', @OID)/../@OID)/@OrderNumber" data-type="number"/>
          <xsl:sort select="key('by_FormRef', @OID)/@OrderNumber" data-type="number"/>
          <xsl:variable name="formrow" select="@OID"/>
          <tr>
            <td>
              <xsl:call-template name="form_link">
                <xsl:with-param name="title" select="fdx:CustomAttributeSet/fdx:CustomAttribute[@Name = 'Title']/fdx:Value"/>
                <xsl:with-param name="name"  select="@Name"/>
                <xsl:with-param name="oid"   select="@OID"/>
              </xsl:call-template>
              <xsl:if test="contains(fdx:CustomAttributeSet/fdx:CustomAttribute[@Name = 'DesignNotes']/fdx:Value, 'Repeating form')">
                <em class="check"> [<xsl:value-of select="$infinity"/>]</em>
              </xsl:if>
            </td>
            <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:Protocol/odm:StudyEventRef">
              <xsl:sort select="@OrderNumber" data-type="number"/>
              <td class="matrix check">
                <xsl:variable name="visitbody"  select="@StudyEventOID"/>
                <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:StudyEventDef[@OID=$visitbody]">
                  <xsl:for-each select="odm:FormRef">
                    <xsl:if test="$formrow = @FormOID">
                      <xsl:value-of select="$checkmark"/>
                    </xsl:if>
                  </xsl:for-each>
                </xsl:for-each>
              </td>
            </xsl:for-each>
          </tr>
        </xsl:for-each>
      </tbody>
    </table>
  </xsl:template>

  <!-- The header of the main table is complex enough to have it's own template -->
  <xsl:template name="table_head">
    <thead>
      <tr>
        <th colspan="4" class="noborder">
          <div class="left formtitle">
            <a class="nohover">
              <xsl:attribute name="id">
                <xsl:value-of select="@OID"/>
              </xsl:attribute>
              <span>
                <!-- Predefined algorithm for form name -->
                <xsl:call-template name="form_name">
                  <xsl:with-param name="title" select="fdx:CustomAttributeSet/fdx:CustomAttribute[@Name = 'Title']/fdx:Value"/>
                  <xsl:with-param name="name"  select="@Name"/>
                </xsl:call-template>
              </span>
            </a>
            <xsl:if test="normalize-space(fdx:CustomAttributeSet/fdx:CustomAttribute[@Name = 'DesignNotes']/fdx:Value) != ''">
              #
            </xsl:if>
          </div>
        </th>
      </tr>
      <xsl:if test="normalize-space(fdx:CustomAttributeSet/fdx:CustomAttribute[@Name = 'NotesTop']/fdx:Value) != ''">
        <tr>
          <th colspan="4" class="noborder">
            <xsl:apply-templates select="fdx:CustomAttributeSet/fdx:CustomAttribute[@Name = 'NotesTop']"/>
          </th>
        </tr>
      </xsl:if>
      <xsl:if test="odm:Description">
        <tr>
          <th colspan="4" class="noborder">
            <xsl:apply-templates select="odm:Description"/>
          </th>
        </tr>
      </xsl:if>
      <tr><th colspan="4" class="noborder" id="anno"><br/></th></tr>
      <tr>
        <th class="crfhead seqw left">Ref</th>
        <th class="crfhead quew">CRF Question</th>
        <th class="crfhead answ">Data Collected</th>
        <xsl:if test="$parmdisplay = 'spec' or $parmdisplay = 'acrf'">
          <th class="crfhead annw" id="anno">SDTM Annotations</th>
        </xsl:if>
      </tr>
    </thead>
  </xsl:template>

  <!-- Add Guidance text from Custom NotesTop -->
  <xsl:template match="fdx:CustomAttributeSet/fdx:CustomAttribute[@Name = 'NotesTop']">
    <div class="left note">
      <xsl:value-of select="fdx:Value"/>
    </div>
  </xsl:template>

  <!-- Add LEO Note from Descrition/TranslatedText -->
  <xsl:template match="odm:Description">
    <div id="internal" class="left note">
      <xsl:value-of select="odm:TranslatedText"/>
    </div>
  </xsl:template>

  <!-- Create a link to a form -->
  <xsl:template name="form_link">
    <xsl:param name="title"/>
    <xsl:param name="name"/>
    <xsl:param name="oid"/>
    <a>
      <xsl:attribute name="href">#<xsl:value-of select="$oid"/></xsl:attribute>
      <span>
        <!-- Predefined algorithm for form name -->
        <xsl:call-template name="form_name">
          <xsl:with-param name="title" select="$title"/>
          <xsl:with-param name="name"  select="$name"/>
        </xsl:call-template>
      </span>
    </a>
  </xsl:template>

  <!-- If a Formedix title exists, use it over the form name  -->
  <xsl:template name="form_name">
    <xsl:param name="title"/>
    <xsl:param name="name"/>
    <xsl:choose>
      <xsl:when test="normalize-space($title) != '' and normalize-space($title) != normalize-space($name)">
        <xsl:if test="$parmdisplay = 'spec'">
          <span id="internal">
            <xsl:value-of select="$name"/>
          </span>
          <br/>
        </xsl:if>
        <xsl:value-of select="$title"/>
      </xsl:when>
      <xsl:when test="normalize-space($title) != ''">
        <xsl:value-of select="$title"/>
      </xsl:when>
      <xsl:when test="normalize-space($name) != ''">
        <xsl:value-of select="$name"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Show a note above the next question -->
  <xsl:template name="notes_above">
    <xsl:if test="normalize-space(fdx:CustomAttributeSet/fdx:CustomAttribute[@Name = 'NotesAbove']/fdx:Value) != ''">
      <tr>
        <td class="seqw">
        </td>
        <td class="note" colspan="2">
          <xsl:value-of select="fdx:CustomAttributeSet/fdx:CustomAttribute[@Name = 'NotesAbove']/fdx:Value"/>
        </td>
        <td id="anno" class="annw anno">NOT SUBMITTED</td>
      </tr>
    </xsl:if>
  </xsl:template>

  <!-- Show the sequence number as a reference to each question -->
  <xsl:template name="sequence_number">
    <xsl:param name="major"/>
    <xsl:param name="minor"/>
    <xsl:param name="has_note"/>
    <xsl:value-of select="$major"/>.<xsl:value-of select="$minor"/>
    <xsl:if test="$has_note">
      #
    </xsl:if>
  </xsl:template>

  <!-- Show one question on the form, including guidance text and LEO note -->
  <xsl:template name="question">
    <xsl:value-of select="odm:Question/odm:TranslatedText"/>
    <p class="note left"><xsl:value-of select="fdx:CustomAttributeSet/fdx:CustomAttribute[@Name = 'Notes']/fdx:Value"/></p>
    <xsl:apply-templates select="odm:Description"/>
  </xsl:template>

  <!-- Collect the data as answer to the question -->
  <xsl:template name="answer">
    <xsl:choose>
      <xsl:when test="contains(odm:Question/odm:TranslatedText,    'all that apply') or
                      contains(odm:Description/odm:TranslatedText, 'all that apply')">
        <xsl:variable name="check" select="odm:CodeListRef/@CodeListOID"/>
        <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:CodeList/odm:CodeListItem[../@OID=$check]">
          <xsl:sort select="@OrderNumber" data-type="number"/>
          <input type="checkbox" name="$check"/><label for="$check"><xsl:value-of select="odm:Decode/odm:TranslatedText"/><span class="note"> (<xsl:value-of select="@CodedValue"/>)</span></label><br/>
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="normalize-space(odm:CodeListRef/@CodeListOID) != ''">
        <xsl:variable name="radio" select="odm:CodeListRef/@CodeListOID"/>
        <!-- CodeListItem and EnumeratedItem are mutually exclusive, thus processing them in sequence displays only any one having data -->
        <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:CodeList/odm:CodeListItem[../@OID=$radio]">
          <xsl:sort select="@OrderNumber" data-type="number"/>
          <input type="radio" name="$radio"/>
            <label for="$radio">
              <xsl:value-of select="odm:Decode/odm:TranslatedText"/>
              <xsl:if test="normalize-space(odm:Decode/odm:TranslatedText) = ''">
                <xsl:value-of select="@CodedValue"/>
              </xsl:if>
              <span class="note"> (<xsl:value-of select="@CodedValue"/>)</span>
            </label>
            <br/>
        </xsl:for-each>
        <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:CodeList/odm:EnumeratedItem[../@OID=$radio]">
          <xsl:sort select="@OrderNumber" data-type="number"/>
          <input type="radio" name="$radio"/><label for="$radio"><xsl:value-of select="@CodedValue"/></label><br/>
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="@DataType = 'integer'">
        <input type="number"/><span class="note"> Integer</span>
      </xsl:when>
      <xsl:when test="@DataType = 'float'">
        <input type="number"/><span class="note"> Floating point</span>
      </xsl:when>
      <xsl:when test="@DataType = 'date'">
        <xsl:if test="$parmdisplay = 'data'">
          <input type="date"/><span class="note"> Date</span>
          <p class="note left">
            The displayed date is formatted based on the locale of the user's browser. Always collect dates as DD-MMM-YYYY and store dates as ISO8601 in SDTM.
          </p>
        </xsl:if>
        <xsl:if test="$parmdisplay != 'data'">
        <input type="text" placeholder="DD-MMM-YYYY"/><span class="note"> Date</span>
          <p class="note left">
            Always collect dates as DD-MMM-YYYY and store dates as ISO8601 in SDTM.
          </p>
        </xsl:if>
      </xsl:when>
      <xsl:when test="@DataType = 'time'">
        <xsl:if test="$parmdisplay = 'data'">
          <input type="time"/><span class="note"> Time</span>
          <p class="note left">
            The displayed time is formatted based on the locale of the user's browser. Always collect times as HH:MM and store times as ISO8601 in SDTM.
          </p>
        </xsl:if>
        <xsl:if test="$parmdisplay != 'data'">
          <input type="text" placeholder="HH:MM"/><span class="note"> Time</span>
          <p class="note left">
            Always collect times as HH:MM and store times as ISO8601 in SDTM.
          </p>
        </xsl:if>
      </xsl:when>
      <xsl:when test="@DataType = 'text'">
        <input type="text"/><span class="note"> Text</span>
      </xsl:when>
      <xsl:otherwise>
        <input>
          <xsl:attribute name="type">
            <xsl:value-of select="@DataType"/><span class="note"> ZZZZ</span>
          </xsl:attribute>
        </input>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Show the SDTM annotation to the question -->
  <xsl:template name="annotation">
    <xsl:param name="domain"/>
      <xsl:choose>
        <xsl:when test="normalize-space(odm:Alias[@Context='SDTM']/@Name) = '' and normalize-space(@SDSVarName) = ''">
        </xsl:when>
        <xsl:when test="normalize-space(odm:Alias[@Context='SDTM']/@Name) = ''">
          <xsl:value-of select="$domain"/>.<xsl:call-template name="define_anchor">
            <xsl:with-param name="target" select="@SDSVarName"/>
          </xsl:call-template>
          <xsl:value-of select="@SDSVarName"/>
        </xsl:when>
        <xsl:when test="normalize-space(@SDSVarName) = ''">
          <xsl:call-template name="break_lines">
            <xsl:with-param name="text" select="odm:Alias[@Context='SDTM']/@Name"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$domain"/>.<xsl:call-template name="define_anchor">
            <xsl:with-param name="target" select="@SDSVarName"/>
          </xsl:call-template><xsl:value-of select="@SDSVarName"/>,
          <br/>
          <xsl:call-template name="words">
            <xsl:with-param name="text_string" select="translate(odm:Alias[@Context='SDTM']/@Name, ',.=:- ', '¤¤¤¤¤¤')"/>
          </xsl:call-template>
          <xsl:call-template name="break_lines">
            <xsl:with-param name="text" select="odm:Alias[@Context='SDTM']/@Name"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
  </xsl:template>

  <!-- PDF anchor for define.xml -->
  <xsl:template name="define_anchor">
    <xsl:param name="target"/>
    <a>
      <xsl:attribute name="href">
        #<xsl:value-of select="$target"/>
      </xsl:attribute>
    </a>
    <a class="nohover">
      <xsl:attribute name="id">
        <xsl:value-of select="$target"/>
      </xsl:attribute>
    </a>
  </xsl:template>

  <!-- Replace occurences of '. ' (period blank) with HTML line break -->
  <xsl:template name="break_lines">
    <xsl:param name="text"/>
    <xsl:choose>
      <xsl:when test="$text = ''">
        <!-- Prevent this routine from hanging -->
        <xsl:value-of select="$text"/>
      </xsl:when>
      <xsl:when test="contains($text, '. ')">
        <xsl:value-of select="substring-before($text, '. ')"/>.
        <br/>
        <xsl:call-template name="break_lines">
          <xsl:with-param name="text" select="substring-after($text, '. ')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Split a string into words -->
  <xsl:template name="words">
    <xsl:param name="text_string" select="''"/>
    <xsl:param name="separator" select="'¤'"/>
    <xsl:if test="not($text_string = '' or $separator = '')">
      <xsl:variable name="head" select="substring-before(concat($text_string, $separator), $separator)"/>
      <xsl:variable name="tail" select="substring-after($text_string, $separator)"/>
      <xsl:call-template name="define_anchor">
        <xsl:with-param name="target" select="$head"/>
      </xsl:call-template>
      <xsl:call-template name="words">
        <xsl:with-param name="text_string" select="$tail"/>
        <xsl:with-param name="separator" select="$separator"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Show design notes for each question identified by the question reference number -->
  <xsl:template name="question_notes">
    <!-- Collect an indicator for each question design note for this form -->
    <xsl:variable name="qnotes">
      <xsl:for-each select="odm:ItemGroupRef">
        <xsl:variable name="groupkey1" select="@ItemGroupOID"/>
        <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:ItemGroupDef[@OID=$groupkey1]">
          <xsl:for-each select="odm:ItemRef">
            <xsl:variable name="itemkey1" select="@ItemOID"/>
            <xsl:if test="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:ItemDef[@OID=$itemkey1]/fdx:CustomAttributeSet/fdx:CustomAttribute[@Name = 'DesignNotes']/fdx:Value">
              Design note
            </xsl:if>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>

    <!-- Question Design Note(s), if any -->
    <xsl:if test="normalize-space($qnotes) != ''">
      <p/>
      <table class="desw">
        <thead>
          <tr><th class="left" colspan="2">Question design note(s)</th></tr>
        </thead>
        <tbody>
          <tr><td class="seqw">Question</td><td>Note</td></tr>
          <xsl:for-each select="odm:ItemGroupRef">
            <xsl:sort select="@OrderNumber" data-type="number"/>
            <xsl:variable name="groupnote" select="@ItemGroupOID"/>
            <xsl:variable name="gnumnote"  select="@OrderNumber"/>
            <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:ItemGroupDef[@OID=$groupnote]">
              <xsl:for-each select="odm:ItemRef">
                <xsl:sort select="@OrderNumber" data-type="number"/>
                <xsl:variable name="itemnote" select="@ItemOID"/>
                <xsl:variable name="inumnote" select="@OrderNumber"/>
                <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:ItemDef[@OID=$itemnote]">
                  <xsl:variable name="questionnote" select="fdx:CustomAttributeSet/fdx:CustomAttribute[@Name = 'DesignNotes']/fdx:Value"/>
                  <xsl:if test="normalize-space($questionnote) != ''">
                    <tr>
                      <td class="seqw">
                        <xsl:call-template name="sequence_number">
                          <xsl:with-param name="major"    select="$gnumnote"/>
                          <xsl:with-param name="minor"    select="$inumnote"/>
                          <xsl:with-param name="has_note" select="false"/>
                        </xsl:call-template>
                      </td>
                      <td class="note"><xsl:value-of select="$questionnote"/></td>
                    </tr>
                  </xsl:if>
                </xsl:for-each>
              </xsl:for-each>
            </xsl:for-each>
          </xsl:for-each>
        </tbody>
      </table>
    </xsl:if>
  </xsl:template>

  <!-- Form Design Note, if any -->
  <xsl:template name="form_notes">
    <xsl:if test="normalize-space(fdx:CustomAttributeSet/fdx:CustomAttribute[@Name = 'DesignNotes']/fdx:Value) != ''">
      <p/>
      <table class="desw">
        <thead>
          <tr><th class="left">Form design note</th></tr>
        </thead>
        <tbody>
          <tr><td class="note"><xsl:value-of select="fdx:CustomAttributeSet/fdx:CustomAttribute[@Name = 'DesignNotes']/fdx:Value"/></td></tr>
        </tbody>
      </table>
    </xsl:if>
    <xsl:call-template name="question_notes"/>
  </xsl:template>
</xsl:stylesheet>
