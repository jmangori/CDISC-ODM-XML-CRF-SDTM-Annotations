<?php
/*
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
*/
  error_reporting(0);

  // Load the XML source from disk
  if (isset($_FILES['parmxml']) && ($_FILES['parmxml']['error'] == UPLOAD_ERR_OK))
    $xml = simplexml_load_file($_FILES['parmxml']['tmp_name']);

  // Load the translating style sheet from server
  $xsl = new DOMDocument;
  $xsl->load($_POST["parmxsl"]);

  // Upload logo image file from disk
  if (isset($_FILES['parmlogo']) && ($_FILES['parmlogo']['error'] == UPLOAD_ERR_OK))
  $logo = 'logos/' . $_FILES["parmlogo"]["name"];
  $type = strtolower(pathinfo($logo, PATHINFO_EXTENSION));
  if (isset($_POST['submit']) /* && $_FILES["parmlogo"]["name"] != "" */)
    if (getimagesize($_FILES["parmlogo"]["tmp_name"]))
      if ($_FILES["parmlogo"]["size"] <= 6291455)
        if($type == "jpg" || $type == "png" || $type == "jpeg" || $type == "gif")
          move_uploaded_file($_FILES["parmlogo"]["tmp_name"], $logo);

  // Configure the transformer
  $proc = new XSLTProcessor;
  $proc->importStyleSheet($xsl); // attach the xsl rules

  // XSLT parameters
  $proc->setParameter('', "parmanno",    $_POST["parmanno"]);
  $proc->setParameter('', "parmname",    $_POST["parmname"]);
  $proc->setParameter('', "parmlogo",    $logo);
  $proc->setParameter('', "parmstudy",   $_POST["parmstudy"]);
  $proc->setParameter('', "parmsite",    $_POST["parmsite"]);
  $proc->setParameter('', "parminv",     $_POST["parminv"]);
  $proc->setParameter('', "parmsubject", $_POST["parmsubject"]);
  $proc->setParameter('', "parminit",    $_POST["parminit"]);
  $proc->setParameter('', "parmvisit",   $_POST["parmvisit"]);

  // Do the transformation
  echo $proc->transformToXML($xml);

  // Delete the logo file from disk, but wait until the transformation is complete
  register_shutdown_function('sleep', 1);
  register_shutdown_function('unlink', realpath('.') . '/' . $logo);
?>
