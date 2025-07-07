description = 
[[
-V1.1.7-
Fixed a bug that caused the game server to crash upon loading a world the second time after creating it.

-V1.1.6-
Fixed a bug where characters could not directly drag and drop food into the Deluxe Pot to add food before the GUI was open. Now functions the same as the Crock Pot.

-V1.1.5-
Added an option to scale the pot and it's collision. Scales from 150% down to 25% in size.

-V1.1.4-
Fixed an issue relating to Craft Pot (727774324) compatibility.

-V1.1.3-
Fixed an issue with the widget crashing servers.

-V1.1.1-
Fixed a bug regarding the recipe not showing up in worlds that had been generated before the mod was added. (Thanks The Toblin for noticing this!)
Rewrote the UI to use the default cookpot UI, since it was already doing that, but in a custom way (Useless, I know. It's just how the original mod functioned and I didn't think to change it)
This UI change will make it compatible with my new mod Recipe Repeater, that allows you to repeat receipes when opening a cooking pot with a custom key.

-V1.1-
Huge rewrite of the code. No longer uses its own custom stewer file (This was part of the original mod), which means that it is now FULLY compatible with Heap of Foods, including the custom cooking time! 
It also means it should be compatible with any mod that uses any function from stewer.lua.
With this change, the pot is now also compatible with Insight (workshopid=2189004162).

Re-added custom cooking time
Insight compatibility (along with possibly other mods)
Code rewrite
Removed the option for selecting how many ingredients to use
Fixed some translation issues in the settings
Regardless of the amount of output items selected in settings, only 1 will show from now on (but you will still gain the extra)

-V1.0.5-
Another small fix. I accidentally took out the code for recipes, whoops.

-V1.0.4-
Fixed small crash issue. Thanks ChaosMind42.

-V1.0.3-
Removed cooktime as an option since it was causing crashes. I'll look more into this in the future.

-V1.0.2-
POSSIBLE fix for the error between this mod and HoF. Was probably caused by the December update to HoF. Line of code seemed to be running even when HoF was detected, which it shouldn't do.
If still getting errors, please post your full crash log to pastebin and post it on the mod page.

-V1.0.1-
Added Warly's Heap of Foods recipes to the pot. Fixed an issue where Warly's recipes were being added to standard crockpot instead of just the Deluxe Pot.
Added an in-game lore reason to characters inspecting the Deluxe Pot as to why they can make Warly's dishes without him, and a small custom line to Warly.
Changed priority of mod so it loads AFTER Heap of Foods, in order to call upon its files.
Cleaned up code.
]]

name                        = "Deluxe Cooking Pot - Updated"
author                      = "Im So HM02 (Original by Astro & JanKiwen)"
version                     = "1.1.7"
forumthread                 = ""
icon                        = "modicon.tex"
icon_atlas                  = "modicon.xml"
api_version                 = 10
all_clients_require_mod     = true
dst_compatible              = true
client_only_mod             = false
priority 					= -500

--Configs

local Empty = {{description = "", data = 0}}

local OptionRecipe	=	{{description 	= "Easy",         	data = "EASY",    		hover = "Cutstone and marble"},
						{description 	= "Normal",        	data = "NORMAL",  		hover = "Cutstones, gold nuggets and, marble"},
						{description 	= "Hard",          	data = "HARD",    		hover = "Cutstones, marble and, moonrock nuggets"},
						{description 	= "Harder",        	data = "HARDER",  		hover = "Steel wool, marble and, moonrock nuggets"},
						{description 	= "Rockhard!",     	data = "ROCKHARD",		hover = "More Steel wool, marble and, moonrock nuggets"}}
	
local OptionFresh	= 	{{description 	= "OFF",     		data = 1  , 			hover = "Standard"},
						{description 	= "Less",     		data = 0.8, 			hover = "A little fresh bonus"},
						{description 	= "Normal",   		data = 0.3, 			hover = "Medium fresh bonus"},
						{description 	= "More",     		data = 0.1, 			hover = "Huge fresh bonus"},
						{description 	= "Super!",   		data = 0  , 			hover = "Cooked food is 100% fresh even when cooked from unfresh ingredients"}}

local OptionMult 	=	{{description 	= "x2",     		data = 2,    			hover = "Cooking time is 2 times longer"},
						{description 	= "x1.5",    		data = 1.5,  			hover = "Cooking time is 50% longer"},
						{description 	= "x1.1",    		data = 1.1,  			hover = "Cooking time is 10% longer"},
						{description 	= "x1",      		data = 1,    			hover = "Standard cooking time"},
						{description 	= "x0.9",    		data = 0.9,  			hover = "Cooking time is 10% less"},
						{description 	= "x0.66",   		data = 0.66, 			hover = "Cooking time is 33% less"},
						{description 	= "x0.5",    		data = 0.5,  			hover = "Cooking time is halfed"},
						{description 	= "x0.33",   		data = 0.33, 			hover = "Cooking time is 66% less"},
						{description 	= "x0.1",    		data = 0.1,  			hover = "Super fast cooking. Only 10% of standard time."}}

local OptionScale 	= 	{{description 	= "25%", 			data = 0.25, 			hover = "Half of half"},
						{description 	= "50%", 			data = 0.5, 			hover = "Half the normal size"},
						{description 	= "75%", 			data = 0.75, 			hover = "Smaller than normal"},
						{description 	= "100%", 			data = 1, 				hover = "Normal size"},
						{description 	= "125%", 			data = 1.25, 			hover = "Slightly larger"},
						{description 	= "150%", 			data = 1.5, 			hover = "Much larger"}}

local OptionAmount	=	{{description 	= "1 (Default)",  	data = 0, 				hover = "Default vanilla amount"},
						{description 	= "2",     			data = 1, 				hover = "Vanilla + 1"},
						{description 	= "3",   			data = 2, 				hover = "Vanilla + 2"},
						{description 	= "4",     			data = 3, 				hover = "Vanilla + 3"}}

local OptionWarly	=	{{description 	= "True", 			data = true , 			hover = "Pot will have access to Warly's Recipes."},
						{description 	= "False", 			data = false, 			hover = "Deluxe Pot will not have access to Warly's Recipes."}}

local function Title(title) --Allows use of an empty label as a header
return {name=title, options=Empty, default=0,}
end

local SEPARATOR = Title("")

--Config options

configuration_options =
{
	Title("Settings"),
	{
		name 	= "RECIPE",
		label 	= "Recipe Difficulty",
		default = "NORMAL",
		options = OptionRecipe
	},

	{
		name 	= "FRESHBONUS",
		label 	= "Freshness Bonus",
		default = 1,
		options = OptionFresh
	},

	{
		name 	= "COOKTIMEMULT",
		label 	= "Cooking Time",
		default = 1,
		options = OptionMult
	},

	{
		name 	= "AMOUNTBONUS",
		label 	= "Amount Bonus",
		default = 0,
		options = OptionAmount
	},

	{
        name 	= "WARLY_FOODS",
        label 	= "Allow Warly Recipes?",
        default = false, 
        hover 	= "Allows Deluxe Pot to Cook Warly Restricted Recipes (By any player)",
        options = OptionWarly
	},
	{
		name 	= "SCALE",
		label 	= "Deluxe Pot Scale",
		default = 1,
		options = OptionScale,
		hover 	= "Set the size of the Deluxe Pot in the world."
	}
}