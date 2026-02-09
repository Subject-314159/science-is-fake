-- Reset all technology effetcs in order to re-unlock (new) recipes
for _,f in pairs(game.forces) do
    f.reset_technology_effects()
end