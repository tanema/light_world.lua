--[[
The MIT License (MIT)

Copyright (c) 2014 Marcus Ihde

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
local _PACKAGE = (...):match("^(.+)[%./][^%./]+") or ""
local class = require(_PACKAGE..'/class')
local stencils = require(_PACKAGE..'/stencils')
local vector = require(_PACKAGE..'/vector')
local Light = require(_PACKAGE..'/light')
local Body = require(_PACKAGE..'/body')

LOVE_LIGHT_CURRENT = nil
LOVE_LIGHT_CIRCLE = nil
LOVE_LIGHT_POLY = nil
LOVE_LIGHT_IMAGE = nil
LOVE_LIGHT_BODY = nil
LOVE_LIGHT_LAST_BUFFER = nil
LOVE_LIGHT_SHADOW_GEOMETRY = nil

LOVE_LIGHT_BLURV = love.graphics.newShader("shader/blurv.glsl")
LOVE_LIGHT_BLURH = love.graphics.newShader("shader/blurh.glsl")
LOVE_LIGHT_BLURV:send("screen", {love.window.getWidth(), love.window.getHeight()})
LOVE_LIGHT_BLURH:send("screen", {love.window.getWidth(), love.window.getHeight()})

LOVE_LIGHT_TRANSLATE_X = 0
LOVE_LIGHT_TRANSLATE_Y = 0
LOVE_LIGHT_TRANSLATE_X_OLD = 0
LOVE_LIGHT_TRANSLATE_Y_OLD = 0
LOVE_LIGHT_DIRECTION = 0


love.light = {}

-- light world
function love.light.newWorld()
	local o = {}

	o.lights = {}
	o.ambient = {0, 0, 0}
	o.body = {}
	o.refraction = {}
	o.shadow = love.graphics.newCanvas()
	o.shadow2 = love.graphics.newCanvas()
	o.shine = love.graphics.newCanvas()
	o.shine2 = love.graphics.newCanvas()
	o.normalMap = love.graphics.newCanvas()
	o.glowMap = love.graphics.newCanvas()
	o.glowMap2 = love.graphics.newCanvas()
	o.refractionMap = love.graphics.newCanvas()
	o.refractionMap2 = love.graphics.newCanvas()
	o.reflectionMap = love.graphics.newCanvas()
	o.reflectionMap2 = love.graphics.newCanvas()
	o.normalInvert = false
	o.glowBlur = 1.0
	o.glowTimer = 0.0
	o.glowDown = false
	o.refractionStrength = 8.0
	o.pixelShadow = love.graphics.newCanvas()
	o.pixelShadow2 = love.graphics.newCanvas()
	o.shader = love.graphics.newShader("shader/poly_shadow.glsl")
	o.glowShader = love.graphics.newShader("shader/glow.glsl")
	o.normalShader = love.graphics.newShader("shader/normal.glsl")
	o.normalInvertShader = love.graphics.newShader("shader/normal_invert.glsl")
	o.materialShader = love.graphics.newShader("shader/material.glsl")
	o.refractionShader = love.graphics.newShader("shader/refraction.glsl")
	o.refractionShader:send("screen", {love.window.getWidth(), love.window.getHeight()})
	o.reflectionShader = love.graphics.newShader("shader/reflection.glsl")
	o.reflectionShader:send("screen", {love.window.getWidth(), love.window.getHeight()})
	o.reflectionStrength = 16.0
	o.reflectionVisibility = 1.0
	o.changed = true
	o.blur = 2.0
	o.optionShadows = true
	o.optionPixelShadows = true
	o.optionGlow = true
	o.optionRefraction = true
	o.optionReflection = true
	o.isShadows = false
	o.isLight = false
	o.isPixelShadows = false
	o.isGlow = false
	o.isRefraction = false
	o.isReflection = false

	-- update
	o.update = function()
		LOVE_LIGHT_LAST_BUFFER = love.graphics.getCanvas()

		if LOVE_LIGHT_TRANSLATE_X ~= LOVE_LIGHT_TRANSLATE_X_OLD or LOVE_LIGHT_TRANSLATE_Y ~= LOVE_LIGHT_TRANSLATE_Y_OLD then
			LOVE_LIGHT_TRANSLATE_X_OLD = LOVE_LIGHT_TRANSLATE_X
			LOVE_LIGHT_TRANSLATE_Y_OLD = LOVE_LIGHT_TRANSLATE_Y
			o.changed = true
		end

		love.graphics.setColor(255, 255, 255)
		love.graphics.setBlendMode("alpha")

		if o.optionShadows and (o.isShadows or o.isLight) then
			love.graphics.setShader(o.shader)

			local lightsOnScreen = 0
			LOVE_LIGHT_BODY = o.body
			for i = 1, #o.lights do
				if o.lights[i].changed or o.changed then
					if o.lights[i].x + o.lights[i].range > LOVE_LIGHT_TRANSLATE_X and o.lights[i].x - o.lights[i].range < love.graphics.getWidth() + LOVE_LIGHT_TRANSLATE_X
						and o.lights[i].y + o.lights[i].range > LOVE_LIGHT_TRANSLATE_Y and o.lights[i].y - o.lights[i].range < love.graphics.getHeight() + LOVE_LIGHT_TRANSLATE_Y
					then
						local lightposrange = {o.lights[i].x, love.graphics.getHeight() - o.lights[i].y, o.lights[i].range}
						LOVE_LIGHT_CURRENT = o.lights[i]
						LOVE_LIGHT_DIRECTION = LOVE_LIGHT_DIRECTION + 0.002
						o.shader:send("lightPosition", {o.lights[i].x - LOVE_LIGHT_TRANSLATE_X, love.graphics.getHeight() - (o.lights[i].y - LOVE_LIGHT_TRANSLATE_Y), o.lights[i].z})
						o.shader:send("lightRange", o.lights[i].range)
						o.shader:send("lightColor", {o.lights[i].red / 255.0, o.lights[i].green / 255.0, o.lights[i].blue / 255.0})
						o.shader:send("lightSmooth", o.lights[i].smooth)
						o.shader:send("lightGlow", {1.0 - o.lights[i].glowSize, o.lights[i].glowStrength})
						o.shader:send("lightAngle", math.pi - o.lights[i].angle / 2.0)
						o.shader:send("lightDirection", o.lights[i].direction)

						love.graphics.setCanvas(o.lights[i].shadow)
						love.graphics.clear()

						-- calculate shadows
						LOVE_LIGHT_SHADOW_GEOMETRY = calculateShadows(LOVE_LIGHT_CURRENT, LOVE_LIGHT_BODY)

						-- draw shadow
						love.graphics.setInvertedStencil(stencils.shadow(LOVE_LIGHT_SHADOW_GEOMETRY, LOVE_LIGHT_BODY))
						love.graphics.setBlendMode("additive")
						love.graphics.rectangle("fill", LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y, love.graphics.getWidth(), love.graphics.getHeight())

						-- draw color shadows
						love.graphics.setBlendMode("multiplicative")
						love.graphics.setShader()
						for k = 1,#LOVE_LIGHT_SHADOW_GEOMETRY do
							if LOVE_LIGHT_SHADOW_GEOMETRY[k].alpha < 1.0 then
								love.graphics.setColor(
									LOVE_LIGHT_SHADOW_GEOMETRY[k].red * (1.0 - LOVE_LIGHT_SHADOW_GEOMETRY[k].alpha),
									LOVE_LIGHT_SHADOW_GEOMETRY[k].green * (1.0 - LOVE_LIGHT_SHADOW_GEOMETRY[k].alpha),
									LOVE_LIGHT_SHADOW_GEOMETRY[k].blue * (1.0 - LOVE_LIGHT_SHADOW_GEOMETRY[k].alpha)
								)
								love.graphics.polygon("fill", unpack(LOVE_LIGHT_SHADOW_GEOMETRY[k]))
							end
						end

						for k = 1, #LOVE_LIGHT_BODY do
							if LOVE_LIGHT_BODY[k].alpha < 1.0 then
								love.graphics.setBlendMode("multiplicative")
								love.graphics.setColor(LOVE_LIGHT_BODY[k].red, LOVE_LIGHT_BODY[k].green, LOVE_LIGHT_BODY[k].blue)
								if LOVE_LIGHT_BODY[k].shadowType == "circle" then
									love.graphics.circle("fill", LOVE_LIGHT_BODY[k].x - LOVE_LIGHT_BODY[k].ox, LOVE_LIGHT_BODY[k].y - LOVE_LIGHT_BODY[k].oy, LOVE_LIGHT_BODY[k].radius)
								elseif LOVE_LIGHT_BODY[k].shadowType == "rectangle" then
									love.graphics.rectangle("fill", LOVE_LIGHT_BODY[k].x - LOVE_LIGHT_BODY[k].ox, LOVE_LIGHT_BODY[k].y - LOVE_LIGHT_BODY[k].oy, LOVE_LIGHT_BODY[k].width, LOVE_LIGHT_BODY[k].height)
								elseif LOVE_LIGHT_BODY[k].shadowType == "polygon" then
									love.graphics.polygon("fill", unpack(LOVE_LIGHT_BODY[k].data))
								end
							end

							if LOVE_LIGHT_BODY[k].shadowType == "image" and LOVE_LIGHT_BODY[k].img then
								love.graphics.setBlendMode("alpha")
								local length = 1.0
								local shadowRotation = math.atan2((LOVE_LIGHT_BODY[k].x) - o.lights[i].x, (LOVE_LIGHT_BODY[k].y + LOVE_LIGHT_BODY[k].oy) - o.lights[i].y)
								--local alpha = math.abs(math.cos(shadowRotation))

								LOVE_LIGHT_BODY[k].shadowVert = {
									{math.sin(shadowRotation) * LOVE_LIGHT_BODY[k].imgHeight * length, (length * math.cos(shadowRotation) + 1.0) * LOVE_LIGHT_BODY[k].imgHeight + (math.cos(shadowRotation) + 1.0) * LOVE_LIGHT_BODY[k].shadowY, 0, 0, LOVE_LIGHT_BODY[k].red, LOVE_LIGHT_BODY[k].green, LOVE_LIGHT_BODY[k].blue, LOVE_LIGHT_BODY[k].alpha * LOVE_LIGHT_BODY[k].fadeStrength * 255},
									{LOVE_LIGHT_BODY[k].imgWidth + math.sin(shadowRotation) * LOVE_LIGHT_BODY[k].imgHeight * length, (length * math.cos(shadowRotation) + 1.0) * LOVE_LIGHT_BODY[k].imgHeight + (math.cos(shadowRotation) + 1.0) * LOVE_LIGHT_BODY[k].shadowY, 1, 0, LOVE_LIGHT_BODY[k].red, LOVE_LIGHT_BODY[k].green, LOVE_LIGHT_BODY[k].blue, LOVE_LIGHT_BODY[k].alpha * LOVE_LIGHT_BODY[k].fadeStrength * 255},
									{LOVE_LIGHT_BODY[k].imgWidth, LOVE_LIGHT_BODY[k].imgHeight + (math.cos(shadowRotation) + 1.0) * LOVE_LIGHT_BODY[k].shadowY, 1, 1, LOVE_LIGHT_BODY[k].red, LOVE_LIGHT_BODY[k].green, LOVE_LIGHT_BODY[k].blue, LOVE_LIGHT_BODY[k].alpha * 255},
									{0, LOVE_LIGHT_BODY[k].imgHeight + (math.cos(shadowRotation) + 1.0) * LOVE_LIGHT_BODY[k].shadowY, 0, 1, LOVE_LIGHT_BODY[k].red, LOVE_LIGHT_BODY[k].green, LOVE_LIGHT_BODY[k].blue, LOVE_LIGHT_BODY[k].alpha * 255}
								}

								LOVE_LIGHT_BODY[k].shadowMesh:setVertices(LOVE_LIGHT_BODY[k].shadowVert)
								love.graphics.draw(LOVE_LIGHT_BODY[k].shadowMesh, LOVE_LIGHT_BODY[k].x - LOVE_LIGHT_BODY[k].ox + LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_BODY[k].y - LOVE_LIGHT_BODY[k].oy + LOVE_LIGHT_TRANSLATE_Y)
							end
						end

						love.graphics.setShader(o.shader)

						-- draw shine
						love.graphics.setCanvas(o.lights[i].shine)
						o.lights[i].shine:clear(255, 255, 255)
						love.graphics.setBlendMode("alpha")
						love.graphics.setStencil(stencils.poly(LOVE_LIGHT_BODY))
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

			-- update shine
			love.graphics.setCanvas(o.shine)
			love.graphics.setColor(unpack(o.ambient))
			love.graphics.setBlendMode("alpha")
			love.graphics.rectangle("fill", LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y, love.graphics.getWidth(), love.graphics.getHeight())
			love.graphics.setColor(255, 255, 255)
			love.graphics.setBlendMode("additive")
			for i = 1, #o.lights do
				if o.lights[i].visible then
					love.graphics.draw(o.lights[i].shine, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
				end
			end
		end

		if o.optionPixelShadows and o.isPixelShadows then
			-- update pixel shadow
			love.graphics.setBlendMode("alpha")

			-- create normal map
			o.normalMap:clear()
			love.graphics.setShader()
			love.graphics.setCanvas(o.normalMap)
			for i = 1, #o.body do
				if o.body[i].type == "image" and o.body[i].normalMesh then
					love.graphics.setColor(255, 255, 255)
					love.graphics.draw(o.body[i].normalMesh, o.body[i].x - o.body[i].nx + LOVE_LIGHT_TRANSLATE_X, o.body[i].y - o.body[i].ny + LOVE_LIGHT_TRANSLATE_Y)
				end
			end
			love.graphics.setColor(255, 255, 255)
			love.graphics.setBlendMode("alpha")

			o.pixelShadow2:clear()
			love.graphics.setCanvas(o.pixelShadow2)
			love.graphics.setBlendMode("additive")
			love.graphics.setShader(o.shader2)

			for i = 1, #o.lights do
				if o.lights[i].visible then
					if o.normalInvert then
						o.normalInvertShader:send('screenResolution', {love.graphics.getWidth(), love.graphics.getHeight()})
						o.normalInvertShader:send('lightColor', {o.lights[i].red / 255.0, o.lights[i].green / 255.0, o.lights[i].blue / 255.0})
						o.normalInvertShader:send('lightPosition',{o.lights[i].x, love.graphics.getHeight() - o.lights[i].y, o.lights[i].z / 255.0})
						o.normalInvertShader:send('lightRange',{o.lights[i].range})
						o.normalInvertShader:send("lightSmooth", o.lights[i].smooth)
						o.normalInvertShader:send("lightAngle", math.pi - o.lights[i].angle / 2.0)
						o.normalInvertShader:send("lightDirection", o.lights[i].direction)
						love.graphics.setShader(o.normalInvertShader)
					else
						o.normalShader:send('screenResolution', {love.graphics.getWidth(), love.graphics.getHeight()})
						o.normalShader:send('lightColor', {o.lights[i].red / 255.0, o.lights[i].green / 255.0, o.lights[i].blue / 255.0})
						o.normalShader:send('lightPosition',{o.lights[i].x, love.graphics.getHeight() - o.lights[i].y, o.lights[i].z / 255.0})
						o.normalShader:send('lightRange',{o.lights[i].range})
						o.normalShader:send("lightSmooth", o.lights[i].smooth)
						o.normalShader:send("lightAngle", math.pi - o.lights[i].angle / 2.0)
						o.normalShader:send("lightDirection", o.lights[i].direction)
						love.graphics.setShader(o.normalShader)
					end
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
			love.graphics.rectangle("fill", LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y, love.graphics.getWidth(), love.graphics.getHeight())
			love.graphics.setBlendMode("alpha")
		end

		if o.optionGlow and o.isGlow then
			-- create glow map
			o.glowMap:clear(0, 0, 0)
			love.graphics.setCanvas(o.glowMap)

			if o.glowDown then
				o.glowTimer = math.max(0.0, o.glowTimer - love.timer.getDelta())
				if o.glowTimer == 0.0 then
					o.glowDown = not o.glowDown
				end
			else
				o.glowTimer = math.min(o.glowTimer + love.timer.getDelta(), 1.0)
				if o.glowTimer == 1.0 then
					o.glowDown = not o.glowDown
				end
			end

			for i = 1, #o.body do
				if o.body[i].glowStrength > 0.0 then
					love.graphics.setColor(o.body[i].glowRed * o.body[i].glowStrength, o.body[i].glowGreen * o.body[i].glowStrength, o.body[i].glowBlue * o.body[i].glowStrength)
				else
					love.graphics.setColor(0, 0, 0)
				end

				if o.body[i].type == "circle" then
					love.graphics.circle("fill", o.body[i].x, o.body[i].y, o.body[i].radius)
				elseif o.body[i].type == "rectangle" then
					love.graphics.rectangle("fill", o.body[i].x, o.body[i].y, o.body[i].width, o.body[i].height)
				elseif o.body[i].type == "polygon" then
					love.graphics.polygon("fill", unpack(o.body[i].data))
				elseif o.body[i].type == "image" and o.body[i].img then
					if o.body[i].glowStrength > 0.0 and o.body[i].glow then
						love.graphics.setShader(o.glowShader)
						o.glowShader:send("glowImage", o.body[i].glow)
						o.glowShader:send("glowTime", love.timer.getTime() * 0.5)
						love.graphics.setColor(255, 255, 255)
					else
						love.graphics.setShader()
						love.graphics.setColor(0, 0, 0)
					end
					love.graphics.draw(o.body[i].img, o.body[i].x - o.body[i].ix + LOVE_LIGHT_TRANSLATE_X, o.body[i].y - o.body[i].iy + LOVE_LIGHT_TRANSLATE_Y)
				end
			end
		end

		if o.optionRefraction and o.isRefraction then
			love.graphics.setShader()

			-- create refraction map
			o.refractionMap:clear()
			love.graphics.setCanvas(o.refractionMap)
			for i = 1, #o.body do
				if o.body[i].refraction and o.body[i].normal then
					love.graphics.setColor(255, 255, 255)
					if o.body[i].tileX == 0.0 and o.body[i].tileY == 0.0 then
						love.graphics.draw(normal, o.body[i].x - o.body[i].nx + LOVE_LIGHT_TRANSLATE_X, o.body[i].y - o.body[i].ny + LOVE_LIGHT_TRANSLATE_Y)
					else
						o.body[i].normalMesh:setVertices(o.body[i].normalVert)
						love.graphics.draw(o.body[i].normalMesh, o.body[i].x - o.body[i].nx + LOVE_LIGHT_TRANSLATE_X, o.body[i].y - o.body[i].ny + LOVE_LIGHT_TRANSLATE_Y)
					end
				end
			end

			love.graphics.setColor(0, 0, 0)
			for i = 1, #o.body do
				if not o.body[i].refractive then
					if o.body[i].type == "circle" then
						love.graphics.circle("fill", o.body[i].x, o.body[i].y, o.body[i].radius)
					elseif o.body[i].type == "rectangle" then
						love.graphics.rectangle("fill", o.body[i].x, o.body[i].y, o.body[i].width, o.body[i].height)
					elseif o.body[i].type == "polygon" then
						love.graphics.polygon("fill", unpack(o.body[i].data))
					elseif o.body[i].type == "image" and o.body[i].img then
						love.graphics.draw(o.body[i].img, o.body[i].x - o.body[i].ix + LOVE_LIGHT_TRANSLATE_X, o.body[i].y - o.body[i].iy + LOVE_LIGHT_TRANSLATE_Y)
					end
				end
			end
		end

		if o.optionReflection and o.isReflection then
			-- create reflection map
			if o.changed then
				o.reflectionMap:clear(0, 0, 0)
				love.graphics.setCanvas(o.reflectionMap)
				for i = 1, #o.body do
					if o.body[i].reflection and o.body[i].normal then
						love.graphics.setColor(255, 0, 0)
						o.body[i].normalMesh:setVertices(o.body[i].normalVert)
						love.graphics.draw(o.body[i].normalMesh, o.body[i].x - o.body[i].nx + LOVE_LIGHT_TRANSLATE_X, o.body[i].y - o.body[i].ny + LOVE_LIGHT_TRANSLATE_Y)
					end
				end
				for i = 1, #o.body do
					if o.body[i].reflective and o.body[i].img then
						love.graphics.setColor(0, 255, 0)
						love.graphics.draw(o.body[i].img, o.body[i].x - o.body[i].ix + LOVE_LIGHT_TRANSLATE_X, o.body[i].y - o.body[i].iy + LOVE_LIGHT_TRANSLATE_Y)
					elseif not o.body[i].reflection and o.body[i].img then
						love.graphics.setColor(0, 0, 0)
						love.graphics.draw(o.body[i].img, o.body[i].x - o.body[i].ix + LOVE_LIGHT_TRANSLATE_X, o.body[i].y - o.body[i].iy + LOVE_LIGHT_TRANSLATE_Y)
					end
				end
			end
		end

		love.graphics.setShader()
		love.graphics.setBlendMode("alpha")
		love.graphics.setStencil()
		love.graphics.setCanvas(LOVE_LIGHT_LAST_BUFFER)

		o.changed = false
	end
	o.refreshScreenSize = function()
		o.shadow = love.graphics.newCanvas()
		o.shadow2 = love.graphics.newCanvas()
		o.shine = love.graphics.newCanvas()
		o.shine2 = love.graphics.newCanvas()
		o.normalMap = love.graphics.newCanvas()
		o.glowMap = love.graphics.newCanvas()
		o.glowMap2 = love.graphics.newCanvas()
		o.refractionMap = love.graphics.newCanvas()
		o.refractionMap2 = love.graphics.newCanvas()
		o.reflectionMap = love.graphics.newCanvas()
		o.reflectionMap2 = love.graphics.newCanvas()
		o.pixelShadow = love.graphics.newCanvas()
		o.pixelShadow2 = love.graphics.newCanvas()
	end
	-- draw shadow
	o.drawShadow = function()
		if o.optionShadows and (o.isShadows or o.isLight) then
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
	end
	-- draw shine
	o.drawShine = function()
		if o.optionShadows and o.isShadows then
			love.graphics.setColor(255, 255, 255)
			if o.blur and false then
				LOVE_LIGHT_LAST_BUFFER = love.graphics.getCanvas()
				LOVE_LIGHT_BLURV:send("steps", o.blur)
				LOVE_LIGHT_BLURH:send("steps", o.blur)
				love.graphics.setBlendMode("alpha")
				love.graphics.setCanvas(o.shine2)
				love.graphics.setShader(LOVE_LIGHT_BLURV)
				love.graphics.draw(o.shine, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
				love.graphics.setCanvas(o.shine)
				love.graphics.setShader(LOVE_LIGHT_BLURH)
				love.graphics.draw(o.shine2, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
				love.graphics.setCanvas(LOVE_LIGHT_LAST_BUFFER)
				love.graphics.setBlendMode("multiplicative")
				love.graphics.setShader()
				love.graphics.draw(o.shine, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
				love.graphics.setBlendMode("alpha")
			else
				love.graphics.setBlendMode("multiplicative")
				love.graphics.setShader()
				love.graphics.draw(o.shine, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
				love.graphics.setBlendMode("alpha")
			end
		end
	end
	-- draw pixel shadow
	o.drawPixelShadow = function()
		if o.optionPixelShadows and o.isPixelShadows then
			love.graphics.setColor(255, 255, 255)
			love.graphics.setBlendMode("multiplicative")
			love.graphics.setShader()
			love.graphics.draw(o.pixelShadow, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
			love.graphics.setBlendMode("alpha")
		end
	end
	-- draw material
	o.drawMaterial = function()
		love.graphics.setShader(o.materialShader)
		for i = 1, #o.body do
			if o.body[i].material and o.body[i].normal then
				love.graphics.setColor(255, 255, 255)
				o.materialShader:send("material", o.body[i].material)
				love.graphics.draw(o.body[i].normal, o.body[i].x - o.body[i].nx + LOVE_LIGHT_TRANSLATE_X, o.body[i].y - o.body[i].ny + LOVE_LIGHT_TRANSLATE_Y)
			end
		end
		love.graphics.setShader()
	end
	-- draw glow
	o.drawGlow = function()
		if o.optionGlow and o.isGlow then
			love.graphics.setColor(255, 255, 255)
			if o.glowBlur == 0.0 then
				love.graphics.setBlendMode("additive")
				love.graphics.setShader()
				love.graphics.draw(o.glowMap, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
				love.graphics.setBlendMode("alpha")
			else
				LOVE_LIGHT_BLURV:send("steps", o.glowBlur)
				LOVE_LIGHT_BLURH:send("steps", o.glowBlur)
				LOVE_LIGHT_LAST_BUFFER = love.graphics.getCanvas()
				love.graphics.setBlendMode("additive")
				o.glowMap2:clear()
				love.graphics.setCanvas(o.glowMap2)
				love.graphics.setShader(LOVE_LIGHT_BLURV)
				love.graphics.draw(o.glowMap, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
				love.graphics.setCanvas(o.glowMap)
				love.graphics.setShader(LOVE_LIGHT_BLURH)
				love.graphics.draw(o.glowMap2, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
				love.graphics.setCanvas(LOVE_LIGHT_LAST_BUFFER)
				love.graphics.setShader()
				love.graphics.draw(o.glowMap, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
				love.graphics.setBlendMode("alpha")
			end
		end
	end
	-- draw refraction
	o.drawRefraction = function()
		if o.optionRefraction and o.isRefraction then
			LOVE_LIGHT_LAST_BUFFER = love.graphics.getCanvas()
			if LOVE_LIGHT_LAST_BUFFER then
				love.graphics.setColor(255, 255, 255)
				love.graphics.setBlendMode("alpha")
				love.graphics.setCanvas(o.refractionMap2)
				love.graphics.draw(LOVE_LIGHT_LAST_BUFFER, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
				love.graphics.setCanvas(LOVE_LIGHT_LAST_BUFFER)
				o.refractionShader:send("backBuffer", o.refractionMap2)
				o.refractionShader:send("refractionStrength", o.refractionStrength)
				love.graphics.setShader(o.refractionShader)
				love.graphics.draw(o.refractionMap, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
				love.graphics.setShader()
			end
		end
	end
	-- draw reflection
	o.drawReflection = function()
		if o.optionReflection and o.isReflection then
			LOVE_LIGHT_LAST_BUFFER = love.graphics.getCanvas()
			if LOVE_LIGHT_LAST_BUFFER then
				love.graphics.setColor(255, 255, 255)
				love.graphics.setBlendMode("alpha")
				love.graphics.setCanvas(o.reflectionMap2)
				love.graphics.draw(LOVE_LIGHT_LAST_BUFFER, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
				love.graphics.setCanvas(LOVE_LIGHT_LAST_BUFFER)
				o.reflectionShader:send("backBuffer", o.reflectionMap2)
				o.reflectionShader:send("reflectionStrength", o.reflectionStrength)
				o.reflectionShader:send("reflectionVisibility", o.reflectionVisibility)
				love.graphics.setShader(o.reflectionShader)
				love.graphics.draw(o.reflectionMap, LOVE_LIGHT_TRANSLATE_X, LOVE_LIGHT_TRANSLATE_Y)
				love.graphics.setShader()
			end
		end
	end
	-- new light
	o.newLight = function(x, y, red, green, blue, range)
		o.lights[#o.lights + 1] = Light(o, x, y, red, green, blue, range)
    o.isLight = true
		return o.lights[#o.lights]
	end
	-- clear lights
	o.clearLights = function()
		o.lights = {}
		o.isLight = false
		o.changed = true
	end
	-- clear objects
	o.clearBodys = function()
		o.body = {}
		o.changed = true
		o.isShadows = false
		o.isPixelShadows = false
		o.isGlow = false
		o.isRefraction = false
		o.isReflection = false
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
	-- set normal invert
	o.setNormalInvert = function(invert)
		o.normalInvert = invert
	end
	-- set blur
	o.setBlur = function(blur)
		o.blur = blur
		o.changed = true
	end
	-- set blur
	o.setShadowBlur = function(blur)
		o.blur = blur
		o.changed = true
	end
	-- set buffer
	o.setBuffer = function(buffer)
		if buffer == "render" then
			love.graphics.setCanvas(LOVE_LIGHT_LAST_BUFFER)
		else
			LOVE_LIGHT_LAST_BUFFER = love.graphics.getCanvas()
		end

		if buffer == "glow" then
			love.graphics.setCanvas(o.glowMap)
		end
	end
	-- set glow blur
	o.setGlowStrength = function(strength)
		o.glowBlur = strength
		o.changed = true
	end
	-- set refraction blur
	o.setRefractionStrength = function(strength)
		o.refractionStrength = strength
	end
	-- set reflection strength
	o.setReflectionStrength = function(strength)
		o.reflectionStrength = strength
	end
	-- set reflection visibility
	o.setReflectionVisibility = function(visibility)
		o.reflectionVisibility = visibility
	end
	-- new rectangle
	o.newRectangle = function(x, y, w, h)
	  return o.newBody("rectangle", x, y, width, height)
	end
	-- new circle
	o.newCircle = function(x, y, r)
	  return o.newBody("circle", x, y, radius)
	end
	-- new polygon
	o.newPolygon = function(...)
	  return o.newBody("polygon", ...)
	end
	-- new image
	o.newImage = function(img, x, y, width, height, ox, oy)
	  return o.newBody("image", img, x, y, width, height, ox, oy)
	end
	-- new refraction
	o.newRefraction = function(normal, x, y, width, height)
	  return o.newBody("refraction", normal, x, y, width, height)
	end
	-- new refraction from height map
	o.newRefractionHeightMap = function(heightMap, x, y, strength)
    local normal = HeightMapToNormalMap(heightMap, strength)
    return o.newRefraction(p, normal, x, y)
	end
	-- new reflection
	o.newReflection = function(normal, x, y, width, height)
	  return o.newBody("reflection", normal, x, y, width, height)
	end
	-- new reflection from height map
	o.newReflectionHeightMap = function(heightMap, x, y, strength)
    local normal = HeightMapToNormalMap(heightMap, strength)
    return o.newReflection(p, normal, x, y)
	end
	-- new body
	o.newBody = function(type, ...)
    local id = #o.body + 1
    o.body[id] = Body(o, id, type, ...)
    o.changed = true
		return o.body[#o.body]
	end
	-- set polygon data
	o.setPoints = function(n, ...)
		o.body[n].data = {...}
	end
	-- get polygon count
	o.getBodyCount = function()
		return #o.body
	end
	-- get polygon
	o.getPoints = function(n)
		if o.body[n].data then
			return unpack(o.body[n].data)
		end
	end
	-- set light position
	o.setLightPosition = function(n, x, y, z)
		o.lights[n]:setPosition(x, y, z)
	end
	-- set light x
	o.setLightX = function(n, x)
		o.lights[n]:setX(x)
	end
	-- set light y
	o.setLightY = function(n, y)
		o.lights[n]:setY(y)
	end
	-- set light angle
	o.setLightAngle = function(n, angle)
		o.lights[n]:setAngle(angle)
	end
	-- set light direction
	o.setLightDirection = function(n, direction)
		o.lights[n]:setDirection(direction)
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

function calculateShadows(light, body)
	local shadowGeometry = {}
	local shadowLength = 100000

	for i = 1, #body do
		if body[i].shadowType == "rectangle" or body[i].shadowType == "polygon" then
			curPolygon = body[i].data
			if not body[i].castsNoShadow then
				local edgeFacingTo = {}
				for k = 1, #curPolygon, 2 do
					local indexOfNextVertex = (k + 2) % #curPolygon
					local normal = {-curPolygon[indexOfNextVertex+1] + curPolygon[k + 1], curPolygon[indexOfNextVertex] - curPolygon[k]}
					local lightToPoint = {curPolygon[k] - light.x, curPolygon[k + 1] - light.y}

					normal = vector.normalize(normal)
					lightToPoint = vector.normalize(lightToPoint)

					local dotProduct = vector.dot(normal, lightToPoint)
					if dotProduct > 0 then table.insert(edgeFacingTo, true)
					else table.insert(edgeFacingTo, false) end
				end

				local curShadowGeometry = {}
				for k = 1, #edgeFacingTo do
					local nextIndex = (k + 1) % #edgeFacingTo
					if nextIndex == 0 then nextIndex = #edgeFacingTo end
					if edgeFacingTo[k] and not edgeFacingTo[nextIndex] then
						curShadowGeometry[1] = curPolygon[nextIndex*2-1]
						curShadowGeometry[2] = curPolygon[nextIndex*2]

						local lightVecFrontBack = vector.normalize({curPolygon[nextIndex*2-1] - light.x, curPolygon[nextIndex*2] - light.y})
						curShadowGeometry[3] = curShadowGeometry[1] + lightVecFrontBack[1] * shadowLength
						curShadowGeometry[4] = curShadowGeometry[2] + lightVecFrontBack[2] * shadowLength

					elseif not edgeFacingTo[k] and edgeFacingTo[nextIndex] then
						curShadowGeometry[7] = curPolygon[nextIndex*2-1]
						curShadowGeometry[8] = curPolygon[nextIndex*2]

						local lightVecBackFront = vector.normalize({curPolygon[nextIndex*2-1] - light.x, curPolygon[nextIndex*2] - light.y})
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
					curShadowGeometry.alpha = body[i].alpha
					curShadowGeometry.red = body[i].red
					curShadowGeometry.green = body[i].green
					curShadowGeometry.blue = body[i].blue
					shadowGeometry[#shadowGeometry + 1] = curShadowGeometry
				end
			end
		elseif body[i].shadowType == "circle" then
			if not body[i].castsNoShadow then
				local length = math.sqrt(math.pow(light.x - (body[i].x - body[i].ox), 2) + math.pow(light.y - (body[i].y - body[i].oy), 2))
				if length >= body[i].radius and length <= light.range then
					local curShadowGeometry = {}
					local angle = math.atan2(light.x - (body[i].x - body[i].ox), (body[i].y - body[i].oy) - light.y) + math.pi / 2
					local x2 = ((body[i].x - body[i].ox) + math.sin(angle) * body[i].radius)
					local y2 = ((body[i].y - body[i].oy) - math.cos(angle) * body[i].radius)
					local x3 = ((body[i].x - body[i].ox) - math.sin(angle) * body[i].radius)
					local y3 = ((body[i].y - body[i].oy) + math.cos(angle) * body[i].radius)

					curShadowGeometry[1] = x2
					curShadowGeometry[2] = y2
					curShadowGeometry[3] = x3
					curShadowGeometry[4] = y3

					curShadowGeometry[5] = x3 - (light.x - x3) * shadowLength
					curShadowGeometry[6] = y3 - (light.y - y3) * shadowLength
					curShadowGeometry[7] = x2 - (light.x - x2) * shadowLength
					curShadowGeometry[8] = y2 - (light.y - y2) * shadowLength
					curShadowGeometry.alpha = body[i].alpha
					curShadowGeometry.red = body[i].red
					curShadowGeometry.green = body[i].green
					curShadowGeometry.blue = body[i].blue
					shadowGeometry[#shadowGeometry + 1] = curShadowGeometry
				end
			end
		end
	end

	return shadowGeometry
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
			green = (255 + ((matrix[2][2] - matrix[1][1]) + (matrix[2][3] - matrix[2][2])) * strength) / 2.0
			blue = 192

			imgData2:setPixel(k, i, red, green, blue)
		end
	end

	return love.graphics.newImage(imgData2)
end
