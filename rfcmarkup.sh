#!/usr/bin/env python
# -*- python -*-
#
#       Add HTML markup and links to internet-drafts and RFCs
#
#       -----------------------------------------------------------------
#
#	Copyright 2002 Henrik Levkowetz
#
#	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program; if not, write to the Free Software
#	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#       -----------------------------------------------------------------
#
#       The current version of GPL is at http://www.gnu.org/licenses/gpl.txt
#
#       -----------------------------------------------------------------
#
#       The purpose of this program is to fetch a text document
#       indicated by a URL, and add markup so that any references to
#       interet-drafts or RFCs are changed into hyperlinks, for easier
#       browsing.
#
#       It is called as:
#
#           .../cgi-bin/markup.cgi?url=http://www.ietf.org/internet-drafts/draft-something-or-other-00.txt
#
#


import cgi, os, sys, urllib, re, string, cgitb

"""
   TODO:
        * Handle IEN-nnnn references
        * Refactor into
            get_args()
            markup_top()
            markup_body()
            markup_refs()
          which in turn use
            fix_urls()
            fix_rfcs()
            fix_drafts()
            fix_refref()
            fix_refdef()
            ...
"""

version = "1.96"
cgitb.enable()
args = {}

args["bisdraft"] = ""
args["dcmeta"] = ""
args["dcmetaprofile"] = ""
args["diffmenu"] = ""
args["doccolor"] = ""
args["docinfo"] = True
args["draft"] = ""
args["errata"] = ""
args["favicon"] = ""
args["iprmenu"] = ""
args["erratamenu"] = ""
args["nitsmenu"] = ""
args["obsolete"] = ""
args["overflow"] = ""
args["padding"] = ""
args["plaintext"] = ""
args["script"] = "rfcmarkup"
args["status"] = ""
args["title"] = "rfcmarkup.cgi"
args["tracker"] = ""
args["updated"] = ""
args["version"] = version
args["wgmenu"] = ""
args["emailmenu"] = ""
args["doc"] = ""
args["extrastyle"] = ""
args["htmllink"] = ""
args["style"] = """
    <style type="text/css">
	body {
	    margin: 0px 8px;
            font-size: 1em;
	}
        h1, h2, h3, h4, h5, h6, .h1, .h2, .h3, .h4, .h5, .h6 {
	    font-weight: bold;
            line-height: 0pt;
            display: inline;
            white-space: pre;
            font-family: monospace;
            font-size: 1em;
	    font-weight: bold;
        }
        pre {
            font-size: 1em;
            margin-top: 0px;
            margin-bottom: 0px;
        }
	.pre {
	    white-space: pre;
	    font-family: monospace;
	}
	.header{
	    font-weight: bold;
	}
        .newpage {
            page-break-before: always;
        }
        .invisible {
            text-decoration: none;
            color: white;
        }
        @media print {
            body {
                font-size: 10.5pt;
            }
            h1, h2, h3, h4, h5, h6 {
                font-size: 10.5pt;
            }
        
            a:link, a:visited {
                color: inherit;
                text-decoration: none;
            }
            .noprint {
                display: none;
            }
        }
	@media screen {
	    .grey, .grey a:link, .grey a:visited {
		color: #777;
	    }
            .docinfo {
                background-color: #EEE;
            }
            .top {
                border-top: 7px solid #EEE;
            }
            .bgwhite  { background-color: white; }
            .bgred    { background-color: #F44; }
            .bggrey   { background-color: #666; }
            .bgbrown  { background-color: #840; }            
            .bgorange { background-color: #FA0; }
            .bgyellow { background-color: #EE0; }
            .bgmagenta{ background-color: #F4F; }
            .bgblue   { background-color: #66F; }
            .bgcyan   { background-color: #4DD; }
            .bggreen  { background-color: #4F4; }

            .legend   { font-size: 90%; }
            .cplate   { font-size: 70%; border: solid grey 1px; }
	}
    </style>
    <!--[if IE]>
    <style>
    body {
       font-size: 13px;
       margin: 10px 10px;
    }
    </style>
    <![endif]-->
"""

status2style = {
    "BEST CURRENT PRACTICE": "bgmagenta",
    "DRAFT STANDARD": "bgcyan",
    "EXPERIMENTAL": "bgyellow",
    "HISTORIC": "bggrey",
    "INFORMATIONAL": "bgorange",
    "PROPOSED STANDARD": "bgblue",
    "STANDARD": "bggreen",
    }

usagetext = """

NAME
    %(script)s - add HTML markup and links to internet-drafts and RFCs

SYNOPSIS
    http://example.com/cgi-bin/%(script)s?url=http://example.org/document.txt

DESCRIPTION
    This program is a cgi-bin script which adds html link markup on the
    fly to IETF text-format documents - i.e. RFCs, drafts and other text
    documents which contain references to RFCs and drafts.

    The script is written in Python, so the http server on which you run
    it must have Python installed. You can download Python
    from http://www.python.org. The script has been verified to work with
    Python 2.2 and later.

    It may be called by either http POST or GET, and the relevant field
    names which may be provided are as follows:

OPTIONS
    rfc=number

        Specify the number of an RFC to fetch and mark up.

    draft=draft-name

        Specify the name of an internet-draft to fetch and mark up

    doc=rfcnum-or-draftname

        %(script)s will guess which document is wanted based on the
        name or number given

    url=some-general-url

        Specify an url to fetch and mark up. If the URL does not have a
        scheme identifier, or if it has file: as its scheme identifier,
        this opens a local file; otherwise it opens a socket to a
        server somewhere on the network.

    Either rfc, draft, doc or url must be provided.

        Example:
            http://www.levkowetz.com/ietf/%(script)s?rfc=3344

        will return RFC 3344 with added link markup.

    repository=repository-path
    
        Specify a nonstandard repository to fetch documents from. By
        default, RFCs or drafts are read from the repository at
        http://www.ietf.org/. repository-path may be an url or a path
        local to the server on which the script is running. The last
        alternative is useful when running the script under a http server on
        a local machine, when you also have an RFC and draft repository
        on the same machine. This option assumes that there is one rfc/
        directory and one internet-drafts/ directory under the given
        repository path, whether it is an url or a local path.

        Example:
            http://localhost/cgi-bin/%(script)s?rfc=3344&repository=/usr/local/share/ietf

        will fetch RFCs from /usr/local/share/ietf/rfc/ on the server on
        which the script is running.

COPYRIGHT
 	Copyright 2002 Henrik Levkowetz

 	This program is free software; you can redistribute it and/or modify
 	it under the terms of the GNU General Public License as published by
 	the Free Software Foundation; either version 2 of the License, or
 	(at your option) any later version.

 	This program is distributed in the hope that it will be useful,
 	but WITHOUT ANY WARRANTY; without even the implied warranty of
 	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 	GNU General Public License for more details.

 	You should be able to retrieve a copy of the GNU General Public
 	License from http://www.gnu.org/licenses/gpl.txt; if not, write
 	to the Free Software Foundation, Inc., 59 Temple Place, Suite
 	330, Boston, MA 02111-1307 USA

MAINTAINER
        %(script)s is maintained by Henrik Levkowetz, <henrik@levkowetz.com>.
        The latest version of this script can be retrieved from
        http://tools.ietf.org/tools/rfcmarkup.

""" % args

