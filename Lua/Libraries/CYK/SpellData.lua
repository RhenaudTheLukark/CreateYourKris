return function(self)
    -- Spells data
    self.spells = { }

    -- Adds a spell to the spell database
    function self.AddSpell(name, description, tpCost, targetType)
        -- Function usage checking
        if type(name) ~= "string" then
            error("The first argument of CYK.AddSpell() must be a string. (name)", 2)
        elseif type(description) ~= "string" then
            error("The second argument of CYK.AddSpell() must be a string. (description)", 2)
        elseif type(tpCost) ~= "number" or tpCost < 0 or tpCost > 100 then
            error("The third argument of CYK.AddSpell() must be a number between 0 and 100. (tpCost)", 2)
        elseif targetType ~= "Enemy" and targetType ~= "Player" then
            error("The fourth argument of CYK.AddSpell() must be Player or Enemy. (targetType)", 2)
        elseif self.spells[name] then
            if CYKDebugLevel > 1 then
                DEBUG("[WARN] The spell " .. name .. " already exists in the spell database.")
            end
        end

        local spell = { }
        spell.description = "[font:uidialog][novoice][instant][color:808080]" .. description .. "\n[color:ff8040]" .. tostring(tpCost) .. "% TP"
        spell.tpCost = tpCost
        spell.targetType = targetType
        self.spells[name] = spell
    end
end