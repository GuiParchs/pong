local Class = require 'lib.class'

local Paddle = Class{}

Paddle.width = 5
Paddle.height = 35

Paddle.speed = 220

function Paddle:init(x, y)
    self.x = x
    self.y = y

    self.dy = 0
end

function Paddle:update(dt)
    self.y = self.y + self.dy * dt

    if self.y <= 0 then
        self.y = 0
        self.dy = math.max(0, self.dy)
    elseif self.y >= VIRTUAL_HEIGHT - Paddle.height then
        self.y = VIRTUAL_HEIGHT - Paddle.height
        self.dy = math.min(0, self.dy)
    end
end

-- direction should be -1 for up, 1 for down, and 0 for stop
function Paddle:move(direction)
    self.dy = Paddle.speed * direction
end

function Paddle:render()
    love.graphics.rectangle('fill', self.x, self.y, Paddle.width, Paddle.height)
end

return Paddle