def prelude(static=False):
    if int(args.get("header", "1")):
        if os.environ.get("GATEWAY_INTERFACE","") and not static:
            print "Content-type: text/html; charset=utf-8\nCache-Control: max-age=86400\n"

        sys.stdout.write( """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head %(dcmetaprofile)s>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="robots" content="%(robots)s" />
    <meta name="creator" content="%(script)s version %(version)s" />
    %(dcmeta)s
    <link rel="icon" href="%(favicon)s" type="image/png" />
    <link rel="shortcut icon" href="%(favicon)s" type="image/png" />
    <title>%(title)s</title>
    %(extrastyle)s
    %(style)s
    <script type="text/javascript"><!--
    function addHeaderTags() {
	var spans = document.getElementsByTagName("span");
	for (var i=0; i < spans.length; i++) {
	    var elem = spans[i];
	    if (elem) {
		var level = elem.getAttribute("class");
                if (level == "h1" || level == "h2" || level == "h3" || level == "h4" || level == "h5" || level == "h6") {
                    elem.innerHTML = "<"+level+">"+elem.innerHTML+"</"+level+">";		
                }
	    }
	}
    }
    var legend_html = "Colour legend:<br /> \
     <table> \
        <tr><td>Unknown:</td>          <td><span class='cplate bgwhite'>&nbsp;&nbsp;&nbsp;&nbsp;</span></td></tr> \
        <tr><td>Draft:</td>            <td><span class='cplate bgred'>&nbsp;&nbsp;&nbsp;&nbsp;</span></td></tr> \
        <tr><td>Informational:</td>    <td><span class='cplate bgorange'>&nbsp;&nbsp;&nbsp;&nbsp;</span></td></tr> \
        <tr><td>Experimental:</td>     <td><span class='cplate bgyellow'>&nbsp;&nbsp;&nbsp;&nbsp;</span></td></tr> \
        <tr><td>Best Common Practice:</td><td><span class='cplate bgmagenta'>&nbsp;&nbsp;&nbsp;&nbsp;</span></td></tr> \
        <tr><td>Proposed Standard:</td><td><span class='cplate bgblue'>&nbsp;&nbsp;&nbsp;&nbsp;</span></td></tr> \
        <tr><td>Draft Standard:</td>   <td><span class='cplate bgcyan'>&nbsp;&nbsp;&nbsp;&nbsp;</span></td></tr> \
        <tr><td>Standard:</td>         <td><span class='cplate bggreen'>&nbsp;&nbsp;&nbsp;&nbsp;</span></td></tr> \
        <tr><td>Historic:</td>         <td><span class='cplate bggrey'>&nbsp;&nbsp;&nbsp;&nbsp;</span></td></tr> \
        <tr><td>Obsolete:</td>         <td><span class='cplate bgbrown'>&nbsp;&nbsp;&nbsp;&nbsp;</span></td></tr> \
    </table>";
    function showElem(id) {
        var elem = document.getElementById(id);
        elem.innerHTML = eval(id+"_html");
        elem.style.visibility='visible';
    }
    function hideElem(id) {
        var elem = document.getElementById(id);
        elem.style.visibility='hidden';        
        elem.innerHTML = "";
    }
    // -->
    </script>
</head>
<body onload="addHeaderTags()">
   <div style="height: 13px;">
      <div onmouseover="this.style.cursor='pointer';"
         onclick="showElem('legend');"
         onmouseout="hideElem('legend')"
	 style="height: 6px; position: absolute;"
         class="pre noprint docinfo %(doccolor)s"
         title="Click for colour legend." >                                                                        </div>
      <div id="legend"
           class="docinfo noprint pre legend"
           style="position:absolute; top: 4px; left: 4ex; visibility:hidden; background-color: white; padding: 4px 9px 5px 7px; border: solid #345 1px; "
           onmouseover="showElem('legend');"
           onmouseout="hideElem('legend');">
      </div>
   </div>
""" % args)
    else:
        print """<html><body>
   <!-- %(script)s version %(version)s -->
   %(style)s
<pre>""" % args

topmenu = """<span class="pre noprint docinfo top">[<a href="../html/" title="Document search and retrieval page">Docs</a>] [<a href="%(plaintext)s" title="Plaintext version of this document">txt</a>|<a href="/pdf/%(doc)s" title="PDF version of this document">pdf</a>%(htmllink)s]%(draft)s%(tracker)s%(wgmenu)s%(emailmenu)s%(diffmenu)s%(nitsmenu)s%(iprmenu)s%(erratamenu)s%(padding)s</span><br />"""
#wgmenu = """ [<a href="../wg/%(wg)s" title="The working group handling this
#document">WG</a>] [<a href="../wg/%(wg)s/%(base)s" title="The WG docment page for this document">Doc Info</a>]"""
wgmenu = """ [<a href="../wg/%(wg)s" title="The working group handling this document">WG</a>]"""
emailmenu = """ [<a href="mailto:%(base)s@tools.ietf.org?subject=%(base)s%%20" title="Send email to the document authors">Email</a>]"""
diffmenu = """ [<a href="/rfcdiff?difftype=--hwdiff&amp;url2=%(doc)s" title="Inline diff (wdiff)">Diff1</a>] [<a href="/rfcdiff?url2=%(doc)s" title="Side-by-side diff">Diff2</a>]"""
nitsmenu = """ [<a href="/idnits?url=http://tools.ietf.org/id/%(doc)s" title="Run an idnits check of this document">Nits</a>]"""
draftiprmenu = """ [<a href="https://datatracker.ietf.org/ipr/search/?option=document_search&document_search=%(base)s" title="IPR disclosures related to this document">IPR</a>]"""
rfciprmenu = """ [<a href="https://datatracker.ietf.org/ipr/search/?option=rfc_search&rfc_search=%(rfc)s" title="IPR disclosures related to this document">IPR</a>]"""
htmllink = """|<a href="/id/%(draftname)s.html" title="HTML version of this document, from XML2RFC">html</a>"""

docinfo = """
<span class="pre noprint docinfo">                                                                        </span><br />
<span class="pre noprint docinfo">%(obsolete)-51s%(status)21s</span><br />
<span class="pre noprint docinfo">%(updated)-60s%(errata)12s</span><br />
<pre>
"""

nomenu = """<pre>



"""

statuslen = len("BEST CURRENT PRACTICE") # 21
erratalen = len("Errata Exist")               # 12

def postlude():
    if int(args.get("blurb", "1")):
        print """</pre><br />
<span class="noprint"><small><small>Html markup produced by rfcmarkup %(version)s, available from
<a href="http://tools.ietf.org/tools/rfcmarkup/">http://tools.ietf.org/tools/rfcmarkup/</a>
</small></small></span>
</body></html>""" % args
    else:
        print "</pre></body></html>"

def version():
    prelude()
    print "%(script)s version %(version)s" % args
    postlude()

def usage():
    print usagetext

def markup():
        global args
#        sys.stderr = sys.stdout
        extra = ""
        bcp = None
        std = None
        rfc = None
        wgname = None
        draftname = None
        charter = None
        info = {}
        attribs = {}
	fields = cgi.FieldStorage()
        for key in fields.keys():
            attribs[key] = fields[key].value

        script = os.environ.get("SCRIPT_NAME", sys.argv[0])

        if fields.has_key("info"):
            info = fields["info"].value
            if (info=="usage"):
                usage()
            if (info=="version"):
                version()
            return

        if fields.has_key("--info"):
            info = fields["--info"].value
            if (info=="usage"):
                print usagetext
            if (info=="version"):
                print "%(script)s version %(version)s" % args
            return

        if fields.has_key("repository"):
            rfcs = fields["repository"].value + "/rfc"
            ids =  fields["repository"].value + "/internet-drafts"
            extra = extra + "repository=%s&amp;" % fields["repository"].value
        else:
            if os.path.exists("/home/ietf/rfc"):
                rfcs = "file:///home/ietf/rfc"
            else:
                rfcs = "http://tools.ietf.org/rfc"
            if os.path.exists("/home/ietf/id"):
                ids =  "file:///home/ietf/id"
            else:
                ids =  "http://tools.ietf.org/id"

        if fields.has_key("rfc-repository"):
            rfcs = fields["rfc-repository"].value
            extra = extra + "rfc-repository=%s&amp;" % fields["rfc-repository"].value

        if fields.has_key("id-repository"):
            ids = fields["id-repository"].value
            extra = extra + "id-repository=%s&amp;" % fields["id-repository"].value

        if fields.has_key("header"):
            args["header"] = fields["header"].value

        if fields.has_key("blurb"):
            args["blurb"] = fields["blurb"].value

        if fields.has_key("style"):
            args["style"] = fields["style"].value

        if fields.has_key("docinfo"):
            args["docinfo"] = eval(fields["docinfo"].value)

        if fields.has_key("robots"):
            args["robots"] = fields["robots"].value
        else:
            args["robots"] = "index,nofollow"

	if fields.has_key("staticpath"):
	    optstatic = fields["staticpath"].value == "true"
            args["robots"] = "index,follow"
	else:
	    optstatic = False

        if fields.has_key("topmenu"):
	    optmenu = fields["topmenu"].value == "true"
            #extra = extra + "topmenu=%s&amp;" % fields["topmenu"].value
	else:
	    optmenu = False

        if fields.has_key("lineoffset"):
	    optlineoffs = int(fields["lineoffset"].value)
            #extra = extra + "topmenu=%s&amp;" % fields["topmenu"].value
	else:
	    optlineoffs = 0

        # Handle document information.
        if fields.has_key("draft"):
            url = "%s/%s" % (ids, fields["draft"].value)
            args["title"] = fields["draft"].value[6:].split(".")[0]
