require "Libraries/CYK/Sandboxing/All"

-- CYK is the environment!
getset.defineProperty(_ENV, "CYK", { get = function() return Encounter["CYK"] end, set = function(value) error("Can't set the value CYK in a wave!") end })

-- As a wave is a different script, we have to update State() to go through the encounter script
function State(state, arg1, arg2, arg3)
    SuperCall(Encounter, "CYK.PlayerState", state, arg1, arg2, arg3)
end

veryBigBulletPool = { }
_CreateProjectile = CreateProjectile
-- Overrides CreateProjectile
function CreateProjectile(spritename, initial_x, initial_y, layer)
    return CreateProjectileForReal(spritename, initial_x, initial_y, layer, false)
end

_CreateProjectileAbs = CreateProjectileAbs
-- Overrides CreateProjectileAbs
function CreateProjectileAbs(spritename, initial_x, initial_y, layer)
    return CreateProjectileForReal(spritename, initial_x, initial_y, layer, true)
end

-- Actually does the thing CreateProjectile and CreateProjectileAbs is supposed to do
function CreateProjectileForReal(spritename, initial_x, initial_y, layer, isAbs)
    -- Starts the right CYF function
    local projectile = (isAbs and _CreateProjectileAbs or _CreateProjectile)(spritename, initial_x, initial_y, layer)
    if not layer then
        projectile.sprite.layer = "Bullet"
    end

    -- Sets this bullet's enemy creator and adds it to a very big pool of bullets
    projectile["from"] = math.random(1, #Encounter["CYK"].enemies)
    table.insert(veryBigBulletPool, projectile)
    return projectile
end

-- Is this one even in the documentation?
function CreateProjectileLayer(name, relatedTag, before)
    if type(name) ~= "string" then
        error("CreateProjectileLayer needs a string for its name parameter.")
    end
    if type(relatedTag) ~= "string" and relatedTag ~= "nil" then
        error("CreateProjectileLayer needs a string for its relatedTag parameter.")
    elseif relatedTag == nil then
        relatedTag = ""
    end
    CreateLayer(name .. "Bullet", relatedTag .. "Bullet", before)
end

-- Arena object
FakeArena = (require "Libraries/CYK/RotatableArena")()
_Arena = Arena
SetGlobal("Arena", _Arena)
Arena = { }

getset.defineProperty(Arena, "width",         { get = function()      return _Arena.width         end, set = function(value) _Arena.width = value         end })
getset.defineProperty(Arena, "height",        { get = function()      return _Arena.height        end, set = function(value) _Arena.height = value        end })
getset.defineProperty(Arena, "x",             { get = function()      return _Arena.x             end, set = function(value) _Arena.x = value             end })
getset.defineProperty(Arena, "y",             { get = function()      return _Arena.y             end, set = function(value) _Arena.y = value             end })
getset.defineProperty(Arena, "currentwidth",  { get = function()      return _Arena.currentwidth  end, set = function(value) _Arena.currentwidth = value  end })
getset.defineProperty(Arena, "currentheight", { get = function()      return _Arena.currentheight end, set = function(value) _Arena.currentheight = value end })
getset.defineProperty(Arena, "currentx",      { get = function()      return _Arena.currentx      end, set = function(value) _Arena.currentx = value      end })
getset.defineProperty(Arena, "currenty",      { get = function()      return _Arena.currenty      end, set = function(value) _Arena.currenty = value      end })
getset.defineProperty(Arena, "isResizing",    { get = function()      return _Arena.isResizing    end, set = function(value) _Arena.isResizing = value    end })
getset.defineProperty(Arena, "isMoving",      { get = function()      return _Arena.isMoving      end, set = function(value) _Arena.isMoving = value      end })
getset.defineProperty(Arena, "isModifying",   { get = function()      return _Arena.isModifying   end, set = function(value) _Arena.isModifying = value   end })

function Arena.Resize(width, height)                                       _Arena.Resize(width, height)                                       end
function Arena.ResizeImmediate(width, height)                              _Arena.ResizeImmediate(width, height)                              end
function Arena.Move(x, y, movePlayer, immediate)                           _Arena.Move(x, y, movePlayer, immediate)                           end
function Arena.MoveTo(x, y, movePlayer, immediate)                         _Arena.MoveTo(x, y, movePlayer, immediate)                         end
function Arena.MoveAndResize(x, y, width, height, movePlayer, immediate)   _Arena.MoveAndResize(x, y, width, height, movePlayer, immediate)   end
function Arena.MoveToAndResize(x, y, width, height, movePlayer, immediate) _Arena.MoveToAndResize(x, y, width, height, movePlayer, immediate) end

-- New Arena functions and values
getset.defineProperty(Arena, "inner",    { get = function() return FakeArena.arena["inner"] end, set = function(value) error("Can't set the Arena's inner sprite!") end })
getset.defineProperty(Arena, "outer",    { get = function() return FakeArena.arena          end, set = function(value) error("Can't set the Arena's outer sprite!") end })
getset.defineProperty(Arena, "rotation", { get = function() return FakeArena.arena.rotation end, set = function(value) FakeArena.RotateArena(value, false)            end })

function Arena.Update() FakeArena.Update() end

-- Overwrite the Inventory object's functions set in all scripts
function Inventory.SetInventory(names)                    SuperCall(Encounter, "CYK.Inventory.SetInventory", names)                    end
function Inventory.AddCustomItem(name, desc, type, tType) SuperCall(Encounter, "CYK.Inventory.AddCustomItem", name, desc, type, tType) end
function Inventory.AddItem(name, index)                   SuperCall(Encounter, "CYK.Inventory.AddItem", name, index)                   end
function Inventory.RemoveItem(index)                      SuperCall(Encounter, "CYK.Inventory.RemoveItem", index)                      end
function Inventory.SetItem(index, name)                   SuperCall(Encounter, "CYK.Inventory.SetItem", index, name)                   end
function Inventory.GetItem(index)                         SuperCall(Encounter, "CYK.Inventory.GetItem", index)                         end
function Inventory.GetItemData(index)                     SuperCall(Encounter, "CYK.Inventory.GetItemData", index)                     end