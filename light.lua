LOVE_LIGHT_CURRENT = nil
LOVE_LIGHT_CIRCLE = nil
LOVE_LIGHT_POLY = nil
LOVE_LIGHT_IMAGE = nil
LOVE_LIGHT_LAST_BUFFER = nil

LOVE_LIGHT_BLURV = love.graphics.newShader("shader/blurv.glsl")
LOVE_LIGHT_BLURH = love.graphics.newShader("shader/blurh.glsl")

love.light = {}

-- light world
function love.light.newWorld()
	local o = {}
	o.lights = {}
	o.ambient = {0, 0, 0}
	o.circle = {}
	o.poly = {}
	o.img = {}
	o.shadow = love.graphics.newCanvas()
	o.shine = love.graphics.newCanvas()
	o.pixelShadow = love.graphics.newCanvas()
	o.pixelShadow2 = love.graphics.newCanvas()
	o.shader = love.graphics.newShader("shader/poly_shadow.glsl")
	o.shader2 = love.graphics.newShader("shader/pixel_self_shadow.glsl")
	o.changed = true
	o.blur = true
	-- update
	o.update = function()
		LOVE_LIGHT_LAST_BUFFER = love.graphics.getCanvas()
		love.graphics.setShader(o.shader)
		if o.changed then
			love.graphics.setCanvas(o.shadow)
			o.shadow:clear(unpack(o.ambient))
			love.graphics.setBlendMode("additive")
		else
			love.graphics.setColor(255,255,255)
			love.graphics.setBlendMode("alpha")
		end

		local lightsOnScreen = 0
		LOVE_LIGHT_CIRCLE = o.circle
		LOVE_LIGHT_POLY = o.poly
		LOVE_LIGHT_IMAGE = o.img
		for i = 1, #o.lights do
			if o.lights[i].changed or o.changed then
				local curLightX = o.lights[i].x
				local curLightY = o.lights[i].y
				local curLightRange = o.lights[i].range
				local curLightColor = {
					o.lights[i].red / 255.0,
					o.lights[i].green / 255.0,
					o.lights[i].blue / 255.0
				}
				local curLightSmooth = o.lights[i].smooth
				local curLightGlow = {
					1.0 - o.lights[i].glowSize,
					o.lights[i].glowStrength
				}

				if  curLightX+curLightRange > 0 and curLightX-curLightRange < love.graphics.getWidth()
				and curLightY+curLightRange > 0 and curLightY-curLightRange < love.graphics.getHeight()
				then
					local lightposrange = {curLightX, love.graphics.getHeight() - curLightY, curLightRange}
					LOVE_LIGHT_CURRENT = o.lights[i]
					o.shader:send("lightPositionRange", lightposrange)
					o.shader:send("lightColor", curLightColor)
					o.shader:send("smooth", curLightSmooth)
					o.shader:send("glow", curLightGlow)

					if o.changed then
						love.graphics.setCanvas(o.shadow)
					else
						love.graphics.setCanvas(o.lights[i].shadow)
						love.graphics.clear()
					end

					-- draw shadow
					love.graphics.setInvertedStencil(shadowStencil)
					love.graphics.setBlendMode("additive")
					love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

					-- draw shine
					love.graphics.setCanvas(o.lights[i].shine)
					o.lights[i].shine:clear(255, 255, 255)
					love.graphics.setBlendMode("alpha")
					love.graphics.setStencil(polyStencil)
					love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

					lightsOnScreen = lightsOnScreen + 1
				end

				o.lights[i].changed = o.changed
			end
		end

		-- update shadow
		love.graphics.setShader()
		if not o.changed then
			love.graphics.setCanvas(o.shadow)
			love.graphics.setStencil()
			love.graphics.setColor(unpack(o.ambient))
			love.graphics.setBlendMode("alpha")
			love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
			love.graphics.setColor(255, 255, 255)
			love.graphics.setBlendMode("additive")
			for i = 1, #o.lights do
				love.graphics.draw(o.lights[i].shadow)
			end
		end

		-- update shine
		love.graphics.setCanvas(o.shine)
		love.graphics.setColor(unpack(o.ambient))
		love.graphics.setBlendMode("alpha")
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
		love.graphics.setColor(255,255,255)
		love.graphics.setBlendMode("additive")
		for i = 1, #o.lights do
			love.graphics.draw(o.lights[i].shine)
		end

				love.graphics.setColor(255, 255, 255)
		love.graphics.setBlendMode("alpha")
		o.pixelShadow:clear()
		math.randomseed(2)
		love.graphics.setShader()
		love.graphics.setCanvas(o.pixelShadow)

		for i = 1, #o.img do
			if o.img[i].normal then
				love.graphics.draw(o.img[i].normal, o.img[i].x - o.img[i].ox2, o.img[i].y - o.img[i].oy2)
			end
		end

		-- update pixel shadow
		o.pixelShadow2:clear()
		love.graphics.setCanvas(o.pixelShadow2)
		love.graphics.setBlendMode("additive")
		love.graphics.setShader(o.shader2)

		local curLightAmbient = {
			o.ambient[1] / 255.0,
			o.ambient[2] / 255.0,
			o.ambient[3] / 255.0
		}
		for i = 1, #o.lights do
			local curLightColor = {
				o.lights[i].red / 255.0,
				o.lights[i].green / 255.0,
				o.lights[i].blue / 255.0
			}
			o.shader2:send("lightPosition", {o.lights[i].x, love.graphics.getHeight() - o.lights[i].y, 16})
			o.shader2:send("lightRange", {o.lights[i].range})
			o.shader2:send("lightColor", curLightColor)
			o.shader2:send("lightAmbient", curLightAmbient)
			o.shader2:send("lightSmooth", {o.lights[i].smooth})
			love.graphics.draw(o.pixelShadow)
		end

		love.graphics.setShader()
		o.pixelShadow:clear(255, 255, 255)
		love.graphics.setCanvas(o.pixelShadow)
		love.graphics.setBlendMode("alpha")
		love.graphics.draw(o.pixelShadow2)

		love.graphics.setShader()
		love.graphics.setBlendMode("alpha")
		love.graphics.setStencil()
		love.graphics.setCanvas(LOVE_LIGHT_LAST_BUFFER)

		o.changed = false
	end
	-- draw shadow
	o.drawShadow = function()
		love.graphics.setColor(255, 255, 255)
		if o.blur then
			LOVE_LIGHT_LAST_BUFFER = love.graphics.getCanvas()
			love.graphics.setBlendMode("alpha")
			love.graphics.setCanvas(o.shadow)
			love.graphics.setShader(LOVE_LIGHT_BLURV)
			love.graphics.draw(o.shadow)
			love.graphics.setShader(LOVE_LIGHT_BLURH)
			love.graphics.draw(o.shadow)
			love.graphics.setCanvas(LOVE_LIGHT_LAST_BUFFER)
			love.graphics.setBlendMode("multiplicative")
			love.graphics.setShader()
			love.graphics.draw(o.shadow)
			love.graphics.setBlendMode("alpha")
		else
			love.graphics.setBlendMode("multiplicative")
			love.graphics.setShader()
			love.graphics.draw(o.shadow)
			love.graphics.setBlendMode("alpha")
		end
	end
	-- draw shine
	o.drawShine = function()
		love.graphics.setColor(255, 255, 255)
		love.graphics.setBlendMode("multiplicative")
		love.graphics.setShader()
		love.graphics.draw(o.shine)
		love.graphics.setBlendMode("alpha")
	end
	-- draw pixel shadow
	o.drawPixelShadow = function()
		love.graphics.setColor(255, 255, 255)
		if o.blur and false then
			LOVE_LIGHT_LAST_BUFFER = love.graphics.getCanvas()
			love.graphics.setBlendMode("alpha")
			love.graphics.setCanvas(o.pixelShadow)
			love.graphics.setShader(LOVE_LIGHT_BLURV)
			love.graphics.draw(o.pixelShadow)
			love.graphics.setShader(LOVE_LIGHT_BLURH)
			love.graphics.draw(o.pixelShadow)
			love.graphics.setCanvas(LOVE_LIGHT_LAST_BUFFER)
			love.graphics.setBlendMode("multiplicative")
			love.graphics.setShader()
			love.graphics.draw(o.pixelShadow)
			love.graphics.setBlendMode("alpha")
		else
			love.graphics.setBlendMode("multiplicative")
			love.graphics.setShader()
			love.graphics.draw(o.pixelShadow)
			love.graphics.setBlendMode("alpha")
		end
	end
	-- new light
	o.newLight = function(x, y, red, green, blue, range)
		o.lights[#o.lights + 1] = love.light.newLight(o, x, y, red, green, blue, range)

		return o.lights[#o.lights]
	end
	-- clear lights
	o.clearLights = function()
		o.lights = {}
	end
	-- clear objects
	o.clearObjects = function()
		o.poly = {}
		o.circle = {}
		o.img = {}
	end
	-- set ambient color
	o.setAmbientColor = function(red, green, blue)
		o.ambient = {red, green, blue}
	end
	-- set ambient red
	o.setAmbientRed = function(red)
		o.ambient[1] = red
	end
	-- set ambient green
	o.setAmbientGreen = function(green)
		o.ambient[2] = green
	end
	-- set ambient blue
	o.setAmbientBlue = function(blue)
		o.ambient[3] = blue
	end
	-- set blur
	o.setBlur = function(blur)
		o.blur = blur
		o.changed = true
	end
	-- new rectangle
	o.newRectangle = function(x, y, w, h)
		return love.light.newRectangle(o, x, y, w, h)
	end
	-- new circle
	o.newCircle = function(x, y, r)
		return love.light.newCircle(o, x, y, r)
	end
	-- new polygon
	o.newPolygon = function(...)
		return love.light.newPolygon(o, ...)
	end
	-- new image
	o.newImage = function(img, x, y, width, height, ox, oy)
		return love.light.newImage(o, img, x, y, width, height, ox, oy)
	end
	-- set polygon data
	o.setPoints = function(n, ...)
		o.poly[n].data = {...}
	end
	-- get circle count
	o.getCircleCount = function()
		return #o.circle
	end
	-- get polygon count
	o.getPolygonCount = function()
		return #o.poly
	end
	-- get polygon
	o.getPoints = function(n)
		return unpack(o.poly[n].data)
	end
	-- get light count
	o.getLightCount = function()
		return #o.lights
	end
	-- get light x position
	o.getLightX = function(n)
		return o.lights[n].x
	end
	-- get light y position
	o.getLightY = function(n)
		return o.lights[n].y
	end

	return o
end

-- light object
function love.light.newLight(p, x, y, red, green, blue, range)
	local o = {}
	o.shadow = love.graphics.newCanvas()
	o.shine = love.graphics.newCanvas()
	o.x = x
	o.y = y
	o.z = 1
	o.red = red
	o.green = green
	o.blue = blue
	o.range = range
	o.smooth = 1.0
	o.glowSize = 0.1
	o.glowStrength = 0.0
	o.changed = true
	-- set position
	o.setPosition = function(x, y)
		if x ~= o.x or y ~= o.y then
			o.x = x
			o.y = y
			o.changed = true
		end
	end
	-- set color
	o.setColor = function(red, green, blue)
		o.red = red
		o.green = green
		o.blue = blue
		--p.changed = true
	end
	-- set range
	o.setRange = function(range)
		if range ~= o.range then
			o.range = range
			o.changed = true
		end
	end
	-- set glow size
	o.setSmooth = function(smooth)
		o.smooth = smooth
		o.changed = true
	end
	-- set glow size
	o.setGlowSize = function(size)
		o.glowSize = size
		o.changed = true
	end
	-- set glow strength
	o.setGlowStrength = function(strength)
		o.glowStrength = strength
		o.changed = true
	end
	-- get type
	o.getType = function()
		return "light"
	end

	return o
end

-- rectangle object
function love.light.newRectangle(p, x, y, w, h)
	local o = {}
	p.poly[#p.poly + 1] = o
	o.id = #p.poly
	o.x = x
	o.y = y
	o.w = w
	o.h = h
	o.ox = w / 2
	o.oy = h / 2
	o.shine = true
	p.changed = true
	o.data = {
		o.x - o.ox,
		o.y - o.oy,
		o.x - o.ox + o.w,
		o.y - o.oy,
		o.x - o.ox + o.w,
		o.y - o.oy + o.h,
		o.x - o.ox,
		o.y - o.oy + o.h
	}
	-- refresh
	o.refresh = function()
		o.data[1] = o.x - o.ox
		o.data[2] = o.y - o.oy
		o.data[3] = o.x - o.ox + o.w
		o.data[4] = o.y - o.oy
		o.data[5] = o.x - o.ox + o.w
		o.data[6] = o.y - o.oy + o.h
		o.data[7] = o.x - o.ox
		o.data[8] = o.y - o.oy + o.h
	end
	-- set position
	o.setPosition = function(x, y)
		if x ~= o.x or y ~= o.y then
			o.x = x
			o.y = y
			o.refresh()
			p.changed = true
		end
	end
	-- set dimension
	o.setDimension = function(w, h)
		o.w = w
		o.h = h
		o.refresh()
		p.changed = true
	end
	-- set shadow on/off
	o.setShadow = function(b)
		o.castsNoShadow = not b
		p.changed = true
	end
	-- set shine on/off
	o.setShine = function(b)
		o.shine = b
		p.changed = true
	end
	-- get x
	o.getX = function()
		return o.x
	end
	-- get y
	o.getY = function()
		return o.y
	end
	-- get type
	o.getType = function()
		return "rectangle"
	end

	return o
end

-- circle object
function love.light.newCircle(p, x, y, radius)
	local o = {}
	p.circle[#p.circle + 1] = o
	o.id = #p.circle
	o.x = x
	o.y = y
	o.radius = radius
	o.shine = true
	p.changed = true
	-- set position
	o.setPosition = function(x, y)
		if x ~= o.x or y ~= o.y then
			o.x = x
			o.y = y
			p.changed = true
		end
	end
	-- set radius
	o.setRadius = function(radius)
		if radius ~= o.radius then
			o.radius = radius
			p.changed = true
		end
	end
	-- set shadow on/off
	o.setShadow = function(b)
		o.castsNoShadow = not b
		p.changed = true
	end
	-- set shine on/off
	o.setShine = function(b)
		o.shine = b
		p.changed = true
	end
	-- get x
	o.getX = function()
		return o.x
	end
	-- get y
	o.getY = function()
		return o.y
	end
	-- get radius
	o.getRadius = function()
		return o.radius
	end
	-- get type
	o.getType = function()
		return "circle"
	end

	return o
end

-- poly object
function love.light.newPolygon(p, ...)
	local o = {}
	p.poly[#p.poly + 1] = o
	o.id = #p.poly
	o.shine = true
	p.changed = true
	if ... then
		o.data = {...}
	else
		o.data = {0,0,0,0,0,0}
	end
	-- set polygon data
	o.setPoints = function(...)
		o.data = {...}
		p.changed = true
	end
	-- set shadow on/off
	o.setShadow = function(b)
		o.castsNoShadow = not b
		p.changed = true
	end
	-- set shine on/off
	o.setShine = function(b)
		o.shine = b
		p.changed = true
	end
	-- get polygon data
	o.getPoints = function()
		return unpack(o.data)
	end
	-- get type
	o.getType = function()
		return "polygon"
	end

	return o
end

-- image object
function love.light.newImage(p, img, x, y, width, height, ox, oy)
	local o = {}
	p.poly[#p.poly + 1] = o
	p.img[#p.img + 1] = o
	o.id = #p.img
	o.img = img
	o.normal = nil
	o.x = x
	o.y = y
	o.width = width or img:getWidth()
	o.height = height or img:getHeight()
	o.ox = o.width / 2.0
	o.oy = o.height / 2.0
	o.ox2 = ox or o.width / 2.0
	o.oy2 = oy or o.height / 2.0
	o.shine = true
	p.changed = true
	o.data = {
		o.x - o.ox,
		o.y - o.oy,
		o.x - o.ox + o.width,
		o.y - o.oy,
		o.x - o.ox + o.width,
		o.y - o.oy + o.height,
		o.x - o.ox,
		o.y - o.oy + o.height
	}
	-- refresh
	o.refresh = function()
		o.data[1] = o.x - o.ox
		o.data[2] = o.y - o.oy
		o.data[3] = o.x - o.ox + o.width
		o.data[4] = o.y - o.oy
		o.data[5] = o.x - o.ox + o.width
		o.data[6] = o.y - o.oy + o.height
		o.data[7] = o.x - o.ox
		o.data[8] = o.y - o.oy + o.height
	end
	-- set position
	o.setPosition = function(x, y)
		if x ~= o.x or y ~= o.y then
			o.x = x
			o.y = y
			o.refresh()
			p.changed = true
		end
	end
	-- set dimension
	o.setDimension = function(width, height)
		o.width = width
		o.height = height
		o.refresh()
		p.changed = true
	end
	-- set shadow on/off
	o.setShadow = function(b)
		o.castsNoShadow = not b
		p.changed = true
	end
	-- set shine on/off
	o.setShine = function(b)
		o.shine = b
		p.changed = true
	end
	-- set image
	o.setImage = function(img)
		o.img = img
	end
	-- set normal
	o.setNormal = function(normal)
		o.normal = normal
	end
	-- get type
	o.getType = function()
		return "image"
	end

	return o
end

-- vector functions
function normalize(v)
	local len = math.sqrt(math.pow(v[1], 2) + math.pow(v[2], 2))
	local normalizedv = {v[1] / len, v[2] / len}
	return normalizedv
end

function dot(v1, v2)
	return v1[1] * v2[1] + v1[2] * v2[2]
end

function lengthSqr(v)
    return v[1] * v[1] + v[2] * v[2]
end

function length(v)
    return math.sqrt(lengthSqr(v))
end

function calculateShadows(lightsource, geometry, circle, image)
    local shadowGeometry = {}
    local shadowLength = 10000

    for i, v in pairs(geometry) do
		curPolygon = v.data
        if not v.castsNoShadow then 
            local edgeFacingTo = {}
            for j=1,#curPolygon,2 do
                local indexOfNextVertex = (j+2) % #curPolygon
                local normal = {-curPolygon[indexOfNextVertex+1] + curPolygon[j+1], curPolygon[indexOfNextVertex] - curPolygon[j]}
                local lightToPoint = {curPolygon[j] - lightsource.x, curPolygon[j+1] - lightsource.y}

                normal = normalize(normal)
                lightToPoint = normalize(lightToPoint)

				local dotProduct = dot(normal, lightToPoint)
                if dotProduct > 0 then table.insert(edgeFacingTo, true)
                else table.insert(edgeFacingTo, false) end
            end

			local curShadowGeometry = {}
			for j, curFacing in pairs(edgeFacingTo) do
				local nextIndex = (j+1) % #edgeFacingTo; if nextIndex == 0 then nextIndex = #edgeFacingTo end
				if curFacing and not edgeFacingTo[nextIndex] then 
					curShadowGeometry[1] = curPolygon[nextIndex*2-1]
					curShadowGeometry[2] = curPolygon[nextIndex*2]

					local lightVecFrontBack = normalize({curPolygon[nextIndex*2-1] - lightsource.x, curPolygon[nextIndex*2] - lightsource.y})
					curShadowGeometry[3] = curShadowGeometry[1] + lightVecFrontBack[1] * shadowLength
					curShadowGeometry[4] = curShadowGeometry[2] + lightVecFrontBack[2] * shadowLength

				elseif not curFacing and edgeFacingTo[nextIndex] then 
					curShadowGeometry[7] = curPolygon[nextIndex*2-1]
					curShadowGeometry[8] = curPolygon[nextIndex*2]

					local lightVecBackFront = normalize({curPolygon[nextIndex*2-1] - lightsource.x, curPolygon[nextIndex*2] - lightsource.y})
					curShadowGeometry[5] = curShadowGeometry[7] + lightVecBackFront[1]*shadowLength
					curShadowGeometry[6] = curShadowGeometry[8] + lightVecBackFront[2]*shadowLength
				end
			end
			if  curShadowGeometry[1]
			and curShadowGeometry[2]
			and curShadowGeometry[3]
			and curShadowGeometry[4]
			and curShadowGeometry[5]
			and curShadowGeometry[6]
			and curShadowGeometry[7]
			and curShadowGeometry[8]
			then
				shadowGeometry[#shadowGeometry + 1] = curShadowGeometry
			end
		end
	end

    for i, v in pairs(circle) do
		local curShadowGeometry = {}
		local angle = math.atan2(lightsource.x - v.x, v.y - lightsource.y) + math.pi / 2
		local x2 = v.x + math.sin(angle) * v.radius
		local y2 = v.y - math.cos(angle) * v.radius
		local x3 = v.x - math.sin(angle) * v.radius
		local y3 = v.y + math.cos(angle) * v.radius

		curShadowGeometry[1] = x2
		curShadowGeometry[2] = y2
		curShadowGeometry[3] = x3
		curShadowGeometry[4] = y3

		curShadowGeometry[5] = x3 - (lightsource.x - x3) * shadowLength
		curShadowGeometry[6] = y3 - (lightsource.y - y3) * shadowLength
		curShadowGeometry[7] = x2 - (lightsource.x - x2) * shadowLength
		curShadowGeometry[8] = y2 - (lightsource.y - y2) * shadowLength
		shadowGeometry[#shadowGeometry + 1] = curShadowGeometry
	end

    return shadowGeometry
end

shadowStencil = function()
	local shadowGeometry = calculateShadows(LOVE_LIGHT_CURRENT, LOVE_LIGHT_POLY, LOVE_LIGHT_CIRCLE)
	for i = 1,#shadowGeometry do
		love.graphics.polygon("fill", unpack(shadowGeometry[i]))
	end
    for i = 1, #LOVE_LIGHT_POLY do
		love.graphics.polygon("fill", unpack(LOVE_LIGHT_POLY[i].data))
    end
    for i = 1, #LOVE_LIGHT_CIRCLE do
        love.graphics.circle("fill", LOVE_LIGHT_CIRCLE[i].getX(), LOVE_LIGHT_CIRCLE[i].getY(), LOVE_LIGHT_CIRCLE[i].getRadius())
	end
    for i = 1, #LOVE_LIGHT_IMAGE do
		--love.graphics.rectangle("fill", LOVE_LIGHT_IMAGE[i].x, LOVE_LIGHT_IMAGE[i].y, LOVE_LIGHT_IMAGE[i].width, LOVE_LIGHT_IMAGE[i].height)
    end
end

polyStencil = function()
    for i = 1, #LOVE_LIGHT_CIRCLE do
		if LOVE_LIGHT_CIRCLE[i].shine then
			love.graphics.circle("fill", LOVE_LIGHT_CIRCLE[i].getX(), LOVE_LIGHT_CIRCLE[i].getY(), LOVE_LIGHT_CIRCLE[i].getRadius())
		end
	end
    for i = 1, #LOVE_LIGHT_POLY do
		if LOVE_LIGHT_POLY[i].shine then
			love.graphics.polygon("fill", unpack(LOVE_LIGHT_POLY[i].data))
		end
    end
    for i = 1, #LOVE_LIGHT_IMAGE do
		if LOVE_LIGHT_IMAGE[i].shine then
			--love.graphics.rectangle("fill", LOVE_LIGHT_IMAGE[i].x, LOVE_LIGHT_IMAGE[i].y, LOVE_LIGHT_IMAGE[i].width, LOVE_LIGHT_IMAGE[i].height)
		end
    end
end