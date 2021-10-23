-- This library is the real core of CYK: it's where all the magic happens!
-- Without this library, CYK wouldn't even be active to begin with!

-- Wraps the EnteringState() function, and only calls the Encounter's EnteringState() function if CYK's state is changed
_EnteringState = EnteringState
function EnteringState(newstate, oldstate, isCYKState)
    if not isCYKState then EnteringRealState(newstate, oldstate)
    else                   ProtectedCYKCall(_EnteringState, newstate, oldstate)
    end
end

-- Wraps the EncounterStarting() function to include CYK itself, duh
_EncounterStarting = EncounterStarting
function EncounterStarting()
    require "Libraries/CYK/Sandboxing/Encounter"
    CYK = (require "Libraries/CYK/CYKCore")(_G)
    ProtectedCYKCall(_EncounterStarting)
end

-- Wraps the Update() function to update CYK and each active entity
_Update = Update
function Update()
    CYK.Update()
    ProtectedCYKCall(_Update)
    for i = #CYK.players, 1, -1 do
        ProtectedCYKCall(CYK.players[i].Update)
    end
    for i = 1, #CYK.allEnemies do
        local enemy = CYK.allEnemies[i]
        if enemy.isactive then
            ProtectedCYKCall(enemy.Update)
        elseif enemy.spareOrFleeStart > 0 then
            if enemy.spareOrFleeAnim == "spare" then CYK.UpdateSpare(enemy)
            else                                     CYK.UpdateFlee(enemy)
            end
        end
    end
end

