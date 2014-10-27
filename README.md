# light_world.lua

  This is the light modeling done by Priorblue [here](https://bitbucket.org/PriorBlue/love2d-light-and-shadow-engine), 
only it has been largely refactored and edited to allow for scaling and proper translation.  
 
## Installation
   
  Copy and rename the lib folder into your project.
    
## How to use

```lua
local LightWorld = require "lib/light_world"

-- create light world
lightWorld = LightWorld({
  drawBackground = drawBackground, --the callback to use for drawing the background
  drawForground = drawForground, --the callback to use for drawing the foreground
  ambient = {55,55,55},         --the general ambient light in the environment
})

function love.draw()
  love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(scale)
    lightWorld:draw(x,y,scale)
  love.graphics.pop()
end
```

For more information please check out the (wiki)[https://github.com/tanema/light_world.lua/wiki] and see the examples directory to see how it is fully used. This project can be run with love to see the demonstrations in action. 

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
			
## License

A License has been included in this project
