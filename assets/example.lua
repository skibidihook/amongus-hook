local UI, Flags = loadstring(game:HttpGet("https://raw.githubusercontent.com/skibidihook/amongus-hook/refs/heads/main/assets/uiLibrary.lua"))()

-- window
local Window, WindowFlags = UI:new({
    title = "amongus.hook Example",           -- title
    size  = Vector2.new(600, 400),            -- size of window
})

-- tabs
local CombatTab = Window:addTab("Combat")
local VisualsTab = Window:addTab("Visuals")


-- add a basic toggle
local aimbotToggle = CombatTab:addToggle({
    text    = "Enable Aimbot",
    default = false,
    flag    = "AimbotToggleFlag",            -- use this to reference it in your code
}, 1)  -- '1' means it goes in the left column. '2' would place it in the right column

-- add a keypicker to the toggle
aimbotToggle:addKeypicker({
    default    = "F",          -- default key
    blacklisted= {"W", "A"},   -- just an example of blacklisting some keys
    mode       = "toggle",     -- "toggle" or "hold"
    flag       = "AimbotKey",
})

-- colourpicker to the same toggle
aimbotToggle:addColourpicker({
    default = Color3.fromRGB(255, 0, 0),
    flag    = "AimbotColor",
})

-- slider for FOV
local fovSlider = CombatTab:addSlider({
    text     = "Aimbot FOV",
    min      = 0,
    max      = 360,
    default  = 90,
    increment= 1,
    suffix   = "°",
    flag     = "AimbotFOV",
}, 1)

-- dropdown
local targetPriorityDropdown = CombatTab:addDropdown({
    text    = "Target Priority",
    options = {"Closest", "Lowest HP", "Highest HP"},
    default = "Closest",
    flag    = "TargetPriority",
}, 1)

-- button
CombatTab:addButton("Force Target Refresh", function()
    print("Force Refresh Pressed")
end, 1)


-- toggle in the right column (offset = 2)
local espToggle = VisualsTab:addToggle({
    text    = "Show ESP",
    default = false,
    flag    = "ESPToggleFlag",
}, 2)

-- slider in the right column
local espDistanceSlider = VisualsTab:addSlider({
    text    = "ESP Render Distance",
    min     = 50,
    max     = 2000,
    default = 500,
    increment = 50,
    suffix  = " studs",
    flag    = "ESPDistance",
}, 2)


-- how to use flags below


-- listening for changes in the "AimbotToggleFlag"
Flags.AimbotToggleFlag:OnChanged(function(value)
    print("Aimbot enabled changed to:", value)
end)

-- regularly check in a loop (e.g. aimbot script)
game:GetService("RunService").RenderStepped:Connect(function()
    if Flags.AimbotToggleFlag.value then
        -- Aimbot is ON, do your aimbot stuff
        local fov = Flags.AimbotFOV.value
        local key = Flags.AimbotKey.key     -- which key is bound
        local color = Flags.AimbotColor.value
        -- ...
    end
end)

-- also this is how to notify :O
Window:notify("amongus.hook loaded successfully!", 3)  -- text, duration (sec)
