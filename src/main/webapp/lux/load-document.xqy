declare namespace file="http://expath.org/ns/file";
declare namespace demo="http://luxdb.net/demo";

import module namespace http="http://expath.org/ns/http-client";

declare variable $lux:http as document-node() external;

declare function demo:load-from-http ($url as xs:string)
  as document-node()
{
  let $request := <http:request method="get" href="{$url}" />
  let $response := http:send-request ($request)
  let $log := lux:log (concat("title=", $response[2]/descendant::TITLE[1]), "debug")
  return ($log, $response[2])
};

declare function demo:load-url ($url as xs:string)
as xs:string*
{
    let $doc as document-node()? := if (starts-with($url, "http:")) then
      demo:load-from-http ($url)
    else if (starts-with ($url, "file:")) then
      doc ($url)
    else
      doc (concat("file:", $url))
    let $doctype as xs:string := name($doc/*)
    let $load-xsl as xs:string := concat ("file:", $doctype, "-load.xsl")
    return if (doc-available ($load-xsl)) then
      demo:transform-load ($url, $doc, doc($load-xsl))
    else
      demo:default-load ($url, $doc)
};

declare function demo:transform-load ($url as xs:string, $doc as document-node(), $xsl as document-node())
  as xs:string
{
    let $basename := replace($url, "^.*/(.*)(\.(ht|x)ml)?", "$1")
    let $uri := concat ("/", $basename, ".xml")
    let $uri2 := concat ($uri, lux:log(("insert transformed ", $uri), "debug"))
    let $transformed := lux:transform ($xsl, $doc, ("uri-base", $basename))
    return (lux:insert ($uri, $transformed), $uri2)
};

declare function demo:chunk-words ($basename as xs:string, $i, $words as xs:string*)
{
  let $uri := concat ($basename, "-", $i, ".xml")
  let $e := subsequence($words,1,250)
  let $uri2 := concat ($uri, lux:log(("insert default ", $uri, " ", $e), "debug"))
  return (lux:insert ($uri, <chunk uri="{$uri}">{$e}</chunk>), $uri2,
    if (count($words) gt 250)
      then demo:chunk-words($basename, $i+1, subsequence($words,250)) 
    else ()
  )
};

(:
declare function demo:default-load ($url as xs:string, $doc as document-node())
  as xs:string*
{
    let $basename := "/chunk"
    let $words := tokenize ($doc, "\s+")
    return demo:chunk-words ($basename, 1, $words)
};
:)

declare function demo:default-load ($url as xs:string, $doc as document-node())
{
    let $uri := (substring-after($url, "/exist/rest/db"), substring-after($url, ":/"), $url)[1]
    let $words := tokenize ($doc, "\s+")
    return (lux:insert ($uri, $doc), $uri)
};

declare function demo:load-document ()
  as node()*
{
  let $url := $lux:http/http/params/param[@name='url']/value/string()
  let $loaded := demo:load-url ($url)
  return <li>Loaded {count($loaded)} documents from { $url, lux:commit() }</li>
};

demo:load-document()
