local _PACKAGE = (...):match("^(.+)[%./][^%./]+") or ""
local class = require(_PACKAGE.."/class")

local vec3 = class()

function vec3:init(x, y, z)
  self.x, self.y, self.z = x, y, z
end

function vec3:normalize()
	local len = self:length()
	return vec3((self.x / len), (self.y / len), (self.z / len))
end

function vec3:dot(v2)
	return (self.x * v2.x) + (self.y * v2.y) + (self.z * v2.z)
end
 
function vec3:cross(v2)
  return ((self.y * v2.z) - (self.z * v2.y)),
         ((self.z * v2.x) - (self.x * v2.z)),
         ((self.x * v2.y) - (self.y * v2.x))
end

function vec3:length()
	return math.sqrt(self:dot(self))
end

return vec3

