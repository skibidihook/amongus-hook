--[[
      camelCase
      CCLASS BASED (OMG OOP) OOP OOP OOP IN LUA
      
      
      yes yes
      boom!!
      mADE JUST FOR FALLELNNN XOXOOXOXO

      DONT USE IT OR ELSE :angry:
	tab spacing is scuffed asf (might need to fix if i can be bothered (I CANT) )
]]

--[[
	TODO:
	- take advanatge of the classes more ( dont have local onclicked functions and whatnot )
]]

-- w constants
local GLOBAL_FONT = 1;
local KEY_CONVERSION = {
	['One'] 		= '1';
	['Two'] 		= '2';
	['Three'] 		= '3';
	['Four'] 		= '4';
	['Five'] 		= '5';
	['Six'] 		= '6';
	['Seven'] 		= '7';
	['Eight'] 		= '8';
	['Nine'] 		= '9';
	['Zero'] 		= '0';
	['Return'] 		= 'Enter';
	['LeftBracket'] 	= 'LBracket';
	['RightBracket'] 	= 'RBracket';
	['Equals'] 		= '=';
	['Minus'] 		= '-';
	['Escape'] 		= 'Esc';
	['LeftShift'] 	= 'LShift';
	['RightShift'] 	= 'RShift';
	['RightControl'] 	= 'RCtrl';
	['LeftControl'] 	= 'LCtrl';
	['Quote'] 		= "'";
	['Semicolon']	= ';';
	['Delete'] 		= 'Del';
	['Up'] 		= 'UpArrow';
	['Down'] 		= 'DownArrow';
	['Right'] 		= 'RightArrow';
	['Left'] 		= 'LeftArrow';
	['RightAlt'] 	= 'RAlt';
	['LeftAlt'] 	= 'LAlt';
	['MouseButton2'] 	= 'MB2';
};

-- local Drawing = require(script.Drawing);

local cloneref		= cloneref or function(...) return ... end;


-- defines ugh (ok this is snake case cuz yea)
local drawing_new       = Drawing and Drawing.new;
local vector2           = Vector2.new;
local color_rgb         = Color3.fromRGB;

local math_clamp		= math.clamp;
local math_round		= math.round;

local task_spawn		= task.spawn;
local task_delay 		= task.delay;

local table_insert      = table.insert;
local table_find 		= table.find;

local string_find       = string.find;
local string_sub        = string.sub;
local tostring          = tostring;

local userInputService: UserInputService 	= cloneref(game:GetService('UserInputService'));
local runService: RunService 			= cloneref(game:GetService('RunService'));

local camera            = cloneref(workspace.CurrentCamera);






local createDrawing = function(_type, properties, ...)
	local drawing = drawing_new(_type);
	for index, value in properties do
		drawing[index] = value;
	end;
	for _, _table in {...} do
		table_insert(_table, drawing);
	end;
	return drawing;
end;
local createClass = function(_table: table?): table -- Creates an empty class (yea no problem for the info)
	local class = _table or {};
	class.__index = class;
	return class;
end;


-- class DEFIITIONS (yea!)
local windowClass       = createClass({
	index = 0;

});
local tabClass          = createClass();
local toggleClass       = createClass();
local sliderClass       = createClass();
local dropdownClass	= createClass();
local buttonClass		= createClass();
local keypickerClass	= createClass();



