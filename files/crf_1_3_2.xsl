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
       * spec: CRF specification with selection buttons, implementation notes, SDTM annotations (default)
       * bcrf: Blank CRF for submission
       * acrf: SDTM annotated CRF for submission
       * book: Complete CRF book with forms repeated by visit
       Standard name, version, and status are derived from the XML file name externally
       Any image logo file may be resized to fit the text height of a headline, preserving aspect
  -->
  <xsl:param name="parmdisplay" select="spec"/> <!-- Display mode -->
  <xsl:param name="parmstudy"/>                 <!-- Name of any study or standard defined in the ODM-XML file -->
  <xsl:param name="parmversion"/>               <!-- Version of the ODM-XML file -->
  <xsl:param name="parmstatus"/>                <!-- Status of the ODM-XML file -->
  <xsl:param name="parmname"/>                  <!-- Company name -->
  <xsl:param name="parmlogo"/>                  <!-- Company logo file name -->
  <xsl:param name="parmlang"/>                  <!-- Language of TranslatedText (future) -->
  <xsl:param name="parmcdash" select="1"/>      <!-- Display CDASH annotation from Alias (if present) (0/1) -->
  <xsl:param name="parmoids"  select="0"/>      <!-- Display identifiers (OIDs)          (if present) (0/1) -->

  <!-- Keys to sort forms in the order of visit schedule, if present -->
  <xsl:key name="by_StudyEventRef" match="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:Protocol/odm:StudyEventRef" use="@StudyEventOID"/>
  <xsl:key name="by_FormRef"       match="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:StudyEventDef/odm:FormRef"  use="@FormOID"/>

  <!-- Variables for case conversion -->
  <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'" />
  <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />

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
          @media print  { .noprint { display: none; } thead { display: table-header-group; } .rotate { padding: 0px 0px 0px 0px; margin: 0px; } }
          .noprint      { position: fixed; bottom: 0.5em; right: 0.5em; z-index: 99; }
          .rotate span  { writing-mode: vertical-rl; transform: rotate(180deg); white-space: nowrap; }
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
            <xsl:when test="$parmdisplay = 'spec' or $parmdisplay = 'acrf' or normalize-space($parmdisplay) = ''">
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
          <xsl:if test="$parmdisplay != 'spec' and normalize-space($parmdisplay) != ''">
              #internal { visibility: hidden; display: none; }
          </xsl:if>
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
        <xsl:if test="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:StudyEventDef">
          <xsl:call-template name="visit_matrix"/>
          <p style="page-break-before: always; margin-top: 0;"/>
        </xsl:if>
        <xsl:call-template name="toc"/>

        <xsl:choose>
          <xsl:when test="$parmdisplay = 'book'">
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
            <xsl:if test="$parmoids = '1'">
              <xsl:call-template name="section"/>
            </xsl:if>
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
                      <xsl:with-param name="has_note" select="normalize-space(
                        odm:Alias[@Context='implementationNotes']/@Name)
                          != ''"/> <!-- Implementation Notes -->
                    </xsl:call-template>
                  </td>
                  <td class="quew">
                    <xsl:call-template name="question"/>
                  </td>
                  <td class="answ">
                    <xsl:call-template name="answer"/>
                  </td>
                  <td id="anno" class="annw anno">
                    <xsl:if test="odm:Alias[@Context='Target']/@Name">
                      <xsl:call-template name="define_anchor">
                        <xsl:with-param name="target" select="odm:Alias[@Context='Target']/@Name"/>
                      </xsl:call-template>
                    </xsl:if>
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
        <xsl:if test="$parmoids = '1'">
          <td class="noborder">
            <button onClick="for(var element of document.querySelectorAll('[id=oids]')) element.style.visibility = (element.style.visibility == 'collapse') ? 'visible' : 'collapse';">
              Identifiers Off and On
            </button>
          </td>
        </xsl:if>
        <xsl:if test="$parmdisplay = 'spec' or normalize-space($parmdisplay) = ''">
          <td class="noborder">
            <button onClick="for(var element of document.querySelectorAll('[id=anno]')) element.style.visibility   = (element.style.visibility   == 'collapse') ? 'visible' : 'collapse';
                             for(var element of document.querySelectorAll('[id=anno]')) element.style.borderRight  = (element.style.borderRight  == '0px') ? '1px solid Darkgrey' : '0px';
                             for(var element of document.querySelectorAll('[id=anno]')) element.style.borderBottom = (element.style.borderBottom == '0px') ? '1px solid Darkgrey' : '0px';
                             for(var element of document.querySelectorAll('[id=anno]')) element.style.borderTop    = (element.style.borderTop    == '0px') ? '1px solid Darkgrey' : '0px';">
              SDTM annotations Off and On
            </button>
          </td>
          <td class="noborder">
            <button onClick="for(var element of document.querySelectorAll('[id=internal]')) element.style.visibility = (element.style.visibility == 'collapse') ? 'visible' : 'collapse';">
              Internal notes Off and On
            </button>
          </td>
          <td class="noborder">
            <button onClick="for(var element of document.querySelectorAll('[id=implement]')) element.style.visibility = (element.style.visibility == 'collapse') ? 'visible' : 'collapse';">
              Implementation notes Off and On
            </button>
          </td>
        </xsl:if>
        <xsl:if test=".//odm:Alias[@Context='completionInstructions']/@Name">
          <td class="noborder">
            <button onClick="for(var element of document.querySelectorAll('[id=complete]')) element.style.visibility = (element.style.visibility == 'collapse') ? 'visible' : 'collapse';">
              Completion instructions Off and On
            </button>
          </td>
        </xsl:if>
        <xsl:if test="($parmdisplay = 'spec' or normalize-space($parmdisplay) != '') and $parmcdash = '1' and .//odm:Alias[@Context='CDASH']">
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
      <xsl:when test="normalize-space(/odm:ODM/odm:Study[1]/odm:GlobalVariables/odm:StudyName) = 'Not applicable' and normalize-space($parmstudy) != ''">
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
      <h2>Protocol Name: <xsl:value-of select="odm:ProtocolName"/></h2>
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
          <xsl:if test="not(contains($parmlogo, '.'))">data:image/png;base64,</xsl:if><xsl:value-of select="$parmlogo"/>
        </xsl:attribute>
      </img>
    </p>
  </xsl:template>

  <!-- Toc, Alfabetic sorting of Forms by name -->
  <xsl:template name="toc">
    <table class="center maxw">
      <thead>
        <tr>
          <td class="noborder" colspan="3">
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
    <table class="center">
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
              <th class="crfhead rotate plain">
                <xsl:choose>
                  <xsl:when test="$parmdisplay = 'book'">
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
              <xsl:if test="contains(
                odm:Alias[@Context='implementationNotes']/@Name,
                  'Repeating form')"> <!-- Implementation Notes. Candidate for deletion -->
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
      <xsl:if test="$parmdisplay = 'book'">
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
                          <xsl:if test="not(contains($parmlogo, '.'))">data:image/png;base64,</xsl:if><xsl:value-of select="$parmlogo"/>
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
            <xsl:if test="($parmdisplay = 'spec' or normalize-space($parmdisplay) = '') and
                             normalize-space(odm:Alias[@Context='implementationNotes']/@Name) != ''">
                               <!-- Implementation Notes -->
              <text id="implement"> #</text>
            </xsl:if>
            <xsl:if test="$parmoids = '1'">
              <span id="oids" class="note">
                <br/>FormDef OID = <xsl:value-of select="@OID"/>
              </span>
            </xsl:if>
          </div>
        </th>
      </tr>
      <xsl:if test="normalize-space(
        odm:Alias[@Context='completionInstructions']/@Name)
          != ''"> <!-- Completion Instructions. Candidate for deletion -->
        <tr id="complete">
          <th colspan="4" class="noborder left note">
            <xsl:apply-templates select=
              "odm:Alias[@Context='completionInstructions']/@Name"/>
                <!-- Completion Instructions. Candidate for deletion -->
          </th>
        </tr>
      </xsl:if>
      <xsl:if test="odm:Description">
        <tr id="internal">
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
        <xsl:if test="$parmdisplay = 'spec' or normalize-space($parmdisplay) = '' or $parmdisplay = 'acrf'">
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
    <div id="internal" class="left note">
      <xsl:value-of select="odm:TranslatedText"/> <!-- Implementation Notes -->
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

  <!-- Show a section -->
  <xsl:template name="section">
    <tr id="oids">
      <td class="seqw"/>
      <td class="quew note">
        ItemGroupDef OID = <xsl:value-of select="@OID"/>
      </td>
      <td class="answ"/>
      <td class="annw anno" id="anno"/>
    </tr>
  </xsl:template>

  <!-- Show the sequence number as a reference to each question -->
  <xsl:template name="sequence_number">
    <xsl:param name="major"/>
    <xsl:param name="minor"/>
    <xsl:param name="has_note"/>
    <xsl:value-of select="$major"/>.<xsl:value-of select="$minor"/>
    <xsl:if test="($parmdisplay = 'spec' or normalize-space($parmdisplay) = '') and $has_note">
      <text id="implement"> #</text>
    </xsl:if>
  </xsl:template>

  <!-- Show one question on the form, including guidance text and completion note -->
  <xsl:template name="question">
    <xsl:if test="$parmoids = '1'">
      <div id="oids" class="note">
        ItemDef OID = <xsl:value-of select="@OID"/>
      </div>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="odm:Question/odm:TranslatedText">
        <xsl:value-of select="odm:Question/odm:TranslatedText"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="@Name"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="($parmdisplay = 'spec' or normalize-space($parmdisplay) = '') and odm:Alias[@Context='prompt']">
      <xsl:value-of select="odm:Alias[@Context='prompt']"/>
    </xsl:if>
    <xsl:if test="($parmdisplay = 'spec' or normalize-space($parmdisplay) = '') and odm:Alias[@Context='prompt']">
      <p class="left">
        PROMPT:
        <xsl:value-of select="odm:Alias[@Context='prompt']/@Name"/>
      </p> <!-- Prompt text for data entry -->
    </xsl:if>
    <xsl:if test="odm:Alias[@Context='completionInstructions']/@Name">
      <p class="note left" id="complete"><xsl:value-of select="odm:Alias[@Context='completionInstructions']/@Name"/></p> <!-- Completion Instructions -->
    </xsl:if>
