--[[
The MIT License (MIT)

Copyright (c) 2016 Marcus Ihde

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
local _PACKAGE = (...)

-- Since require() doesn't support enumeration we automatically populate the
-- shader list using
-- for f in lib/shaders/postshaders/*.lua; echo \"`basename $f .lua`\",
-- and manually remove init.lua
local names = {
"black_and_white",
"blurh",
"blurv",
"chromatic_aberration",
"contrast",
"curvature",
"edges",
"four_colors",
"hdr_tv",
"monochrome",
"phosphorish",
"phosphor",
"pip",
"pixellate",
"radialblur",
"scanlines",
"tilt_shift",
"waterpaint",
}

local shaders = {}
for _, name in ipairs(names) do
  local module = _PACKAGE.."."..v
  local str = require(module)
  local effect = love.graphics.newShader(str)
  local defs = {}
  for vtype, extern in str:gmatch("extern (%w+) (%w+)") do
    defs[extern] = true
  end
  shaders[name] = {effect, defs}
end

return shaders
