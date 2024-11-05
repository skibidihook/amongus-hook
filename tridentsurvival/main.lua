-- p100 actor functionality

local source = game:HttpGet('https://raw.githubusercontent.com/mainstreamed/amongus-hook/refs/heads/main/tridentsurvival/obfuscated.lua');
local actor_functionality = run_on_actor and getactors;

if (actor_functionality) then
      return run_on_actor(getactors()[1], source);
end;
loadstring(source)();
