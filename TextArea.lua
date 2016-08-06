--[[------------------------TextArea library---------------------------------
Author: Nikolay Yevstakhov aka N1cke
License: MIT

[TextArea]
TextArea is Gideros library to show and edit multiline and oneline texts.
TextArea supports hardware and virtual (built-in) keyboard input. Text can
be scrolled via mouse/touch and selected via mouse or virtual keyboard.
All standard text operations are supported: Select All, Duplicate, Cut, Copy,
Paste, Undo, Redo. If text can't fit into width and height vertical and
horizontal sliders will appear to help with the navigation. Each text can
have it's own colors and alphas of text, sliders, selection and cursor.
Various alignment modes are available: left, right, center and justified
with ability to suppress word breaks ('wholewords' setting). When text
editing is finished TextArea will run callback if defined.

[Virtual keyboard]
Virtual keyboard is fully customizable from within itself: you can set
each color, change font and sound, modify height, set cursor delays etc.
More than 150 layouts is available for it in included keyboard layouts file
(kblayouts.lua). Keyboard settings are automatically saved in a file
('keyboard.json' by default). It also automatically resizes when screen
resolution changes and fits editable text. If you need to popup it without
touch, for example for cursor settings, you can press "Menu" key on hardware
keyboard. 

[API]
◘ TextArea.new(t)
	creates TextArea instance
	accepts a table (t) where all parameters are optional:
	'font': [Font] font for the text
	'text': [string] text to display
	'sample': [string] text to get top and height for lines
	'align': ["L"|"C"|"R"|"J" or 0..1 or -1] left/center/right/justified
	'valign': [number in 0..1 range] relative vertical positioning
	'width': [number] to clip text width
	'height': [number] to clip text height
	'letterspace': [number] a space between characters
	'linespace': [number] line height modifier
	'color': [number in 0x000000..0xFFFFFF range] text color
	'colors': [table] paragraph colors, can have a fraction for alpha
	'wholewords': [boolean] only whole words in lines if enabled
	'oneline': [boolean] fits all text into one line if enabled
	'maxchars': [number] maximum text length restriction
	'undolevels': [number in 0.. range] levels for undo/redo operations
	'curwidth': [number] cursor width in pixels
	'curcolor': [number in 0x000000..0xFFFFFF range] cursor color 
	'curalpha': [number in 0..1 range] cursor alpha
	'selcolor': [number in 0x000000..0xFFFFFF range] selection color 
	'selalpha': [number in 0..1 range] selection alpha
	'sldwidth': [number] slider width in pixels
	'sldcolor': [number in 0x000000..0xFFFFFF range] slider color
	'sldalpha': [number in 0..1 range] slider alpha
	'edit': [boolean] adds mouse/touch listener to focus and edit if enabled
	'scroll': [boolean] adds mouse/touch listener to scroll if enabled
	'callback': [function] (textfield, esc) to be called when editing is done
	NOTE: any missing parameter will be defaulted to TextArea.default one
◘ TextArea:update(t)
	updates TextArea with new values from table (t)
	accepts a table with same parameters as for TextArea.new
◘ TextArea.property
	gets property value
	'property' is any parameter accepted by TextArea.new
◘ TextArea:setFocus(showkeyboard)
	to manually set focus on TextArea
	'showkeyboard': [boolean] shows virtual keyboard if enabled
	NOTE: you can't set focus on text without it's width and height set
◘ TextArea:removeFocus(hidekeyboard)
	to manually set focus from TextArea
	'hidekeyboard': [boolean] hides virtual keyboard if enabled
	NOTE: you can't remove focus from text if you are not focused on it
◘ TextArea.setKeyboardFonts(fonts)
	sets fonts for virtual keyboard
	'fonts': [table] list of fonts
◘ TextArea.setKeyboardSounds(sounds)
	sets sounds for virtual keyboard
	'sounds': [table] list of sounds
◘ TextArea.setKeyboardLayouts(layouts, [langsPerRow], [lang], [lang2])
	sets layouts for virtual keyboard
	'layouts': [table] list of languages where language is list of layouts
	'langsPerRow': [number greater than 0] langs menu columns' number
	'lang': [string, optional] sets main language
	'lang2': [string, optional] sets extra language
	
[Keyboard Layouts]
Can be set via TextArea.setKeyboardLayouts(layouts).
All layouts are grouped into languages:
{lang1 = {...}, lang2 = {...}, ...}
Each language group can contain up to 8 main layouts at 1..8 indexes:
{l1, l2, l3, l4, l5, l6, l7, l8}
	1: lowercase letters (shift: off, alt: off)
	2: uppercase letters (shift: on, alt: off)
	3: main symbols (shift: off, alt: on)
	4: extra symbols (shift: on, alt: on)
	5: bottom bar
	6: colors menu
	7: options menu
	8: cursor menu
Each missing layout will be loaded from default layouts.
Each language group also supports extra layouts. Extra layout is an layout
you can go to when you hold a key with this extra layout name.
--]]-------------------------------------------------------------------------

TextArea = Core.class(Sprite)
local Keyboard = Bitmap.new(RenderTarget.new(0, 0))
local Cursor = Pixel.new()

TextArea.default = {
	font        = Font.getDefault(),
	text        = "",
	sample      = "qP|", 
	align       = false,
	width       = false,
	height      = false,
	letterspace = 0,
	linespace   = 0,
	color       = false,
	colors      = false,
	wholewords  = false,
	oneline     = false,
	maxchars    = false,
	undolevels  = 10,
	curwidth    = 2,
	curcolor    = 0x000000,
	curalpha    = 1,
	selcolor    = 0x888888,
	selalpha    = 0.25,
	sldwidth    = 2,
	sldcolor    = 0x888888,
	sldalpha    = 0.5,
	edit        = false,
	scroll      = false,
	callback    = false,
}

for k,v in pairs(TextArea.default) do TextArea[k] = v end

Keyboard.default = {
	settings = "|D|keyboard.json",
	layouts = false,
	fonts = {Font.getDefault()},
	sounds = {},
	langsPerRow = 15,
	aniFactor = 0.15,

	cursorShowTime = 30,
	cursorHideTime = 30,
	
	repeatDelay = 500,
	repeatSpan  = 50,
	
	lang = "en",
	lang2 = "en",
	
	fontIndex = 1,
	soundIndex = 1,

	fixTime = 500,
	aniTime = 250,

	vibro = true,

	groundColor = 0xBB8800,
	groundAlpha = 1.0,

	keysColor = 0x000000,
	keysAlpha = 0.5,
	
	frameColor = 0xFFBB00,
	frameAlpha = 1.0,

	fillColor = 0xFF0000,
	fillAlpha = 0.2,

	keysScale = 0.9,

	height = 0.5,
	margin = 0.0,
}

for k,v in pairs(Keyboard.default) do Keyboard[k] = v end

local function getScreenWidth()
	return application:getScaleMode() == "noScale" and
		application:getDeviceWidth() or application:getContentWidth()
end

local function getScreenHeight()
	return application:getScaleMode() == "noScale" and
		application:getDeviceHeight() or application:getContentHeight()
end

-- Keyboard