<!--
    Description at question level contains a repeat of the CDASH Alias in all the CDISC ePortal forms
    <xsl:apply-templates select="odm:Description"/>
-->
  </xsl:template>

  <!-- Collect the data as answer to the question -->
  <xsl:template name="answer">
    <xsl:if test="$parmoids = '1' and odm:CodeListRef/@CodeListOID">
      <div id="oids" class="note">
        CodeList OID = <xsl:value-of select="odm:CodeListRef/@CodeListOID"/>
      </div>
    </xsl:if>
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
          <xsl:variable name="radioname" select="translate(../@OID, ' ', '_')"/>
          <input type="radio">
            <xsl:attribute name="name">
              <xsl:value-of select="$radioname"/>
            </xsl:attribute>
          </input>
          <label>
            <xsl:attribute name="for">
              <xsl:value-of select="$radioname"/>
            </xsl:attribute>
            <xsl:value-of select="odm:Decode/odm:TranslatedText"/>
            <xsl:if test="normalize-space(odm:Decode/odm:TranslatedText) = ''">
              <xsl:value-of select="@CodedValue"/>
            </xsl:if>
            <span class="note"> (<xsl:value-of select="@CodedValue"/>)</span>
          </label>
          <br/>
        </xsl:for-each>
        <!-- Enumerated codelists are simple radio buttons -->
        <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:CodeList/odm:EnumeratedItem[../@OID=$radio]">
          <xsl:sort select="@Rank" data-type="number"/>
          <xsl:variable name="enumname" select="translate(../@OID, ' ', '_')"/>
          <input type="radio">
            <xsl:attribute name="name">
              <xsl:value-of select="$enumname"/>
            </xsl:attribute>
          </input>
          <label>
            <xsl:attribute name="for">
              <xsl:value-of select="$enumname"/>
            </xsl:attribute>
            <span class="note"><xsl:value-of select="@CodedValue"/></span>
          </label><br/>
        </xsl:for-each>
      </xsl:when>
      <!-- Data type integer -->
      <xsl:when test="@DataType = 'integer'">
        <input type="number"/><span class="note"> Integer</span>
      </xsl:when>
      <!-- Data type float -->
      <xsl:when test="@DataType = 'float'">
        <input type="number"/><span class="note"> Floating point (<xsl:value-of select="@Length"/>.<xsl:value-of select="@SignificantDigits"/>)</span>
      </xsl:when>
      <!-- Data type date -->
      <xsl:when test="@DataType = 'date'">
        <input type="text" placeholder="DD-MMM-YYYY"/><span class="note"> Date</span>
        <p class="note left">
          Always collect dates as DD-MMM-YYYY and store dates as ISO8601 in SDTM
        </p>
      </xsl:when>
      <!-- Data type time -->
      <xsl:when test="@DataType = 'time'">
        <input type="text" placeholder="HH:MM"/><span class="note"> Time</span>
        <p class="note left">
          Always collect times as HH:MM and store times as ISO8601 in SDTM
        </p>
      </xsl:when>
      <!-- Data type text -->
      <xsl:when test="@DataType = 'text'">
        <input type="text"/><span class="note"> Text</span>
      </xsl:when>
      <!-- Data type boolean -->
      <xsl:when test="@DataType = 'boolean'">
        <xsl:variable name="boolname" select="translate(@OID, ' ', '_')"/>
        <input type="checkbox">
          <xsl:attribute name="name">
            <xsl:value-of select="$boolname"/>
          </xsl:attribute>
        </input>
        <label>
          <xsl:attribute name="for">
            <xsl:value-of select="$boolname"/>
          </xsl:attribute>
          <xsl:value-of select="odm:Question/odm:TranslatedText"/>
          <span class="note"> (<xsl:value-of select="translate(odm:Question/odm:TranslatedText, $lowercase, $uppercase)"/>) Boolean</span>
        </label><br/>
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
    <xsl:if test="odm:MeasurementUnitRef">
      <xsl:variable name="unitoid" select="odm:MeasurementUnitRef/@MeasurementUnitOID"/>
      <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:BasicDefinitions/odm:MeasurementUnit[@OID=$unitoid]">
        <xsl:variable name="unitname" select="translate(@OID, ' ', '_')"/>
        <br/>
        <input type="radio">
          <xsl:attribute name="name">
            <xsl:value-of select="$unitname"/>
          </xsl:attribute>
        </input>
        <label>
          <xsl:attribute name="for">
            <xsl:value-of select="$unitname"/>
          </xsl:attribute>
          <span class="note">Unit
            (<xsl:value-of select="odm:Symbol/odm:TranslatedText"/>)
          </span>
        </label>
      </xsl:for-each>
    </xsl:if>
    <xsl:if test="($parmdisplay = 'spec' or normalize-space($parmdisplay) = '') and $parmcdash = '1' and odm:Alias[@Context='CDASH']">
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

    <!-- Dataset and Variable -->
    <xsl:choose>
      <!-- Dataset and variable are each in Domain and SDSVarname -->
      <xsl:when test="normalize-space($domain) != '' and normalize-space(@SDSVarName) != ''">
        <!-- Anchor for domain.variable -->
        <xsl:call-template name="define_anchor">
          <xsl:with-param name="target" select="concat($domain, '.', @SDSVarName)"/>
        </xsl:call-template>
        <!-- Anchor for variable alone -->
        <xsl:call-template name="define_anchor">
          <xsl:with-param name="target" select="@SDSVarName"/>
        </xsl:call-template>
        <xsl:value-of select="$domain"/>
        <xsl:text>.</xsl:text>
        <xsl:value-of select="@SDSVarName"/>
        <xsl:if test="odm:Alias[@Context='SDTM']/@Name">
          <xsl:text>,</xsl:text>
          <br/>
        </xsl:if>
      </xsl:when>
      <!-- Dataset and Variable are both in SDSVarname separated by a period -->
      <xsl:when test="normalize-space(@SDSVarName) != '' and contains(substring(@SDSVarName, 1, 9), '.')">
        <!-- Anchor for variable contents -->
        <xsl:call-template name="define_anchor">
          <xsl:with-param name="target" select="@SDSVarName"/>
        </xsl:call-template>
        <xsl:value-of select="@SDSVarName"/>
        <xsl:if test="odm:Alias[@Context='SDTM']/@Name">
          <xsl:text>,</xsl:text>
          <br/>
        </xsl:if>
      </xsl:when>
        <!-- No dataset or variable specified, annotation expected in Alias only -->
      <xsl:otherwise/>
    </xsl:choose>

    <!-- Additional annotations beyond Dataset and Variable -->
    <xsl:choose>
      <!-- Variable with an optional Dataset prefix are in Alias -->
      <xsl:when test="contains(odm:Alias[@Context='SDTM']/@Name, ',') and
                      not(contains(substring-before(odm:Alias[@Context='SDTM']/@Name, ','), '=')) and
                      not(contains(substring-before(odm:Alias[@Context='SDTM']/@Name, ','), ' '))">
        <xsl:call-template name="define_anchor">
          <xsl:with-param name="target" select="substring-before(odm:Alias[@Context='SDTM']/@Name, ',')"/>
        </xsl:call-template>
        <xsl:value-of select="substring-before(odm:Alias[@Context='SDTM']/@Name, ',')"/>
        <xsl:text>,</xsl:text>
        <br/>
        <xsl:call-template name="annotation_text">
          <xsl:with-param name="text_line" select="substring-after(odm:Alias[@Context='SDTM']/@Name, ',')"/>
        </xsl:call-template>
      </xsl:when>
      <!-- Alias contains only additional annotations -->
      <xsl:when test="contains(odm:Alias[@Context='SDTM']/@Name, ',') or contains(odm:Alias[@Context='SDTM']/@Name, ' ')">
        <xsl:call-template name="annotation_text">
          <xsl:with-param name="text_line" select="odm:Alias[@Context='SDTM']/@Name"/>
        </xsl:call-template>
      </xsl:when>
      <!-- Alias contains only a Variable, with an optional Dataset prefix -->
      <xsl:otherwise>
        <xsl:call-template name="define_anchor">
          <xsl:with-param name="target" select="odm:Alias[@Context='SDTM']/@Name"/>
        </xsl:call-template>
        <xsl:call-template name="inline_anchor">
          <xsl:with-param name="inline" select="odm:Alias[@Context='SDTM']/@Name"/>
        </xsl:call-template>
        <xsl:value-of select="odm:Alias[@Context='SDTM']/@Name"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Link target for each word of text and splitting of lines -->
  <xsl:template name="annotation_text">
    <xsl:param name="text_line"/>
    <xsl:call-template name="anchor_words">
      <xsl:with-param name="text_string" select='translate($text_line, ",.=:-_ &apos;", "¤¤¤¤¤¤¤¤")'/>
    </xsl:call-template>
    <xsl:call-template name="break_lines">
      <xsl:with-param name="lines" select="normalize-space($text_line)"/>
    </xsl:call-template>
  </xsl:template>

  <!-- PDF anchor for define.xml. Also create a link to the target to preserve the target -->
  <xsl:template name="define_anchor">
    <xsl:param name="target"/>
    <xsl:if test="$target != '' and not(contains($target, ' '))">
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
    </xsl:if>
  </xsl:template>

  <!-- Replace occurences of '. ' (period blank) with HTML line break -->
  <xsl:template name="break_lines">
    <xsl:param name="lines"/>
    <xsl:choose>
      <xsl:when test="$lines = ''">
        <!-- Prevent this routine from hanging -->
        <xsl:value-of select="$lines"/>
      </xsl:when>
      <!-- Do not split lines when '. ' (period blank) occurs inside single quotes (abbreviations) -->
      <xsl:when test='contains($lines, ". ") and ((string-length(substring-before($lines, ". ")) - string-length(translate(substring-before($lines, ". "), "&apos;", ""))) mod 2 = 0 or not(contains($lines, "&apos;")))'>
        <xsl:call-template name="inline_anchor">
          <xsl:with-param name="inline" select="substring-before($lines, '. ')"/>
        </xsl:call-template>
        <xsl:value-of select="substring-before($lines, '. ')"/>.
        <br/>
        <xsl:call-template name="break_lines">
          <xsl:with-param name="lines" select="substring-after($lines, '. ')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test='contains($lines, ". ")'>
        <xsl:call-template name="inline_anchor">
          <xsl:with-param name="inline" select="$lines"/>
        </xsl:call-template>
        <xsl:value-of select="$lines"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="inline_anchor">
          <xsl:with-param name="inline" select="$lines"/>
        </xsl:call-template>
        <xsl:value-of select="$lines"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Split a string into words -->
  <xsl:template name="anchor_words">
    <xsl:param name="text_string" select="''"/>
    <xsl:param name="separator" select="'¤'"/>
    <xsl:if test="not($text_string = '' or $separator = '')">
      <xsl:variable name="head" select="substring-before(concat($text_string, $separator), $separator)"/>
      <xsl:variable name="tail" select="substring-after($text_string, $separator)"/>
      <xsl:call-template name="define_anchor">
        <xsl:with-param name="target" select="$head"/>
      </xsl:call-template>
      <xsl:call-template name="anchor_words">
        <xsl:with-param name="text_string" select="$tail"/>
        <xsl:with-param name="separator" select="$separator"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Identify in-text Dataset.Variable constructs and create them a target -->
  <xsl:template name="inline_anchor">
    <xsl:param name="inline" select="''"/>
    <xsl:if test="normalize-space($inline) != ''">
      <xsl:if test="contains($inline, ',')">
        <xsl:call-template name="inline_anchor">
          <xsl:with-param name="inline" select="substring-after($inline, ',')"/>
        </xsl:call-template>
      </xsl:if>
      <xsl:if test="contains(substring-before($inline, '='), '.')">
        <xsl:call-template name="define_anchor">
          <xsl:with-param name="target" select="normalize-space(substring-before($inline, '='))"/>
        </xsl:call-template>
        <xsl:if test="contains(substring-after($inline, '='), '.') and not(contains(substring-after($inline, '='), ' ')) and not(contains(substring-after($inline, '='), ','))">
          <xsl:call-template name="define_anchor">
            <xsl:with-param name="target" select="normalize-space(substring-after($inline, '='))"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- Show implementation notes for each question identified by the question reference number -->
  <xsl:template name="question_notes">
    <!-- Collect an indicator for each question implementation note for this form -->
    <xsl:if test="$parmdisplay = 'spec' or normalize-space($parmdisplay) = ''">
      <xsl:variable name="qnotes">
        <xsl:for-each select="odm:ItemGroupRef">
          <xsl:variable name="groupkey1" select="@ItemGroupOID"/>
          <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:ItemGroupDef[@OID=$groupkey1]">
            <xsl:for-each select="odm:ItemRef">
              <xsl:variable name="itemkey1" select="@ItemOID"/>
              <xsl:if test="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:ItemDef[@OID=$itemkey1]/odm:Alias[@Context='implementationNotes']/@Name"> <!-- Implementation Notes -->
                Implementation note
              </xsl:if>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:variable>

      <!-- Question implementation note(s), if any -->
      <xsl:if test="normalize-space($qnotes) != ''">
        <p/>
        <table class="desw" id="implement">
          <thead>
            <tr><th class="left" colspan="2">Question implementation note(s)</th></tr>
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

  <!-- Form implementation note, if any. Candidate for deletion -->
  <xsl:template name="form_notes">
    <xsl:if test="($parmdisplay = 'spec' or normalize-space($parmdisplay) = '') and
                    normalize-space(odm:Alias[@Context='implementationNotes']/@Name) != ''"> <!-- Implementation Notes -->
      <p/>
      <table class="desw" id="implement">
        <thead>
          <tr><th class="left">Form implementation note</th></tr>
        </thead>
        <tbody>
          <tr><td class="note"><xsl:value-of select="odm:Alias[@Context='implementationNotes']/@Name"/></td></tr> <!-- Implementation Notes -->
        </tbody>
      </table>
    </xsl:if>
    <xsl:call-template name="question_notes"/>
  </xsl:template>
</xsl:stylesheet>