#            if not url[-4:] == ".txt":
#                url = url + ".txt"
	elif fields.has_key("rfc"):
            rfc = fields["rfc"].value
            url = "%s/rfc%s.txt" % (rfcs, rfc)
            args["title"] = "rfc "+fields["rfc"].value
            args["doc"] = "rfc"+rfc
	elif fields.has_key("bcp"):
            bcp = fields["bcp"].value
            url = "%s/bcp/bcp%s.txt" % (rfcs, bcp)
            args["title"] = "bcp "+fields["bcp"].value
            args["doc"] = "bcp"+bcp
	elif fields.has_key("fyi"):
            fyi = fields["fyi"].value
            url = "%s/fyi/fyi%s.txt" % (rfcs, fyi)
            args["title"] = "fyi "+fields["fyi"].value
            args["doc"] = "fyi"+fyi
	elif fields.has_key("std"):
            std = fields["std"].value
            url = "%s/std/std%s.txt" % (rfcs, std)
            args["title"] = "std "+fields["std"].value
            args["doc"] = "std"+std
	elif fields.has_key("url"):
	    url = fields["url"].value
            if not re.match("^(http|https|ftp|file)", url):
                url = "http://%s%s/%s" %( os.environ.get("SERVER_NAME", "ietf.levkowetz.com"), os.path.dirname(script), url)
            args["title"] = os.path.basename(fields["url"].value)
        elif fields.has_key("doc") or os.environ.get("PATH_INFO", "/") != "/":
            if fields.has_key("doc"):
                doc = fields["doc"].value
            else:
                doc = os.environ.get("PATH_INFO", "/")[1:]
            # Remove extension
            if doc.rfind(".") > 0:
                doc = doc[:doc.rfind(".")]
            if re.match("^[0-9]+$", doc):
                rfc = doc
                url = "file:///home/ietf/rfc/rfc%s.txt" % doc
                title = "RFC " + rfc
                args["doc"] = "rfc"+rfc
            elif re.match("rfc[0-9]+$", doc):
                rfc = doc[3:]
                url = "%s/%s.txt" % (rfcs, doc)
                title = "RFC " + rfc
                args["doc"] = "rfc"+rfc
            elif re.match("^bcp[0-9]+$", doc):
                url = "%s/bcp/%s.txt" % (rfcs, doc)
                title = "BCP " + doc[3:]
                args["doc"] = "bcp"+doc[3:]
            elif re.match("^fyi[0-9]+$", doc):
                url = "%s/fyi/%s.txt" % (rfcs, doc)
                title = "FYI " + doc[3:]
                args["doc"] = "fyi"+doc[3:]
            elif re.match("^std[0-9]+$", doc):
                url = "%s/std/%s.txt" % (rfcs, doc)
                title = "STD " + doc[3:]
                args["doc"] = "std"+doc[3:]
            elif re.match("^ion-.+$", doc):
                url = "file:///home/ietf/ion/approved/%s.txt" % doc
                title = "ION: " + doc
                args["doc"] = doc
            elif re.match("^charter-.+$", doc):
                url = "file:///www/tools.ietf.org/charter/%s.txt" % doc
                title = doc.split(".")[0]
                args["doc"] = doc
                charter = doc
            elif re.match("draft-[0-9a-z.*-]+$", doc):
                if not re.match(".*\..+", doc):
                    doc = doc + ".txt"
                url = "http://tools.ietf.org/id/%s" % doc
                title = doc.split(".")[0]
                draftparts = re.match("draft-([0-9a-z]+)-(krb-wg|[0-9a-z]+)-([0-9a-z.*-]+)$", doc)
                if draftparts and draftparts.group(1) == "ietf":
                    wgname = draftparts.group(2)
                    args["wg"] = wgname
                    args["base"] = os.path.splitext(doc)[0][:-3]
                draftname = doc
                args["doc"] = doc
            else:
                url = "your document ('%s')." % doc
                title = ""

            args["title"] = title

	elif script == "rfcmarkup":
            usage()
            #print "<pre>"
            #print fields
            #print os.environ
            #print "</pre>"
            return
        else:
            prelude()
            print """</pre>
            <p>
            <big><b>Add HTML markup to a document:</b></big>
            </p>
            <p>
            Please provide a document number, draft name or URL:
            </p>
            <p>
            <form action="%s">
              <table>
                <tr><td>RFC (number only):                                      </td><td><input type="text" name="rfc" /></td></tr>
                <tr><td>Draft: (name starting with <tt>draft-</tt>):            </td><td><input type="text" name="draft" /></td></tr>
                <tr><td>URL (any text document available through http or ftp):  </td><td><input type="text" name="url" /></td></tr>
                <tr><td>                                                        </td><td><input type="Submit" value="Submit"/></td></tr>
              </table>
            </form>
            </p>
            </body>
            </html>
            """ % script
            return

        if fields.has_key("title"):
            args["title"] = fields["title"].value

        if fields.has_key("extrastyle"):
            args["extrastyle"] = "<style>"+fields["extrastyle"].value+"</style>"

        tags = []
        if fields.has_key("comments"):
            if type(fields["comments"]) is type([]):
                for item in fields["comments"]: tags.append(item.value)
            else:
                tags.append(fields["comments"].value)

        colors = []
        if fields.has_key("color"):
            if type(fields["color"]) is type([]):
                for item in fields["color"]: colors.append(item.value)
            else:
                colors.append(untaint(fields["color"].value))
        else:
            colors = ["#F00", "#0A0", "#00C", "#880", "#088", "#808", ]            

	if url.startswith("file:///home/ietf/"):
	    start = len("file:///home/ietf/") -1
	    args["plaintext"] = url[start:]
	else:
	    args["plaintext"] = url

	# Get the raw text of the source page
        try:
            f = urllib.urlopen(url)
            data = f.read()
            f.close()
        except:
            prelude();
            print "<h3> &nbsp; &nbsp; Sorry, couldn't find %s</h3>" % os.path.basename(url)
            sys.exit(0)


        def filetext(path):
            if os.path.isfile(path):
                file = open(path)
                text = file.read()
                file.close()
                return text.strip()
            else:
                return ""

        def listdir(path, pattern):
            dirlist = os.listdir(path)
            files = [ x for x in dirlist if re.match(pattern, x) ]
            files.sort()
            return files

        def stateinfo(fullname):
            name = fullname
            if name.endswith(".txt"):
                name = name[:-4]
            if re.search("-[0-9][0-9]$", name):
                name = name[:-3]
            info = filetext("/www/tools.ietf.org/draft/%s/now" % (name))
            attribs = {}
            if info:
                first, rest = info.split(None, 1)
                if first.startswith("19") or first.startswith("20"):
                    attribs["timestamp"] = first
                    first, rest = rest.split(None, 1)
                if first.startswith("draft-"):
                    attribs["document"] = first
                attriblist = re.findall("([A-Za-z]+='[^']+')", info)
                for attrib in attriblist:
                    try:
                        attr, value = attrib.split("=")
                        value = value[1:-1]
                        if ";" in value:
                            value = value.rsplit(";", 1)[0]
                        value = eval("'"+value+"'")
                        attribs[attr] = value
                    except:
                        pass
            else:
                try:
                    import idauthors
                    if not fullname.endswith(".txt"):
                        fullname = fullname + ".txt"
                    attribs = idauthors.getmeta(fullname) or {}
                except Exception:
                    pass
            return attribs

        def setdcmeta(attribs, args):
            metatext = '<link rel="schema.DC" href="http://purl.org/dc/elements/1.1/" />\n'
            metaval = {}
            metatags = [
                ("doctitle", "DC.Title"), 
                ("docauthors", "DC.Creator"),
                ("docsubmitted", "DC.Date.Issued"),
                ("docpublished", "DC.Date.Issued"),         # overrides submission date
                ("docabstract", "DC.Description.Abstract"),
                ("document", "DC.Identifier"),
                ("docrfcnum", "DC.Identifier"),             # overides draft id
                ("docreplaces", "DC.Relation.Replaces"),
                ("docobsoletes", "DC.Relation.Replaces"),   # overrides draft replacement
            ]
            listtags = ["DC.Creator", "DC.Relation.Replaces", ]
            for key, tag in metatags:
                if key in attribs:
                    if key == "document":
                        val = "urn:ietf:id:%s" % attribs[key][6:]
                    elif key == "docrfcnum":
                        val = "urn:ietf:rfc:%s" % attribs[key]
                    else:
                        val = attribs[key] or ""
                    metaval[tag] = cgi.escape(val)
            for tag, val in metaval.items():
                val = val.replace(r"\\n", " ")
                if tag in listtags and "," in val:
                    items = val.split(",")
                    if tag == "DC.Creator":
                        for i in range(len(items)):
                            item = items[i]
                            parts = item.split()
                            if parts:
                                if "@" in parts[-1]:
                                    parts = parts[:-1]
                            items[i] = " ".join(parts)
                        items = list(set(items))
                        for item in items:
                            parts = item.split()
                            if parts:
                                # emit with family name first, then comma and given name or initials
                                metatext += '<meta name="%s" content="%s, %s" />\n' % (tag, parts[-1], " ".join(parts[:-1]))
                    else:
                        for item in items:
                            metatext += '<meta name="%s" content="%s" />\n' % (tag, item.strip())
                else:
                    metatext += '<meta name="%s" content="%s" />\n' % (tag, val)
            args["dcmeta"] = metatext
            args["dcmetaprofile"] = 'profile="http://dublincore.org/documents/2008/08/04/dc-html/"'
            return args
            

        # Helper function to generate left-side metainformation (list of RFCs)
        def leftmeta(docname, tag, prefix, rightlen):
            line = ""
            info = filetext("/home/ietf/rfc/meta/%s.%s" % (docname, tag))

            if info:
                line = prefix
                leftlen = len(prefix)
                rfclen  = len(" 0000,")
                count = 0
                maxcount = (72 - leftlen - max(rightlen,erratalen,statuslen))/rfclen
                
                for rfc in info.split():
                    rfcnum = rfc[3:]
                    if count:
                        line = line + ","
                        if (count % maxcount) == 0:
                            line = line + " "*(72-leftlen-rfclen*maxcount) + "\n" + " "*leftlen
                    count += 1
		    if optstatic:
			line = line + """ <a href=\"./rfc%s\">%s</a>""" % (rfcnum, rfcnum)
		    else:
                        line = line + """ <a href=\"%s/%s\">%s</a>""" % (script, rfcnum, rfcnum)
                line = line + " "*(72-leftlen-rightlen-((count-1)%maxcount+1)*rfclen+1) # +1 for the missing comma after the last rfcnum
            return line, info
            
        def chartermeta(charter, prefix, rightlen, attribs):
            name = re.sub("-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9](\.txt)?$", "", charter)
            line = ""
            files = listdir("/www/tools.ietf.org/charter/", name+"-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\.txt$")
            versions = [ file[-14:-4] for file in files ]

            if versions:
                line = line + prefix
                leftlen = len(prefix)
                verlen = len(" 2000-01-01")
                count = 0
                nextdoclen = 0
                maxcount = (72 - leftlen - rightlen)/verlen
                for ver in versions:
                    if count:
                        #line = line + ","
                        if (count % maxcount) == 0:
                            line = line + " "*(72-leftlen-verlen*maxcount) + "\n" + " "*leftlen
                    count += 1
                    if optstatic:
                        line = line + """ <a href=\"./%s-%s\">%s</a>""" % (name, ver, ver)
                    else:
                        line = line + """ <a href=\"%s/%s-%s\">%s</a>""" % (script, name, ver, ver)
                line = line + " "*(50-leftlen-rightlen-nextdoclen-(count%maxcount)*verlen+1) # +1 for the missing comma after the last rfcnum
            return line

        def draftmeta(draftname, prefix, rightlen, attribs):
            name = draftname[:-3]
            rev  = draftname[-2:]
            line = ""
            rfc = filetext("/home/ietf/rfc/meta/%s.rfcnum" % (name,))
            versions = filetext("/www/tools.ietf.org/draft/%s/versions" % (name,))

            if versions:
                if not rev in versions:
                    versions += " " + rev
                attribs["docversions"] = ", ".join(versions.split())
                line = line + prefix
                leftlen = len(prefix)

                verlen  = len(" 00")
                count = 0
                nextdoclen = 0
                maxcount = (47 - leftlen - rightlen)/verlen

                prev = None
                if "docreplaces" in attribs:
                    prev = attribs["docreplaces"]
                    pname = prev
                else:
                    match = re.match(".*-((rfc)?[0-9][0-9][0-9]+)bis(-.*|$)", name)
                    if match:
                        prev = match.group(1)
                        pname = prev
                        if pname.startswith("rfc"):
                            pname = pname[3:]
                        pname = "RFC " + pname
                if prev:
                    if optstatic:
                        line = line + """ (<a href="./%s" title="Precursor">%s</a>)""" % (prev, pname)
                    else:
                        line = line + """ (<a href="%s/%s" title="Precursor">%s</a>)""" % (script, prev, pname)
                    prevlen = len(" (%s)" % pname)
                    count = (prevlen + verlen-1) // verlen
                    line = line + " " * (count*verlen - prevlen)
                    if count >= maxcount:
                        line = line + " "*(72-leftlen-verlen*count) + "\n" + " "*leftlen
                        count = 0

                for ver in versions.split():
                    if count:
                        #line = line + ","
                        if (count % maxcount) == 0:
                            line = line + " "*(72-leftlen-verlen*maxcount) + "\n" + " "*leftlen
                    count += 1
                    if optstatic:
                        line = line + """ <a href=\"./%s-%s\">%s</a>""" % (name, ver, ver)
                    else:
                        line = line + """ <a href=\"%s/%s-%s\">%s</a>""" % (script, name, ver, ver)
                if rfc:
                    rfcnum = rfc[3:]
                    if int(rfcnum) > 0:
                        if (count % maxcount) == 0:
                            line = line + " "*(72-leftlen-verlen*maxcount) + "\n" + " "*leftlen
                        nextdoclen = len(" RFC 0000")
                        if optstatic:
                            line = line + """ <a href=\"./rfc%s\">RFC %4s</a>""" % (rfcnum, rfcnum)
                        else:
                            line = line + """ <a href=\"%s/%s\">RFC %4s</a>""" % (script, rfcnum, rfcnum)
                elif "docreplacement" in attribs:
                    replacement = attribs["docreplacement"]
                    if replacement and replacement != "0":
                        if (count % maxcount) == 0:
                            line = line + " "*(72-leftlen-verlen*maxcount) + "\n" + " "*leftlen
                        nextdoclen = len(replacement)+1
                        if optstatic:
                            line = line + """ <a href=\"./%s\" title="%s replaces this draft">%s</a>""" % (replacement, replacement, replacement)
                        else:
                            line = line + """ <a href=\"%s/%s\" title="%s replaces this draft">%s</a>""" % (script, replacement, replacement, replacement)
                        
                line = line + " "*(50-leftlen-rightlen-nextdoclen-(count%maxcount)*verlen+1) # +1 for the missing comma after the last rfcnum
            return line

        if draftname:
            
            attribs.update(stateinfo(draftname))
            args["favicon"] = "/images/id.png"
            draftname = draftname.split(".")[0]
            args["obsolete"] = draftmeta(draftname, "Versions:", 0, attribs)
            args["doccolor"] = "bgred"
            args["tracker"] = " [<a href='https://datatracker.ietf.org/doc/%s' title='IESG Datatracker information for this document'>Tracker</a>]" % (draftname[:-3])
            
        elif charter and optmenu:
            args["obsolete"] = chartermeta(charter, "Versions:", 0, attribs)

        elif rfc:
            attribs.update(stateinfo("rfc%s" % (rfc)))
            args["favicon"] = "/images/rfc.png"
            if filetext("/home/ietf/rfc/meta/rfc%s.errata" % rfc):
                # Errata URL changes around 18 Oct 2007 
                # args["errata"] = """<a href="http://www.rfc-editor.org/cgi-bin/errataSearch.pl?rfc=%s">Errata</a>""" % rfc
                args["errata"] = "<span style='color: #C00;'>Errata Exist</span>"
                args["erratamenu"] = """ [<a href="http://www.rfc-editor.org/errata_search.php?rfc=%s">Errata</a>]""" % rfc

            args["status"] = filetext("/home/ietf/rfc/meta/rfc%s.status" % rfc)

            args["obsolete"], info = leftmeta("rfc%s"%rfc, "obsolete", "Obsoleted by:", statuslen)
            args["updated"],  info = leftmeta("rfc%s"%rfc, "updated", "Updated by:", erratalen)

            if args["obsolete"]:
                args["doccolor"] = "bgbrown"
            else:
                if args["status"] in status2style:
                    args["doccolor"] = status2style[args["status"]]
                else:
                    args["doccolor"] = "bgwhite"

            # If there is no obsolete field, use that for Updated
            # Assumption: the obsoleted by list never has more than 6 rfcs,
            # but the updated by list may have more.
            if len(args["updated"]) and not len(args["obsolete"]):
                leftlen = len("Updated by:")
                rightlen = statuslen
                rfclen = len(" 0000,")
                maxcount = (72 - leftlen - max(rightlen,erratalen,statuslen))/rfclen
                count = min(maxcount, len(info.split()))

                updated = args["updated"].split("\n", 1)
                args["obsolete"] = updated[0]
                if updated[1:]:
                    args["updated"] = updated[1]
                else:
                    args["updated"] = ""
                # Add padding to make the line 72 spaces wide when rendered
                if len(info.split()) > maxcount:
                    args["obsolete"] = args["obsolete"].strip() + " " * (72-leftlen-rightlen-count*rfclen)
                else:
                    args["obsolete"] = args["obsolete"].strip() + " " * (72-leftlen-rightlen-count*rfclen+1) # +1 for the missing comma after the last rfcnum

            draft = filetext("/home/ietf/rfc/meta/rfc%s.draft" % rfc)
            if draft:
                short = draft
                draftmaxlen = 29
                if "errata" in args:
                    draftmaxlen -= len(" [Errata]")
                if len(draft) > draftmaxlen:
                    short = draft[:draftmaxlen-3] + "..."
                if optstatic:
                    args["draft"] = (""" [<a href="%s" title="%s">%s</a>]""") % (draft, draft, short)
                else:
                    args["draft"] = (""" [<a href="%s?%sdoc=%s" title="%s">%s</a>]""") % (script, optmenu and "topmenu=true&amp;" or "",draft, draft, short)

        elif bcp:
            args["doccolor"] = "bgmagenta"

        elif std:
            args["doccolor"] = "bggreen"

        args = setdcmeta(attribs, args)

        if f.info().gettype() == "text/html":
            print "Location: %s\n" % url
