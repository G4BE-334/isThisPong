WINDOW_WIDTH = 1152 --1280
WINDOW_HEIGHT = 648 -- 720

-- Window that will be used for "objects" and "figures" in the game
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- Speed at which the paddle will be moving
PADDLE_SPEED = 240

-- Speech at which the AI paddle will be moving
AI_SPEED = 180

-- Define victory score
VICTORY_SCORE = 10

specialChance = 0

-- Class library that enables the use of objects oriented programming in Lua
Class = require 'classes/class'

-- https://github.com/Ulydev/push
push = require 'classes/push'

-- https://github.com/vrld/hump/blob/master/timer.lua
Timer = require 'classes/timer'

-- Class that stores methods and attributes for the paddles
require 'classes/Paddle'

-- Class that stores emthods and attributes for the ball
require 'classes/Ball'

player2 = false;

local textbox = {
    x = 40,
    y = 40,
    width = 400,
    height = 200,
    text = 'This is a textbox',
    active = false,
    colors = {
        background = { 255, 255, 255, 255 },
        text = { 40, 40, 40, 255 }
    }
}


-- Load function; Runs when the game is initialized
function love.load()
    
    -- Generate pseudo-random number seeding it to the current time
    math.randomseed(os.time())

    -- "nearest-neighbor" filter will allow love to produce crisp 2D look
    -- No blurriness to images or text
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    -- Set the title of the application window
    love.window.setTitle('Pong')

    -- import nice retro-looking fonts
    smallFont = love.graphics.newFont('fonts/font.ttf', 10)
    scoreFont = love.graphics.newFont('fonts/font.ttf', 20)
    victoryFont = love.graphics.newFont('fonts/font.ttf', 32)
    fpsFont = love.graphics.newFont('fonts/fontfps.ttf', 8)

    -- import and set up sound eeffects
    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/hitball.wav', 'static'),
        ['point_scored'] = love.audio.newSource('sounds/goal.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/hitwall.wav', 'static'),
        ['power_up'] = love.audio.newSource('sounds/Powerup10.wav', 'static')

    }

    music = love.audio.newSource('sounds/soundtrack.wav', 'static')

    -- Initialize the window with virtual resolution
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })

    -- Initialize score variables
    player1Score = 0
    AIScore = 0

    -- Initialize the server variable and switch between 1 and 2 to whoever
    -- is going to serve
    servingPlayer = 1
    -- Variable to define winner
    winningPlayer = 0

    -- Initialize player paddles and ball
    player1 = Paddle(10, 30, 5, 28)
    AI = Paddle(VIRTUAL_WIDTH - 15, VIRTUAL_HEIGHT - 30, 5, 28)
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    -- Set up the state of the game
    gameState = 'start'
    music:setLooping(true)
    music:play()
end

function love.textinput (text)
    if textbox.active then
        textbox.text = textbox.text .. text
    end
end

-- Function called by LOVE to resize the screen to the specified width and height
function love.resize(w, h)
    push:resize(w, h)
end

