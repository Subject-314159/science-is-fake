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
end)

script.on_load(function()
    load()
end)

script.on_event(defines.events.on_tick, function(e)
end)
