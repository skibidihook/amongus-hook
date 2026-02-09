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

local FlagSize = math.clamp(GlobalSize - 6, 8, 10)
local FlagLineHeight = FlagSize + 1

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

    local function Get2DBoxFrom3DBounds(CF, Size)
        local SX, SY, SZ = Size.X, Size.Y, Size.Z
        local HX, HY, HZ = SX * 0.5, SY * 0.5, SZ * 0.5

        local MinX, MinY = math.huge, math.huge
        local MaxX, MaxY = -math.huge, -math.huge
        local MinZ = math.huge

        for IX = -1, 1, 2 do
            for IY = -1, 1, 2 do
                for IZ = -1, 1, 2 do
                    local CornerWorld = (CF * CFrame.new(HX * IX, HY * IY, HZ * IZ)).Position
                    local V2, _, Z = WorldToViewPoint(CornerWorld)
                    if Z < MinZ then MinZ = Z end
                    if V2.X < MinX then MinX = V2.X end
                    if V2.Y < MinY then MinY = V2.Y end
                    if V2.X > MaxX then MaxX = V2.X end
                    if V2.Y > MaxY then MaxY = V2.Y end
                end
            end
        end

        return Vector2.new(MinX, MinY), Vector2.new(MaxX - MinX, MaxY - MinY), MinZ
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

            for i = 1, #Cache.FlagTexts do
                Cache.FlagTexts[i].Size = FlagSize
            end

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

        local FullBox = { Lines = {}, Outlines = {} }
        for i = 1, 4 do
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
            table.insert(FullBox.Outlines, Outline)
            table.insert(FullBox.Lines, Line)
        end

        local FlagTexts = {}
        for i = 1, 6 do
            local FlagText = CreateDrawing("Text", {
                Visible = false,
                Center = false,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Color = Color3.new(1, 1, 1),
                Transparency = 1,
                Size = FlagSize,
                Text = "",
                Font = GlobalFont,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings)
            table.insert(FlagTexts, FlagText)
        end

        local Drawings = {
            Corners = Corners,
            FullBox = FullBox,

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
        local Humanoid = Current and Current.Humanoid
        local RootPart = Current and Current.RootPart

        if not Humanoid or not RootPart then
            return self:HideDrawings()
        end

        local _, RootOnScreen, RootZ = WorldToViewPoint(RootPart.Position)
        if not RootOnScreen or RootZ <= 0 then
            self.Current.Visible = false
            return self:HideDrawings()
        end

        local BoxCF, BoxSize3 = GetBoundingBox(Humanoid, true)
        local BoxPos2D, BoxSize2D, MinZ = Get2DBoxFrom3DBounds(BoxCF, BoxSize3)
        if MinZ <= 0 then
            return self:HideDrawings()
        end

        self.Current.Visible = true
        self.Hidden = false

        local Center2D = BoxPos2D + (BoxSize2D * 0.5)
        local Offset = BoxSize2D * 0.5

        self:RenderBox(Center2D, BoxPos2D, BoxSize2D, Settings.Box)
        self:RenderName(Center2D, Offset, Settings.Name)
        self:RenderWeapon(Center2D, Offset, Settings.Weapon)
        self:RenderDistance(Center2D, Offset, Settings.Distance, DistanceOverride)
        self:RenderHealthbar(Center2D, Offset, Settings.Healthbar)
        self:RenderFlags(BoxPos2D, BoxSize2D, Settings.Flags)
    end

    function PlayerESP:PrimaryPartAdded()
        local PrimaryPart = self.Current.Character.PrimaryPart
        if PrimaryPart then
            self.Current.RootPart = PrimaryPart
            if self.Current.Humanoid and self.Current.Health and self.Current.Health > 0 then
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

    function PlayerESP:RenderBox(Center2D, BoxPos2D, BoxSize2D, BoxSettings)
        local Corners = self.Drawings.Corners
        local FullBox = self.Drawings.FullBox

        local CornersLines = Corners.Lines
        local CornersOutlines = Corners.Outlines

        local FullLines = FullBox.Lines
        local FullOutlines = FullBox.Outlines

        local Enabled = false
        local Mode = "corner"

        if type(BoxSettings) == "table" then
            Enabled = not not BoxSettings.Enabled
            Mode = string.lower(BoxSettings.Mode or "corner")
        else
            Enabled = not not BoxSettings
        end

        if not Enabled then
            for i = 1, 8 do
                CornersLines[i].Visible = false
                CornersOutlines[i].Visible = false
            end
            for i = 1, 4 do
                FullLines[i].Visible = false
                FullOutlines[i].Visible = false
            end
            return
        end

        if Mode == "full" then
            for i = 1, 8 do
                CornersLines[i].Visible = false
                CornersOutlines[i].Visible = false
            end

            local X1 = BoxPos2D.X
            local Y1 = BoxPos2D.Y
            local X2 = BoxPos2D.X + BoxSize2D.X
            local Y2 = BoxPos2D.Y + BoxSize2D.Y

            local P = {
                {Vector2.new(X1, Y1), Vector2.new(X2, Y1)},
                {Vector2.new(X2, Y1), Vector2.new(X2, Y2)},
                {Vector2.new(X2, Y2), Vector2.new(X1, Y2)},
                {Vector2.new(X1, Y2), Vector2.new(X1, Y1)},
            }

            for i = 1, 4 do
                local O = FullOutlines[i]
                local L = FullLines[i]
                O.Visible = true
                L.Visible = true
                O.From = P[i][1]
                O.To = P[i][2]
                L.From = P[i][1]
                L.To = P[i][2]
            end

            return
        end

        for i = 1, 4 do
            FullLines[i].Visible = false
            FullOutlines[i].Visible = false
        end

        local Left = BoxPos2D.X
        local Top = BoxPos2D.Y
        local Right = BoxPos2D.X + BoxSize2D.X
        local Bottom = BoxPos2D.Y + BoxSize2D.Y

        local HorizontalLen = math.floor(BoxSize2D.X * 0.25)
        local VerticalLen = math.floor(BoxSize2D.Y * 0.25)

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

            local Outline = CornersOutlines[i]
            local Line = CornersLines[i]

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

    function PlayerESP:RenderDistance(Vector2Pos, Offset, Enabled, DistanceOverride)
        local Distance = self.Drawings.Distance
        if not Enabled then
            Distance.Visible = false
            return
        end
        local YOffset = self.Drawings.Weapon.Visible and (GlobalSize + 1) or 0
        local Magnitude = math.round(DistanceOverride or (CurrentCamera.CFrame.Position - self.Current.RootPart.Position).Magnitude)
        Distance.Visible = true
        Distance.Position = Vector2Pos + Vector2.new(0, Offset.Y + YOffset)
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

    function PlayerESP:RenderFlags(BoxPos2D, BoxSize2D, FlagsSettings)
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

        local Right = BoxPos2D.X + BoxSize2D.X
        local Top = BoxPos2D.Y
        local X = Right + 2

        local Mode = string.lower(FlagsSettings.Mode or "normal")
        if Mode == "always" then
            local Count = math.min(#Items, #FlagTexts)
            for i = 1, Count do
                local Item = Items[i]
                local TextObj = FlagTexts[i]
                local State = not not Item.State
                TextObj.Visible = true
                TextObj.Size = FlagSize
                TextObj.Text = tostring(Item.Text or "")
                TextObj.Position = Vector2.new(X, Top + (FlagLineHeight * (i - 1)))
                TextObj.Color = (State and (Item.ColorTrue or Color3.new(0, 1, 0))) or (Item.ColorFalse or Color3.new(1, 0, 0))
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
                TextObj.Size = FlagSize
                TextObj.Text = tostring(Item.Text or "")
                TextObj.Position = Vector2.new(X, Top + (FlagLineHeight * Index))
                TextObj.Color = Item.ColorTrue or Color3.new(0, 1, 0)
                Index = Index + 1
            end
        end
    end

    EspLibrary.PlayerESP = PlayerESP
end

return EspLibrary, 3
