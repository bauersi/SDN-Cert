require 'tools/strings'
require 'core/commonTest'

TestCommonTest = {}

function TestCommonTest:testBasic()

    local before = " hello   world    ! "
    local actual = CommonTest.readInArgs(before)
    local expected = { "hello", "world", "!" }

    luaunit.assertEquals(actual, expected)
end