import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/sprites"

local gfx <const> = playdate.graphics

local SCREEN_W, SCREEN_H = 400, 240

local paddle = { x = 170, y = 200, width = 60, height = 10 }

local ball = { x = 200, y = 180, dx = 2, dy = -2, radius = 4 }

local bricks = {}
local rows, cols = 3, 8
local brickWidth, brickHeight = 40, 12
local score = 0

-- Initialize bricks
for r = 1, rows do
    for c = 1, cols do
        local brick = {
            x = 20 + (c-1)*(brickWidth + 5),
            y = 30 + (r-1)*(brickHeight + 5),
            width = brickWidth,
            height = brickHeight,
            alive = true
        }
        table.insert(bricks, brick)
    end
end

-- ===== Playdate update loop =====
function playdate.update()
    gfx.clear()

    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        paddle.x = math.max(0, paddle.x - 4)
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        paddle.x = math.min(SCREEN_W - paddle.width, paddle.x + 4)
    end
    -- Crank control
    local crankDelta = playdate.getCrankChange()
    paddle.x = math.min(SCREEN_W - paddle.width, math.max(0, paddle.x + crankDelta))

    -- --- Move ball
    ball.x = ball.x + ball.dx
    ball.y = ball.y + ball.dy

    -- Bounce walls
    if ball.x - ball.radius < 0 or ball.x + ball.radius > SCREEN_W then
        ball.dx = -ball.dx
    end
    if ball.y - ball.radius < 0 then
        ball.dy = -ball.dy
    end

    -- Bounce paddle
    if ball.y + ball.radius >= paddle.y and
       ball.x >= paddle.x and
       ball.x <= paddle.x + paddle.width then
        ball.dy = -ball.dy
        ball.y = paddle.y - ball.radius
    end

    -- Brick collisions
    for _, brick in ipairs(bricks) do
        if brick.alive and
           ball.x + ball.radius > brick.x and
           ball.x - ball.radius < brick.x + brick.width and
           ball.y + ball.radius > brick.y and
           ball.y - ball.radius < brick.y + brick.height then
               brick.alive = false
               ball.dy = -ball.dy
               score = score + 1
               break
        end
    end

    -- Ball falls below screen → reset game
    if ball.y - ball.radius > SCREEN_H then
        ball.x, ball.y = 200, 180
        ball.dx, ball.dy = 2, -2
        paddle.x = 170
        score = 0
        -- reset bricks
        for _, brick in ipairs(bricks) do brick.alive = true end
    end

    -- --- Draw bricks ---
    for _, brick in ipairs(bricks) do
        if brick.alive then
            gfx.fillRect(brick.x, brick.y, brick.width, brick.height)
        end
    end

    gfx.fillRect(paddle.x, paddle.y, paddle.width, paddle.height)

    gfx.fillRect(ball.x - ball.radius, ball.y - ball.radius, ball.radius * 2, ball.radius * 2)

    gfx.drawText("Score: "..score, 5, 5)

end
