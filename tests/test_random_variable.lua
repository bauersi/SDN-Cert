require "common/class"
require "tools/random_variable"

Test_RandomVariable_GetMin = {

    testEmpty = function ()

        local var = RandomVariable('Test', 'number')

        local actual = var:getMin()
        local expected = 0

        luaunit.assertEquals(actual, expected)
    end,

    testBasic = function ()

        local var = RandomVariable('Test', 'number')
        var:add(1,1)
        var:add(2,1)
        var:add(4,3)

        local actual = var:getMin()
        local expected = 1

        luaunit.assertEquals(actual, expected)
    end,
}

Test_RandomVariable_GetMax = {

    testEmpty = function ()

        local var = RandomVariable('Test', 'number')

        local actual = var:getMax()
        local expected = 0

        luaunit.assertEquals(actual, expected)
    end,

    testBasic = function ()

        local var = RandomVariable('Test', 'number')
        var:add(1,1)
        var:add(2,1)
        var:add(4,3)

        local actual = var:getMax()
        local expected = 4

        luaunit.assertEquals(actual, expected)
    end,
}

Test_RandomVariable_GetMedian = {

    testEmpty = function ()

        local var1 = RandomVariable('Test', 'number')

        local actual = var1:getMedian()
        local expected = 0

        luaunit.assertEquals(actual, expected)
    end,

    testBasicOne = function ()

        local var1 = RandomVariable('Test', 'number')
        var1:add(3,1)

        local actual = var1:getMedian()
        local expected = 3

        luaunit.assertEquals(actual, expected)

        local var2 = RandomVariable('Test', 'number')
        var2:add(3,2)

        local actual = var2:getMedian()
        local expected = 3

        luaunit.assertEquals(actual, expected)
    end,

    testBasicMulti = function ()

        local var1 = RandomVariable('Test', 'number')
        var1:add(1,1)
        var1:add(2,1)
        var1:add(3,1)
        var1:add(4,1)
        var1:add(5,1)

        local actual = var1:getMedian()
        local expected = 3

        luaunit.assertEquals(actual, expected)

        local var2 = RandomVariable('Test', 'number')
        var2:add(1,1)
        var2:add(2,2)
        var2:add(3,1)
        var2:add(4,1)
        var2:add(5,1)

        actual = var2:getMedian()
        expected = 2.5

        luaunit.assertEquals(actual, expected)

        local var3 = RandomVariable('Test', 'number')
        var3:add(1,1)
        var3:add(2,3)
        var3:add(3,1)
        var3:add(4,1)
        var3:add(5,1)

        actual = var3:getMedian()
        expected = 2

        luaunit.assertEquals(actual, expected)

        local var4 = RandomVariable('Test', 'number')
        var4:add(1,9)
        var4:add(2,1)

        actual = var4:getMedian()
        expected = 1

        luaunit.assertEquals(actual, expected)

        local var5 = RandomVariable('Test', 'number')
        var5:add(1,1)
        var5:add(2,9)

        actual = var5:getMedian()
        expected = 2

        luaunit.assertEquals(actual, expected)
    end,
}

Test_RandomVariable_GetPercentil = {

    testNil = function ()

        local var1 = RandomVariable('Test', 'number')

        local actual = pack(var1:getPercentil())
        local expected = {}

        luaunit.assertEquals(actual, expected)
    end,

    testEmpty = function ()

        local var1 = RandomVariable('Test', 'number')

        local actual = pack(var1:getPercentil(0.25, 0.5, 0.75))
        local expected = {0,0,0}

        luaunit.assertEquals(actual, expected)
    end,

    testBasicOne = function ()

        local var1 = RandomVariable('Test', 'number')
        var1:add(3,1)

        local actual = pack(var1:getPercentil(0.25, 0.5, 0.75))
        local expected = {3,3,3}

        luaunit.assertEquals(actual, expected)

        local var2 = RandomVariable('Test', 'number')
        var2:add(3,2)

        local actual = pack(var1:getPercentil(0.25, 0.5, 0.75))
        local expected = {3,3,3}

        luaunit.assertEquals(actual, expected)
    end,

    testBasicMulti = function ()

        local var1 = RandomVariable('Test', 'number')
        var1:add(1,1)
        var1:add(2,1)
        var1:add(3,1)
        var1:add(4,1)
        var1:add(5,1)

        local actual = pack(var1:getPercentil(0.25, 0.5, 0.75))
        local expected = {2,3,4}

        luaunit.assertEquals(actual, expected)

        local var2 = RandomVariable('Test', 'number')
        var2:add(1,1)
        var2:add(2,2)
        var2:add(3,1)
        var2:add(4,1)
        var2:add(5,1)

        actual = pack(var2:getPercentil(0.25, 0.5, 0.75))
        expected = {2,2.5,4}

        luaunit.assertEquals(actual, expected)

        local var3 = RandomVariable('Test', 'number')
        var3:add(1,2)
        var3:add(2,3)
        var3:add(3,1)
        var3:add(4,1)
        var3:add(5,1)

        actual = pack(var3:getPercentil(0.25, 0.5, 0.75))
        expected = {1.5,2,3.5}

        luaunit.assertEquals(actual, expected)

        local var4 = RandomVariable('Test', 'number')
        var4:add(1,9)
        var4:add(2,1)

        actual = pack(var4:getPercentil(0.25, 0.5, 0.75))
        expected = {1,1,1}

        luaunit.assertEquals(actual, expected)

        local var5 = RandomVariable('Test', 'number')
        var5:add(1,1)
        var5:add(2,9)

        actual = pack(var5:getPercentil(0.25, 0.5, 0.75))
        expected = {2,2,2}

        luaunit.assertEquals(actual, expected)

        local var6 = RandomVariable('Test', 'number')
        var6:add(1,1)
        var6:add(2,3)
        var6:add(3,1)
        var6:add(4,1)
        var6:add(5,1)

        actual = pack(var6:getPercentil(0.25, 0.5, 0.75))
        expected = {2,2,4}

        luaunit.assertEquals(actual, expected)
    end,
}

