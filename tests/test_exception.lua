require "common/class"
require "common/exception"
require "tools/strings"

TestException = {

    testBasic = function ()

        local ex = Exception("NilPointerException", "Value is nil")

        local status, exception = pcall(ex.throw, ex)
        local trace = debug.traceback()

        local parts = string.split(trace,':')
        parts[3] = tostring(tonumber(parts[3])-1)
        local expected_stacktrace = table.concat(parts, ':')

        luaunit.assertEquals(status, false)
        luaunit.assertEquals(exception.name, "NilPointerException")
        luaunit.assertEquals(exception.message, "Value is nil")
        luaunit.assertEquals(exception.stacktrace, "NilPointerException: Value is nil\n"..expected_stacktrace)
    end,

    testWithoutMessage = function ()

        local ex = Exception("NilPointerException")

        local status, exception = pcall(ex.throw, ex)
        local trace = debug.traceback()

        local parts = string.split(trace,':')
        parts[3] = tostring(tonumber(parts[3])-1)
        local expected_stacktrace = table.concat(parts, ':')

        luaunit.assertEquals(status, false)
        luaunit.assertEquals(exception.name, "NilPointerException")
        luaunit.assertEquals(exception.message, "")
        luaunit.assertEquals(exception.stacktrace, "NilPointerException: \n"..expected_stacktrace)
    end,

    testWithoutName = function ()

        local ex = Exception(nil, "Value is nil")

        local status, exception = pcall(ex.throw, ex)
        local trace = debug.traceback()

        local parts = string.split(trace,':')
        parts[3] = tostring(tonumber(parts[3])-1)
        local expected_stacktrace = table.concat(parts, ':')

        luaunit.assertEquals(status, false)
        luaunit.assertEquals(exception.name, "Exception")
        luaunit.assertEquals(exception.message, "Value is nil")
        luaunit.assertEquals(exception.stacktrace, "Exception: Value is nil\n"..expected_stacktrace)
    end,

    testToString = function ()

        local ex = Exception(nil, "Value is nil")

        local actual = tostring(ex)
        local expected = "Exception: Value is nil"

        luaunit.assertEquals(actual, expected)
    end
}


