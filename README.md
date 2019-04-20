# `getopt(3)`-like option parsing for Lua

Simple, conventional argument parsing with a friendly licence. For Lua
5.1 and later. See the source file header for full documentation.

## Example usage

```lua
local append = false
local binary = false
local color = 'white'
local nonoptions = {}
local infile = io.input()

for opt, arg in getopt(arg, 'abc:h', nonoptions) do
    if opt == 'a' then
        append = true
    elseif opt == 'b' then
        binary = true
    elseif opt == 'c' then
        color = arg
    elseif opt == 'h' then
        usage()
        os.exit(0)
    elseif opt == '?' then
        print('error: unknown option: ' .. arg)
        os.exit(1)
    elseif opt == ':' then
        print('error: missing argument: ' .. arg)
        os.exit(1)
    end
end

if #nonoptions == 1 then
    infile = io.open(nonoptions[1], 'r')
elseif #nonoptions > 1
    print('error: wrong number of arguments: ' .. #nonoptions)
    os.exit(1)
end

-- ...
```

## Run the tests

    $ lua getopt.lua