#            print f.info()
#            print data
            return

        # ------------------------------------------------------------------------
        # Start of markup handling

        # Convert \r which is not followed or preceded by a \n to \n
        #  (in case this is a mac document)
        data = re.sub("([^\n])\r([^\n])", "\g<1>\n\g<2>", data)
        # Strip \r (in case this is a ms format document):
        data = string.replace(data,"\r","")

        # -------------
        # Normalization

        # Remove whitespace at the end of lines
        data = re.sub("[\t ]+\n", "\n", data)

        data = data.expandtabs()

        # Remove extra blank lines at the start of the document
        data = re.sub("^\n*", "", data, 1)

        # Fix up page breaks:
        # \f should aways be preceeded and followed by \n
        data = re.sub("([^\n])\f", "\g<1>\n\f", data)
        data = re.sub("\f([^\n])", "\f\n\g<1>", data)

        # [Page nn] should be followed by \n\f\n
        data = re.sub("(?i)(\[Page [0-9ivxlc]+\])[\n\f\t ]*(\n *[^\n\f\t ])", "\g<1>\n\f\g<2>", data)
        
        # Normalize indentation
        linestarts = re.findall("(?m)^([ ]*)\S", data);
        prefixlen = 72
        for start in linestarts:
            if len(start) < prefixlen:
                prefixlen = len(start)
        if prefixlen:
            data = re.sub("\n"+(" "*prefixlen), "\n", data)

        # reference name tag markup
        reference = {}
        ref_url = {}

        ## Locate the start of the References section as the first reference
        ## definition after the last reference usage
        ## Incomplete 05 Aug 2010 17:05:27

        ##ref_usages = re.findall("(\W)(\[)([-\w.]+)((, ?[-\w.]+)*\])", data)
        ref_defs = re.findall("(?sm)^( *\n *)\[([-\w.]+?)\]( +)(.*?)(\n *)$", data)

        ##ref_pos = [ match.start() for match in ref_usages ]
        ##def_pos = [ match.start() for match in ref_defs ]
        ##ref_pos = [ pos for pos in ref_pos if not pos in ref_defs ]
        ##last_ref_pos = ref_pos[-1] if ref_pos else None

        #sys.stderr.write("ref_defs: %s\n" % repr(ref_defs))        
        for tuple in ref_defs:
            title_match = re.search("(?sm)^(.*?(\"[^\"]+?\").+?|.*?(,[^,]+?,)[^,]+?)$", tuple[3])
            if title_match:
                reftitle = title_match.group(2) or title_match.group(3).strip("[ ,]+")
                # Get rid of page break information inside the title
                reftitle = re.sub("(?s)\n\n\S+.*\n\n", "", reftitle)
                reftitle = reftitle.replace("'","&#39;")    # Quote quotes
                reftitle = re.sub("[\n\t ]+", " ", reftitle) # Remove newlines and tabs
                reference[tuple[1]] = reftitle
            url_match = re.search(r"(http|https|ftp)://\S+", tuple[3])
            if url_match:
                ref_url[tuple[1]] = url_match.group(0)
                
        # -------------
        # escape any html significant characters
        data = cgi.escape(data);


        # -------------
        # Adding markup

        # Typewriter-style underline:
        data = re.sub("_[\b](.)", "<u>\g<1></u>", data)

        # Line number markup goes here


        # Obsoletes: ... markup
        
        def rfclist_replace(keyword, data):
            def replacement(match):
                group = list(match.groups(""))
                group[3] = re.sub("\d+", """<a href=\"%s?%srfc=\g<0>\">\g<0></a>""" % (script, extra), group[3])
                if group[8]:
                    group[8] = re.sub("\d+", """<a href=\"%s?%srfc=\g<0>\">\g<0></a>""" % (script, extra), group[8])
                else:
                    group[8] = ""
                return "\n%s%s%s\n%s%s" % (group[0], group[3], group[5], group[7], group[8])
            data = re.sub("\n(%s( RFCs| RFC)?: ?( RFCs| RFC)?)(( \d+,| \d+)+)(.*)\n(( *)((\d+, )*(\d+)))*" % keyword, replacement, data, 1)
            return data

        data = rfclist_replace("Obsoletes", data)
        data = rfclist_replace("Updates", data)
        
        lines = data.splitlines(True)
        head  = "".join(lines[:28])
        rest  = "".join(lines[28:])

        # title markup
        head = re.sub("""(?im)(([12][0-9][0-9][0-9]|^Obsoletes.*|^Category: (Standards Track|Informational|Experimental|Best Current Practice)) *\n\n+ +)([A-Z][^\n]+)$""", """\g<1><span class=\"h1\">\g<4></span>""", head, 1)
        head = re.sub("""(?i)(<span class="h1".+</span>)(\n +)([^<\n]+)\n""", """\g<1>\g<2><span class="h1">\g<3></span>\n""", head, 1)
        head = re.sub("""(?i)(<span class="h1".+</span>)(\n +)([^<\n]+)\n""", """\g<1>\g<2><span class="h1">\g<3></span>\n""", head, 1)

        if "doctitle" in attribs:
            args["title"] = args["title"] + " - " + attribs["doctitle"]
        else:
            for match in re.finditer("""(?i)<span class="h1".*?>(.+?)</span>""", head):
                if not (match.group(1).startswith("draft-") or match.group(1).startswith("&lt;draft-")):
                    if not " -" in args["title"]:
                        args["title"] = args["title"] + " -"
                    args["title"] = args["title"] + " " + match.group(1)

        data = head + rest

        # http link markup
        # link crossing a line.  Not permitting ":" after the line break will
        # result in some URLs broken across lines not being recognized, but
        # will on the other hand correctly handle a series of URL listed line
        # by line, one on each line.
        #  Link crossing a line, where the continuation contains '.' or '/'
	data = re.sub("(?im)(\s|^|[^=]\"|\()((http|https|ftp)://([:A-Za-z0-9_./@%&?#~=-]+)?)(\n +)([A-Za-z0-9_./@%&?#~=-]+[./][A-Za-z0-9_./@%&?#~=-]+[A-Za-z0-9_/@%&?#~=-])([.,)\"\s]|$)",
                        "\g<1><a href=\"\g<2>\g<6>\">\g<2></a>\g<5><a href=\"\g<2>\g<6>\">\g<6></a>\g<7>", data)
	data = re.sub("(?im)(&lt;)((http|https|ftp)://([:A-Za-z0-9_./@%&?#~=-]+)?)(\n +)([A-Za-z0-9_./@%&?#~=-]+[A-Za-z0-9_/@%&?#~=-])(&gt;)",
                        "\g<1><a href=\"\g<2>\g<6>\">\g<2></a>\g<5><a href=\"\g<2>\g<6>\">\g<6></a>\g<7>", data)
        #  Link crossing a line, where first line ends in '-'
	data = re.sub("(?im)(\s|^|[^=]\"|\()((http|https|ftp)://([:A-Za-z0-9_./@%&?#~=-]+)?-)(\n +)([A-Za-z0-9_./@%&?#~=-]+[A-Za-z0-9_/@%&?#~=-])([.,)\"\s]|$)",
                        "\g<1><a href=\"\g<2>\g<6>\">\g<2></a>\g<5><a href=\"\g<2>\g<6>\">\g<6></a>\g<7>", data)
	data = re.sub("(?im)(&lt;)((http|https|ftp)://([:A-Za-z0-9_./@%&?#~=-]+)?)(\n +)([A-Za-z0-9_./@%&?#~=-]+[A-Za-z0-9_/@%&?#~=-])(&gt;)",
                        "\g<1><a href=\"\g<2>\g<6>\">\g<2></a>\g<5><a href=\"\g<2>\g<6>\">\g<6></a>\g<7>", data)
        # link crossing a line, enclosed in "<" ... ">"
	data = re.sub("(?im)<((http|https|ftp)://([:A-Za-z0-9_./@%&?#~=-]+)?)(\n +)([A-Za-z0-9_./@%&?#~=-]+[A-Za-z0-9_/@%&?#~=-])>",
                        "<\g<1><a href=\"\g<1>\g<5>\">\g<1></a>\g<4><a href=\"\g<1>\g<5>\">\g<5></a>>", data)
	data = re.sub("(?im)(&lt;)((http|https|ftp)://([:A-Za-z0-9_./@%&?#~=-]+)?)(\n +)([A-Za-z0-9_./@%&?#~=-]+[A-Za-z0-9_/@%&?#~=-])(&gt;)",
                        "\g<1><a href=\"\g<2>\g<6>\">\g<2></a>\g<5><a href=\"\g<2>\g<6>\">\g<6></a>\g<7>", data)
        # link on a single line
	data = re.sub("(?im)(\s|^|[^=]\"|&lt;|\()((http|https|ftp)://[:A-Za-z0-9_./@%&?#~=-]+[A-Za-z0-9_/@%&?#~=-])([.,)\"\s]|&gt;|$)",
                        "\g<1><a href=\"\g<2>\">\g<2></a>\g<4>", data)

        # undo markup if RFC2606 domain
        data = re.sub("""(?i)<a href="[a-z]*?://([a-z0-9_-]+?\.)?example(\.(com|org|net))?(/.*?)?">(.*?)</a>""", "\g<5>", data) 
  
        # draft markup
        # draft name crossing line break
	data = re.sub("([^/#=\?\w-])(draft-([-a-zA-Z0-9]+-)?)(\n +)([-a-zA-Z0-9]+[a-zA-Z0-9](.txt)?)",
                        "\g<1><a href=\"%s?%sdraft=\g<2>\g<5>\">\g<2></a>\g<4><a href=\"%s?%sdraft=\g<2>\g<5>\">\g<5></a>" % (script, extra, script, extra), data)
        # draft name on one line (but don't mess with what we just did above)
	data = re.sub("([^/#=\?\w>=-])(draft-[-a-zA-Z0-9]+[a-zA-Z0-9](.txt)?)",
                        "\g<1><a href=\"%s?%sdraft=\g<2>\">\g<2></a>" % (script, extra), data)

        # rfc markup
        # rfc and number on the same line
	data = re.sub("""(?i)([^[/\w-])(rfc([- ]?))([0-9]+)(\W)""",
                        """\g<1><a href=\"%s?%srfc=\g<4>\">\g<2>\g<4></a>\g<5>""" % (script, extra), data)
        # rfc and number on separate lines
	data = re.sub("(?i)([^[/\w-])(rfc([-]?))(\n +)([0-9]+)(\W)",
                        "\g<1><a href=\"%s?%srfc=\g<5>\">\g<2></a>\g<4><a href=\"%s?%srfc=\g<5>\">\g<5></a>\g<6>" % (script, extra, script, extra), data)
        # spelled out Request For Comments markup
	data = re.sub("(?i)(\s)(Request\s+For\s+Comments\s+\([^)]+\)\s+)([0-9]+)",
                        "\g<1>\g<2><a href=\"%s?%srfc=\g<3>\">\g<3></a>" % (script, extra), data)
        # bcp markup
	data = re.sub("(?i)([^[/\w-])(bcp([- ]?))([0-9]+)(\W)",
                        "\g<1><a href=\"%s?%sbcp=\g<4>\">\g<2>\g<4></a>\g<5>" % (script, extra), data)
	data = re.sub("(?i)([^[/\w-])(bcp([-]?))(\n +)([0-9]+)(\W)",
                        "\g<1><a href=\"%s?%sbcp=\g<5>\">\g<2></a>\g<4><a href=\"%s?%sbcp=\g<5>\">\g<5></a>\g<6>" % (script, extra, script, extra), data)

        def workinprogress_replacement(match):
            g1 = match.group(1)
            g2 = match.group(2)
            g3 = match.group(3)
            # eliminate embedded hyperlinks in text we'll use as anchor text
            g4 = match.group(4)
            g4 = re.sub("<a.+?>(.+?)</a>", "\g<1>", g4)
            g4url = urllib.quote_plus(g4)
            g5 = match.group(5)
            return """%s[<a name=\"ref-%s\" id=\"ref-%s\">%s</a>]%s<a style=\"text-decoration: none\" href='http://www.google.com/search?sitesearch=tools.ietf.org%%2Fhtml%%2F&amp;q=inurl:draft-+%s'>%s</a>%s""" % (g1, g2, g2, g2, g3, g4url, g4, g5)

        data = re.sub("(\n *\n *)\[([-\w.]+)\](\s+.*?)(\".+\")(,\s+Work\s+in\s+Progress.)", workinprogress_replacement, data)
        data = re.sub("(\n *\n *)\[([-\w.]+)\](\s)", "\g<1>[<a name=\"ref-\g<2>\" id=\"ref-\g<2>\">\g<2></a>]\g<3>", data)

        data = re.sub("(\n *\n *)\[(RFC [-\w.]+)\](\s)", "\g<1>[<a name=\"ref-\g<2>\" id=\"ref-\g<2>\">\g<2></a>]\g<3>", data)

        ref_targets = re.findall('<a name="ref-(.*?)"', data)

        # reference link markup
        def reference_replacement(match):
            pre = match.group(1)
            beg = match.group(2)
            tag = match.group(3)
            end = match.group(4)
            isrfc = re.match("(?i)^rfc[ -]?([0-9]+)$", tag)
            if isrfc:
                rfcnum = isrfc.group(1)
                if tag in reference:
                    return """%s%s<a href="%s?%srfc=%s" title='%s'>%s</a>%s""" % (pre, beg, script, extra, rfcnum, cgi.escape(reference[tag]), tag, end)
                else:
                    return """%s%s<a href="%s?%srfc=%s">%s</a>%s""" % (pre, beg, script, extra, rfcnum , tag, end)
            else:
                if tag in ref_targets:
                    if tag in reference:
                        return """%s%s<a href="#ref-%s" title='%s'>%s</a>%s""" % (pre, beg, tag, cgi.escape(reference[tag]), tag, end)
                    else:
                        return """%s%s<a href="#ref-%s">%s</a>%s""" % (pre, beg, tag, tag, end)
                else:
                    return match.group(0)

        # Group:       1   2   3        45
        data = re.sub("(\W)(\[)([-\w.]+)((, ?[-\w.]+)*\])", reference_replacement, data)
        data = re.sub("(\W)(\[)(RFC [0-9]+)((, ?RFC [0-9]+)*\])", reference_replacement, data)
        while True:
            old = data
            data = re.sub("(\W)(\[(?:<a.*?>.*?</a>, ?)+)([-\w.]+)((, ?[-\w.]+)*\])", reference_replacement, data)
            if data == old:
                break
        while True:
            old = data
            data = re.sub("(\W)(\[(?:<a.*?>.*?</a>, ?)+)(RFC [-\w.]+)((, ?RFC [-\w.]+)*\])", reference_replacement, data)
            if data == old:
                break

	# greying out the page headers and footers
	data = re.sub("\n(.+\[Page \w+\])\n\f\n(.+)\n", """\n<span class="grey">\g<1></span>\n\f\n<span class="grey">\g<2></span>\n""", data)

        # contents link markup: section links
        #                   1    2   3        4        5        6         7
        data = re.sub("(?m)^(\s*)(\d+(\.\d+)*)(\.?[ ]+)(.*[^ .])( *\. ?\.)(.*[0-9])$", """\g<1><a href="#section-\g<2>">\g<2></a>\g<4>\g<5>\g<6>\g<7>""", data)
        data = re.sub("(?m)^(\s*)(Appendix |)([A-Z](\.\d+)*)(\.?[ ]+)(.*[^ .])( *\. ?\.)(.*[0-9])$", """\g<1><a href="#appendix-\g<3>">\g<2>\g<3></a>\g<5>\g<6>\g<7>\g<8>""", data)

        # page number markup
        multidoc_separator = "========================================================================"
        if re.search(multidoc_separator, data):
            parts = re.split(multidoc_separator, data)
            for i in range(len(parts)):
                parts[i] = re.sub("(?si)(\f)([^\f]*\[Page (\w+)\])", "\g<1><a name=\"%(page)s-\g<3>\" id=\"%(page)s-\g<3>\" href=\"#%(page)s-\g<3>\" class=\"invisible\"> </a>\g<2>"%{"page": "page-%s"%(i+1)}, parts[i])
                parts[i] = re.sub("(?i)(\. ?\. *)([0-9ivxlc]+)( *\n)", "\g<1><a href=\"#%(page)s-\g<2>\">\g<2></a>\g<3>"%{"page": "page-%s"%(i+1)}, parts[i])
            data = multidoc_separator.join(parts)
        else:
            # page name tag markup
            data = re.sub("(?si)(\f)([^\f]*\[Page (\w+)\])", "\g<1><a name=\"page-\g<3>\" id=\"page-\g<3>\" href=\"#page-\g<3>\" class=\"invisible\"> </a>\g<2>", data)
            # contents link markup: page numbers
            data = re.sub("(?i)(\. ?\. *)([0-9ivxlc]+)( *\n)", "\g<1><a href=\"#page-\g<2>\">\g<2></a>\g<3>", data)

        # section number tag markup
        def section_anchor_replacement(match):
            # exclude TOC entries
            mstring = match.group(0)
            if " \. \. " in mstring or "\.\.\." in mstring:
                return mstring

            level = len(re.findall("[^\.]+", match.group(1)))+1
	    if level > 6:
		level = 6
	    return """<span class="h%s"><a name=\"section-%s\">%s</a>%s</span>""" % (level, match.group(1), match.group(1), match.group(3))

        data = re.sub("(?im)^(\d+(\.\d+)*)(\.?[ ].*)$", section_anchor_replacement, data)
	#data = re.sub("(?i)(\n *\n *)(\d+(\.\d+)*)(\.?[ ].*)", section_replacement, data)
	# section number link markup
        data = re.sub("(?i)(section\s)(\d+(\.\d+)*)", "<a href=\"#section-\g<2>\">\g<1>\g<2></a>", data)
        data = re.sub("(?i)(section)\n(\s+)(\d+(\.\d+)*)", "<a href=\"#section-\g<3>\">\g<1></a>\n\g<2><a href=\"#section-\g<3>\">\g<3></a>", data)

        while True:
            old = data
            data = re.sub("(?i)(sections\s(<a.*?>.*?</a>(,\s|\s?-\s?|\sthrough\s|\sor\s|\sto\s|,?\sand\s))*)(\d+(\.\d+)*)", "\g<1><a href=\"#section-\g<4>\">\g<4></a>", data)
            if data == old:
                break

