LOVE_LIGHT_CURRENT = nil
LOVE_LIGHT_CIRCLE = nil
LOVE_LIGHT_POLY = nil
LOVE_LIGHT_IMAGE = nil
LOVE_LIGHT_LAST_BUFFER = nil

LOVE_LIGHT_BLURV = love.graphics.newShader("shader/blurv.glsl")
LOVE_LIGHT_BLURH = love.graphics.newShader("shader/blurh.glsl")

LOVE_LIGHT_TRANSLATE_X = 0
LOVE_LIGHT_TRANSLATE_Y = 0
LOVE_LIGHT_TRANSLATE_X_OLD = 0
LOVE_LIGHT_TRANSLATE_Y_OLD = 0

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
	o.shadow2 = love.graphics.newCanvas()
	o.shine = love.graphics.newCanvas()
	o.normalMap = love.graphics.newCanvas()
	o.glowMap = love.graphics.newCanvas()
	o.glowMap2 = love.graphics.newCanvas()
	o.isGlowBlur = false
	o.pixelShadow = love.graphics.newCanvas()
	o.pixelShadow2 = love.graphics.newCanvas()
	o.shader = love.graphics.newShader("shader/poly_shadow.glsl")
	o.normalShader = love.graphics.newShader("shader/normal.glsl")
	o.changed = true
	o.blur = 2.0
	-- update
	o.update = function()
		LOVE_LIGHT_LAST_BUFFER = love.graphics.getCanvas()
		love.graphics.setShader(o.shader)

		if LOVE_LIGHT_TRANSLATE_X ~= LOVE_LIGHT_TRANSLATE_X_OLD or LOVE_LIGHT_TRANSLATE_Y ~= LOVE_LIGHT_TRANSLATE_Y_OLD then
			LOVE_LIGHT_TRANSLATE_X_OLD = LOVE_LIGHT_TRANSLATE_X
			LOVE_LIGHT_TRANSLATE_Y_OLD = LOVE_LIGHT_TRANSLATE_Y
			o.changed = true
		end

		if o.changed then
			love.graphics.setCanvas(o.shadow)
			o.shadow:clear(unpack(o.ambient))
			love.graphics.setBlendMode("additive")
		else
			love.graphics.setColor(255, 255, 255)
			love.graphics.setBlendMode("alpha")
		end

		local lightsOnScreen = 0
		LOVE_LIGHT_CIRCLE = o.circle
		LOVE_LIGHT_POLY = o.poly
		LOVE_LIGHT_IMAGE = o.img
		for i = 1, #o.lights do
			if o.lights[i].changed or o.changed then
				if  o.lights[i].x + o.lights[i].range > LOVE_LIGHT_TRANSLATE_X and o.lights[i].x - o.lights[i].range < love.graphics.getWidth() + LOVE_LIGHT_TRANSLATE_X
				and o.lights[i].y + o.lights[i].range > LOVE_LIGHT_TRANSLATE_Y and o.lights[i].y - o.lights[i].range < love.graphics.getHeight() + LOVE_LIGHT_TRANSLATE_Y
				then
					local lightposrange = {o.lights[i].x, love.graphics.getHeight() - o.lights[i].y, o.lights[i].range}
					LOVE_LIGHT_CURRENT = o.lights[i]
					o.shader:send("lightPositionRange", {o.lights[i].x - LOVE_LIGHT_TRANSLATE_X, love.graphics.getHeight() - (o.lights[i].y - LOVE_LIGHT_TRANSLATE_Y), o.lights[i].range})
					o.shader:send("lightColor", {o.lights[i].red / 255.0, o.lights[i].green / 255.0, o.lights[i].blue / 255.0})
					o.shader:send("smooth", o.lights[i].smooth)
					o.shader:send("glow", {1.0 - o.lights[i].glowSize, o.lights[i].glowStrength})

					if o.changed then
						love.graphics.setCanvas(o.shadow)
					else
						love.graphics.setCanvas(o.lights[i].shadow)
						love.graphics.clear()
					end

					-- draw shadow
					love.graphics.setInvertedStencil(shadowStencil)
					love.graphics.setBlendMode("additive")
					love.graphics.rectangle("fill", LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y, love.graphics.getWidth(), love.graphics.getHeight())

					-- draw shine
					love.graphics.setCanvas(o.lights[i].shine)
					o.lights[i].shine:clear(255, 255, 255)
					love.graphics.setBlendMode("alpha")
					love.graphics.setStencil(polyStencil)
					love.graphics.rectangle("fill", LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y, love.graphics.getWidth(), love.graphics.getHeight())

					lightsOnScreen = lightsOnScreen + 1

					o.lights[i].visible = true
				else
					o.lights[i].visible = false
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
			love.graphics.rectangle("fill", LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y, love.graphics.getWidth(), love.graphics.getHeight())
			love.graphics.setColor(255, 255, 255)
			love.graphics.setBlendMode("additive")
			for i = 1, #o.lights do
				if o.lights[i].visible then
					love.graphics.draw(o.lights[i].shadow, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
				end
			end
			o.isShadowBlur = false
		end

		-- update shine
		love.graphics.setCanvas(o.shine)
		love.graphics.setColor(unpack(o.ambient))
		love.graphics.setBlendMode("alpha")
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
		love.graphics.setColor(255, 255, 255)
		love.graphics.setBlendMode("additive")
		for i = 1, #o.lights do
			if o.lights[i].visible then
				love.graphics.draw(o.lights[i].shine, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
			end
		end

		-- update pixel shadow
		love.graphics.setColor(255, 255, 255)
		love.graphics.setBlendMode("alpha")

		-- create normal map
		if o.changed then
			o.normalMap:clear()
			love.graphics.setShader()
			love.graphics.setCanvas(o.normalMap)
			for i = 1, #o.img do
				if o.img[i].normal then
					love.graphics.setColor(255, 255, 255)
					love.graphics.draw(o.img[i].normal, o.img[i].x - o.img[i].ox2, o.img[i].y - o.img[i].oy2)
				else
					love.graphics.setColor(0, 0, 0, 0)
					love.graphics.rectangle("fill", o.img[i].x - o.img[i].ox2, o.img[i].y - o.img[i].oy2, o.img[i].imgWidth, o.img[i].imgHeight)
				end
			end
			love.graphics.setColor(255, 255, 255)
		end

		o.pixelShadow2:clear()
		love.graphics.setCanvas(o.pixelShadow2)
		love.graphics.setBlendMode("additive")
		love.graphics.setShader(o.shader2)

		for i = 1, #o.lights do
			if o.lights[i].visible then
				o.normalShader:send('screenResolution', {love.graphics.getWidth(), love.graphics.getHeight()})
				o.normalShader:send('lightColor', {o.lights[i].red / 255.0, o.lights[i].green / 255.0, o.lights[i].blue / 255.0})
				o.normalShader:send('lightPosition',{o.lights[i].x, love.graphics.getHeight() - o.lights[i].y, o.lights[i].z / 255.0})
				o.normalShader:send('lightRange',{o.lights[i].range})
				o.normalShader:send("lightSmooth", o.lights[i].smooth)
				love.graphics.setShader(o.normalShader)
				love.graphics.draw(o.normalMap, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
			end
		end

		love.graphics.setShader()
		o.pixelShadow:clear(255, 255, 255)
		love.graphics.setCanvas(o.pixelShadow)
		love.graphics.setBlendMode("alpha")
		love.graphics.draw(o.pixelShadow2, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
		love.graphics.setBlendMode("additive")
		love.graphics.setColor({o.ambient[1], o.ambient[2], o.ambient[3]})
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
		love.graphics.setBlendMode("alpha")

		-- create glow map
		if o.changed then
			o.glowMap:clear(0, 0, 0)
			love.graphics.setCanvas(o.glowMap)
			for i = 1, #o.img do
				if o.img[i].glow then
					love.graphics.setColor(255, 255, 255)
					love.graphics.draw(o.img[i].glow, o.img[i].x - o.img[i].ox2, o.img[i].y - o.img[i].oy2)
				else
					love.graphics.setColor(0, 0, 0)
					love.graphics.draw(o.img[i].img, o.img[i].x - o.img[i].ox2, o.img[i].y - o.img[i].oy2)
				end
			end
			o.isGlowBlur = false
		end

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
			LOVE_LIGHT_BLURV:send("steps", o.blur)
			LOVE_LIGHT_BLURH:send("steps", o.blur)
			love.graphics.setBlendMode("alpha")
			love.graphics.setCanvas(o.shadow2)
			love.graphics.setShader(LOVE_LIGHT_BLURV)
			love.graphics.draw(o.shadow, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
			love.graphics.setCanvas(o.shadow)
			love.graphics.setShader(LOVE_LIGHT_BLURH)
			love.graphics.draw(o.shadow2, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
			love.graphics.setCanvas(LOVE_LIGHT_LAST_BUFFER)
			love.graphics.setBlendMode("multiplicative")
			love.graphics.setShader()
			love.graphics.draw(o.shadow, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
			love.graphics.setBlendMode("alpha")
		else
			love.graphics.setBlendMode("multiplicative")
			love.graphics.setShader()
			love.graphics.draw(o.shadow, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
			love.graphics.setBlendMode("alpha")
		end
	end
	-- draw shine
	o.drawShine = function()
		love.graphics.setColor(255, 255, 255)
		love.graphics.setBlendMode("multiplicative")
		love.graphics.setShader()
		love.graphics.draw(o.shine, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
		love.graphics.setBlendMode("alpha")
	end
	-- draw pixel shadow
	o.drawPixelShadow = function()
		love.graphics.setColor(255, 255, 255)
		love.graphics.setBlendMode("multiplicative")
		love.graphics.setShader()
		love.graphics.draw(o.pixelShadow, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
		love.graphics.setBlendMode("alpha")
	end
	-- draw glow
	o.drawGlow = function()
		love.graphics.setColor(255, 255, 255)
		if o.isGlowBlur then
			love.graphics.setBlendMode("additive")
			love.graphics.setShader()
			love.graphics.draw(o.glowMap, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
			love.graphics.setBlendMode("alpha")
		else
			LOVE_LIGHT_BLURV:send("steps", 1.0)
			LOVE_LIGHT_BLURH:send("steps", 1.0)
			LOVE_LIGHT_LAST_BUFFER = love.graphics.getCanvas()
			love.graphics.setBlendMode("alpha")
			love.graphics.setCanvas(o.glowMap2)
			love.graphics.setShader(LOVE_LIGHT_BLURV)
			love.graphics.draw(o.glowMap, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
			love.graphics.setCanvas(o.glowMap)
			love.graphics.setShader(LOVE_LIGHT_BLURH)
			love.graphics.draw(o.glowMap2, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
			love.graphics.setCanvas(LOVE_LIGHT_LAST_BUFFER)
			love.graphics.setBlendMode("additive")
			love.graphics.setShader()
			love.graphics.draw(o.glowMap, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
			love.graphics.setBlendMode("alpha")

			o.isGlowBlur = true
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
		o.changed = true
	end
	-- clear objects
	o.clearObjects = function()
		o.poly = {}
		o.circle = {}
		o.img = {}
		o.changed = true
	end
	-- set offset
	o.setTranslation = function(translateX, translateY)
		LOVE_LIGHT_TRANSLATE_X = translateX
		LOVE_LIGHT_TRANSLATE_Y = translateY
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
	-- get polygon count
	o.getObjectCount = function()
		return #o.poly + #o.circle
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
	-- set light position
	o.setLightPosition = function(n, x, y)
		o.lights[n].setPosition(x, y)
	end
	-- set light x
	o.setLightX = function(n, x)
		o.lights[n].setX(x)
	end
	-- set light y
	o.setLightY = function(n, y)
		o.lights[n].setY(y)
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
	-- get type
	o.getType = function()
		return "world"
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
	o.z = 15
	o.red = red
	o.green = green
	o.blue = blue
	o.range = range
	o.smooth = 1.0
	o.glowSize = 0.1
	o.glowStrength = 0.0
	o.changed = true
	o.visible = true
	-- set position
	o.setPosition = function(x, y)
		if x ~= o.x or y ~= o.y then
			o.x = x
			o.y = y
			o.changed = true
		end
	end
	-- get x
	o.getX = function()
		return o.x
	end
	-- get y
	o.getY = function()
		return o.y
	end
	-- set x
	o.setX = function(x)
		if x ~= o.x then
			o.x = x
			o.changed = true
		end
	end
	-- set y
	o.setY = function(y)
		if y ~= o.y then
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
function love.light.newRectangle(p, x, y, width, height)
	local o = {}
	p.poly[#p.poly + 1] = o
	o.id = #p.poly
	o.x = x or 0
	o.y = y or 0
	o.width = width or 64
	o.height = height or 64
	o.ox = o.width / 2
	o.oy = o.height / 2
	o.shine = true
	o.type = "rectangle"
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
	-- set x
	o.setX = function(x)
		if x ~= o.x then
			o.x = x
			o.refresh()
			p.changed = true
		end
	end
	-- set y
	o.setY = function(y)
		if y ~= o.y then
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
	-- get x
	o.getX = function()
		return o.x
	end
	-- get y
	o.getY = function()
		return o.y
	end
	-- get width
	o.getWidth = function()
		return o.width
	end
	-- get height
	o.getHeight = function()
		return o.height
	end
	-- get rectangle data
	o.getPoints = function()
		return unpack(o.data)
	end
	-- get type
	o.getType = function()
		return o.type
	end

	return o
end

-- circle object
function love.light.newCircle(p, x, y, radius)
	local o = {}
	p.circle[#p.circle + 1] = o
	o.id = #p.circle
	o.x = x or 0
	o.y = y or 0
	o.radius = radius or 200
	o.shine = true
	o.type = "circle"
	p.changed = true
	-- set position
	o.setPosition = function(x, y)
		if x ~= o.x or y ~= o.y then
			o.x = x
			o.y = y
			p.changed = true
		end
	end
	-- set x
	o.setX = function(x)
		if x ~= o.x then
			o.x = x
			p.changed = true
		end
	end
	-- set y
	o.setY = function(y)
		if y ~= o.y then
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
		return o.type
	end

	return o
end

-- poly object
function love.light.newPolygon(p, ...)
	local o = {}
	p.poly[#p.poly + 1] = o
	o.id = #p.poly
	o.shine = true
	o.type = "polygon"
	p.changed = true
	if ... then
		o.data = {...}
	else
		o.data = {0, 0, 0, 0, 0, 0}
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
		return o.type
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
	o.glow = nil
	o.x = x or 0
	o.y = y or 0
	o.width = width or img:getWidth()
	o.height = height or img:getHeight()
	o.ox = o.width / 2.0
	o.oy = o.height / 2.0
	o.ox2 = ox or o.width / 2.0
	o.oy2 = oy or o.height / 2.0
	o.imgWidth = img:getWidth()
	o.imgHeight = img:getHeight()
	o.shine = true
	o.type = "image"
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
	-- set x position
	o.setX = function(x)
		if x ~= o.x then
			o.x = x
			o.refresh()
			p.changed = true
		end
	end
	-- set y position
	o.setY = function(y)
		if y ~= o.y then
			o.y = y
			o.refresh()
			p.changed = true
		end
	end
	-- get width
	o.getWidth = function()
		return o.width
	end
	-- get height
	o.getHeight = function()
		return o.height
	end
	-- get image width
	o.getImageWidth = function()
		return o.imgWidth
	end
	-- get image height
	o.getImageHeight = function()
		return o.imgHeight
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
	o.setNormalMap = function(normal)
		o.normal = normal
	end
	-- set height map
	o.setHeightMap = function(heightMap, strength)
		o.normal = HeightMapToNormalMap(heightMap, strength)
	end
	-- generate flat normal map
	o.generateNormalMapFlat = function(mode)
		local imgData = o.img:getData()
		local imgNormalData = love.image.newImageData(o.imgWidth, o.imgHeight)
		local color

		if mode == "top" then
			color = {127, 127, 255}
		elseif mode == "front" then
			color = {127, 255, 127}
		elseif mode == "back" then
			color = {127, 0, 127}
		elseif mode == "left" then
			color = {31, 255, 223}
		elseif mode == "right" then
			color = {223, 223, 127}
		end

		for i = 0, o.imgHeight - 1 do
			for k = 0, o.imgWidth - 1 do
				local r, g, b, a = imgData:getPixel(k, i)
				if a > 0 then
					imgNormalData:setPixel(k, i, color[1], color[2], color[3], 255)
				end
			end
		end

		o.normal = love.graphics.newImage(imgNormalData)
	end
	-- generate faded normal map
	o.generateNormalMapFade = function(horizontalFade, verticalFade)
		local imgData = o.img:getData()
		local imgNormalData = love.image.newImageData(o.imgWidth, o.imgHeight)
		local dx = 255.0 / o.imgWidth
		local dy = 255.0 / o.imgHeight
		local nx
		local ny
		local nz

		for i = 0, o.imgWidth - 1 do
			for k = 0, o.imgHeight - 1 do
				local r, g, b, a = imgData:getPixel(i, k)
				if a > 0 then
					if horizontalFade == "fade" then
						nx = i * dx
					elseif horizontalFade == "inverse" then
						nx = 255 - i * dx
					else
						nx = 127
					end

					if verticalFade == "fade" then
						ny = 127 + k * dy * 0.5
						nz = 255 - k * dy * 0.5
					elseif verticalFade == "inverse" then
						ny = 127 - k * dy * 0.5
						nz = 127 - k * dy * 0.25
					else
						ny = 255
						nz = 127
					end

					imgNormalData:setPixel(i, k, nx, ny, nz, 255)
				end
			end
		end

		o.normal = love.graphics.newImage(imgNormalData)
	end
	-- generate normal map
	o.generateNormalMap = function(strength)
		o.normal = HeightMapToNormalMap(o.img, strength)
	end
	-- set normal
	o.setGlowMap = function(glow)
		o.glow = glow
	end
	-- get type
	o.getType = function()
		return o.type
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
					curShadowGeometry[5] = curShadowGeometry[7] + lightVecBackFront[1] * shadowLength
					curShadowGeometry[6] = curShadowGeometry[8] + lightVecBackFront[2] * shadowLength
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
		local x2 = (v.x + math.sin(angle) * v.radius)
		local y2 = (v.y - math.cos(angle) * v.radius)
		local x3 = (v.x - math.sin(angle) * v.radius)
		local y3 = (v.y + math.cos(angle) * v.radius)

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
        love.graphics.circle("fill", LOVE_LIGHT_CIRCLE[i].x, LOVE_LIGHT_CIRCLE[i].y, LOVE_LIGHT_CIRCLE[i].radius)
	end
    for i = 1, #LOVE_LIGHT_IMAGE do
		--love.graphics.rectangle("fill", LOVE_LIGHT_IMAGE[i].x, LOVE_LIGHT_IMAGE[i].y, LOVE_LIGHT_IMAGE[i].width, LOVE_LIGHT_IMAGE[i].height)
    end
end

polyStencil = function()
    for i = 1, #LOVE_LIGHT_CIRCLE do
		if LOVE_LIGHT_CIRCLE[i].shine then
			love.graphics.circle("fill", LOVE_LIGHT_CIRCLE[i].x, LOVE_LIGHT_CIRCLE[i].y, LOVE_LIGHT_CIRCLE[i].radius)
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

function HeightMapToNormalMap(heightMap, strength)
	local imgData = heightMap:getData()
	local imgData2 = love.image.newImageData(heightMap:getWidth(), heightMap:getHeight())
	local red, green, blue, alpha
	local x, y
	local matrix = {}
	matrix[1] = {}
	matrix[2] = {}
	matrix[3] = {}
	strength = strength or 1.0

	for i = 0, heightMap:getHeight() - 1 do
		for k = 0, heightMap:getWidth() - 1 do
			for l = 1, 3 do
				for m = 1, 3 do
					if k + (l - 1) < 1 then
						x = heightMap:getWidth() - 1
					elseif k + (l - 1) > heightMap:getWidth() - 1 then
						x = 1
					else
						x = k + l - 1
					end

					if i + (m - 1) < 1 then
						y = heightMap:getHeight() - 1
					elseif i + (m - 1) > heightMap:getHeight() - 1 then
						y = 1
					else
						y = i + m - 1
					end

					local red, green, blue, alpha = imgData:getPixel(x, y)
					matrix[l][m] = red
				end
			end

			red = (255 + ((matrix[1][2] - matrix[2][2]) + (matrix[2][2] - matrix[3][2])) * strength) / 2.0
			green = (255 - ((matrix[2][2] - matrix[1][1]) + (matrix[2][3] - matrix[2][2])) * strength) / 2.0
			blue = 192

			imgData2:setPixel(k, i, red, green, blue)
		end
	end

	return love.graphics.newImage(imgData2)
end