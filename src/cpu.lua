local gameState = require 'src.gameState'

local cpu = {}

local MIN_SERVE_DELAY = 0.9
local MAX_SERVE_DELAY = 4.5
local SERVE_DELAY_SHITF = 0.8 -- decreases serve delay the more points P1 has

local TAUNT_SPEED = 20
local TAUNT_RANGE = 15

local MIN_REACTION_TIME = 0.01
local MAX_REACTION_TIME = 0.17

local MAX_TARGET_OFFSET = 6
local MOVE_MARGIN = 16
local LEAD_TIME = 0.085 -- foresees the y position

local ball
local paddle

local currentTask
local lastGameState
local moveTimer = 0
local taskTimer = 0

local targetY

local function getRandomNumber(min, max, serveRelated)
    if serveRelated then
        local shift = gameState.score[1] * SERVE_DELAY_SHITF
        max = max - shift

        if min < 0 then
            shift = -shift
        end
        min = min - shift / 5
    end

    if max < min then min = max end

    return love.math.random() * (max - min) + min
end

local function taunt(speedIncrease)
    local oscillation = math.sin(love.timer.getTime() * TAUNT_SPEED * (1 + speedIncrease)) * TAUNT_RANGE
    targetY = GAME_HEIGHT / 2 + oscillation + getRandomNumber(-MAX_TARGET_OFFSET, MAX_TARGET_OFFSET)
end

function cpu.setVariables(ballRef, paddleRef)
    ball = ballRef
    paddle = paddleRef
end

function cpu.reset()
    if not paddle then return end
    
    currentTask = nil
    paddle:move(0)
    targetY = nil
end

function cpu.handleGame(dt)
    -- Reset task if game state changes
    if lastGameState ~= gameState.state then
        lastGameState = gameState.state
        cpu.reset()
    end

    -- Update timers
    taskTimer = taskTimer - dt
    moveTimer = moveTimer - dt

    -- Serve state
    if gameState.state == 'serve' then
        if not currentTask then
            -- Start serve countdown
            if gameState.servingPlayer == 2 then
                currentTask = 'serve'
                taskTimer = getRandomNumber(MIN_SERVE_DELAY, MAX_SERVE_DELAY, true)
            else
                currentTask = 'waiting_serve' -- or wait for player to serve
            end
        
        -- Serve when timer is up
        elseif currentTask == 'serve' and taskTimer <= 0 then
            ball:serve(2)
            gameState.state = 'playing'
            currentTask = nil -- reset task
        end

        -- TAUNT
        if currentTask == 'waiting_serve' or currentTask == 'serve' then
            taunt(gameState.score[1] / 5)
        end

    -- Playing state
    elseif gameState.state == 'playing' then
        if currentTask ~= 'updating' then
            currentTask = 'updating'
            taskTimer = MIN_REACTION_TIME
        end

        if taskTimer <= 0 then
            targetY = ball.y + (ball.dy * LEAD_TIME) + ball.size / 2 + getRandomNumber(-MAX_TARGET_OFFSET, MAX_TARGET_OFFSET)
            taskTimer = getRandomNumber(MIN_REACTION_TIME, MAX_REACTION_TIME)
        end
    
    -- Game over state
    elseif gameState.state == 'gameover' then
        if gameState.score[2] == 5 then
            taunt(5)
        else
            paddle:move(1)
        end
    end

    -- Move paddle
    if targetY then
        if moveTimer > 0 then return end

        cpu.move()

        moveTimer = getRandomNumber(MIN_REACTION_TIME, MAX_REACTION_TIME)
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