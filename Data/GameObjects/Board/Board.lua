local BOARD_WIDTH = 10
local BOARD_HEIGHT = 22
local TILE_SIZE = 32
local FALLING_TIME = 0.5 --seconds
local SPAWN_BLOCK_TIME = 0.25
local DISSAPEAR_BLOCK_TIME = 0.1
local DISSAPEAR_BLOCK_COUNT = 5
--[[
    Board states:
        stop: nothing happens
        falling_state: blocks are currently fallings
        completed_line_state: a line is completed
        game_over_state: u r 2 bad m8
]]
local boardState = {
    currentState = "stop"
}
local prev_state = 0
-- Handler to 'Game' GameObject
local game
-- Showed/Not showed completed lines (for animation purpose)
local completed_lines_showed = true
-- Tables of landed and falling blocks
local landed = {}
local falling = {}
-- Timers
local fall_timer
local disappear_timer
-- Counters
local disappear_counter
-- Table of completed lines
local completed_lines = {}

function Local.Init(pos)
    game = Scene:getGameObject("game")
    InitializeBindings()
    print("Board instancied")
    print("Board pos x, y: ", pos.x, pos.y)
    This:getSceneNode():setPosition(obe.UnitVector(pos.x, pos.y, obe.Units.SceneUnits));
    -- Initiate tables of landed and falling blocks
    for i = 1,BOARD_WIDTH do
        landed[i] = {}
        falling[i] = {}
        for j = 1,BOARD_HEIGHT do
            landed[i][j] = 0
            falling[i][j] = 0
        end
    end

    fall_timer = FALLING_TIME
    disappear_counter = DISSAPEAR_BLOCK_COUNT
    disappear_timer = DISSAPEAR_BLOCK_TIME

    --TEST FOR DEBUGGING
    for i = 1, 9 do
        Object:add_block(landed, i, 22)
        Object:add_block(landed, i, 21)
        Object:add_block(landed, i, 19)
    end
    for i = 1, 8 do
        Object:add_block(landed, i, 20)
    end
    --Object:add_block(falling, 10, 1, obe.Color(255, 0, 255))
    Object:add_block(falling, 10, 1, obe.Color(255, 0, 255))
    Object:add_block(falling, 10, 2, obe.Color(255, 0, 255))
    Object:add_block(falling, 10, 3, obe.Color(255, 0, 255))
    Object:add_block(falling, 10, 4, obe.Color(255, 0, 255))
    move_blocks(-1, 0, true)
    move_blocks(-1, 0, true)
    move_blocks(1, 0, true)
end

function InitializeBindings()
    --Global.Actions.UP_PRESSED = rotate_blocks()
    Global.Actions.LEFT_PRESSED = function()
        if boardState.currentState == "falling_state" then
            move_blocks(-1, 0, true)
        end
    end
    Global.Actions.RIGHT_PRESSED = function()
        if boardState.currentState == "falling_state" then
            move_blocks(1, 0, true)
        end
    end
    Global.Actions.DOWN_PRESSED = function()
        if boardState.currentState == "falling_state" then
            move_blocks(0, 1, true)
        end
    end

end

-- Change board state
function Object:setState(state)
    boardState.currentState = state
    print("Changed state to ", state)
end

-- Return board position
function get_pos()
    return This:getSceneNode():getPosition():to(obe.Units.ScenePixels)
end

-- Create and add landed block to board
function Object:add_block(boardTable, boardX, boardY, color)
    boardX = boardX or 0
    boardY = boardY or 0
    local blockPos = {}
    blockPos = get_pos() + obe.UnitVector((boardX-1)*TILE_SIZE, (boardY-1)*TILE_SIZE, obe.Units.ScenePixels)
    local newBlock = Scene:createGameObject("Block")({
        pos = {x=blockPos.x, y=blockPos.y},
        color = color
    })
    boardTable[boardX][boardY] = newBlock
end

-- Move falling blocks to specified direction
function move_blocks(dirX, dirY, safe)
    if safe == true then
        if not can_move(dirX, dirY) then return end
    end
    local i, j, stepi, stepj, desti, destj = 1, BOARD_HEIGHT, 1, -1, BOARD_WIDTH, 1
    if dirX > 0 then i, desti, stepi = BOARD_WIDTH, 1, -1 end
    if dirY < 0 then j, destj, stepj = 1, BOARD_HEIGHT, 1 end
    for i = i, desti, stepi do
        for j = j, destj, stepj do
            -- If falling block found
            if falling[i][j] ~= 0 then
                move_block(i, j, dirX, dirY, falling, falling)
            end
        end
    end
end

-- Move block at blockX;blockY coordinates to dirX+dirY direction
-- blockarray: pointer to array of blocks ("falling" or "landed" blocks)
-- destArray: pointer to destination array
function move_block(blockX, blockY, dirX, dirY, blockarray, destArray)
    local block = blockarray[blockX][blockY]
    if block ~= 0 then
        destArray[blockX + dirX][blockY + dirY] = block
        blockarray[blockX][blockY] = 0
        newBlockPos = get_pos() + obe.UnitVector((blockX-1+dirX)*TILE_SIZE, (blockY-1+dirY)*TILE_SIZE, obe.Units.ScenePixels)
        block:setPosition(newBlockPos)
    end
