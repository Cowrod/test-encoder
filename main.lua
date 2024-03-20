local types = {
	number  = "\255",
	string  = "\254",
	boolean = "\253", ["nil"] = "\253",
	table   = {
		number  = "\252",
		ordered = "\251",
		other   = "\250"
	}
}

function isEmpty(tbl)
	for i,v in pairs(tbl)do
		return false
	end
	return true
end

function isAllINT(tbl)
	if isEmpty(tbl) then
		return false
	end
	for i,v in pairs(tbl)do
		if type(v) ~= "number" then
			return false
		end
	end
	return true
end

function isOrdered(tbl)
	return#tbl~=0 or isEmpty(tbl)
end

function count(tbl) 
	if type(tbl)~="table" or isOrdered(tbl)then
		return type(tbl)=="table"and#tbl or #tostring(tbl)
	else
		local total = 0
		for i, v in pairs(tbl) do
			total = total + 1
		end
		return total
	end
end

function encodeData(value)
	local valueType = type(value)
	local byte = types[valueType]
	if type(byte) == "table" then
		if isAllINT(value) and isOrdered(value) then
			value = table.concat(value, "\2").."\2"
			return byte.number.."\1"..#value.."\1"..value
		elseif isOrdered(value) then
			local values = {}
			for i, v in pairs(value) do
				val = encodeData(v)
				if val then
					table.insert(values, val)
				end
			end
			local values = table.concat(values)
			value = byte.ordered.."\1"..#values.."\1"..values values=nil
			return value
		else
			local total = count(value)
			local values = {}
			for i, v in pairs(value) do
				val = encodeData(v)
				if val then
					table.insert(values, encodeData(i))
					table.insert(values, val)
				end
			end
			value = table.concat(values)values=nil
			value = byte.other.."\1"..#value.."\1"..value
			return value
		end
	elseif byte then
		value = byte=="\253"and(value and"1"or"0")or tostring(value)
		value = byte.."\1"..#value.."\1"..value
		return value
	end
	return false
end

function decoderHandler(type, data)
	collectgarbage()-- this is really needed here. cuz main decoding data normally gets copied around 2-3 times
	if type == "\255" then
		return tonumber(data)
	elseif type == "\254" then
		return tostring(data)
	elseif type == "\253" then
		return data == "1"
	elseif type == "\252" then
		local output = {}
		data:gsub("(%d+)\2",function(int)
			table.insert(output, tonumber(int))
		end)
		return output
	elseif type == "\251" or type == "\250" then
		return decodeData(data, type == "\250")
	end
end

function decodeData(data, isIndexedTable)
	local output = {}
	while true do
		_type, _len = tostring(data):match"(.)\1(%d+)\1"
		if _type and _len then
			_data = data:sub(#_len+4,_len+#_len+3)
			data = data:sub(_len+#_len+4,#data)
			if _data and data then
				_data = decoderHandler(_type, _data)
				if _data then
					table.insert(output, _data)
				else break end
			else break end
		else break end
		_type,_len,_data=nil
	end
	if isIndexedTable then
		local newOutput, name = {}, ""
		for i, v in pairs(output)do
			if i % 2 == 1 then
				name = v
			else
				newOutput[name] = v
			end
		end
		output, name = nil
		return newOutput
	else
    return output
  end
end

return {encode=encodeData, decode=decodeData}
