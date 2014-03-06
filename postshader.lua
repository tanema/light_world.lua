LOVE_POSTSHADER_BUFFER_RENDER = love.graphics.newCanvas()
LOVE_POSTSHADER_BUFFER_BACK = love.graphics.newCanvas()
LOVE_POSTSHADER_LAST_BUFFER = nil

LOVE_POSTSHADER_BLURV = love.graphics.newShader("shader/blurv.glsl")
LOVE_POSTSHADER_BLURH = love.graphics.newShader("shader/blurh.glsl")
LOVE_POSTSHADER_CONTRAST = love.graphics.newShader("shader/contrast.glsl")

LOVE_POSTSHADER_BLURV:send("screen", {love.window.getWidth(), love.window.getHeight()})
LOVE_POSTSHADER_BLURH:send("screen", {love.window.getWidth(), love.window.getHeight()})

love.postshader = {}

love.postshader.setBuffer = function(path)
	if path == "back" then
		love.graphics.setCanvas(LOVE_POSTSHADER_BUFFER_BACK)
	else
		love.graphics.setCanvas(LOVE_POSTSHADER_BUFFER_RENDER)
	end
end

love.postshader.draw = function(shader)
	LOVE_POSTSHADER_LAST_BUFFER = love.graphics.getCanvas()

	if shader == "bloom" then
		-- Bloom Shader
		love.graphics.setCanvas(LOVE_POSTSHADER_BUFFER_BACK)
		love.graphics.setBlendMode("alpha")

		love.graphics.setShader(LOVE_POSTSHADER_BLURV)
		love.graphics.draw(LOVE_POSTSHADER_BUFFER_RENDER)

		love.graphics.setShader(LOVE_POSTSHADER_BLURH)
		love.graphics.draw(LOVE_POSTSHADER_BUFFER_BACK)

		love.graphics.setShader(LOVE_POSTSHADER_CONTRAST)
		love.graphics.draw(LOVE_POSTSHADER_BUFFER_BACK)

		love.graphics.setCanvas(LOVE_LIGHTMAP_LAST_BUFFER)
		love.graphics.setShader()
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(LOVE_POSTSHADER_BUFFER_RENDER)
		love.graphics.setBlendMode("additive")
		love.graphics.setColor(255, 255, 255, 63)
		love.graphics.draw(LOVE_POSTSHADER_BUFFER_BACK)
		love.graphics.setBlendMode("alpha")
	elseif shader == "blur" then
		-- Blur Shader
		LOVE_POSTSHADER_BLURV:send("steps", 2.0)
		LOVE_POSTSHADER_BLURH:send("steps", 2.0)
		love.graphics.setCanvas(LOVE_POSTSHADER_BUFFER_BACK)
		love.graphics.setBlendMode("alpha")

		love.graphics.setShader(LOVE_POSTSHADER_BLURV)
		love.graphics.draw(LOVE_POSTSHADER_BUFFER_RENDER)

		love.graphics.setShader(LOVE_POSTSHADER_BLURH)
		love.graphics.draw(LOVE_POSTSHADER_BUFFER_BACK)

		love.graphics.setCanvas(LOVE_LIGHTMAP_LAST_BUFFER)
		love.graphics.setShader()
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(LOVE_POSTSHADER_BUFFER_BACK)
	end
end