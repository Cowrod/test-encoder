local encoder = require'./main'
local settings = {
	array_size = 10000,
	max_random_string_lenght = 9,
	total_loop = 10
}

local function random_string(size)
	local output = {}
	for i = 1, size do
		table.insert(output,
			string.char(
				math.random(0,255)
			)
		)
	end
	return table.concat(output)
end

local function test_array(_size)
	local output, size = {}, 0
	for i = 1, _size do
		local value = math.random(2)==1 and
			math.random()or
			random_string(
				math.random(settings.max_random_string_lenght)
			)
		table.insert(output, value)
		size = size + #tostring(value)
	end
	return output, size
end

for i = 1, settings.total_loop do
	local loop_start = os.clock()
	local array, size = test_array(settings.array_size)
	
	local encode_start = os.clock()
	local encoded = encoder.encode(array)
	local encoded_diff = #encoded-#array
	local encode_end = os.clock()-encode_start
	
	local decode_start = os.clock()
	local decoded = encoder.decode(encoded)
	local decode_end = os.clock()-decode_start
	local decoded_diff = #decoded[1] == #array

	local loop_end = os.clock()-loop_start

	print("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
	print("Loop "..i..". is done!")
	print("Loop took: "..loop_end)
	print("Array size: "..size)
	print("=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=")
	print("Encoded array size: "..#encoded)
	print("Encoded array size diff: "..encoded_diff)
	print("Encoding took: "..encode_end.." second(s)")
	print("=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=")
	print("Decoded data difference check: "..tostring(decoded_diff))
	print("Decoding took: "..decode_end.." second(s)")
	
end
print("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
