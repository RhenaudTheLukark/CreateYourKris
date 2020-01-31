require "Libraries/CYK/ScriptOwnerBypass"
require "Libraries/CYK/Util"

-- Pre-call to CYF's State() function. Updates awaitingCYKInput, which allows the player to use CYK
_OldState = State
function OldState(state, forceAwaitingCYKInput)
    if forceAwaitingCYKInput then
        awaitingCYKInput = forceAwaitingCYKInput
    else
        awaitingCYKInput = state == "NONE"
    end
    _OldState(state)
end

-- CYK's State() function
function State(state, arg1, arg2, arg3)
    return CYK.PlayerState(state, arg1, arg2, arg3)
end

-- GetCurrentState() returns CYK's state instead of CYF's state
OldGetCurrentState = GetCurrentState
function GetCurrentState()
    return CYK.state
end

-- Calls a function only if it exists. Simple yet deadly
function ProtectedCYKCall(func, ...)
    if func then
        return func(...)
    end
end

getset = require("Libraries/CYK/GetSet")

-- Inventory object, better not use it in a wave!
Inventory = { }
function Inventory.SetInventory(names)                    CYK.Inventory.SetInventory(names)                    end
function Inventory.AddCustomItem(name, desc, type, tType) CYK.Inventory.AddCustomItem(name, desc, type, tType) end
function Inventory.AddItem(name, index)                   CYK.Inventory.AddItem(name, index)                   end
function Inventory.RemoveItem(index)                      CYK.Inventory.RemoveItem(index)                      end
function Inventory.SetItem(index, name)                   CYK.Inventory.SetItem(index, name)                   end
function Inventory.GetItem(index)                         CYK.Inventory.GetItem(index)                         end
function Inventory.GetItemData(index)                     CYK.Inventory.GetItemData(index)                     end
function Inventory.SetAmount()                            error("Inventory.SetAmount is unavailable in CYK.")  end
function Inventory.GetType()                              error("Inventory.GetType is unavailable in CYK. Use Inventory.GetItemData(index).type instead.") end
function Inventory.AddCustomItems()                       error("Inventory.AddCustomItems is unavailable in CYK. You must use Inventory.AddCustomItem() to add each of your custom item, as new item data is required to correctly use items in CYK.") end
getset.defineProperty(Inventory, "NoDelete",  { get = function() error("Inventory.NoDelete is unavailable in CYK.") end, set = function(value) error("Inventory.NoDelete is unavailable in CYK.") end })
getset.defineProperty(Inventory, "ItemCount", { get = function() return #CYK.Inventory.inventory                    end, set = function(value) error("Inventory.ItemCount is read-only.") end         })

-- Player object
_Player = Player
Player = { }

getset.defineProperty(Player, "x",         { get = function() return _Player.x         end, set = function(value) _Player.x = value    end })
getset.defineProperty(Player, "y",         { get = function() return _Player.y         end, set = function(value) _Player.y = value    end })
getset.defineProperty(Player, "absx",      { get = function() return _Player.absx      end, set = function(value) _Player.absx = value end })
getset.defineProperty(Player, "absy",      { get = function() return _Player.absy      end, set = function(value) _Player.absy = value end })
getset.defineProperty(Player, "sprite",    { get = function() return _Player.sprite    end, set = function(value) _Player.sprite = value    end })
getset.defineProperty(Player, "ishurting", { get = function() return _Player.ishurting end, set = function(value) _Player.ishurting = value end })
getset.defineProperty(Player, "ismoving",  { get = function() return _Player.ismoving  end, set = function(value) _Player.ismoving = value  end })
getset.defineProperty(Player, "name",             { get = function() error("Player.name is unavailable in CYK.")             end, set = function(value) error("Player.name is unavailable in CYK.")             end })
getset.defineProperty(Player, "lv",               { get = function() error("Player.lv is unavailable in CYK.")               end, set = function(value) error("Player.lv is unavailable in CYK.")               end })
getset.defineProperty(Player, "hp",               { get = function() error("Player.hp is unavailable in CYK.")               end, set = function(value) error("Player.hp is unavailable in CYK.")               end })
getset.defineProperty(Player, "maxhp",            { get = function() error("Player.maxhp is unavailable in CYK.")            end, set = function(value) error("Player.maxhp is unavailable in CYK.")            end })
getset.defineProperty(Player, "maxhpshift",       { get = function() error("Player.maxhpshift is unavailable in CYK.")       end, set = function(value) error("Player.maxhpshift is unavailable in CYK.")       end })
getset.defineProperty(Player, "atk",              { get = function() error("Player.atk is unavailable in CYK.")              end, set = function(value) error("Player.atk is unavailable in CYK.")              end })
getset.defineProperty(Player, "weapon",           { get = function() error("Player.weapon is unavailable in CYK.")           end, set = function(value) error("Player.weapon is unavailable in CYK.")           end })
getset.defineProperty(Player, "weaponatk",        { get = function() error("Player.weaponatk is unavailable in CYK.")        end, set = function(value) error("Player.weaponatk is unavailable in CYK.")        end })
getset.defineProperty(Player, "def",              { get = function() error("Player.def is unavailable in CYK.")              end, set = function(value) error("Player.def is unavailable in CYK.")              end })
getset.defineProperty(Player, "armor",            { get = function() error("Player.armor is unavailable in CYK.")            end, set = function(value) error("Player.armor is unavailable in CYK.")            end })
getset.defineProperty(Player, "armordef",         { get = function() error("Player.armordef is unavailable in CYK.")         end, set = function(value) error("Player.armordef is unavailable in CYK.")         end })
getset.defineProperty(Player, "lastenemychosen",  { get = function() error("Player.lastenemychosen is unavailable in CYK.")  end, set = function(value) error("Player.lastenemychosen is unavailable in CYK.")  end })
getset.defineProperty(Player, "lasthitmultipler", { get = function() error("Player.lasthitmultipler is unavailable in CYK.") end, set = function(value) error("Player.lasthitmultipler is unavailable in CYK.") end })

Player.controlOverride = false
function Player.SetControlOverride(bool)
    if bool == true or bool == false then
        Player.controlOverride = bool
    else
        error("Player.SetControlOverride requires a boolean as an argument.")
    end
end

function Player.Move(x, y, ignoreWalls)      _Player.Move(x, y, ignoreWalls)      end
function Player.MoveTo(x, y, ignoreWalls)    _Player.MoveTo(x, y, ignoreWalls)    end
function Player.MoveToAbs(x, y, ignoreWalls) _Player.MoveToAbs(x, y, ignoreWalls) end
function Player.ForceHP()                    error("Player.ForceHP is unavailable in CYK.")         end
function Player.SetMaxHPShift()              error("Player.SetMaxHPShift is unavailable in CYK.")   end
function Player.SetAttackAnim()              error("Player.SetAttackAnim is unavailable in CYK.")   end
function Player.ResetAttackAnim()            error("Player.ResetAttackAnim is unavailable in CYK.") end
function Player.ChangeTarget(entityID)       error("Player.ChangeTarget is unavailable in CYK.")    end
function Player.Hurt()                       error("Player.Hurt is unavailable in CYK. Use the function entity.Hurt instead to damage both enemies and players!")             end
function Player.Heal()                       error("Player.Heal is unavailable in CYK. Use the function entity.Heal instead to heal both enemies and players!")               end
function Player.ForceAttack()                error("Player.ForceAttack is unavailable in CYK. Use the function entity.Hurt instead to damage both enemies and players!")      end
function Player.MultiTarget()                error("Player.MultiTarget is unavailable in CYK. Use the function entity.Hurt instead to damage both enemies and players!")      end
function Player.ForceMultiAttack()           error("Player.ForceMultiAttack is unavailable in CYK. Use the function entity.Hurt instead to damage both enemies and players!") end
function Player.CheckDeath()                 error("Player.CheckDeath is unavailable in CYK. Use the function entity.Hurt instead to damage both enemies and players!")       end