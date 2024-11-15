# test-encoder
simple array encoder/decoder<br/>
faster than luvit's json, but a big bigger rathor to luvit's json.

## Usage

### Installation
```bash
git clone https://github.com/Cowrod/test-encoder.git
cd test-encoder
```

### Example usage

```lua
-- require the module and fs
local encoder = require('./main')
local fs = require('fs')

-- example 1.
fs.writeFileSync("myEncodedData.log", encoder.encode{
    index1 = "index2",
    [9] = (function()
        local output = {}
        for i = 1, 500 do
            table.insert(output, math.random(-1e13, 1e13))
        end
        return output
    end)(),
    what = "yes"
})

local decodedData = encoder.decode(fs.readFileSync("myEncodedData.log"))[1]

-- example 2.
for i = 1, 1e3 do
    local data = {
        id = i,
        data1 = math.random(-1e13, 1e13),
        data2 = randomstr(math.random(100))
    }
    fs.appendFileSync("myUpdatedData.log", encoder.encode(data))
    data = nil
end

local updatedData = encoder.decode(fs.readFileSync("myUpdatedData.log"))
```

### Benchmark

```bash
luvit benchmark.lua
# If you need to use this on other env's you will either need to remove the minifiying thing or replace it with another one that you have.
```

## License
[GNU General Public License v3.0](LICENSE)
