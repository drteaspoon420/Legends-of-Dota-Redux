///Changes made to this branch code to decrease testing time

///Pregame.lua - line 3333
local minTime = 3
///to
local minTime = .5

///game_setup.js - line 5263
var showDuration = 3;
///to
var showDuration = .5;

///game_setup.js - line "function buildHeroList() {"
///add below
Game.SetTeamSelectionLocked(true);

///game_setup.js - comment out following lines: 
$('#lodPopupMessage').visible = true;