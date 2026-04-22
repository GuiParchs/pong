local push = require 'lib.push'

local Ball = require 'src.Ball'
local Paddle = require 'src.Paddle'

local gameState = require 'src.GameState'
local sounds = require 'src.sounds'
local ui = require 'src.ui'

VIRTUAL_WIDTH = 320
VIRTUAL_HEIGHT = 240

WINDOW_WIDTH = 1024
WINDOW_HEIGHT = 768

local BG_COLOR = {40/255, 45/255, 52/255, 1}


local paddle1, paddle2
local ball

local showFps = false
local isQuitting = false
local quitTimer = nil

function love.load()
    love.window.setTitle('PONG')
    
    love.graphics.setDefaultFilter('nearest', 'nearest')

    math.randomseed(os.time())

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
    
    ui.loadFonts()
    sounds.load()
end

function love.update(dt)
    if isQuitting then
        quitTimer = quitTimer - dt

        if quitTimer <= 0 then
            return love.event.quit()
        end
    end

    -- Player 1
    if love.keyboard.isDown('w') then
        paddle1.dy = -Paddle.speed
    elseif love.keyboard.isDown('s') then
        paddle1.dy = Paddle.speed
    else
        paddle1.dy = 0
    end

    -- Player 2
    if love.keyboard.isDown('up') then
        paddle2.dy = -Paddle.speed
    elseif love.keyboard.isDown('down') then
        paddle2.dy = Paddle.speed
    else
        paddle2.dy = 0
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

        if gameState.score[scorePlayer] == 3 and gameState.score[opposingPlayer] == 4 then
            gameState.score[opposingPlayer] = 3
        else
            gameState.score[scorePlayer] = gameState.score[scorePlayer] + 1
        end


        gameState.state = 'serve'
        gameState.servingPlayer = opposingPlayer
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
    end

    -- GameState logic
    -- Start
    if gameState.state == 'start' then
        if key == 'return' or key == 'kpenter' then
            gameState.state = 'serve'
            gameState.servingPlayer = math.random(2)
            sounds.select:play()
        end


    -- Serve
    elseif gameState.state == 'serve' then

        if gameState.servingPlayer == 1 and (key == 'return' or key == 'kpenter') or
           gameState.servingPlayer == 2 and key == 'space' then

            gameState.state = 'playing'
            ball:serve(gameState.servingPlayer)
        end
    end
end

function love.draw()
    push:start()

    love.graphics.clear(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], BG_COLOR[4])

    if gameState.state == 'start' then
        ui.drawStartText()
    else
        ui.drawCenterNet(12, 6)
        ui.drawScoreBoard(gameState.score[1], gameState.score[2])
    end

    if gameState.state == 'serve' then
        ui.drawServeText(gameState.servingPlayer)
    end


    paddle1:render()
    paddle2:render()

    ball:render()

    if showFps then
        ui.drawFPS()
    end

    push:finish()
end

function love.resize(w, h)
    push:resize(w, h)
end