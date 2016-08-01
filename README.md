# TextArea — Gideros library for multiline text editing

## TextArea
TextArea is Gideros library to show and edit multiline and oneline texts. TextArea supports hardware and virtual (built-in) keyboard input. Text can be scrolled via mouse/touch and selected via mouse or virtual keyboard. All standard text operations are supported: Select All, Duplicate, Cut, Copy, Paste, Undo, Redo. If text can't fit into width and height vertical and horizontal sliders will appear to help with the navigation. Each text can have it's own colors and alphas of text, sliders, selection and cursor. Various alignment modes are available: left, right, center and justified with ability to suppress word breaks ('wholewords' setting). When text editing is finished TextArea will run callback if defined.

## Virtual keyboard
Virtual keyboard is fully customizable from within itself: you can set each color, change font and sound, modify height, set cursor delays etc. More than 150 layouts is available for it in included keyboard layouts file (kblayouts.lua). Keyboard settings are automatically saved in a file ('keyboard.json' by default). It also automatically resizes when screen resolution changes and fits editable text. If you need to popup it without touch, for example for cursor settings, you can press "Menu" key on hardware keyboard. 

## API
```lua
◘ TextArea.new(t)
	creates TextArea instance
	accepts a table (t) where all parameters are optional:
	'font': [Font] font for the text
	'text': [string] text to display
	'sample': [string] text to get top and height for lines
	'align': ["L"|"C"|"R"|"J"] i.e. left, center, right or justified
	'width': [number] to clip text width
	'height': [number] to clip text height
	'letterspace': [number] a space between characters
	'linespace': [number] line height modifier
	'color': [number in 0x000000..0xFFFFFF range] text color
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
```
	
## Keyboard Layouts
Can be set via TextArea.setKeyboardLayouts(layouts).

All layouts are grouped into languages:
```lua
{lang1 = {...}, lang2 = {...}, ...}
```
Each language group can contain up to 8 main layouts at 1..8 indexes:
```lua
{l1, l2, l3, l4, l5, l6, l7, l8}
```
	1: lowercase letters (shift: off, alt: off)
	2: uppercase letters (shift: on, alt: off)
	3: main symbols (shift: off, alt: on)
	4: extra symbols (shift: on, alt: on)
	5: bottom bar
	6: colors menu
	7: options menu
	8: cursor menu
Each missing layout will be loaded from default layouts.
Each language group also supports extra layouts. Extra layout is an layout you can go to when you hold a key with this extra layout name.