windowClass.new = function(options: table)
	assert(type(options) == 'table', `invalid argument #1 to 'windowClass.new' (table expected, got {type(options)})`);
	windowClass.index += 1;

	local window = setmetatable({
		id                = windowClass.index;
		active            = true;
		title             = options.title or 'amongus.hook';
		size              = options.size or vector2(600, 500);
		position          = camera.ViewportSize / 2;

		tabSettings       = {
			index = 0;
			tabs = {};
		};

		clickDetectors 	= {};
		keyDetectors 	= {};
		keyEnd		= {};
		flags             = {}; -- cheeky flags :P
		connectedToggles	= {};

		drawings          = {};
		allDrawings       = {};
		overlapDrawings   = {};
	}, windowClass);

	-- drawings
	do
		local drawings = window.drawings;

		drawings.base     = createDrawing('Square', {
			Visible           = window.active;
			Filled            = true;
			Transparency      = 1;
			Thickness         = 1;
			Color             = color_rgb(39, 39, 39);
			Position          = window.position - window.size / 2;
			Size              = window.size;
			ZIndex            = 10;
		}, window.allDrawings);

		drawings.onDrag	= createDrawing('Square', {
			Visible           = window.active;
			Filled            = false;
			Transparency      = 1;
			Thickness         = 1;
			Color             = color_rgb(255, 42, 191);
			Position          = drawings.base.Position;
			Size              = vector2(window.size.X, 20);
			ZIndex            = -999;
		},  window.allDrawings);



		drawings.baseOutline = createDrawing('Square', {
			Visible           = window.active;
			Filled            = false;
			Transparency      = 1;
			Thickness         = 1;
			Color             = color_rgb(7, 7, 7);
			Position          = drawings.base.Position - vector2(1, 1);
			Size              = drawings.base.Size + vector2(2, 2);
			ZIndex            = 11;
		}, window.allDrawings);

		drawings.innerOutline = createDrawing('Square', {
			Visible           = window.active;
			Filled            = false;
			Transparency      = 1;
			Thickness         = 1;
			Color             = color_rgb(7, 7, 7);
			Position          = drawings.baseOutline.Position + vector2(0, 20);
			Size              = drawings.base.Size + vector2(2, 2) - vector2(0, 20);
			ZIndex            = 11;
		}, window.allDrawings);
		drawings.innerOutline2 = createDrawing('Square', {
			Visible           = window.active;
			Filled            = false;
			Transparency      = 1;
			Thickness         = 1;
			Color             = color_rgb(7, 7, 7);
			Position          = drawings.innerOutline.Position + vector2(0, 40);
			Size              = drawings.innerOutline.Size - vector2(0, 40);
			ZIndex            = 11;
		}, window.allDrawings);
		drawings.sectionOutline1 = createDrawing('Square', {
			Visible           = window.active;
			Filled            = false;
			Transparency      = 1;
			Thickness         = 1;
			Color             = color_rgb(7, 7, 7);
			Position          = drawings.innerOutline2.Position + vector2(16, 16);
			Size              = drawings.innerOutline2.Size - vector2(drawings.innerOutline2.Size.X / 2 + 24, 32);
			ZIndex            = 11;
		}, window.allDrawings);
		drawings.sectionOutline2 = createDrawing('Square', {
			Visible           = window.active;
			Filled            = false;
			Transparency      = 1;
			Thickness         = 1;
			Color             = color_rgb(7, 7, 7);
			Position          = drawings.innerOutline2.Position + vector2(drawings.innerOutline2.Size.X / 2 + 8, 16);
			Size              = drawings.sectionOutline1.Size;
			ZIndex            = 11;
		}, window.allDrawings);

		drawings.title = createDrawing('Text', {
			Visible           = window.active;
			Center            = false;
			Outline           = true;
			Transparency      = 1;
			Size              = 13;
			Font              = GLOBAL_FONT;
			Text              = window.title;
			Color             = color_rgb(195, 195, 195);
			OutlineColor      = color_rgb(0, 0, 0);
			Position          = drawings.base.Position + vector2(2, 2);
			ZIndex            = 11;
		}, window.allDrawings);
	end;

	-- setup
	do
		-- click detectors

		local clickDetectors 	= window.clickDetectors;
		local keyDetectors	= window.keyDetectors;
		local keyEnd 		= window.keyEnd;


		userInputService.InputBegan:Connect(function(input, gameProcessed)
			for i = 1, #keyDetectors do
				keyDetectors[i](input, gameProcessed);
			end;
			
			--[[if (gameProcessed) then
				return;
                  else]]if (input.KeyCode == Enum.KeyCode.RightShift) then
				return window:toggle();
			elseif (input.UserInputType ~= Enum.UserInputType.MouseButton1) then
				return;
			end;

			window.mouseHeld = true;

			local mousePosition = userInputService:GetMouseLocation();
			for i = 1, #clickDetectors do
				clickDetectors[i](mousePosition);
			end;
		end);

		userInputService.InputEnded:Connect(function(input, gameProcessed)

			for i = 1, #keyEnd do
				keyEnd[i](input, gameProcessed);
			end;

			if (input.UserInputType ~= Enum.UserInputType.MouseButton1) then
				return;
			end;
			window.mouseHeld = false;
		end);



		local onDrag = function(mousePosition)

			local positions = {};
			for i = 1, #window.allDrawings do
				positions[i] = window.allDrawings[i].Position;
			end;


			local connection;
			connection = runService.RenderStepped:Connect(function()
				if (not window.mouseHeld) then
					return connection:Disconnect();
				end;

				local offset = userInputService:GetMouseLocation() - mousePosition;

				for i = 1, #positions do
					window.allDrawings[i].Position = positions[i] + offset;
				end;
			end);

		end;

		window:onClick(window.drawings.onDrag, onDrag);

	end;
	return window, window.flags;
