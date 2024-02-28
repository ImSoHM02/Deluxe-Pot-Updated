local KnownModIndex = GLOBAL.KnownModIndex
local require = GLOBAL.require

PrefabFiles = { "deluxpot" }

Assets = { 
	Asset("ATLAS", "images/inventoryimages/deluxpot.xml"), 
	Asset("IMAGE", "minimap/deluxpot.tex" ),
	Asset("ATLAS", "minimap/deluxpot.xml" ),
}

AddMinimapAtlas("minimap/deluxpot.xml")

STRINGS = GLOBAL.STRINGS
Recipe = GLOBAL.Recipe
Ingredient = GLOBAL.Ingredient
TECH = GLOBAL.TECH
TUNING = GLOBAL.TUNING

TUNING.deluxpotconf = {
    Recipe         = GetModConfigData("RECIPE"),
    FreshBonus     = GetModConfigData("FRESHBONUS"),
    CookTimeMult   = GetModConfigData("COOKTIMEMULT"),
    AmountBonus    = GetModConfigData("AMOUNTBONUS")
}

local params = GLOBAL.require "mycontainers"
local containers = GLOBAL.require "containers"
containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, params.deluxpot.widget.slotpos ~= nil and #params.deluxpot.widget.slotpos or 0)
local old_widgetsetup = containers.widgetsetup
function containers.widgetsetup(container, prefab, data, ...)
        local pref = prefab or container.inst.prefab
        if pref == "deluxpot" then
                local t = params[pref]
                if t ~= nil then
                        for k, v in pairs(t) do
                                container[k] = v
                        end
                        container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
                end
        else
                return old_widgetsetup(container, prefab, data, ...)
        end
end

local RecipeIngredients = {
    Ingredient("cutstone", 3), 
    Ingredient("marble", 5)
}

if GetModConfigData("RECIPE") == "NORMAL" then
    RecipeIngredients = {
        Ingredient("cutstone", 5), 
        Ingredient("goldnugget", 10), 
        Ingredient("marble", 10)}
elseif GetModConfigData("RECIPE") == "HARD" then
    RecipeIngredients = {
        Ingredient("cutstone", 5), 
        Ingredient("moonrocknugget", 5), 
        Ingredient("marble", 10)}
elseif GetModConfigData("RECIPE") == "HARDER" then
    RecipeIngredients = {
        Ingredient("steelwool", 5), 
        Ingredient("moonrocknugget", 15), 
        Ingredient("marble", 15)}
elseif GetModConfigData("RECIPE") == "ROCKHARD" then    
    RecipeIngredients = {
        Ingredient("steelwool", 10), 
        Ingredient("moonrocknugget", 20), 
        Ingredient("marble", 20)}
end

if GetModConfigData("WARLY_FOODS") then
    for k,recipe in pairs (require("preparedfoods_warly")) do
        AddCookerRecipe("deluxpot", recipe)
    end
    if not hofwarly then
        ---
    end
    if hofwarly then
        for k, v in pairs(require("hof_foodrecipes_warly")) do
                AddCookerRecipe("portablecookpot", v)
                AddCookerRecipe("deluxpot", v)
    
            if v.card_def then
                AddCookerRecipe("deluxpot", v)
                AddCookerRecipe("portablecookpot", v)
            end
        end
    end
end

AddRecipe2(
    "deluxpot",
    RecipeIngredients,
    TECH.SCIENCE_TWO, "deluxpot_placer", {"COOKING"})
RegisterInventoryItemAtlas("images/inventoryimages/deluxpot.xml", "deluxpot.tex")

STRINGS.NAMES.DELUXPOT = "Deluxe Cooking Pot"
STRINGS.RECIPE_DESC.DELUXPOT = "Cook more and better!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.DELUXPOT = "Warly mentioned he left a book... where is it?"
STRINGS.CHARACTERS.WARLY.DESCRIBE.DELUXPOT = "I'm glad I made this thing portable..."