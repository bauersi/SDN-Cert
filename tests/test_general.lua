require "common/class"
require "tools/strings"
require "tools/general"

Test_Pack = {

    testBasic = function ()

        local actual = pack()
        local expected = {}

        luaunit.assertEquals(actual, expected)

        actual = pack(nil, nil, nil)
        expected = {}

        luaunit.assertEquals(actual, expected)

        actual = pack(nil, nil, 'x', nil, nil)
        expected = {}
        expected[1] = nil
        expected[2] = nil
        expected[3] = 'x'

        luaunit.assertEquals(actual, expected)

    end,
}

Test_XPack = {

    testBasic = function ()

        local actual = xpack()
        local expected = { n=0 }

        luaunit.assertEquals(actual, expected)

        actual = xpack(nil, nil, nil)
        expected = { n=3 }

        luaunit.assertEquals(actual, expected)

        actual = xpack(nil, nil, 'x', nil, nil)
        expected = { n=5 }
        expected[1] = nil
        expected[2] = nil
        expected[3] = 'x'

        luaunit.assertEquals(actual, expected)

    end,
}

Test_XUnpack = {

    testBasic = function ()

        luaunit.assertErrorMsgContains("bad argument #1 to 'xunpack' (table expected, got no value)", xunpack)

        local actual = xpack(xunpack({}))
        local expected = xpack(unpack({}))

        luaunit.assertEquals(actual, expected)

        actual = xpack(xunpack({nil, 'x', nil}))
        expected = xpack(unpack({nil, 'x', nil}))

        luaunit.assertEquals(actual, expected)
    end,

    testAdvanced = function ()

        local actual = xpack(xunpack({}))
        local expected = {n=0}

        luaunit.assertEquals(actual, expected)

        actual = xpack(xunpack({n=3}))
        expected = {n=3}

        luaunit.assertEquals(actual, expected)

        actual = xpack(xunpack({nil, nil, 'x', n=5}))
        expected = {n=5}
        expected[3] = 'x'

        luaunit.assertEquals(actual, expected)

    end,
}