local push = require 'lib.push'

local Ball = require 'src.Ball'
local Paddle = require 'src.Paddle'

local gameState = require 'src.GameState'
local ui = require 'src.ui'

VIRTUAL_WIDTH = 320
VIRTUAL_HEIGHT = 240

WINDOW_WIDTH = 1024
WINDOW_HEIGHT = 768

local BG_COLOR = {40/255, 45/255, 52/255, 1}


local paddle1, paddle2
local ball

local showFps = false


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

    ui.loadFonts()

    local W_OFFSET = 8
    local H_OFFSET = 10

    paddle1 = Paddle(W_OFFSET, H_OFFSET)
    paddle2 = Paddle(VIRTUAL_WIDTH - W_OFFSET - Paddle.width, VIRTUAL_HEIGHT - H_OFFSET - Paddle.height)

    local BALL_OFFSET = Ball.size / 2
    ball = Ball(VIRTUAL_WIDTH / 2 - BALL_OFFSET, VIRTUAL_HEIGHT / 2 - BALL_OFFSET)
end

function love.update(dt)
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
end

function love.keypressed(key)
    -- Global keys
    if key == 'escape' then
        love.event.quit()
    elseif key == 'f' or key == 'f11' then
        push:switchFullscreen()
    elseif key == 'f1' then
        showFps = not showFps
    end

    -- GameState logic

    -- Start
    if gameState.state == 'start' then
        if key == 'return' or key == 'kpenter' then
            gameState.state = 'serve'
            gameState.servingPlayer = math.random(2)
        end


    -- Serve
    elseif gameState.state == 'serve' then
        if gameState.servingPlayer == 1 and (key == 'return' or key == 'kpenter') or
           gameState.servingPlayer == 2 and key == 'space' then
            gameState.state = 'playing'
        end
    end
end

function love.draw()
    push:start()

    love.graphics.clear(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], BG_COLOR[4])

    if gameState.state == 'start' then
        ui.drawStartText()
    else
        ui.drawScore(gameState.score[1], gameState.score[2])
    end

    if gameState.state == 'serve' then
        ui.drawServeText(gameState.servingPlayer)

    elseif gameState.state == 'playing' then
        ui.drawCenterNet(12, 6)
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