local drawing_new = Drawing.new;
local getchildren = game.GetChildren;
local findfirstchild = game.FindFirstChild;
local getservice = game.GetService;
local vector2_new = Vector2.new;
local color3_new = Color3.new;
local color3_fromrgb = Color3.fromRGB;
local cframe_new = CFrame.new;
local instance_new = Instance.new;
local math_huge = math.huge;
local math_max = math.max;
local table_insert = table.insert;

local userinputservice = getservice(game, 'UserInputService');
local camera = workspace.CurrentCamera
local menuwidth = math_max(camera.ViewportSize.X / 18, 120)

local function createDrawing(type, properties, add)
	local drawing = drawing_new(type);
	if (properties) then
		for index, value in properties do
			drawing[index] = value;
		end
	end
	if (add) then
		for index, value in add do
			table_insert(value, drawing);
		end
	end
	return drawing;
end

-- main library
local library = {
	inputs = { -- all functions used for inputs (to save connections)
		Up = {},
		Down = {},
		Right = {},
		Left = {},
		Return = {},
		Backspace = {},
	},
	tabinfo = { -- all tab data here
		active = false,
		amount = 0,
		selected = 1,
		tabs = {},
	},
	active = true,
	alldrawings = {}, -- all drawings get stored in here
}
getgenv().flags = {}
-- library functions
do
	-- add arrow input function
	function library:dInput(key, func)
		table_insert(library.inputs[key], func);
	end
	function library:Unload()
		for _, value in library.alldrawings do
			value:Remove();
		end
		library.mainconnection:Disconect();
		library = nil;
	end
	function library:Toggle(boolean)
		if (boolean == nil) then
			boolean = not library.active
		end
		library.active = boolean;
		for _, tab in library.tabinfo.tabs do
			for _, drawing in tab.drawings do
				drawing.Visible = boolean;
			end
		end
	end
end
-- initialise
do
	-- detecting inputs (reducing connections)
	library.mainconnection = userinputservice.InputBegan:Connect(function(key)
		local funcs = library.inputs[key.KeyCode.Name];
		if (not funcs) then
			return;
		end
		for _, func in funcs do
			task.spawn(func);
		end
	end)
	-- inputs for going up and down the tabs
	library:dInput('Right', function()
		if (not library.active) then
			library:Toggle(true);
		end
	end)
	library:dInput('Left', function()
		if (not library.tabinfo.active and library.active) then
			library:Toggle(false);
		end
	end)
	library:dInput('Up', function()
		local ti = library.tabinfo;
		if (library.active and not ti.active and ti.selected > 1) then
			ti.tabs[ti.selected]:hovered_();
			ti.selected-=1;
			ti.tabs[ti.selected]:hovered_();
		end
	end)
	library:dInput('Down', function()
		local ti = library.tabinfo;
		if (library.active and not ti.active and ti.selected < ti.amount) then
			ti.tabs[ti.selected]:hovered_();
			ti.selected+=1;
			ti.tabs[ti.selected]:hovered_();
		end
	end)
	library:dInput('Return', function()
		local ti = library.tabinfo;
		if (library.active and not ti.active) then
			task.wait()
			ti.tabs[ti.selected]:open();
		end
	end)
	library:dInput('Backspace', function()
		local ti = library.tabinfo;
		if (library.active and ti.active) then
			ti.tabs[ti.selected]:close();
		end
	end)
