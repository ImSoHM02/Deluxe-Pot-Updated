require "prefabutil"

local cooking = require("cooking")
local FOODSTCOOK = cooking.recipes["cookpot"]


local assets =
{
    Asset("ANIM", "anim/deluxpot.zip"),
    Asset("ANIM", "anim/cook_pot_food.zip"),
    Asset("ANIM", "anim/ui_cookpot_1x4.zip"),
}

local prefabs =
{
    "collapse_small",
}

local function dospoildeluxe(inst, self)
    self.task = nil
    self.targettime = nil
    self.spoiltime = nil

    if self.onspoil ~= nil then
        self.onspoil(inst)
    end
end

local function dostewdeluxe(inst, self)
    self.task = nil
    self.targettime = nil
    self.spoiltime = nil

    if self.ondonecooking ~= nil then
        self.ondonecooking(inst)
    end

    if self.product == self.spoiledproduct then
        if self.onspoil ~= nil then
            self.onspoil(inst)
        end
    elseif self.product ~= nil then
        local recipe = cooking.GetRecipe(inst.prefab, self.product)
        local prep_perishtime = (recipe ~= nil and (recipe.cookpot_perishtime or recipe.perishtime)) or 0
        if prep_perishtime > 0 then
            local prod_spoil = self.product_spoilage or 1
            self.spoiltime = prep_perishtime * prod_spoil
            self.targettime =  GetTime() + self.spoiltime
            self.task = self.inst:DoTaskInTime(self.spoiltime, dospoildeluxe, self)
        end
    end

    self.done = true
end

local function StartCookingDeluxe(self, doer)
    if self.targettime == nil and self.inst.components.container ~= nil then
        self.chef_id = (doer ~= nil and doer.player_classified ~= nil) and doer.userid
        self.ingredient_prefabs = {}

        self.done = nil
        self.spoiltime = nil

        if self.onstartcooking ~= nil then
            self.onstartcooking(self.inst)
        end

        for k, v in pairs (self.inst.components.container.slots) do
            table.insert(self.ingredient_prefabs, v.prefab)
        end

        local cooktime = 1
        self.product, cooktime = cooking.CalculateRecipe(self.inst.prefab, self.ingredient_prefabs)
        local productperishtime = cooking.GetRecipe(self.inst.prefab, self.product).perishtime or 0

        if productperishtime > 0 then
            local spoilage_total = 0
            local spoilage_n = 0
            for k, v in pairs (self.inst.components.container.slots) do
                if v.components.perishable ~= nil then
                    spoilage_n = spoilage_n + 1
                    spoilage_total = spoilage_total + v.components.perishable:GetPercent()
                end
            end
            self.product_spoilage =
                (spoilage_n <= 0 and 1) or
                (self.keepspoilage and spoilage_total / spoilage_n) or
                1 - (1 - spoilage_total / spoilage_n) * .5 * TUNING.deluxpotconf.FreshBonus
        else
            self.product_spoilage = nil
        end

        cooktime = TUNING.BASE_COOK_TIME * cooktime * self.cooktimemult
        self.targettime = GetTime() + cooktime
        if self.task ~= nil then
            self.task:Cancel()
        end
        self.task = self.inst:DoTaskInTime(cooktime, dostewdeluxe, self)

        self.inst.components.container:Close()
        self.inst.components.container:DestroyContents()
        self.inst.components.container.canbeopened = false
    end
end

local function HarvestAmount(self, harvester)
    if self.done then
        if self.onharvest ~= nil then
            self.onharvest(self.inst)
        end

        if self.product ~= nil then
            local loot = SpawnPrefab(self.product)
            if loot ~= nil then
                local recipe = cooking.GetRecipe(self.inst.prefab, self.product)

                if harvester ~= nil and
                    self.chef_id == harvester.userid and
                    recipe ~= nil and
                    recipe.cookbook_category ~= nil and
                    cooking.cookbook_recipes[recipe.cookbook_category] ~= nil and
                    cooking.cookbook_recipes[recipe.cookbook_category][self.product] ~= nil then
                    harvester:PushEvent("learncookbookrecipe", {product = self.product, ingredients = self.ingredient_prefabs})
                end

                local stacksize = recipe and recipe.stacksize or 1
                local amountbonus = TUNING.deluxpotconf.AmountBonus
                stacksize = stacksize + amountbonus -- Extra food amount is now configurable.

                if stacksize > 1 then
                    loot.components.stackable:SetStackSize(stacksize)
                end

                if self.spoiltime ~= nil and loot.components.perishable ~= nil then
                    local spoilpercent = self:GetTimeToSpoil() / self.spoiltime
                    loot.components.perishable:SetPercent(self.product_spoilage * spoilpercent)
                    loot.components.perishable:StartPerishing()
                end
                if harvester ~= nil and harvester.components.inventory ~= nil then
                    harvester.components.inventory:GiveItem(loot, nil, self.inst:GetPosition())
                else
                    LaunchAt(loot, self.inst, nil, 1, 1)
                end
            end
            self.product = nil
        end

        if self.task ~= nil then
            self.task:Cancel()
            self.task = nil
        end
        self.targettime = nil
        self.done = nil
        self.spoiltime = nil
        self.product_spoilage = nil

        if self.inst.components.container ~= nil then
            self.inst.components.container.canbeopened = true
        end

        return true
    end
