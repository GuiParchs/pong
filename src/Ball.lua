local Class = require 'lib.class'

local sounds = require 'src.sounds'

local MAX_SERVE_DY = 80
local MIN_SERVE_DX = 100
local MAX_SERVE_DX = 150

local BASE_SPEEDUP = 0.01
local BONUS_SPEEDUP = 0.5
local BONUS_DECAY = 0.2
local MAX_DX = 350
local MAX_SPEED = 400

local Ball = Class{}

Ball.size = 4

function Ball:init(x, y)
    self.x = x
    self.y = y

    self.dx = 0
    self.dy = 0
    self.bonusFactor = 0

    self.lastSpeed = nil
end

function Ball:serve(player)
    self.dy = math.random(-MAX_SERVE_DY, MAX_SERVE_DY)
    self.dx = math.random(MIN_SERVE_DX, MAX_SERVE_DX)

    if player == 2 then
        self.dx = -self.dx
    end
    
    sounds.serve:play()
end

-- Returns 1 if player 1 scores, 2 if player 2 scores, nil otherwise
function Ball:update(dt)
    local speed = self.dx + self.dx * (self.bonusFactor * BONUS_SPEEDUP)

    if math.abs(speed) > MAX_SPEED then
        speed = MAX_SPEED * (speed < 0 and -1 or 1)
    end

    if Debug then
        self.lastSpeed = speed
    end

    self.x = self.x + speed * dt
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

    self.bonusFactor = math.max(0, self.bonusFactor - BONUS_DECAY * dt)

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

    self:_hitPaddle(paddle)

    return true
end

function Ball:reset()
    self.x = VIRTUAL_WIDTH / 2 - Ball.size / 2
    self.y = VIRTUAL_HEIGHT / 2 - Ball.size / 2
    self.dx = 0
    self.dy = 0
    self.bonusFactor = 0
end

function Ball:render()
    love.graphics.rectangle('fill', self.x, self.y, Ball.size, Ball.size)
end

function Ball:_hitPaddle(paddle)
    -- Reverse dx direction
    self.dx = -self.dx

    -- calculate hit position on paddle
    local paddleCenter = paddle.y + paddle.height / 2
    local ballCenter = self.y + Ball.size / 2

    local intersect = (ballCenter - paddleCenter) / (paddle.height / 2)
    local impactPoint = 1 - math.min(1, math.abs(intersect)) -- distance from center (0 - 1)

    -- Apply bonus
    self.bonusFactor = (self.bonusFactor * impactPoint * (1 - BONUS_DECAY)) + impactPoint -- sweet spot factor

    -- Speed up ball
    self:_speedUp()

    -- Change angle
    intersect = math.max(-1.2, math.min(1.2, intersect))
    self.dy = intersect * 140

    -- Play audio
    sounds.paddleHit:stop()
    sounds.paddleHit:play()
end

function Ball:_hitWall()
    self.dy = -self.dy
    self.bonusFactor = self.bonusFactor / 3
    self:_speedUp()

    sounds.wallHit:stop()
    sounds.wallHit:play()
end

function Ball:_speedUp()
    local newDx = self.dx * (1 + BASE_SPEEDUP)

    if math.abs(newDx) > MAX_DX then
        self.dx = MAX_DX * (newDx < 0 and -1 or 1)
    else
        self.dx = newDx
    end
end

function Ball:_hitGoal()
    self:reset()

    sounds.goal:stop()
    sounds.goal:play()
end

return Ball