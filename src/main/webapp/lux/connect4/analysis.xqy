xquery version "1.0";

module namespace c4a="http://falutin.net/connect4/analysis";

declare variable $c4a:dirs as element(dirs) := <dirs>
  <dir x="1" y="0" />,
  <dir x="0" y="1" />,
  <dir x="1" y="-1" />,
  <dir x="1" y="1" />
</dirs>;

declare variable $c4a:dirpairs as element(dirs) := 
<dirs>
  <pair>
  <dir x="1" y="0" />
  <dir x="-1" y="0" />
  </pair><pair>
  <dir x="0" y="1" />
  <dir x="0" y="-1" />
  </pair><pair>
  <dir x="1" y="-1" />
  <dir x="-1" y="1" />
  </pair><pair>
  <dir x="1" y="1" />
  <dir x="-1" y="-1" />
  </pair>
</dirs>;

declare variable $c4a:inigo-scores := (0, 1, 10, 100);

declare function c4a:get-cell ($game, $row, $col)
{
  $game/grid/row[$row]/cell[$col]
};

declare function c4a:count-run ($game as element(game), $row, $col, $cell, $len, $dir)
  as xs:integer
{
  let $y1 := $row + $dir/@y
  let $x1 := $col + $dir/@x
  let $nabor := c4a:get-cell ($game, $y1, $x1)
  return 
    if ($nabor = $cell and string($cell))
      then c4a:count-run ($game, $y1, $x1, $nabor, $len + 1, $dir)
    else
      $len
};

declare function c4a:check-cell ($game as element(game), $row, $col, $cell, $len, $dir)
  as xs:string?
{
  if (c4a:count-run($game, $row, $col, $cell, $len, $dir) >= 4)
    then $cell
  else 
    ()
};

declare function c4a:compute-winner ($game as element(game))
{
  for $row in (1 to 7), $col in (1 to 6), $dir in $c4a:dirs//dir
  let $cell := c4a:get-cell ($game, $row, $col)
  return c4a:check-cell ($game, $row, $col, $cell, 1, $dir)
};

