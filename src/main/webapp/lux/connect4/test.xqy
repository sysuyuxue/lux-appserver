xquery version "1.0";

declare namespace c4="http://falutin.net/connect4";

import module namespace util="http://falutin.net/connect4/util" at "util.xqy";
import module namespace layout="http://falutin.net/connect4/layout" at "layout.xqy";
import module namespace c4a="http://falutin.net/connect4/analysis" at "analysis.xqy";

declare variable $lux:http as document-node() external;

declare function c4:test ()
{
  let $game-id := util:param ($lux:http, 'game')
  let $game := collection()/game[@id=$game-id]
  let $inigo-grid := c4a:inigo-grid($game, $game//player[2])
  return layout:outer('/connect4/test.xqy', 
    c4a:draw-vezzini ($game, $game//player[2])
    <div>{
      for $i in (1 to 7) return
        c4a:draw-vezzini-grid ($game)
    }</div>
(:    
    <textarea rows="24" cols="80">{ 
    $inigo-grid
                                  } </textarea>
:)
                )
};


c4:test()