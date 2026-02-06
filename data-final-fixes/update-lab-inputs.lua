-- Go through all labs in the mapping table and add the new items as input
for lab_name, prop in pairs(lab_map) do
    local lab = data.raw["lab"][lab_name]
    lab.inputs = {} -- We *should* be able to kick out all original science packs here
    for science, _ in pairs(prop.items) do

        -- Check if this item is not accidentally a science pack
        local is_science_pack = false
        for _, s in pairs(all_sciences) do
            if s == science then
                is_science_pack = true
                break
            end
        end

        -- Add the item if it is not an original science pack
        if not is_science_pack then
            table.insert(lab.inputs, science)
        end
    end
end
