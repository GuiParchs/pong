local gameState = require 'src.GameState'

local ui = {}

local smallFont, mediumFont

local lastMult = 0

local scoresDisplay = {
    [0] = 'LÖVE',
    [1] = '15',
    [2] = '30',
    [3] = '40',
    [4] = 'ADV',
    [5] = 'GAME'
}

local function getPlayerDisplayName(player)
    if player == 1 then
        return 'P1'
    elseif gameState.mode == 'pvp' then
        return 'P2'
    else
        return 'CPU'
    end
end

local function setColor(color)
    if color == 'black' then
        love.graphics.setColor(0, 0, 0, 1)
    elseif color == 'green' then
        love.graphics.setColor(0, 1, 0, 1)
    elseif color == 'gray' then
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function ui.loadFonts()
    smallFont = love.graphics.newFont('assets/font.ttf', 8)
    mediumFont = love.graphics.newFont('assets/font.ttf', 16)
end

function ui.drawStartText()
    love.graphics.setFont(smallFont)
    love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('Press Enter to start', 0, 20, VIRTUAL_WIDTH, 'center')
end

function ui.drawStartOptions(gameMode)
    local rectW = 140
    local rectH = 15
    local centerX = VIRTUAL_WIDTH / 2 - rectW / 2
    local baseY = VIRTUAL_HEIGHT - 60

    local isPvp = gameMode == 'pvp'
    
    love.graphics.setFont(smallFont)
    local fontHeightOffset = smallFont:getHeight() / 2

    love.graphics.rectangle(isPvp and 'fill' or 'line', centerX, baseY, rectW, rectH)
    setColor(isPvp and 'black' or nil)
    love.graphics.printf('Player vs Player', 0, baseY + fontHeightOffset, VIRTUAL_WIDTH, 'center')

    baseY = baseY + rectH + 10

    setColor()

    love.graphics.rectangle(isPvp and 'line' or 'fill', centerX, baseY, rectW, rectH)
    setColor(isPvp and 'white' or 'black')
    love.graphics.printf('Man vs Machine', 0, baseY + fontHeightOffset, VIRTUAL_WIDTH, 'center')

    setColor()
end

function ui.drawServeText(playerServing, gameMode)
    local key = playerServing == 1 and 'Enter' or 'Space'

    love.graphics.setFont(smallFont)
    love.graphics.printf(getPlayerDisplayName(playerServing) .. ' is serving!', 0, 10, VIRTUAL_WIDTH, 'center')

    if gameMode == 'pvp' or playerServing == 1 then
        love.graphics.printf('Press ' .. key .. ' to serve', 0, 20, VIRTUAL_WIDTH, 'center')
    else
        love.graphics.printf('Waiting for ' .. getPlayerDisplayName(playerServing) .. ' to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
    end
end

function ui.drawGameInfo(score1, score2)
    if (score1 >= 3 or score2 >= 3) and score1 ~= score2 then
        love.graphics.setFont(smallFont)
        love.graphics.printf('GAME POINT', 0, VIRTUAL_HEIGHT / 5 + 20, VIRTUAL_WIDTH, 'center')
    end
end

local function drawScore(display, x, y, width)
    love.graphics.printf(display, x, y, width, 'center')
end

function ui.drawScoreBoard(score1, score2)
    local halfWidth = VIRTUAL_WIDTH / 2
    local h = VIRTUAL_HEIGHT / 5

    love.graphics.setFont(mediumFont)

    if score1 == 3 and score2 == 3 then
        drawScore('DEUCE', 0, h, halfWidth)
        drawScore('DEUCE', halfWidth, h, halfWidth)
    else
        drawScore(scoresDisplay[score1], 0, h, halfWidth)
        drawScore(scoresDisplay[score2], halfWidth, h, halfWidth)
    end
end

function ui.drawCenterNet(segmentHeight, gap)
    local total = segmentHeight + gap
    local x = math.floor(VIRTUAL_WIDTH / 2 - 1)

    local y = gap


    setColor('gray')

    while y + segmentHeight <= VIRTUAL_HEIGHT - gap do
        love.graphics.rectangle('fill', x, y, 2, segmentHeight)
        y = y + total
    end

    setColor()
end

function ui.drawGameOverText(score1, score2)
    local winner = score1 > score2 and getPlayerDisplayName(1) or getPlayerDisplayName(2)

    love.graphics.setFont(smallFont)
    love.graphics.printf(winner .. ' wins!', 0, 10, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('Press Enter to restart', 0, 20, VIRTUAL_WIDTH, 'center')

end

function ui.drawFPS()
    love.graphics.setFont(smallFont)
    setColor('green')
    love.graphics.print(tostring(love.timer.getFPS()), 10, 10)
    setColor()
end

function ui.drawDebug(ball)
    local h = VIRTUAL_HEIGHT - 30

    love.graphics.setFont(smallFont)
    setColor('green')

    love.graphics.printf(string.format('dx: %d', ball.dx), 10, h, VIRTUAL_WIDTH, 'left')
    love.graphics.printf(string.format('dy: %d', ball.dy), 10, h + 20, VIRTUAL_WIDTH, 'left')


    love.graphics.printf(string.format('speed: %d', math.abs(ball.lastSpeed or 0)), 0, h, VIRTUAL_WIDTH - 10, 'right')
    love.graphics.printf(string.format('bonus factor: %.3f', ball.bonusFactor), 0, h + 20, VIRTUAL_WIDTH - 10, 'right')


    setColor()
end

return ui