end;
tabClass.new = function(window, tabName: string)
	assert(type(window) == 'table', `invalid argument #1 to 'tabClass.new' (table expected, got {type(window)})`);
	window.tabSettings.index += 1;

	local tab = setmetatable({
		id                = window.tabSettings.index;
		active            = window.tabSettings.index == 1 and true or false;
		window            = window;
		name              = tabName or `tab{window.tabSettings.index}`;

		offsets           = {10, 10};

		drawings          = {};
		allDrawings       = {};
		toggleDrawings    = {};
	}, tabClass);


	-- drawings
	do
		local drawings = tab.drawings;

		drawings.outline = createDrawing('Square', {
			Visible           = window.active;
			Filled            = false;
			Transparency      = 1;
			Thickness         = 1;
			Color             = --[[tab.id == 2 and color_rgb(255, 0, 0) or ]]color_rgb(7, 7, 7);
			-- Position          = window.drawings.base.Position - vector2(1, 1);
			-- Size              = drawings.base.Size + vector2(2, 2);
			ZIndex            = 11;
		}, window.allDrawings);

		drawings.text = createDrawing('Text', {
			Visible           = window.active;
			Center            = true;
			Outline           = true;
			Transparency      = 1;
			Size              = 13;
			Font              = GLOBAL_FONT;
			Text              = tab.name;
			Color             = color_rgb(195, 195, 195);
			OutlineColor      = color_rgb(0, 0, 0);
			-- Position          = drawings.base.Position + vector2(2, 2);
			ZIndex            = 11;
		}, window.allDrawings);
	end;

	tab.onClicked = function()
		if (tab.active) then
			return;
		end;

		local allTabs = tab.window.tabSettings.tabs;
		for i = 1, #allTabs do
			local tab2 = allTabs[i];
			if (tab2 ~= tab) then
				tab2:toggle(false);
			end;
		end;

		tab:toggle(true);
	end;
	tab.window:onClick(tab.drawings.outline, tab.onClicked);


	table_insert(window.tabSettings.tabs, tab);

	tab:toggle(tab.active);
	window:reloadTabs();

	return tab;
end;
toggleClass.new = function(tab, options: table, offset: number)
	assert(type(tab) == 'table', `invalid argument #1 to 'toggleClass.new' (table expected, got {type(tab)})`);
	assert(type(options) == 'table', `invalid argument #2 to 'toggleClass.new' (table expected, got {type(options)})`);
	assert(type(offset) == 'number', `invalid argument #3 to 'toggleClass.new' (number expected, got {type(offset)})`);

	offset = math.round(math.clamp(offset, 1, 2)); -- yep!

	local toggle = setmetatable({
		tab         = tab;
		window      = tab.window;
		text        = options.text or 'Toggle';
		enabled	= options.default or false;
		drawings    = {};
	}, toggleClass);

	-- flags
	do
		toggle.flag = {
			type = 'toggle';
			value = toggle.enabled;
			self = toggle;
		}
		toggle.flag.Changed = function(...) end
		if (options.flag) then
			function toggle.flag:OnChanged(_function)
				toggle.flag.Changed = _function;
				_function(toggle.flag.value);
			end;
			toggle.window.flags[options.flag] = toggle.flag;
		end;
	end;

	-- drawings;
	do
		local drawings = toggle.drawings;

		drawings.outline = createDrawing('Square', {
			Visible           = tab.active;
			Filled            = false;
			Transparency      = 1;
			Thickness         = 1;
			Color             = color_rgb(7, 7, 7);
			Position          = toggle.window.drawings[`sectionOutline{offset}`].Position + vector2(15, tab.offsets[offset]);
			Size              = vector2(15, 15);
			ZIndex            = 11;
		}, toggle.window.allDrawings, tab.allDrawings);

		drawings.accent = createDrawing('Square', {
			Visible           = tab.active;
			Filled            = true;
			Transparency      = toggle.enabled and 1 or 0;
			Thickness         = 1;
			Color             = color_rgb(255, 0, 0);
			Position          = drawings.outline.Position + vector2(1, 1);
			Size              = vector2(13.5, 13);
			ZIndex            = 11;
		}, toggle.window.allDrawings, tab.allDrawings);

		drawings.text = createDrawing('Text', {
			Visible           = tab.active;
			Center            = false;
			Outline           = true;
			Transparency      = 1;
			Size              = 13;
			Font              = GLOBAL_FONT;
			Text              = toggle.text;
			Color             = color_rgb(195, 195, 195);
			OutlineColor      = color_rgb(0, 0, 0);
			Position          = drawings.outline.Position + vector2(20, 1);
			ZIndex            = 11;
		}, toggle.window.allDrawings, tab.allDrawings);

		drawings.clickDetector = createDrawing('Square', {
			Visible           = tab.active;
			Filled            = false;
			Transparency      = 1;
			Thickness         = 1;
			Color             = color_rgb(255, 42, 191);
			Position          = drawings.outline.Position;
			Size              = vector2(22 + drawings.text.TextBounds.X, 15);
			ZIndex            = -999;
		}, toggle.window.allDrawings, tab.allDrawings);
	end;

	toggle.onClicked = function()
		local enabled = not toggle.enabled;
		toggle.enabled = enabled;

		toggle.flag.value = enabled;
		toggle.flag.Changed(enabled);


		toggle.drawings.accent.Transparency = enabled and 1 or 0;
	end;

	toggle.setValue = function(value)
		toggle.enabled = value;
		toggle.flag.value = value;
		toggle.flag.Changed(value);
		toggle.drawings.accent.Transparency = value and 1 or 0;
	end;

	toggle.window:onClick(toggle.drawings.clickDetector, toggle.onClicked);
	tab.offsets[offset] += 20;

	return toggle;
