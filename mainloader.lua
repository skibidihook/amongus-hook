if not game:IsLoaded() then
	game.Loaded:Wait()
end;

local messagebox = messagebox or function(message, title, id) warn(`[{title} - {message}`); return 6; end;
local request = request or http_request;
local loadstring = loadstring;

if (not request) then
	return messagebox('request function is unsupported!', 'amongus.hook', 48);
elseif (not loadstring) then
	return messagebox('loadstring function is unsupported!', 'amongus.hook', 48);
elseif (not Drawing) then
	loadstring(game:HttpGet("https://raw.githubusercontent.com/mainstreamed/amongus-hook/refs/heads/main/drawingfix.lua"))(); -- fuck you wave!!!
end;
	
local placeid = game.PlaceId;
local dir = 'https://raw.githubusercontent.com/mainstreamed/amongus-hook/main/';

local statuslist = {
	['fallensurvival'] = {
		name = 'Fallen Survival',
		status = 'Undetected',
	},
	['tridentsurvival'] = {
		name = 'Trident Survival',
		status = 'Detected',
	},
};

local load = function(name)
	local game = statuslist[name];
	if (game.status ~= 'Undetected') then
		if (messagebox(`{game.name} is Currently Marked as {game.status}!\n\nAre You Sure You Want to Continue?`, `amongus.hook`, 52) ~= 6) then
			return;
		end;
	end;
	loadstring(request({Url=`{dir}{name}/main.lua`,Method='GET'}).Body)();
end;

if (placeid == 13253735473) then
	return load('tridentsurvival');
elseif (placeid == 13800717766 or placeid == 15479377118) then
	return load('fallensurvival');
end;
messagebox(`This Game is Unsupported!\n\nIf you believe this is incorrect, please open a ticket in our discord! - discord.gg/2jycAcKvdw`, `amongus.hook [{placeid}]`, 48);
