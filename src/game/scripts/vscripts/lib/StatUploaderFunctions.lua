require('lib/StatUploader')
local isTest = true
local steamIDs;

ListenToGameEvent('game_rules_state_change', 
  function(keys)
    local state = GameRules:State_Get()

    if state == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
      SU:Init()
    end
  end, nil)

function SU:BuildSteamIDArray()
    local players = {}
    for playerID = 0, DOTA_MAX_PLAYERS do
      if PlayerResource:IsValidPlayerID(playerID) then
        if not PlayerResource:IsBroadcaster(playerID) then
          table.insert(players, PlayerResource:GetSteamAccountID(playerID))
        end
      end
    end

    return players
end

function SU:Init()
  steamIDs = SU:BuildSteamIDArray()
  DeepPrintTable(steamIDs)
  
  if SU.StatSettings ~= nil then
    if isTest or (not GameRules:IsCheatMode()) then
      ListenToGameEvent('game_rules_state_change', 
        function(keys)
          local state = GameRules:State_Get()

          if state == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
            SU:SendAuthInfo()
          elseif state == DOTA_GAMERULES_STATE_PRE_GAME then
            SU:LoadPlayersMessages()
          end
        end, nil)
    else
      print("Bad stat recording conditions.")
    end    
  else
    print("StatUploader settings file not found.")
  end
end

function SU:LoadPlayersMessages()
  local requestParams = {
    Command = "LoadPlayersMessages",
    SteamIDs = steamIDs
  }
    
  SU:SendRequest( requestParams, function(obj)
    if type(obj) == "string" then
      print(obj)
      return
    end
      
    for playerID = 0, DOTA_MAX_PLAYERS do
      if PlayerResource:IsValidPlayerID(playerID) then
        if not PlayerResource:IsBroadcaster(playerID) then
          local steamID = PlayerResource:GetSteamAccountID(playerID)
          local messages = table.filter(obj, function(k, v, obj)
            return v.SteamID == tostring(steamID)
          end)

          CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "su_new_messages", messages )
        end
      end
    end 
  end)
end