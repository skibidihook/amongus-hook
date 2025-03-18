--[[ 
    * Ensured indentation is consistent
    * CamelCase for class names
    * Takes advantage of “self:Method()” instead of local inline function for onClick
]]

local KEY_CONVERSION = {
    ['One']          = '1',
    ['Two']          = '2',
    ['Three']        = '3',
    ['Four']         = '4',
    ['Five']         = '5',
    ['Six']          = '6',
    ['Seven']        = '7',
    ['Eight']        = '8',
    ['Nine']         = '9',
    ['Zero']         = '0',
    ['Return']       = 'Enter',
    ['LeftBracket']  = 'LBracket',
    ['RightBracket'] = 'RBracket',
    ['Equals']       = '=',
    ['Minus']        = '-',
    ['Escape']       = 'Esc',
    ['LeftShift']    = 'LShift',
    ['RightShift']   = 'RShift',
    ['RightControl'] = 'RCtrl',
    ['LeftControl']  = 'LCtrl',
    ['Quote']        = "'",
    ['Semicolon']    = ';',
    ['Delete']       = 'Del',
    ['Up']           = 'UpArrow',
    ['Down']         = 'DownArrow',
    ['Right']        = 'RightArrow',
    ['Left']         = 'LeftArrow',
    ['RightAlt']     = 'RAlt',
    ['LeftAlt']      = 'LAlt',
    ['MouseButton2'] = 'MB2',
};

local GLOBAL_FONT = 1

-- Drawing references
local drawing_new     = Drawing and Drawing.new
local vector2         = Vector2.new
local color_rgb       = Color3.fromRGB
local color_hsv       = Color3.fromHSV

-- Math references
local math_clamp      = math.clamp
local math_round      = math.round
local math_abs        = math.abs

-- Task references
local task_spawn      = task.spawn
local task_delay      = task.delay

-- Table references
local table_insert    = table.insert
local table_find      = table.find
local table_remove    = table.remove

-- String references
local string_find     = string.find
local string_sub      = string.sub
local tostring        = tostring

-- Roblox services
local cloneref        = cloneref or function(x) return x end
local userInputService= cloneref(game:GetService('UserInputService'))
local runService      = cloneref(game:GetService('RunService'))
local camera          = cloneref(workspace.CurrentCamera)

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

local function loadFolders()
    local requiredFolders = {
        'amghook',
        'amghook\\assets',
    }
    for _, folderName in ipairs(requiredFolders) do
        if not isfolder(folderName) then
            makefolder(folderName)
        end
    end
end

-- Placeholder references – you presumably have these defined somewhere else:
-- local ASSET_IMAGES = { ... }
-- local base64_decode = function(...) ... end

local function loadAssets()
    loadFolders()
    for assetName, assetData in pairs(ASSET_IMAGES or {}) do
        local filePath = ('amghook\\assets\\%s'):format(assetName)
        if not isfile(filePath) then
            writefile(filePath, base64_decode(assetData))
        end
    end
end

local function createDrawing(dType, properties, ...)
    local obj = drawing_new(dType)
    for i, v in pairs(properties) do
        obj[i] = v
    end
    for _, t in ipairs({...}) do
        table_insert(t, obj)
    end
    return obj
end

local function createClass(tbl)
    local class = tbl or {}
    class.__index = class
    return class
end

--------------------------------------------------------------------------------
-- Classes
--------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Notification Class
-------------------------------------------------------------------------------
local NotifyClass = createClass()

function NotifyClass:new(window, text, time)
    local notification = setmetatable({
        window      = window,
        text        = text,
        time        = time,
        active      = true,
        drawings    = {},
        offset      = 0,
        goalPos     = vector2(10, 10),
    }, NotifyClass)

    local notificationOffset = 65
    for _, otherNotif in ipairs(window.notifications) do
        notificationOffset = notificationOffset + otherNotif.offset + 10
    end

    -- Create drawings
    do
        local drawings = notification.drawings

        drawings.text = createDrawing('Text', {
            Visible       = true,
            Center        = false,
            Outline       = true,
            Transparency  = 1,
            Size          = 13,
            Font          = GLOBAL_FONT,
            Text          = text,
            Color         = color_rgb(195, 195, 195),
            OutlineColor  = color_rgb(0, 0, 0),
            ZIndex        = 9,
        })
        drawings.text.Position = vector2(
            -drawings.text.TextBounds.X - 5,
            notificationOffset + 5
        )

        drawings.background = createDrawing('Square', {
            Visible       = true,
            Filled        = true,
            Transparency  = 1,
            Thickness     = 1,
            Color         = color_rgb(39, 39, 39),
            Position      = drawings.text.Position - vector2(5, 5),
            Size          = drawings.text.TextBounds + vector2(10, 10),
            ZIndex        = 8,
        })

        drawings.background_outline = createDrawing('Square', {
            Visible       = true,
            Filled        = false,
            Transparency  = 1,
            Thickness     = 1,
            Color         = color_rgb(0, 0, 0),
            Position      = drawings.background.Position,
            Size          = drawings.background.Size,
            ZIndex        = 9,
        })

        drawings.accent = createDrawing('Square', {
            Visible       = true,
            Filled        = true,
            Transparency  = 1,
            Thickness     = 1,
            Color         = color_rgb(255, 0, 0),
            Position      = drawings.background.Position - vector2(2, 0),
            Size          = drawings.background.Size + vector2(2, 2),
            ZIndex        = 7,
        })
    end

    notification.offset = notification.drawings.accent.Size.Y
    notification.goalPos = vector2(10, notificationOffset)
    notification:moveTo(notification.goalPos, 0.2)

    table_insert(window.notifications, notification)

    local totalTime = 0
    notification.connection = runService.RenderStepped:Connect(function(deltaTime)
        totalTime = totalTime + deltaTime
        if totalTime >= time - 0.05 then
            notification.connection:Disconnect()
            notification:remove()
        end
    end)

    return notification
