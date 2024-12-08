local cloneref          = cloneref or function(...) return ...; end;
local compareinstances  = compareinstances or rawequal;

local runService        = cloneref(game:GetService('RunService'));

local currentCamera     = cloneref(workspace.CurrentCamera);


local createDrawing           = function(_type, properties, ...)
      local drawing = Drawing.new(_type);
      for i, value in properties do
            drawing[i] = value;
      end;
      for _, _table in {...} do
            table.insert(_table, drawing);
      end;
      return drawing;
end;
local getBoundingBox = function(model)
      local cframe, size = model:GetBoundingBox();
      return cframe, Vector3.new(math.min(size.X, 5), math.min(size.Y, 6.7), math.min(size.Z, 5));
end;
local worldToViewPoint = function(position)
      local pos, onscreen = currentCamera:WorldToViewportPoint(position);
      return Vector2.new(pos.X, pos.Y), onscreen, pos.Z;
end;


local playerESP = {
      playerCache = {};
      drawingCache = {};

      childAddedConnections = {};
      childRemovedConnections = {};
};
playerESP.__index = playerESP;

playerESP.onChildAdded = function(_function)
      table.insert(playerESP.childAddedConnections, _function);
end;
playerESP.onChildRemoved = function(_function)
      table.insert(playerESP.childRemovedConnections, _function);
end;
playerESP.new = function(player: Player)
      local self = setmetatable({
            player = player;
            allDrawings = {};
            drawings = nil;
            current = nil;
      }, playerESP);

      local cache = playerESP.drawingCache[1];
      if (cache) then
            table.remove(playerESP.drawingCache, 1);
            
            cache.name.Text = player.DisplayName;

            self.allDrawings = cache.all;
            self.drawings = cache;
      else
            self:createDrawingCache();
      end;

      player.CharacterAdded:Connect(function(...)
            return self:characterAdded(...);
      end);
      player.CharacterRemoving:Connect(function(...)
            return self:characterRemoved(...);
      end);

      if (player.Character) then
            self:characterAdded(player.Character, true);
      end;

      playerESP.playerCache[player] = self;

      return self;
end;
playerESP.remove = function(player: Player)
      local cache = playerESP.playerCache[player];
      playerESP.playerCache[player] = nil;

      table.insert(playerESP.drawingCache, cache.drawings);
end;

function playerESP:createDrawingCache()
      local allDrawings = {};
      local drawings = {
            box = createDrawing('Square', { Visible=false, Thickness=1, Color=Color3.new(1, 1, 1), Filled=false, ZIndex=0 }, allDrawings);
            boxOutline = createDrawing('Square', { Visible=false, Thickness=2, Color=Color3.new(0, 0, 0), Filled=false, ZIndex=-1 }, allDrawings);

            healthBar = createDrawing('Square', { Visible=false, Thickness=1, Filled=true, ZIndex=0 }, allDrawings);
            healthBackground = createDrawing('Square', { Visible=false, Color=Color3.new(0.239215, 0.239215, 0.239215), Transparency=0.7, Thickness=1, Filled=true, ZIndex=-1 }, allDrawings);

            name = createDrawing('Text', {
                  Visible           = false;
                  Center            = true;
                  Outline           = true;
                  OutlineColor      = Color3.new(0, 0, 0);
                  Color             = Color3.new(1, 1, 1);
                  Transparency      = 1;
                  Size              = 13;
                  Text              = self.player.DisplayName;
                  Font              = 1;
                  ZIndex            = 0;
            }, allDrawings);
            distance = createDrawing('Text', {
                  Visible           = false;
                  Center            = true;
                  Outline           = true;
                  OutlineColor      = Color3.new(0, 0, 0);
                  Color             = Color3.new(1, 1, 1);
                  Transparency      = 1;
                  Size              = 13;
                  Font              = 1;
                  ZIndex            = 0;
            }, allDrawings);
            weapon = createDrawing('Text', {
                  Visible           = false;
                  Center            = true;
                  Outline           = true;
                  OutlineColor      = Color3.new(0, 0, 0);
                  Color             = Color3.new(1, 1, 1);
                  Transparency      = 1;
                  Size              = 13;
                  Font              = 1;
                  ZIndex            = 0;
            }, allDrawings);
      };
      drawings.all = allDrawings;

      self.drawings = drawings;
      self.allDrawings = allDrawings;