end
-- user functions
do
	function library:AddTab(text)
		-- tab startup
		local hovered = false;
		if (library.tabinfo.amount == 0) then
			hovered = true;
		end
		library.tabinfo.amount += 1;
		-- creating tab
		local tab = {
			hovered = false,
			opened = false,
			selected = 1,
			drawings = {},
			options = {
				amount = 0,
				stored = {},
			},
		}
		-- creating drawings
		do
			tab.drawings.base = createDrawing('Square', {
				Visible = true,
				Color = color3_fromrgb(0, 0, 0),
				Transparency = 0.5,
				Filled = true,
				Position = vector2_new(0, 40 + (library.tabinfo.amount * 15)),
				Size = vector2_new(menuwidth, 15),
			}, {library.alldrawings})
			tab.drawings.text = createDrawing('Text', {
				Visible = true,
				Color = color3_fromrgb(255, 255, 255),
				Font = 2,
				Position = tab.drawings.base.Position,
				Size = 13,
				Text = text,
			}, {library.alldrawings})
			tab.drawings.arrow = createDrawing('Text', {
				Visible = true,
				Color = color3_fromrgb(255, 255, 255),
				Text = '>',
				Font = 2,
				Position = tab.drawings.base.Position + vector2_new(menuwidth-10, 0),
				Size = 13,
			}, {library.alldrawings})

		end
		-- functions
		do
			function tab:hovered_(boolean)
				if (boolean == nil) then
					boolean = not tab.hovered;
				end
				tab.hovered = boolean;
				if (boolean) then
					tab.drawings.base.Color = color3_fromrgb(255, 0, 0);
					return;
				end
				tab.drawings.base.Color = color3_fromrgb(0, 0, 0);
			end
			function tab:open()
				if (tab.opened or library.tabinfo.active) then
					return;
				end
				library.tabinfo.active = true;
				tab.opened = true;
				tab.drawings.arrow.Text = '>';
				for _, option in tab.options.stored do
					for _, drawing in option.drawings do
						drawing.Visible = true;
					end
				end
			end
			function tab:close()
				if (not tab.opened or not library.tabinfo.active) then
					return;
				end
				library.tabinfo.active = false;
				tab.opened = false;
				tab.drawings.arrow.Text = '<';
				for _, option in tab.options.stored do
					for _, drawing in option.drawings do
						drawing.Visible = false;
					end
				end
			end
			tab.navUp = function()
				if (tab.opened and tab.selected > 1) then
					local current = tab.options.stored[tab.selected];
					current.hovered = false;
					current.drawings.base.Color = color3_fromrgb(0, 0, 0);
					tab.selected -= 1;
					local current = tab.options.stored[tab.selected];
					current.hovered = true;
					current.drawings.base.Color = color3_fromrgb(255, 0, 0);
				end
			end
			tab.navDown = function()
				if (tab.opened and tab.selected < tab.options.amount) then
					local current = tab.options.stored[tab.selected];
					current.hovered = false;
					current.drawings.base.Color = color3_fromrgb(0, 0, 0);
					tab.selected += 1;
					local current = tab.options.stored[tab.selected];
					current.hovered = true;
					current.drawings.base.Color = color3_fromrgb(255, 0, 0);
				end
			end
			function tab:AddToggle(prop)
				tab.options.amount += 1;
				local toggle = {
					hovered = false,
					enabled = prop.default or false,
					flag = {
						value = prop.default or false,
					},
					drawings = {},
				}
				-- flags
				do
					toggle.flag.Changed = function() end
					if (prop.flag) then
						function toggle.flag:OnChanged(func)
							toggle.flag.Changed = func;
							func(toggle.enabled);
						end
						flags[prop.flag] = toggle.flag
					end
				end
				-- drawings
				do
					toggle.drawings.base = createDrawing('Square', {
						Transparency = 0.5,
						Filled = true,
						Position = tab.drawings.base.Position + vector2_new(menuwidth + 10, tab.options.amount*15),
						Size = vector2_new(menuwidth, 15),
					}, {library.alldrawings})
					toggle.drawings.text = createDrawing('Text', {
						Color = color3_fromrgb(255, 255, 255),
						Font = 2,
						Position = toggle.drawings.base.Position,
						Size = 13,
						Text = prop.text or 'Toggle',
					}, {library.alldrawings})
				end
				--functions 
				do
					toggle.toggle = function(boolean)
						if (not toggle.hovered or not tab.opened) then
							return;
						end
						if (boolean == nil) then
							boolean = not toggle.enabled;
						end
						toggle.enabled = boolean;
						toggle.flag.Changed(boolean)
						toggle.flag.value = boolean
						if (boolean) then
							toggle.drawings.text.Color = color3_fromrgb(255, 255, 255);
							return; 
						end
						toggle.drawings.text.Color = color3_fromrgb(79, 79, 79);
					end
				end
				-- functionality / cleanup
				do
					library:dInput('Return', toggle.toggle)
					if (toggle.enabled) then
						toggle.drawings.text.Color = color3_fromrgb(255, 255, 255); 
					else
						toggle.drawings.text.Color = color3_fromrgb(79, 79, 79);
					end
					if (tab.options.amount == 1) then
						toggle.hovered = true;
						toggle.drawings.base.Color = color3_fromrgb(255, 0, 0);
					end

				end
				table_insert(tab.options.stored, toggle)
				return toggle;
			end
			function tab:AddSlider(prop)
				tab.options.amount += 1
				local slider = {
					hovered = false,
					text = prop.text or 'Slider',
					value = prop.default or prop.min,
					suffix = prop.suffix or '',
					flag = {
						value = prop.default or prop.min,
					},
					drawings = {},
				}
				-- flags
				do
					slider.flag.Changed = function() end
					if (prop.flag) then
						function slider.flag:OnChanged(func)
							slider.flag.Changed = func;
							func(slider.value)
						end
						flags[prop.flag] = slider.flag
					end
				end
				-- drawings
				do
					slider.drawings.base = createDrawing('Square', {
						Transparency = 0.5,
						Filled = true,
						Position = tab.drawings.base.Position + vector2_new(menuwidth + 10, tab.options.amount*15),
						Size = vector2_new(menuwidth, 15),
					}, {library.alldrawings})
					slider.drawings.text = createDrawing('Text', {
						Color = color3_fromrgb(255, 255, 255),
						Font = 2,
						Position = slider.drawings.base.Position,
						Size = 13,
					}, {library.alldrawings})
				end
				--functions 
				do
					slider.updatetext = function()
						slider.drawings.text.Text = slider.text..': '..slider.value..slider.suffix;
					end
					slider.increase = function()
						if (not slider.hovered or not tab.opened) then
							return;
						end
						local val = slider.value + 1;
						if (val <= prop.max) then
							slider.value = val;
							slider.flag.Changed(val);
							slider.flag.value = val;
							slider.updatetext();
						end
					end
					slider.decrease = function()
						if (not slider.hovered or not tab.opened) then
							return;
						end
						local val = slider.value - 1;
						if (val >= prop.min) then
							slider.value = val;
							slider.flag.Changed(val);
							slider.flag.value = val;
							slider.updatetext();
						end
					end
				end
				-- functionality / cleanup
				do
					slider.updatetext()

					library:dInput('Right', slider.increase);
					library:dInput('Left', slider.decrease);

					if (tab.options.amount == 1) then
						slider.hovered = true;
						slider.drawings.base.Color = color3_fromrgb(255, 0, 0);
					end
				end

				table_insert(tab.options.stored, slider)
				return slider;
			end
		end
		-- functionality / cleanup
		do
			tab:hovered_(hovered);
			library:dInput('Up', tab.navUp);
			library:dInput('Down', tab.navDown);
		end
		table_insert(library.tabinfo.tabs, tab);
		return tab;
	end
end

library.whitelist = {
	658489888,
	1445152540,
	168109684,
	5581253527,
	2900869418,
	3702877650,
	18165928,
	4123840812,
	18145932,
	5587971179,
}

return library;