end

function NotifyClass:moveTo(position, duration)
    if self.move_connection then
        self.move_connection:Disconnect()
        self.move_connection = nil
    end

    local allDrawings = self.drawings
    local basePos     = allDrawings.background.Position
    local offset      = position - basePos

    local basePositions = {}
    for i, drawObj in pairs(allDrawings) do
        basePositions[i] = drawObj.Position
    end

    local totalTime = 0
    self.move_connection = runService.RenderStepped:Connect(function(dt)
        totalTime = totalTime + dt
        if totalTime >= duration then
            for i, pos in pairs(basePositions) do
                allDrawings[i].Position = pos + offset
            end
            self.move_connection:Disconnect()
            self.move_connection = nil
            return
        end
        local pct = totalTime / duration
        for i, pos in pairs(basePositions) do
            allDrawings[i].Position = pos + offset * pct
        end
    end)
end

function NotifyClass:remove()
    local notifications = self.window.notifications
    local index         = table_find(notifications, self)
    if not index then return end

    table_remove(notifications, index)

    local offset = self.offset + 10
    self:moveTo(vector2(10, -offset), 0.05)

    local totalTime = 0
    self.connection = runService.RenderStepped:Connect(function(deltaTime)
        totalTime = totalTime + deltaTime
        if totalTime >= 0.05 then
            for _, drawObj in pairs(self.drawings) do
                drawObj:Remove()
            end
            self.connection:Disconnect()
        end
    end)

    -- Slide up remaining notifications
    for i = index, #notifications do
        local notif = notifications[i]
        notif.goalPos = notif.goalPos - vector2(0, offset)
        notif:moveTo(notif.goalPos, 0.05)
    end
end

-------------------------------------------------------------------------------
-- Window Class
-------------------------------------------------------------------------------
local WindowClass = createClass({
    index        = 0,
    notifications= {},
})

function WindowClass:new(options)
    assert(type(options) == 'table', ("invalid argument #1 to 'WindowClass.new' (table expected, got %s)"):format(type(options)))

    WindowClass.index = WindowClass.index + 1
    loadAssets()

    local window = setmetatable({
        id           = WindowClass.index,
        active       = true,
        title        = options.title or "amongus.hook",
        size         = options.size or vector2(600, 500),
        position     = camera.ViewportSize / 2,

        tabSettings  = {
            index = 0,
            tabs  = {},
        },

        clickDetectors  = {},
        keyDetectors    = {},
        keyEnd          = {},
        flags           = {},
        connectedToggles= {},

        mouseHeld    = false,
        drawings     = {},
        allDrawings  = {},
        overlapDrawings = {},
    }, WindowClass)

    -- Initialize main drawings
    local d = window.drawings

    -- Base background
    d.base = createDrawing('Square', {
        Visible       = window.active,
        Filled        = true,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(39, 39, 39),
        Position      = window.position - window.size/2,
        Size          = window.size,
        ZIndex        = 10,
    }, window.allDrawings)

    -- Drag bar "hidden"
    d.onDrag = createDrawing('Square', {
        Visible       = window.active,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(255, 42, 191),
        Position      = d.base.Position,
        Size          = vector2(window.size.X, 20),
        ZIndex        = -999,
    }, window.allDrawings)

    d.baseOutline = createDrawing('Square', {
        Visible       = window.active,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(7, 7, 7),
        Position      = d.base.Position - vector2(1, 1),
        Size          = d.base.Size + vector2(2, 2),
        ZIndex        = 11,
    }, window.allDrawings)

    d.innerOutline = createDrawing('Square', {
        Visible       = window.active,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(7, 7, 7),
        Position      = d.baseOutline.Position + vector2(0, 20),
        Size          = d.base.Size + vector2(2, 2) - vector2(0, 20),
        ZIndex        = 11,
    }, window.allDrawings)

    d.innerOutline2 = createDrawing('Square', {
        Visible       = window.active,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(7, 7, 7),
        Position      = d.innerOutline.Position + vector2(0, 40),
        Size          = d.innerOutline.Size - vector2(0, 40),
        ZIndex        = 11,
    }, window.allDrawings)

    d.sectionOutline1 = createDrawing('Square', {
        Visible       = window.active,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(7, 7, 7),
        Position      = d.innerOutline2.Position + vector2(16, 16),
        Size          = d.innerOutline2.Size - vector2(d.innerOutline2.Size.X/2 + 24, 32),
        ZIndex        = 11,
    }, window.allDrawings)

    d.sectionOutline2 = createDrawing('Square', {
        Visible       = window.active,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(7, 7, 7),
        Position      = d.innerOutline2.Position + vector2(d.innerOutline2.Size.X/2 + 8, 16),
        Size          = d.sectionOutline1.Size,
        ZIndex        = 11,
    }, window.allDrawings)

    d.title = createDrawing('Text', {
        Visible       = window.active,
        Center        = false,
        Outline       = true,
        Transparency  = 1,
        Size          = 13,
        Font          = GLOBAL_FONT,
        Text          = window.title,
        Color         = color_rgb(195, 195, 195),
        OutlineColor  = color_rgb(0, 0, 0),
        Position      = d.base.Position + vector2(2, 2),
        ZIndex        = 11,
    }, window.allDrawings)

    -- Input logic
    do
        -- Capture user input
        userInputService.InputBegan:Connect(function(input, gp)
            for _, kd in ipairs(window.keyDetectors) do
                kd(input, gp)
            end
            if input.KeyCode == Enum.KeyCode.RightShift then
                window:toggle()
                return
            end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                return
            end
            window.mouseHeld = true

            local mousePos = userInputService:GetMouseLocation()
            for _, cd in ipairs(window.clickDetectors) do
                cd(mousePos)
            end
        end)

        userInputService.InputEnded:Connect(function(input, gp)
            for _, ke in ipairs(window.keyEnd) do
                ke(input, gp)
            end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                window.mouseHeld = false
            end
        end)
    end

    -- Make the top bar draggable
    window:onClick(d.onDrag, function(mousePosition)
        local basePositions = {}
        for i, drw in ipairs(window.allDrawings) do
            basePositions[i] = drw.Position
        end

        local connection
        connection = runService.RenderStepped:Connect(function()
            if not window.mouseHeld then
                connection:Disconnect()
                return
            end
            local offset = userInputService:GetMouseLocation() - mousePosition
            for i, pos in ipairs(basePositions) do
                window.allDrawings[i].Position = pos + offset
            end
        end)
    end)

    return window, window.flags