-- Function that runs every frame with "dt" passed in, 
-- with dt in seconds since the last frame
function love.update(dt)
    
    Timer.update(dt)
    
    if gameState == 'serve' then

        -- Before switching to play, initialize ball's velocity based
        -- on player who last scored
        ball.dY = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dX = math.random(140, 200)
        elseif servingPlayer == 2 then
            ball.dX = -math.random(140, 200)
        end

        -- Wait a little and then serve
        -- After analysing I saw that not making the player press enter every time
        -- makes the game flow smoothly and seem more natural
        if player2 == false then 
            Timer.after(0.8, function() gameState = 'play' end)
        else
            Timer.after(0.8, function() gameState = '2players' end)
        end

    elseif gameState == 'play' or gameState == '2players' then
       
        -- Detect ball collision with paddles, reversing dx if true and
        -- slightly increasing it, then altering the dy based on position 
        -- Deflect the ball to the right
        if ball:collides(player1) then
            -- Play paddle hit sound effect
            sounds['paddle_hit']:play()
            
            ball.dX = -ball.dX * 1.15
            ball.x = player1.x + 5

            -- Keep velocity going in the same direction but randomized
            if ball.dY < 0 then
                ball.dY = -math.random(10, 150)
            else
                ball.dY = math.random(10, 150)
            end
        end

        -- deflect the ball to the left
        if ball:collides(AI) then
            -- Play paddle hit sound effect
            sounds['paddle_hit']:play()
            
            ball.dX = -ball.dX * 1.15
            ball.x = AI.x - 4

            -- Keep velocity going in the same direction but randomized
            if ball.dY < 0 then
                ball.dY = -math.random(10, 150)
            else
                ball.dY = math.random(10, 150)
            end
        end

        -- detect upper and lower screen boundaries collision and reverse if colide
        if ball.y <= 0 then
            if (ball.dX < 0 and AI.level > 0) then 
                -- 33% of using the ability but it will use it every 3 times at least
                specialChance = math.random(3)

                if specialChance == 3 or AI.skillCount == 2 then
                    -- Special ability will transfer the ball to the other side of the window
                    sounds['power_up']:play() -- Special ability sound effect
                    ball.y = VIRTUAL_HEIGHT - 4
                
                    -- Reset skill count
                    AI.skillCount = 0
                else
                    -- Increase skill count to "charge" skill
                    AI.skillCount = AI.skillCount + 1

                    -- Play wall hit sound effect
                    sounds['wall_hit']:play()
                        
                    -- Deflect the ball down
                    ball.y = 0
                    ball.dY = -ball.dY
                end
                specialChance = 0
            else
                -- Play wall hit sound effect
                sounds['wall_hit']:play()
                    
                -- Deflect the ball down
                ball.y = 0
                ball.dY = -ball.dY
            end
        -- -4 to take in consideration the balls size
        elseif ball.y >= VIRTUAL_HEIGHT - 4 then
            
            if (ball.dX < 0 and AI.level > 0) then
                specialChance = math.random(3)
                -- 33% of using the ability but it will use it every 3 times at least
                
                if (specialChance == 3 or AI.skillCount == 2) then
                    -- Special ability will transfer the ball to the other side of the window
                    -- Special ability sound effect
                    sounds['power_up']:play()
                    ball.y = 0
                    -- Reset skill count
                    AI.skillCount = 0

                else
                    -- Increase skill count
                    AI.skillCount = AI.skillCount + 1

                    -- Player wall hit sound effect
                    sounds['wall_hit']:play()
                    
                    -- Deflect the ball up
                    ball.y = VIRTUAL_HEIGHT - 4
                    ball.dY = -ball.dY

                end
                specialChance = 0
            else
                -- Player wall hit sound effect
                sounds['wall_hit']:play()
                
                -- Deflect the ball up
                ball.y = VIRTUAL_HEIGHT - 4
                ball.dY = -ball.dY
            end
        end
    end

    -- If the ball reaches the left or the right edge of the screen
    -- Goal; Update the score
    if ball.x < 0 then
        -- Play point scored sound effect
        sounds['point_scored']:play()
        
        servingPlayer = 1
        AIScore = AIScore + 1

        -- End the game when victory score is reached
        if AIScore == VICTORY_SCORE then
            winningPlayer = 2
            gameState = 'defeat'
            music:stop()
            ball:reset()

            AI_SPEED = 180
        else
            gameState = 'serve'
            -- Return ball to initial position
            ball:reset()         
        end
    end

    if ball.x > VIRTUAL_WIDTH then
        -- Player point scored sound effect
        sounds['point_scored']:play()
        
        servingPlayer = 2
        player1Score = player1Score + 1

        if gameState ~= '2players' then
            AI.level = 1
            -- Change AI difficulty based on scores
            if player1Score >= VICTORY_SCORE/2 and player1Score < VICTORY_SCORE/2 + 2 then
                AI_SPEED = 200
                
            elseif player1Score >= VICTORY_SCORE/2 + 2 and player1Score < VICTORY_SCORE - 1 then
                AI_SPEED = 240
            elseif player1Score >= VICTORY_SCORE - 1 then
                AI_SPEED = 280
            end
        end

        -- End the game when victory score is reached
        if player1Score == VICTORY_SCORE then
            winningPlayer = 1
            gameState = 'victory'
            music:stop()
            ball:reset()

            AI_SPEED = 180
        else
            gameState = 'serve'
            -- Return ball to initial position
            ball:reset()
        end
    end

    -- Player1 movement
    if love.keyboard.isDown('w') then
        player1.dY = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dY = PADDLE_SPEED
    else
        player1.dY = 0
    end

    if love.keyboard.isDown('up') then
        AI.dY = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        AI.dY = PADDLE_SPEED
    else
        AI.dY = 0
    end

    -- Determining collision point
    -- The AI is only going to start moving when the ball is on the middle of the screen to make the game fair for users to play against AI
    if ball.dX > 0 and ball.x >= VIRTUAL_WIDTH/2 and player2 == false then
        angularVelocity = ball.dY/ball.dX
        collisionPoint = ball.y + ((AI.x - ball.x) * angularVelocity)
        
        -- AI movement
        if AI.y + 10 <= collisionPoint - 2 or AI.y >= collisionPoint + 2 then
            -- Utilize collision point +-2 here to create an area where the AI can be
            -- When using just collision point before the AI would "shake" on the same point because of inaccuracy
            if (AI.y + 10)  < collisionPoint then
                AI.dY = AI_SPEED
            elseif (AI.y + 10) > collisionPoint then
                AI.dY = -AI_SPEED
            end
        else
            AI.dY = 0 
        end
            
    elseif player2 == false then
        AI.dY = 0
    end

    -- -- Update the ball's position and velocity only if in play state
    if gameState == 'play' or gameState == '2players' then
        ball:update(dt)
    end

    player1:update(dt)
    AI:update(dt)
