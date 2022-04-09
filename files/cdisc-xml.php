<?php
/*
  Copyright (c) 2022 Jørgen Mangor Iversen

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
*/
  error_reporting(0);
  header('Cache-Control: no-cache, no-store, must-revalidate');
  header('Pragma: no-cache');
  header('Expires: 0');

  // Upload the XML source from disk
  if (isset($_FILES['parmxml']) && ($_FILES['parmxml']['error'] == UPLOAD_ERR_OK))
    $xml = simplexml_load_file($_FILES['parmxml']['tmp_name']);

  // Upload the translating style sheet from server
  if (isset($_FILES['parmxsl']) && ($_FILES['parmxsl']['error'] == UPLOAD_ERR_OK))
    $xsl = simplexml_load_file($_FILES['parmxsl']['tmp_name']);

//  $xsl = new DOMDocument;
//  $xsl->load($_POST["parmxsl"]);

  // Upload logo image file from disk
  if (isset($_FILES['parmlogo']) && ($_FILES['parmlogo']['error'] == UPLOAD_ERR_OK))
    $logo = base64_encode(file_get_contents($_FILES['parmlogo']['tmp_name']));

  // Configure the transformer
  $proc = new XSLTProcessor;
  $proc->importStyleSheet($xsl); // attach the xsl rules

  // XSLT parameters
  $proc->setParameter('', "parmdisplay",            $_POST["parmdisplay"]);
  $proc->setParameter('', "parmname",               $_POST["parmname"]);
  $proc->setParameter('', "parmlogo",               $logo);
  $proc->setParameter('', "parmstudy",              $_POST["parmstudy"]);
  $proc->setParameter('', "parmversion",            $_POST["parmversion"]);
  $proc->setParameter('', "parmstatus",             $_POST["parmstatus"]);
  $proc->setParameter('', "parmlang",               $_POST["parmlang"]);
  $proc->setParameter('', "parmcdash",              $_POST["parmcdash"]);
  $proc->setParameter('', "nCodeListItemDisplay",   $_POST["nCodeListItemDisplay"]);
  $proc->setParameter('', "displayMethodsTable",    $_POST["displayMethodsTable"]);
  $proc->setParameter('', "displayCommentsTable",   $_POST["displayCommentsTable"]);
  $proc->setParameter('', "displayPrefix",           $_POST["displayPrefix"]);
  $proc->setParameter('', "displayLengthDFormatSD", $_POST["displayLengthDFormatSD"]);

  // Do the transformation
  echo $proc->transformToXML($xml);
?>
