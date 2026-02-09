-- Convert all prototype 'item' to 'tool'
-- For all other item children make a conversion recipe
-- e.g. 'ammo' to 'tool' and 'tool' to 'ammo'
-- For those items add a small mark (paper icon?) in one of the corners
-- Function to create recipes
local function get_recipe(from, to)
    local org = data.raw["recipe"][from]
    if not org then
        org = data.raw["recipe"][to]
    end
    local r = {
        type = "recipe",
        name = from .. "-to-" .. to,
        ingredients = {{
            type = "item",
            name = from,
            amount = 1
        }},
        results = {{
            type = "item",
            name = to,
            amount = 1
        }},
        energy_required = 0.1,
        maximum_productivity = 0,
        enabled = (org and org.enabled) or true,
        -- enabled = false,
        allow_decomposition = false,
        allow_quality = false,
        auto_recycle = false
    }
    return r
end
local function get_recipe_to(name)
    return get_recipe(name, name .. suffix)
end
local function get_recipe_from(name)
    return get_recipe(name .. suffix, name)
end

local function add_recipe_to_tech(recipe)
    -- Loop through all tech and their unlocking recipes
    -- TODO: Update to DAG, because now we add the recipe to ALL applicable tech and not just only the first one, possibly resulting in duplicates
    for tech_name, tech in pairs(data.raw["technology"]) do
        local match = false
        for _, effect in pairs(tech.effects or {}) do
            if effect.type == "unlock-recipe" then
                -- Check if this recipe's products are used in our recipe
                local urec = data.raw["recipe"][effect.recipe]
                for _, res in pairs(urec.results or {}) do
                    if res.name == recipe.ingredients[1].name or res.name == recipe.results[1].name then
                        match = true
                        goto continue
                        break
                    end
                end
                if match then
                    break
                end
            end
        end

        ::continue:: -- TODO: Verify if we can jump here from the loop-in-the-loop-in-the-loop
        -- If this technology unlocks a recipe that produces an item used in our recipe, add our recipe to the tech
        if match then
            local prop = {
                type = "unlock-recipe",
                recipe = recipe.name
            }
            table.insert(tech.effects, prop)
        end
    end
end

-- Create tool copies of non-items
-- Ignore selection tools, blueprints, rail planner and tools
local prot = {"item", "ammo", "capsule", "gun", "item-with-entity-data", "item-with-label", "item-with-inventory",
              "blueprint-book", "item-with-tags", "module", "rail-planner", "space-platform-starter-pack", "armor",
              "repair-tool"}
local recs = {}
local itms = {}
for _, p in pairs(prot) do
    -- Init the sub-array
    itms[p] = {}

    -- Go through all prototypes
    for _, itm in pairs(data.raw[p] or {}) do
        -- Deepcopy the item
        local cur = table.deepcopy(itm)
        cur.type = "tool"
        cur.durability = 1
        cur.durability_description_key = "description.science-pack-remaining-amount-key"
        cur.factoriopedia_durability_description_key = "description.factoriopedia-science-pack-remaining-amount-key"
        cur.durability_description_value = "description.science-pack-remaining-amount-value"

        -- Update non-item items to "science-is-fake-tools"
        if p ~= "item" then
            -- Update item prototype data
            cur.name = cur.name .. suffix

            -- TODO: Fix localised name

            -- Create a conversion recipe
            local rto = get_recipe_to(itm.name)
            -- local rfrom = get_recipe_from(itm.name)
            -- table.insert(recs, rto)
            -- table.insert(recs, rfrom)
            data:extend({rto})

            -- Add the conversion recipes to the appropriate tech
            add_recipe_to_tech(rto)

        end

        -- Add the item to the mapping table
        -- If the item is a regular tool it return the same name
        -- If the item is not a tool it returns the name + suffix
        item_map[itm.name] = cur.name

        -- Remember the item
        itms[p][itm.name] = cur
    end
end

-- Remove item in data and extend with tool
for _, p in pairs(prot) do
    for name, itm in pairs(itms[p]) do
        -- Remove the item
        if p == "item" then
            data.raw["item"][name] = nil
        end

        -- Extend the tool
        data:extend({itm})
    end
end

-- Create new recipes
-- data:extend(recs)
