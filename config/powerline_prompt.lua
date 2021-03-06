-- Configurations
--- powerline_config_prompt_type is whether the displayed prompt is the full path or only the folder name
 -- Use:
 -- "full" for full path like C:\Windows\System32
local promptTypeFull = "full"
 -- "folder" for folder name only like System32
local promptTypeFolder = "folder"
 -- default is promptTypeFull
 -- Set default value if no value is already set
if not powerline_config_prompt_type then
    powerline_config_prompt_type = promptTypeFull
end 
if not powerline_config_prompt_useHomeSymbol then 
	powerline_config_prompt_useHomeSymbol = true 
end

-- Constacts
homeSymbol = ""

---
-- Extracts only the folder name from the input Path
-- Ex: Input C:\Windows\System32 returns System32
---
local function get_folder_name(path)
	local reversePath = string.reverse(path)
	local slashIndex = string.find(reversePath, "\\")
	return string.sub(path, string.len(path) - slashIndex + 2)
end

-- * Segment object with these properties:
---- * isNeeded: sepcifies whether a segment should be added or not. For example: no Git segment is needed in a non-git folder
---- * text
---- * textColor: Use one of the color constants. Ex: colorWhite
---- * fillColor: Use one of the color constants. Ex: colorBlue
local segment = {
    isNeeded = true,
    text = "",
    textColor = colorWhite, 
    fillColor = colorBlue
}

---
-- Sets the properties of the Segment object, and prepares for a segment to be added
---
local function init()
	cwd = clink.get_cwd()
	if powerline_config_prompt_type == promptTypeFolder then
		cwd =  get_folder_name(cwd)
	else 
		if powerline_config_prompt_useHomeSymbol then 
			if string.find(cwd, clink.get_env("HOME")) then 
				cwd = string.gsub(cwd, clink.get_env("HOME"), homeSymbol)
			end
		end
	end
	segment.textColor = colorWhite
	segment.fillColor = colorBlue
	segment.text = cwd.." "
end 

---
-- Uses the segment properties to add a new segment to the prompt
---
local function addAddonSegment()
    init()
    addSegment(segment.text, segment.textColor, segment.fillColor)
end 

-- Register this addon with Clink
clink.prompt.register_filter(addAddonSegment, 55)