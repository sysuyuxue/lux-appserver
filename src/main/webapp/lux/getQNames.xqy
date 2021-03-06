declare namespace lux="http://luxdb.net";
declare variable $lux:http as document-node() external;

let $query := $lux:http/http/params/param[@name="query"]/value/string()
let $tokens := 
  for $s in subsequence(lux:field-terms("lux_path", $query), 1, 15) 
  where not ($s eq "{}")
  return concat('"', $s, '"')

return
text { '[', string-join ($tokens, ","), ']' }
