repeat wait() until game:IsLoaded()

local placeid = game.PlaceId;
local str = "https://raw.githubusercontent.com/mainstreamed/amongus-hook/main/";

if (placeid == 13800717766 or placeid == 15479377118) then
    loadstring(game:HttpGet(str.."fallensurvival/main.lua", true))()
elseif (placeid == 13253735473) then
    loadstring(game:HttpGet(str.."tridentsurvival/main.lua", true))()
elseif (placeid == 292439477) then
    loadstring(game:HttpGet(str.."phantomforces/main.lua"))()
else
    print('Failed to find game! - please open a ticket and send a screenshot ['..tostring(placeid)..'] [discord.gg/2jycAcKvdw]')
end
