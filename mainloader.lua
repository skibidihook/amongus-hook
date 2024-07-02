if not game:IsLoaded() then
	game.Loaded:Wait()
end;

if (identifyexecutor() ~= 'Wave') then
    return warn('You are running a unsupported executor!');
end;

local messagebox = messagebox or function(title, message, id) warn(`[{title} - {message}`);end;
local request = request or http_request;
local loadstring = loadstring;

if (not request) then
	return error('request function is unsupported!');
elseif (not loadstring) then
	return error('loadstring function is unsupported!');
end;

local placeid = game.PlaceId;
local dir = 'https://raw.githubusercontent.com/mainstreamed/amongus-hook/main/';

local statuslist = {
	['fallensurvival'] = {
		name = 'Fallen Survival',
		status = 'Detected',
	},
	['tridentsurvival'] = {
		name = 'Trident Survival',
		status = 'Undetected',
	},
};

local load = function(name)
	local game = statuslist[name];
	if (game.status ~= 'Undetected') then
		if (messagebox(`amongus.hook`, `{game.name} is Currently Marked as {game.status}!\n\nAre You Sure You Want to Continue?`, 52) ~= 6) then
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
messagebox(`amongus.hook [{placeid}]`, `This Game is Unsupported!\n\nIf you believe this is incorrect, please open a ticket in our discord! - discord.gg/2jycAcKvdw`, 48);