end

function WindowClass:addTab(tabName)
    local TabClass = self._TabClass or require(script) -- or directly define below
    return TabClass:new(self, tabName)
end

function WindowClass:reloadTabs()
    local tabs = self.tabSettings.tabs
    for _, tab in ipairs(tabs) do
        tab:reload()
    end
end

function WindowClass:isWithin(drawing, mousePosition)
    local size   = drawing.Size
    local offset = mousePosition - drawing.Position
    return (offset.X > 0 and offset.Y > 0 and offset.X < size.X and offset.Y < size.Y)
end

function WindowClass:onClick(drawing, onClick, onMiss, ignoreOverlap)
    onMiss = onMiss or function() end
    local function handleClick(mousePosition)
        if not (drawing.Visible and self:isWithin(drawing, mousePosition)) then
            return onMiss(mousePosition)
        elseif ignoreOverlap then
            return onClick(mousePosition)
        end
        -- Check overlap
        for _, over in ipairs(self.overlapDrawings) do
            if over.Visible and self:isWithin(over, mousePosition) then
                return onMiss(mousePosition)
            end
        end
        return onClick(mousePosition)
    end
    table_insert(self.clickDetectors, handleClick)
end

function WindowClass:toggle()
    local enabled = not self.active
    self.active   = enabled

    for _, fn in ipairs(self.connectedToggles) do
        task_spawn(fn, enabled)
    end

    -- Simple approach: shift everything far away if “disabled”
    local shift = enabled and vector2(-99999, -99999) or vector2(99999, 99999)
    for _, drw in ipairs(self.allDrawings) do
        drw.Position = drw.Position + shift
    end
end

function WindowClass:onToggle(callback)
    table_insert(self.connectedToggles, callback)
end

function WindowClass:addKeyDetector(callback)
    table_insert(self.keyDetectors, callback)
end

function WindowClass:addKeyEnd(callback)
    table_insert(self.keyEnd, callback)
end

function WindowClass:notify(text, duration)
    return NotifyClass:new(self, text, duration)
end

-------------------------------------------------------------------------------
-- Tab Class
-------------------------------------------------------------------------------
local TabClass = createClass()

function TabClass:new(window, tabName)
    window.tabSettings.index = window.tabSettings.index + 1

    local tab = setmetatable({
        id       = window.tabSettings.index,
        active   = (window.tabSettings.index == 1),
        window   = window,
        name     = tabName or ("Tab" .. window.tabSettings.index),
        offsets  = {10, 10}, -- for left/right columns, presumably

        drawings      = {},
        allDrawings   = {},
        toggleDrawings= {},
    }, TabClass)

    -- Outline + text
    tab.drawings.outline = createDrawing('Square', {
        Visible       = window.active,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(7, 7, 7),
        ZIndex        = 11,
    }, window.allDrawings)

    tab.drawings.text = createDrawing('Text', {
        Visible       = window.active,
        Center        = true,
        Outline       = true,
        Transparency  = 1,
        Size          = 13,
        Font          = GLOBAL_FONT,
        Text          = tab.name,
        Color         = color_rgb(195, 195, 195),
        OutlineColor  = color_rgb(0, 0, 0),
        ZIndex        = 11,
    }, window.allDrawings)

    -- Set up click
    window:onClick(tab.drawings.outline, function()
        tab:onClicked()
    end)

    table_insert(window.tabSettings.tabs, tab)
    tab:toggle(tab.active)
    window:reloadTabs()

    return tab
end

function TabClass:reload()
    local window   = self.window
    local total    = window.tabSettings.index
    local width    = window.drawings.innerOutline.Size.X

    local size     = math.ceil(width / total)
    local xOffset  = size * (self.id - 1)

    self.drawings.outline.Position = window.drawings.innerOutline.Position + vector2(xOffset, 0)
    if self.id == total then
        self.drawings.outline.Size = vector2((width - size*(total - 1)), 41)
    else
        self.drawings.outline.Size = vector2(size + 1, 41)
    end

    self.drawings.text.Position = self.drawings.outline.Position + vector2(self.drawings.outline.Size.X/2, 14)
end

function TabClass:toggle(isEnabled)
    if isEnabled == nil then
        isEnabled = not self.active
    end
    self.active = isEnabled

    local c = (isEnabled and color_rgb(255, 255, 255) or color_rgb(195, 195, 195))
    self.drawings.text.Color = c
    for _, drw in ipairs(self.allDrawings) do
        drw.Visible = isEnabled
    end
    for _, td in ipairs(self.toggleDrawings) do
        td.Visible = false
    end
end

function TabClass:onClicked()
    if self.active then return end
    for _, otherTab in ipairs(self.window.tabSettings.tabs) do
        if otherTab ~= self then
            otherTab:toggle(false)
        end
    end
    self:toggle(true)
end

function TabClass:addToggle(options, offset)
    local ToggleClass = self._ToggleClass or require(script)
    return ToggleClass:new(self, options, offset)
end

function TabClass:addSlider(options, offset)
    local SliderClass = self._SliderClass or require(script)
    return SliderClass:new(self, options, offset)
end

function TabClass:addDropdown(options, offset)
    local DropdownClass = self._DropdownClass or require(script)
    return DropdownClass:new(self, options, offset)
