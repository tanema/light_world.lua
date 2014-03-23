LOVE_POSTSHADER_BUFFER_RENDER = love.graphics.newCanvas()
LOVE_POSTSHADER_BUFFER_BACK = love.graphics.newCanvas()
LOVE_POSTSHADER_LAST_BUFFER = nil

LOVE_POSTSHADER_BLURV = love.graphics.newShader("shader/blurv.glsl")
LOVE_POSTSHADER_BLURH = love.graphics.newShader("shader/blurh.glsl")
LOVE_POSTSHADER_CONTRAST = love.graphics.newShader("shader/contrast.glsl")
LOVE_POSTSHADER_CHROMATIC_ABERRATION = love.graphics.newShader("shader/chromatic_aberration.glsl")

LOVE_POSTSHADER_BLURV:send("screen", {love.window.getWidth(), love.window.getHeight()})
LOVE_POSTSHADER_BLURH:send("screen", {love.window.getWidth(), love.window.getHeight()})

love.postshader = {}

love.postshader.setBuffer = function(path)
	if path == "back" then
		love.graphics.setCanvas(LOVE_POSTSHADER_BUFFER_BACK)
	else
		love.graphics.setCanvas(LOVE_POSTSHADER_BUFFER_RENDER)
	end
	LOVE_POSTSHADER_LAST_BUFFER = love.graphics.getCanvas()
end

love.postshader.addEffect = function(shader, ...)
	args = {...}
	LOVE_POSTSHADER_LAST_BUFFER = love.graphics.getCanvas()

	if shader == "bloom" then
		-- Bloom Shader
		LOVE_POSTSHADER_BLURV:send("steps", args[1] or 2.0)
		LOVE_POSTSHADER_BLURH:send("steps", args[1] or 2.0)
		love.graphics.setCanvas(LOVE_POSTSHADER_BUFFER_BACK)
		love.graphics.setBlendMode("alpha")

		love.graphics.setShader(LOVE_POSTSHADER_BLURV)
		love.graphics.draw(LOVE_POSTSHADER_BUFFER_RENDER)

		love.graphics.setShader(LOVE_POSTSHADER_BLURH)
		love.graphics.draw(LOVE_POSTSHADER_BUFFER_BACK)

		love.graphics.setShader(LOVE_POSTSHADER_CONTRAST)
		love.graphics.draw(LOVE_POSTSHADER_BUFFER_BACK)

		love.graphics.setCanvas(LOVE_POSTSHADER_LAST_BUFFER)
		love.graphics.setShader()
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(LOVE_POSTSHADER_BUFFER_RENDER)
		love.graphics.setBlendMode("additive")
		love.graphics.setColor(255, 255, 255, (args[2] or 0.25) * 255)
		love.graphics.draw(LOVE_POSTSHADER_BUFFER_BACK)
		love.graphics.setBlendMode("alpha")
	elseif shader == "blur" then
		-- Blur Shader
		LOVE_POSTSHADER_BLURV:send("steps", args[1] or 2.0)
		LOVE_POSTSHADER_BLURH:send("steps", args[2] or 2.0)
		love.graphics.setCanvas(LOVE_POSTSHADER_BUFFER_BACK)
		love.graphics.setBlendMode("alpha")

		love.graphics.setShader(LOVE_POSTSHADER_BLURV)
		love.graphics.draw(LOVE_POSTSHADER_BUFFER_RENDER)

		love.graphics.setShader(LOVE_POSTSHADER_BLURH)
		love.graphics.draw(LOVE_POSTSHADER_BUFFER_BACK)

		love.graphics.setCanvas(LOVE_POSTSHADER_LAST_BUFFER)
		love.graphics.setShader()
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(LOVE_POSTSHADER_BUFFER_BACK)
	elseif shader == "chromatic" then
		-- Blur Shader
		LOVE_POSTSHADER_CHROMATIC_ABERRATION:send("redStrength", {args[1] or 0.0, args[2] or 0.0})
		LOVE_POSTSHADER_CHROMATIC_ABERRATION:send("greenStrength", {args[3] or 0.0, args[4] or 0.0})
		LOVE_POSTSHADER_CHROMATIC_ABERRATION:send("blueStrength", {args[5] or 0.0, args[6] or 0.0})
		love.graphics.setCanvas(LOVE_POSTSHADER_BUFFER_BACK)
		love.graphics.setBlendMode("alpha")

		love.graphics.setShader(LOVE_POSTSHADER_CHROMATIC_ABERRATION)
		love.graphics.draw(LOVE_POSTSHADER_BUFFER_RENDER)

		love.graphics.setCanvas(LOVE_POSTSHADER_LAST_BUFFER)
		love.graphics.setShader()
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(LOVE_POSTSHADER_BUFFER_BACK)
	end
end

love.postshader.draw = function()
	if LOVE_POSTSHADER_LAST_BUFFER then
		love.graphics.setCanvas()
		love.graphics.setShader()
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(LOVE_POSTSHADER_LAST_BUFFER)
	end
end