TextArea.setKeyboardFonts{
	TTFont.new("NotoSans.ttf", 100)
}

TextArea.setKeyboardSounds{
	Sound.new("Keypress.wav")
}

TextArea.setKeyboardLayouts(require "kblayouts", 10)

local width = application:getDeviceWidth()
local height = application:getDeviceHeight()
local chars = {}
for code = 1, 2048 do chars[#chars+1] = utf8.char(code) end
local font = TTFont.new("NotoSans.ttf", 30, table.concat(chars))
local callback = function(self, escape)
	print("escape:", escape, ", text:", self.text)
end

local text = [[
The MIT License (MIT)

Copyright (c) <year> <copyright holders>

Permission   is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.]]

local textarea1 = TextArea.new{
	font        = font,
	text        = text,
	sample      = "qP|", 
	align       = "C",
	width       = 0.45 * width,
	height      = 0.45 * height,
	letterspace = 0,
	linespace   = 5,
	color       = 0x0099DD,
	wholewords  = false,
	oneline     = false,
	maxchars    = false,
	undolevels  = 10,
	curwidth    = 2,
	curcolor    = 0x000000,
	curalpha    = 1,
	selcolor    = 0x88CCCC,
	selalpha    = 0.25,
	sldwidth    = 4,
	sldcolor    = 0x882222,
	sldalpha    = 0.5,
	edit        = true,
	scroll      = true,
	callback    = callback,
}
textarea1:setPosition(0.05 * width, 0.00 * height)
stage:addChild(textarea1)

local textarea2 = TextArea.new{
	font        = font,
	text        = text,
	align       = "R",
	wholewords  = true,
	width       = 0.45 * width,
	height      = 0.45 * height,
	color       = 0xDD9988,
	curcolor    = 0xFF22DD,
	sldwidth    = 10,
	scroll      = true,
}
textarea2:setPosition(0.50 * width, 0.00 * height)
stage:addChild(textarea2)

local textarea3 = TextArea.new{
	font        = font,
	color       = 0xFFFFFF,
	width       = 1.00 * width,
	height      = 0.05 * height,
	curcolor    = 0x777777,
	selcolor    = 0x2288FF,
	oneline     = true,
	edit        = true,
	callback    = callback,
}
local background = Pixel.new(0x000000, 1.0, 1.00 * width, 0.05 * height)
background:setPosition(0.00 * width, 0.54 * height)
stage:addChild(background)
textarea3:setPosition(0.00 * width, 0.55 * height)
stage:addChild(textarea3)

local textarea4 = TextArea.new{
	font        = font,
	text        = text,
	align       = "J",
	wholewords  = true,
	color       = 0x22BB22,
	width       = 0.80 * width,
	height      = 0.30 * height,
	curcolor    = 0xFF7777,
	edit        = true,
	callback    = callback,
}
textarea4:setPosition(0.10 * width, 0.65 * height)
stage:addChild(textarea4)

