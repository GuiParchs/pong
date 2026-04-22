local sounds = {}

function sounds.load()
    sounds.select = love.audio.newSource('assets/sounds/select.wav', 'static')
    sounds.serve = love.audio.newSource('assets/sounds/serve.wav', 'static')
    sounds.paddleHit = love.audio.newSource('assets/sounds/paddle_hit.wav', 'static')
    sounds.wallHit = love.audio.newSource('assets/sounds/wall_hit.wav', 'static')
    sounds.goal = love.audio.newSource('assets/sounds/goal.wav', 'static')
end

return sounds