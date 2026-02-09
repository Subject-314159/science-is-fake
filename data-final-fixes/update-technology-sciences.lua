-- For each technology, check what it unlocks, and base the research cost on that
-- e.g. technology logistics unlocks recipes: 
-- Splitter: 5x green circuit + 5x iron plate + 4x yellow belt
-- Underground: 10x iron plate + 5x yellow belt
-- Total: 5x green circuit + 15x iron plate + 9x yellow belt
-- One research increment costs 1 automation science pack
-- The net cost for one increment is (average of sciences per increment) * (sum of each recipe ingredient)
-- So the net cost (ingredients) for one technology research: (1 * 5) green circuit + (1 * 15) iron plate + (1 * 9) yellow belt
-- The rest of the technology unit remains the same; count, count_formula, time
-- Technology with a trigger unlock will not be affected
-- Technology that unlocks anything else but a recipe gets the sum of ingredients for that science pack for each unlock effect (for now)
-- e.g. incerter capacity bonus 1 has one effect inserter-stack-size-bonus and costs 1 automation and 1 logistics science pack
-- Automation science pack: 1x copper plate + 1x iron gear
-- Logistic science pack: 1x yellow inserter + 1x yellow belt
-- Total non-recipe unlocks: 1
-- The net cost for one increment is (number of non-recipe unlocks)  * (sum of each science ingredient)
-- So the net cost (ingredients) for one technology research: (1 * 1) copper plate + (1 * 1) iron gear + (1 * 1) yellow inserter + (1 * 1) yellow belt
-- Go through all technologies
for name, tech in pairs(data.raw["technology"]) do
    -- Sum the cost of all unlocked recipe ingredients
    if tech.unit then
        local all_results = {}
        local cost = {}
        local non_recipe_effects = 0
        for _, effect in pairs(tech.effects or {}) do
            if effect.type == "unlock-recipe" then
                local recipe = data.raw["recipe"][effect.recipe]
                for _, ingredient in pairs(recipe.ingredients or {}) do
                    local toolname, amount
                    if ingredient.type == "item" then
                        -- Get the tool name equivalent of the item for non item/tool items
                        toolname = item_map[ingredient.name]
                        amount = ingredient.amount
                    else
                        -- Get the barrel equivalent of the fluid and the number of barrelt (rounded up) based on the fluid count for this recipe
                        toolname = fluid_map[ingredient.name].barrel_item
                        amount = math.ceil(ingredient.amount / fluid_map[ingredient.name].fluid_amount)
                    end
                    -- It could be that we have a science pack as ingredient, so we need to check nil
                    if toolname then
                        cost[toolname] = (cost[toolname] or 0) + amount
                    end
                end

                -- Collect each results
                for _, result in pairs(recipe.results or {}) do
                    all_results[result.name] = true
                    if item_map[result.name] then
                        all_results[item_map[result.name]] = true
                    end
                    if fluid_map[result.name] then
                        all_results[fluid_map[result.name].barrel_item] = true
                    end
                end
            else
                non_recipe_effects = non_recipe_effects + 1
            end
        end

        -- Remove all items from the cost which are a result of the unlocked recipe
        -- This is to prevent deadlocks
        -- E.g. technology fluid handling unlocks both barrelling/unbarrelling recipes
        -- But the translated required items for the technology are only unlocked by this technology
        -- To investigate: We might unlock "optimizing" recipes that produce material which is already unlocked, we should not have to remove those
        -- Option: BFS DAG the technologies instead
        -- For each result removed this way, add a non_recipe_effect multiplier
        for res, _ in pairs(all_results) do
            if cost[res] then
                non_recipe_effects = non_recipe_effects + 1
                cost[res] = nil
            end
        end

        -- Get the science cost for non-recipe effects
        -- Or if the tech does not have any effects at all
        if non_recipe_effects > 0 or not tech.effects or next(cost) == nil then
            -- Correct multiplier if we got here because the tech does not have any effects
            if non_recipe_effects == 0 then
                non_recipe_effects = 1
            end

            -- Go through all science packs required for this technology
            for _, ingredient in pairs(tech.unit.ingredients or {}) do
                local science = ingredient[1]
                -- Add each item ingredient cost of that science to our total cost multiplied by the number of non-recipe effects this tech has
                for item, count in pairs(science_cost[science] or {}) do
                    cost[item] = (cost[item] or 0) + (count * non_recipe_effects)
                end
            end
        end

        -- Get the cost multiplier
        local sumscience = 0
        local sciencetypes = 0
        if not tech.unit then
            log(tech.name .. " has no unit")
        elseif not tech.unit.ingredients then
            log(tech.name .. " has no ingredients")
        end
        log(tech.name .. " has ingredients: " .. serpent.line(tech.unit.ingredients))
        for _, ingredient in pairs(tech.unit.ingredients or {}) do
            sumscience = sumscience + (ingredient[2] or 1)
            sciencetypes = sciencetypes + 1
        end

        -- Multiply the science cost if applicable
        if sumscience > 0 and sciencetypes > 0 then
            local multiplier = math.min(sumscience / sciencetypes, 10)
            for name, count in pairs(cost) do
                cost[name] = math.max(math.ceil(count * multiplier), 314)
            end
        end

        log(tech.name .. " final cost = " .. serpent.line(cost))

        -- Add the new ingredients to the lab map for each lab that can research this technology
        for lab_name, lab_prop in pairs(lab_map) do
            local can_research = true
            -- Check if this lab accepts each science pack of our current tech
            for _, ingredient in pairs(tech.unit.ingredients or {}) do
                -- Check if the lab accepts this one science pack
                local lab_accepts_science = false
                for _, lab_science in pairs(lab_prop.sciences) do
                    -- As soon as we find the science in this lab that our current tech needs we can break out of the loop
                    if ingredient[1] == lab_science then
                        lab_accepts_science = true
                        break
                    end
                end

                -- As soon as we encounter a science in our current tech that this lab does not accept we can break out of the loop
                if not lab_accepts_science then
                    can_research = false
                    break
                end
            end

            -- If this lab can research this technology, add all the items to the mapping
            for name, count in pairs(cost) do
                lab_prop.items[name] = true
            end
        end

        -- Replace the cost of this tech with the calculated cost
        if next(cost) ~= nil then
            -- Convert to ingredient array
            local ing = {}
            for item, count in pairs(cost) do
                local prop = {item, count}
                table.insert(ing, prop)
            end
            tech.unit.ingredients = ing
        end
    end
end

-- At this point we *should* have no more tech with any of the original science packs
