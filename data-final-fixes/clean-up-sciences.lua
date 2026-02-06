-- Remove all science from the game through the following steps:
-- Remove all science pack items
-- Remove all science items from recipe inputs
-- Remove all recipes that then no longer have inputs/outputs
-- Remove all removed recipes from technology
-- Remove all technologies that no longer have unlock effects
local successful = false

-- Remove all science packs
for _, sci in pairs(all_sciences) do
    -- data.raw["tool"][sci] = nil
    data.raw["tool"][sci].hidden = true
end

-- Remove all science inputs/outputs from recipes
-- And mark the recipe for removal if there are no ingredients/results left
local recipe_to_remove = {}
for recipe_name, recipe in pairs(data.raw["recipe"]) do
    local arrays = {recipe.ingredients, recipe.results}
    for _, arr in pairs(arrays) do
        local removed_something = false
        -- Reverse iterate over the ingredient/result array (because we will remove entries and want to keep the order)
        for i = #arr, 1, -1 do
            -- Check if the ingredient/result is a science pack
            if arr[i].type == "item" then
                for _, sci in pairs(all_sciences) do
                    if arr[i].name == sci then
                        -- Remove the science pack as main product from the recipe
                        -- if recipe.main_product == arr[i].name then
                        --     recipe.main_product = nil
                        -- end

                        -- Remove the ingredient/result
                        -- table.remove(arr, i)
                        removed_something = true
                        recipe.hidden = true
                        break
                    end
                end
            end
        end

        -- Check if there are any ingredients/results left, or mark for removal
        if removed_something then
            -- table.insert(recipe_to_remove, recipe_name)
            recipe_to_remove[recipe_name] = true
            log(recipe_name .. " marked for removal:" .. serpent.block(recipe))
        end
    end
end

log("Recipe to remove = " .. serpent.block(recipe_to_remove))
for rec, _ in pairs(recipe_to_remove) do
    -- data.raw["recipe"][rec] = nil
    data.raw["recipe"][rec].hidden = true
end

-- Remove all recipes from their technologies
local tech_to_remove = {}
for tech_name, tech in pairs(data.raw["technology"]) do
    if tech.effects then
        -- Remove the recipe effect
        for i = #tech.effects, 1, -1 do
            local eff = tech.effects[i]
            if eff.type == "unlock-recipe" and recipe_to_remove[eff.recipe] then
                table.remove(tech.effects, i)
            end
        end
        if #tech.effects == 0 then
            tech.effects = nil
            tech_to_remove[tech_name] = true
        end
    end
end

log("Tech to remove = " .. serpent.block(tech_to_remove))

-- Recursive inherit prerequisites from tech to be removed
local function recursive_inherit_prerequisites(tech, new)
    for _, pre in pairs(tech.prerequisites or {}) do
        if tech_to_remove[pre] then
            local pretech = data.raw["technology"][pre]
            recursive_inherit_prerequisites(pretech, new)
        else
            new[pre] = true
        end
    end
end

for tech_name, tech in pairs(data.raw["technology"]) do
    -- Inherit prerequisites
    local new = {}
    recursive_inherit_prerequisites(tech, new)
    tech.prerequisites = {}
    for pre, _ in pairs(new) do
        table.insert(tech.prerequisites, pre)
    end

    -- Remove tech from prerequisites that are to be removed
    for i = #tech.prerequisites, 1, -1 do
        if tech_to_remove[tech.prerequisites[i]] then
            table.remove(tech.prerequisites, i)
        end
    end
end

-- Remove all affected technologies
for tech_name, _ in pairs(tech_to_remove) do
    -- Remove the tech
    -- data.raw["technology"][tech_name] = nil
    data.raw["technology"][tech_name].hidden = true
end

-- Celebrate success
successful = true
if successful then
    log("Science is fake!")
end
