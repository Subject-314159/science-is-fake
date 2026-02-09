local init = function()
end

local load = function()
        commands.add_command("sif-test-deadlock", "Start the unittesting function to check if the current tech tree is deadlock free", function(command)
            -- Instantiate storage
            storage = storage or {}

            -- Check if unittest is running
            if storage.unittest_deadlock then
                game.print("Unit test for deadlock is already running, please wait...")
            else

                -- Create the force
                local f = game.create_force()

                -- Get the entry tech
                local tech = {}
                local numtech = 0
                for _,t in pairs(f.technologies) do
                    if not t.prerequisites then table.insert(tech,t) end
                    numtech=numtech+1
                end

                -- Set the flag and init struct
                storage.unittest_deadlock = true
                storage.deadlock = {force = f, available_tech=tech, recipe_shortlist = {}}

                -- Inform user
                game.print("unittest for deadlock started, expected duration: "..numtech.." ticks")
                game.print("During this period (severe) lag may be experienced")
            end
    end)
end

script.on_configuration_changed(function()
    init()
end)

script.on_init(function()
    init()
    load()

    -- Warn players if the mod is added to an existing save
    -- We consider games that are >10sec old to be an existing save
    if game.tick > 10 * 60 then
        game.print(
            "[color=red]WARNING[/color] It appears that Science Is Fake was added to an existing save, be aware that your production chain might be broken!")
    end
end)

script.on_load(function()
    load()
end)

local function cleanup_unittest_deadlock()
    -- Reset the flag
    storage.unittest_deadlock = false

    -- Delete the force
    local tgt = next(game.forces)
    if tgt.index == storage.deadlock.force.index then
        tgt = next(game.forces, storage.deadlock.force.index)
    end
    if tgt then
        game.merge_forces(storage.deadlock.force.index, tgt.index)
    end

    -- Delete the data array
    storage.deadlock = nil
end

local function fail_unittest_deadlock()
    -- This function is to be called as soon as we fail our deadlock unittest
    game.print("[color=red][FAIL][/color] Unable to research all technologies due to locked recipies")
    cleanup_unittest_deadlock()
end

local function pass_unittest_deadlock()
    -- This function is to be called as soon as we pass our deadlock unittest
    game.print("[color=green][PASS][/color] All technologies can be researched and no deadlocks are found")
    cleanup_unittest_deadlock()
end

local function do_unittest_deadlock_tick()
    --Get the first next available tech
    local tech = table.remove(storage.deadlock.available_tech)
    if tech then
        local researchable = false
        -- Check if this technology has a trigger
        local T = protoypes.technology[tech.name]
        if T.research_trigger then
            -- Mark researchable
            researchable = true
        else
            if tech.research_unit_ingredients then
                -- Get a list of all "sciences" needed for this tech
                local reqs = {}
                for _,unit in pairs(tech.research_unit_ingredients) do
                    reqs[unit.name]=true
                end

                -- Go through previously used recipe shortlist
                for _,rec in pairs(storage.deadlock.recipe_shortlist or {}) do
                    for _,res in pairs(rec.products) do
                        if reqs[res.name] then reqs[res.name] = nil end
                    end
                end

                -- Go through all unlocked recipes for this force and check if we can produce each research ingredient
                for _,rec in pairs(f.recipes or {}) do
                    --Early exit if we found all "sciences"
                    if next(reqs) == nil then break end

                    -- Go through the products of this recipe and check if it is one of our "sciences"
                    for _,res in pairs(rec.products) do
                        if reqs[res.name] then 
                            -- Clear this science requirement
                            reqs[res.name] = nil

                            -- Add this recipe as unlocking recipe in our shortlist
                            if not storage.deadlock.recipe_shortlist[res.name] then storage.deadlock.recipe_shortlist[res.name] = res end
                        end
                    end

                end

                -- Check if all required research ingredients are produced, or fail our unit test
                if next(reqs) then
                    local missing = {}
                    for r,_ in pairs(reqs) do
                        table.insert(missing,r)
                    end
                    game.print("Unable to research " .. tech.name..", unable to produce following items: "..serpent.line(missing))
                    fail_unittest_deadlock()
                end

                -- If we got here it means we can research this tech, mark researchable
                researchable = true
            else
                -- No ingredients either means it costs time to research or it has a trigger, mark researchable
                researchable = true
            end
        end

        if researchable then
            -- Research the current tech
            tech.research_recursive()

            -- For each successor, check if it is available
            for _,suc in pairs(tech.successors or {}) do
                -- Only non-infinite tech
                local TS = prototypes.technology[suc.name]
                if TS.max_level < 4294960000 then
                    local available = true
                    for _,pre in pairs(suc.prerequisites or {}) do
                        available = available and pre.researched
                    end

                    -- Add this successor as available next tech
                    if available then table.insert(storage.deadlock.available_tech,suc) end
                end
            end

            -- Notify user
            game.print(tech.name.." is researchable with the available recipes")
        end
    else
        -- There are no more available tech, check if all technologies are indeed researched
        local all_researched = true
        for _,t in pairs(storage.unittest_deadlock.force.technologies) do
            local T = prototypes.technology[t.name]
            if T.max_level < 4294960000 and not t.researched then
                -- This tech is not infinite and not researched
                -- Check if it is available by checking if all prerequisites are researched
                local available = true
                for _,pre in pairs(t.prerequisites) do
                    available = available and pre.researched
                end

                -- Add this successor as available next tech
                if available then 
                    table.insert(storage.deadlock.available_tech,t) 
                    all_researched = false
                end
            end
        end

        if all_researched then
            pass_unittest_deadlock()
        end
    end
end

script.on_event(defines.events.on_tick, function(e)
    if storage.unittest_deadlock then
        do_unittest_deadlock_tick()
    end
end)