end

function TabClass:addButton(text, onClick, offset)
    local ButtonClass = self._ButtonClass or require(script)
    return ButtonClass:new(self, text, onClick, offset)
end

-------------------------------------------------------------------------------
-- Toggle Class
-------------------------------------------------------------------------------
local ToggleClass = createClass()

function ToggleClass:new(tab, options, offset)
    offset = math_clamp(math_round(offset), 1, 2)

    local toggle = setmetatable({
        tab        = tab,
        window     = tab.window,
        text       = options.text or "Toggle",
        enabled    = options.default or false,
        drawings   = {},
    }, ToggleClass)

    -- Flag
    toggle.flag = {
        type    = 'toggle',
        value   = toggle.enabled,
        self    = toggle,
        Changed = function() end,
    }
    if options.flag then
        function toggle.flag:OnChanged(cb)
            toggle.flag.Changed = cb
            cb(toggle.flag.value)
        end
        toggle.window.flags[options.flag] = toggle.flag
    end

    local w   = toggle.window
    local d   = w.drawings
    local pos = d[('sectionOutline%d'):format(offset)].Position + vector2(15, tab.offsets[offset])

    -- Drawings
    toggle.drawings.outline = createDrawing('Square', {
        Visible       = tab.active,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(7, 7, 7),
        Position      = pos,
        Size          = vector2(15, 15),
        ZIndex        = 11,
    }, w.allDrawings, tab.allDrawings)

    toggle.drawings.accent = createDrawing('Square', {
        Visible       = tab.active,
        Filled        = true,
        Transparency  = (toggle.enabled and 1 or 0),
        Thickness     = 1,
        Color         = color_rgb(255, 0, 0),
        Position      = pos + vector2(1, 1),
        Size          = vector2(13.5, 13),
        ZIndex        = 11,
    }, w.allDrawings, tab.allDrawings)

    toggle.drawings.text = createDrawing('Text', {
        Visible       = tab.active,
        Center        = false,
        Outline       = true,
        Transparency  = 1,
        Size          = 13,
        Font          = GLOBAL_FONT,
        Text          = toggle.text,
        Color         = color_rgb(195, 195, 195),
        OutlineColor  = color_rgb(0, 0, 0),
        Position      = pos + vector2(20, 1),
        ZIndex        = 11,
    }, w.allDrawings, tab.allDrawings)

    toggle.drawings.clickDetector = createDrawing('Square', {
        Visible       = tab.active,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(255, 42, 191),
        Position      = pos,
        Size          = vector2(22 + toggle.drawings.text.TextBounds.X, 15),
        ZIndex        = -999,
    }, w.allDrawings, tab.allDrawings)

    -- Click logic
    w:onClick(toggle.drawings.clickDetector, function() 
        toggle:onClicked()
    end)

    tab.offsets[offset] = tab.offsets[offset] + 20
    return toggle
end

function ToggleClass:onClicked()
    self:setValue(not self.enabled)
end

function ToggleClass:setValue(val)
    self.enabled       = val
    self.flag.value    = val
    self.flag.Changed(val)
    self.drawings.accent.Transparency = (val and 1 or 0)
end

function ToggleClass:addKeypicker(options)
    local KeypickerClass = self._KeypickerClass or require(script)
    return KeypickerClass:new(self, options)
end

function ToggleClass:addColourpicker(options)
    local ColourpickerClass = self._ColourpickerClass or require(script)
    return ColourpickerClass:new(self, options)
end

-------------------------------------------------------------------------------
-- Slider Class
-------------------------------------------------------------------------------
local SliderClass = createClass()

function SliderClass:new(tab, options, offset)
    local slider = setmetatable({
        tab     = tab,
        window  = tab.window,

        text    = options.text,
        value   = options.default or options.min,
        max     = options.max,
        min     = options.min,
        increment=options.increment or 1,
        suffix  = options.suffix or '',
        drawings= {},
    }, SliderClass)

    slider.range = slider.max - slider.min
    local incStr = tostring(slider.increment)
    local dotPos = string_find(incStr, '.', 1, true)
    if dotPos then
        slider.maxIndex = #incStr - dotPos
    end

    -- Flag
    slider.flag = {
        type   = 'slider',
        value  = slider.value,
        self   = slider,
        Changed= function() end,
    }
    if options.flag then
        function slider.flag:OnChanged(cb)
            slider.flag.Changed = cb
            cb(slider.flag.value)
        end
        slider.window.flags[options.flag] = slider.flag
    end

    local w = slider.window
    local basePos = w.drawings[('sectionOutline%d'):format(offset)].Position + vector2(15, tab.offsets[offset] + 15)
    local sizeX   = w.drawings.sectionOutline1.Size.X - 30

    slider.drawings.outline = createDrawing('Square', {
        Visible       = tab.active,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(7, 7, 7),
        Position      = basePos,
        Size          = vector2(sizeX, 15),
        ZIndex        = 11,
    }, w.allDrawings, tab.allDrawings)

    slider.drawings.accent = createDrawing('Square', {
        Visible       = tab.active,
        Filled        = true,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(255, 0, 0),
        Position      = basePos + vector2(1, 1),
        Size          = vector2((sizeX-2)*(slider.value - slider.min)/slider.range, 13),
        ZIndex        = 11,
    }, w.allDrawings, tab.allDrawings)

    slider.drawings.text = createDrawing('Text', {
        Visible       = tab.active,
        Center        = false,
        Outline       = true,
        Transparency  = 1,
        Size          = 13,
        Font          = GLOBAL_FONT,
        Text          = slider.text,
        Color         = color_rgb(195, 195, 195),
        OutlineColor  = color_rgb(0, 0, 0),
        Position      = basePos + vector2(1, -15),
        ZIndex        = 11,
    }, w.allDrawings, tab.allDrawings)

    slider.drawings.value = createDrawing('Text', {
        Visible       = tab.active,
        Center        = true,
        Outline       = true,
        Transparency  = 1,
        Size          = 13,
        Font          = GLOBAL_FONT,
        Text          = slider.value..slider.suffix,
        Color         = color_rgb(195, 195, 195),
        OutlineColor  = color_rgb(0, 0, 0),
        Position      = basePos + vector2(sizeX/2, 1),
        ZIndex        = 12,
    }, w.allDrawings, tab.allDrawings)

    -- Click logic
    w:onClick(slider.drawings.outline, function()
        slider:onClicked()
    end)

    tab.offsets[offset] = tab.offsets[offset] + 35
    return slider
