local players           = game:GetService('Players');
local localplayer       = players.LocalPlayer;
if (not localplayer) then
      players:GetPropertyChangedSignal('LocalPlayer'):Wait();
      localplayer = players.LocalPlayer;
end;

local source = game:HttpGet('https://raw.githubusercontent.com/mainstreamed/amongus-hook/refs/heads/main/tridentsurvival/obfuscated.lua');

if (run_on_actor) then
      local actor = getactors and getactors()[1] or localplayer:FindFirstChildWhichIsA('Actor', true);
      if (actor) then
            return run_on_actor(actor, source);
      end;
end;
loadstring(source)();
