return function(CYK)
    -- Inventory management system
    local self = { }

    self.itemLimit = 12
    self.inventory = { }
    function self.SetInventory(inventory)
        if type(inventory) ~= "table" then
            error("Inventory.SetInventory() needs a table of strings as an argument.")
        end
        self.inventory = { }
        for i = 1, math.min(#inventory, self.itemLimit) do
            if type(inventory[i]) ~= "string" then
                error("Inventory.SetInventory() needs a table of strings as an argument.")
            end
            if not self.items[inventory[i]] then
                error("The item " .. tostring(inventory[i]) .. " doesn't exist.")
            end
            table.insert(self.inventory, inventory[i])
        end
        if #inventory > self.itemLimit and CYKDebugLevel > 0 then
            DEBUG("[WARN] Inventory.SetInventory: You tried to set " .. tostring(#inventory) .. " items, but only a maximum of " .. tostring(self.itemLimit) .. " items are allowed.")
        end
    end

    self.items = { }
    function self.AddCustomItem(name, description, itemType, targetType)
        if type(name) ~= "string" then
            error("Inventory.AddCustomItem: The first argument must be a string. (name)")
        elseif type(description) ~= "string" then
            error("Inventory.AddCustomItem: The second argument must be a string. (description)")
        elseif itemType ~= 0 and itemType ~= 1 then
            error("Inventory.AddCustomItem: The third argument must be 0 or 1. (type)")
        elseif targetType ~= "Enemy" and targetType ~= "Player" and targetType ~= "AllPlayer" and targetType ~= "AllEnemy" then
            error("Inventory.AddCustomItem: The fourth argument must be Player, Enemy, AllPlayer or AllEnemy. (targetType)")
        elseif self.items[name] then
            if CYKDebugLevel > 1 then
                DEBUG("[WARN] Inventory.AddCustomItem: The item " .. name .. " already exists in the item database.")
            end
        end

        local item = { }
        item.description = "[font:uidialog][novoice][instant][color:808080]" .. description
        item.type = itemType
        item.targetType = targetType
        self.items[name] = item
    end

    function self.AddItem(name, index)
        if index == nil then index = #self.inventory + 1 end
        if index < 1 or index > self.itemLimit then
            error("Inventory.AddItem: The item index " .. tostring(index) .. " is invalid, it must be between 1 and " .. tostring(self.itemLimit) .. ".")
        elseif not self.items[name] then
            error("Inventory.AddItem: The item " .. tostring(inventory[i]) .. " doesn't exist.")
        end
        if #self.inventory == self.itemLimit then
            return false
        end
        if index > #self.inventory then table.insert(self.inventory, name)
        else                            table.insert(self.inventory, index, name)
        end
        return true
    end

    function self.RemoveItem(index)
        if index < 1 or index > #self.inventory then
            error("Inventory.RemoveItem: The item index " .. tostring(index) " is invalid, it must be between 1 and the number of items in the inventory.")
        else
            table.remove(self.inventory, index)
        end
    end

    function self.SetItem(index, name)
        if index < 1 or index > self.itemLimit then
            error("Inventory.SetItem: The item index " .. tostring(index) .. " is invalid, it must be between 1 and " .. tostring(self.itemLimit) .. ".")
        elseif not self.items[name] then
            error("Inventory.SetItem: The item " .. tostring(inventory[i]) .. " doesn't exist.")
        end
        if index <= #self.inventory then self.inventory[index] = name
        else                             table.insert(self.inventory, name)
        end
    end

    function self.GetItem(index)
        if index < 1 or index > #self.inventory then
            error("Inventory.GetItem: The item index " .. tostring(index) .. " is invalid, it must be between 1 and the number of items in the inventory.")
        end
        return self.inventory[index]
    end

    function self.GetItemData(index)
        if index < 1 or index > #self.inventory then
            error("Inventory.GetItemData: The item index " .. tostring(index) .. " is invalid, it must be between 1 and the number of items in the inventory.")
        end
        return self.items[self.inventory[index]]
    end

    self.turnItemsUsed = { }
    function self.UseItem(itemID)
        local item = self.inventory[itemID]
        if item == nil then
            error("Tried to use item #" .. tostring(itemID) .. " out of " .. tostring(#self.inventory))
        end
        local itemData = self.items[item]
        if itemData.type == 0 then
            table.remove(self.inventory, itemID)
        end
    end

    function self.GetCurrentInventory()
        local currentInventory = table.copy(self.inventory)
        local removedItems = { }
        for i = 1, CYK.turn - 1 do
            if self.turnItemsUsed[i] ~= nil then
                if self.items[currentInventory[self.turnItemsUsed[i]]].type == 0 then
                    table.insert(removedItems, self.turnItemsUsed[i])
                    table.remove(currentInventory, self.turnItemsUsed[i])
                end
            end
        end
        local last = 999 -- I hope you don't have a thousand items boi
        for i = 1, #removedItems do
            if removedItems[i] >= last then
                for j = i, #removedItems do
                    removedItems[j] = removedItems[j] + 1
                end
            end
            last = removedItems[i]
        end
        return { inventory = currentInventory, removed = removedItems }
    end

    return self
end