end

function SliderClass:onClicked()
    local outline    = self.drawings.outline
    local startX     = outline.Position.X
    local maxX       = outline.Size.X

    local connection
    connection = runService.RenderStepped:Connect(function()
        if not self.window.mouseHeld then
            connection:Disconnect()
            return
        end
        local offset     = userInputService:GetMouseLocation().X - startX
        local percentage = math_clamp(offset/maxX, 0, 1)

        local val = math_round(self.range * percentage / self.increment)*self.increment + self.min
        self:setValue(val)
    end)
end

function SliderClass:setValue(val)
    self.value       = val
    self.flag.value  = val
    self.flag.Changed(val)

    local outline = self.drawings.outline
    self.drawings.accent.Size = vector2((outline.Size.X - 2)*(self.value - self.min)/self.range, self.drawings.accent.Size.Y)

    local shownValue = val
    if self.maxIndex then
        shownValue = tostring(val)
        local dotPos = string_find(shownValue, '.', 1, true)
        if dotPos then
            shownValue = string_sub(shownValue, 1, self.maxIndex+dotPos)
        end
    end
    self.drawings.value.Text = shownValue..self.suffix
end

-------------------------------------------------------------------------------
-- Dropdown Class
-------------------------------------------------------------------------------
local DropdownClass = createClass()

function DropdownClass:new(tab, options, offset)
    local dropdown = setmetatable({
        tab     = tab,
        window  = tab.window,
        text    = options.text,
        options = options.options,
        value   = options.default or options.options[1] or 'None',
        drawings= {},
    }, DropdownClass)

    -- Flag
    dropdown.flag = {
        type   = 'dropdown',
        value  = dropdown.value,
        self   = dropdown,
        Changed= function() end,
    }
    if options.flag then
        function dropdown.flag:OnChanged(cb)
            dropdown.flag.Changed = cb
            cb(dropdown.flag.value)
        end
        dropdown.window.flags[options.flag] = dropdown.flag
    end

    local w = dropdown.window
    local pos = w.drawings[('sectionOutline%d'):format(offset)].Position + vector2(15, tab.offsets[offset] + 15)
    local sizeX = w.drawings.sectionOutline1.Size.X - 30

    dropdown.drawings.outline = createDrawing('Square', {
        Visible       = tab.active,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(7, 7, 7),
        Position      = pos,
        Size          = vector2(sizeX, 15),
        ZIndex        = 11,
    }, w.allDrawings, tab.allDrawings)

    dropdown.drawings.text = createDrawing('Text', {
        Visible       = tab.active,
        Center        = false,
        Outline       = true,
        Transparency  = 1,
        Size          = 13,
        Font          = GLOBAL_FONT,
        Text          = dropdown.text,
        Color         = color_rgb(195, 195, 195),
        OutlineColor  = color_rgb(0, 0, 0),
        Position      = pos + vector2(1, -15),
        ZIndex        = 11,
    }, w.allDrawings, tab.allDrawings)

    dropdown.drawings.value = createDrawing('Text', {
        Visible       = tab.active,
        Center        = true,
        Outline       = true,
        Transparency  = 1,
        Size          = 13,
        Font          = GLOBAL_FONT,
        Text          = dropdown.value,
        Color         = color_rgb(195, 195, 195),
        OutlineColor  = color_rgb(0, 0, 0),
        Position      = pos + vector2(sizeX/2, 1),
        ZIndex        = 11,
    }, w.allDrawings, tab.allDrawings)

    dropdown.drawings.rightText = createDrawing('Text', {
        Visible       = tab.active,
        Center        = true,
        Outline       = true,
        Transparency  = 1,
        Size          = 13,
        Font          = GLOBAL_FONT,
        Text          = '>',
        Color         = color_rgb(195, 195, 195),
        OutlineColor  = color_rgb(0, 0, 0),
        Position      = pos + vector2(sizeX - 10, 1),
        ZIndex        = 11,
    }, w.allDrawings, tab.allDrawings)

    dropdown.drawings.leftText = createDrawing('Text', {
        Visible       = tab.active,
        Center        = true,
        Outline       = true,
        Transparency  = 1,
        Size          = 13,
        Font          = GLOBAL_FONT,
        Text          = '<',
        Color         = color_rgb(195, 195, 195),
        OutlineColor  = color_rgb(0, 0, 0),
        Position      = pos + vector2(10, 1),
        ZIndex        = 11,
    }, w.allDrawings, tab.allDrawings)

    local rtPos    = dropdown.drawings.rightText.Position
    dropdown.drawings.rightClick = createDrawing('Square', {
        Visible       = tab.active,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(255, 42, 191),
        Position      = rtPos - vector2(dropdown.drawings.rightText.TextBounds.X/2 + 2, 0),
        Size          = vector2(13, 13),
        ZIndex        = -999,
    }, w.allDrawings, tab.allDrawings)

    local ltPos    = dropdown.drawings.leftText.Position
    dropdown.drawings.leftClick = createDrawing('Square', {
        Visible       = tab.active,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(255, 42, 191),
        Position      = ltPos - vector2(dropdown.drawings.leftText.TextBounds.X/2 + 2, 0),
        Size          = vector2(13, 13),
        ZIndex        = -999,
    }, w.allDrawings, tab.allDrawings)

    -- Click logic
    w:onClick(dropdown.drawings.rightClick, function()
        dropdown:onRightClicked()
    end)
    w:onClick(dropdown.drawings.leftClick, function()
        dropdown:onLeftClicked()
    end)

    tab.offsets[offset] = tab.offsets[offset] + 35
    return dropdown
