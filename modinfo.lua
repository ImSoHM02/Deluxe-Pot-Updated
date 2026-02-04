description =
[[
Version 1.1.11 - Food for Thought
- Fixed:
    Cooked food display issue where finished dishes would appear invisible or show incorrect food items.
    Harvest amount calculation now multiplies stack size by productmult instead of adding bonus, ensuring visual display matches harvested quantity.
]]

name                        = "Deluxe Cooking Pot - Updated"
author                      = "Im So HM02 (Original by Astro & JanKiwen)"
version                     = "1.1.11"
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
