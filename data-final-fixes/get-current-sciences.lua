-- Go through all labs
-- Get all sciences per lab
-- Add unique sciences to science collection
for name, lab in pairs(data.raw["lab"]) do
    -- Init the lab map array
    lab_map[name] = {
        sciences = lab.inputs,
        items = {}
    }

    -- Add unique sciences to the all science array
    for _, science in pairs(lab.inputs) do
        -- Check if this science is already present in our all sciences array
        local present = false
        for _, s in pairs(all_sciences) do
            if s == science then
                present = true
                break
            end
        end

        -- Add it if not present
        if not present then
            -- Add the science to the all science array
            table.insert(all_sciences, science)

            -- Get the science production cost
            science_cost[science] = {}
            local cur_cost = science_cost[science]

            -- Get the recipe that produces this science
            for _, recipe in pairs(data.raw["recipe"]) do
                -- Check if this recipe produces our science
                local recipe_produces_science = false
                for _, result in pairs(recipe.results or {}) do
                    if result.type == "item" and result.name == science then
                        recipe_produces_science = true
                        break
                    end
                end

                -- Add the recipe ingredient costs to our cost array
                -- TODO: Decide what to do if multiple recipes produce a science (with potential ingredients which are unlocked later in the tree and causing a deadlock)
                -- TODO: Decide what to do if a science recipe requires another science pack (probably needs recursive replacement)
                if recipe_produces_science then
                    for _, ingredient in pairs(recipe.ingredients or {}) do
                        -- Get the tool name equivalent of the item for non item/tool items/fluids
                        local toolname
                        if ingredient.type == "item" then
                            toolname = item_map[ingredient.name]
                        else
                            if fluid_map[ingredient.name] then
                                toolname = fluid_map[ingredient.name].barrel_item
                            end
                        end
                        if toolname then
                            cur_cost[toolname] = (cur_cost[toolname] or 0) + ingredient.amount
                        end
                    end
                end
            end

        end
    end
end

