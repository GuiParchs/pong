local push = require 'lib.push'

local Ball = require 'src.Ball'
local Paddle = require 'src.Paddle'

local cpu = require 'src.cpu'
local gameState = require 'src.GameState'
local sounds = require 'src.sounds'
local ui = require 'src.ui'

VIRTUAL_WIDTH = 320
VIRTUAL_HEIGHT = 240

WINDOW_WIDTH = 1024
WINDOW_HEIGHT = 768

local BG_COLOR = {40/255, 45/255, 52/255}

Debug = false


local paddle1, paddle2
local ball

local showFps = false
local isQuitting = false
local quitTimer = nil

function love.load()
    love.window.setTitle('PONG')
    
    love.graphics.setDefaultFilter('nearest', 'nearest')
    
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true,
        pixelperfect = true
    })

    local W_OFFSET = 8
    local H_OFFSET = 10
    
    paddle1 = Paddle(W_OFFSET, H_OFFSET)
    paddle2 = Paddle(VIRTUAL_WIDTH - W_OFFSET - Paddle.width, VIRTUAL_HEIGHT - H_OFFSET - Paddle.height)
    
    local BALL_OFFSET = Ball.size / 2
    ball = Ball(VIRTUAL_WIDTH / 2 - BALL_OFFSET, VIRTUAL_HEIGHT / 2 - BALL_OFFSET)

    math.randomseed(os.time())
    
    ui.loadFonts()
    sounds.load()
end

local function handlePaddleInput(paddle, upKeys, downKeys)
    local upPressed = false
    local downPressed = false

    for i = 1, #upKeys do
        if love.keyboard.isDown(upKeys[i]) then
            upPressed = true
            break
        end

        if love.keyboard.isDown(downKeys[i]) then
            downPressed = true
            break
        end
    end

    if upPressed and downPressed then
        paddle:move(0)
    elseif upPressed then
        paddle:move(-1)
    elseif downPressed then
        paddle:move(1)
    else
        paddle:move(0)
    end
end

function love.update(dt)
    if isQuitting then
        quitTimer = quitTimer - dt

        if quitTimer <= 0 then
            return love.event.quit()
        end
    end

    if gameState.state == 'start' then
        return
    end

    -- Gameplay

    if gameState.mode == 'pvp' then
        -- Player 1
        handlePaddleInput(paddle1, {'w'}, {'s'})

        -- Player 2
        handlePaddleInput(paddle2, {'up'}, {'down'})

    else
        -- Player 1
        handlePaddleInput(paddle1, {'w', 'up'}, {'s', 'down'})

        -- CPU
        cpu.handleGame(dt)
    end

    paddle1:update(dt)
    paddle2:update(dt)

    if ball:collides(paddle1) then
        ball.x = paddle1.x + Paddle.width

    elseif ball:collides(paddle2) then
        ball.x = paddle2.x - Ball.size
    end

    local scorePlayer = ball:update(dt)

    if scorePlayer then
        local opposingPlayer = scorePlayer == 1 and 2 or 1

        if gameState.score[scorePlayer] == 3 and gameState.score[opposingPlayer] < 3 then
            gameState.score[scorePlayer] = 5 -- win
        elseif gameState.score[scorePlayer] == 3 and gameState.score[opposingPlayer] == 4 then
            gameState.score[opposingPlayer] = 3
        else
            gameState.score[scorePlayer] = gameState.score[scorePlayer] + 1
        end

        if gameState.score[scorePlayer] == 5 then
            gameState.state = 'gameover'
        else
            gameState.state = 'serve'
            gameState.servingPlayer = opposingPlayer
        end
    end
end

function love.keypressed(key)
    -- Global keys
    if key == 'escape' then
        isQuitting = true
        quitTimer = 0.25
        sounds.goal:play()
    elseif key == 'f' or key == 'f11' then
        push:switchFullscreen()
        sounds.select:play()
    elseif key == 'f1' then
        showFps = not showFps
        sounds.select:play()
    elseif key == 'f2' then
        Debug = not Debug
        sounds.select:play()
    end

    -- GameState logic
    -- Start
    if gameState.state == 'start' then
        if key == 'w' or key == 'up' or key == 's' or key == 'down' then
            gameState.mode = gameState.mode == 'pvp' and 'mvm' or 'pvp'
            sounds.select:play()

        elseif key == 'return' or key == 'kpenter' then
            if gameState.mode == 'mvm' then
                cpu.setVariables(ball, paddle2)
            end

            gameState.state = 'serve'
            gameState.servingPlayer = math.random(2)
            sounds.select:play()
        end


    -- Serve
    elseif gameState.state == 'serve' then

        if (key == 'return' or key == 'kpenter') and gameState.servingPlayer == 1 or
           key == 'space' and gameState.servingPlayer == 2 and gameState.mode == 'pvp' then

            gameState.state = 'playing'
            ball:serve(gameState.servingPlayer)
        end
    
    elseif gameState.state == 'playing' then
        if key == '0' then
            gameState.state = 'serve'
            ball:reset()
        end


    --GameOver
    elseif gameState.state == 'gameover' then
        if key == 'return' or key == 'kpenter' then
            gameState.state = 'start'
            gameState.score = {0, 0}
            sounds.select:play()
        end
    end
end

function love.draw()
    push:start()

    love.graphics.clear(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3])

    if gameState.state == 'start' then
        ui.drawStartText()
        ui.drawStartOptions(gameState.mode)
    else
        ui.drawCenterNet(12, 6)
        ui.drawScoreBoard(gameState.score[1], gameState.score[2])
    end

    if gameState.state == 'serve' then
        ui.drawServeText(gameState.servingPlayer, gameState.mode)
        ui.drawGameInfo(gameState.score[1], gameState.score[2])

    elseif gameState.state == 'gameover' then
        ui.drawGameOverText(gameState.score[1], gameState.score[2])
    end


    paddle1:render()
    paddle2:render()

    ball:render()

    if showFps then
        ui.drawFPS()
    end

    if Debug then
        ui.drawDebug(ball)
    end

    push:finish()
end

function love.resize(w, h)
    push:resize(w, h)
end