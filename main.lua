local Ball = require 'src.Ball'
local Paddle = require 'src.Paddle'

local cpu = require 'src.cpu'
local gameState = require 'src.gameState'
local shader = require 'src.shader'
local sounds = require 'src.sounds'
local ui = require 'src.ui'

GAME_WIDTH = 320
GAME_HEIGHT = 240

Debug = false
EnableCRT = true


local BG_COLOR = {40/255, 45/255, 52/255}

local scale, offsetX, offsetY
local scaledW, scaledH
local gameCanvas

local paddle1, paddle2
local ball

local showFps = false
local isQuitting = false
local quitTimer = nil

local function updateResolution(winW, winH)
    winW, winH = math.max(winW, 1), math.max(winH, 1)
    
    -- Maximum scale that fits window
    scale = math.min(winW / GAME_WIDTH, winH / GAME_HEIGHT)
    
    -- Pixel perfect
    scale = math.max(1, math.floor(scale)) 
    
    -- Scaled resolution
    scaledW = GAME_WIDTH * scale
    scaledH = GAME_HEIGHT * scale
    
    -- 4:3 margin
    offsetX = math.floor((winW - scaledW) / 2)
    offsetY = math.floor((winH - scaledH) / 2)
    
    -- Resize moonshine effect
    if EnableCRT then
        shader.resize(winW, winH)
    end
end

local function switchFullscreen()
    love.window.setFullscreen(not love.window.getFullscreen(), 'desktop')
    updateResolution(love.graphics.getDimensions())
end

local function switchShaders()
    if not shader.get() then
        shader.load()
    end

    EnableCRT = not EnableCRT

    shader.resize(love.graphics.getDimensions())
    sounds.setFilter(EnableCRT)
end

function love.load()
    -- set window title
    love.window.setTitle('PONG')

    -- Gamve canvas (low-res)
    gameCanvas = love.graphics.newCanvas(GAME_WIDTH, GAME_HEIGHT)
    gameCanvas:setFilter("nearest", "nearest") -- no filtering

    -- Create paddles
    local paddleW = 8
    local paddleH = 10
    
    paddle1 = Paddle(paddleW, paddleH)
    paddle2 = Paddle(GAME_WIDTH - paddleW - Paddle.width, GAME_HEIGHT - paddleH - Paddle.height)
    
    -- Create ball
    ball = Ball()
    ball:reset()
    
    -- Load resources
    ui.loadFonts()
    sounds.load()

    -- CRT shader effect
    if EnableCRT then
        shader.load()
        sounds.setFilter(true)
    end

    -- Update resolution
    switchFullscreen()
    --updateResolution(love.graphics.getDimensions())
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
        cpu.reset()
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
        if gameState.state == 'start' then
            isQuitting = true
            quitTimer = 0.25
        else
            gameState.state = 'start'
            gameState.score = {0, 0}
            ball:reset()
        end

        sounds.play('select')
    elseif key == 'f' or key == 'f11' then
        switchFullscreen()
        sounds.play('select')
    elseif key == 'f1' then
        showFps = not showFps
        sounds.play('select')
    elseif key == 'f2' then
        switchShaders()
        sounds.play('select')
    elseif key == 'f3' then
        Debug = not Debug
        sounds.play('select')
    end

    -- GameState logic
    -- Start
    if gameState.state == 'start' then
        if key == 'w' or key == 'up' or key == 's' or key == 'down' then
            gameState.mode = gameState.mode == 'pvp' and 'mvm' or 'pvp'
            sounds.play('select')

        elseif key == 'return' or key == 'kpenter' then
            if gameState.mode == 'mvm' then
                cpu.setVariables(ball, paddle2)
            end

            gameState.state = 'serve'
            gameState.servingPlayer = love.math.random(2)
            sounds.play('select')
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
            sounds.play('select')
        end
    end
end

local function drawGameFrame()
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
end

local function drawGameCanvas()
    love.graphics.draw(
        gameCanvas,
        offsetX, -- horizontal margin
        offsetY, -- vertical margin
        0,
        scale,
        scale
    )
end

function love.draw()
    -- set low-res canvas
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear()
    
    -- draw game
    drawGameFrame()
    
    love.graphics.setCanvas() -- start drawing to screen

    -- Apply shader
    if EnableCRT then
        shader.get()(function()
            drawGameCanvas()
        end)
    else
        drawGameCanvas()
    end
end

function love.resize(winW, winH)
    updateResolution(winW, winH)
end