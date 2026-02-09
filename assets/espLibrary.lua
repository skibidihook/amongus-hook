local CloneRef = cloneref or function(...) return ... end
local RunService = CloneRef(game:GetService("RunService"))
local CurrentCamera = CloneRef(workspace.CurrentCamera)

local CreateDrawing = function(Type, Properties, ...)
    local DrawingObject = Drawing.new(Type)
    for Key, Value in pairs(Properties) do
        DrawingObject[Key] = Value
    end
    for _, TableRef in {...} do
        table.insert(TableRef, DrawingObject)
    end
    return DrawingObject
end

local GetBoundingBox = function(Model, IsPlayer)
    if IsPlayer then
        return Model:ComputeR15BodyBoundingBox()
    end
    return Model:GetBoundingBox()
end

local WorldToViewPoint = function(Position)
    local Pos, OnScreen = CurrentCamera:WorldToViewportPoint(Position)
    return Vector2.new(Pos.X, Pos.Y), OnScreen, Pos.Z
end

local GlobalFont = _G.GLOBAL_FONT or 1
local GlobalSize = _G.GLOBAL_SIZE or 13
local BaseZIndex = 1

local EspLibrary = {}

do
    local PlayerESP = {
        PlayerCache = {},
        DrawingCache = {},
        AllDrawingCache = {},
        ChildAddedConnections = {},
        ChildRemovedConnections = {},
        DrawingAddedConnections = {},
    }
    PlayerESP.__index = PlayerESP

    PlayerESP.OnChildAdded = function(Callback)
        table.insert(PlayerESP.ChildAddedConnections, Callback)
    end
    PlayerESP.OnChildRemoved = function(Callback)
        table.insert(PlayerESP.ChildRemovedConnections, Callback)
    end
    PlayerESP.OnDrawingAdded = function(Callback)
        table.insert(PlayerESP.DrawingAddedConnections, Callback)
    end

    PlayerESP.New = function(Player)
        local Self = setmetatable({
            Player = Player,
            Connections = {},
            Hidden = false,
            AllDrawings = nil,
            Drawings = nil,
            Current = nil,
        }, PlayerESP)

        local Cache = PlayerESP.DrawingCache[1]
        if Cache then
            table.remove(PlayerESP.DrawingCache, 1)
            Cache.Name.Text = Player.DisplayName
            Self.AllDrawings = Cache.All
            Self.Drawings = Cache
        else
            Self:CreateDrawingCache()
        end

        for i = 1, #PlayerESP.DrawingAddedConnections do
            PlayerESP.DrawingAddedConnections[i](Self)
        end

        table.insert(Self.Connections, Player.CharacterAdded:Connect(function(...)
            return Self:CharacterAdded(...)
        end))
        table.insert(Self.Connections, Player.CharacterRemoving:Connect(function(...)
            return Self:CharacterRemoved(...)
        end))

        if Player.Character then
            Self:CharacterAdded(Player.Character, true)
        end

        PlayerESP.PlayerCache[Player] = Self
        return Self
    end

    PlayerESP.Remove = function(Player)
        local Cache = PlayerESP.PlayerCache[Player]
        if type(Cache) ~= "table" or type(Cache.Drawings) ~= "table" or type(Cache.Connections) ~= "table" then
            return
        end
        PlayerESP.PlayerCache[Player] = nil
        for i = 1, #Cache.Connections do
            Cache.Connections[i]:Disconnect()
        end
        table.insert(PlayerESP.DrawingCache, Cache.Drawings)
    end

    function PlayerESP:CreateDrawingCache()
        local AllDrawings = {}

        local Corners = { Lines = {}, Outlines = {} }
        for i = 1, 8 do
            local Outline = CreateDrawing("Line", {
                Visible = false,
                Thickness = 2,
                Color = Color3.new(0, 0, 0),
                ZIndex = BaseZIndex,
            }, AllDrawings)
            local Line = CreateDrawing("Line", {
                Visible = false,
                Thickness = 1,
                Color = Color3.new(1, 1, 1),
                ZIndex = BaseZIndex + 1,
            }, AllDrawings)
            table.insert(Corners.Outlines, Outline)
            table.insert(Corners.Lines, Line)
        end

        local FlagTexts = {}
        for i = 1, 4 do
            local FlagText = CreateDrawing("Text", {
                Visible = false,
                Center = false,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Color = Color3.new(1, 0, 0),
                Transparency = 1,
                Size = GlobalSize,
                Text = "",
                Font = GlobalFont,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings)
            table.insert(FlagTexts, FlagText)
        end

        local Drawings = {
            Corners = Corners,
            Name = CreateDrawing("Text", {
                Visible = false,
                Center = true,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Color = Color3.new(1, 1, 1),
                Transparency = 1,
                Size = GlobalSize,
                Text = self and self.Player and self.Player.DisplayName or "",
                Font = GlobalFont,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings),
            Distance = CreateDrawing("Text", {
                Visible = false,
                Center = true,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Color = Color3.new(1, 1, 1),
                Transparency = 1,
                Size = GlobalSize,
                Font = GlobalFont,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings),
            HealthBar = CreateDrawing("Square", {
                Visible = false,
                Thickness = 1,
                Filled = true,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings),
            HealthBackground = CreateDrawing("Square", {
                Visible = false,
                Color = Color3.new(0.239215, 0.239215, 0.239215),
                Transparency = 0.7,
                Thickness = 1,
                Filled = true,
                ZIndex = BaseZIndex,
            }, AllDrawings),
            Weapon = CreateDrawing("Text", {
                Visible = false,
                Center = true,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Color = Color3.new(1, 1, 1),
                Transparency = 1,
                Size = GlobalSize,
                Font = GlobalFont,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings),
            FlagTexts = FlagTexts,
        }
        Drawings.All = AllDrawings

        self.Drawings = Drawings
        self.AllDrawings = AllDrawings
    end

    function PlayerESP:HideDrawings()
        if self.Hidden then return end
        self.Hidden = true
        for i = 1, #self.AllDrawings do
            self.AllDrawings[i].Visible = false
        end
    end

    function PlayerESP:SetNonActive()
        if self.Current.Active == false then return end
        self.Current.Active = false
        for i = 1, #self.AllDrawings do
            self.AllDrawings[i].Visible = false
        end
    end

    function PlayerESP:HumanoidHealthChanged()
        local Humanoid = self.Current.Humanoid
        if not Humanoid then return end

        local Health = Humanoid.Health
        local MaxHealth = Humanoid.MaxHealth
        local HealthPercentage = Health / MaxHealth

        if self.Current.RootPart and Health > 0 then
            self.Current.Active = true
        else
            self:SetNonActive()
        end

        self.Current.Health = Health
        self.Current.MaxHealth = MaxHealth
        self.Current.HealthPercentage = HealthPercentage

        self.Drawings.HealthBar.Color = Color3.new(1, 0, 0):Lerp(Color3.new(0, 1, 0), HealthPercentage)
    end

    function PlayerESP:SetupHumanoid(Humanoid, FirstTime)
        self:HumanoidHealthChanged()
        table.insert(self.Connections, Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            self:HumanoidHealthChanged()
        end))

        if FirstTime then
            local ChildAddedConnections = self.ChildAddedConnections
            local CharacterChildren = self.Current.Character:GetChildren()
            for i = 1, #CharacterChildren do
                local Child = CharacterChildren[i]
                for j = 1, #ChildAddedConnections do
                    ChildAddedConnections[j](self, Child)
                end
            end
        end
    end

    function PlayerESP:Loop(Settings, DistanceOverride)
        local Current = self.Current
        local _, Size = GetBoundingBox(Current.Humanoid, true)
        local Goal = Current.RebuiltPos or Current.RootPart.Position

        local Vector2Pos, OnScreen = WorldToViewPoint(Goal)
        self.Current.Visible = OnScreen
        if not OnScreen then
            return self:HideDrawings()
        end
        self.Hidden = false

        local CF = CFrame.new(Goal, CurrentCamera.CFrame.Position)
        local X, Y = -Size.X / 2, Size.Y / 2
        local TopRight = WorldToViewPoint((CF * CFrame.new(X, Y, 0)).Position)
        local BottomRight = WorldToViewPoint((CF * CFrame.new(X, -Y, 0)).Position)

        local Offset = Vector2.new(
            math.max(TopRight.X - Vector2Pos.X, BottomRight.X - Vector2Pos.X),
            math.max((Vector2Pos.Y - TopRight.Y), (BottomRight.Y - Vector2Pos.Y))
        )

        self:RenderCornerBox(Vector2Pos, Offset, Settings.Box)
        self:RenderName(Vector2Pos, Offset, Settings.Name)
        self:RenderDistance(Vector2Pos, Offset, Settings.Distance, DistanceOverride)
        self:RenderHealthbar(Vector2Pos, Offset, Settings.Healthbar)
        self:RenderWeapon(Vector2Pos, Offset, Settings.Weapon)
        self:RenderFlags(Vector2Pos, Offset, Settings.Flags)
    end

    function PlayerESP:PrimaryPartAdded()
        local PrimaryPart = self.Current.Character.PrimaryPart
        if PrimaryPart then
            self.Current.RootPart = PrimaryPart
            if self.Current.Humanoid and self.Current.Health > 0 then
                self.Current.Active = true
            end
        end
    end

    function PlayerESP:ChildAdded(Child)
        if Child.ClassName == "Humanoid" then
            self.Current.Humanoid = Child
            self:SetupHumanoid(Child)
        end
        for i = 1, #self.ChildAddedConnections do
            self.ChildAddedConnections[i](self, Child)
        end
    end

    function PlayerESP:ChildRemoved(Child)
        if not self.Current then
        elseif Child == self.Current.Humanoid then
            self.Current.Humanoid = nil
            self:SetNonActive()
        elseif Child == self.Current.RootPart then
            self.Current.RootPart = nil
            self:SetNonActive()
        end
        for i = 1, #self.ChildRemovedConnections do
            self.ChildRemovedConnections[i](self, Child)
        end
    end

    function PlayerESP:CharacterAdded(Character, FirstTime)
        self.Current = {
            Character = Character,
            Active = false,
            Humanoid = Character:FindFirstChild("Humanoid"),
            RootPart = Character:FindFirstChild("HumanoidRootPart"),
            Health = nil,
            Weapon = nil,
            Connection = nil,
            Visible = false,
        }

        table.insert(self.Connections, Character:GetPropertyChangedSignal("PrimaryPart"):Connect(function()
            self:PrimaryPartAdded()
        end))
        table.insert(self.Connections, Character.ChildAdded:Connect(function(...)
            return self:ChildAdded(...)
        end))
        table.insert(self.Connections, Character.ChildRemoved:Connect(function(...)
            return self:ChildRemoved(...)
        end))

        if self.Current.Humanoid then
            self:SetupHumanoid(self.Current.Humanoid, FirstTime)
        end
    end

    function PlayerESP:CharacterRemoved(Character)
        self.Current = nil
        for i = 1, #self.AllDrawings do
            self.AllDrawings[i].Visible = false
        end
    end

    function PlayerESP:RenderCornerBox(Vector2Pos, Offset, Enabled)
        local Drawings = self.Drawings
        local Corners = Drawings.Corners
        local Lines = Corners.Lines
        local Outlines = Corners.Outlines

        if not Enabled then
            for i = 1, 8 do
                Lines[i].Visible = false
                Outlines[i].Visible = false
            end
            return
        end

        local Position = Vector2Pos - Offset
        local Size = Offset * 2

        local Left = Position.X
        local Top = Position.Y
        local Right = Position.X + Size.X
        local Bottom = Position.Y + Size.Y

        local HorizontalLen = math.floor(Size.X * 0.25)
        local VerticalLen = math.floor(Size.Y * 0.25)

        local Points = {
            {Vector2.new(Left, Top), Vector2.new(Left + HorizontalLen, Top)},
            {Vector2.new(Left, Top), Vector2.new(Left, Top + VerticalLen)},
            {Vector2.new(Right - HorizontalLen, Top), Vector2.new(Right, Top)},
            {Vector2.new(Right, Top), Vector2.new(Right, Top + VerticalLen)},
            {Vector2.new(Left, Bottom), Vector2.new(Left + HorizontalLen, Bottom)},
            {Vector2.new(Left, Bottom - VerticalLen), Vector2.new(Left, Bottom)},
            {Vector2.new(Right - HorizontalLen, Bottom), Vector2.new(Right, Bottom)},
            {Vector2.new(Right, Bottom - VerticalLen), Vector2.new(Right, Bottom)},
        }

        for i = 1, 8 do
            local P1 = Points[i][1]
            local P2 = Points[i][2]
            local Outline = Outlines[i]
            local Line = Lines[i]
            Outline.Visible = true
            Line.Visible = true
            Outline.From = P1
            Outline.To = P2
            Line.From = P1
            Line.To = P2
        end
    end

    function PlayerESP:RenderName(Vector2Pos, Offset, Enabled)
        local Name = self.Drawings.Name
        if not Enabled then
            Name.Visible = false
            return
        end
        Name.Visible = true
        Name.Position = Vector2Pos - Vector2.new(0, Offset.Y + Name.Size)
    end

    function PlayerESP:RenderDistance(Vector2Pos, Offset, Enabled, DistanceOverride)
        local Distance = self.Drawings.Distance
        if not Enabled then
            Distance.Visible = false
            return
        end
        local Magnitude = math.round(DistanceOverride or (CurrentCamera.CFrame.Position - self.Current.RootPart.Position).Magnitude)
        Distance.Visible = true
        Distance.Position = Vector2Pos + Vector2.new(0, Offset.Y)
        Distance.Text = `[{Magnitude}]`
    end

    function PlayerESP:RenderHealthbar(Vector2Pos, Offset, Enabled)
        if not Enabled then
            self.Drawings.HealthBar.Visible = false
            self.Drawings.HealthBackground.Visible = false
            return
        end
        local HealthBar = self.Drawings.HealthBar
        local HealthBackground = self.Drawings.HealthBackground
        HealthBar.Visible = true
        HealthBackground.Visible = true
        local BasePosition = Vector2Pos - Offset - Vector2.new(5, 0)
        local BaseSize = Vector2.new(3, Offset.Y * 2)
        local HealthLength = (BaseSize.Y - 2) * self.Current.HealthPercentage
        local HealthPosition = BasePosition + Vector2.new(1, 1 + (BaseSize.Y - 2 - HealthLength))
        local HealthSize = Vector2.new(1, HealthLength)
        HealthBackground.Position = BasePosition
        HealthBackground.Size = BaseSize
        HealthBar.Position = HealthPosition
        HealthBar.Size = HealthSize
    end

    function PlayerESP:RenderWeapon(Vector2Pos, Offset, Enabled)
        local WeaponText = self.Drawings.Weapon
        if not Enabled then
            WeaponText.Visible = false
            return
        end
        WeaponText.Visible = true
        WeaponText.Position = Vector2Pos + Vector2.new(0, Offset.Y)
        WeaponText.Text = self.Current.Weapon and string.lower(self.Current.Weapon.Name) or "none"
    end

    function PlayerESP:RenderFlags(Vector2Pos, Offset, FlagsSettings)
        local FlagTexts = self.Drawings.FlagTexts
        for i = 1, #FlagTexts do
            FlagTexts[i].Visible = false
        end
        if not FlagsSettings or not FlagsSettings.Enabled then
            return
        end

        local Items = {}
        if type(FlagsSettings.Builder) == "function" then
            local Ok, Result = pcall(function() return FlagsSettings.Builder(self) end)
            if Ok and type(Result) == "table" then
                Items = Result
            end
        end

        local Position = Vector2Pos - Offset
        local Size = Offset * 2
        local Right = Position.X + Size.X
        local Top = Position.Y
        local Spacing = math.max(GlobalSize, 12) + 6

        local Mode = string.lower(FlagsSettings.Mode or "normal")
        if Mode == "always" then
            for i = 1, math.min(#Items, #FlagTexts) do
                local Item = Items[i]
                local TextObj = FlagTexts[i]
                local State = not not Item.State
                local TrueColor = Item.ColorTrue or Color3.new(0, 1, 0)
                local FalseColor = Item.ColorFalse or Color3.new(1, 0, 0)
                TextObj.Visible = true
                TextObj.Text = tostring(Item.Text or "")
                TextObj.Position = Vector2.new(Right + 4 + Spacing * (i - 1), Top)
                TextObj.Color = State and TrueColor or FalseColor
            end
            return
        end

        local Index = 0
        for i = 1, #Items do
            if Index >= #FlagTexts then break end
            local Item = Items[i]
            if Item.State then
                local TextObj = FlagTexts[Index + 1]
                TextObj.Visible = true
                TextObj.Text = tostring(Item.Text or "")
                TextObj.Position = Vector2.new(Right + 4 + Spacing * Index, Top)
                TextObj.Color = Item.ColorTrue or Color3.new(0, 1, 0)
                Index = Index + 1
            end
        end
    end

    EspLibrary.PlayerESP = PlayerESP
end

return EspLibrary, 3