end;
sliderClass.new = function(tab, options: table, offset: number)
	assert(type(tab) == 'table', `invalid argument #1 to 'sliderClass.new' (table expected, got {type(tab)})`);
	assert(type(options) == 'table', `invalid argument #2 to 'sliderClass.new' (table expected, got {type(options)})`);
	assert(type(offset) == 'number', `invalid argument #3 to 'sliderClass.new' (number expected, got {type(offset)})`);

	local slider = setmetatable({
		tab         = tab;
		window      = tab.window;

		text        = options.text;
		value 	= options.default or options.min;
		max         = options.max;
		min         = options.min;
		increment   = options.increment or 1;
		suffix      = options.suffix or '';

		drawings    = {};
	}, sliderClass);

	slider.range = slider.max - slider.min;

	local stringIncrement 	= tostring(slider.increment);
	local dotIndex 		= string_find(stringIncrement, '.', 1, true);
	if (dotIndex) then
		slider.maxIndex = #stringIncrement - dotIndex;
	end;

	-- flags
	do
		slider.flag = {
			type = 'slider';
			value = slider.value;
			self = slider;
		}
		slider.flag.Changed = function(...) end
		if (options.flag) then
			function slider.flag:OnChanged(_function)
				slider.flag.Changed = _function;
				_function(slider.flag.value);
			end;
			slider.window.flags[options.flag] = slider.flag;
		end;
	end;



	-- drawings
	do
		local drawings = slider.drawings;

		drawings.outline 	= createDrawing('Square', {
			Visible           = tab.active;
			Filled            = false;
			Transparency      = 1;
			Thickness         = 1;
			Color             = color_rgb(7, 7, 7);
			Position          = slider.window.drawings[`sectionOutline{offset}`].Position + vector2(15, tab.offsets[offset] + 15);
			Size              = vector2(slider.window.drawings.sectionOutline1.Size.X - 30, 15);
			ZIndex            = 11;
		}, slider.window.allDrawings, tab.allDrawings);

		drawings.accent 	= createDrawing('Square', {
			Visible           = tab.active;
			Filled            = true;
			Transparency      = 1;
			Thickness         = 1;
			Color             = color_rgb(255, 0, 0);
			Position          = drawings.outline.Position + vector2(1, 1);
			Size              = vector2( (drawings.outline.Size.X - 2) * (slider.value - slider.min) / slider.range, drawings.outline.Size.Y - 2);
			ZIndex            = 11;
		}, slider.window.allDrawings, tab.allDrawings);

		drawings.text 	= createDrawing('Text', {
			Visible           = tab.active;
			Center            = false;
			Outline           = true;
			Transparency      = 1;
			Size              = 13;
			Font              = GLOBAL_FONT;
			Text              = slider.text;
			Color             = color_rgb(195, 195, 195);
			OutlineColor      = color_rgb(0, 0, 0);
			Position          = drawings.outline.Position + vector2(1, -15);
			ZIndex            = 11;
		}, slider.window.allDrawings, tab.allDrawings);

		drawings.value 	= createDrawing('Text', {
			Visible           = tab.active;
			Center            = true;
			Outline           = true;
			Transparency      = 1;
			Size              = 13;
			Font              = GLOBAL_FONT;
			Text              = slider.value .. slider.suffix;
			Color             = color_rgb(195, 195, 195);
			OutlineColor      = color_rgb(0, 0, 0);
			Position          = drawings.outline.Position + vector2(drawings.outline.Size.X / 2, 1);
			ZIndex            = 12;
		}, slider.window.allDrawings, tab.allDrawings);
	end;

	slider.onClicked = function()

		local startingX 	= slider.drawings.outline.Position.X;
		local maxX 		= slider.drawings.outline.Size.X;


		local connection;
		connection = runService.RenderStepped:Connect(function()
			if (not slider.window.mouseHeld) then
				return connection:Disconnect();
			end;

			local offset 	= userInputService:GetMouseLocation().X - startingX;
			local percentage 	= math_clamp(offset / maxX, 0, 1);

			slider.value = math_round( slider.range * percentage / slider.increment ) * slider.increment + slider.min;

			slider.flag.value = slider.value;
			slider.flag.Changed(slider.value);

			slider.drawings.accent.Size = vector2( (slider.drawings.outline.Size.X - 2) * (slider.value - slider.min) / slider.range , slider.drawings.accent.Size.Y);
                  
			local stringValue = slider.value;
			if (slider.maxIndex) then
				stringValue = tostring(stringValue);

				local dotIndex = string_find(tostring(stringValue), '.', 1, true);
				if (dotIndex) then
					stringValue = string_sub(tostring(stringValue), 1, slider.maxIndex + dotIndex);
				end;
			end;
			
			slider.drawings.value.Text = stringValue .. slider.suffix;
		end);
	end;

	slider.setValue = function(value)
		slider.value = value;

		slider.flag.value = slider.value;
		slider.flag.Changed(slider.value);

		slider.drawings.accent.Size = vector2( (slider.drawings.outline.Size.X - 2) * (slider.value - slider.min) / slider.range , slider.drawings.accent.Size.Y);
		slider.drawings.value.Text = slider.value .. slider.suffix;
	end;

	slider.window:onClick(slider.drawings.outline, slider.onClicked);

	tab.offsets[offset] += 35;

	return slider;
