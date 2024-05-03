-- Initializing global variables
LatestGameState = nil
-- Game = Grid 1 - Bikini Bottom
Game = "7FoscACQw6exmtKGI87sVI4ls_klNIwuPRoHxpHSdOg"
--or
-- Grid 2 - The Matrix
-- Game = "y2SumslSgziUYIUYYlGXAXPcxLXexIkbaxxsNa9_VXg"
--or
-- Grid 3 - Mario World
-- Game = "oPre75iYJzWPiNkk_7B6QwmDPBSJIn9Rqrvil1Gho7U"
CRED = "Sa0iBLPNyJQrwpTTG-tWLQU-1QeUAJA73DdxGGiKoJc"
Counter = 0

colors = {
    red = "\27[31m",
    green = "\27[32m",
    blue = "\27[34m",
    reset = "\27[0m",
    gray = "\27[90m"
}

-- Distance calculation function
function distance(x1, y1, x2, y2)
    return math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
end

-- Decides the next action based on player proximity, energy, and random factors
function decideNextAction()
    local player = LatestGameState.Players[ao.id]
    local lowEnergyThreshold = 20
    local randomAttackChance = 0.3
    local attackRange = 3
    local retreatRange = 5

    -- Check if any player is within attack range
    local targetInRange = false
    for target, state in pairs(LatestGameState.Players) do
        if target ~= ao.id and distance(player.x, player.y, state.x, state.y) <= attackRange then
            targetInRange = true
            break
        end
    end

    -- Check if any player is within retreat range
    local playerNearby = false
    for target, state in pairs(LatestGameState.Players) do
        if target ~= ao.id and distance(player.x, player.y, state.x, state.y) <= retreatRange then
            playerNearby = true
            break
        end
    end

    -- Decide the action based on conditions
    if player.energy > 15 and (targetInRange or math.random() < randomAttackChance) then
        print(colors.red .. "Engaging target. Launching offensive attack!" .. colors.reset)
        ao.send({ Target = Game, Action = "PlayerAttack", AttackEnergy = tostring(player.energy) })
    elseif player.energy <= lowEnergyThreshold and playerNearby then
        print(colors.blue .. "Low energy detected. Retreating to a safe distance." .. colors.reset)
        local bestDirection = findSafeDirection(player.x, player.y)
        if bestDirection then
            ao.send({ Target = Game, Action = "PlayerMove", Direction = bestDirection })
        else
            print(colors.red .. "Unable to find a safe retreat path. Holding position." .. colors.reset)
        end
    else
        print(colors.gray .. "No immediate threats detected. Exploring the area." .. colors.reset)
        local directionMap = { "Up", "Down", "Left", "Right", "UpRight", "UpLeft", "DownRight", "DownLeft" }
        local randomIndex = math.random(#directionMap)
        ao.send({ Target = Game, Action = "PlayerMove", Direction = directionMap[randomIndex] })
    end
end

-- Finds the safest direction to move away from all players
function findSafeDirection(x, y)
    local bestDirection = nil
    local maxDistance = 0
    for _, direction in ipairs({ "Up", "Down", "Left", "Right", "UpRight", "UpLeft", "DownRight", "DownLeft" }) do
        local newX, newY = x, y
        if direction == "Up" then
            newY = newY - 1
        elseif direction == "Down" then
            newY = newY + 1
        elseif direction == "Left" then
            newX = newX - 1
        elseif direction == "Right" then
            newX = newX + 1
        elseif direction == "UpRight" then
            newX, newY = newX + 1, newY - 1
        elseif direction == "UpLeft" then
            newX, newY = newX - 1, newY - 1
        elseif direction == "DownRight" then
            newX, newY = newX + 1, newY + 1
        elseif direction == "DownLeft" then
            newX, newY = newX - 1, newY + 1
        end
        local minDistance = math.huge
        for _, targetState in pairs(LatestGameState.Players) do
            if targetState.id ~= ao.id then
                local dist = distance(newX, newY, targetState.x, targetState.y)
                minDistance = math.min(minDistance, dist)
            end
        end
        if minDistance > maxDistance then
            maxDistance = minDistance
            bestDirection = direction
        end
    end
    return bestDirection
end

-- Handler to print game announcements and trigger game state updates
Handlers.add(
    "PrintAnnouncements",
    Handlers.utils.hasMatchingTag("Action", "Announcement"),
    function(msg)
        ao.send({ Target = Game, Action = "GetGameState" })
        print(colors.green .. msg.Event .. ": " .. msg.Data .. colors.reset)
        print("Location: " .. "row: " .. LatestGameState.Players[ao.id].x .. ' col: ' .. LatestGameState.Players[ao.id]
            .y)
    end
)

-- Handler to trigger game state updates
Handlers.add(
    "GetGameStateOnTick",
    Handlers.utils.hasMatchingTag("Action", "Tick"),
    function()
        ao.send({ Target = Game, Action = "GetGameState" })
    end
)

-- Handler to update the game state upon receiving game state information
Handlers.add(
    "UpdateGameState",
    Handlers.utils.hasMatchingTag("Action", "GameState"),
    function(msg)
        local json = require("json")
        LatestGameState = json.decode(msg.Data)
        ao.send({ Target = ao.id, Action = "UpdatedGameState" })
        print("Location: " .. "row: " .. LatestGameState.Players[ao.id].x .. ' col: ' .. LatestGameState.Players[ao.id]
            .y)
    end
)

-- Handler to decide the next best action
Handlers.add(
    "decideNextAction",
    Handlers.utils.hasMatchingTag("Action", "UpdatedGameState"),
    function()
        decideNextAction()
        ao.send({ Target = ao.id, Action = "Tick" })
    end
)

Prompt = function() return Name .. "> " end
