<?xml version="1.0" encoding="UTF-8"?>
<!--
  Copyright (c) 2020 Jørgen Mangor Iversen

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

  <!-- Special characters in a variables for enhanced readability -->
  <xsl:variable name="checkmark"    select="'&#10004;'"/>
  <xsl:variable name="infinity"     select="'&#8734;'"/>

  <xsl:variable name="studyname"    select="/odm:ODM/odm:Study[1]/odm:GlobalVariables/odm:StudyName"/>
  <xsl:variable name="protocolname" select="/odm:ODM/odm:Study[1]/odm:GlobalVariables/odm:ProtocolName"/>
  <xsl:variable name="created"      select="/odm:ODM/@CreationDateTime"/>
  <xsl:variable name="changed"      select="/odm:ODM/@AsOfDateTime"/>

  <xsl:template match="/">
    <html>
      <head>
        <title>CRF Specification <xsl:value-of select="$studyname"/></title>
        <meta http-equiv="Content-Type"    content="text/html;charset=utf-8"/>
        <meta http-equiv="X-UA-Compatible" content="IE=9"/>
        <meta http-equiv="cache-control"   content="no-cache"/>
        <meta http-equiv="pragma"          content="no-cache"/>
        <meta http-equiv="expires"         content="0"/>
        <meta name="Author"                content="Jørgen Mangor Iversen"/>
        <style>
          html            { margin:  1em 1em 1em 1em; }
          *               { font-family: Arial, Helvetica, sans-serif !important; }
          h1,h2,h3,p      { text-align: center; }
          table           { solid DarkGrey; padding: 1em; border-spacing: 0; border-collapse: collapse; }
          table.rotate    { border: 1px; box-sizing: border-box; }
          th,td           { border-left:   1px solid DarkGrey;
                            border-right:  1px solid DarkGrey;
                            border-top:    1px solid DarkGrey;
                            border-bottom: 1px solid DarkGrey; }
          @media print    { .noprint { display: none; } }
          .noprint        { position: fixed; bottom: 0.5em; right: 0.5em; z-index: 99; }
          .rotate tr,
          .rotate td,
          .rotate th      { position: relative; padding: 0.2em; }
          .rotate th span { transform-origin: 0 50%; white-space: nowrap; display: block; position: absolute; bottom: 0; left: 50%;
                            transform:         rotate(-90.0deg);
                            -moz-transform:    rotate(-90.0deg);
                            -o-transform:      rotate(-90.0deg);
                            -webkit-transform: rotate(-90.0deg); }
          .height         { height:15em; vertical-align:bottom; } <!-- Adjust this height value if vertical visit names don't fit the visit matrix table headers -->
          .noborder       { border: none; }
          .matrix         { text-align: center; }
          .check          { color: DarkGreen; }
          .maintable      { border: 1px; width: 100%; }
          .crfhead        { background-color: Gainsboro; }
          .formname       { text-align: left; }
          .anno           { background-color: LightYellow; }
          .note           { font-style: italic; }
          .seqw           { width: 5em; }
          .quew           { width: 30%; }
          .answ           { width: 25%; }
          .annw           { width: 40%; }
        </style>
      </head>
      <body>
        <!-- Non printable buttons -->
        <table class="noprint">
          <tr>
            <!-- Turn elements off and on. In-line JavaScript as SCRIPT sections will not execute and onload() will not fire, probably because the document never finishes loading when created by document.documentElement.appendChild() -->
            <td class="noborder">
              <button onClick="for(var element of document.querySelectorAll('[id=anno]'))     element.style.visibility = (element.style.visibility == 'collapse') ? 'visible' : 'collapse';">
                Annotations Off and On
              </button>
            </td>
            <td class="noborder">
              <button onClick="for(var element of document.querySelectorAll('[id=internal]')) element.style.visibility = (element.style.visibility == 'collapse') ? 'visible' : 'collapse';">
                Internal notes Off and On
              </button>
            </td>
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
        <p style="page-break-after: always"/>

        <!-- Toc -->
        <h3>Table of Contents</h3>
        <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:FormDef">
          <p><a><xsl:attribute name="href">#<xsl:value-of select="@OID"/></xsl:attribute><span><xsl:value-of select="@Name"/></span></a></p>
        </xsl:for-each>
        <p style="page-break-after: always"/>

        <!-- Vist Matrix -->
        <xsl:if test="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:StudyEventDef">
          <h3>Visit Matrix</h3>
          <table class="rotate">
            <thead>
              <tr>
                <th class="formname crfhead">Visit Number</th>
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
                <th id="anno" class="anno">TV.VISITNUM</th>
              </tr>
              <tr>
                <th class="formname height crfhead">Event/<br/>Form</th>
                <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:Protocol/odm:StudyEventRef">
                  <xsl:sort select="@OrderNumber" data-type="number"/>
                  <xsl:variable name="visithead" select="@StudyEventOID"/>
                  <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:StudyEventDef[@OID=$visithead]">
                    <th class="crfhead"><span><xsl:value-of select="@Name"/></span></th>
                  </xsl:for-each>
                </xsl:for-each>
                <th id="anno" class="anno">TV.VISIT</th>
              </tr>
              <tr>
                <th class="formname crfhead">Mandatory visit</th>
                <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:Protocol/odm:StudyEventRef">
                  <xsl:sort select="@OrderNumber" data-type="number"/>
                  <th class="crfhead"><xsl:value-of select="@Mandatory"/></th>
                </xsl:for-each>
                <td id="anno" class="anno">NOT SUBMITTED</td>
              </tr>
            </thead>
            <tbody>
              <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:FormDef">
                <xsl:sort select="odm:ItemGroupRef/@OrderNumber" data-type="number"/>
                <xsl:variable name="formrow" select="@OID"/>
                <tr>
                  <td>
                    <xsl:value-of select="@Name"/>
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
                  <td id="anno" class="anno">NOT SUBMITTED</td>
                </tr>
              </xsl:for-each>
            </tbody>
          </table>
        <p style="page-break-after: always"/>
        </xsl:if>

        <!-- One table per form becomes one form per page -->
        <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:FormDef">
          <xsl:sort select="odm:ItemGroupRef/@OrderNumber" data-type="number"/>
          <xsl:variable name="form" select="@OID"/>
          <table class="maintable">
            <thead>
              <tr>
                <th class="formname crfhead" colspan="3">
                  <a>
                    <xsl:attribute name="id">
                      <xsl:value-of select="@OID"/>
                    </xsl:attribute>
                    <xsl:value-of select="@Name"/>
                   </a>
                   <xsl:if test="normalize-space(@Repeating) = 'Yes'">
                     [Repeating form]
                   </xsl:if>
                   <xsl:if test="normalize-space(odm:Alias/@Name) != ''">
                    <br/><div id="internal" class="note"><xsl:value-of select="odm:Alias/@Name"/></div>
                  </xsl:if>
                </th>
                <th id="anno" class="crfhead annw">SDTM Annotations</th>
              </tr>
            </thead>
            <tbody>
              <xsl:for-each select="odm:ItemGroupRef">
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
                        <td class="seqw"><xsl:value-of select="$gnum"/>.<xsl:value-of select="$inum"/></td>
                        <td class="quew"><xsl:value-of select="odm:Question/odm:TranslatedText"/><br/>
                                <div class="note"><xsl:value-of select="odm:Description/odm:TranslatedText"/></div></td>
                        <td class="answ">
                          <xsl:choose>
                            <xsl:when test="contains(odm:Question/odm:TranslatedText,    'all that apply') or
                                            contains(odm:Description/odm:TranslatedText, 'all that apply')">
                              <xsl:variable name="check" select="odm:CodeListRef/@CodeListOID"/>
                              <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:CodeList/odm:CodeListItem[../@OID=$check]">
                                <input type="checkbox" name="$check"/><label for="$check"><xsl:value-of select="odm:Decode/odm:TranslatedText"/></label><br/>
                            </xsl:for-each>
                            </xsl:when>
                            <xsl:when test="normalize-space(odm:CodeListRef/@CodeListOID) != ''">
                              <xsl:variable name="radio" select="odm:CodeListRef/@CodeListOID"/>
                              <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:CodeList/odm:CodeListItem[../@OID=$radio]">
                                <input type="radio" name="$radio"/><label for="$radio"><xsl:value-of select="odm:Decode/odm:TranslatedText"/></label><br/>
                              </xsl:for-each>
                            </xsl:when>
                            <xsl:when test="@DataType = 'integer'">
                              <input type="number"/>
                            </xsl:when>
                            <xsl:when test="@DataType = 'float'">
                              <input type="number"/>
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
                        <td id="anno" class="annw anno">
                          <xsl:choose>
                            <xsl:when test="normalize-space(odm:Alias/@Name) = '' and normalize-space(@SDSVarName) = ''">
                            </xsl:when>
                            <xsl:when test="normalize-space(odm:Alias/@Name)=''">
                              <xsl:value-of select="$domain"/>.<xsl:value-of select="@SDSVarName"/>
                            </xsl:when>
                            <xsl:when test="normalize-space(@SDSVarName) = ''">
                              <xsl:value-of select="odm:Alias/@Name"/>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="$domain"/>.<xsl:value-of select="@SDSVarName"/>,<br/><xsl:value-of select="odm:Alias/@Name"/>
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
