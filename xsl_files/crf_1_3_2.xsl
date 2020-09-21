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
          html         { margin:  10px 10px 10px 10px; }
          *            { font-family: Arial, Helvetica, sans-serif !important; }
          h1,h2,h3,p   { text-align: center; }
          .noprint     { position: fixed; bottom: 10px; right: 10px; }
          @media print { .noprint { display: none; } }
          .maintable   { border:        1px solid DarkGrey; padding: 5; border-spacing: 0; width: 100%; border-collapse: collapse; }
          .maincell    { border-left:   1px solid DarkGrey;
                         border-right:  1px solid DarkGrey;
                         border-top:    1px solid DarkGrey;
                         border-bottom: 1px solid DarkGrey; }
          .crfhead     { background-color: Gainsboro; }
          .formname    { text-align: left; }
          .anno        { background-color: LightYellow; }
          .note        { font-style: italic; }
          .seqw        { width: 5em; }
          .quew        { width: 30%; }
          .answ        { width: 25%; }
          .annw        { width: 40%; }
        </style>
        <script>
          <!-- Repeat from HTML, if this file ever becomes stand-alone-->
          function hide(elements) {
            for (var element of elements) {
              element.style.visibility = (element.style.visibility == 'collapse') ? 'visible' : 'collapse';
            }
          }
        </script>
      </head>
      <body>
        <!-- Non printable buttons -->
        <table class="noprint"><tr>
          <td><button onClick="hide(document.querySelectorAll('[id=anno]'))">Annotations Off and On</button></td>
          <td><button onClick="hide(document.querySelectorAll('[id=internal]'))">Internal notes Off and On</button></td>
          <td><button onClick="document.documentElement.scrollTop = 0">Scroll to the top</button></td>
        </tr></table>

        <!-- Title page -->
        <h1>CRF Specification for <xsl:value-of select="$studyname"/></h1>
        <p><xsl:value-of select="/odm:ODM/odm:Study[1]/odm:GlobalVariables/odm:StudyDescription"/></p>
        <xsl:if test="$studyname != $protocolname">
          <h2>Protocol Name: <xsl:value-of select="$protocolname"/></h2>
        </xsl:if>
        <p><xsl:value-of select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:Protocol/odm:Description/odm:TranslatedText"/></p>
        <xsl:if test="$created != ''">
          <p>CRF Creation date: <xsl:value-of select="$created"/></p>
        </xsl:if>
        <xsl:if test="$changed != ''">
          <p>CRF valid from date: <xsl:value-of select="$changed"/></p>
        </xsl:if>
        <p style="page-break-after: always"></p>

        <!-- Toc -->
        <h3>Table of Contents</h3>
        <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:FormDef">
          <p><a><xsl:attribute name="href">#<xsl:value-of select="@OID"/></xsl:attribute><span><xsl:value-of select="@Name"/></span></a></p>
        </xsl:for-each>
        <p style="page-break-after: always"></p>

        <!-- One table per form becomes one form per page -->
        <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:FormDef">
          <xsl:sort select="odm:ItemGroupRef/@OrderNumber" data-type="number"/>
          <xsl:variable name="form"  select="@OID"/>
          <table id= "maintable" class="maintable">
            <thead class="crfhead">
              <tr>
                <th class="maincell formname" colspan="3">
                  <a>
                    <xsl:attribute name="id">
                      <xsl:value-of select="@OID"/>
                    </xsl:attribute>
                    <xsl:value-of select="@Name"/>
                    <xsl:if test="normalize-space(odm:Alias/@Name) != ''">
                      <br/><div id="internal" class="note"><xsl:value-of select="odm:Alias/@Name"/></div>
                    </xsl:if>
                  </a>
                </th>
                <th id="anno" class="maincell">SDTM Annotation</th>
              </tr>
            </thead>
            <tbody>
              <xsl:for-each select="odm:ItemGroupRef">
                <xsl:variable name="group" select="@ItemGroupOID"/>
                <xsl:variable name="gnum"  select="@OrderNumber"/>
                <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:ItemGroupDef[@OID=$group]">
                  <xsl:for-each select="odm:ItemRef">
                    <xsl:sort select="@OrderNumber" data-type="number"/>
                    <xsl:variable name="item" select="@ItemOID"/>
                    <xsl:variable name="inum" select="@OrderNumber"/>
                    <xsl:for-each select="/odm:ODM/odm:Study[1]/odm:MetaDataVersion[1]/odm:ItemDef[@OID=$item]">
                      <tr>
                        <td class="maincell seqw"><xsl:value-of select="$gnum"/>.<xsl:value-of select="$inum"/></td>
                        <td class="maincell quew"><xsl:value-of select="odm:Question/odm:TranslatedText"/><br/>
                                <div class="note"><xsl:value-of select="odm:Description/odm:TranslatedText"/></div></td>
                        <td class="maincell answ">
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
                        <td id="anno" class="maincell annw anno">
                          <xsl:choose>
                            <xsl:when test="normalize-space(odm:Alias/@Name)='' and normalize-space(@SDSVarName)=''">
                            </xsl:when>
                            <xsl:when test="normalize-space(odm:Alias/@Name)=''">
                              <xsl:value-of select="@SDSVarName"/>
                            </xsl:when>
                            <xsl:when test="normalize-space(@SDSVarName)=''">
                              <xsl:value-of select="odm:Alias/@Name"/>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="@SDSVarName"/>,<br/><xsl:value-of select="odm:Alias/@Name"/>
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
          <p style="page-break-after: always"></p>
        </xsl:for-each>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
