require "common/bundle"
require "tools/strings"
require "tools/csv"

TestCsvGetRowCount = {

    testBasic = function ()

        local csv = CSV()
        csv:addLine('1,2,3')

        luaunit.assertEquals(csv:getRowCount(), 1)
    end

}

TestCsvAddRow = {

    testAddRow = function ()

        local csv = CSV()
        csv:addRow({ '1', '2', '3' })

        luaunit.assertEquals(csv:getRowCount(), 1)

        local actual  = csv:getLine(1)
        local expected = '1,2,3'

        luaunit.assertEquals(actual, expected)
    end,

    testAddEmptyRow = function ()
        local csv = CSV()
        luaunit.assertErrorMsgContains('table required', csv.addRow, csv, nil)
        luaunit.assertEquals(csv:getRowCount(), 0)
    end,

    testWrongType = function ()
        local csv = CSV()
        luaunit.assertErrorMsgContains('table required', csv.addRow, csv, 1)
        luaunit.assertEquals(csv:getRowCount(), 0)
    end
}

TestCsvAddLine = {

    testBasic = function ()

        local csv = CSV()
        csv:addLine('1,2,3')

        luaunit.assertEquals(csv:getRowCount(), 1)

        local actual  = csv:getLine(1)
        local expected = '1,2,3'

        luaunit.assertEquals(actual, expected)
    end,

    testDifferentSeparator = function ()

        local csv = CSV()
        csv:addLine('1;2;3', ';')

        luaunit.assertEquals(csv:getRowCount(), 1)

        local actual  = csv:getLine(1)
        local expected = '1,2,3'

        luaunit.assertEquals(actual, expected)
    end,

    testAddEmptyRow = function ()
        local csv = CSV()
        csv:addLine('')
        luaunit.assertEquals(csv:getRowCount(), 0)
    end,

    testWrongType = function ()
        local csv = CSV()
        luaunit.assertErrorMsgContains('string required', csv.addLine, csv, 1)
        luaunit.assertEquals(csv:getRowCount(), 0)
    end
}

TestCsvGetRow = {

    testBasic = function ()

        local csv = CSV()
        csv:addLine('1,2,3')
        csv:addLine('2,3,4')
        csv:addLine('3,4,5')

        local actual  = csv:getRow(2)
        local expected = { '2', '3', '4' }

        luaunit.assertEquals(actual, expected)
    end,

    testOutOfRange = function ()

        local csv = CSV()
        csv:addLine('1,2,3')
        csv:addLine('2,3,4')
        csv:addLine('3,4,5')

        local actual  = csv:getRow(99)
        local expected = nil

        luaunit.assertEquals(actual, expected)
    end
}

TestCsvGetLine = {

    testBasic = function ()

        local csv = CSV()
        csv:addLine('1,2,3')
        csv:addLine('2,3,4')
        csv:addLine('3,4,5')

        local actual  = csv:getLine(2)
        local expected = '2,3,4'

        luaunit.assertEquals(actual, expected)
    end,

    testDifferentSeparator = function ()

        local csv = CSV()
        csv:addLine('1,2,3')
        csv:addLine('2,3,4')
        csv:addLine('3,4,5')

        local actual  = csv:getLine(2,';')
        local expected = '2;3;4'

        luaunit.assertEquals(actual, expected)
    end,

    testOutOfRange = function ()

        local csv = CSV()
        csv:addLine('1,2,3')
        csv:addLine('2,3,4')
        csv:addLine('3,4,5')

        local actual  = csv:getLine(99)
        local expected = nil

        luaunit.assertEquals(actual, expected)
    end
}

TestCsvGetLines = {

    testEmpty = function ()

        local csv = CSV()

        local actual  = csv:getLines()
        local expected = {}

        luaunit.assertEquals(actual, expected)
    end,

    testBasic = function ()

        local csv = CSV()
        csv:addLine('1,2,3')
        csv:addLine('2,3,4')
        csv:addLine('3,4,5')

        local actual  = csv:getLines()
        local expected = { '1,2,3', '2,3,4', '3,4,5' }

        luaunit.assertEquals(actual, expected)
    end,

    testDifferentSeparator = function ()

        local csv = CSV()
        csv:addLine('1,2,3')
        csv:addLine('2,3,4')
        csv:addLine('3,4,5')

        local actual  = csv:getLines(';')
        local expected = { '1;2;3', '2;3;4', '3;4;5' }

        luaunit.assertEquals(actual, expected)
    end
}

