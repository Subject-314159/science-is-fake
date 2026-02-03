local init = function()
end

local load = function()
end

script.on_configuration_changed(function()
    init()
end)

script.on_init(function()
    init()
    load()

    -- Warn players if the mod is added to an existing save
    -- We consider games that are >10sec old to be an existing save
    if game.tick > 10*60 then
        game.print("[color=red][font=bold]WARNING[/font][/color] It appears that Science Is Fake was added to an existing save, be aware that your production chain might be broken!")
end)

script.on_load(function()
    load()
end)

script.on_event(defines.events.on_tick, function(e)
end)
