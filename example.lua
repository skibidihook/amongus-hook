-- initialization
local LibraryLib = game:HttpGet("https://raw.githubusercontent.com/mainstreamed/amongus-hook/refs/heads/main/uilibrary.lua")
local Library, flags = loadstring(LibraryLib)()

-- creates a new tab named "Example Tab"
local tab = Library:AddTab("Example Tab")

-- adds a button to the example tab
tab:AddButton("Click Me", function()
    print("Button clicked!")
end)

-- adds a toggle to the example tab
tab:AddToggle({
    text = "Toggle Option",
    default = false,
    flag = "ToggleOption",
    callback = function(state)
        print("Toggle state: " .. tostring(state))
    end
})

-- adds a slider to the example tab
tab:AddSlider({
    text = "Volume",
    default = 5,
    min = 0,
    max = 10,
    suffix = "",
    flag = "VolumeLevel",
    callback = function(value)
        print("Slider value: " .. value)
    end
})

-- adds a dropdown to the example tab
tab:AddDropdown({
    text = "Select Mode",
    options = {"Easy", "Medium", "Hard"},
    default = "Medium",
    flag = "GameMode",
    callback = function(value)
        print("Dropdown selected: " .. value)
    end
})