#        # section x of draft-y markup
#        data = re.sub("(?i)<a href=\"[^\"]*\">(section)\s(\d+(\.\d+)*)</a>(\s+(of|in)\s+)<a href=\"[^\"]*\">(draft-[-.a-zA-Z0-9]+[a-zA-Z0-9])</a>", "<a href=\"%s?%surl=%s/rfc\g<7>.txt#section-\g<2>\">\g<1>&nbsp;\g<2>\g<4>\g<6>\g<7></a>" % (script, extra, rfcs), data)
#        # draft-y, section x markup
#        data = re.sub("(?i)<a href=\"[^\"]*\">(draft-[-.a-zA-Z0-9]+[a-zA-Z0-9])</a>(,?\s)<a href=\"[^\"]*\">(section)\s(\d+(\.\d+)*)</a>", "<a href=\"%s?%surl=%s/rfc\g<2>.txt#section-\g<5>\">\g<1>\g<2>\g<3>\g<4>&nbsp;\g<5></a>" % (script, extra, rfcs), data)
#        # [draft-y], section x markup
#        data = re.sub("(?i)\[<a href=\"[^>\"]+\">(draft-[-.a-zA-Z0-9]+[a-zA-Z0-9])</a>\](,?\s)<a href=\"[^>\"]*\">(section)\s(\d+(\.\d+)*)</a>", "<a href=\"%s?%surl=%s/rfc\g<2>.txt#section-\g<5>\">[\g<1>\g<2>]\g<3>\g<4>&nbsp;\g<5></a>" % (script, extra, rfcs), data)

        # section x of rfc y markup
	data = re.sub("(?i)<a href=\"[^\"]*\"[^>]*>(section)\s(\d+(\.\d+)*)</a>(\s+(of|in)\s+)<a href=\"[^\"]*\"[^>]*>(rfc[- ]?)([0-9]+)</a>",
            "<a href=\"%s?%srfc=\g<7>#section-\g<2>\">\g<1>&nbsp;\g<2>\g<4>\g<6>\g<7></a>" % (script, extra), data)
	data = re.sub("(?i)<a href=\"[^\"]*\"[^>]*>(section)\s(\d+(\.\d+)*)</a>(\s+(of|in)\s+)<a href=\"[^\"]*\"[^>]*>(bcp[- ]?)([0-9]+)</a>",
            "<a href=\"%s?%sbcp=\g<7>#section-\g<2>\">\g<1>&nbsp;\g<2>\g<4>\g<6>\g<7></a>" % (script, extra), data)
        # rfc y, section x markup
	data = re.sub("(?i)<a href=\"[^\"]*\"[^>]*>(rfc[- ]?)([0-9]+)</a>(,?\s+)<a href=\"[^\"]*\"[^>]*>(section)\s(\d+(\.\d+)*)</a>",
            "<a href=\"%s?%srfc=\g<2>#section-\g<5>\">\g<1>\g<2>\g<3>\g<4>&nbsp;\g<5></a>" % (script, extra), data)
	data = re.sub("(?i)<a href=\"[^\"]*\"[^>]*>(bcp[- ]?)([0-9]+)</a>(,?\s+)<a href=\"[^\"]*\"[^>]*>(section)\s(\d+(\.\d+)*)</a>",
            "<a href=\"%s?%sbcp=\g<2>#section-\g<5>\">\g<1>\g<2>\g<3>\g<4>&nbsp;\g<5></a>" % (script, extra), data)
        # section x of? [rfc y] markup
	data = re.sub("(?i)<a href=\"[^\"]*\"[^>]*>(section)\s(\d+(\.\d+)*)</a>(\s+(of\s+|in\s+)?)\[<a href=\"[^\"]*\"[^>]*>(rfc[- ]?)([0-9]+)</a>\]",
            "<a href=\"%s?%srfc=\g<7>#section-\g<2>\">\g<1>&nbsp;\g<2>\g<4>[\g<6>\g<7>]</a>" % (script, extra), data)
	data = re.sub("(?i)<a href=\"[^\"]*\"[^>]*>(section)\s(\d+(\.\d+)*)</a>(\s+(of\s+|in\s+)?)\[<a href=\"[^\"]*\"[^>]*>(bcp[- ]?)([0-9]+)</a>\]",
            "<a href=\"%s?%sbcp=\g<7>#section-\g<2>\">\g<1>&nbsp;\g<2>\g<4>[\g<6>\g<7>]</a>" % (script, extra), data)
        # [rfc y], section x markup
	data = re.sub("(?i)\[<a href=\"[^>\"]+\"[^>]*>(rfc[- ]?)([0-9]+)</a>\](,?\s+)<a href=\"[^>\"]*\"[^>]*>(section)\s(\d+(\.\d+)*)</a>",
            "<a href=\"%s?%srfc=\g<2>#section-\g<5>\">[\g<1>\g<2>]\g<3>\g<4>&nbsp;\g<5></a>" % (script, extra), data)
	data = re.sub("(?i)\[<a href=\"[^>\"]+\"[^>]*>(bcp[- ]?)([0-9]+)</a>\](,?\s+)<a href=\"[^>\"]*\"[^>]*>(section)\s(\d+(\.\d+)*)</a>",
            "<a href=\"%s?%sbcp=\g<2>#section-\g<5>\">[\g<1>\g<2>]\g<3>\g<4>&nbsp;\g<5></a>" % (script, extra), data)

        # remove section link for section x.x (of|in) <something else>
        old = data
	data = re.sub("(?i)<a href=\"[^\"]*\"[^>]*>(section\s)(\d+(\.\d+)*)</a>(\s+(of|in)\s+)(\[?)<a href=\"([^\"]*)\"([^>]*)>(.*)</a>(\]?)",
            '\g<1>\g<2>\g<4>\g<6><a href="\g<7>"\g<8>>\g<9></a>\g<10>', data)
	data = re.sub('(?i)(\[?)<a href="([^"]*)"([^>]*)>(.*?)</a>(\]?,\s+)<a href="[^"]*"[^>]*>(section\s)(\d+(\.\d+)*)</a>',
            '\g<1><a href="\g<2>"\g<3>>\g<4></a>\g<5>\g<6>\g<7>', data)