-- Big function that checks if CYK's variables are correctly setup at the beginning of the Encounter
-- Will throw errors or warnings if anything's wrong
function CYKDataChecker()
    if CYKDebugLevel == nil then                DEBUG("CYKDebugLevel was not found. Setting to 0."); CYKDebugLevel = 0
    elseif type(CYKDebugLevel) ~= "number" then error("The encounter must have a variable named CYKDebugLevel as a number, but it is a " .. type(CYKDebugLevel) .. ".\nCYKDebugLevel tells CYK if it must display some warnings or debug texts.")
    end

    local debug = CYKDebugLevel > 0

    if type(arenasize) ~= "table" then         error("The encounter must have a variable named arenasize as a table, but it is a " .. type(arenasize) .. ".\narenasize must contain two numbers which are the size of the arena in the next wave in pixels.")
    elseif type(arenasize[1]) ~= "number" then error("The first value of the table arenasize must be a number, but it is a " .. type(arenasize[1]) .. ".\narenasize must contain two numbers which are the size of the arena in the next wave in pixels.")
    elseif type(arenasize[2]) ~= "number" then error("The second value of the table arenasize must be a number, but it is a " .. type(arenasize[2]) .. ".\narenasize must contain two numbers which are the size of the arena in the next wave in pixels.")
    end

    if type(arenapos) ~= "table" then         error("The encounter must have a variable named arenapos as a table, but it is a " .. type(arenapos) .. ".\narenapos must contain two numbers which are the position of the arena in the next wave.")
    elseif type(arenapos[1]) ~= "number" then error("The first value of the table arenapos must be a number, but it is a " .. type(arenapos[1]) .. ".\narenapos must contain two numbers which are the position of the arena in the next wave.")
    elseif type(arenapos[2]) ~= "number" then error("The second value of the table arenapos must be a number, but it is a " .. type(arenapos[2]) .. ".\narenapos must contain two numbers which are the position of the arena in the next wave.")
    end

    if arenarotation == nil then
        if debug then DEBUG("arenarotation was not found. Setting to 0.") end
        arenarotation = 0
    elseif type(arenarotation) ~= "number" then error("The encounter must have a variable named arenarotation as a number, but it is a " .. type(arenarotation) .. ".\narenarotation sets the roation value of the arena in the next wave.")
    end

    if arenacolor == nil then
        if debug then DEBUG("arenacolor was not found. Setting to { 0, 1, 0 } (green color).") end
        arenacolor = { 0, 1, 0 }
    elseif type(arenacolor) ~= "table" then     error("Tried to set the value of the variable arenacolor with a " .. type(arenacolor) .. ", but this variable must be a table with 3 numbers.\narenacolor must contain three numbers which are the color of the arena in the next wave.")
    elseif type(arenacolor[1]) ~= "number" then error("The first value of the table arenacolor must be a number, but it is a " .. type(arenacolor[1]) .. ".\narenacolor must contain three numbers which are the color of the arena in the next wave.")
    elseif type(arenacolor[2]) ~= "number" then error("The second value of the table arenacolor must be a number, but it is a " .. type(arenacolor[2]) .. ".\narenacolor must contain three numbers which are the color of the arena in the next wave.")
    elseif type(arenacolor[3]) ~= "number" then error("The third value of the table arenacolor must be a number, but it is a " .. type(arenacolor[3]) .. ".\narenacolor must contain three numbers which are the color of the arena in the next wave.")
    end

    local playerCount = 0
    if type(players) ~= "table" then error("The encounter must have a variable named players as a table, but it is a " .. type(players) .. ".\nplayers must contain as many strings as Players you want in this encounter. Those strings must match the namme of the scripts in the folder Lua/Players.")
    else
        playerCount = #players
        for i = 1, #players do
            if type(players[i]) ~= "string" then error("The value #" .. i .. " of the table players must be a string, but it is a " .. type(players[i]) .. ".\nplayers must contain as many strings as Players you want in this encounter. Those strings must match the namme of the scripts in the folder Lua/Players.") end
        end
    end

    if type(playerpositions) ~= "table" then   error("The encounter must have a variable named playerpositions as a table, but it is a " .. type(playerpositions) .. ".\nplayerpositions must contain as many tables containing two integers as Players you want in this encounter. Those integers are the position of the bottom left corner of the Players.")
    elseif #playerpositions < playerCount then error("The playerpositions variable must have at least the same amount of values as the players table.\nplayerpositions must contain as many tables containing two integers as Players you want in this encounter. Those integers are the position of the bottom left corner of the Players.")
    else
        for i = 1, #playerpositions do
            if type(playerpositions[i]) ~= "table" then             error("The value #" .. i .. " of the table playerpositions must be a table, but it is a " .. type(playerpositions[i]) .. ".\nplayerpositions must contain as many tables containing two integers as Players you want in this encounter. Those integers are the position of the bottom left corner of the Players.")
            else
                if type(playerpositions[i][1]) ~= "number" then     error("The first value of the table #" .. i .. " of the table playerpositions must be a number, but it is a " .. type(playerpositions[i][1]) .. ".\nplayerpositions must contain as many tables containing two integers as Players you want in this encounter. Those integers are the position of the bottom left corner of the Players.")
                elseif type(playerpositions[i][2]) ~= "number" then error("The second value of the table #" .. i .. " of the table playerpositions must be a number, but it is a " .. type(playerpositions[i][1]) .. ".\nplayerpositions must contain as many tables containing two integers as Players you want in this encounter. Those integers are the position of the bottom left corner of the Players.")
                end
            end
        end
        if #playerpositions > playerCount and debug then DEBUG("playerpositions has more values than players. The extra values are ignored.") end
    end

    local enemyCount = 0
    if type(enemies) ~= "table" then error("The encounter must have a variable named enemies as a table, but it is a " .. type(enemies) .. ".\nenemies must contain as many strings as Enemies you want in this encounter. Those strings must match the namme of the scripts in the folder Lua/Enemies.")
    else
        enemyCount = #enemies
        for i = 1, #enemies do
            if type(enemies[i]) ~= "string" then error("The value #" .. i .. " of the table enemies must be a string, but it is a " .. type(enemies[i]) .. ".\nenemies must contain as many strings as Enemies you want in this encounter. Those strings must match the namme of the scripts in the folder Lua/Enemies.") end
        end
    end

    if type(enemypositions) ~= "table" then  error("The encounter must have a variable named enemypositions as a table, but it is a " .. type(enemypositions) .. ".\nenemypositions must contain as many tables containing two integers as Enemies you want in this encounter. Those integers are the position of the bottom left corner of the Enemies.")
    elseif #enemypositions < enemyCount then error("The enemypositions variable must have at least the same amount of values as the enemies table.\nenemypositions must contain as many tables containing two integers as Enemies you want in this encounter. Those integers are the position of the bottom left corner of the Enemies.")
    else
        for i = 1, #enemypositions do
            if type(enemypositions[i]) ~= "table" then             error("The value #" .. i .. " of the table enemypositions must be a table, but it is a " .. type(enemypositions[i]) .. ".\nenemypositions must contain as many tables containing two integers as Enemies you want in this encounter. Those integers are the position of the bottom left corner of the Enemies.")
            else
                if type(enemypositions[i][1]) ~= "number" then     error("The first value of the table #" .. i .. " of the table enemypositions must be a number, but it is a " .. type(enemypositions[i][1]) .. ".\nenemypositions must contain as many tables containing two integers as Enemies you want in this encounter. Those integers are the position of the bottom left corner of the Enemies.")
                elseif type(enemypositions[i][2]) ~= "number" then error("The second value of the table #" .. i .. " of the table enemypositions must be a number, but it is a " .. type(enemypositions[i][1]) .. ".\nenemypositions must contain as many tables containing two integers as Enemies you want in this encounter. Those integers are the position of the bottom left corner of the Enemies.")
                end
            end
        end
        if #enemypositions > enemyCount and debug then DEBUG("enemypositions has more values than enemies. The extra values are ignored.") end
    end

    if preloadAnimations ~= nil then
        if type(preloadAnimations) ~= "boolean" then error("The encounter must have a variable named preloadAnimations as a boolean, but it is a " .. type(preloadAnimations) .. ".\npreloadAnimations will trigger all of the entities' animations to lower the loading time of CYK during the battle at the cost of a higher loading time at the beginning of the encounter.") end
    end

    if fontCharUsedForPlayer == nil then
        if debug then DEBUG("fontCharUsedForPlayer not found. Setting to an empty table.") end
        fontCharUsedForPlayer = { }
    elseif type(fontCharUsedForPlayer) ~= "table" then error("The encounter must have a variable named fontCharUsedForPlayer as a table, but it is a " .. type(fontCharUsedForPlayer) .. ".\nfontCharUsedForPlayer tells the engine which character it should use if it wants to display the head of a Player in a text, like when trying to display acts requiring multiple Players.")
    else
        for k, v in pairs(fontCharUsedForPlayer) do
            if type(v) ~= "string" then error("The value " .. k .. " of the table fontCharUsedForPlayer must be a string, but it is a " .. type(v) .. ".\nfontCharUsedForPlayer tells the engine which character it should use if it wants to display the head of a Player in a text, like when trying to display acts requiring multiple Players.") end
        end
    end

    if background == nil then
        if debug then DEBUG("background was not found. Setting to true.") end
        background = true
    elseif type(background) ~= "boolean" then error("The encounter must have a variable named background as a boolean, but it is a " .. type(background) .. ".\nbackground tells the engine if it should display Deltarune's battle background or not. Set it to true to display the background, false otherwise.")
    end

    if backgroundfade == nil then
        if debug then DEBUG("backgroundfade was not found. Setting to true.") end
        backgroundfade = true
    elseif type(backgroundfade) ~= "boolean" then error("The encounter must have a variable named backgroundfade as a boolean, but it is a " .. type(backgroundfade) .. ".\nbackgroundfade tells the engine if it should fade the background out when the enemies talk and fade the background in when the wave ends.")
    end

    if chapter2 == nil then
        if debug then DEBUG("chapter2 was not found. Setting to false.") end
        chapter2=false
    elseif type(chapter2)~="boolean" then error("The encounter must have a variable named chapter2 as a boolean, but it is a "..type(chapter2)..". chapter2 tells the engine if it must use or not features from Deltarune Chapter 2 or not, such as the new Game Over or the new mercy system.")
    end


    if HandleItem == nil then if debug then    DEBUG("[WARN] Encounter: HandleItem() missing.") end
    elseif type(HandleItem) ~= "function" then error("The encounter can have a variable named HandleItem as a function, but it is a " .. type(HandleItem) .. ".")
    end

    if HandleSpare == nil then if debug then    DEBUG("[WARN] Encounter: HandleSpare() missing.") end
    elseif type(HandleSpare) ~= "function" then error("The encounter can have a variable named HandleSpare as a function, but it is a " .. type(HandleSpare) .. ".")
    end

    if EnemyDialogueStarting == nil then if debug then    DEBUG("[WARN] Encounter: EnemyDialogueStarting() missing.") end
    elseif type(EnemyDialogueStarting) ~= "function" then error("The encounter can have a variable named EnemyDialogueStarting as a function, but it is a " .. type(EnemyDialogueStarting) .. ".")
    end

    if EnemyDialogueEnding == nil then if debug then    DEBUG("[WARN] Encounter: EnemyDialogueEnding() missing.") end
    elseif type(EnemyDialogueEnding) ~= "function" then error("The encounter can have a variable named EnemyDialogueEnding as a function, but it is a " .. type(EnemyDialogueEnding) .. ".")
    end

    if DefenseEnding == nil then if debug then    DEBUG("[WARN] Encounter: DefenseEnding() missing.") end
    elseif type(DefenseEnding) ~= "function" then error("The encounter can have a variable named DefenseEnding as a function, but it is a " .. type(DefenseEnding) .. ".")
    end

    if EnteringState == nil then if debug then    DEBUG("[WARN] Encounter: EnteringState() missing.") end
    elseif type(EnteringState) ~= "function" then error("The encounter can have a variable named EnteringState as a function, but it is a " .. type(EnteringState) .. ".")
    end

    if EncounterStarting == nil then if debug then    DEBUG("[WARN] Encounter: EncounterStarting() missing.") end
    elseif type(EncounterStarting) ~= "function" then error("The encounter can have a variable named EncounterStarting as a function, but it is a " .. type(EncounterStarting) .. ".")
    end

    if Update == nil then if debug then    DEBUG("[WARN] Encounter: Update() missing.") end
    elseif type(Update) ~= "function" then error("The encounter can have a variable named Update as a function, but it is a " .. type(Update) .. ".")
    end
end

CYKDataChecker()

-- CYK contains actually no CYF enemy, so we don't want the enemies table entered by the modder to load CYF enemies instead
_enemies = enemies
enemies = { }