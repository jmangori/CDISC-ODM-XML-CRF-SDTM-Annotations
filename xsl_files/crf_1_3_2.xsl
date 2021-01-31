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

  <!-- Parameters to be passed from outside -->
  <xsl:param name="parmanno"/>
  <xsl:param name="parmname"/>
  <xsl:param name="parmlogo"/> <!-- Base 64 data string -->
  <xsl:param name="parmstudy"/>
  <xsl:param name="parmsite"/>
  <xsl:param name="parminv"/>
  <xsl:param name="parmsubject"/>
  <xsl:param name="parminit"/>
  <xsl:param name="parmvisit"/>

  <!-- Special characters in a variables for enhanced readability -->
  <xsl:variable name="checkmark"    select="'&#10004;'"/>
  <xsl:variable name="infinity"      select="'&#8734;'"/>
  <xsl:variable name="spacechar"    select="' '"/>

  <xsl:variable name="studyname"    select="/odm:ODM/odm:Study[1]/odm:GlobalVariables/odm:StudyName"/>
  <xsl:variable name="protocolname" select="/odm:ODM/odm:Study[1]/odm:GlobalVariables/odm:ProtocolName"/>
  <xsl:variable name="created"      select="/odm:ODM/@CreationDateTime"/>
  <xsl:variable name="changed"      select="/odm:ODM/@AsOfDateTime"/>

  <xsl:template match="/">
    <html>
      <head>
        <title>CRF Specification</title>
        <meta http-equiv="Content-Type"    content="text/html;charset=utf-8"/>
        <meta http-equiv="X-UA-Compatible" content="IE=9"/>
        <meta http-equiv="cache-control"   content="no-cache"/>
        <meta http-equiv="pragma"          content="no-cache"/>
        <meta http-equiv="expires"         content="0"/>
        <meta name="Author"                content="Jørgen Mangor Iversen"/>
        <style>
          html          { margin:  1em 1em 1em 1em; }
          *             { font-family: Helvetica, Arial, sans-serif !important; }
          h1, h2, p     { text-align: center; }
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
          .noborder     { border: none; }
          .nolrborder   { border-left: none; border-right: none; }
          .nolborder    { border-left: none; }
          .norborder    { border-right: none; }
          @media print  { .noprint { display: none; } }
          .noprint      { position: fixed; bottom: 0.5em; right: 0.5em; z-index: 99; }
          .rotate span  { writing-mode: vertical-rl; transform: rotate(180deg); padding: 0.2em; }
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
          .small        { font-size: 0.7em; }
          .even         { width: 20em; text-align: left; }
          .seqw         { width: 5em; }
        <xsl:if test="$parmanno = 'acrf'">
          .anno         { background-color: LightYellow; }
          .insw         { width: 25%; }
          .quew         { width: 25%; }
          .answ         { width: 20%; }
          .annw         { width: 25%; }
        </xsl:if>
        <xsl:if test="$parmanno = 'bcrf'">
          .anno         { visibility: hidden; display: none; }
          .insw         { width: 30%; }
          .quew         { width: 30%; }
          .answ         { width: 35%; }
          .annw         { width: 0; }
        </xsl:if>
        </style>
      </head>
      <body>
        <!-- Non printable buttons -->
        <table class="noprint">
          <tr>
            <xsl:if test="$parmanno = 'acrf'">
              <!-- Turn elements off and on. In-line JavaScript as SCRIPT sections will not execute and onload() will not fire, probably because the document never finishes loading when created by appendChild() -->
              <td class="noborder">
                <button onClick="for(var element of document.querySelectorAll('[id=anno]')) element.style.visibility = (element.style.visibility == 'collapse') ? 'visible' : 'collapse';">
                  Annotations Off and On
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

        <!-- Title page -->
        <h1>CRF Specification for <xsl:value-of select="$studyname"/></h1>
        <p><xsl:value-of select="/odm:ODM/odm:Study[1]/odm:GlobalVariables/odm:StudyDescription"/></p>
        <xsl:if test="$studyname != $protocolname">
          <h2>Protocol Name: <xsl:value-of select="$protocolname"/></h2>
        </xsl:if>
        <xsl:if test="$created != ''">
          <p>CRF Creation date: <xsl:value-of select="$created"/></p>
        </xsl:if>
        <xsl:if test="$changed != ''">
          <p>CRF valid from date: <xsl:value-of select="$changed"/></p>
        </xsl:if>
        <xsl:if test="$parmlogo != ''">
          <p>
            <img alt="Company Logo" title="Company Logo">
              <xsl:attribute name="src">
                data:image/png;base64,<xsl:value-of select="$parmlogo"/>
              </xsl:attribute>
            </img>
          </p>
        </xsl:if>
        <xsl:if test="$parmname != ''">
          <p><xsl:value-of select="$parmname"/></p>
        </xsl:if>
        <p style="page-break-after: always"/>

        <!-- Toc -->
        <h2>Table of Contents</h2>
        <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:FormDef">
          <xsl:sort select="@Name" data-type="text"/>
          <p>
            <a>
              <xsl:attribute name="href">#<xsl:value-of select="@OID"/></xsl:attribute>
              <span>
                <xsl:value-of select="@Name"/>
              </span>
            </a>
          </p>
        </xsl:for-each>
        <p style="page-break-after: always"/>

        <!-- Vist Matrix -->
        <xsl:if test="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:StudyEventDef">
          <h2>Visit Matrix</h2>
          <table class="center">
            <thead>
              <tr>
                <th class="left crfhead">Visit Number</th>
                <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:Protocol/odm:StudyEventRef">
                  <xsl:sort select="@OrderNumber" data-type="number"/>
                  <xsl:variable name="numhead" select="@StudyEventOID"/>
                  <xsl:variable name="visitnum" select="@OrderNumber"/>
                  <th class="crfhead">
                    <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:StudyEventDef[@OID=$numhead]">
                      <xsl:if test="@Type = 'Scheduled'">
                        <xsl:value-of select="$visitnum"/>
                      </xsl:if>
                    </xsl:for-each>
                  </th>
                </xsl:for-each>
                <th id="anno" class="anno noborder">TV.VISITNUM</th>
              </tr>
              <tr>
                <th class="left crfhead">Event/<br/>Form</th>
                <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:Protocol/odm:StudyEventRef">
                  <xsl:sort select="@OrderNumber" data-type="number"/>
                  <xsl:variable name="visithead" select="@StudyEventOID"/>
                  <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:StudyEventDef[@OID=$visithead]">
                    <th class="crfhead rotate"><span><xsl:value-of select="@Name"/></span></th>
                  </xsl:for-each>
                </xsl:for-each>
                <th id="anno" class="anno noborder">TV.VISIT</th>
              </tr>
              <tr>
                <th class="left crfhead">Mandatory visit</th>
                <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:Protocol/odm:StudyEventRef">
                  <xsl:sort select="@OrderNumber" data-type="number"/>
                  <th class="crfhead"><xsl:value-of select="@Mandatory"/></th>
                </xsl:for-each>
                <td id="anno" class="anno noborder">NOT SUBMITTED</td>
              </tr>
            </thead>
            <tbody>
              <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:FormDef">
                <xsl:sort select="@Name" data-type="text"/>
                <xsl:variable name="formrow" select="@OID"/>
                <tr>
                  <td>
                    <a>
                      <xsl:attribute name="href">#<xsl:value-of select="@OID"/></xsl:attribute>
                      <span>
                        <xsl:value-of select="@Name"/>
                      </span>
                    </a>
                    <xsl:if test="@Repeating = 'Yes'">
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
                  <td id="anno" class="anno noborder">NOT SUBMITTED</td>
                </tr>
              </xsl:for-each>
            </tbody>
          </table>
          <p style="page-break-after: always"/>
        </xsl:if>

        <!-- One table per form becomes one form per page -->
        <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:FormDef">
          <xsl:sort select="@Name" data-type="text"/>
          <xsl:sort select="@Name" data-type="text"/>
          <xsl:variable name="form" select="@OID"/>
          <table class="maintable">
            <thead>
              <tr>
                <th class="noborder" colspan="5">
                  <table class="maintable">
                    <tr>
                      <xsl:if test="$parmname != '' or $parmlogo != ''">
                        <td class="plain small insw" rowspan="2">
                          <xsl:if test="$parmname != ''">
                            <xsl:value-of select="$parmname"/><br/>
                          </xsl:if>
                          <xsl:if test="$parmlogo != ''">
                            <img alt="Company Logo" title="Company Logo">
                              <xsl:attribute name="src">
                                data:image/png;base64,<xsl:value-of select="$parmlogo"/>
                              </xsl:attribute>
                            </img>
                          </xsl:if>
                        </td>
                      </xsl:if>
                      <xsl:if test="$parmstudy != ''">
                        <td class="plain small left even norborder">Study/Trial:</td>
                        <td class="plain small left even nolrborder">
                          <input type="text" size="4">
                            <xsl:attribute name="value">
                              <xsl:value-of select="$studyname"/>
                            </xsl:attribute>
                            <xsl:attribute name="disabled">
                              true
                            </xsl:attribute>
                          </input>
                        </td>
                        <td class="plain small left even nolborder"><div id="anno" class="anno"><xsl:value-of select="$parmstudy"/></div></td>
                      </xsl:if>
                      <xsl:if test="$parmsubject != ''">
                        <td class="plain small left even norborder">Subject Number:</td>
                        <td class="plain small left even nolrborder"><input type="text" size="4"/></td>
                        <td class="plain small left even nolborder"><div id="anno" class="anno"><xsl:value-of select="$parmsubject"/></div></td>
                      </xsl:if>
                    </tr>
                    <tr>
                      <xsl:if test="$parmsite != ''">
                        <td class="plain small left even norborder">Site Number:</td>
                        <td class="plain small left even nolrborder"><input type="text" size="4"/></td>
                        <td class="plain small left even nolborder"><div id="anno" class="anno"><xsl:value-of select="$parmsite"/></div></td>
                      </xsl:if>
                      <xsl:if test="$parminit != ''">
                        <td class="plain small left even norborder">Subject Initials:</td>
                        <td class="plain small left even nolrborder"><input type="text" size="4"/></td>
                        <td class="plain small left even nolborder"><div id="anno" class="anno"><xsl:value-of select="$parminit"/></div></td>
                      </xsl:if>
                    </tr>
                    <tr>
                      <td class="plain small insw">Protocol: <xsl:value-of select="$protocolname"/></td>
                      <xsl:if test="$parminv != ''">
                        <td class="plain small left even norborder">Investigator:</td>
                        <td class="plain small left even nolrborder"><input type="text" size="4"/></td>
                        <td class="plain small left even nolborder"><div id="anno" class="anno"><xsl:value-of select="$parminv"/></div></td>
                      </xsl:if>
                      <xsl:if test="$parmvisit != ''">
                        <td class="plain small left even norborder">Visit:</td>
                        <td class="plain small left even nolrborder"><input type="text" size="4"/></td>
                        <td class="plain small left even nolborder"><div id="anno" class="anno"><xsl:value-of select="$parmvisit"/></div></td>
                      </xsl:if>
                    </tr>
                  </table>
                </th>
              </tr>
              <tr><th colspan="5" class="noborder"><br/></th></tr>
              <tr>
                <th colspan="5" class="noborder">
                  <div class="left formtitle">
                    <a class="nohover">
                      <xsl:attribute name="id">
                        <xsl:value-of select="@OID"/>
                      </xsl:attribute>
                      <xsl:value-of select="@Name"/>
                    </a>
                    <xsl:if test="normalize-space(@Repeating) = 'Yes'">
                      [Repeating form]
                    </xsl:if>
                  </div>
                </th>
              </tr>
              <tr>
                <th colspan="5" class="noborder">
                  <xsl:if test="normalize-space(odm:Description/odm:TranslatedText) != ''">
                    <p class="note left">
                      <strong>CRF instructions:</strong>
                      <xsl:value-of select="$spacechar"/>
                      <xsl:value-of select="odm:Description/odm:TranslatedText"/>
                    </p>
                  </xsl:if>
                </th>
              </tr>
              <tr><th colspan="5" class="noborder"><br/></th></tr>
            </thead>
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
                        <td class="insw noborder">
                          <div class="note"><xsl:value-of select="odm:Description/odm:TranslatedText"/></div>
                        </td>
                        <td class="seqw">
                          <xsl:value-of select="$gnum"/>.<xsl:value-of select="$inum"/>
                        </td>
                        <td class="quew">
                          <xsl:value-of select="odm:Question/odm:TranslatedText"/>
                        </td>
                        <td class="answ">
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
                                <input type="radio" name="$radio"/><label for="$radio"><xsl:value-of select="odm:Decode/odm:TranslatedText"/><span class="note"> (<xsl:value-of select="@CodedValue"/>)</span></label><br/>
                              </xsl:for-each>
                              <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:CodeList/odm:EnumeratedItem[../@OID=$radio]">
                                <xsl:sort select="@OrderNumber" data-type="number"/>
                                <input type="radio" name="$radio"/><label for="$radio"><xsl:value-of select="@CodedValue"/></label><br/>
                              </xsl:for-each>
                            </xsl:when>
                            <xsl:when test="@DataType = 'integer'">
                              <input type="number"/>
                            </xsl:when>
                            <xsl:when test="@DataType = 'float'">
                              <input type="number"/>
                            </xsl:when>
                            <xsl:when test="@DataType = 'date'">
                              <input type="date"/>
                              <p class="note left">
                                The displayed date is formatted based on the locale of the user's browser. Always collect dates as YYYY-MM-DD.
                              </p>
                            </xsl:when>
                            <xsl:when test="@DataType = 'time'">
                              <input type="time"/>
                              <p class="note left">
                                The displayed time is formatted based on the locale of the user's browser
                              </p>
                            </xsl:when>
                            <xsl:otherwise>
                              <input>
                                <xsl:attribute name="type">
                                  <xsl:value-of select="@DataType"/>
                                </xsl:attribute>
                              </input>
                            </xsl:otherwise>
                          </xsl:choose>
                        </td>
                        <td id="anno" class="annw anno noborder">
                          <xsl:choose>
                            <xsl:when test="normalize-space(odm:Alias[@Context='SDTM']/@Name) = '' and normalize-space(@SDSVarName) = ''">
                            </xsl:when>
                            <xsl:when test="normalize-space(odm:Alias[@Context='SDTM']/@Name)=''">
                              <xsl:value-of select="$domain"/>.<xsl:value-of select="@SDSVarName"/>
                            </xsl:when>
                            <xsl:when test="normalize-space(@SDSVarName) = ''">
                              <xsl:value-of select="odm:Alias[@Context='SDTM']/@Name"/>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="$domain"/>.<xsl:value-of select="@SDSVarName"/>,<br/><xsl:value-of select="odm:Alias[@Context='SDTM']/@Name"/>
                            </xsl:otherwise>
                          </xsl:choose>
                        </td>
                      </tr>
                    </xsl:for-each>
                  </xsl:for-each>
                </xsl:for-each>
              </xsl:for-each>
            </tbody>
          </table>

          <p style="page-break-after: always"/>
        </xsl:for-each>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
