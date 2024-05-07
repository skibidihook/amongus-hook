local mt                      = getrawmetatable(Drawing.new('Square'));
local getrenderproperty       = clonefunction(mt.__index);
local setrenderproperty       = clonefunction(mt.__newindex);
local drawing_new             = clonefunction(Drawing.new);
local run_on_actor            = clonefunction(run_on_actor);
local typeof                  = clonefunction(typeof);
local type                    = clonefunction(type);
local error                   = clonefunction(error);
-- drawing fix setup
local cache = {
      drawings = {},
      index = 0,
};
local id, event = create_comm_channel();
local fire = clonefunction(event.Fire);
-- comm channel handler
do
      local main_connection = function(...)
            local args = {...};
            if (args[1] ~= 'parallel') then
                  return;
            end;

            local action, id, index, value = args[2], args[3], args[4], args[5];
            if (action == 'index') then
                  fire(event, 'serial', getrenderproperty(cache.drawings[id], index));
            elseif (action == 'new') then
                  cache.index += 1;
                  fire(event, 'serial', cache.index);
                  cache.drawings[cache.index] = drawing_new(id, index);
            elseif (action == 'remove') then
                  cache.drawings[id]:Remove();
            elseif (action == 'newindex') then
                  if (index == 'Font' and typeof(value) == 'Vector2') then
                        value = cache.drawings[value.X];
                  end;
                  cache.drawings[id][index] = value;
            end;
      end;
      event.Event:Connect(main_connection);
end;
local run_on_actor_fix = function(actor, string, ...)
      string = [[
            local Drawing = Drawing;
            local setfpscap = setfpscap;
            do 
                  local g_env = getgenv();
                  local reg = {};

                  local log;
                  local newuserdata       = Vector2.new;
                  local event             = get_comm_channel(0);
                  local fire              = clonefunction(event.Fire);
                  local getnamecallmethod = clonefunction(getnamecallmethod);
                  local setrawmetatable   = clonefunction(setrawmetatable);
                  local setfflag          = clonefunction(setfflag);

                  local typeof            = clonefunction(typeof);
                  local type              = clonefunction(type);
                  local error             = clonefunction(error);
                  local connections       = {};

                  local getlog = function()
                        local logged = log;
                        log = nil;
                        return logged;
                  end;
                  local main_connection = function(...)
                        local args = {...};
                        if (args[1] == 'serial') then
                              log = args[2];
                        end;
                  end;

                  event.Event:Connect(main_connection);

                  -- changing vars
                  do
                        Drawing = {
                              new = function(...)
                                    fire(event, 'parallel', 'new', ...);
                                    local draw_id = getlog();
                                    local userdata = newuserdata(draw_id, 0);
                                    local mt = {
                                          __type = 'DrawingObject',
                                          __index = function(self, index)
                                                fire(event, 'parallel', 'index', draw_id, index);
                                                return getlog();
                                          end,
                                          __newindex = function(self, index, value)
                                                fire(event, 'parallel', 'newindex', draw_id, index, value);
                                          end,
                                          __namecall = function(self, ...)
                                                local method = getnamecallmethod();
                                                if (method == 'Remove' or method == 'Destroy') then
                                                      fire(event, 'parallel', 'remove', draw_id);
                                                end;
                                          end,
                                    };
                                    setrawmetatable(userdata, mt);
                                    return userdata;
                              end,
                              Fonts = {UI = 0, System = 1, Plex = 2, Monospace = 3},
                        };
                        setfpscap = function(fpscap)
                              if (type(fpscap) ~= 'number') then
                                    return error(`invalid argument #1 (number expected, got {typeof(fpscap)})`);
                              end;
                              setfflag('TaskSchedulerTargetFps', fpscap);
                        end;

                        g_env.Drawing = Drawing;
                        g_env.setfpscap = setfpscap;
                  end;

            end;
      ]]..string;
      return run_on_actor(actor, string, ...);
end;

if (getfflag('DebugRunParallelLuaOnMainThread') == 'true') then
      return messagebox('amongus.hook', 'Please DO NOT use the Actor Bypass!\n\nReopen Roblox to be able to use amongus.hook', 48)
end;

run_on_actor_fix(getactors()[1], request({Url=`https://raw.githubusercontent.com/mainstreamed/amongus-hook/main/tridentsurvival/obfuscated.lua`,Method='GET'}).Body);