end;
function playerESP:hideDrawings()
      for i = 1, #self.allDrawings do
            self.allDrawings[i].Visible = false;
      end;
end;

--character functions
function playerESP:setNonActive()
      if (self.current.active == false) then
            return;
      end;
      self.current.active = false;
      for i = 1, #self.allDrawings do
            self.allDrawings[i].Visible = false;
      end;
end;
function playerESP:humanoidHealthChanged()
      local humanoid                = self.current.humanoid;

      local health                  = humanoid.Health;
      local maxHealth               = humanoid.MaxHealth;
      local healthPercentage        = health / maxHealth;

      if (self.current.rootPart and health > 0) then
            self.current.active = true;
      else
            self:setNonActive();
      end;



      self.current.health           = health;
      self.current.maxHealth        = maxHealth;
      self.current.healthPercentage = healthPercentage;

      self.drawings.healthBar.Color = Color3.new(1, 0, 0):Lerp(Color3.new(0, 1, 0), healthPercentage);
end;
function playerESP:setupHumanoid(humanoid: Humanoid, firstTime)

      self:humanoidHealthChanged();

      humanoid:GetPropertyChangedSignal('Health'):Connect(function()
            self:humanoidHealthChanged();
      end);

      if (firstTime) then
            local childAddedConnections = self.childAddedConnections;
            local characterChildren = self.current.character:GetChildren();

            for i = 1, #characterChildren do
                  local child = characterChildren[i];
                  for i = 1, #childAddedConnections do
                        childAddedConnections[i](self, child);
                  end;
            end;
      end;
end;
function playerESP:loop(settings)
      local current = self.current;

      local _, size              = getBoundingBox(current.character);
      local goal              = current.rootPart.Position;

      local vector2, onscreen = worldToViewPoint(goal);
      if (not onscreen) then
            return self:hideDrawings();
      end;

      local cframe = CFrame.new(goal, currentCamera.CFrame.Position);

      local x, y = -size.X / 2, size.Y / 2;
      local topright    = worldToViewPoint((cframe * CFrame.new(x, y, 0)).Position)
      local bottomright = worldToViewPoint((cframe * CFrame.new(x, -y, 0)).Position)

      local offset = Vector2.new(
            math.max(topright.X - vector2.X, bottomright.X - vector2.X),
            math.max((vector2.Y - topright.Y), (bottomright.Y - vector2.Y))
      );

      self:renderBox(vector2, offset, settings.box);
      self:renderName(vector2, offset, settings.name);
      self:renderDistance(vector2, offset, settings.distance);
      self:renderHealthbar(vector2, offset, settings.healthbar);
      self:renderWeapon(vector2, offset, settings.weapon);
end;
function playerESP:primaryPartAdded()
      local primaryPart = self.current.character.PrimaryPart;

      if (primaryPart) then
            self.current.rootPart = primaryPart;
            if (self.current.humanoid and self.current.health > 0) then
                  self.current.active = true;
            end;
      end;
end;
function playerESP:childAdded(child: Instance)

      if (child.ClassName == 'Humanoid') then
            self.current.humanoid = child;
            self:setupHumanoid(child);
      end;


      for i = 1, #self.childAddedConnections do
            self.childAddedConnections[i](self, child);
      end;
