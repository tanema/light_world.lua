# light_world.lua

  This is the light modeling done by Priorblue [here](https://bitbucket.org/PriorBlue/love2d-light-and-shadow-engine), 
only it has been largely refactored and edited to allow for scaling and proper translation.  

*Supports love 11.2(master branch), 0.10.1(commit 414b9b74c0eb95bfb8b5e26a11caf2b32beccca0)
 
## Installation
   
  Copy and rename the lib folder into your project.
    
## How to use

```lua
local LightWorld = require "lib" --the path to where light_world is (in this repo "lib")

--create light world
function love.load()
  lightWorld = LightWorld({
    ambient = {55/255,55/255,55/255},         --the general ambient light in the environment
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

For more information please check out the [wiki](https://github.com/tanema/light_world.lua/wiki) and see the examples directory to see how it is fully used. This project can be run with love to see the demonstrations in action. 

### Gamera & HUMP
There are example in the example directory how to use both of these with the library.

## Features ##
* **[Preview (Video)](https://www.youtube.com/watch?v=6V5Dtsa6Nd4)**
* polygon shadow calculation [Preview](http://onepixelahead.de/love2d_polyshadow.png)
* circle shadow calculation
* image shadow calculation [Preview](http://onepixelahead.de/love2d_polyshadow18.png)
* shadow blur
* light color, range, smooth and glow [Preview](http://onepixelahead.de/love2d_polyshadow2.png)
* ambient light
* self shadowing on images with normal maps [Preview](http://onepixelahead.de/love2d_polyshadow_pixelshadow.png)
* dynamic glow effect on images and circle/poly objects [Preview](http://onepixelahead.de/love2d_polyshadow_glow.png) [Preview](http://onepixelahead.de/love2d_polyshadow15.gif)
* generate flat or gradient normal maps [Preview](http://onepixelahead.de/love2d_polyshadow7.png)
* convert height maps to normal maps [Preview](http://onepixelahead.de/love2d_polyshadow8.png)
* generate a normal map directly from the image (usually gives poor results)
* shadow color and alpha (glass) [Preview](http://onepixelahead.de/love2d_polyshadow9.png)
* directional light [Preview](http://onepixelahead.de/love2d_polyshadow12.png)
* refractions (moveable) [Preview](http://onepixelahead.de/love2d_polyshadow13.gif)
* chromatic aberration [Preview](http://onepixelahead.de/love2d_polyshadow16.gif)
* postshader with many included postshaders, plus easy to extend
* animations in tandem with normal maps thanks to [anim8](https://github.com/kikito/anim8)
			
## License

A License has been included in this project

## Contributors
- Jon @xiejiangzhi
- Brandon Blanker Lim-it @flamendless 
- @Azorlogh
- Gustavo Kishima @gukiboy
- Rose L. Liverman @TangentFoxy
- Kyle McLamb @Alloyed