TestTryCatchFinally = {

    testTry = function ()

        local function x () return 15 end

        local actualStack = {}
        TryCatchFinally(function ()
            table.insert(actualStack, "try")
            x()
        end, function ()
            table.insert(actualStack, "catch")
        end)

        local expectedStack = { "try" }

        luaunit.assertEquals(actualStack, expectedStack)

    end,

    testCatchErrorWithFunction = function ()

        local function x () return error("test") end

        local actualStack = {}
        local actualException = false
        TryCatchFinally(function ()
            table.insert(actualStack, "try")
            x()
        end, function (err)
            table.insert(actualStack, "catch")
            actualException = err
        end)

        local expectedStack = { "try", "catch" }

        luaunit.assertEquals(actualStack, expectedStack)
        luaunit.assertEquals(isException(actualException), true)
        luaunit.assertEquals(actualException.name, "Exception")
        local actualMessagePart = string.sub(actualException.message, #actualException.message-5)
        luaunit.assertEquals(actualMessagePart, ": test")

    end,

    testDefaultCatchExceptionWithFunction = function ()

        local expectedException = Exception("TryException", "try")

        local function x () return expectedException:throw() end

        local actualStack = {}
        local actualException = false
        TryCatchFinally(function ()
            table.insert(actualStack, "try")
            x()
        end, function (err)
            table.insert(actualStack, "catch")
            actualException = err
        end)

        local expectedStack = { "try", "catch" }

        luaunit.assertEquals(actualStack, expectedStack)
        luaunit.assertEquals(actualException, expectedException)

    end,

    testDefaultCatchExceptionWithTable = function ()

        local expectedException = Exception("TryException", "try")

        local function x () return expectedException:throw() end

        local actualStack = {}
        local actualException = false
        TryCatchFinally(function ()
            table.insert(actualStack, "try")
            x()
        end, {
            CatchException = function (err)
                table.insert(actualStack, "catch")
                actualException = err
            end,
            function (err)
                table.insert(actualStack, "catch default")
                actualException = err
            end
        })

        local expectedStack = { "try", "catch default" }

        luaunit.assertEquals(actualStack, expectedStack)
        luaunit.assertEquals(actualException, expectedException)

    end,

    testCatchExceptionWithTableFunction = function ()

        local expectedException = Exception("CatchException", "catch")

        local function x () return expectedException:throw() end

        local actualStack = {}
        local actualException = false
        TryCatchFinally(function ()
            table.insert(actualStack, "try")
            x()
        end, {
            function (err)
                table.insert(actualStack, "catch default")
                actualException = err
            end,
            CatchException = function (err)
                table.insert(actualStack, "catch")
                actualException = err
            end
        })

        local expectedStack = { "try", "catch" }

        luaunit.assertEquals(actualStack, expectedStack)
        luaunit.assertEquals(actualException, expectedException)
    end,

    testCatchExceptionNotFound = function ()

        local expectedException = Exception("TryException", "try")

        local function x () return expectedException:throw() end

        local actualStack = {}

        local actualStatus, actualException = pcall(
            TryCatchFinally,
            function ()
                table.insert(actualStack, "try")
                x()
            end,
            {
                Exception = function (err)
                    table.insert(actualStack, "catch")
                end
            }
        )
        table.insert(actualStack, "outer catch")

        local expectedStack = { "try", "outer catch" }

        luaunit.assertEquals(actualStack, expectedStack)
        luaunit.assertEquals(actualStatus, false)
        luaunit.assertEquals(actualException, expectedException)

    end,

    testFinally = function ()

        local function x () return 1 end

        local actualStack = {}
        TryCatchFinally(
            function ()
                table.insert(actualStack, "try")
                x()
            end,
            nil,
            function ()
                table.insert(actualStack, "finally")
            end
        )

        local expectedStack = { "try", "finally" }

        luaunit.assertEquals(actualStack, expectedStack)
    end,

    testExceptionFinally = function ()

        local expectedException = Exception("TryException", "try")

        local function x () return expectedException:throw() end

        local actualStack = {}

        local actualStatus, actualException = pcall(
            TryCatchFinally,
            function ()
                table.insert(actualStack, "try")
                x()
            end,
            nil,
            function ()
                table.insert(actualStack, "finally")
            end
        )
        table.insert(actualStack, "outer catch")

        local expectedStack = { "try", "finally", "outer catch" }

        luaunit.assertEquals(actualStatus, false)
        luaunit.assertEquals(actualException, expectedException)
        luaunit.assertEquals(actualStack, expectedStack)
    end,

    testCatchFinally = function ()

        local function x () return Exception("TryException", "try"):throw() end

        local actualStack = {}

        TryCatchFinally(
            function ()
                table.insert(actualStack, "try")
                x()
            end,
            function (err)
                table.insert(actualStack, "catch")
            end,
            function ()
                table.insert(actualStack, "finally")
            end
        )

        local expectedStack = { "try", "catch", "finally" }

        luaunit.assertEquals(actualStack, expectedStack)
    end,

    testCatchExceptionFinally = function ()

        local expectedException = Exception("CatchException", "catch")

        local function x () return Exception("TryException", "try"):throw() end

        local actualStack = {}

        local actualStatus, actualException = pcall(
            TryCatchFinally,
            function ()
                table.insert(actualStack, "try")
                x()
            end,
            function (err)
                table.insert(actualStack, "catch")
                expectedException:throw()
            end,
            function ()
                table.insert(actualStack, "finally")
            end
        )
        table.insert(actualStack, "outer catch")

        local expectedStack = { "try", "catch", "finally", "outer catch" }

        luaunit.assertEquals(actualStatus, false)
        luaunit.assertEquals(actualException, expectedException)
        luaunit.assertEquals(actualStack, expectedStack)
    end,

    testTryReturnNon = function ()

        local actualStack = {}
        local actualResult = TryCatchFinally(function ()
            table.insert(actualStack, "try")
        end, function (err)
            table.insert(actualStack, "catch")
        end)

        local expectedStack = { "try" }

        luaunit.assertEquals(actualStack, expectedStack)
        luaunit.assertNil(actualResult)
    end,

    testTryReturnOne = function ()

        local actualStack = {}
        local actualException = false
        local actualResult = pack(TryCatchFinally(function ()
            table.insert(actualStack, "try")
            return "hello"
        end, function (err)
            table.insert(actualStack, "catch")
        end
        ))

        local expectedStack = { "try" }
        local expectedResult = { "hello" }

        luaunit.assertEquals(actualStack, expectedStack)
        luaunit.assertEquals(actualResult, expectedResult)
    end,

    testTryReturnMulti = function ()

        local actualStack = {}
        local actualResult = pack(TryCatchFinally(function ()
            table.insert(actualStack, "try")
            return "hello", "world", 123456
        end, function (err)
            table.insert(actualStack, "catch")
        end
        ))

        local expectedStack = { "try" }
        local expectedResult = { "hello", "world", 123456 }

        luaunit.assertEquals(actualStack, expectedStack)
        luaunit.assertEquals(actualResult, expectedResult)
    end,

    testCatchReturnNon = function ()

        local expectedException = Exception("CatchException", "catch")

        local function x () return expectedException:throw() end

        local actualStack = {}
        local actualException = false
        local actualResult = TryCatchFinally(function ()
            table.insert(actualStack, "try")
            x()
        end, function (err)
            table.insert(actualStack, "catch")
            actualException = err
        end
        )

        local expectedStack = { "try", "catch" }

        luaunit.assertEquals(actualStack, expectedStack)
        luaunit.assertEquals(actualException, expectedException)
        luaunit.assertNil(actualResult)
    end,

    testCatchReturnOne = function ()

        local expectedException = Exception("CatchException", "catch")

        local function x () return expectedException:throw() end

        local actualStack = {}
        local actualException = false
        local actualResult = pack(TryCatchFinally(function ()
            table.insert(actualStack, "try")
            x()
        end, function (err)
            table.insert(actualStack, "catch")
            actualException = err
            return "hello"
        end
        ))

        local expectedStack = { "try", "catch" }
        local expectedResult = { "hello" }

        luaunit.assertEquals(actualStack, expectedStack)
        luaunit.assertEquals(actualException, expectedException)
        luaunit.assertEquals(actualResult, expectedResult)
    end,

    testCatchReturnMulti = function ()

        local expectedException = Exception("CatchException", "catch")

        local function x () return expectedException:throw() end

        local actualStack = {}
        local actualException = false
        local actualResult = pack(TryCatchFinally(function ()
            table.insert(actualStack, "try")
            x()
        end, function (err)
            table.insert(actualStack, "catch")
            actualException = err
            return "hello", "world", 123456
        end
        ))

        local expectedStack = { "try", "catch" }
        local expectedResult = { "hello", "world", 123456 }

        luaunit.assertEquals(actualStack, expectedStack)
        luaunit.assertEquals(actualException, expectedException)
        luaunit.assertEquals(actualResult, expectedResult)
    end,

    testFinallyReturnNon = function ()

        local actualStack = {}
        local actualResult = pack(TryCatchFinally(function ()
            table.insert(actualStack, "try")
            return "hello", "world", 123456
        end, function ()
            table.insert(actualStack, "catch")
        end, function ()
            table.insert(actualStack, "finally")
        end))

        local expectedStack = { "try", "finally" }
        local expectedResult = { "hello", "world", 123456 }

        luaunit.assertEquals(actualStack, expectedStack)
        luaunit.assertEquals(actualResult, expectedResult)
    end,

    testFinallyReturnNil = function ()

        local actualStack = {}
        local actualResult = pack(TryCatchFinally(function ()
            table.insert(actualStack, "try")
            return "hello", "world", 123456
        end, function ()
            table.insert(actualStack, "catch")
        end, function ()
            table.insert(actualStack, "finally")
            return nil
        end))

        local expectedStack = { "try", "finally" }
        local expectedResult = {}

        luaunit.assertEquals(actualStack, expectedStack)
        luaunit.assertEquals(actualResult, expectedResult)
    end,

    testFinallyReturnOne = function ()

        local actualStack = {}
        local actualResult = pack(TryCatchFinally(function ()
            table.insert(actualStack, "try")
            return "hello", "world", 123456
        end, function ()
            table.insert(actualStack, "catch")
        end, function ()
            table.insert(actualStack, "finally")
            return "finally"
        end))

        local expectedStack = { "try", "finally" }
        local expectedResult = { "finally" }

        luaunit.assertEquals(actualStack, expectedStack)
        luaunit.assertEquals(actualResult, expectedResult)
    end,

    testFinallyReturnMulti = function ()

        local actualStack = {}
        local actualResult = pack(TryCatchFinally(function ()
            table.insert(actualStack, "try")
            return "hello", "world", 123456
        end, function ()
            table.insert(actualStack, "catch")
        end, function ()
            table.insert(actualStack, "finally")
            return "finally", "hello", "world"
        end))

        local expectedStack = { "try", "finally" }
        local expectedResult = { "finally", "hello", "world" }

        luaunit.assertEquals(actualStack, expectedStack)
        luaunit.assertEquals(actualResult, expectedResult)
    end,

    testCatchFinallyReturnMulti = function ()

        local expectedException = Exception("CatchException", "catch")

        local function x () return expectedException:throw() end

        local actualStack = {}
        local actualException = false
        local actualResult = pack(TryCatchFinally(function ()
            table.insert(actualStack, "try")
            x()
        end, function (ex)
            table.insert(actualStack, "catch")
            actualException = ex
            return "catch"
        end, function ()
            table.insert(actualStack, "finally")
            return "finally", "hello", "world"
        end))

        local expectedStack = { "try", "catch", "finally" }
        local expectedResult = { "finally", "hello", "world" }

        luaunit.assertEquals(actualStack, expectedStack)
        luaunit.assertEquals(actualException, expectedException)
        luaunit.assertEquals(actualResult, expectedResult)
    end,

}