# light_world.lua

A library for Love2d to create a dynamic lighting system, supporting:
- Shadows for any shape
- Normal maps for 3d like reflections
- Glow maps
- Postshader effects
- Animations with normal maps

All of this is base of a previous version made by [PriorBlue](https://bitbucket.org/PriorBlue/love2d-light-and-shadow-engine),

## Installation

Copy and rename the lib folder into your project.

## How to use
For more information please check out the [wiki](https://github.com/tanema/light_world.lua/wiki) and see the examples directory to see how it is fully used.
This project can be run with love to see the demonstrations in action.

```lua
local LightWorld = require "lib" --the path to where light_world is (in this repo "lib")

--create light world
function love.load()
  lightWorld = LightWorld({
    ambient = {0.21,0.21,0.21},         --the general ambient light in the environment
  })
end

function love.update(dt)
  lightWorld:update(dt)
  lightWorld:setTranslation(x, y, scale)
end

function love.draw()
  love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(scale)
    lightWorld:draw(function()
      -- do your stuff
    end)
  love.graphics.pop()
end
```

## Contributors
- Jon @xiejiangzhi
- Brandon Blanker Lim-it @flamendless
- @Azorlogh
- Gustavo Kishima @gukiboy
- Rose L. Liverman @TangentFoxy
- Kyle McLamb @Alloyed
- @Buckle2000
- Benoit Giannangeli @giann