end


function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

for k, v in pairs(cooking.recipes.cookpot) do
    table.insert(prefabs, v.name)
end

for k,recipe in pairs (FOODSTCOOK) do

    local rep = deepcopy(recipe)
    AddCookerRecipe("deluxpot", rep) 
end

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    if not inst:HasTag("burnt") and inst.components.stewer.product ~= nil and inst.components.stewer:IsDone() then
        inst.components.lootdropper:AddChanceLoot(inst.components.stewer.product, 1)
    end
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        if inst.components.stewer:IsCooking() then
            inst.AnimState:PlayAnimation("work_hit")
            inst.AnimState:PushAnimation("work", true)
        elseif inst.components.stewer:IsDone() then
            local mult = inst.components.stewer.productmult or 1
            inst.AnimState:PlayAnimation("done"..mult.."_hit")
            inst.AnimState:PushAnimation("done"..mult, false)
        else
            inst.AnimState:PlayAnimation("hit")
            inst.AnimState:PushAnimation("idle", false)
        end
    end
end

--anim and sound callbacks

local function startcookfn(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("work", true)
        inst.SoundEmitter:KillSound("snd")
        inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_rattle", "snd")
        inst.Light:Enable(true)
    end
end

local function onopen(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("open", true)
        inst.SoundEmitter:KillSound("snd")
        inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_open")
        inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot", "snd")
    end
end

local function onclose(inst)
    if not inst:HasTag("burnt") then
        if not inst.components.stewer:IsCooking() then
            inst.AnimState:PlayAnimation("idle")
            inst.SoundEmitter:KillSound("snd")
        end
        inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_close")
    end
end

local function spoilfn(inst)
    if not inst:HasTag("burnt") then
        inst.components.stewer.product = inst.components.stewer.spoiledproduct
        inst.AnimState:OverrideSymbol("food", "cook_pot_food", inst.components.stewer.product)
    end
end

local function ShowProduct(inst)
    if not inst:HasTag("burnt") then
        local product = inst.components.stewer.product
        if IsModCookingProduct(inst.prefab, product) or IsModCookingProduct("cookpot", product) then
            --print("moded!")
            inst.AnimState:OverrideSymbol("food", product, product)
        else
            --print("not moded!")
            inst.AnimState:OverrideSymbol("food", "cook_pot_food", product)
        end
    end
end

local function donecookfn(inst)
    if not inst:HasTag("burnt") then
        local mult = inst.components.stewer.productmult or 1
        inst.AnimState:PlayAnimation("work_pst"..mult)        
        inst.AnimState:PushAnimation("done"..mult, false)
        ShowProduct(inst)
        inst.SoundEmitter:KillSound("snd")
        inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_finish")
        inst.Light:Enable(false)
    end
end

local function continuedonefn(inst)
    if not inst:HasTag("burnt") then
        local mult = inst.components.stewer.productmult or 1
        inst.AnimState:PlayAnimation("done"..mult)
        ShowProduct(inst)
    end
end

local function continuecookfn(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("work", true)
        inst.Light:Enable(true)
        inst.SoundEmitter:KillSound("snd")
        inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_rattle", "snd")
    end
end

local function harvestfn(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("idle")
    end
end

local function getstatus(inst)
    return (inst:HasTag("burnt") and "BURNT")
        or (inst.components.stewer:IsDone() and "DONE")
        or (not inst.components.stewer:IsCooking() and "EMPTY")
        or (inst.components.stewer:GetTimeToCook() > 15 and "COOKING_LONG")
        or "COOKING_SHORT"
end

local function onfar(inst)
    if inst.components.container ~= nil then
        inst.components.container:Close()
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("built")
    inst.AnimState:PushAnimation("idle", false)
    inst.SoundEmitter:PlaySound("dontstarve/common/cook_pot_craft")
end

local function onsave(inst, data)
    if inst.components.stewer ~= nil then
        data.chef_id = inst.components.stewer.chef_id
        data.ingredient_prefabs = inst.components.stewer.ingredient_prefabs
        data.product_spoilage = inst.components.stewer.product_spoilage
    end

    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil then
        if inst.components.stewer ~= nil then
            inst.components.stewer.chef_id = data.chef_id
            inst.components.stewer.ingredient_prefabs = data.ingredient_prefabs
            inst.components.stewer.product_spoilage = data.product_spoilage
        end
        if data.burnt then
            inst.components.burnable.onburnt(inst)
            inst.Light:Enable(false)
        end
    end
end

local function OnLoadPostPass(inst, newents, data)
    if data and data.additems and inst.components.container then
        for i, itemname in ipairs(data.additems)do
            local ent = SpawnPrefab(itemname)
            inst.components.container:GiveItem(ent)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    -- Set scale from mod configuration (default 1 if not set)
    local scale = (TUNING.deluxpotconf and TUNING.deluxpotconf.Scale) or 1
    MakeObstaclePhysics(inst, 1 * scale)
    inst.Transform:SetScale(3 * scale, 3 * scale, 3 * scale)

    inst.MiniMapEntity:SetIcon("deluxpot.tex")
    inst.MiniMapEntity:SetPriority(1)

    inst.Light:Enable(false)
    inst.Light:SetRadius(.6)
    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(.5)
    inst.Light:SetColour(235/255,62/255,12/255)

    inst:AddTag("structure")
    
    inst.AnimState:SetBank("deluxpot")
    inst.AnimState:SetBuild("deluxpot")
    inst.AnimState:PlayAnimation("idle")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        -- Add the 'stewer' component on the client side
        inst:AddComponent("stewer")
    
        -- Save any existing OnEntityReplicated function
        local old_OnEntityReplicated = inst.OnEntityReplicated
    
        -- Define the new OnEntityReplicated function
        inst.OnEntityReplicated = function(inst)
            -- Call the old function if it exists
            if old_OnEntityReplicated ~= nil then
                old_OnEntityReplicated(inst)
            end
            -- Set up the container widget
            inst.replica.container:WidgetSetup("cookpot")
        end
    
        return inst
    end

    inst:AddComponent("stewer")
    inst.components.stewer.cooktimemult = TUNING.deluxpotconf.CookTimeMult
    inst.components.stewer.onstartcooking = startcookfn
    inst.components.stewer.oncontinuecooking = continuecookfn
    inst.components.stewer.oncontinuedone = continuedonefn
    inst.components.stewer.ondonecooking = donecookfn
    inst.components.stewer.onharvest = harvestfn
    inst.components.stewer.Harvest = HarvestAmount
    inst.components.stewer.StartCooking = StartCookingDeluxe
    inst.components.stewer.dostew = dostewdeluxe
    inst.components.stewer.dospoil = dospoildeluxe
    inst.components.stewer.onspoil = spoilfn
    
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("cookpot") -- Use the cookpot widget setup
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose
    
    inst:AddComponent("inventoryitemholder")
    inst.components.inventoryitemholder:SetAcceptStacks(true)
    inst.components.inventoryitemholder:SetAllowedTags({"cookable"})
    inst.components.inventoryitemholder:SetOnItemGivenFn(function(inst, item, giver)
        if inst.components.container:GiveItem(item) then
            inst.components.container:Open(giver)
            return true
        end
        return false
    end)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(3,5)
    inst.components.playerprox:SetOnPlayerFar(onfar)

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:ListenForEvent("onbuilt", onbuilt)

    MakeSnowCovered(inst)

    --MakeMediumBurnable(inst, nil, nil, true)
    MakeSmallPropagator(inst)

    inst.OnSave = onsave 
    inst.OnLoad = onload

    return inst
end

return Prefab("deluxpot", fn, assets, prefabs),
    -- Placer now uses the configured scale
    MakePlacer("deluxpot_placer", "deluxpot", "deluxpot", "idle", nil, nil, nil, 3 * ((TUNING.deluxpotconf and TUNING.deluxpotconf.Scale) or 1))
