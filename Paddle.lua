Class = require 'class'

Paddle = Class{}

Paddle.width = 5
Paddle.height = 35

Paddle.speed = 220

function Paddle:init(x, y)
    self.x = x
    self.y = y

    self.dy = 0
end

function Paddle:update(dt)
    if self.dy < 0 then
        self.y = math.max(0, self.y + self.dy * dt)
    else
        self.y = math.min(VIRTUAL_HEIGHT - Paddle.height, self.y + self.dy * dt)
    end
end

function Paddle:render()
    love.graphics.rectangle('fill', self.x, self.y, Paddle.width, Paddle.height)
end

return Paddle