Test_RandomVariable_GetMean = {

    testEmpty = function ()

        local var1 = RandomVariable('Test', 'number')

        local actual = var1:getMean()
        local expected = 0

        luaunit.assertEquals(actual, expected)
    end,

    testBasic = function ()

        local var1 = RandomVariable('Test', 'number')
        var1:add(1,1)
        var1:add(2,1)
        var1:add(3,1)
        var1:add(4,1)
        var1:add(5,1)

        local actual = var1:getMean()
        local expected = 3

        luaunit.assertEquals(actual, expected)

        local var2 = RandomVariable('Test', 'number')
        var2:add(1,1)
        var2:add(2,4)
        var2:add(3,2)
        var2:add(4,1)
        var2:add(5,4)

        actual = var2:getMean()
        expected = 3.25

        luaunit.assertEquals(actual, expected)

        local var3 = RandomVariable('Test', 'number')
        var3:add(1,4)
        var3:add(2,3)
        var3:add(3,1)
        var3:add(4,1)
        var3:add(5,1)

        actual = var3:getMean()
        expected = 2.2

        luaunit.assertEquals(actual, expected)

        local var4 = RandomVariable('Test', 'number')
        var4:add(1,2)
        var4:add(2,8)

        actual = var4:getMean()
        expected = 1.8

        luaunit.assertEquals(actual, expected)
    end,
}

Test_RandomVariable_GetStandardDeviation = {

    testEmpty = function ()

        local var1 = RandomVariable('Test', 'number')

        local actual = var1:getStandardDeviation()
        local expected = 0

        luaunit.assertEquals(actual, expected)
    end,

    testBasic = function ()

        local var1 = RandomVariable('Test', 'number')
        var1:add(2,1)
        var1:add(4,3)
        var1:add(5,2)
        var1:add(7,1)
        var1:add(9,1)

        local actual = var1:getStandardDeviation()
        local expected = 2

        luaunit.assertEquals(actual, expected)
    end,

}

Test_RandomVariable_GetVariance = {

    testEmpty = function ()

        local var1 = RandomVariable('Test', 'number')

        local actual = var1:getVariance()
        local expected = 0

        luaunit.assertEquals(actual, expected)
    end,

    testBasic = function ()

        local var1 = RandomVariable('Test', 'number')
        var1:add(2,1)
        var1:add(4,3)
        var1:add(5,2)
        var1:add(7,1)
        var1:add(9,1)

        local actual = var1:getVariance()
        local expected = 4

        luaunit.assertEquals(actual, expected)
    end,

}

Test_RandomVariable_FromCsv = {

    testBasis = function ()

        local csv = CSV()
        csv:addRow({ 'A', 'B', 'C' })
        csv:addRow({ '1', '10', '20' })
        csv:addRow({ '2', '9', '21' })
        csv:addRow({ '3', '8', '22' })
        csv:addRow({ '4', '7', '23' })
        csv:addRow({ '5', '6', '24' })

        local var = RandomVariable:fromCsv('Test', 'number', csv, 1, 2, 2)

        local actual = var.data
        local expected = {}
        expected[1] = {1,10 }
        expected[2] = {2,9 }
        expected[3] = {3,8 }
        expected[4] = {4,7 }
        expected[5] = {5,6}

        luaunit.assertEquals(actual, expected)

        local var = RandomVariable:fromCsv('Test', 'number', csv, 2, 3, 2)

        local actual = var.data
        local expected = {}
        expected[10] = {10,20 }
        expected[9] = {9,21 }
        expected[8] = {8,22 }
        expected[7] = {7,23 }
        expected[6] = {6,24}

        luaunit.assertEquals(actual, expected)
    end

}

Test_RandomVariable_ToCsv = {

    testBasis = function ()

        local expectedCsv = CSV()
        expectedCsv:addRow({ '1', '10'})
        expectedCsv:addRow({ '2', '9'})
        expectedCsv:addRow({ '3', '8' })
        expectedCsv:addRow({ '4', '7' })
        expectedCsv:addRow({ '5', '6' })

        local var = RandomVariable:fromCsv('Test', 'number', expectedCsv, 1, 2, 1)

        local actualCsv = var:toCsv()

        local actual = actualCsv.data
        local expected = expectedCsv.data

        luaunit.assertEquals(actual, expected)
    end

}

Test_RandomVariable_Splice = {

    testEmpty = function ()

        local var = RandomVariable('Test', 'number')
        local spliced = var:splice(10,100)

        local actual = var:getTotalOccurrence()
        local expected = spliced:getTotalOccurrence()

        luaunit.assertEquals(actual, expected)
    end,

    testBasic = function ()

        local var = RandomVariable('Test', 'number')
        var:add(1,1)
        var:add(1.5,1)
        var:add(2,1)
        var:add(3,1)
        var:add(4,1)
        var:add(4.5,1)
        var:add(5,1)

        local spliced = var:splice(2,4)

        local actualMin = spliced:getMin()
        local actualMax = spliced:getMax()
        local expectedMin = 2
        local expectedMax = 4

        luaunit.assertEquals(actualMin, expectedMin)
        luaunit.assertEquals(actualMax, expectedMax)
    end,
}