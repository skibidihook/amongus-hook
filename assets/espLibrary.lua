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

local FlagSize = math.clamp(GlobalSize - 2, 11, 13)
local FlagLineHeight = FlagSize + 2

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
                Cache.FlagTexts[i].Font = GlobalFont
                Cache.FlagTexts[i].Color = Color3.new(1, 1, 1)
                Cache.FlagTexts[i].Outline = true
                Cache.FlagTexts[i].OutlineColor = Color3.new(0, 0, 0)
                Cache.FlagTexts[i].Transparency = 1
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

    EspLibrary.PlayerESP = PlayerESP
end

return EspLibrary, 3
