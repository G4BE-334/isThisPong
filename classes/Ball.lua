Ball = Class{}

function Ball:init(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height


    self.dX = math.random(2) == 1 and -100 or 100
    self.dY = math.random(-50, 50)
end

function Ball:collides(box)
    if self.x > box.x + box.width or self.x + self.width < box.x then
        return false
    end

    if self.y > box.y + box.height or self.y + self.height < box.y then
        return false
    end
    return true
end

function Ball:reset()
    self.x = VIRTUAL_WIDTH / 2 - 2
    self.y = VIRTUAL_HEIGHT / 2 - 2

    self.dX = math.random(2) == 1 and -100 or 100
    self.dY = math.random(-50, 50)
end

function Ball:render()
    love.graphics.rectangle('fill', self.x, self.y, 4, 4)
end

function Ball:update(dt)
    self.x = self.x + self.dX * dt
    self.y = self.y + self.dY * dt
end