function Keyboard.importLayouts(filename)
	local layouts = {}
	local json = require "json"
	local file = io.open(filename, "rb")
	local data = file:read"*a"
	file:close()
	local r = "jQuery.keyboard.layouts%[['\"](.-)['\"]%]%s?=%s?({.-});"
	for name, layout in data:gmatch(r) do
		layoutjson = layout
			:gsub(" ' ", " \\u0057 ")
			:gsub(" '\"", " \\u0057\"")
			:gsub("\"' ", "\"\\u0057 ")
			:gsub(" \" ", " \\u0052 ")
			:gsub(" \\\"", " \\u0052")
			:gsub("'", "\"")
			:gsub("],%s+}", "]\n}")
			:gsub("\"\"", "\\u0052")
			:gsub("//.-\n", "\n")
			:gsub("name%s?:", "\"name\" :")
			:gsub("lang%s?:", "\"lang\" :")
			:gsub("shift%s?:", "\"shift\" :")
			:gsub("alt%s?:", "\"alt\" :")
			:gsub("/%*.-%*/", "")
		local dec = json.decode(layoutjson)
		local t = {}
		for k,v in ipairs{"normal", "shift", "alt", "alt-shift"} do
			if dec[v] then
				dec[v][#dec[v]] = nil
				local page = table.concat(dec[v], "\n")
				t[k] = page:gsub("\\u", "%%x"):gsub("{%w+}", "")
			end
		end
		layouts[name:gsub("%s", "-")] = t
	end
	return layouts
end

local colorsMenu = {
	{"Keys"  , "-R", "R+", "-G", "G+", "-B", "B+", "-A", "A+"},
	{"Ground", "-R", "R+", "-G", "G+", "-B", "B+", "-A", "A+"},
	{"Frame" , "-R", "R+", "-G", "G+", "-B", "B+", "-A", "A+"},
	{"Fill"  , "-R", "R+", "-G", "G+", "-B", "B+", "-A", "A+"},
}

local optionsMenu = {
	{"<Font"  , "Font>"  , "<Scale" , "Scale>" , "<Delay", "Delay>"},
	{"<Sound" , "Sound>" , "<Vibro" , "Vibro>" , "<Span" , "Span>" },
	{"<Height", "Height>", "<Margin", "Margin>", "<Show" , "Show>" },
	{"<Hold"  , "Hold>"  , "<Anim"  , "Anim>"  , "<Hide" , "Hide>" },
}

local toolbarMenu = {
	{"Shift", "Alt", "Space" , "BS"    , "Enter"  },
	{"Shift", "Alt", "Left"  , "Right" , "Go"     },
	{"Shift", "Alt", "Switch", "Cursor", "Esc"    },
	{"Shift", "Alt", "Langs" , "Colors", "Options"},
}

local cursorMenu = {
	{"Undo", "Redo", "Dup"   , "All", "Cut" , "Copy"  , "Paste" },
	{"Home", "Up"  , "PageUp", ""   , "Home", "Up"    , "PageUp"},
	{"Left", "Move", "Right" , ""   , "Left", "Select", "Right" },
	{"End" , "Down", "PageDn", ""   , "End" , "Down"  , "PageDn"},
}

local defaultLayout = {
[[
1 2 3 4 5 6 7 8 9 0
q w e r t y u i o p
 a s d f g h j k l 
 , z x c v b n m . 
]],[[
1 2 3 4 5 6 7 8 9 0
Q W E R T Y U I O P
 A S D F G H J K L 
 , Z X C V B N M . 
]],[[
! @ # $ % ^ & * ( )
` ~ - _ = + { } [ ]
    ; : " ' | \    
    , < > ? / .    
]],[[
¡ ¢ £ ¤ ¥ ¦ § ¨ © ª
« ¬ ­® ¯ ° ± ¹ ² ³ ´
µ ¶ · ¸ º » ¼ ½ ¾ ¿
      × Ø ÷ ø      
]],[[
Shift Alt Space BS Enter
Shift Alt Left Right Go
Shift Alt Switch Cursor Esc
Shift Alt Langs Colors Options
]],[[
Keys -R R+ -G G+ -B B+ -A A+
Ground -R R+ -G G+ -B B+ -A A+
Frame -R R+ -G G+ -B B+ -A A+
Fill -R R+ -G G+ -B B+ -A A+
]],[[
<Font Font> <Scale Scale> <Delay Delay>
<Sound Sound> <Vibro Vibro> <Span Span>
<Height Height> <Margin Margin> <Show Show>
<Hold Hold> <Anim Anim> <Hide Hide>
]],[[
Undo Redo Dup All Cut Copy Paste
Home Up PageUp   Home Up PageUp
Left Move Right   Left Select Right
End Down PageDn   End Down PageDn
]],
["A"] = "À Á Â Ã Ä Å Æ Ā Ă Ą \n \n \n ",
["C"] = "Ç Ć Ĉ Ċ Č \n \n \n ",
["D"] = "Ð Ď Đ \n \n \n ",
["E"] = "È É Ê Ë Ē Ĕ Ė Ę Ě \n \n \n ",
["G"] = "Ĝ Ğ Ġ Ģ \n \n \n ",
["H"] = "Ĥ Ħ \n \n \n ",
["I"] = "Ì Í Î Ï Ĩ Ī Ĭ Į İ Ĳ \n \n \n ",
["J"] = "Ĵ \n \n \n ",
["K"] = "Ķ \n \n \n ",
["L"] = "Ĺ Ļ Ľ Ŀ Ł \n \n \n ",
["N"] = "Ñ Ń Ņ Ň Ŋ\n \n \n ",
["O"] = "Ò Ó Ô Õ Ö Ō Ŏ Ő Œ \n \n \n ",
["R"] = "Ŕ Ŗ Ř \n \n \n ",
["S"] = "ß Ś Ŝ Ş Š \n \n \n ",
["T"] = "Þ Ţ Ť Ŧ \n \n \n ",
["U"] = "Ù Ú Û Ü Ũ Ū Ŭ Ů Ű Ų \n \n \n ",
["W"] = "Ŵ \n \n \n ",
["Y"] = "Ý Ŷ Ÿ \n \n \n ",
["Z"] = "Ź Ż Ž \n \n \n ",
["a"] = "à á â ã ä å æ ā ă ą \n \n \n ",
["c"] = "ç ć ĉ ċ č \n \n \n ",
["d"] = "ð ď đ \n \n \n ",
["e"] = "è é ê ë ē ĕ ė ę ě \n \n \n ",
["g"] = "ĝ ğ ġ ģ \n \n \n ",
["h"] = "ĥ ħ \n \n \n ",
["i"] = "ì í î ï ĩ ī ĭ į ı ĳ \n \n \n ",
["j"] = "ĵ \n \n \n ",
["k"] = "ķ ĸ \n \n \n ",
["l"] = "ĺ ļ ľ ŀ ł \n \n \n ",
["n"] = "ñ ń ņ ň ŉ ŋ \n \n \n ",
["o"] = "ò ó ô õ ö ō ŏ ő œ \n \n \n ",
["r"] = "ŕ ŗ ř \n \n \n ",
["s"] = "ſ ś ŝ ş š \n \n \n ",
["t"] = "þ ţ ť ŧ \n \n \n ",
["u"] = "ù ú û ü ũ ū ŭ ů ű ų\n \n \n ",
["w"] = "ŵ \n \n \n ",
["y"] = "ý ÿ ŷ \n \n \n ",
["z"] = "ź ż ž \n \n \n ",
}

if Keyboard.settings then
	local file = io.open(Keyboard.settings, "rb")
	if file then
		local data = file:read "*a"
		local cfg = require"json".decode(data)
		file:close()
		for k,v in pairs(Keyboard.default) do
			Keyboard[k] = cfg[k] ~= nil and cfg[k] or v
		end
	end
	
	Keyboard:addEventListener(Event.APPLICATION_EXIT, function()
		local default = {}
		for k,v in pairs(Keyboard.default) do default[k] = Keyboard[k] end
		default.layouts, default.fonts, default.sounds = nil
		default.settings, default.langsPerRow, default.aniFactor = nil
		local cfg = require"json".encode(default)
		local file = io.open(Keyboard.settings, "wb")
		file:write(cfg)
		file:close()
	end)
end

function Keyboard.getLangsMenu(layouts, langsPerRow)
	local t = {}
	for k,v in pairs(layouts) do t[#t+1] = k end
	table.sort(t, function(a, b) return a < b end)
	for i = #t, 1, -langsPerRow do table.insert(t, i, "\n") end
	return table.concat(t, " ")
end

if not Keyboard.layouts then
	Keyboard.layouts = {en = defaultLayout}
	Keyboard.default.lang = Keyboard.lang
	Keyboard.default.lang2 = Keyboard.lang2
end

local langsMenu = Keyboard.getLangsMenu(Keyboard.layouts,
	Keyboard.langsPerRow)

local defaultLang = Keyboard.layouts[Keyboard.default.lang]

for _,lang in pairs(Keyboard.layouts) do
	for i = 1, 8 do
		lang[i] = lang[i] or defaultLang[i] or defaultLayout[i]
	end
end

if not Keyboard.layouts[Keyboard.lang] then
	Keyboard.lang = next(Keyboard.layouts)
end

if not Keyboard.layouts[Keyboard.lang2] then
	Keyboard.lang2 = next(Keyboard.layouts)
end

local selector = Path2D.new()
Keyboard:addChild(selector)
selector:setVisible(false)
local selTimer = Timer.new(50, 1)
selTimer:addEventListener(Event.TIMER, function()
	selector:setVisible(false)
end)

local shiftSelector = Path2D.new()
Keyboard:addChild(shiftSelector)
shiftSelector:setVisible(false)
local shiftFixed = false
local shiftTimer = Timer.new(Keyboard.fixTime, 1)

local altSelector = Path2D.new()
Keyboard:addChild(altSelector)
altSelector:setVisible(false)
local altFixed = false
local altTimer = Timer.new(Keyboard.fixTime, 1)

local function setSelectorsColor(c, a)
	selector:setLineColor(Keyboard.frameColor, Keyboard.frameAlpha)
	selector:setFillColor(Keyboard.fillColor, Keyboard.fillAlpha)
	shiftSelector:setLineColor(Keyboard.frameColor, Keyboard.frameAlpha)
	shiftSelector:setFillColor(Keyboard.fillColor, Keyboard.fillAlpha)
	altSelector:setLineColor(Keyboard.frameColor, Keyboard.frameAlpha)
	altSelector:setFillColor(Keyboard.fillColor, Keyboard.fillAlpha)
end

setSelectorsColor()

local function setSelectorSize(s, w, h)
	w, h = w - 1, h - 1
	s:setSvgPath(string.format("M 1 1 L %s 1 L %s %s L 1 %s Z", w, w, h, h))
end

local function updateColors(color, alpha, key)
	local a = math.ceil(alpha * 255)
	local b = color % 256
	local g = (color - b) / 256 % 256
	local r = (color - 256 * g - b) / 65536 % 16777216
	
	local d = 32
	
	if     key == "-R" then r = math.max(r - d, 0)
	elseif key == "R+" then r = math.min(r + d, 255)
	elseif key == "-G" then g = math.max(g - d, 0)
	elseif key == "G+" then g = math.min(g + d, 255)
	elseif key == "-B" then b = math.max(b - d, 0)
	elseif key == "B+" then b = math.min(b + d, 255)			
	elseif key == "-A" then a = math.max(a - d, 0)
	elseif key == "A+" then a = math.min(a + d, 255) end
	return r * 65536 + g * 256 + b, a / 255
end

local function getLangBounds(font, lang)
	local l = Keyboard.layouts[lang]
	local normals, toolbar = nil, l[5]
	local langs, colors, options, cursor = langsMenu, l[6], l[7], l[8]
	
	l[5], l[6], l[7], l[8] = nil, nil, nil, nil
	local t = {}
	for i, layout in pairs(l) do t[#t+1] = layout end
	normals = table.concat(t)
	l[5], l[6], l[7], l[8] = toolbar, colors, options, cursor
	
	local groups = {
		normals = normals,
		toolbar = toolbar,
		langs = langs,
		colors = colors,
		options = options,
		cursor = cursor
	}
	
	local bounds = {}
	
	for name,words in pairs(groups) do
		local b = {}
		local ym, wm, hm = 0, 0, 0
		for word in words:gmatch"%S+" do
			local x, y, w, h = font:getBounds(word)
			b[word] = {x, y, w, h}
			ym, wm, hm = math.min(ym, y), math.max(wm, w), math.max(hm, h)
		end
		b[1], b[2], b[3] = ym, wm, hm
		bounds[name] = b
	end
	
	return bounds
end

local function getLines(layout)
	local t = {}
	local lines = {}
	for line in layout:gmatch"([^\r\n]+)" do lines[#lines+1] = line end
	for i,line in ipairs(lines) do
		local words = {}
		local spaces = line:sub(1,1) == " " and 1 or 0
		for word in line:gmatch"%S*" do
			if word == "" then
				spaces = spaces + 1
			else
				for i = 1, math.floor((spaces - 1) / 2) do
					words[#words+1] = ""
				end
				spaces = 0
				words[#words+1] = word
			end
		end
		spaces = spaces - 1
		for i = 1, math.floor((spaces) / 2) do
			words[#words+1] = ""
		end
		words.shifted = (#line:match" *" % 2) * (spaces % 2)
		
		t[#t+1] = words
	end
	
	return t
end

local font = Keyboard.fonts[math.min(#Keyboard.fonts, Keyboard.fontIndex)]
local sound = Keyboard.sounds[math.min(#Keyboard.sounds, Keyboard.soundIndex)]
local bounds = getLangBounds(font, Keyboard.lang)
local frames = math.max(1, math.ceil(Keyboard.aniTime/16))
local appW, appH = nil, nil
local texture = nil
local lines = nil
local key = nil
local isToolbar = nil
local isExtra = nil
local menu = nil
local lastX, lastY = nil, nil
local toolbarMode = nil
local extTimer = Timer.new(Keyboard.fixTime, 1)
local aniTimer = Timer.new(15, frames)
local realheight = 0
local hidden = true

function Keyboard.updatePosY(t)
	local k = Keyboard.aniFactor
	appH = getScreenHeight()
	local ax, ay = stage:getAnchorPosition()
	local h = realheight
	local y = k * (1 - t) * h + appH - h + ay
	Keyboard:setY(y)
	return y
end

function Keyboard.slide()
	local t = aniTimer:getCurrentCount() / frames
	
	if hidden then
		if t == 1 and Cursor.__parent then
			local parent = Cursor.__parent
			local escape = Cursor.escape
			if escape then
				Cursor.escape = false
				if escape ~= "Menu" then
					local pos = parent.cursorpos
					parent.selection = {pos, pos}
					Cursor.setSelection(pos, pos)
					Cursor.selection:removeFromParent()
					Cursor.vslider:removeFromParent()
					Cursor.hslider:removeFromParent()
					Cursor:removeFromParent()
				end
			end
			Keyboard:removeFromParent()
			if escape and escape ~= "Menu" and parent.callback
			and parent.text ~= Cursor.origtext then
				parent.callback(parent, escape == "Esc")
			end
			stage:setAnchorPosition(0, 0)
			Keyboard.updatePosY(1)
			return
		else
			t = 1 - t
		end
	end
	
	if Cursor.__parent then
		local parent = Cursor.__parent
		local h = realheight
		local y = (1 - t) * Keyboard.aniFactor * h + appH - h
		if t == 1 and not hidden then
			local oldheight = parent.height
			parent.height = math.min(Cursor.areaHeight, y)
			if parent.height ~= oldheight then
				parent:updateArea(parent.width, parent.height)
				parent:updateSliders()
			end
		end
		local _, y1 = parent:getBounds(stage)
		local px, py = parent:getAnchorPosition()
		if parent.scrollheight == 0 then py = 0 end
		local y2 = y1 + parent.height + py
		local ay = t * (y2 - y)
		stage:setAnchorPosition(0, ay)
	end
	
	Keyboard.updatePosY(t)
	Keyboard:setAlpha(t)
end

aniTimer:addEventListener(Event.TIMER, Keyboard.slide)

extTimer:addEventListener(Event.TIMER, function()
	isExtra = true
	if key then Keyboard.update() end
	key = nil
	selector:setVisible()
	Keyboard.onKeyPress{x = lastX, y = lastY}
end)

function Keyboard.update()
	local appW0, appH0 = appW, appH
	appW, appH = getScreenWidth(), getScreenHeight()
	realheight = appH * Keyboard.height
	local layoutHeight = (1 - Keyboard.margin - Keyboard.margin) * realheight
	
	if true or appW ~= appW0 or appH ~= appH0 then
		texture = RenderTarget.new(appW, realheight)
	end
	
	texture:clear(Keyboard.groundColor, Keyboard.groundAlpha)
	
	local stamp = TextField.new(font, "")
	
	stamp:setTextColor(Keyboard.keysColor)
	stamp:setAlpha(Keyboard.keysAlpha)
	
	local shift = shiftSelector:isVisible()
	local alt = altSelector:isVisible()
	
	local layout, mode = nil, nil
	if menu then
		if menu == langsMenu then
			layout, mode = langsMenu, "langs"
		elseif menu == colorsMenu then
			layout, mode = Keyboard.layouts[Keyboard.lang][6], "colors"
		elseif menu == optionsMenu then
			layout, mode = Keyboard.layouts[Keyboard.lang][7], "options"
		elseif menu == cursorMenu then
			layout, mode = Keyboard.layouts[Keyboard.lang][8], "cursor"
		end
	elseif isExtra then
		layout, mode = Keyboard.layouts[Keyboard.lang][key], "normals"
	else
		local m = (shift and 1 or 0) + (alt and 2 or 0) + 1
		layout, mode = Keyboard.layouts[Keyboard.lang][m], "normals"
	end
	
	local lb = bounds[mode]
	local charY, charW, charH = lb[1], lb[2], lb[3]
	lines = getLines(layout)
	
	local maxL = 1
	for i = 1, #lines do maxL = math.max(maxL, #lines[i]) end
	local maxW = appW / maxL
	
	local n = #lines
	local lineH = layoutHeight / (n + 1)
	local scale = math.min(lineH / charH, maxW / charW) * Keyboard.keysScale
	
	Keyboard.layoutY0 = appH - realheight * (1 - Keyboard.margin)
	Keyboard.layoutY1 = appH - realheight * Keyboard.margin - 1
	Keyboard.lineH = lineH
	
	local offsetY = -0.5 * (lineH - scale * charH) + scale * charY -
		realheight * Keyboard.margin + lineH
	
	stamp:setScale(scale)
	
	Keyboard.lineLengths = {}
	Keyboard.lineOffsetXs = {}
	
	for i = 1, n do
		stamp:setY(lineH * i - offsetY)	
		local l = #lines[i]
		Keyboard.lineLengths[i] = l
		local shifted = lines[i].shifted
		local w = appW / (l + shifted)
		local x0 = 0.5 * shifted * w
		Keyboard.lineOffsetXs[i] = x0
		for j = 1, l do
			local char = lines[i][j]
			if char ~= "" then
				local cx, cw = lb[char][1], lb[char][3]
				stamp:setText(char)
				local offsetX = 0.5 * (w - cw * scale) - cx * scale
				stamp:setX(x0 + w * (j - 1) + offsetX)
				texture:draw(stamp)
			end
		end
	end
	
	toolbarMode = ((shift and not shiftFixed) and 1 or 0) +
		((alt and not altFixed) and 2 or 0) + 1
	local specialKeys = getLines(Keyboard.layouts[Keyboard.lang][5])
	local words = specialKeys[toolbarMode]
	local l = #words
	local w0 = appW / l
	local lb = bounds.toolbar
	local wordY, wordW, wordH = lb[1], lb[2], lb[3]
	
	local scale = Keyboard.keysScale * math.min(lineH/wordH, w0 / wordW)
	stamp:setScale(scale)
	
	stamp:setY(lineH * n + 0.5 * (lineH - scale * wordH) -
		scale * wordY + realheight * Keyboard.margin)
	
	for i = 1, l do
		stamp:setText(words[i])
		local x0 = appW * (i - 1) / l
		local x, w = lb[words[i]][1], lb[words[i]][3]
		stamp:setX(x0 + 0.5 * (w0 - scale * (w - x)))
		texture:draw(stamp)
	end
	
	setSelectorSize(shiftSelector, w0, lineH)
	setSelectorSize(altSelector, w0, lineH)
	
	local y0 = n * lineH + realheight * Keyboard.margin
	shiftSelector:setPosition(0, y0)
	altSelector:setPosition(w0, y0)
	
	Keyboard:setTexture(texture)
	
	if not hidden and not aniTimer:isRunning() then Keyboard.slide() end
end

function Keyboard.updateOptions(key)
	local kb = Keyboard
	if key == "<Font" then
		kb.fontIndex = kb.fontIndex == 1 and #kb.fonts or kb.fontIndex - 1
		font = kb.fonts[kb.fontIndex] or kb.fonts[1]
		bounds = getLangBounds(font, Keyboard.lang)
		Keyboard.update()
	elseif key == "Font>" then
		kb.fontIndex = kb.fontIndex == #kb.fonts and 1 or kb.fontIndex + 1
		font = kb.fonts[kb.fontIndex] or kb.fonts[1]
		bounds = getLangBounds(font, Keyboard.lang)
		Keyboard.update()
	elseif key == "<Sound" then
		kb.soundIndex = kb.soundIndex == 1 and #kb.sounds or
			kb.soundIndex - 1
		sound = kb.sounds[kb.soundIndex]
	elseif key == "Sound>" then
		kb.soundIndex = kb.soundIndex == #kb.sounds and 1 or
			kb.soundIndex + 1
		sound = kb.sounds[kb.soundIndex]
	elseif key == "<Vibro" then
		Keyboard.vibro = false
	elseif key == "Vibro>" then
		Keyboard.vibro = true
	elseif key == "Scale>" then
		kb.keysScale = math.min(kb.keysScale + 0.05, 1.0)
		Keyboard.update()
	elseif key == "<Scale" then
		kb.keysScale = math.max(kb.keysScale - 0.05, 0.5)
		Keyboard.update()
	elseif key == "Height>" then
		kb.height = math.min(kb.height + 0.05, 0.75)
		appW, appH = 0, 0
		Keyboard.update()
	elseif key == "<Height" then
		kb.height = math.max(kb.height - 0.05, 0.25)
		appW, appH = 0, 0
		Keyboard.update()
	elseif key == "Margin>" then
		kb.margin = math.min(kb.margin + 0.025, 0.25)
		Keyboard.update()
	elseif key == "<Margin" then
		kb.margin = math.max(kb.margin - 0.025, 0.00)
		Keyboard.update()
	elseif key == "Hold>" then
		kb.fixTime = math.min(kb.fixTime + 100, 750)
		shiftTimer:setDelay(kb.fixTime)
		altTimer:setDelay(kb.fixTime)
		extTimer:setDelay(kb.fixTime)
	elseif key == "<Hold" then
		kb.fixTime = math.max(kb.fixTime - 100, 250)
		shiftTimer:setDelay(kb.fixTime)
		altTimer:setDelay(kb.fixTime)
		extTimer:setDelay(kb.fixTime)
	elseif key == "Anim>" then
		kb.aniTime = math.min(kb.aniTime + 100, 500)
		frames = math.max(1, math.ceil(Keyboard.aniTime/16))
		aniTimer:setRepeatCount(frames)
		aniTimer:reset()
		aniTimer:start()
	elseif key == "<Anim" then
		kb.aniTime = math.max(kb.aniTime - 100, 0)
		frames = math.max(1, math.ceil(Keyboard.aniTime/16))
		aniTimer:setRepeatCount(frames)
		aniTimer:reset()
		aniTimer:start()
	elseif key == "Delay>" then
		kb.repeatDelay = math.min(kb.repeatDelay + 128, 1024)
	elseif key == "<Delay" then
		kb.repeatDelay = math.max(kb.repeatDelay - 128, 0)
	elseif key == "Span>" then
		kb.repeatSpan = math.min(kb.repeatSpan + 32, 256)
	elseif key == "<Span" then
		kb.repeatSpan = math.max(kb.repeatSpan - 32, 32)
	elseif key == "Show>" then
		kb.cursorShowTime = math.min(kb.cursorShowTime + 8, 64)
	elseif key == "<Show" then
		kb.cursorShowTime = math.max(kb.cursorShowTime - 8, 8)
	elseif key == "Hide>" then
		kb.cursorHideTime = math.min(kb.cursorHideTime + 8, 64)
	elseif key == "<Hide" then
		kb.cursorHideTime = math.max(kb.cursorHideTime - 8, 8)
	end	
end

function Keyboard.onKeyPress(e)
	local x, y = e.x or e.touch.x, e.y or e.touch.y
	if isExtra then selector:setVisible(false) end
	key = nil
	if y < Keyboard.layoutY0 or y > Keyboard.layoutY1 then
		lastX, lastY = nil, nil
		return
	end
	if e.__userdata then e:stopPropagation() end
	lastX, lastY = x, y
	local row = 1 + math.floor((y - Keyboard.layoutY0) / Keyboard.lineH)
	local x0, w0 = 0, 0
	local l = #lines
	local col = nil
	isToolbar = row > l
	local toolbar = toolbarMenu[toolbarMode]
	if isToolbar then
		col = math.floor(x * #toolbar / appW)  + 1
		w0 = appW / #toolbar
		x0 = (col - 1) * w0
	else
		local w = appW - 2 * Keyboard.lineOffsetXs[row]
		col = 1 + math.floor((x - Keyboard.lineOffsetXs[row]) *
			Keyboard.lineLengths[row] / w)
		if lines[row][col] == nil or lines[row][col] == "" then return end
		x0 = Keyboard.lineOffsetXs[row] + (col - 1) * w / #lines[row]
		w0 = (appW - 2 * Keyboard.lineOffsetXs[row]) /
			Keyboard.lineLengths[row]		
	end
	
	key = lines[row] and lines[row][col] or toolbarMenu[toolbarMode][col]
	
	if isExtra then
		key = nil
		local y0 = appH - Keyboard.layoutY0 - (l - row + 2) * Keyboard.lineH
		selector:setVisible(true)
		selTimer:reset()
		setSelectorSize(selector, w0, Keyboard.lineH)
		selector:setPosition(x0, y0)
		return
	end
	
	if isToolbar then
		if key == "Langs"  then
			menu = langsMenu
		elseif key == "Colors" then
			menu = colorsMenu
		elseif key == "Options" then
			menu = optionsMenu
		elseif key == "Cursor" then
			menu = cursorMenu
		elseif key == "Shift" then
			if shiftTimer:isRunning() and shiftSelector:isVisible() then
				shiftTimer:stop()
				shiftFixed = true
			else
				shiftSelector:setVisible(not shiftSelector:isVisible())
				shiftTimer:start()
				shiftFixed = false
			end
			if menu then menu = nil; altSelector:setVisible(false) end			
		elseif key == "Alt" then
			if altTimer:isRunning() and altSelector:isVisible() then
				altTimer:stop()
				altFixed = true
			else
				altSelector:setVisible(not altSelector:isVisible())
				altTimer:start()
				altFixed = false
			end
			if menu then menu = nil; shiftSelector:setVisible(false) end			
		elseif key == "Switch" then
			Keyboard.lang, Keyboard.lang2 = Keyboard.lang2, Keyboard.lang
			bounds = getLangBounds(font, Keyboard.lang)
		elseif key == "Space" then
			Cursor.onKeyDown{key = " "}
		else
			Cursor.onKeyDown{specialKey = key}
		end
		if ({Langs=0,Colors=0,Options=0,Cursor=0,Shift=0,Alt=0})[key] then
			Keyboard.update()
		end
	elseif menu then
		if menu == langsMenu then
			if Keyboard.lang2 == key then Keyboard.lang2 = Keyboard.lang end
			Keyboard.lang = key
			bounds = getLangBounds(font, Keyboard.lang)
			shiftSelector:setVisible(false)
			altSelector:setVisible(false)
		elseif menu == colorsMenu then
			if col == 1 then return end
			local name = colorsMenu[row][1]:lower()
			Keyboard[name.."Color"], Keyboard[name.."Alpha"] = updateColors(
				Keyboard[name.."Color"], Keyboard[name.."Alpha"], key)
			if row < 3 then Keyboard.update() else setSelectorsColor() end
		elseif menu == optionsMenu then
			Keyboard.updateOptions(optionsMenu[row][col])
		elseif menu == cursorMenu then
			if key == "Move" or key == "Select" then return end
			Cursor.onKeyDown{specialKey = cursorMenu[row][col],
				shift = col > 3}
		end
	elseif Keyboard.layouts[Keyboard.lang][key] then
		extTimer:start()
	else
		extTimer:stop()
	end
	
	local y0 = appH - Keyboard.layoutY0 - (l - row + 2) * Keyboard.lineH
	selector:setVisible(true)
	selTimer:reset()
	setSelectorSize(selector, w0, Keyboard.lineH)
	selector:setPosition(x0, y0)
	if sound then sound:play() end
	if Keyboard.vibro then application:vibrate() end
end

function Keyboard.onKeyMove(e)
	if isExtra then Keyboard.onKeyPress(e) end
	if lastX or lastY then e:stopPropagation() end
end

function Keyboard.onKeyRelease(e)
	if lastX or lastY then e:stopPropagation() end
	local needupdate = false
	
	if isExtra then
		isExtra = false
		Keyboard.onKeyPress(e)
		selector:setVisible(false)
		needupdate = true
	end
	
	selTimer:start()
	extTimer:stop()
	
	if menu == langsMenu and not shiftSelector:isVisible() then
		key = nil
		menu = nil
		needupdate = true
	end
	
	if isToolbar and ({Alt = 0, Shift = 0, Left = 0, Right = 0,
	Langs = 0, Colors = 0, Options = 0})[key] or menu then
		Cursor.lastKeyEvent = nil
		return
	end
	
	if shiftSelector:isVisible() and not shiftFixed and key then
		shiftSelector:setVisible(false)
		needupdate = true
	end
	
	if altSelector:isVisible() and not altFixed and key then
		altSelector:setVisible(false)
		needupdate = true
	end
	
	if not isToolbar and key then Cursor.onKeyDown{key = key} end
	key = nil
	if needupdate then Keyboard.update() end
	Cursor.lastKeyEvent = nil
end

function Keyboard.onEnterFrame()
	if stage:getChildIndex(Keyboard) ~= stage:getNumChildren() then
		stage:addChild(Keyboard)
	end
end

function Keyboard.show()
	if not hidden or aniTimer:isRunning() then return end
	Keyboard:addEventListener(Event.MOUSE_DOWN, Keyboard.onKeyPress, self)
	Keyboard:addEventListener(Event.MOUSE_MOVE, Keyboard.onKeyMove, self)
	Keyboard:addEventListener(Event.MOUSE_UP, Keyboard.onKeyRelease, self)
	Keyboard:addEventListener(Event.TOUCHES_BEGIN, Keyboard.onKeyPress, self)
	Keyboard:addEventListener(Event.TOUCHES_MOVE, Keyboard.onKeyMove, self)
	Keyboard:addEventListener(Event.TOUCHES_END, Keyboard.onKeyRelease, self)
	Keyboard:addEventListener(Event.APPLICATION_RESIZE, Keyboard.update, self)
	Keyboard:addEventListener(Event.ENTER_FRAME, Keyboard.onEnterFrame, self)
	stage:setAnchorPosition(0, 0)
	Keyboard:setY(getScreenHeight())
	Keyboard.update()
	stage:addChild(Keyboard)
	hidden = false
	selector:setVisible(false)
	aniTimer:reset()
	aniTimer:start()
end

function Keyboard.hide()
	if hidden or aniTimer:isRunning() then return end
	Keyboard:removeEventListener(Event.MOUSE_DOWN, Keyboard.onKeyPress, self)
	Keyboard:addEventListener(Event.MOUSE_MOVE, Keyboard.onKeyMove, self)	
	Keyboard:removeEventListener(Event.MOUSE_UP, Keyboard.onKeyRelease, self)
	Keyboard:removeEventListener(Event.TOUCHES_BEGIN, Keyboard.onKeyPress, self)
	Keyboard:addEventListener(Event.TOUCHES_MOVE, Keyboard.onKeyMove, self)
	Keyboard:removeEventListener(Event.TOUCHES_END, Keyboard.onKeyRelease, self)
	Keyboard:removeEventListener(Event.APPLICATION_RESIZE, Keyboard.update, self)
	Keyboard:removeEventListener(Event.ENTER_FRAME, Keyboard.onEnterFrame, self)
	if Cursor.__parent then Cursor.__parent:updateSliders() end
	hidden = true
	selector:setVisible(false)
	shiftSelector:setVisible(false)
	altSelector:setVisible(false)
	aniTimer:reset()
	aniTimer:start()
end

-- TextArea

TextArea.isTextArea = true
TextArea.cursorpos  = 1
TextArea.undolevel  = 1
TextArea.valign     = 0

function TextArea:init(p)
	local oldtext, oldundolevel = self.text, self.undolevel
	
	for k,v in pairs(p or {}) do
		if v ~= nil then self[k] = v end
	end
	
	if self.undolevels > 0 then
		if not self.texthistory then
			oldtext = self.text
			self.texthistory = self.texthistory or {self.text}
			self.cursorhistory = self.cursorhistory or {false}
		end
	
		local level = self.undolevel
		if level == oldundolevel and self.text ~= oldtext then
			if level < #self.texthistory then
				for i = level+1, #self.texthistory do
					self.texthistory[i] = nil
					self.cursorhistory[i] = nil
				end
			end
			if level == self.undolevels then
				level = level - 1
				table.remove(self.texthistory, 1)
				table.remove(self.cursorhistory, 1)
			end
			self.cursorhistory[level] = self.cursorpos
			level = level + 1
			table.insert(self.texthistory, self.text)
			table.insert(self.cursorhistory, false)
		elseif level < oldundolevel then
			if oldundolevel == #self.texthistory then
				self.cursorhistory[oldundolevel] = self.cursorpos
			end
			if level >= 1 then
				self.text = self.texthistory[level]
				self.cursorpos = self.cursorhistory[level]
			else
				level = 1
			end
		elseif level > oldundolevel then
			if level <= #self.texthistory then
				self.text = self.texthistory[level]
				self.cursorpos = self.cursorhistory[level]
			else
				level = #self.texthistory
			end
		end
		self.undolevel = level
	end
	
	local font, text, sample = self.font, self.text, self.sample
	local align, width, height = self.align, self.width, self.height
	local letterspace, linespace = self.letterspace, self.linespace
	local wholewords, oneline = self.wholewords, self.oneline
	local color, colors, maxchars = self.color, self.colors, self.maxchars
	
	local x, y, w, h = font:getBounds(sample)
	h = h + linespace
	
	local chars, sections, lines = TextArea.getLines(
		font, oneline and text:gsub("\n", " ") or text,
		letterspace, not oneline and width, length, wholewords)
		
	local n = #lines
	
	if align == "J" or align == -1 then
		local sw = font:getAdvanceX("  ") - font:getAdvanceX(" ")
			+ letterspace
		for i = 1, n do
			local p1, p2 = sections[i][1], sections[i][2]
			local spNum = math.floor((width - chars[p2][4]) / sw)
			local lastChar = chars[p2][5]
			if spNum > 0 and lastChar ~= "\n" and i ~= n then
				local _, ocNum = lines[i]:gsub(" +", "")
				if lastChar == " " then ocNum = ocNum - 1 end
				if ocNum > 0 then
					local num = math.floor(spNum / ocNum)
					local rem = spNum % ocNum
					local j = 0
					local line = lines[i]:gsub(" +", function(s)
						j = j + 1
						local k = (j <= ocNum and num or 0) +
							(j <= rem and 1 or 0)
						if k > 0 then
							local pos1, pos2
							local m = 0
							for p = p1, p2 do
								if chars[p][5] == " "
								and chars[p+1][5] ~= " " then
									m = m + 1
									if m == j then pos2 = p; break end
								end
							end
							local l = #s
							pos1 = pos2 - l + 1
							local off = k * sw
							local sOff = off / l
							for p = pos1, pos2 do
								chars[p][4] = chars[p][4] + sOff *
									(p - pos1 + 1)
								chars[p][3] = chars[p][4] - sOff - sw
							end
							for p = pos2 + 1, p2 do
								chars[p][3] = chars[p][3] + off
								chars[p][4] = chars[p][4] + off
							end
							return s .. (" "):rep(k)
						end
					end, ocNum)
					lines[i] = line
				end
			end
		end
	end
	
	local t = {}
	
	for i = 1, n do
		local textfield = TextField.new(font, lines[i])
		t[i] = textfield
	end
	
	if align == "R" or align == "C" or tonumber(align) == align then
		local k = align == "C" and 0.5 or 1.0
		for i = 1, n do
			local x = k * (width - t[i]:getWidth())
			local p1, p2 = sections[i][1], sections[i][2]
			for p = p1, p2 do
				local char = chars[p]
				char[3], char[4] = char[3] + x, char[4] + x
			end
			t[i]:setX(x)
		end
	end
	
	for i = 1, n do self:addChild(t[i]) end
	
	if colors then
		local defaultcolor = color
		local linenum = 1
		for i = 1, n do
			local color = colors[linenum]
			color = color or defaultcolor
			if color then
				local alpha = color % 1
				if alpha > 0 then t[i]:setAlpha(alpha) end
				if color >= 1 then t[i]:setTextColor(color) end
			end
			if lines[i]:byte(-1) == 10 then linenum = linenum + 1 end
		end
	elseif color then
		for i = 1, n do t[i]:setTextColor(color) end
	end
	
	if letterspace ~= 0 then
		for i = 1, n do t[i]:setLetterSpacing(letterspace) end
	end
	
	self.realwidth = oneline and chars[#chars][4] + self.curwidth or
		self:getWidth()
	self.realheight = #lines * h
	
	self.chars, self.sections, self.lines = chars, sections, lines
	
	self.heightmul = self.realheight / Sprite.getHeight(self)
	self.lineheight = h
	self.selection = {0, 0}
	
	if self.cursorpos > #chars then self.cursorpos = #chars end
	
	if width and height then self:updateArea(width, height) end
	
	if self.edit or self.scroll then
		if not width or not height then
			error("TextArea: set width and height to edit or scroll text")
		end
		self:addEventListener(Event.MOUSE_DOWN, TextArea.onFocus, self)
		self:addEventListener(Event.TOUCHES_BEGIN, TextArea.onFocus, self)
	else
		self:removeEventListener(Event.MOUSE_DOWN, TextArea.onFocus, self)
		self:removeEventListener(Event.TOUCHES_BEGIN, TextArea.onFocus, self)
	end
	
	for i = 1, n do
		t[i]:setY((i - 1) * h - y)
	end
end

function TextArea:updateArea(width, height)
	local ax, ay = self:getAnchorPosition()
	self.scrollwidth  = math.max(self.realwidth - width - 1, 0)
	self.scrollheight = math.max(self.realheight - height - 1, 0)
	if self.scrollwidth == 0 then ax = 0 end
	if ax >= self.scrollwidth then
		ax = math.max(0, self.realwidth - width)
		self:setAnchorPosition(ax, ay)
	end
	if self.scrollheight == 0 then ay = 0 end
	if ay >= self.scrollheight then
		ay = math.max(0, self.realheight - height)
		self:setAnchorPosition(ax, ay)
	end
	self:setClip(ax-1, ay-1, width+1, height+1)
	if self.valign ~= 0 and self.scrollheight == 0 then
		ay = self.valign * (self.realheight - self.height)
		self:setAnchorPosition(ax, ay)
	end
end

function TextArea.getLines(font, text, letterspace, width, length, wholewords)
	width, length = width or math.huge, length or math.huge
	local chars, sections, lines = {}, {}, {}
	local row, col, line, n = 1, 0, "", 0
	chars[0], sections[0] = {row, col, 0, 0, ""}, {0, 0}
	
	for i,code in utf8.codes(text) do
		n = n + 1
		col = col + 1
		if code == 10 then
			lines[row] = line .. "\n"
			line = ""
			local x = col == 1 and 0 or chars[n-1][4]
			chars[n] = {row, col, x, x, "\n"}
			sections[row] = {sections[row-1][2]+1, n}
			row, col = row + 1, 0
		else
			local char = utf8.char(code)
			local linex = line .. char
			local _, _, w = font:getBounds(linex.." ")
			if letterspace ~= 0 then w = w + letterspace * utf8.len(linex) end
			if w > width or n > length then
				if wholewords and utf8.find(linex, " ") then
					local pos1, pos2 = sections[row-1][2]+1, n-1
					
					local pos = pos2
					for p = pos2, pos1+1, -1 do
						if chars[p][5] == " " then pos = p; break end
					end
					local t = {}
					for p = pos1, pos do t[p-pos1+1] = chars[p][5] end
					lines[row] = table.concat(t)
					sections[row] = {pos1, pos}
					row, col = row + 1, 0
					local _, _, w = font:getBounds(char.." ")
					chars[n] = {row, col, 0, w, char}
					local offset = chars[pos+1][3]
					local t = {}
					for p = pos+1, pos2 do
						col = col + 1
						t[p-pos] = chars[p][5]
						chars[p] = {row, col, chars[p][3]-offset,
							chars[p][4]-offset, chars[p][5]}
					end
					t[#t+1] = char
					line = table.concat(t)
					local _, _, w = font:getBounds(line.." ")
					if letterspace ~= 0 then
						w = w + letterspace * utf8.len(line)
					end
					if chars[n-1][1] == row then
						chars[n] = {row, col, chars[n-1][4], w, char}
					else
						chars[n] = {row, col, 0, w, char}
					end
				else
					lines[row] = line
					local _, _, w = font:getBounds(char.." ")
					sections[row] = {sections[row-1][2]+1, n-1}
					row, col = row + 1, 1
					line = char
					chars[n] = {row, col, 0, w, char}
				end
			else
				line = linex
				local x = col == 1 and 0 or chars[n-1][4]
				chars[n] = {row, col, x, w, char}
			end
		end
	end	
	
	local i = #lines+1
	lines[i] = line
	local c = chars[n]
	if c[5] == "\n" then c = {c[1]+1, 1, 0, 0, "\n"} end
	chars[n+1] = {c[1], c[2]+1, c[4], c[4], ""}
	sections[i] = {sections[i-1][2]+1, n+1}
	chars[0], sections[0] = nil, nil
	return chars, sections, lines, colors
end

function TextArea:update(p)
	local cursorParent = Cursor.__parent
	local cursorpos = self.cursorpos
	local sel = self.selection
	local width, height = self.width, self.height
	for i, child in pairs(self.__children) do child:removeFromParent() end
	TextArea.init(self, p)
	self.selection = sel
	if cursorParent == self then
		self:addChild(Cursor.selection)
		self:addChild(Cursor.vslider)
		self:addChild(Cursor.hslider)
		self:addChild(Cursor)
		local char = self.chars[self.cursorpos]
		Cursor:setPosition(char[3], (char[1] - 1) * self.lineheight)
		if sel[1] ~= sel[2] then Cursor.setSelection(sel[1], sel[2]) end
		if width ~= self.width or height ~= self.height then
			self:updateSliders()
		end
	end
end

function TextArea.setKeyboardFonts(fonts)
	Keyboard.fonts = fonts
	Keyboard.fontIndex = 1
	font = Keyboard.fonts[Keyboard.fontIndex]
	bounds = getLangBounds(font, Keyboard.lang)
	Keyboard.update()
end

function TextArea.setKeyboardSounds(sounds)
	Keyboard.sounds = sounds
	Keyboard.soundIndex = 1
	sound = Keyboard.sounds[Keyboard.soundIndex]
end

function TextArea.setKeyboardLayouts(layouts, langsPerRow, lang, lang2)
	Keyboard.layouts = layouts and layouts or {en = defaultLayout}
	Keyboard.lang = lang or Keyboard.default.lang
	Keyboard.lang2 = lang2 or Keyboard.default.lang2
	Keyboard.langsPerRow = langsPerRow or Keyboard.default.langsPerRow
	langsMenu = Keyboard.getLangsMenu(Keyboard.layouts, Keyboard.langsPerRow)
	defaultLang = Keyboard.layouts[Keyboard.default.lang]
	for _,lang in pairs(Keyboard.layouts) do
		for i = 1, 8 do
			lang[i] = lang[i] or defaultLang[i] or defaultLayout[i]
		end
	end
	if not Keyboard.layouts[Keyboard.lang] then
		Keyboard.lang = next(Keyboard.layouts)
	end
	if not Keyboard.layouts[Keyboard.lang2] then
		Keyboard.lang2 = next(Keyboard.layouts)
	end
	bounds = getLangBounds(font, Keyboard.lang)
	Keyboard.update()
end

function TextArea:removeFocus(escape)
	if self ~= Cursor.__parent then return end
	if not hidden and self.edit then
		self.height = Cursor.areaHeight
		self:updateArea(self.width, self.height)
		Cursor.areaHeight = nil
	end
	Cursor.lastKeyEvent = nil
	for key in pairs(Cursor.modifiers) do
		Cursor.modifiers[key] = false
	end
	if hidden or escape == "Switch" then
		local pos = self.cursorpos
		self.selection = {pos, pos}
		Cursor.setSelection(pos, pos)
		Cursor.selection:removeFromParent()
		Cursor.vslider:removeFromParent()
		Cursor.hslider:removeFromParent()
		Cursor:removeFromParent()
		if self.callback and self.text ~= Cursor.origtext then
			self.callback(self, escape == "Esc" or escape == "Switch")
		end
		Cursor.escape = false
	elseif escape then
		Cursor.escape = escape
		Keyboard.hide()
	end
end

function TextArea:setFocus(showKeyboard)
	if not self.width or not self.height then
		error("TextArea: set width and height to focus", 2)
	end
	
	local parent = Cursor.__parent
	if parent and self ~= parent then parent:removeFocus("Switch") end
	
	Cursor.origtext = self.text
	
	self:addChild(Cursor)
	self:addChild(Cursor.selection)
	self:addChild(Cursor.vslider)
	self:addChild(Cursor.hslider)
	self:updateSliders()
	
	Cursor:setDimensions(self.curwidth, self.lineheight - self.linespace)
	Cursor:setColor(self.curcolor, self.curalpha)
	Cursor.setPos(self.cursorpos, true)
	Cursor.selection:setFillColor(self.selcolor, self.selalpha)
	
	if not self.edit then Cursor:setWidth(0); return Keyboard.hide() end
	
	Cursor.areaHeight = self.height
	
	Cursor:addEventListener(Event.ENTER_FRAME, Cursor.onEnterFrame)
	
	if not hidden then
		aniTimer:reset()
		aniTimer:start()
	elseif showKeyboard then
		Keyboard.show()
	end
end

function TextArea:onFocus(e)
	if self == Cursor.__parent or aniTimer:isRunning() then return end
	local x0, y0 = e.x or e.touch.x, e.y or e.touch.y
	local x, y = self:globalToLocal(x0, y0)
	local ax, ay = self:getAnchorPosition()
	if x < ax or y < ay then return end
	if x > ax + self.width or y > ay + self.height then return end
	self:setFocus(e.touch)
	Cursor.onPointerDown(e)
end

function TextArea:getHeight()
	return self.heightmul * Sprite.getHeight(self)
end

function TextArea:updateSliders()
	if self ~= Cursor.__parent then return end
	
	local ax, ay = self:getAnchorPosition()
	
	local w = self.width * self.width / self.realwidth
	local ox = (self.width - w) * ax / self.scrollwidth
	if self.scrollwidth == 0 then ox = 0 end
	if self.scrollwidth > 1 then
		Cursor.hslider:setDimensions(w, self.sldwidth)
	else
		Cursor.hslider:setDimensions(0, 0)
	end
	Cursor.hslider:setColor(self.sldcolor, self.sldalpha)
	Cursor.hslider:setPosition(ax + ox, ay + self.height - self.sldwidth)	
	
	local h = self.height * self.height / self.realheight
	local oy = (self.height - h) * ay / self.scrollheight
	if self.scrollheight == 0 then oy = 0 end
	if self.scrollheight > 1 then
		Cursor.vslider:setDimensions(self.sldwidth, h)
	else
		Cursor.vslider:setDimensions(0, 0)
	end
	Cursor.vslider:setColor(self.sldcolor, self.sldalpha)
	Cursor.vslider:setPosition(ax + self.width - self.sldwidth, ay + oy)
end

function TextArea:onResize(w, h)
	self:update{width = w, height = h}
end

-- Cursor

Cursor.selection = Path2D.new()
Cursor.selection:setLineColor(0, 0)

Cursor.vslider = Pixel.new()
Cursor.hslider = Pixel.new()

Cursor.clipboard = ""

Cursor.blinkCounter = 0
Cursor.repeatCounter = 0

Cursor.focus = false

Cursor.lastKeyEvent = nil
Cursor.lastX = nil

Cursor.pointerX = 0
Cursor.pointerY = 0

Cursor.escape = false
Cursor.origtext = false

Cursor.specialKeys = {
	[00] = "Esc",
	
	[48] = "F1",
	[49] = "F2",
	[50] = "F3",
	[51] = "F4",
	[52] = "F5",
	[53] = "F6",
	[54] = "F7",
	[55] = "F8",
	[56] = "F9",
	[57] = "F10",
	[58] = "F11",
	[59] = "F12",
	
	[08] = "PauseBreak",
	
	[04] = "Enter",
	[05] = "NumEnter",
	
	[36] = "CapsLock",
	[37] = "NumLock",
	[38] = "ScrollLock",
	
	[18] = "Left",
	[19] = "Up",
	[20] = "Right",
	[21] = "Down",
	
	[06] = "Insert",
	[07] = "Delete",
	[16] = "Home",
	[17] = "End",
	[22] = "PageUp",
	[23] = "PageDn",
	
	[01] = "Tab",
	[03] = "BS",
	
	[85] = "Menu",
	
	[32] = "Shift",
	[33] = "Ctrl",
	[34] = "Win",
	[35] = "Alt",
}

if application:getDeviceInfo() == "Mac OS" then
	Cursor.specialKeys[34], Cursor.specialKeys[33] = "Ctrl", "Win"
end

Cursor.directions = {
	Left   = 0,
	Right  = 1,
	Up     = 2,
	Down   = 3,
	Home   = 4,
	End    = 5,
	PageUp = 6,
	PageDn = 7,
}

Cursor.modifiers = {
	Shift = false,
	Ctrl  = false,
	Win   = false,
	Alt   = false,
}

Cursor.hotkeys = {
	A = "All",
	C = "Copy",
	X = "Cut",
	V = "Paste",
	D = "Dup",
	Z = "Undo",
	Y = "Redo",
}

function Cursor.onEnterFrame(e)
	local parent = Cursor.__parent
	if not parent then return end
	if Cursor.lastKeyEvent then
		local c = Cursor.repeatCounter + 1
		local d = math.floor(Keyboard.repeatDelay * 0.06)
		local s = math.floor(Keyboard.repeatSpan * 0.06)
		if c >= d and (c - d) % s == 0 then
			Cursor.onKeyDown(Cursor.lastKeyEvent)
		end
		Cursor.repeatCounter = c
	else
		Cursor.repeatCounter = 0
	end
	Cursor.blinkCounter = Cursor.blinkCounter + 1
	local totalTime = Keyboard.cursorShowTime + Keyboard.cursorHideTime
	if Cursor.blinkCounter > totalTime then Cursor.blinkCounter = 0 end
	local time = Cursor.blinkCounter % totalTime
	Cursor:setVisible(time < Keyboard.cursorShowTime)
end

function Cursor.onKeyDown(e)
	local parent = Cursor.__parent
	if not parent or not parent.edit then return end
	
	Cursor.lastKeyEvent = e
	Cursor.blinkCounter = 0
	
	local k = e.realCode or 0
	local s = Cursor.modifiers.Ctrl and
		Cursor.hotkeys[string.char(e.keyCode or "")] or
		e.specialKey or Cursor.specialKeys[k - 16777216]
	if Cursor.modifiers.Ctrl and not s then return end
	if e.keyCode and 301 <= e.keyCode and e.keyCode <= 306 then s = "Esc" end
	if k > 16777216 and not s then return end
	
	if Cursor.modifiers[s] ~= nil then
		Cursor.modifiers[s] = true
		Cursor.lastKeyEvent = nil
		return
	end
	
	local shift = Cursor.modifiers.Shift
	
	local text = nil
	if s == "Paste" then
		local clipboard = application:get"clipboard" or Cursor.clipboard
		if clipboard == nil or clipboard == "" then return end
		text = clipboard
	elseif s == "Tab" then
		text = "  "
	elseif s == "Enter" or s == "NumEnter" then
		if shift or parent.oneline then s = "Go" else text = "\n" end
	elseif e.key then
		text = e.key
	elseif not s and k then
		text = shift and utf8.char(k) or utf8.lower(utf8.char(k))
	end
	if text then return Cursor.insertText(text) end
	
	if s and Cursor.directions[s] then
		shift = shift or e.shift
		local pos = parent.cursorpos
		local row = parent.chars[pos][1]
		local chars = parent.chars
		local sections = parent.sections
		local sel = parent.selection
		if shift and sel[1] == sel[2] then sel[1] = pos end
		local lastX = Cursor.lastX
		Cursor.lastX = nil
		
		if s == "Left" then
			Cursor.setPos(math.max(pos - 1, 1))
		elseif s == "Right" then
			Cursor.setPos(math.min(pos + 1, #chars))
		elseif s == "Up" then
			if not lastX then lastX = parent.chars[pos][3] end
			Cursor.lastX = lastX
			row = row - 1
			if row < 1 then
				pos = 1
			else
				pos = Cursor.findPosInRow(row, chars, sections, lastX)
			end
			Cursor.setPos(pos)
		elseif s == "Down" then
			if not lastX then lastX = chars[pos][3] end
			Cursor.lastX = lastX
			row = row + 1
			if row > #sections then
				pos = #chars
			else
				pos = Cursor.findPosInRow(row, chars, sections, lastX)
			end
			Cursor.setPos(pos)
		elseif s == "Home" then
			Cursor.setPos(sections[row][1])
		elseif s == "End" then
			Cursor.setPos(sections[row][2])
		elseif s == "PageUp" then
			if not lastX then lastX = chars[pos][3] end
			Cursor.lastX = lastX
			row = row - math.floor(parent.height / parent.lineheight)
			if row < 1 then
				pos = 1
			else
				pos = Cursor.findPosInRow(row, chars, sections, lastX)
			end
			Cursor.setPos(pos)		
		elseif s == "PageDn" then
			if not lastX then lastX = parent.chars[pos][3] end
			Cursor.lastX = lastX
			row = row + math.floor(parent.height / parent.lineheight)
			if row > #parent.sections then
				pos = #parent.chars
			else
				pos = Cursor.findPosInRow(row, chars, sections, lastX)
			end
			Cursor.setPos(pos)		
		end
		
		sel[2] = parent.cursorpos
		if not shift then sel[1] = sel[2] end
		Cursor.setSelection(sel[1], sel[2])
	end
	
	if s == "All" then
		parent.selection = {1, #parent.chars}
		Cursor.setSelection(parent.selection[1], parent.selection[2])
	elseif s == "Esc" or s == "Go" then
		parent:removeFocus(s)
	elseif s == "Menu" then
		if aniTimer:isRunning() then return end
		if hidden then parent:setFocus(true) else parent:removeFocus(s) end
	elseif s == "BS" then
		if Cursor.delSelection() then return end
		local pos = parent.cursorpos - 1
		if pos > 0 then
			parent:update{text = utf8.remove(parent.text, pos, pos)}
			Cursor.setPos(pos)
		end
	elseif s == "Delete" then
		if Cursor.delSelection() then return end
		local pos = parent.cursorpos
		parent:update{text = utf8.remove(parent.text, pos, pos)}
		Cursor.setPos(pos)
	elseif s == "Copy" or s == "Cut" then
		local sel = parent.selection
		if sel[1] ~= sel[2] then
			local pos1, pos2 = sel[1], sel[2]
			if pos1 > pos2 then pos1, pos2 = pos2, pos1 end
			local text = utf8.sub(parent.text, pos1, pos2 - 1)
			pcall(Application.set, application, "clipboard", text)
			Cursor.clipboard = text
		end
		if s == "Cut" then Cursor.delSelection() end
	elseif s == "Dup" then
		local sel = parent.selection
		if sel[1] ~= sel[2] then
			local pos1, pos2 = sel[1], sel[2]
			if pos1 > pos2 then pos1, pos2 = pos2, pos1 end
			local text = utf8.sub(parent.text, pos1, pos2 - 1)
			Cursor.insertText(text)
			Cursor.insertText(text)
		else
			local row = parent.chars[parent.cursorpos][1]
			local chars = parent.chars
			local pos1, pos2 = 1, #chars
			for i = row-1, 1, -1 do
				local pos = parent.sections[i][2]
				if chars[pos][5] == "\n" then pos1 = pos; break end
			end
			for i = row, #parent.sections do
				local pos = parent.sections[i][2]
				if chars[pos][5] == "\n" then pos2 = pos; break end
			end
			local text = utf8.sub(parent.text, pos1, pos2)
			if text:sub(-1,-1) == "\n" then text = text:sub(1, -2) end
			if text:sub(1, 1) ~= "\n" then text = "\n"..text end
			local pos = parent.cursorpos
			Cursor.setPos(pos2)
			Cursor.insertText(text)
			Cursor.setPos(pos)
		end
	elseif s == "Undo" then
		parent:update{undolevel = parent.undolevel - 1}
	elseif s == "Redo" then
		parent:update{undolevel = parent.undolevel + 1}
	end
end

function Cursor.onKeyUp(e)
	local k = e.realCode
	local s = Cursor.specialKeys[k - 16777216]
	if Cursor.modifiers[s] then Cursor.modifiers[s] = false end
	Cursor.lastKeyEvent = nil
end

function Cursor.onPointerHover(e)
	
end

function Cursor.onPointerDown(e)
	if aniTimer:isRunning() then return end
	local parent = Cursor.__parent
	local x0, y0 = e.x or e.touch.x, e.y or e.touch.y
	local x, y = parent:globalToLocal(x0, y0)
	local ax, ay = parent:getAnchorPosition()
	if x < ax or y < ay then return end
	if x > ax + parent.width or y > ay + parent.height then return end
	if not parent.edit or e.button and e.button ~= 1 or e.touch then
		Cursor.pointerX, Cursor.pointerY = x0, y0
		Cursor.focus = 0
		return
	end
	Cursor.setPos(Cursor.getPosFromXY(x, y) or parent.cursorpos)
	parent.selection = {parent.cursorpos, parent.cursorpos}
	Cursor.blinkCounter = 0
	Cursor.focus = true
	parent:updateSliders()
end

function Cursor.onPointerMove(e)
	if not Cursor.focus or aniTimer:isRunning() then return end
	local parent = Cursor.__parent
	local x0, y0 = e.x or e.touch.x, e.y or e.touch.y
	if Cursor.focus == 0 then
		local dx, dy = x0 - Cursor.pointerX, y0 - Cursor.pointerY
		Cursor.pointerX, Cursor.pointerY = x0, y0
		local ax, ay = parent:getAnchorPosition()
		local x, y = ax - dx, ay - dy
		if y < 0 then y = 0
		elseif y > parent.scrollheight then y = parent.scrollheight end
		if x < 0 then x = 0
		elseif x > parent.scrollwidth then x = parent.scrollwidth end
		if parent.scrollheight == 0 and parent.valign > 0 then
			y = parent.valign * (parent.realheight - parent.height)
		end
		parent:setAnchorPosition(x, y)
		parent:setClip(x-1, y-1, parent.width+1, parent.height+1)
		parent:updateSliders()
		return
	end
	local x, y = parent:globalToLocal(x0, y0)
	if e.touch then
		local x1, y1 = parent:getAnchorPosition()
		local x2, y2 = x1 + parent.width, y1 + parent.height
		if x < x1 then x = x1 elseif x > x2 then x = x2 end
		if y < y1 then y = y1 elseif y > y2 then y = y2 end
	end
	Cursor.setPos(Cursor.getPosFromXY(x, y) or parent.cursorpos)
	parent.selection[2] = parent.cursorpos
	if e.touch then
		parent.selection[1] = parent.cursorpos
	else
		Cursor.setSelection(parent.selection[1], parent.selection[2])
	end
	Cursor.blinkCounter = 0
	parent:updateSliders()
end

function Cursor.onPointerUp(e)
	if not Cursor.focus then return end
	if hidden and e.touch and Cursor.focus == true then Keyboard.show() end
	if Cursor.focus == true then Cursor.onPointerMove(e) end
	if Cursor.focus == 0 and e.touch then
		Cursor.focus = true
		Cursor.onPointerMove(e)
	end
	Cursor.lastX = nil
	Cursor.focus = false
end

function Cursor.findPosInRow(row, chars, sections, lastX)
	local pos = sections[row][2]
	for i = sections[row][1], sections[row][2] do
		if lastX < chars[i][4] then
			pos = i + (lastX < 0.5 * (chars[i][3] + chars[i][4]) and 0 or 1)
			break
		end	
	end
	return pos
end

function Cursor.setPos(pos, noscroll)
	local parent = Cursor.__parent
	if not parent.edit then return end
	parent.cursorpos = pos
	local x = parent.chars[pos][3]
	local y = (parent.chars[pos][1] - 1) * parent.lineheight
	Cursor:setPosition(x, y)
	if noscroll or parent.scrollwidth == 0 then
		if parent.valign == 0 and parent.scrollheight == 0 then
			return parent:updateSliders()
		end
	end
	local x0, y0 = parent:getAnchorPosition()
	local x1 = math.min(x0 + parent.width, parent:getWidth())
	if x < x0 or x > x1 then
		if x > x1 then x = x - parent.width + parent.curwidth end
	else
		x = x0
	end
	if parent.scrollwidth == 0 then x = 0 end
	local y1 = math.min(y0 + parent.height, parent:getHeight()) -
		parent.lineheight
	if y < y0 or y > y1 then
		if y > y1 then y = y - parent.height + parent.lineheight end
	else
		y = y0
	end
	if parent.scrollheight == 0 and parent.valign > 0 then
		y = parent.valign * (parent.realheight - parent.height)
	end
	parent:setAnchorPosition(x, y)
	parent:setClip(x-1, y-1, parent.width+1, parent.height+1)
	parent:updateSliders()
end

function Cursor.getPosFromXY(x, y)
	local parent = Cursor.__parent
	local row = math.ceil(y / parent.lineheight)
	local section = parent.sections[row]
	if not section then return end
	local chars = parent.chars
	local width = parent.width
	if x < 0 or x > math.max(chars[section[2]][4], width) then return end
	for i = section[1], section[2] do
		if x < chars[i][4] then
			return i + (x < 0.5 * (chars[i][3] + chars[i][4]) and 0 or 1)
		end
	end
	return section[2]
end

function Cursor.insertText(text)
	local parent = Cursor.__parent
	Cursor.delSelection()
	local newtext = utf8.insert(parent.text, parent.cursorpos, text)
	if parent.maxchars and utf8.len(newtext) > parent.maxchars then
		return
	end
	parent:update{text = newtext}
	Cursor.setPos(parent.cursorpos + utf8.len(text))
end

function Cursor.delSelection()
	local parent = Cursor.__parent
	local sel = parent.selection
	if sel[1] == sel[2] then return end
	if sel[1] > sel[2] then sel[1], sel[2] = sel[2], sel[1] end
	local newtext = utf8.remove(parent.text, sel[1], sel[2]-1)
	parent:update{text = newtext}
	parent.selection = {0, 0}
	Cursor.setSelection(0, 0)
	Cursor.setPos(math.min(sel[1], sel[2]))
	return true
end

function Cursor.setSelection(pos1, pos2)
	if pos1 == pos2 then return Cursor.selection:setSvgPath"" end
	if pos1 > pos2 then pos1, pos2 = pos2, pos1 end
	local parent = Cursor.__parent
	local chars = parent.chars
	local sections = parent.sections
	local h = parent.lineheight
	local rect = "M %s %s L %s %s L %s %s L %s %s Z"
	local t = {}
	
	if pos1 < 1 then pos1 = 1 end
	if pos2 > #chars then pos2 = #chars end
	local row1, row2 = chars[pos1][1], chars[pos2][1]
	
	if row1 == row2 then
		local x1, y1 = chars[pos1][3], (row1-1) * h
		local x2, y2 = chars[pos2][3], row1 * h
		if x2 - x1 < 2 then x2 = x1 + 2 end
		t[#t+1] = rect:format(x1, y1, x2, y1, x2, y2, x1, y2)
	else
		local x1, y1 = chars[pos1][3], (row1-1) * h
		local x2, y2 = chars[sections[row1][2]][4], (row1) * h
		if x2 - x1 < 2 then x2 = x1 + 2 end
		t[#t+1] = rect:format(x1, y1, x2, y1, x2, y2, x1, y2)
		
		for row = row1+1, row2-1 do
			local x1, y1 = chars[sections[row][1]][3], (row-1) * h
			local x2, y2 = chars[sections[row][2]][4], row * h
			if x2 - x1 < 2 then x2 = x1 + 2 end
			t[#t+1] = rect:format(x1, y1, x2, y1, x2, y2, x1, y2)			
		end
		
		local x1, y1 = chars[sections[row2][1]][3], (row2-1) * h
		local x2, y2 = chars[pos2][3], row2 * h
		if x2 - x1 < 2 then x2 = x1 + 2 end
		t[#t+1] = rect:format(x1, y1, x2, y1, x2, y2, x1, y2)
	end
	
	Cursor.selection:setSvgPath(table.concat(t, " "))
end

Cursor:addEventListener(Event.KEY_DOWN, Cursor.onKeyDown)
Cursor:addEventListener(Event.KEY_UP, Cursor.onKeyUp)
Cursor:addEventListener(Event.MOUSE_HOVER, Cursor.onPointerHover)
Cursor:addEventListener(Event.MOUSE_DOWN, Cursor.onPointerDown)
Cursor:addEventListener(Event.MOUSE_MOVE, Cursor.onPointerMove)
Cursor:addEventListener(Event.MOUSE_UP, Cursor.onPointerUp)
Cursor:addEventListener(Event.TOUCHES_BEGIN, Cursor.onPointerDown)
Cursor:addEventListener(Event.TOUCHES_MOVE, Cursor.onPointerMove)
Cursor:addEventListener(Event.TOUCHES_END, Cursor.onPointerUp)
