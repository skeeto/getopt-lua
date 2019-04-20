--- getopt(3)-like functionality for Lua 5.1 and later
-- This is free and unencumbered software released into the public domain.

--- getopt(argv, optstring [, nonoptions])
--
-- Returns a closure suitable for "for ... in" loops. On each call the
-- closure returns the next (option, optarg). For unknown options, it
-- returns ('?', option). When a required optarg is missing, it returns
-- (':', option). It's reasonable to continue parsing after errors.
--
-- The optstring follows the same format as POSIX getopt(3). However,
-- this function will never print output on its own.
--
-- Non-option arguments are accumulated, in order, in the optional
-- "nonoptions" table.
--
-- The input argv table is left unmodified.
function getopt(argv, optstring, nonoptions)
    local optind = 1
    local optpos = 2
    nonoptions = nonoptions or {}
    return function()
        while true do
            local arg = argv[optind]
            if arg == nil or arg == '--' then
                return nil
            elseif arg:sub(1, 1) == '-' then
                local opt = arg:sub(optpos, optpos)
                local start, stop = optstring:find(opt .. ':?')
                if not start then
                    optind = optind + 1
                    optpos = 2
                    return '?', opt
                elseif stop > start and #arg > optpos then
                    local optarg = arg:sub(optpos + 1)
                    optind = optind + 1
                    optpos = 2
                    return opt, optarg
                elseif stop > start then
                    local optarg = argv[optind + 1]
                    optind = optind + 2
                    optpos = 2
                    if optarg == nil then
                        return ':', opt
                    end
                    return opt, optarg
                else
                    optpos = optpos + 1
                    if optpos > #arg then
                        optind = optind + 1
                        optpos = 2
                    end
                    return opt, nil
                end
            else
                optind = optind + 1
                table.insert(nonoptions, arg)
            end
        end
    end
end

--- Tests

function fail(...)
    print('\027[91;1mFAIL\027[0m', ...)
    return false
end

function pass(...)
    print('\027[92;1mPASS\027[0m', ...)
    return true
end

function check(name, argv, optstring, expect)
    local actual = {}
    local nonoptions = {}
    for opt, arg in getopt(argv, optstring, nonoptions) do
        table.insert(actual, {opt, arg})
    end
    if #expect ~= #actual then
        return false
    elseif #nonoptions ~= #expect.nonoptions then
        return fail(name, 'differing nonoption lengths')
    else
        for i = 1, #expect do
            local e = expect[i]
            local a = actual[i]
            if e[1] ~= a[1] or e[2] ~= a[2] then
                return fail(name, 'option mismatch ' .. i)
            end
        end
        for i = 1, #nonoptions do
            if expect.nonoptions[i] ~= nonoptions[i] then
                return fail(name, 'nonoption mismatch ' .. i)
            end
        end
    end
    return pass(name)
end

check('basic', {'-a', 'foo', '-b', '-c', 'bar'}, 'abc', {
    {'a', nil},
    {'b', nil},
    {'c', nil},
    nonoptions = {'foo', 'bar'}
})

check('optarg', {'-a', '-bfoo', 'bar', '-c', '-b', 'baz'}, 'ab:c', {
    {'a', nil},
    {'b', 'foo'},
    {'c', nil},
    {'b', 'baz'},
    nonoptions = {'bar'}
})

check('validate', {'-x', '-b', '-x', 'extra', '-b'}, 'ab:c', {
    {'?', 'x'},
    {'b', '-x'},
    {':', 'b'},
    nonoptions = {'extra'}
})

check('group', {'-abc', '-cba', '-abxc'}, 'abcx:', {
    {'a', nil},
    {'b', nil},
    {'c', nil},
    {'c', nil},
    {'b', nil},
    {'a', nil},
    {'a', nil},
    {'b', nil},
    {'x', 'c'},
    nonoptions = {}
})

check('no-options', {'foo', 'bar', 'baz'}, 'abcdef', {
    nonoptions = {'foo', 'bar', 'baz'}
})

check('empty-args', {'', '-a', '', ''}, 'a:', {
    {'a', ''},
    nonoptions = {'', ''}
})
