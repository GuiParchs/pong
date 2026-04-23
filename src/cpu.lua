local gameState = require 'src.GameState'

local cpu = {}

local MIN_SERVE_DELAY = 0.75
local MAX_SERVE_DELAY = 4

local MIN_REACTION_TIME = 0.05
local MAX_REACTION_TIME = 0.2

local MAX_TARGET_OFFSET = 10
local MOVE_MARGIN = 10

local ball
local paddle

local currentTask
local lastGameState
local timer = 0

local targetY

local function getRandomNumber(min, max)
    return math.random() * (max - min) + min
end

function cpu.setVariables(ballRef, paddleRef)
    ball = ballRef
    paddle = paddleRef
end

function cpu.handleGame(dt)
    -- Ignore states
    if gameState.state == 'start' or gameState.state == 'gameover' then
        currentTask = nil
        return
    end

    -- Reset task if game state changes
    if lastGameState ~= gameState.state then
        lastGameState = gameState.state
        currentTask = nil
    end

    -- Update timer
    timer = timer - dt

    -- Serve state
    if gameState.state == 'serve' then

        if not currentTask then
            -- Start serve countdown
            if gameState.servingPlayer == 2 then
                currentTask = 'serve'
                timer = getRandomNumber(MIN_SERVE_DELAY, MAX_SERVE_DELAY)
            else
                currentTask = 'waiting_serve' -- or wait for player to serve
            end
        
        -- Serve when timer is up
        elseif currentTask == 'serve' and timer <= 0 then
            ball:serve(2)
            gameState.state = 'playing'
            currentTask = nil -- reset task
        end

    -- Playing state
    elseif gameState.state == 'playing' then
        if currentTask ~= 'updating' then
            currentTask = 'updating'
            timer = MIN_REACTION_TIME
        end

        if timer <= 0 then
            targetY = ball.y + ball.size / 2 + getRandomNumber(-MAX_TARGET_OFFSET, MAX_TARGET_OFFSET)
            timer = getRandomNumber(MIN_REACTION_TIME, MAX_REACTION_TIME)
        end

        -- Move paddle
        if targetY then
            cpu.move()
        end
    end
end

function cpu.move()
    local paddleCenter = paddle.y + paddle.height / 2 -- CPU position

    if targetY < paddleCenter - MOVE_MARGIN then
        paddle:move(-1) -- Move up
    elseif targetY > paddleCenter + MOVE_MARGIN then
        paddle:move(1) -- Move down
    else
        paddle:move(0) -- Stop
    end
end

return cpu