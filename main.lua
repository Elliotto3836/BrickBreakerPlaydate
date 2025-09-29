import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/sprites"

local gfx <const> = playdate.graphics

local SCREEN_W, SCREEN_H = 400, 240

-- Gameplay variables
local paddle = { x = 170, y = 200, width = 60, height = 10 }
local ball = { x = 200, y = 180, dx = 2, dy = -2, radius = 4 }

local bricks = {}
local rows, cols = 3, 8
local brickWidth, brickHeight = 40, 12
local score = 0
local lives = 3
local highScore = 0
local gameState = "start" 
local isPaused = false

local INITIAL_BALL_SPEED = 2.5

-- persistence
local function loadSave()
    local saved = playdate.datastore.read("brickbreaker_save")
    if saved and saved.highScore then
        highScore = saved.highScore
    else
        highScore = 0
    end
end

local function saveSave()
    playdate.datastore.write({ highScore = highScore }, "brickbreaker_save")
end

local function resetBricks()
    bricks = {}
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
end

local function resetBall(resetPos)
    ball.x = 200
    ball.y = 180

    ball.dx = INITIAL_BALL_SPEED
    ball.dy = -INITIAL_BALL_SPEED
    if resetPos then
        paddle.x = 170
    end
end

local function startNewGame()
    score = 0
    lives = 3
    gameState = "playing"
    resetBricks()
    resetBall(true)
end

-- init
loadSave()
resetBricks()

function playdate.update()
    gfx.clear()

    -- Handle input for start/gameover/win screens
    if gameState ~= "playing" then
        gfx.drawText("Brick Breaker", SCREEN_W/2 - 60, 30)
        if gameState == "start" then
            gfx.drawText("Press A to start", SCREEN_W/2 - 60, SCREEN_H/2)
        elseif gameState == "win" then
            gfx.drawText("You Win!", SCREEN_W/2 - 30, SCREEN_H/2 - 10)
            gfx.drawText("Press A to play again", SCREEN_W/2 - 80, SCREEN_H/2 + 10)
        elseif gameState == "gameover" then
            gfx.drawText("Game Over", SCREEN_W/2 - 40, SCREEN_H/2 - 10)
            gfx.drawText("Press A to try again", SCREEN_W/2 - 70, SCREEN_H/2 + 10)
        end
        gfx.drawText("High Score: "..highScore, 5, 5)

        if playdate.buttonJustPressed(playdate.kButtonA) then
            startNewGame()
        end
        return
    end

    -- Playing state: movement
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        paddle.x = math.max(0, paddle.x - 4)
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        paddle.x = math.min(SCREEN_W - paddle.width, paddle.x + 4)
    end
    -- Crank control
    local crankDelta = playdate.getCrankChange()
    paddle.x = math.min(SCREEN_W - paddle.width, math.max(0, paddle.x + crankDelta))

    -- Move ball
    ball.x = ball.x + ball.dx
    ball.y = ball.y + ball.dy

    -- Bounce walls
    if ball.x - ball.radius < 0 then
        ball.x = ball.radius
        ball.dx = -ball.dx
    elseif ball.x + ball.radius > SCREEN_W then
        ball.x = SCREEN_W - ball.radius
        ball.dx = -ball.dx
    end
    if ball.y - ball.radius < 0 then
        ball.y = ball.radius
        ball.dy = -ball.dy
    end

    -- Bounce paddle with angle based on hit position
    if ball.y + ball.radius >= paddle.y and
       ball.x >= paddle.x and
       ball.x <= paddle.x + paddle.width and
       ball.dy > 0 then
        -- relative position from -1 (left) to 1 (right)
        local rel = ((ball.x - (paddle.x + paddle.width/2)) / (paddle.width/2))
        local speed = math.sqrt(ball.dx*ball.dx + ball.dy*ball.dy)
        ball.dx = rel * speed
        ball.dy = -math.max(1.5, speed * 0.9)
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
               ball.dx = ball.dx * 1.03
               ball.dy = ball.dy * 1.03
               score = score + 1
               if score > highScore then
                   highScore = score
                   saveSave()
               end
               break
        end
    end

    -- Ball falls below screen: lose life or game over
    if ball.y - ball.radius > SCREEN_H then
        lives = lives - 1
        if lives <= 0 then
            gameState = "gameover"
            if score > highScore then
                highScore = score
                saveSave()
            end
        else
            resetBall(false)
        end
    end

    -- Check win
    if score == rows * cols then
        gameState = "win"
        if score > highScore then
            highScore = score
            saveSave()
        end
    end

    -- Draw bricks
    for _, brick in ipairs(bricks) do
        if brick.alive then
            gfx.fillRect(brick.x, brick.y, brick.width, brick.height)
        end
    end

    gfx.fillRect(paddle.x, paddle.y, paddle.width, paddle.height)
    gfx.fillRect(ball.x - ball.radius, ball.y - ball.radius, ball.radius * 2, ball.radius * 2)

    gfx.drawText("Score: "..score, 5, 5)
    gfx.drawText("Lives: "..lives, 120, 5)
    gfx.drawText("High: "..highScore, 220, 5)

end
