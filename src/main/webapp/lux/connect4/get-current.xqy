xquery version "1.0";

declare namespace c4="http://falutin.net/connect4";
import module namespace util="http://falutin.net/connect4/util" at "util.xqy";

declare variable $lux:http as document-node() external;

let $game-id := util:param ($lux:http, 'game')
let $game as element(game) := collection()/game[@id=$game-id]
where $game/players/player[2] and not($game/@winner)
return $game/players/player[1]/string()