end

-- Function in LOVE2D that allows to access the keys pressed each frame
function love.keypressed(key)

    -- Allow player to close the game by pressing esc
    if key == 'escape' then
        love.event.quit()

    -- Transition between start, serve, and play phase
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            if player2 == false then
                gameState = 'play'
            else
                gameState = '2players'
            end
        -- elseif gameState == 'serve' then
           -- gameState = 'play'
        elseif gameState == 'victory' or gameState == 'defeat' then
            -- Restart the game appropriately 
            gameState = 'serve'

            -- Restart the soundtrack
            music:play()

            -- Reset ball and the scores to 0
            ball:reset()
            player1Score = 0
            AIScore = 0
            
            -- Ddecide following serving player as the opposite of who won
            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end

    elseif key == 'space' and gameState == 'start' then
        gameState = '2players'
        player2 = true
    end
            
end

-- Function called afetr update used to draw anything to the screen and/or update
function love.draw()
    push:apply('start')

    -- Clear the screen with a specific color
    love.graphics.clear(40 / 255, 45 / 255, 52 / 255, 255 / 255)

    displayScore()

    if gameState == 'start' then
        love.graphics.setFont(smallFont)
        love.graphics.printf("Welcome to Pong!", 0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Press Enter to play against computer!", 0, 32, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("OR", 0, 44, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Press Space to play 2 players!", 0, 56, VIRTUAL_WIDTH, 'center')

    elseif gameState == 'serve' then
        love.graphics.setFont(smallFont)
        love.graphics.printf("Get ready to play", 0, 32, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Goal!", 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'victory' then
        -- Draw a victory message
        love.graphics.setFont(victoryFont)
        love.graphics.printf("Player" .. tostring(winningPlayer) .. " WINS!", 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf("Press Enter To Restart!", 0, 42, VIRTUAL_WIDTH, 'center')
    -- When lost a match against AI
    elseif gameState == 'defeat' then
        love.graphics.setFont(victoryFont)
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.printf("YOU LOST!", 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(smallFont)
        love.graphics.printf("GAME OVER. Press Enter To Try Again!", 0, 42, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        -- No UI messages to display in play
    end

    player1:render()
    
    if player2 == false then
        -- Change AI difficulty based on scores
        if player1Score >= VICTORY_SCORE/2 and player1Score < VICTORY_SCORE/2 + 2 then
            -- Yellow
            love.graphics.setColor(1, 1, 0, 1)
        elseif player1Score >= VICTORY_SCORE/2 + 2 and player1Score < VICTORY_SCORE - 1 then
            -- Orange
            love.graphics.setColor(255/255, 165/255, 0, 1)
        elseif player1Score >= VICTORY_SCORE - 1 then
            -- Red
            love.graphics.setColor(1, 0, 0, 1)
        end
    end
    AI:render()
    love.graphics.setColor(1, 1, 1, 1)
    

    ball:render()

    displayFPS()

    push:apply('end')
end

-- Render the current FPS and display to player
function displayFPS()
    love.graphics.setFont(fpsFont)
    love.graphics.setColor(0, 1, 0, 1)
    -- Display velocity for development purposes
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 40, 20)
    love.graphics.print('chance = ' .. specialChance, 360, 180)
    love.graphics.print('ball.dX = ' .. ball.dX, 360, 200)
    love.graphics.print('skill count = ' .. AI.skillCount, 360, 220)
    love.graphics.print('AI.lvl = ' .. AI.level, 360, 230)
    love.graphics.setColor(1, 1, 1, 1)
end

function displayScore()

    -- Draw the score on the center of the screen
    -- Update the score after every goal 
    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50, VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(AIScore), VIRTUAL_WIDTH / 2 + 30, VIRTUAL_HEIGHT / 3)
end
