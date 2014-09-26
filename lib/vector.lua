local vector = {}
-- vector functions
function vector.normalize(v)
	local len = math.sqrt(math.pow(v[1], 2) + math.pow(v[2], 2))
	local normalizedv = {v[1] / len, v[2] / len}
	return normalizedv
end

function vector.dot(v1, v2)
	return v1[1] * v2[1] + v1[2] * v2[2]
end

function vector.lengthSqr(v)
	return v[1] * v[1] + v[2] * v[2]
end

function vector.length(v)
	return math.sqrt(lengthSqr(v))
end

return vector
