-- Library by WD200019

-- SuperCall(func, arg1, arg2, ...)
--  !! Must be loaded in a script with a function to call from another script !! (see Examples)
--     Calls the function 'func' in the current script with the arguments 'arg1', 'arg2', ...
--     Can be called from another script without triggering an error.
--         func (function or string): Refers to the function in the target script to call.
--                                    Can be used in several ways:
---        (in another script)
--         targetScript.Call("SuperCall", function_in_the_target_script)
--         targetScript.Call("SuperCall", "function_in_the_target_script")
--         targetScript.Call("SuperCall", {"function_in_the_target_script", arg1, arg2, ...})
--
--         arg1, arg2, ... (any type): arguments to be passed to the target function.
--
--     Examples (from enemy or wave scripts):
--
--       -- calls the function 'func' of the table 'mytable' in the Encounter script
--       Encounter.Call("SuperCall", "mytable.func")
--
--       -- calls the function 'func2' of the table 'mytable' in the Encounter script, with arguments
--       Encounter.Call("SuperCall", {"mytable.func2", "one", "two"})
--
--     Examples (from the encounter script):
--
--       -- Resizes the Arena in the first active wave (ONLY DURING DEFENDING)
--       Wave[1].Call("SuperCall", {"Arena.ResizeImmediate", 400, 400})
--
--       -- Uses CHECK on the first enemy
--       enemies[1].Call("SuperCall", {"HandleCustomCommand", "CHECK"})

function _SuperCall(func, ...)
    if type(func) == "string" then
        local oldFunc = func

        func = Recurse(func)

        if type(func) == "string" then
            error(func .. oldFunc .. "\" could not be found.")
        elseif func == nil then
            error("The function " .. oldFunc .. " could not be found.")
        end
    elseif type(func) ~= "function" then
        error("Attempt to SuperCall a non-function value.")
    end

    return func(...)
end

function SuperCall(script, func, ...)
    if tostring(script) ~= "ScriptWrapper" then
        error("SuperCall's first parameter must be a script object.")
    end
    if type(func) ~= "string" then
        error("SuperCall's second parameter must be a string.")
    end
    local tab = { func }
    for k, v in pairs({ ... }) do
        table.insert(tab, v)
    end
    return script.Call("_SuperCall", tab)
end

function Recurse(arg, obj)
    obj = obj or _G

    if arg:find("%.") then
        local objectName = arg:sub(0, arg:find("%.") - 1)

        obj = obj[objectName]

        -- we couldn't find the object `objectName` in `obj`
        if not obj then
            return "The table item \"" .. objectName .. "\" of \""
        end

        return Recurse(arg:sub(arg:find("%.") + 1), obj)
    else
        return obj[arg]
    end
end
