-- skibidi example..
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/skibidihook/amongus-hook/refs/heads/main/assets/uiLibrary.lua"))()

-- create window and flags
local Window, Flags = Library:new({
    title = "amongus.hook Example", -- title
    size  = Vector2.new(600, 400),  -- window size
})

-- tabs
local CombatTab = Window:addTab("Combat")
local VisualsTab = Window:addTab("Visuals")

-- toggle
local aimbotToggle = CombatTab:addToggle({
    text    = "Aimbot",
    default = false,
    flag    = "AimbotToggleFlag",
}, 1)

-- keypicker
aimbotToggle:addKeypicker({
    default     = "F",
    blacklisted = {"W", "A"},
    mode        = "toggle", -- can do hold too
    flag        = "AimbotKey",
})

-- slider
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

-- toggle in right column
local espToggle = VisualsTab:addToggle({
    text    = "Show ESP",
    default = false,
    flag    = "ESPToggleFlag",
}, 2)

-- slider in right column
local espDistanceSlider = VisualsTab:addSlider({
    text      = "ESP Render Distance",
    min       = 50,
    max       = 2000,
    default   = 500,
    increment = 50,
    suffix    = " studs",
    flag      = "ESPDistance",
}, 2)

-- listen for changes in "AimbotToggleFlag"
Flags.AimbotToggleFlag:OnChanged(function(value)
    print("Aimbot enabled changed to:", value)
end)

-- loop check
game:GetService("RunService").RenderStepped:Connect(function()
    if Flags.AimbotToggleFlag.value then
        local fov   = Flags.AimbotFOV.value
        local key   = Flags.AimbotKey.key
        local color = Flags.AimbotColor.value
        -- do aimbot stuff
    end
end)

-- super cool notify!
Window:notify("amongus.hook loaded successfully!", 3)
