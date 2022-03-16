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
                version="1.0"
                xml:lang="en"
                exclude-result-prefixes="def xlink odm xsi arm">
  <xsl:output   method="html"
                indent="yes"
                encoding="utf-8"
                doctype-system="http://www.w3.org/TR/html4/strict.dtd"
                doctype-public="-//W3C//DTD HTML 4.01//EN"
                version="4.0"/>

  <!-- Parameters passed from outside. Default display mode is a blank CRF:
       * bcrf: Blank CRF for submission (default)
       * acrf: SDTM annotated CRF for submission with SDTM annotations
       * spec: CRF specifcation with selection buttons, implementation notes, SDTM annotations
       * book: Complete CRF book with forms repeated by visit
       * data: Final CRF ready for data collection (future)
       Standard name, version, and status are derived from the XML file name externally
       Any image logo file may be resized to fit the text height of a headline, preserving aspect
  -->
  <xsl:param name="parmdisplay" select="spec"/> <!-- Display mode -->
  <xsl:param name="parmstudy"/>                 <!-- Name of any study or standard defined in the ODM-XML file -->
  <xsl:param name="parmversion"/>               <!-- Version of the ODM-XML file -->
  <xsl:param name="parmstatus"/>                <!-- Status of the ODM-XML file -->
  <xsl:param name="parmname"/>                  <!-- Company name -->
  <xsl:param name="parmlogo"/>                  <!-- Company logo -->
  <xsl:param name="parmlang"/>                  <!-- Language of TranslatedText (future) -->
  <xsl:param name="parmcdash" select="1"/>      <!-- Display CDASH annotation from Alias (if present) (0/1) -->

  <!-- Keys to sort forms in the order of visit schedule, if present -->
  <xsl:key name="by_StudyEventRef" match="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:Protocol/odm:StudyEventRef" use="@StudyEventOID"/>
  <xsl:key name="by_FormRef"       match="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:StudyEventDef/odm:FormRef"  use="@FormOID"/>

  <!-- Special characters in variables for enhanced readability -->
  <xsl:variable name="checkmark" select="'&#10004;'"/> <!-- ✔ -->
  <xsl:variable name="infinity"  select="'&#8734;'"/>  <!-- ∞ -->
  <xsl:variable name="spacechar" select="'&#0160;'"/>  <!--   -->

  <xsl:template match="/">
    <html>
      <head>
        <title>
          <xsl:call-template name="identifier"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="$parmversion"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="$parmstatus"/>
        </title>
        <meta http-equiv="Content-Type"    content="text/html;charset=utf-8"/>
        <meta http-equiv="X-UA-Compatible" content="IE=9"/>
        <meta http-equiv="cache-control"   content="no-cache"/>
        <meta http-equiv="pragma"          content="no-cache"/>
        <meta http-equiv="expires"         content="0"/>
        <meta name="Author"                content="Jørgen Mangor Iversen"/>
        <style>
          html          { margin: 1em 1em 1em 1em; }
          *             { font-family: Helvetica, Arial, sans-serif !important; }
          h1, h2, h3, p { text-align: center; }
          table         { solid DarkGrey; border-spacing: 0; border-collapse: collapse; page-break-inside: auto; }
          tr            { page-break-inside:avoid; page-break-after:auto; }
          th, td        { border: 1px solid DarkGrey; }
          a:link        { color: black; background-color: transparent; text-decoration: none; }
          a:visited     { color: black; background-color: transparent; text-decoration: none; }
          a:hover       { color: blue;  background-color: transparent; text-decoration: underline; }
          .nohover      { pointer-events: none; }
          @media print  { .noprint { display: none; } thead {display: table-header-group; } }
          .noprint      { position: fixed; bottom: 0.5em; right: 0.5em; z-index: 99; }
          .rotate span  { writing-mode: vertical-rl; transform: rotate(180deg); }
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
          .plain        { font-weight: normal; }
          .small        { font-size: 0.7em; vertical-align: midddle;}
          .inpw         { width: 40%; }
          .maxw         { width: 100%; }
          .seqw         { width: 5em !important; }
          .cdash        { background-color: lightblue; padding: 2px; color: Blue; border: 2px double Blue !important; }
          <xsl:choose>
            <xsl:when test="$parmdisplay = 'spec' or $parmdisplay = 'acrf'">
              .anno     { background-color: LightYellow; }
              .quew     { width: 30%; }
              .answ     { width: 25%; }
              .annw     { width: 40%; }
              .desw     { width: 60%; }
            </xsl:when>
            <xsl:otherwise>
              .anno     { visibility: hidden; display: none; }
              .quew     { width:  50%; }
              .answ     { width:  45%; }
              .desw     { width: 100%; }
            </xsl:otherwise>
          </xsl:choose>
        </style>
      </head>
      <body>
        <xsl:call-template name="buttons"/>
        <xsl:apply-templates select="/odm:ODM/odm:Study[1]/odm:GlobalVariables"/>
        <xsl:apply-templates select="/odm:ODM"/>
