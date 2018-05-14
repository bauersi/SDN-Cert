require "../globConst"
require "tools/general"
require 'tools/strings'

TestStringSanitize = {

    testBasic = function ()

        local before = " Test ( ) . % + - * ? [ ] ^ $ ( ) . % + - * ? [ ] ^ $ "
        local actual1, actual2 = string.sanitize(before)
        local expected = " Test %( %) %. %% %+ %- %* %? %[ %] %^ %$ %( %) %. %% %+ %- %* %? %[ %] %^ %$ "

        luaunit.assertEquals(actual1, expected)
        luaunit.assertEquals(actual2, nil)
    end
}

TestStringReplace = {}

    function TestStringReplace:testReplaceSingle()
        local before = "Hallo World! Hallo!"
        local actual = string.replace(before, "Hallo", "My")
        local expected = "My World! Hallo!"

        luaunit.assertEquals(actual, expected)
    end

    function TestStringReplace:testReplaceSpecialChars()

        for i=1,#string._SPECIAL_CHARS do

            local before = "Replace " .. string._SPECIAL_CHARS[i] .. " Special " .. string._SPECIAL_CHARS[i] .. " Character"
            local actual = string.replace(before, string._SPECIAL_CHARS[i], 'xxx')
            local expected = "Replace xxx Special " .. string._SPECIAL_CHARS[i] .. " Character"

            luaunit.assertEquals(actual, expected)
        end
    end

    function TestStringReplace:testReplaceSpecialCharsWithSpecialChars()

        for i=1,#string._SPECIAL_CHARS do

            local oldSpecialChar = string._SPECIAL_CHARS[i]
            local newSpecialChar = string._SPECIAL_CHARS[((i+1) % #string._SPECIAL_CHARS)+1]

            local oldText = oldSpecialChar .. "x" .. oldSpecialChar
            local newText = newSpecialChar .. "Y" .. newSpecialChar

            local before = "Replace " .. oldText .. " Special " .. oldText .. " Character"
            local actual = string.replace(before, oldText, newText)
            local expected = "Replace " .. newText .. " Special "  .. oldText .. " Character"

            luaunit.assertEquals(actual, expected)
        end
    end

TestStringReplaceAll = {}

    function TestStringReplaceAll:testReplaceAll()
        local before = "Hallo World! Hallo!"
        local actual = string.replaceAll(before, "Hallo", "My")
        local expected = "My World! My!"

        luaunit.assertEquals(actual, expected)
    end

    function TestStringReplaceAll:testReplaceSpecialChars()

        for i=1,#string._SPECIAL_CHARS do

            local before = "Replace " .. string._SPECIAL_CHARS[i] .. " Special " .. string._SPECIAL_CHARS[i] .. " Character"
            local actual = string.replaceAll(before, string._SPECIAL_CHARS[i], 'xxx')
            local expected = "Replace xxx Special xxx Character"

            luaunit.assertEquals(actual, expected)
        end
    end

    function TestStringReplaceAll:testReplaceSpecialCharsWithSpecialChars()

        for i=1,#string._SPECIAL_CHARS do

            local oldSpecialChar = string._SPECIAL_CHARS[i]
            local newSpecialChar = string._SPECIAL_CHARS[((i+1) % #string._SPECIAL_CHARS)+1]

            local oldText = oldSpecialChar .. "x" .. oldSpecialChar
            local newText = newSpecialChar .. "Y" .. newSpecialChar

            local before = "Replace " .. oldText .. " Special " .. oldText .. " Character"
            local actual = string.replaceAll(before, oldText, newText)
            local expected = "Replace " .. newText .. " Special "  .. newText .. " Character"

            luaunit.assertEquals(actual, expected)
        end
    end

TestStringTrim = {}

    function TestStringTrim:testBasic()

        local before = "  A  %  C   "
        local actual = string.trim(before)
        local expected = "A  %  C"

        luaunit.assertEquals(actual, expected)
    end

    function TestStringTrim:testEmpty()

        local before = "        "
        local actual = string.trim(before)
        local expected = ""

        luaunit.assertEquals(actual, expected)
    end

    function TestStringTrim:testWrongType()

        local before = 12.98
        local actual = string.trim(before)
        local expected = 12.98

        luaunit.assertEquals(actual, expected)
    end

TestStringLPad = {

    testBasic = function ()

        local value = "12"
        local len = 4
        local char = '0'

        local actual = string.lpad(value, len, char)
        local expected = "0012"

        luaunit.assertEquals(actual, expected)
    end,

}

TestStringSplit = {

    testBasic = function ()

        local value = "value1,value2,value3"
        local separator = ","

        local actual = string.split(value, separator)
        local expected = { "value1", "value2", "value3" }

        luaunit.assertEquals(actual, expected)
    end,

    testDifferentSeparator = function ()

        local value = "value1#value2#value3"
        local separator = "#"

        local actual = string.split(value, separator)
        local expected = { "value1", "value2", "value3" }

        luaunit.assertEquals(actual, expected)
    end,

    testMaxLength1 = function ()

        local value = "value1#value2#value3"
        local separator = "#"
        local maxNumberOfSplits = 1

        local actual = string.split(value, separator, maxNumberOfSplits)
        local expected = { "value1", "value2#value3" }

        luaunit.assertEquals(actual, expected)
    end,

    testMaxLength2 = function ()

        local value = "value1#value2#value3#value4#value5"
        local separator = "#"
        local maxNumberOfSplits = 3

        local actual = string.split(value, separator, maxNumberOfSplits)
        local expected = { "value1", "value2", "value3", "value4#value5" }

        luaunit.assertEquals(actual, expected)
    end,

    testMaxLength3 = function ()

        local value = "value1#value2#value3#value4#value5"
        local separator = "#"
        local maxNumberOfSplits = 100

        local actual = string.split(value, separator, maxNumberOfSplits)
        local expected = { "value1", "value2", "value3", "value4", "value5" }

        luaunit.assertEquals(actual, expected)
    end

}

TestStringKeyValue = {

    testBasic = function ()

        local value = "key=value"

        local actual = pack(string.getKeyValue(value))
        local expected = { "key", "value" }

        luaunit.assertEquals(actual, expected)
    end,

    testUnderscore = function ()

        local value = "file_1_a=value"

        local actual = pack(string.getKeyValue(value))
        local expected = { "file1a", "value" }

        luaunit.assertEquals(actual, expected)
    end,

    testDifferentSeparator = function ()

        local value = "file_1_a#value"
        local separator = '#'

        local actual = pack(string.getKeyValue(value, separator))
        local expected = { "file1a", "value" }

        luaunit.assertEquals(actual, expected)
    end,

    testValueBoolean = function ()

        local value = "file_1_a#false"
        local separator = '#'

        local actual = pack(string.getKeyValue(value, separator))
        local expected = { "file1a", false }

        luaunit.assertEquals(actual, expected)


        value = "file_1_a#true"
        separator = '#'

        actual = pack(string.getKeyValue(value, separator))
        expected = { "file1a", true }

        luaunit.assertEquals(actual, expected)
    end,

    testNil = function ()

        local actual = pack(string.getKeyValue(nil))
        local expected = {}

        luaunit.assertEquals(actual, expected)
    end
}
