local gameState = require 'src.GameState'

local ui = {}

local smallFont, mediumFont, largeFont

local function getPlayerDisplayName(player)
    if player == 1 then
        return 'P1'
    elseif gameState.mode == 'pvp' then
        return 'P2'
    else
        return 'CPU'
    end
end

function ui.loadFonts()
    smallFont = love.graphics.newFont('assets/font.ttf', 8)
    mediumFont = love.graphics.newFont('assets/font.ttf', 16)
    largeFont = love.graphics.newFont('assets/font.ttf', 32)
end

function ui.drawStartText()
    love.graphics.setFont(smallFont)
    love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('Press Enter to start', 0, 20, VIRTUAL_WIDTH, 'center')
end

function ui.drawServeText(playerServing)
    local key = playerServing == 1 and 'Enter' or 'Space'

    love.graphics.setFont(smallFont)
    love.graphics.printf(getPlayerDisplayName(playerServing) .. ' is serving!', 0, 10, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('Press ' .. key .. ' to serve', 0, 20, VIRTUAL_WIDTH, 'center')
end

function ui.drawScore(score1, score2)
    love.graphics.setFont(largeFont)

    local halfWidth = VIRTUAL_WIDTH / 2
    local h = VIRTUAL_HEIGHT / 5

    -- p1
    love.graphics.printf(
        tostring(score1),
        0,
        h,
        halfWidth,
        'center'
    )

    -- p2
    love.graphics.printf(
        tostring(score2),
        halfWidth,
        h,
        halfWidth,
        'center'
    )
end

function ui.drawCenterNet(segmentHeight, gap)
    local total = segmentHeight + gap
    local x = math.floor(VIRTUAL_WIDTH / 2 - 1)

    local y = gap


    love.graphics.setColor(0.5, 0.5, 0.5, 1)

    while y + segmentHeight <= VIRTUAL_HEIGHT - gap do
        love.graphics.rectangle('fill', x, y, 2, segmentHeight)
        y = y + total
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function ui.drawFPS()
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.print(tostring(love.timer.getFPS()), 10, 10)
    love.graphics.setColor(1, 1, 1, 1)
end

return ui