end;
function playerESP:childRemoved(child)
      if (child == self.current.humanoid) then
            self.current.humanoid = nil;
            self:setNonActive();
      elseif (child == self.current.rootPart) then
            self.current.rootPart = nil;
            self:setNonActive();
      end;

      for i = 1, #self.childRemovedConnections do
            self.childRemovedConnections[i](self, child);
      end;
end;
function playerESP:characterAdded(character: Model, firstTime)
      self.current = {
            character   = character;
            active      = false;

            humanoid    = character:FindFirstChild('Humanoid');
            rootPart    = character:FindFirstChild('HumanoidRootPart');


            health      = nil;
            weapon      = nil;
            connection  = nil;
      };


      character:GetPropertyChangedSignal('PrimaryPart'):Connect(function()
            self:primaryPartAdded();
      end);
      character.ChildAdded:Connect(function(...)
            return self:childAdded(...);
      end);
      character.ChildRemoved:Connect(function(...)
            return self:childRemoved(...);
      end);

      if (self.current.humanoid) then
            self:setupHumanoid(self.current.humanoid, firstTime);
      end;

end;
function playerESP:characterRemoved(character)
      self.current = nil;

      for i = 1, #self.allDrawings do
            self.allDrawings[i].Visible = false;
      end;
end;

--render functions
function playerESP:renderBox(vector2, offset, enabled)
      local drawings = self.drawings;

      if (not enabled) then
            drawings.box.Visible          = false;
            drawings.boxOutline.Visible   = false;
            return;
      end;

      local fill        = drawings.box;
      local outline     = drawings.boxOutline;

      local position    = vector2 - offset;
      local size        = offset * 2;
      
      fill.Visible      = true;
      fill.Position     = position;
      fill.Size         = size;

      outline.Visible   = true;
      outline.Position  = position;
      outline.Size      = size;
end;
function playerESP:renderName(vector2, offset, enabled)
      local name = self.drawings.name;

      if (not enabled) then
            name.Visible          = false;
            return;
      end;
      
      name.Visible      = true;
      name.Position     = vector2 - Vector2.new(0, offset.Y + name.Size);
end;
function playerESP:renderDistance(vector2, offset, enabled)
      local distance = self.drawings.distance;

      if (not enabled) then
            distance.Visible          = false;
            return;
      end;

      local Yoffset     = self.drawings.weapon.Visible and 13 or 0;
      local magnitude   = math.round( (currentCamera.CFrame.Position - self.current.rootPart.Position).Magnitude );
      
      distance.Visible  = true;
      distance.Position = vector2 + Vector2.new(0, offset.Y + Yoffset);
      distance.Text     = `[{magnitude}]`;
end;
function playerESP:renderWeapon(vector2, offset, enabled)
      local weapon = self.drawings.weapon;

      if (not enabled) then
            weapon.Visible          = false;
            return;
      end;

      weapon.Visible  = true;
      weapon.Position = vector2 + Vector2.new(0, offset.Y);
      weapon.Text     = self.current.weapon and string.lower(self.current.weapon.Name) or 'none';
end;
function playerESP:renderHealthbar(vector2, offset, enabled)
      if (not enabled) then
            self.drawings.healthBar.Visible = false;
            self.drawings.healthBackground.Visible = false;
            return;
      end;

      local healthBar         = self.drawings.healthBar;
      local healthBackground  = self.drawings.healthBackground;

      healthBar.Visible = true;
      healthBackground.Visible = true;

      local basePosition = vector2 - offset - Vector2.new(5, 0);
      local baseSize = Vector2.new(3, offset.Y * 2);

      local healthLength = (baseSize.Y - 2) * self.current.healthPercentage;
      local healthPosition = basePosition + Vector2.new(1, 1 + (baseSize.Y - 2 - healthLength));
      local healthSize = Vector2.new(1, healthLength);

      healthBackground.Position     = basePosition;
      healthBackground.Size         = baseSize;

      healthBar.Position            = healthPosition;
      healthBar.Size                = healthSize;
end;




return playerESP;