end

-- Remove block at blockX;blockY coordinates
function remove_block(blockX, blockY, blockarray)
    local block = blockarray[blockX][blockY]
    if block ~= 0 then
        block:deleteObject()
        blockarray[blockX][blockY] = 0
    end
end

-- Check if falling blocks can fall
function can_fall()
    return can_move(0, 1)
end

-- Return if falling blocks can move to specified direction
function can_move(dirX, dirY)
    for i = 1,BOARD_WIDTH do
        for j = 1,BOARD_HEIGHT do
            -- If falling block found
            if falling[i][j] ~= 0 then
                -- If no landed block and not touching board limit
                -- Check if destination is not outside of board
                if j+dirY > BOARD_HEIGHT or 
                j+dirY <= 0 or 
                i+dirX > BOARD_WIDTH or
                i+dirX <= 0 then
                    return false
                end
                -- Check if there is no landed block on destination
                if landed[i+dirX][j+dirY] ~= 0 then return false end
            end
        end
    end
    return true           
end

-- Make blocks falling
function fall_blocks()
    move_blocks(0, 1, false)
end

-- Check if there's completed lines
function check_completed_lines()
    completed_lines = {}
    local line_complete
    for j = 1, BOARD_HEIGHT do
        line_complete = true
        for i = 1, BOARD_WIDTH do
            -- If missing block in this line
            if landed[i][j] == 0 then
                line_complete = false
            end
        end
        -- If line complete, add line number to completed lines table
        if line_complete then
            table.insert(completed_lines, j)
        end
    end
    -- If there's at least one completed line, go to "completed line" state
    if next(completed_lines) ~= nil then
        disappear_timer = 0
        disappear_counter = DISSAPEAR_BLOCK_COUNT
        print("Lines completed:", inspect(completed_lines))
        Object:setState("completed_line_state")
    else -- Else spawn new blocks
        if spawn_blocks() then
            Object:setState("falling_state")
        else
            Object:setState("stop")
            print("GAME OVER !!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        end
    end
end

-- Put falling blocks to landed blocks
function fall_to_land()
    for i = 1,BOARD_WIDTH do
        for j = 1,BOARD_HEIGHT do
            if falling[i][j] ~=0 then
                landed[i][j] = falling[i][j]
                falling[i][j] = 0
            end
        end
    end
end

-- Fall remaining blocks after lines dissapeared
function fall_after_completed_lines()
    for l = 1, #completed_lines do
        for j = completed_lines[l]-1, 1, -1 do
            for i = 1, BOARD_WIDTH do
                move_block(i, j, 0, 1, landed, landed)
            end
        end
    end
    completed_lines = {}
end

-- Spawn blocks at the top of the board
-- If can't spawn, return false
function spawn_blocks()
    -- TEST
    local blocksColor = obe.Color(255, 255, 0)
    local toSpawn = {}
    toSpawn[1] = {0+math.floor(BOARD_WIDTH/2), 1+math.floor(BOARD_WIDTH/2)}
    toSpawn[2] = {1+math.floor(BOARD_WIDTH/2)}
    toSpawn[3] = {1+math.floor(BOARD_WIDTH/2)}
    --
    -- Verify if blocks can spawn
    for j = 1, #toSpawn do
        for i = 1, #toSpawn[j] do
            if landed[i][j] ~= 0 then return false end
        end
    end
    for j = 1, #toSpawn do
        for i = 1, #toSpawn[j] do
            Object:add_block(falling, toSpawn[j][i], j, blocksColor)
        end
    end
    return true
end

--[[ 
    State functions
--]]

-- Blocks are currently falling
function boardState.falling_state(dt)
    fall_timer = fall_timer - dt
    if fall_timer <= 0 then
        if can_fall() then
            fall_blocks()
        else
            Object:setState("stop")
            fall_to_land()
            check_completed_lines()
        end
        fall_timer = FALLING_TIME
    end
end

-- Completed lines dissapearing state (just animation)
function boardState.completed_line_state(dt)
    disappear_timer = disappear_timer - dt
    if disappear_timer < 0 then
        if completed_lines_showed then
            completed_lines_showed = false
            disappear_counter = disappear_counter - 1
        else
            completed_lines_showed = true
        end
        for l = 1, #completed_lines do
            for i = 1, BOARD_WIDTH do
                landed[i][completed_lines[l]]:show(completed_lines_showed)
            end
        end
        if disappear_counter <= 0 then
            Object:setState("stop")
            for j = 1, #completed_lines do
                for k = 1, BOARD_WIDTH do
                    remove_block(k, completed_lines[j], landed)
                end
                print("Removed line", completed_lines[j])
            end
            game:Scored(#completed_lines)
            fall_after_completed_lines()
            if spawn_blocks() then
                Object:setState("falling_state")
            else
                Object:setState("stop")
                print("GAME OVER !")
            end
        end
        disappear_timer = DISSAPEAR_BLOCK_TIME
    end
end

--
function game_over_state()
end

-- Nothing happens
function boardState.stop(dt)
end

--[[ 
    Update function
--]]
function Global.Game.Update(dt)
    if boardState.currentState then
        boardState[boardState.currentState](dt)
    end
end