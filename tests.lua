getopt = require('getopt')

--- Test Harness

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
        return fail(name, 'differing option lengths')
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

--- Tests

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

check('dash-dash', {'-a', '-b', '--', '-c', '--', '-a', '-x'}, 'ab:c', {
    {'a', nil},
    {'b', '--'},
    {'c', nil},
    nonoptions = {'-a', '-x'}
})