end

function DropdownClass:onRightClicked()
    local idx = table_find(self.options, self.value) or 0
    local nextVal = self.options[idx + 1]
    if not nextVal then
        nextVal = self.options[1] or 'None'
    end
    self:setValue(nextVal)
end

function DropdownClass:onLeftClicked()
    local idx = table_find(self.options, self.value) or 2
    local prevVal = self.options[idx - 1]
    if not prevVal then
        prevVal = self.options[#self.options] or 'None'
    end
    self:setValue(prevVal)
end

function DropdownClass:setValue(val)
    self.value = val
    self.drawings.value.Text = val
    self.flag.value = val
    self.flag.Changed(val)
end

-------------------------------------------------------------------------------
-- Button Class
-------------------------------------------------------------------------------
local ButtonClass = createClass()

function ButtonClass:new(tab, text, onClick, offset)
    local button = setmetatable({
        tab       = tab,
        window    = tab.window,
        text      = text,
        drawings  = {},
        onClickFn = onClick,
    }, ButtonClass)

    local w = button.window
    local pos = w.drawings[('sectionOutline%d'):format(offset)].Position + vector2(15, tab.offsets[offset])
    local sizeX = w.drawings.sectionOutline1.Size.X - 30

    button.drawings.outline = createDrawing('Square', {
        Visible       = tab.active,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(7, 7, 7),
        Position      = pos,
        Size          = vector2(sizeX, 15),
        ZIndex        = 11,
    }, w.allDrawings, tab.allDrawings)

    button.drawings.text = createDrawing('Text', {
        Visible       = tab.active,
        Center        = true,
        Outline       = true,
        Transparency  = 1,
        Size          = 13,
        Font          = GLOBAL_FONT,
        Text          = text,
        Color         = color_rgb(195, 195, 195),
        OutlineColor  = color_rgb(0, 0, 0),
        Position      = pos + vector2(sizeX/2, 1),
        ZIndex        = 12,
    }, w.allDrawings, tab.allDrawings)

    -- Click logic
    w:onClick(button.drawings.outline, function()
        button:onClicked()
    end)

    tab.offsets[offset] = tab.offsets[offset] + 20
    return button
end

function ButtonClass:onClicked()
    self.drawings.text.Color = color_rgb(255, 255, 255)
    task_delay(0.3, function()
        if self.drawings.text then
            self.drawings.text.Color = color_rgb(195, 195, 195)
        end
    end)
    if self.onClickFn then
        self.onClickFn()
    end
end

-------------------------------------------------------------------------------
-- Keypicker Class
-------------------------------------------------------------------------------
local KeypickerClass = createClass()

function KeypickerClass:new(toggle, options)
    local keypicker = setmetatable({
        tab         = toggle.tab,
        toggle      = toggle,
        window      = toggle.window,

        active      = false,
        value       = KEY_CONVERSION[options.default] or options.default or 'None',
        blacklisted = options.blacklisted or {},
        mode        = options.mode or 'toggle',

        drawings    = {},
    }, KeypickerClass)

    -- Flag
    keypicker.flag = {
        type   = 'keypicker',
        key    = keypicker.value,
        value  = false,
        self   = keypicker,
        Changed= function() end,
    }
    if options.flag then
        function keypicker.flag:OnChanged(cb)
            keypicker.flag.Changed = cb
            cb(keypicker.flag.value)
        end
        keypicker.window.flags[options.flag] = keypicker.flag
    end

    -- Drawings
    local pos = toggle.drawings.outline.Position + vector2(
        keypicker.window.drawings.sectionOutline1.Size.X - 30, 
        0
    )

    keypicker.drawings.text = createDrawing('Text', {
        Visible       = keypicker.tab.active,
        Outline       = true,
        Transparency  = 1,
        Size          = 13,
        Font          = GLOBAL_FONT,
        Text          = "[ loading ]",
        Color         = color_rgb(195, 195, 195),
        OutlineColor  = color_rgb(0, 0, 0),
        ZIndex        = 12,
    }, keypicker.window.allDrawings, keypicker.tab.allDrawings)

    keypicker.drawings.clickDetector = createDrawing('Square', {
        Visible       = keypicker.tab.active,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(255, 42, 191),
        ZIndex        = -999,
    }, keypicker.window.allDrawings, keypicker.tab.allDrawings)

    -- Add input watchers
    keypicker.window:addKeyDetector(function(input, _)
        keypicker:onKeyPress(input)
    end)

    keypicker.window:addKeyEnd(function(input, _)
        keypicker:onKeyEnd(input)
    end)

    -- Setup clicks
    keypicker.window:onClick(keypicker.drawings.clickDetector, function()
        keypicker:onClicked()
    end)

    keypicker:update()
    return keypicker
end

function KeypickerClass:onKeyPress(input)
    if self.active then
        local keyValue = input.KeyCode.Name
        if keyValue == "Unknown" then
            keyValue = input.UserInputType.Name
            if keyValue ~= "MouseButton2" then
                return
            end
        end
        -- check blacklisted
        for _, black in ipairs(self.blacklisted) do
            if black == keyValue then
                return
            end
        end
        self.active    = false
        self.value     = KEY_CONVERSION[keyValue] or keyValue
        self.flag.key  = self.value
        self:update()
    else
        if self.value == 'None' then
            return
        end
        local keyValue = input.KeyCode.Name
        if keyValue == "Unknown" then
            keyValue = input.UserInputType.Name
            if keyValue ~= "MouseButton2" then
                return
            end
        end
        keyValue = KEY_CONVERSION[keyValue] or keyValue
        if self.value == keyValue then
            -- If not toggle mode, just set to true until released
            local newVal = (self.mode ~= 'toggle') or (not self.flag.value)
            self.flag.value = newVal
            self.flag.Changed(newVal)
        end
    end
end

function KeypickerClass:onKeyEnd(input)
    if self.active or self.value == 'None' or self.mode == 'toggle' then
        return
    end
    local keyValue = input.KeyCode.Name
    if keyValue == "Unknown" then
        keyValue = input.UserInputType.Name
        if keyValue ~= "MouseButton2" then
            return
        end
    end
    keyValue = KEY_CONVERSION[keyValue] or keyValue
    if self.value == keyValue then
        self.flag.value = false
        self.flag.Changed(false)
    end
end

function KeypickerClass:onClicked()
    -- If we are already “active”, setting again resets to None
    if self.active then
        self.active   = false
        self.value    = 'None'
        self:update()
        return
    end

    self.flag.value = false
    self.active     = true
    self.value      = '...'
    self:update()
end

function KeypickerClass:update()
    local textObj   = self.drawings.text
    local detectObj = self.drawings.clickDetector
    textObj.Text    = ("[%s]"):format(self.value)

    local bounds    = textObj.TextBounds
    local xPos      = self.toggle.drawings.outline.Position.X + (self.window.drawings.sectionOutline1.Size.X - 30 - bounds.X)
    local yPos      = self.toggle.drawings.outline.Position.Y

    textObj.Position = vector2(xPos, yPos)
    detectObj.Size   = bounds
    detectObj.Position = textObj.Position
end

function KeypickerClass:setValue(isDown, newKey)
    self.value        = newKey
    self.flag.value   = isDown
    self.flag.Changed(isDown)
    self:update()
end

-------------------------------------------------------------------------------
-- ColourPicker Class
-------------------------------------------------------------------------------
local ColourpickerClass = createClass()

function ColourpickerClass:new(toggle, options)
    local colourpicker = setmetatable({
        tab     = toggle.tab,
        toggle  = toggle,
        window  = toggle.window,
        drawings= {},
        onToggle= {},

        value   = options.default or color_rgb(255,255,255),
        h       = 0,
        s       = 0,
        v       = 0,
    }, ColourpickerClass)

    colourpicker.h, colourpicker.s, colourpicker.v = colourpicker.value:ToHSV()

    -- Flag
    colourpicker.flag = {
        type   = 'colourpicker',
        value  = colourpicker.value,
        self   = colourpicker,
        Changed= function() end,
    }
    if options.flag then
        function colourpicker.flag:OnChanged(cb)
            colourpicker.flag.Changed = cb
            cb(colourpicker.flag.value)
        end
        colourpicker.window.flags[options.flag] = colourpicker.flag
    end

    -- Make sure assets exist
    loadAssets()

    local w = colourpicker.window
    local pos = toggle.drawings.outline.Position + vector2(
        w.drawings.sectionOutline1.Size.X - 60, 
        0
    )

    -- The “small preview” next to the Toggle
    colourpicker.drawings.colour_fill = createDrawing('Square', {
        Visible       = colourpicker.tab.active,
        Filled        = true,
        Transparency  = 1,
        Thickness     = 1,
        Color         = colourpicker.value,
        Position      = pos,
        Size          = vector2(30, 15),
        ZIndex        = 11,
    }, w.allDrawings, colourpicker.tab.allDrawings)

    colourpicker.drawings.colour_outline = createDrawing('Square', {
        Visible       = colourpicker.tab.active,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(0, 0, 0),
        Position      = pos,
        Size          = vector2(30, 15),
        ZIndex        = 12,
    }, w.allDrawings, colourpicker.tab.allDrawings)

    -- The actual big colour picker (hidden initially)
    local bigPos  = pos + vector2(0, 20)

    colourpicker.drawings.background_fill = createDrawing('Square', {
        Visible       = false,
        Filled        = true,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(39, 39, 39),
        Position      = bigPos,
        Size          = vector2(150, 150),
        ZIndex        = 13,
    }, w.allDrawings, colourpicker.onToggle, colourpicker.tab.toggleDrawings)

    colourpicker.drawings.background_outline = createDrawing('Square', {
        Visible       = false,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(0, 0, 0),
        Position      = bigPos,
        Size          = vector2(150, 150),
        ZIndex        = 14,
    }, w.allDrawings, w.overlapDrawings, colourpicker.onToggle, colourpicker.tab.toggleDrawings)

    local cpPos = bigPos + vector2(5, 5)
    colourpicker.drawings.colourpicker_fill = createDrawing('Square', {
        Visible       = false,
        Filled        = true,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_hsv(colourpicker.h,1,1),
        Position      = cpPos,
        Size          = vector2(125, 125),
        ZIndex        = 14,
    }, w.allDrawings, colourpicker.onToggle, colourpicker.tab.toggleDrawings)

    colourpicker.drawings.colourpicker_overlay = createDrawing('Image', {
        Visible       = false,
        Transparency  = 1,
        Data          = readfile('amghook\\assets\\overlay.png'),
        Position      = cpPos,
        Size          = vector2(125, 125),
        ZIndex        = 15,
    }, w.allDrawings, colourpicker.onToggle, colourpicker.tab.toggleDrawings)

    colourpicker.drawings.colourpicker_outline = createDrawing('Square', {
        Visible       = false,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(1, 1, 1),
        Position      = cpPos,
        Size          = vector2(125,125),
        ZIndex        = 16,
    }, w.allDrawings, colourpicker.onToggle, colourpicker.tab.toggleDrawings)

    local huePos = cpPos + vector2(125 + 5, 0)
    colourpicker.drawings.hue_fill = createDrawing('Image', {
        Visible       = false,
        Transparency  = 1,
        Data          = readfile('amghook\\assets\\hue.png'),
        Position      = huePos,
        Size          = vector2(10, 125),
        ZIndex        = 14,
    }, w.allDrawings, colourpicker.onToggle, colourpicker.tab.toggleDrawings)

    colourpicker.drawings.hue_outline = createDrawing('Square', {
        Visible       = false,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(0, 0, 0),
        Position      = huePos,
        Size          = vector2(10,125),
        ZIndex        = 15,
    }, w.allDrawings, colourpicker.onToggle, colourpicker.tab.toggleDrawings)

    colourpicker.drawings.huepicker = createDrawing('Square', {
        Visible       = false,
        Filled        = true,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(255, 255, 255),
        Size          = vector2(14, 6),
        ZIndex        = 16,
    }, w.allDrawings, colourpicker.onToggle, colourpicker.tab.toggleDrawings)

    colourpicker.drawings.huepicker_outline = createDrawing('Square', {
        Visible       = false,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(0, 0, 0),
        Size          = vector2(14, 6),
        ZIndex        = 17,
    }, w.allDrawings, colourpicker.onToggle, colourpicker.tab.toggleDrawings)

    colourpicker.drawings.colourpick = createDrawing('Square', {
        Visible       = false,
        Filled        = true,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(255, 255, 255),
        Size          = vector2(6, 6),
        ZIndex        = 16,
    }, w.allDrawings, colourpicker.onToggle, colourpicker.tab.toggleDrawings)

    colourpicker.drawings.colourpick_outline = createDrawing('Square', {
        Visible       = false,
        Filled        = false,
        Transparency  = 1,
        Thickness     = 1,
        Color         = color_rgb(0, 0, 0),
        Size          = vector2(6, 6),
        ZIndex        = 17,
    }, w.allDrawings, colourpicker.onToggle, colourpicker.tab.toggleDrawings)

    -- Setup clicks
    w:onClick(colourpicker.drawings.colour_outline, function()
        colourpicker:togglePicker()
    end)
    w:onClick(colourpicker.drawings.hue_outline, function()
        colourpicker:onHueClicked()
    end, nil, true)
    w:onClick(colourpicker.drawings.colourpicker_outline, function()
        colourpicker:onColourpickClicked()
    end, nil, true)

    colourpicker:update()
    return colourpicker
end

function ColourpickerClass:togglePicker()
    local isNowVisible = not self.drawings.background_fill.Visible

    local allToggleDrawings = self.tab.toggleDrawings
    for _, drw in ipairs(allToggleDrawings) do
        drw.Visible = false
    end
    for _, drw in ipairs(self.onToggle) do
        drw.Visible = isNowVisible
    end
end

function ColourpickerClass:onHueClicked()
    local hueOut   = self.drawings.hue_outline
    local startY   = hueOut.Position.Y
    local sizeY    = hueOut.Size.Y

    local conn
    conn = runService.RenderStepped:Connect(function()
        if not self.window.mouseHeld then
            conn:Disconnect()
            return
        end
        local pct = math_clamp((userInputService:GetMouseLocation().Y - startY)/sizeY, 0, 1)
        self.h = pct

        local draw = self.drawings
        draw.huepicker.Position          = hueOut.Position + vector2(-2, math_round((sizeY - 6)*pct))
        draw.huepicker_outline.Position  = draw.huepicker.Position
        self:updateHue()
    end)
end

function ColourpickerClass:onColourpickClicked()
    local cpOut   = self.drawings.colourpicker_outline
    local basePos = cpOut.Position
    local maxSize = cpOut.Size - vector2(6,6)

    local conn
    conn = runService.RenderStepped:Connect(function()
        if not self.window.mouseHeld then
            conn:Disconnect()
            return
        end
        local offset    = (userInputService:GetMouseLocation() - basePos)/cpOut.Size
        self.s          = math_clamp(offset.X, 0, 1)
        self.v          = math_abs(math_clamp(offset.Y, 0, 1) - 1)

        local pickPos   = basePos + vector2(
            maxSize.X * self.s, 
            maxSize.Y * math_abs(self.v - 1)
        )
        pickPos         = vector2(math_round(pickPos.X), math_round(pickPos.Y))

        self.drawings.colourpick.Position         = pickPos
        self.drawings.colourpick_outline.Position = pickPos
        self:updateSaturationValue()
    end)
end

function ColourpickerClass:updateHue()
    local val = color_hsv(self.h, self.s, self.v)
    self.drawings.colourpicker_fill.Color = color_hsv(self.h,1,1)
    self.drawings.colour_fill.Color       = val
    self.value = val
    self.flag.value = val
    self.flag.Changed(val)
end

function ColourpickerClass:updateSaturationValue()
    local val = color_hsv(self.h, self.s, self.v)
    self.drawings.colour_fill.Color = val
    self.value = val
    self.flag.value = val
    self.flag.Changed(val)
end

function ColourpickerClass:update()
    self.h, self.s, self.v = self.value:ToHSV()

    local d = self.drawings
    d.colourpicker_fill.Color = color_hsv(self.h,1,1)
    d.colour_fill.Color       = self.value

    local cpOut   = d.colourpicker_outline
    local hueOut  = d.hue_outline

    local maxHue  = hueOut.Size.Y - 6
    d.huepicker.Position         = hueOut.Position + vector2(-2, maxHue*self.h)
    d.huepicker_outline.Position = d.huepicker.Position

    local maxCP  = cpOut.Size - vector2(6,6)
    local cpPosX = cpOut.Position.X + (maxCP.X * self.s)
    local cpPosY = cpOut.Position.Y + (maxCP.Y * math_abs(self.v - 1))

    d.colourpick.Position         = vector2(math_round(cpPosX), math_round(cpPosY))
    d.colourpick_outline.Position = d.colourpick.Position
end

function ColourpickerClass:setValue(col)
    self.value = col
    self.flag.value = col
    self.flag.Changed(col)
    self:update()
end

return WindowClass, 2
