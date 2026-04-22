Class = require 'class'

Ball = Class{}

Ball.size = 4

function Ball:init(x, y)
    self.x = x
    self.y = y

    self.dx = 0
    self.dy = 0
end

function Ball:update(dt)
    
end

function Ball:render()
    love.graphics.rectangle('fill', self.x, self.y, Ball.size, Ball.size)
end

return Ball