--[[
We be beating json!!

1. Plus features:
- Easy data appending
  * """
instead of:
q=json.decode(data1);table.insert(q,data2);json.encode(q)

it is just:
 encoder.encode(data1) .. encoder.encode(data2)
  """
- Minifying
  * """
 encoder.minify.encode(data) 
  """
- Fast as fuck boi: (benchmark below)

--------------------------------

Encode Speed Test (10000 iterations):
Custom encode: 0.049 seconds
Minified custom encode: 0.149 seconds
JSON encode: 0.130 seconds
 => 2.65x faster than JSON in normal encode, 0.87x slower than JSON in minified encode

Size Test:
Custom encode: 207 bytes
Minified custom encode: 157 bytes
JSON encode: 183 bytes
 => 0.88x bigger than JSON in normal encode, 1.16x smaller than JSON in minified encode

Decode Speed Test (10000 iterations):
Custom decode: 0.062 seconds
Minified custom decode: 0.110 seconds
JSON decode: 0.115 seconds
 => 1.85x faster than JSON in normal decode, 1.04x faster than JSON in minified decode

--------------------------------

Big Array Test:

Encode Speed Test (10000 iterations):
Custom encode: 2.002 seconds
Minified encode: 3.554 seconds
JSON encode: 4.517 seconds
 => 2.25x faster than JSON in normal encode, 1.27x faster than JSON in minified encode

Size Test:
Byte count:     3663
Custom encode: 6701 bytes
Minified custom encode: 2187 bytes
JSON encode: 6200 bytes
 => 0.92x bigger than JSON in normal encode, 2.83x smaller than JSON in minified encode

Decode Speed Test (10000 iterations):
Custom decode: 2.672 seconds
Minified custom decode: 3.298 seconds
JSON decode: 5.718 seconds
 => 2.13x faster than JSON in normal decode, 1.73x faster than JSON in minified decode
]]

local types = {
	number  = "\255",
	string  = "\254",
	boolean = "\253", ["nil"] = "\253",
	table   = {
		number  = "\252",
		ordered = "\251",
		other   = "\250"
	}
}local miniz = require('miniz')

function isEmpty(tbl)
	return next(tbl) == nil
end

function isAllINT(tbl)
	if isEmpty(tbl) then return false end
	for _,v in next,tbl do
		if type(v) ~= "number" then return false end
	end
	return true
end

function isOrdered(tbl)
	return #tbl~=0 or isEmpty(tbl)
end

function count(tbl)
	if type(tbl)~="table" or isOrdered(tbl) then
		return type(tbl)=="table" and #tbl or #tostring(tbl)
	end
	local n = 0
	for _ in next,tbl do n=n+1 end
	return n
end

function encodeData(value)
	local valueType = type(value)
	local byte = types[valueType]
	if type(byte) == "table" then
		if isAllINT(value) and isOrdered(value) then
			local str = table.concat(value,"\2").."\2"
			return byte.number..#str.."\1"..str
		elseif isOrdered(value) then
			local values = {}
			local n = 0
			for _,v in next,value do
				local val = encodeData(v)
				if val then
					n = n + 1
					values[n] = val
				end
			end
			local str = table.concat(values,"",1,n)
			return byte.ordered..#str.."\1"..str
		else
			local values = {}
			local n = 0
			for k,v in next,value do
				local val = encodeData(v)
				if val then
					n = n + 1
					values[n] = encodeData(k)
					n = n + 1
					values[n] = val
				end
			end
			local str = table.concat(values,"",1,n)
			return byte.other..#str.."\1"..str
		end
	elseif byte then
		local str = byte=="\253" and (value and "1" or "0") or tostring(value)
		return byte..#str.."\1"..str
	end
	return false
end

function decoderHandler(type, data)
	if type == "\255" then
		return tonumber(data)
	elseif type == "\254" then
		return data
	elseif type == "\253" then
		return data == "1" 
	elseif type == "\252" then
		local output = {}
		local pos = 1
		local len = #data
		while pos <= len do
			local numEnd = data:find("\2", pos)
			if not numEnd then break end
			table.insert(output, tonumber(data:sub(pos, numEnd-1)))
			pos = numEnd + 1
		end
		return output
	elseif type == "\251" or type == "\250" then
		return decodeData(data, type == "\250")
	end
end

function decodeData(data, isIndexedTable)
    local output = {}
    local pos = 1
    local len = #data

    while pos <= len do
        local typeChar = data:sub(pos, pos)
        if typeChar == "" then
            break
        end

        local lenStart = pos + 1
        local lenEnd = data:find("\1", lenStart)
        if not lenEnd then
            break
        end

        local valueLenStr = data:sub(lenStart, lenEnd - 1)
        local valueLen = tonumber(valueLenStr)
        if not valueLen then
            pos = lenEnd + 1
            goto continue
        end

        local valueStart = lenEnd + 1
        local valueEnd = valueStart + valueLen - 1
        if valueEnd > len then
            break
        end

        local valueStr = data:sub(valueStart, valueEnd)
        local value = decoderHandler(typeChar, valueStr)
        if value == nil then
            pos = valueEnd + 1
            goto continue
        end

        table.insert(output, value)
        pos = valueEnd + 1

        ::continue::
    end

    if isIndexedTable then
        local result = {}
        for i = 1, #output, 2 do
            result[output[i]] = output[i + 1]
        end
        return result
    end

    return output
end

return {encode=encodeData, decode=decodeData, minifiy = {
	warning = "Minifying is not recommended as it block a spesific element of encoding, which is 'Easy data appending', thus making the data appending process like JSON (1. decode all data, 2. add new data, 3. re-encode data). Rather to (1. encode, 2. string append)",
	encode = function(value)
		return miniz.compress(encodeData(value))
	end,
	decode = function(value)
		return decodeData(miniz.uncompress(value))
	end
}}
