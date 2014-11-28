local _PACKAGE = (...):match("^(.+)[%./][^%./]+") or ""
local class = require(_PACKAGE.."/class")

local vec2 = class()

function vec2:init(x, y)
  self.x, self.y = x, y
end

function vec2:normalize()
	local len = self:length()
	return vec2(self.x / len, self.y / len)
end

function vec2:dot(v2)
	return (self.x * v2.x) + (self.y * v2.y)
end

function vec2:cross(v2)
  return ((self.x * v2.y) - (self.y * v2.x))
end

function vec2:length()
	return math.sqrt(self:dot(self))
end

return vec2