<!--
        <xsl:value-of select="$parmlang"/>
-->

        <p style="page-break-before: always; margin-top: 0;"/>

        <!-- Either Toc or Visit Matrix for navigation -->
        <xsl:if test="not(/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:StudyEventDef)">
          <xsl:call-template name="toc"/>
        </xsl:if>
        <xsl:if test="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:StudyEventDef">
          <xsl:call-template name="visit_matrix"/>
        </xsl:if>

        <xsl:choose>
          <xsl:when test="$parmdisplay = 'book' or $parmdisplay = 'data'">
            <!-- for each visit, for each form -->
            <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:Protocol/odm:StudyEventRef">
              <xsl:sort select="@OrderNumber" data-type="number"/>
              <xsl:variable name="studyeventoid" select="@StudyEventOID"/>
              <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:StudyEventDef[@OID=$studyeventoid]/odm:FormRef">
                <xsl:sort select="key('by_FormRef', @OID)/@OrderNumber" data-type="number"/>
                <xsl:variable name="formoid"   select="@FormOID"/>
                <xsl:variable name="visitname" select="../@Name"/>
                <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:FormDef[@OID=$formoid]">
                  <xsl:call-template name="one_form">
                    <xsl:with-param name="vis_target" select="$studyeventoid"/>
                    <xsl:with-param name="vis_name"   select="$visitname"/>
                  </xsl:call-template>
                </xsl:for-each>
              </xsl:for-each>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <!-- One table per form becomes one form per page -->
            <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:FormDef">
              <!-- If visit structure is not present, forms will be sorted in FormDef tag order of the ODM file itself -->
              <xsl:sort select="key('by_StudyEventRef', key('by_FormRef', @OID)/../@OID)/@OrderNumber" data-type="number"/>
              <xsl:sort select="key('by_FormRef', @OID)/@OrderNumber" data-type="number"/>
              <xsl:call-template name="one_form"/>
            </xsl:for-each>
          </xsl:otherwise>
        </xsl:choose>

      </body>
    </html>
  </xsl:template>

  <!-- Show one Form -->
  <xsl:template name="one_form">
    <xsl:param name="vis_target"/>
    <xsl:param name="vis_name"/>
    <table class="maintable">
      <p style="page-break-before: always;"/>
      <xsl:call-template name="table_head">
        <xsl:with-param name="visit_target" select="$vis_target"/>
        <xsl:with-param name="visit_name"   select="$vis_name"/>
      </xsl:call-template>
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
                <tr>
                  <td class="seqw">
                    <xsl:call-template name="sequence_number">
                      <xsl:with-param name="major"    select="$gnum"/>
                      <xsl:with-param name="minor"    select="$inum"/>
                      <xsl:with-param name="has_note" select="normalize-space(odm:Alias[@Context='implementationNotes']/@Name) != ''"/> <!-- Implementation Notes -->
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
  </xsl:template>

  <!-- Non printable buttons to turn elements off and on.
       In-line JavaScript as SCRIPT sections will not execute and onload() will not fire -->
  <xsl:template name="buttons">
    <table class="noprint">
      <tr>
        <xsl:if test="$parmcdash = '1' and .//odm:Alias[@Context='CDASH']">
          <td class="noborder">
            <button onClick="for(var element of document.querySelectorAll('[id=cdash]')) element.style.visibility = (element.style.visibility == 'collapse') ? 'visible' : 'collapse';">
              CDASH annotations Off and On
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
      <xsl:when test="normalize-space(/odm:ODM/odm:Study[1]/odm:GlobalVariables/odm:StudyName) = 'Not applicable' and normalize-space($parmstudy) != ' '">
        <xsl:value-of select="$parmstudy"/>
      </xsl:when>
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
    <xsl:choose>
      <xsl:when test="$parmdisplay = 'book'">
        <h1>CRF Book</h1>
      </xsl:when>
      <xsl:when test="normalize-space(/odm:ODM/odm:Study[1]/odm:GlobalVariables/odm:StudyName) = 'Not applicable'">
        <h1>Standard</h1>
      </xsl:when>
      <xsl:otherwise>
        <h1>Study</h1>
      </xsl:otherwise>
    </xsl:choose>
    <h1>CRF Specification for <xsl:call-template name="identifier"/></h1>
    <xsl:if test="$parmversion != ''">
      <h3><xsl:value-of select="$parmversion"/></h3>
    </xsl:if>
    <xsl:if test="$parmstatus != ''">
      <h3>Status: <xsl:value-of select="$parmstatus"/></h3>
    </xsl:if>
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
      <p>
        Creation date: <xsl:value-of select="substring-before(@CreationDateTime, 'T')"/>
        time: <xsl:value-of select="substring-before(substring-after(@CreationDateTime, 'T'), '+')"/>
      </p>
    </xsl:if>
    <xsl:if test="normalize-space(@AsOfDateTime) != ''">
      <p>
        Valid from date: <xsl:value-of select="substring-before(@AsOfDateTime, 'T')"/>
        time: <xsl:value-of select="substring-before(substring-after(@AsOfDateTime, 'T'), '+')"/>
      </p>
    </xsl:if>
    <h3><xsl:value-of select="$parmname"/></h3>
    <p>
      <img>
        <xsl:attribute name="src">
          <xsl:value-of select="$parmlogo"/>
        </xsl:attribute>
      </img>
    </p>
  </xsl:template>

  <!-- Toc, Alfabetic sorting of Forms by name -->
  <xsl:template name="toc">
    <table class="center maxw">
      <thead>
        <tr>
          <td class="noborder">
            <h2 class="center">Table of Contents</h2>
          </td>
        </tr>
      </thead>
      <tbody>
        <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:FormDef">
          <xsl:sort select="@Name" data-type="text"/>
          <tr>
            <td colspan="3" class="noborder matrix">
              <xsl:call-template name="form_link">
                <xsl:with-param name="name"  select="@Name"/>
                <xsl:with-param name="oid"   select="@OID"/>
              </xsl:call-template>
              <p/>
            </td>
          </tr>
        </xsl:for-each>
      </tbody>
    </table>
  </xsl:template>

  <!-- Vist Matrix -->
  <xsl:template name="visit_matrix">
    <table class="center landscape">
      <thead>
        <tr>
          <td class="noborder" colspan="99">
            <h2 class="center">Visit Matrix</h2>
          </td>
        </tr>
        <tr>
          <th class="left crfhead">Event/<br/>Form</th>
          <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:Protocol/odm:StudyEventRef">
            <xsl:sort select="@OrderNumber" data-type="number"/>
            <xsl:variable name="visithead" select="@StudyEventOID"/>
            <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:StudyEventDef[@OID=$visithead]">
              <th class="crfhead rotate">
                <xsl:choose>
                  <xsl:when test="$parmdisplay = 'book' or $parmdisplay = 'data'">
                <span>
                  <a>
                    <xsl:attribute name="href">#<xsl:value-of select="$visithead"/></xsl:attribute>
                    <xsl:value-of select="@Name"/>
                  </a>
                </span>
                  </xsl:when>
                  <xsl:otherwise>
                    <span><xsl:value-of select="@Name"/></span>
                  </xsl:otherwise>
                </xsl:choose>
              </th>
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
                <xsl:with-param name="name"  select="@Name"/>
                <xsl:with-param name="oid"   select="@OID"/>
              </xsl:call-template>
              <xsl:if test="contains(odm:Alias[@Context='implementationNotes']/@Name, 'Repeating form')"> <!-- Implementation Notes. Candidate for deletion -->
                <em class="check"> [<xsl:text>&#8734;</xsl:text>]</em> <!-- ∞ -->
              </xsl:if>
            </td>
            <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:Protocol/odm:StudyEventRef">
              <xsl:sort select="@OrderNumber" data-type="number"/>
              <td class="matrix check">
                <xsl:variable name="visitbody"  select="@StudyEventOID"/>
                <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:StudyEventDef[@OID=$visitbody]">
                  <xsl:for-each select="odm:FormRef">
                    <xsl:if test="$formrow = @FormOID">
                      <xsl:text>&#10004;</xsl:text> <!-- ✔ -->
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
    <xsl:param name="visit_target"/>
    <xsl:param name="visit_name"/>
    <thead>
      <xsl:if test="$parmdisplay = 'book' or $parmdisplay = 'data'">
        <tr>
          <th colspan="4" class="noborder">
            <table class="maintable">
              <tr>
                <td class="plain small" rowspan="2">
                  <xsl:if test="$parmlogo != ''">
                    <a class="nohover">
                      <xsl:attribute name="id">
                        <xsl:value-of select="$visit_target"/>
                      </xsl:attribute>
                      <img height="40">
                        <xsl:attribute name="src">
                          <xsl:value-of select="$parmlogo"/>
                        </xsl:attribute>
                      </img>
                    </a>
                  </xsl:if>
                </td>
                <td class="formtitle">
                  <xsl:if test="$parmname != ''">
                    <xsl:value-of select="$parmname"/>
                  </xsl:if>
                </td>
                <td class="formtitle">
                  <xsl:call-template name="identifier"/>
                </td>
                <td class="plain small">
                  <xsl:value-of select="$parmversion"/>
                  <xsl:text> </xsl:text>
                  <xsl:value-of select="$parmstatus"/>
                </td>
              </tr>
              <tr>
                <td class="plain small">
                  Site <input type="text" class="inpw"/>
                </td>
                <td class="plain small">
                  Subject identifier <input type="text" class="inpw"/>
                </td>
                <td class="plain small">
                  <xsl:value-of select="$visit_name"/>
                </td>
              </tr>
              <tr><th colspan="4" class="noborder"><br/></th></tr>
            </table>
          </th>
        </tr>
      </xsl:if>
      <tr>
        <th colspan="4" class="noborder">
          <div class="left formtitle">
            <a class="nohover">
              <xsl:attribute name="id">
                <xsl:value-of select="@OID"/>
              </xsl:attribute>
              <span>
                <xsl:value-of select="@Name"/>
              </span>
            </a>
            <xsl:if test="$parmdisplay = 'spec' and normalize-space(odm:Alias[@Context='implementationNotes']/@Name) != ''"> <!-- Implementation Notes -->
              #
            </xsl:if>
          </div>
        </th>
      </tr>
      <xsl:if test="normalize-space(odm:Alias[@Context='completionInstructions']/@Name) != ''"> <!-- Completion Instructions. Candidate for deletion -->
        <tr>
          <th colspan="4" class="noborder">
            <xsl:apply-templates select="odm:Alias[@Context='completionInstructions']/@Name"/> <!-- Completion Instructions. Candidate for deletion -->
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
      <tr><th colspan="4" class="noborder"><br/></th></tr>
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

<!--
  <xsl:template name="translatedtext">
    <xsl:param name="text"/>
    <xsl:param name="lang"/>
    <xsl:choose>
      <xsl:when test="normalize-space($lang) = ''">
        <xsl:value-of select="$text"/>
      </xsl:when>
      <xsl:when test="string-length($lang) = 2">
        <xsl:value-of
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

-->
  <!-- Add Note from Description/TranslatedText to Forms -->
  <xsl:template match="odm:Description">
    <div class="left note">
      <xsl:value-of select="odm:TranslatedText"/>
    </div>
  </xsl:template>

  <!-- Create a link to a form -->
  <xsl:template name="form_link">
    <xsl:param name="name"/>
    <xsl:param name="oid"/>
    <a>
      <xsl:attribute name="href">#<xsl:value-of select="$oid"/></xsl:attribute>
      <span>
        <xsl:value-of select="$name"/>
      </span>
    </a>
  </xsl:template>

  <!-- Show the sequence number as a reference to each question -->
  <xsl:template name="sequence_number">
    <xsl:param name="major"/>
    <xsl:param name="minor"/>
    <xsl:param name="has_note"/>
    <xsl:value-of select="$major"/>.<xsl:value-of select="$minor"/>
    <xsl:if test="$parmdisplay = 'spec' and $has_note">
      #
    </xsl:if>
  </xsl:template>

  <!-- Show one question on the form, including guidance text and completion note -->
  <xsl:template name="question">
    <xsl:choose>
      <xsl:when test="$parmdisplay = 'data' and odm:Alias[@Context='prompt']">
        <xsl:value-of select="normalize-space(odm:Alias[@Context='prompt']/@Name)"/> <!-- Prompt text for data entry -->
      </xsl:when>
      <xsl:when test="odm:Question/odm:TranslatedText">
        <xsl:value-of select="odm:Question/odm:TranslatedText"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="@Name"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="$parmdisplay = 'spec' and odm:Alias[@Context='prompt']">
      <xsl:value-of select="odm:Alias[@Context='prompt']"/>
    </xsl:if>
    <xsl:if test="$parmdisplay = 'spec' and odm:Alias[@Context='prompt']">
      <p class="left">
        PROMPT:
        <xsl:value-of select="odm:Alias[@Context='prompt']/@Name"/>
      </p> <!-- Prompt text for data entry -->
    </xsl:if>
    <xsl:if test="odm:Alias[@Context='completionInstructions']/@Name">
      <p class="note left"><xsl:value-of select="odm:Alias[@Context='completionInstructions']/@Name"/></p> <!-- Completion Instructions -->
    </xsl:if>
<!--
    Description at question level contains a repeat of the CDASH Alias in all the CDISC ePortal forms
    <xsl:apply-templates select="odm:Description"/>
-->
  </xsl:template>

  <!-- Collect the data as answer to the question -->
  <xsl:template name="answer">
    <xsl:choose>
      <!-- Questions having the text 'all that apply' associated anywhere are data type Checkbox -->
      <xsl:when test="contains(@Name,                                              'all that apply') or
                      contains(odm:Question/odm:TranslatedText,                    'all that apply') or
                      contains(odm:Description/odm:TranslatedText,                 'all that apply') or
                      contains(odm:Alias[@Context='completionInstructions']/@Name, 'all that apply')">
        <xsl:variable name="check" select="odm:CodeListRef/@CodeListOID"/>
        <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:CodeList/odm:CodeListItem[../@OID=$check]">
          <xsl:sort select="@OrderNumber" data-type="number"/>
          <input type="checkbox" name="$check"/><label for="$check"><xsl:value-of select="odm:Decode/odm:TranslatedText"/><span class="note"> (<xsl:value-of select="@CodedValue"/>)</span></label><br/>
        </xsl:for-each>
      </xsl:when>
      <!-- Questions having code lists associates without the text 'all that apply' are data type Radio buttons -->
      <xsl:when test="normalize-space(odm:CodeListRef/@CodeListOID) != ''">
        <xsl:variable name="radio" select="odm:CodeListRef/@CodeListOID"/>
        <!-- CodeListItem and EnumeratedItem are mutually exclusive, thus processing them in sequence displays only the one having data -->
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
      <!-- Data type integer -->
      <xsl:when test="@DataType = 'integer'">
        <input type="number"/><span class="note"> Integer</span>
      </xsl:when>
      <!-- Data type float -->
      <xsl:when test="@DataType = 'float'">
        <input type="number"/><span class="note"> Floating point</span>
      </xsl:when>
      <!-- Data type date -->
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
      <!-- Data type time -->
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
      <!-- Data type text -->
      <xsl:when test="@DataType = 'text'">
        <input type="text"/><span class="note"> Text</span>
      </xsl:when>
      <!-- Unknown data type is marked for debugging -->
      <xsl:otherwise>
        <input>
          <xsl:attribute name="type">
            <xsl:value-of select="@DataType"/><span class="note">UNKNOWN DATA TYPE</span>
          </xsl:attribute>
        </input>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="$parmcdash = '1' and odm:Alias[@Context='CDASH']">
      <table class="cdash left" id="cdash">
        <tr>
          <td>
            CDASH:
            <xsl:value-of select="normalize-space(odm:Alias[@Context='CDASH']/@Name)"/>
          </td>
        </tr>
      </table>
    </xsl:if>
  </xsl:template>

  <!-- Show the SDTM annotation to the question -->
  <xsl:template name="annotation">
    <xsl:param name="domain"/>
    <xsl:call-template name="dataset">
      <xsl:with-param name="dsn_domain"     select="normalize-space($domain)"/>
      <xsl:with-param name="dsn_sdsvarname" select="normalize-space(@SDSVarName)"/>
      <xsl:with-param name="dsn_alias"      select="normalize-space(odm:Alias[@Context='SDTM']/@Name)"/>
    </xsl:call-template>
    <xsl:call-template name="variable">
      <xsl:with-param name="var_sdsvarname" select="normalize-space(@SDSVarName)"/>
      <xsl:with-param name="var_alias"      select="normalize-space(odm:Alias[@Context='SDTM']/@Name)"/>
    </xsl:call-template>
    <!-- Add a comma and a line break if SDTM Alias contains additional annotations, then additional annotatoins -->
    <xsl:if test="contains(translate(odm:Alias[@Context='SDTM']/@Name, ',=', '  '), ' ')">
      <xsl:text>,</xsl:text>
      <br/>
      <xsl:call-template name="words">
        <xsl:with-param name="text_string" select="translate(odm:Alias[@Context='SDTM']/@Name, ',.=:- ', '¤¤¤¤¤¤')"/>
      </xsl:call-template>
      <xsl:call-template name="break_lines">
        <xsl:with-param name="lines" select="substring-after(odm:Alias[@Context='SDTM']/@Name, ',')"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Decide and print dataset name as prefix to variable name delimited by a dot -->
  <xsl:template name="dataset">
    <xsl:param name="dsn_domain"/>
    <xsl:param name="dsn_sdsvarname"/>
    <xsl:param name="dsn_alias"/>
    <xsl:choose>
      <!-- If the Domain attribute for ItemgroupDef has a value -->
      <xsl:when test="$dsn_domain != ''">
        <xsl:value-of select="$dsn_domain"/><xsl:text>.</xsl:text>
      </xsl:when>
      <!-- If the SDSVarName attribute for ItemDef has a value with a dot in the first 9 characters -->
      <xsl:when test="$dsn_sdsvarname != ''">
        <xsl:if test="contains(substring($dsn_sdsvarname, 1, 9), '.')">
          <xsl:value-of select="substring-before($dsn_sdsvarname, '.')"/><xsl:text>.</xsl:text>
        </xsl:if>
      </xsl:when>
      <!-- If the SDTM Alias for ItemDef has a value with a dot in the first 9 characters -->
      <xsl:when test="$dsn_alias != ''">
        <xsl:if test="contains(substring($dsn_alias, 1, 9), '.')">
          <xsl:value-of select="substring-before($dsn_alias, '.')"/><xsl:text>.</xsl:text>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <!-- If no dataset value, don't print it -->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Decide and print variable name, possibly first or second word of SDTM annotation -->
  <xsl:template name="variable">
    <xsl:param name="var_sdsvarname"/>
    <xsl:param name="var_alias"/>
    <xsl:choose>
      <!-- If SDSVarName attribute has a value -->
      <xsl:when test="$var_sdsvarname != ''">
        <xsl:choose>
          <!-- If SDSVarName attribute has a dot in the first 9 characters -->
          <xsl:when test="contains(substring($var_sdsvarname, 1, 9), '.')">
            <xsl:call-template name="define_anchor">
              <xsl:with-param name="target" select="substring-after($var_sdsvarname, '.')"/>
            </xsl:call-template>
            <xsl:value-of select="substring-after($var_sdsvarname, '.')"/>
          </xsl:when>
          <!-- Else just print it unaltered -->
          <xsl:otherwise>
            <xsl:call-template name="define_anchor">
              <xsl:with-param name="target" select="@var_sdsvarname"/>
            </xsl:call-template>
            <xsl:value-of select="$var_sdsvarname"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- If SDTM Alias has a value -->
      <xsl:when test="$var_alias != ''">
        <xsl:choose>
          <!-- If SDTM Alias for ItemDef has a value with a dot in the first 9 character, print the word after the dot -->
          <xsl:when test="contains(substring($var_alias, 1, 9), '.')">
            <xsl:choose>
              <xsl:when test="contains($var_alias, ' ')">
                <xsl:call-template name="define_anchor">
                  <xsl:with-param name="target" select="substring-before(translate(substring-after($var_alias, '.'), ',.', '  '), ' ')"/>
                </xsl:call-template>
                <xsl:value-of select="substring-before(translate(substring-after($var_alias, '.'), ',.', '  '), ' ')"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="define_anchor">
                  <xsl:with-param name="target" select="substring-after($var_alias, '.')"/>
                </xsl:call-template>
                <xsl:value-of select="substring-after($var_alias, '.')"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <!-- If SDTM Alias for ItemDef contains more than one word -->
          <xsl:when test="contains($var_alias, ' ')">
            <xsl:call-template name="define_anchor">
              <xsl:with-param name="target" select="substring-before(translate($var_alias, ',.', '  '), ' ')"/>
            </xsl:call-template>
            <xsl:value-of select="substring-before(translate($var_alias, ',.', '  '), ' ')"/>
          </xsl:when>
          <!-- Else just print it unaltered -->
          <xsl:otherwise>
            <xsl:call-template name="define_anchor">
              <xsl:with-param name="target" select="$var_alias"/>
            </xsl:call-template>
            <xsl:value-of select="$var_alias"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <!-- If no variable value, don't print it -->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- PDF anchor for define.xml. Also create a link to the target to preserve the target -->
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
    <xsl:param name="lines"/>
    <xsl:choose>
      <xsl:when test="$lines = ''">
        <!-- Prevent this routine from hanging -->
        <xsl:value-of select="$lines"/>
      </xsl:when>
      <xsl:when test="contains($lines, '. ')">
        <xsl:value-of select="substring-before($lines, '. ')"/>.
        <br/>
        <xsl:call-template name="break_lines">
          <xsl:with-param name="lines" select="substring-after($lines, '. ')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$lines"/>
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
    <xsl:if test="$parmdisplay = 'spec'">
    <xsl:variable name="qnotes">
      <xsl:for-each select="odm:ItemGroupRef">
        <xsl:variable name="groupkey1" select="@ItemGroupOID"/>
        <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:ItemGroupDef[@OID=$groupkey1]">
          <xsl:for-each select="odm:ItemRef">
            <xsl:variable name="itemkey1" select="@ItemOID"/>
            <xsl:if test="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:ItemDef[@OID=$itemkey1]/odm:Alias[@Context='implementationNotes']/@Name"> <!-- Implementation Notes -->
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
                  <xsl:variable name="questionnote" select="odm:Alias[@Context='implementationNotes']/@Name"/> <!-- Implementation Notes -->
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
    </xsl:if>
  </xsl:template>

  <!-- Form Design Note, if any. Candidate for deletion -->
  <xsl:template name="form_notes">
    <xsl:if test="$parmdisplay = 'spec' and normalize-space(odm:Alias[@Context='implementationNotes']/@Name) != ''"> <!-- Implementation Notes -->
      <p/>
      <table class="desw">
        <thead>
          <tr><th class="left">Form design note</th></tr>
        </thead>
        <tbody>
          <tr><td class="note"><xsl:value-of select="odm:Alias[@Context='implementationNotes']/@Name"/></td></tr> <!-- Implementation Notes -->
        </tbody>
      </table>
    </xsl:if>
    <xsl:call-template name="question_notes"/>
  </xsl:template>
</xsl:stylesheet>