#         # remove section link for <something>], section x.x
# 	data = re.sub("(?i)     \[<a href=\"([^\"]*)\"([^>]*)>(.*)</a>\]        <a href=\"[^\"]*\"[^>]*>(section)\s(\d+(\.\d+)*)</a>",
#             "\g<1>&nbsp;\g<2>\g<4><a href=\"\g<6>\"\g<7>>[\g<8>]</a>", data)

        # appendix number tag markup
        def appendix_replacement(match):
            # exclude TOC entries
            mstring = match.group(0)
            if " \. \. " in mstring or "\.\.\." in mstring:
                return mstring

            level = len(re.findall("[^\.]+", match.group(1)))+1
	    if level > 6:
		level = 6
	    return """<span class="h%s"><a name=\"appendix-%s\">%s%s</a>%s</span>""" % (level, match.group(2), match.group(1), match.group(2), match.group(4))

        data = re.sub("(?m)^(Appendix |)([A-Z](\.\d+)*)(\.?[ ].*)$", appendix_replacement, data)
	#data = re.sub("(?i)(\n *\n *)(\d+(\.\d+)*)(\.?[ ].*)", appendix_replacement, data)
	# appendix number link markup                          
        data = re.sub(" ([Aa]ppendix\s)([A-Z](\.\d+)*)", " <a href=\"#appendix-\g<2>\">\g<1>\g<2></a>", data)

        # comment markup
        colorcount = 0
        for tag in tags:
            color = colors[colorcount%len(colors)]
            colorcount += 1
            data = re.sub("(?sm)^(%s.*?)(\n *)$"%tag, "<span style=\"color: %s\">\g<1></span>\g<2>"%color, data)

	#
        #data = re.sub("\f", "<div class=\"newpage\" />", data)
        data = re.sub("\f", "</pre><pre class='newpage'>", data)

        # restore indentation
        if prefixlen:
            data = re.sub("\n", "\n"+(" "*prefixlen), data)

	if optstatic:
	    data = re.sub("%s\?(rfc|bcp|std)=" % script, "./\g<1>", data)
	    data = re.sub("%s\?draft=" % script, "./", data)

	# output modified data
        prelude(optstatic)
        if optmenu:
            if draftname:
                args["draftname"] = draftname
                args["nitsmenu"] = nitsmenu % args
                if os.path.exists("/www/tools.ietf.org/id/%s.html"%(draftname)):
                    args["htmllink"] = htmllink % args
            if draftname and (draftname[-2:] != "00" or re.match(".*-(rfc)?[0-9][0-9][0-9]+bis-.*", draftname) or "docreplaces" in attribs):
                args["diffmenu"] = diffmenu % args
            if charter:
                args["diffmenu"] = diffmenu % args
            if rfc and "document" in attribs:
                if "docreplaces" in attribs:
                    #args["doc"] = "%s/rfc%s.txt&amp;url1=%s" % (rfcs, rfc, attribs["docreplaces"])
                    pass
                args["diffmenu"] = diffmenu % args
            if wgname:
                args["wgmenu"] = wgmenu % args
            if draftname:
                args["base"] = draftname[:-3]
                args["emailmenu"] = emailmenu % args
                if "docwg" in attribs and (attribs["docwg"] != 'none'):
                    args["wg"] = attribs["docwg"]
                    args["wgmenu"] = wgmenu % args
            if "docipr" in attribs:
                if draftname:
                    args["base"] = draftname[:-3]
                    args["iprmenu"] = draftiprmenu % args
                else:
                    args["rfc"] = rfc
                    args["iprmenu"] = rfciprmenu % args
            args["padding"] = " "*(72 - len(re.sub("<.*?>", "", (topmenu % args))))
            sys.stdout.write(topmenu % args)
        if args["docinfo"]:
            sys.stdout.write(docinfo % args)
	print data
        postlude()

if __name__ == "__main__":
    if "--version" in sys.argv:
        print "%(script)s\t%(version)s" % args
        sys.exit()
    if "--help" in sys.argv:
        usage()
        sys.exit()

    markup()