end;
dropdownClass.new = function(tab, options: table, offset: number)
	assert(type(tab) == 'table', `invalid argument #1 to 'dropdownClass.new' (table expected, got {type(tab)})`);
	assert(type(options) == 'table', `invalid argument #2 to 'dropdownClass.new' (table expected, got {type(options)})`);
	assert(type(offset) == 'number', `invalid argument #3 to 'dropdownClass.new' (number expected, got {type(offset)})`);

	local dropdown = setmetatable({
		tab 		= tab;
		window 	= tab.window;

		text 		= options.text;
		options 	= options.options;
		value 	= options.default or options.options[1] or 'None';

		drawings 	= {};
	}, dropdownClass);

	-- flags
	do
		dropdown.flag = {
			type = 'dropdown';
			value = dropdown.value;
			self = dropdown;
		}
		dropdown.flag.Changed = function(...) end
		if (options.flag) then
			function dropdown.flag:OnChanged(_function)
				dropdown.flag.Changed = _function;
				_function(dropdown.flag.value);
			end;
			dropdown.window.flags[options.flag] = dropdown.flag;
		end;
	end;



	-- drawings
	do
		local drawings = dropdown.drawings;

		drawings.outline = createDrawing('Square', {
			Visible           = tab.active;
			Filled            = false;
			Transparency      = 1;
			Thickness         = 1;
			Color             = color_rgb(7, 7, 7);
			Position          = dropdown.window.drawings[`sectionOutline{offset}`].Position + vector2(15, tab.offsets[offset] + 15);
			Size              = vector2(dropdown.window.drawings.sectionOutline1.Size.X - 30, 15);
			ZIndex            = 11;
		}, dropdown.window.allDrawings, tab.allDrawings);

		drawings.text 	= createDrawing('Text', {
			Visible           = tab.active;
			Center            = false;
			Outline           = true;
			Transparency      = 1;
			Size              = 13;
			Font              = GLOBAL_FONT;
			Text              = dropdown.text;
			Color             = color_rgb(195, 195, 195);
			OutlineColor      = color_rgb(0, 0, 0);
			Position          = drawings.outline.Position + vector2(1, -15);
			ZIndex            = 11;
		}, dropdown.window.allDrawings, tab.allDrawings);

		drawings.value 	= createDrawing('Text', {
			Visible           = tab.active;
			Center            = true;
			Outline           = true;
			Transparency      = 1;
			Size              = 13;
			Font              = GLOBAL_FONT;
			Text              = dropdown.value;
			Color             = color_rgb(195, 195, 195);
			OutlineColor      = color_rgb(0, 0, 0);
			Position          = drawings.outline.Position + vector2(drawings.outline.Size.X / 2, 1);
			ZIndex            = 11;
		}, dropdown.window.allDrawings, tab.allDrawings);
		drawings.rightText = createDrawing('Text', {
			Visible           = tab.active;
			Center            = true;
			Outline           = true;
			Transparency      = 1;
			Size              = 13;
			Font              = GLOBAL_FONT;
			Text              = '>';
			Color             = color_rgb(195, 195, 195);
			OutlineColor      = color_rgb(0, 0, 0);
			Position          = vector2(drawings.outline.Position.X + drawings.outline.Size.X - 10, drawings.value.Position.Y);
			ZIndex            = 11;
		}, dropdown.window.allDrawings, tab.allDrawings);

		drawings.leftText = createDrawing('Text', {
			Visible           = tab.active;
			Center            = true;
			Outline           = true;
			Transparency      = 1;
			Size              = 13;
			Font              = GLOBAL_FONT;
			Text              = '<';
			Color             = color_rgb(195, 195, 195);
			OutlineColor      = color_rgb(0, 0, 0);
			Position          = vector2(drawings.outline.Position.X + 10, drawings.value.Position.Y);
			ZIndex            = 11;
		}, dropdown.window.allDrawings, tab.allDrawings);

		drawings.rightClick = createDrawing('Square', {
			Visible           = tab.active;
			Filled            = false;
			Transparency      = 1;
			Thickness         = 1;
			Color             = color_rgb(255, 42, 191);
			Position          = drawings.rightText.Position - vector2(drawings.rightText.TextBounds.X / 2 + 2, 0);
			Size              = vector2(13, 13);
			ZIndex            = -999;
		}, dropdown.window.allDrawings, tab.allDrawings);

		drawings.leftClick = createDrawing('Square', {
			Visible           = tab.active;
			Filled            = false;
			Transparency      = 1;
			Thickness         = 1;
			Color             = color_rgb(255, 42, 191);
			Position          = drawings.leftText.Position - vector2(drawings.leftText.TextBounds.X / 2 + 2, 0);
			Size              = vector2(13, 13);
			ZIndex            = -999;
		}, dropdown.window.allDrawings, tab.allDrawings);
	end;

	local rightOnClicked = function()
		local index = table_find(dropdown.options, dropdown.value) or 0;

		local value = dropdown.options[index + 1]; --or dropdown.options[1];
		if (value == nil) then
			value = dropdown.options[1] or 'None';
		end;

		dropdown.value = value;
		dropdown.drawings.value.Text = value;

		dropdown.flag.value = dropdown.value;
		dropdown.flag.Changed(dropdown.value);
	end;

	local leftOnClicked = function()
		local index = table_find(dropdown.options, dropdown.value) or 2;

		local value = dropdown.options[index - 1]; --or dropdown.options[1];
		if (value == nil) then
			value = dropdown.options[#dropdown.options] or 'None';
		end;

		dropdown.value = value;
		dropdown.drawings.value.Text = value;

		dropdown.flag.value = dropdown.value;
		dropdown.flag.Changed(dropdown.value);
	end;

	dropdown.setValue = function(value)
		dropdown.value = value;
		dropdown.drawings.value.Text = value;

		dropdown.flag.value = dropdown.value;
		dropdown.flag.Changed(dropdown.value);
	end;

	dropdown.window:onClick(dropdown.drawings.rightClick, rightOnClicked);
	dropdown.window:onClick(dropdown.drawings.leftClick, leftOnClicked);


	tab.offsets[offset] += 35;

	return dropdown;
end;
buttonClass.new = function(tab, text: string, onClick, offset: number)
	assert(type(tab) == 'table', `invalid argument #1 to 'buttonClass.new' (table expected, got {type(tab)})`);
	assert(type(onClick) == 'function', `invalid argument #2 to 'buttonClass.new' (function expected, got {type(onClick)})`);
	assert(type(offset) == 'number', `invalid argument #3 to 'buttonClass.new' (number expected, got {type(offset)})`);

	local button = setmetatable({
		tab         = tab;
		window      = tab.window;
		text        = text;

		drawings    = {};
	}, buttonClass);

	-- drawings
	do
		local drawings = button.drawings;

		drawings.outline 	= createDrawing('Square', {
			Visible           = tab.active;
			Filled            = false;
			Transparency      = 1;
			Thickness         = 1;
			Color             = color_rgb(7, 7, 7);
			Position          = button.window.drawings[`sectionOutline{offset}`].Position + vector2(15, tab.offsets[offset]);
			Size              = vector2(button.window.drawings.sectionOutline1.Size.X - 30, 15);
			ZIndex            = 11;
		}, button.window.allDrawings, tab.allDrawings);

		drawings.text 	= createDrawing('Text', {
			Visible           = tab.active;
			Center            = true;
			Outline           = true;
			Transparency      = 1;
			Size              = 13;
			Font              = GLOBAL_FONT;
			Text              = button.text;
			Color             = color_rgb(195, 195, 195);
			OutlineColor      = color_rgb(0, 0, 0);
			Position          = drawings.outline.Position + vector2(drawings.outline.Size.X / 2, 1);
			ZIndex            = 12;
		}, button.window.allDrawings, tab.allDrawings);
	end;

	local onClicked = function()
		button.drawings.text.Color = color_rgb(255, 255, 255);
		task_delay(0.3, function()
			button.drawings.text.Color = color_rgb(195, 195, 195);
		end);

		onClick();
	end;
	
	button.window:onClick(button.drawings.outline, onClicked);

	tab.offsets[offset] += 20;

	return button;
end;


keypickerClass.new = function(toggle, options: table)
	assert(type(toggle) == 'table', `invalid argument #1 to 'keypickerClass.new' (table expected, got {type(toggle)})`);
	assert(type(options) == 'table', `invalid argument #2 to 'keypickerClass.new' (table expected, got {type(options)})`);

	local keypicker = setmetatable({
		tab         = toggle.tab;
		toggle 	= toggle;
		window      = toggle.window;
		active 	= false;
		value     	= KEY_CONVERSION[options.default] or options.default or 'None';
		blacklisted	= options.blacklisted or {};
		mode 		= options.mode or 'toggle';

		drawings    = {};
	}, keypickerClass);

		-- flags
		do
			keypicker.flag = {
				type 	= 'keypicker';
				key 	= keypicker.value;
				value = false;
				self 	= keypicker;
			}
			keypicker.flag.Changed = function(...) end
			if (options.flag) then
				function keypicker.flag:OnChanged(_function)
					keypicker.flag.Changed = _function;
					_function(keypicker.flag.value);
				end;
				keypicker.window.flags[options.flag] = keypicker.flag;
			end;
		end;

	-- drawings
	do
		local drawings = keypicker.drawings;

		drawings.text 	= createDrawing('Text', {
			Visible           = keypicker.tab.active;
			-- Center            = true;
			Outline           = true;
			Transparency      = 1;
			Size              = 13;
			Font              = GLOBAL_FONT;
			Text              = '[ loading ]';
			Color             = color_rgb(195, 195, 195);
			OutlineColor      = color_rgb(0, 0, 0);
			-- Position          = drawings.outline.Position + vector2(drawings.outline.Size.X / 2, 1);
			ZIndex            = 12;
		}, keypicker.window.allDrawings, keypicker.tab.allDrawings);

		drawings.clickDetector 	= createDrawing('Square', {
			Visible           = keypicker.tab.active;
			Filled            = false;
			Transparency      = 1;
			Thickness         = 1;
			Color             = color_rgb(255, 42, 191);
			Position          = nil; --button.window.drawings[`sectionOutline{offset}`].Position + vector2(15, tab.offsets[offset]);
			Size              = nil;--vector2(button.window.drawings.sectionOutline1.Size.X - 30, 15);
			ZIndex            = -999;
		}, keypicker.window.allDrawings, keypicker.tab.allDrawings);
	end;


	local onKeyPress = function(key)
		if (keypicker.active) then
			local keyValue 	= key.KeyCode.Name;

			if (keyValue == 'Unknown') then
				keyValue = key.UserInputType.Name;
				if (keyValue ~= 'MouseButton2') then
					return;
				end;
			end;

			for index, value in keypicker.blacklisted do
				if (value == keyValue) then
					return;
				end;
			end;


			keypicker.active 		= false;
			keypicker.value 		= KEY_CONVERSION[keyValue] or keyValue;
			keypicker.flag.key 	= keypicker.value;
			keypicker:update();

			return;
		elseif (keypicker.value == 'None') then
			return;
		end;

		local keyValue 	= key.KeyCode.Name;

		if (keyValue == 'Unknown') then
			keyValue = key.UserInputType.Name;
			if (keyValue ~= 'MouseButton2') then
				return;
			end;
		end;

		keyValue = KEY_CONVERSION[keyValue] or keyValue;

		if (keypicker.value == keyValue) then

			local value = keypicker.mode ~= 'toggle' and true or not keypicker.flag.value;

			keypicker.flag.value = value;
			keypicker.flag.Changed(value);
		end;
	end;

	local onKeyEnd = function(key)
		if (keypicker.active or keypicker.value == 'None' or keypicker.mode == 'toggle') then
			return;
		end;


		local keyValue 	= key.KeyCode.Name;
		if (keyValue == 'Unknown') then
			keyValue = key.UserInputType.Name;
			if (keyValue ~= 'MouseButton2') then
				return;
			end;
		end;

		keyValue = KEY_CONVERSION[keyValue] or keyValue;
		if (keypicker.value == keyValue) then
			keypicker.flag.value = false;
			keypicker.flag.Changed(false);
		end;

	end;

	local onClicked = function()
		keypicker.flag.value = false;

		if (keypicker.active) then

			keypicker.active = false;
			keypicker.value = 'None';
			keypicker:update();

			return;
		end;

		keypicker.active = true;
		keypicker.value = '...';
		keypicker:update();
	end;

	keypicker.window:onClick(keypicker.drawings.clickDetector, onClicked);
	keypicker.window:addKeyDetector(onKeyPress);
	keypicker.window:addKeyEnd(onKeyEnd);

	keypicker:update();
	keypicker.setValue = function(value, key)
		
		keypicker.value = key;
		keypicker.flag.value = value;
		keypicker.flag.Changed(value);

		keypicker:update();
	end;

	return keypicker;
end;


-- windowClass functions
do
	function windowClass:addTab(tabName: string)
		return tabClass.new(self, tabName);
	end;
	function windowClass:reloadTabs()
		local tabs = self.tabSettings.tabs;
		for i = 1, #tabs do
			tabs[i]:reload();
		end;
	end;
	function windowClass:isWithin(drawing, mousePosition)
		local size 		= drawing.Size;
		local offset 	= mousePosition - drawing.Position;

		return (
			offset.X > 0 and offset.Y > 0 and
			offset.X < size.X and offset.Y < size.Y
		);
	end;
	function windowClass:onClick(drawing, onClick, onMiss)
		onMiss = onMiss or function(...) end;
		local onClicked = function(mousePosition)
			if not (drawing.Visible and self:isWithin(drawing, mousePosition)) then
				return onMiss(mousePosition);
			end;

			for i = 1, #self.overlapDrawings do
				local overlapDrawing = self.overlapDrawings[i];
				if (overlapDrawing.Visible and self:isWithin(overlapDrawing, mousePosition)) then
					return onMiss(mousePosition);
				end;
			end;

			return onClick(mousePosition);
		end;

		table_insert(self.clickDetectors, onClicked);
	end;
	function windowClass:toggle()
		local enabled = not self.active;
		self.active = enabled;

		for i = 1, #self.connectedToggles do
			task_spawn(self.connectedToggles[i], enabled);
		end;

		local offset = enabled and vector2(99999, 99999) or vector2(-99999, -99999);
		for i = 1, #self.allDrawings do
			self.allDrawings[i].Position += offset;
		end;
	end;
	function windowClass:onToggle(_function)
		table_insert(self.connectedToggles, _function);
	end;
	function windowClass:addKeyDetector(_function)
		table_insert(self.keyDetectors, _function);
	end;
	function windowClass:addKeyEnd(_function)
		table_insert(self.keyEnd, _function);
	end;
end;

-- tabClass functions
do
	function tabClass:reload()
		local window = self.window;

		local total       = window.tabSettings.index;
		local width       = window.drawings.innerOutline.Size.X;

		local size        = math.ceil(width / total);
		local xOffset     = size * (self.id - 1);

		self.drawings.outline.Position      = window.drawings.innerOutline.Position + vector2(xOffset, 0);

            if (self.id == total) then -- scuffed shit
                  self.drawings.outline.Size = vector2((width - size * (total-1)), 41);
            else
                  self.drawings.outline.Size = vector2(size + 1, 41);
            end;


		-- self.drawings.outline.Size          = vector2(size + (self.id == total and -2 or 1), 41);
		self.drawings.text.Position         = self.drawings.outline.Position + vector2(self.drawings.outline.Size.X / 2, 14);
	end;

	function tabClass:toggle(enabled: boolean?)
		if (enabled == nil) then
			enabled = not self.active;
		end;

		self.active = enabled;

		local allDrawings = self.allDrawings;
		if (enabled) then
			
			self.drawings.text.Color = color_rgb(255, 255, 255);
			for i = 1, #allDrawings do
				allDrawings[i].Visible = true;
			end;
		else

			local toggleDrawings = self.toggleDrawings;
			self.drawings.text.Color = color_rgb(195, 195, 195);
			for i = 1, #allDrawings do
				allDrawings[i].Visible = false;
			end;
			for i = 1, #toggleDrawings do
				toggleDrawings[i].Visible = false;
			end;
		end;

	end;

	function tabClass:addToggle(options: table, offset: number)
		return toggleClass.new(self, options, offset);
	end;

	function tabClass:addSlider(options: table, offset: number)
		return sliderClass.new(self, options, offset);
	end;

	function tabClass:addDropdown(options: table, offset: number)
		return dropdownClass.new(self, options, offset);
	end;

	function tabClass:addButton(text: string, onClick, offset: number)
		return buttonClass.new(self, text, onClick, offset);
	end;
end;

-- keypickerClass functions
do
	function keypickerClass:update()
		local drawings = self.drawings;

		local text 			= drawings.text;
		local clickDetector 	= drawings.clickDetector;

		text.Text 			= `[{self.value}]`;

		local textBounds		= text.TextBounds;
		local position 		= self.toggle.drawings.outline.Position + vector2(self.window.drawings.sectionOutline1.Size.X - 30 - textBounds.X, 0);

		text.Position			= position
		clickDetector.Size 		= textBounds;
		clickDetector.Position		= position;
	end;
end;

-- toggleClass functions
do
	function toggleClass:addKeypicker(options)
		return keypickerClass.new(self, options);
	end;
end;


return windowClass, 1;
