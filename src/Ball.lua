local Class = require 'lib.class'

local sounds = require 'src.sounds'

local Ball = Class{}

Ball.size = 4

function Ball:init(x, y)
    self.x = x
    self.y = y

    self.dx = 0
    self.dy = 0
end

function Ball:serve(player)
    self.dy = math.random(-60, 60)

    if player == 1 then
        self.dx = math.random(120, 180)
    else
        self.dx = -math.random(120, 180)
    end
    
    sounds.serve:play()
end

-- Returns 1 if player 1 scores, 2 if player 2 scores, nil otherwise
function Ball:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt

    -- Collision with top
    if self.y <= 0 then
        self.y = 0
        self:_hitWall()

    -- Collision with bottom
    elseif self.y >= VIRTUAL_HEIGHT - Ball.size then
        self.y = VIRTUAL_HEIGHT - Ball.size
        self:_hitWall()
    end

    -- Collision with left and right walls (goals)
    if self.x < 0 then
        self:_hitGoal()
        return 2

    elseif self.x >= VIRTUAL_WIDTH then
        self:_hitGoal()
        return 1
    end

    return nil
end

function Ball:collides(paddle)
    -- Axis Align Bounding Box (AABB)

    -- Horizontal check
    if self.x > paddle.x + paddle.width then return false end
    if self.x + Ball.size < paddle.x then return false end

    -- Vertical check
    if self.y > paddle.y + paddle.height then return false end
    if self.y + Ball.size < paddle.y then return false end

    -- Collided!
    self.dx = -self.dx
    self.dy = math.random(-150, 150)
    self:_speedUp()

    sounds.paddleHit:stop()
    sounds.paddleHit:play()

    return true
end

function Ball:reset()
    self.x = VIRTUAL_WIDTH / 2 - Ball.size / 2
    self.y = VIRTUAL_HEIGHT / 2 - Ball.size / 2
    self.dx = 0
    self.dy = 0
end

function Ball:render()
    love.graphics.rectangle('fill', self.x, self.y, Ball.size, Ball.size)
end

function Ball:_hitWall()
    self.dy = -self.dy
    self:_speedUp()

    sounds.wallHit:stop()
    sounds.wallHit:play()
end

function Ball:_hitGoal()
    self:reset()

    sounds.goal:stop()
    sounds.goal:play()
end

function Ball:_speedUp()
    local multiplier = 1.02 + math.random() * (0.015)
    self.dx = self.dx * multiplier
    -- fix self.dy = self.dy * multiplier
end

return Ball