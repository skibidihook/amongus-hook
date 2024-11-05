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


            local relay = [[
                  local bindableEvent = game:GetService('CoreGui'):FindFirstChild('actor_reply');
                  if (not bindableEvent) then
                        return;
                  end;
                  bindableEvent:Fire('success');
            ]];
            -- hotfix
            do
                  
                  local bindableEvent = Instance.new('BindableEvent');
                  bindableEvent.Name = 'actor_reply';
                  bindableEvent.Parent = game:GetService('CoreGui');

                  local success;
                  local connection;
                  connection = bindableEvent.Event:Connect(function(...)
                        if (... ~= 'success') then
                              return;
                        end;
                        success = true;
                        connection:Disconnect();
                  end);

                  task.delay(3, function()
                        if (not success) then
                              loadstring(source)();
                        end;
                  end);

            end;

            return run_on_actor(actor, relay..source);
      end;
end;
loadstring(source)();