declare function c4a:check-game ($game as element(game))
  as element(game)
{
  let $winner := c4a:compute-winner ($game)
  return 
    if (count($winner) > 0) then
      <game winner="{$winner[1]}">{$game/@*, $game/*}</game>
    else 
      $game
};

declare function c4a:draw-grid ($game as element(game)?)
{
<table class="c4grid">{
  for $row in $game/grid/row
  return <tr>{
  for $cell at $i in $row/cell return
  <td class="circle" col="{$i}">{
    let $color := $cell/string()
    where $color 
    return attribute style { concat ("background: ", $color, ";") }
  }</td>
  }</tr>
}</table>
};

declare function c4a:draw-inigo-grid ($grid as element(grid)?)
{
<table class="c4grid">{
  for $row at $j in $grid/row
  return <tr>{
  for $cell at $i in $row/cell return
  <td class="circle" col="{$i}">{
    if ($cell/@playable) then 
    attribute style {"background: #0f0;" } else (),
    string($cell/@score)
  }</td>
  }</tr>
}</table>
};

declare function c4a:draw-vezzini ($game as element(game)?, $player)
{
<table class="c4grid">{
  <tr>{
    for $vs in c4a:vezzini-scores($game, $player, 1) return
    <th>{$vs}</th>
  }</tr>,
  for $row at $j in $game/grid/row
  return <tr>{
  for $cell at $i in $row/cell return
  <td class="circle" col="{$i}">{
    let $color := $cell/string()
    where $color 
    return attribute style { concat ("background: ", $color, ";") }
  }</td>
  }</tr>
}</table>
};

declare function c4a:place-circle (
  $game as element(game), 
  $player as element(player), 
  $col as xs:integer)
as element (game)
{
  let $updated-game := c4a:update-game ($game, $player, $col)
  let $checked-game := c4a:check-game ($updated-game)
  let $insert := (
    lux:insert (concat('/connect4/', $game/@id), $checked-game),
    lux:commit())
  return ($checked-game, lux:log(($insert,"hey")[1], "info"))
};

declare function c4a:update-game (
  $game as element(game), 
  $player as element(player), 
  $col as xs:integer)
as element (game)
{
  (: should always = 1 :)
  let $iplayer := count ($game/players/player[. << $player]) + 1
  let $selected := ($game/grid/row/cell[$col][empty(node())])[last()]
  return if (not($selected)) 
    then 
    <game status="error">There's no space left in that column - try again</game> 
  else
  <game>{
    $game/@id, 
    attribute modified { current-dateTime() },
    (: shift player to the end of the queue :)
    <players>{
      $game/players/player[not(position() eq $iplayer)],
      $player
    }</players>,
    <grid>{
      for $row in $game/grid/row return
      <row>{
        for $cell in $row/cell return
          if ($cell is $selected) 
            then <cell>{$player/@color/string()}</cell>
          else $cell
      }</row>
    }</grid>
  }</game>
};

declare function c4a:run-dir-length ($game, $x, $y, $dirpair, $color){
  let $fake-cell := element cell { $color }
  return
    c4a:count-run($game, $y, $x, $fake-cell, 0, $dirpair/dir[1]) +
    c4a:count-run($game, $y, $x, $fake-cell, 0, $dirpair/dir[2]) 
};

declare function c4a:inigo-cell-color-score ($game, $x, $y, $color) {
  max (for $pair as element (pair) in $c4a:dirpairs//pair 
  return c4a:run-dir-length ($game, $x, $y, $pair, $color))
};

declare function c4a:inigo-cell-score($game, $x, $y, $player) {
  let $my-color := string ($game//player[. is $player]/@color)
  let $other-color := string ($game//player[not(. is $player)]/@color)
  let $inigo-score := c4a:inigo-cell-color-score ($game, $x, $y, $my-color)
  let $other-score := c4a:inigo-cell-color-score ($game, $x, $y, $other-color)
  return $c4a:inigo-scores[$inigo-score+1] + ($c4a:inigo-scores[$other-score+1] div 2)
};

declare function c4a:inigo-grid($game, $player)
{
  element grid {
    for $row at $y in $game/grid/row 
    return ( "&#xa;",
      element row {
        for $cell at $x in $row/cell
        return
          element cell {
            if ($cell != '') 
              then ()
            else (
              attribute score {c4a:inigo-cell-score($game, $x, $y, $player)},
              let $below := c4a:get-cell($game, $y+1, $x)
              return if (not ($below) or $below != '') then attribute playable {'true'} else ()
            )
          }
      })
  }
};

(: return the (score, column index) of the move with the max score,
   calling vezzini-score to get them :)
declare function c4a:vezzini-max($game, $player, $depth)
{
  let $scores := c4a:vezzini-scores ($game, $player, $depth)
  let $max := max ($scores)
  return ($max, (for $s at $i in $scores where $s = $max return $i)[1])
};

(: return the scores of each move by playing the move and calling vezzini-score :)
declare function c4a:vezzini-scores($game, $player, $depth)
  as xs:double+
{
  for $col in (1 to count($game//row[1]/cell))
    let $new-game := c4a:update-game ($game, $player, $col)
    return if ($new-game[@status="error"]) 
      then 0 
    else
      c4a:vezzini-score ($new-game, $game//player[not(. is $player)], $depth + 1)
};

(: return the score of the move with the max score, terminating 
   at max-depth, or end of game
 :)
declare function c4a:vezzini-score($game, $player, $depth)
  as xs:double
{
  let $grid := c4a:inigo-grid($game, $game/players/player[1])
  let $max-score := max ($grid//cell[@playable]/@score)
  let $sgn := if ($depth mod 2 eq 1) then 1 else -1
  return if ($depth ge 3 or $max-score ge 100) 
    then $sgn * $max-score
  else
    c4a:vezzini-max ($game, $player, $depth)[1]
};

declare function c4a:vezzini($game)
{
  let $vz := $game/players/player[1]
  let $move := c4a:vezzini-max ($game, $vz, 1)
  let $col := $move[2]
  return c4a:place-circle ($game, $vz, $col)
};

declare function c4a:inigo ($game)
{
  let $grid := c4a:inigo-grid($game, $game/players/player[1])
  let $play := (for $cell in $grid//cell[@playable]
  order by $cell/@score descending
  return $cell)[1]
  let $col := count($play/preceding-sibling::cell) + 1
  return c4a:place-circle ($game, $game/players/player[1], $col)
};

declare function c4a:fezzik ($game)
{
  let $cell := ($game//cell[.=''])[1]
  let $col := count ($cell/preceding-sibling::cell) + 1
  return c4a:place-circle ($game, $game/players/player[1], $col)
};

declare function c4a:is-bot($player)
{
  $player = ("fezzik", "inigo", "vezzini")
};

declare function c4a:bot-play ($game)
{
  let $bot := $game/players/player[1]
  where c4a:is-bot($bot) and not ($game/@winner)
  return if ($bot = "fezzik") 
    then c4a:fezzik ($game)
  else if ($bot = "inigo")
    then c4a:inigo ($game)
  else if ($bot = "vezzini")
    then c4a:vezzini ($game)
  else c4a:fezzik ($game)
};