TestCsvParseFile = {

    testBasic = function ()

        local csv = CSV:parseFile('test_csv_1.csv')

        local actual  = csv:getLines()
        local expected = { 'id,key,value', '1,A,a', '2,B,b', '3,C', '4,D,d,D' }

        luaunit.assertEquals(actual, expected)
    end,

    testDifferentSeparator = function ()

        local csv = CSV:parseFile('test_csv_2.csv',';')

        local actual  = csv:getLines()
        local expected = { 'id,key,value', '1,A,a', '2,B,b', '3,C', '4,D,d,D' }

        luaunit.assertEquals(actual, expected)
    end,

    testException = function ()

        local actualException = false
        TryCatchFinally(function ()
            CSV:parseFile('test_csv_LoadingFileException')
        end,
        function (err)
            actualException = err
        end
        )

        local expectedException = Exception('LoadingFileException', '')

        luaunit.assertTrue(actualException)
        luaunit.assertEquals(actualException.name, expectedException.name)
    end,
}

--[[
TestCsvPrint = {}

    function TestCsvPrint:testBasic()

        local csv = CSV()
        csv:addLine('a,b,c')
        csv:addLine('1,2,3')
        csv:addLine('2,3,4')
        csv:addLine('3,4,5')

        csv:print()

        local actual  = false
        local expected = { 'a,b,c', '1,2,3', '2,3,4', '3,4,5' }

        luaunit.assertEquals(actual, expected)
    end

    function TestCsvPrint:testWithoutHeader()

        local csv = CSV()
        csv:addLine('a,b,c')
        csv:addLine('1,2,3')
        csv:addLine('2,3,4')
        csv:addLine('3,4,5')

        csv:print(false)

        local actual  = false
        local expected = { '1,2,3', '2,3,4', '3,4,5' }

        luaunit.assertEquals(actual, expected)
    end

    function TestCsvPrint:testDifferentSeparator()

        local csv = CSV()
        csv:addLine('a,b,c')
        csv:addLine('1,2,3')
        csv:addLine('2,3,4')
        csv:addLine('3,4,5')

        csv:print(true,';')

        local actual  = false
        local expected = { 'a;b;c', '1;2;3', '2;3;4', '3;4;5' }

        luaunit.assertEquals(actual, expected)
    end
--]]

TestCsvTranspose = {

    testBasic= function ()

        local csv = CSV()
        csv:addLine('a,b,c')
        csv:addLine('1,2,3')
        csv:addLine('2,3,4')
        csv:addLine('3,4,5')
        csv:addLine('4,5,6')
        csv:addLine('5,6,7')

        local transposedCsv1 = csv:transpose()
        local transposedCsv2 = transposedCsv1:transpose()

        local actual  = csv:getLines()
        local expected = { 'a,b,c', '1,2,3', '2,3,4', '3,4,5', '4,5,6', '5,6,7' }

        luaunit.assertEquals(actual, expected)

        actual  = transposedCsv1:getLines()
        expected = { 'a,1,2,3,4,5', 'b,2,3,4,5,6', 'c,3,4,5,6,7' }

        luaunit.assertEquals(actual, expected)

        actual  = transposedCsv2:getLines()
        expected = { 'a,b,c', '1,2,3', '2,3,4', '3,4,5', '4,5,6', '5,6,7' }

        luaunit.assertEquals(actual, expected)
    end
}


TestCsvRemoveLeft = {

    testBasic= function ()

        local csv = CSV()
        csv:addLine('a,b,c')
        csv:addLine('1,2,3')
        csv:addLine('2,3,4')
        csv:addLine('3,4,5')
        csv:addLine('4,5,6')
        csv:addLine('5,6,7')
        csv:addLine('6,7,8')

        local actual  = csv:select(3,5):getLines()
        local expected = { '2,3,4', '3,4,5', '4,5,6' }

        luaunit.assertEquals(actual, expected)

        local actual  = csv:select(3):getLines()
        local expected = { '2,3,4', '3,4,5', '4,5,6', '5,6,7', '6,7,8' }

        luaunit.assertEquals(actual, expected)

        local actual  = csv:select(nil,5):getLines()
        local expected = { 'a,b,c', '1,2,3', '2,3,4', '3,4,5', '4,5,6' }

        luaunit.assertEquals(actual, expected)
    end
}