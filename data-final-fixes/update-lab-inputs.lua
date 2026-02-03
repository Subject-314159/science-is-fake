-- Go through all labs in the mapping table and add the new items as input

for lab_name, prop in pairs(lab_map) do
    local lab = data.raw["lab"][lab_name]
    lab.inputs = {} -- We *should* be able to kick out all original science packs here
    for science, _ in pairs (prop.items) do
        table.insert(lab.inputs, science)
    end
end