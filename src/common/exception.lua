---
-- Exception
--
-- @classmod Exception

Exception = class()

--- create a exception.
--
-- @class function
-- @name Exception
--
-- @string[opt="Exception"] name
-- @string[opt=""] message
-- @tparam Exception[opt] inner_exception
--
-- @usage
--  function div (a, b)
--    if b == 0 then Exception("DivisionByZeroException", "b ~= 0!").throw() end
--    return a / b
--  end
--
--  local status, err = pcall(div, 1, 0)
--
function Exception:_init (name, message, inner_exception)
    self.type = "Exception"
    self.name = ((type(name) ~= "string") and "Exception") or name
    self.message = (message == nil and "") or tostring(message)

    if (type(inner_exception) == "string") then
        self.inner_exception = ErrorToException(inner_exception,1)
    elseif isException(inner_exception) then
        self.inner_exception = inner_exception
    end
    if (self.inner_exception ~= nil) then
        self.message = self.message .. ' : ' .. self.inner_exception.message
    end

    self.stacktrace = ""
end

function Exception:__tostring()
    local result = {}

    if self.inner_exception then
        table.insert(result, tostring(self.inner_exception))
        table.insert(result, '\n')
    end

    if self.stacktrace == "" then
        table.insert(result, self.name)
        table.insert(result, ': ')
        table.insert(result, self.message)
    else
        table.insert(result, self.stacktrace)
    end

    return table.concat(result, '')
end

local function setStackTrace(exception, level)
    local lvl = 4
    if (type(level) == "number") and level >= 0 then
        lvl = lvl + level
    end
    exception.stacktrace = debug.traceback(exception.name .. ': ' .. exception.message, lvl)
end

---
-- throws an exception
--
function Exception:throw()
    if self.stacktrace == "" then
        setStackTrace(self)
    end
    error(self)
end

function ErrorToException (err, level)
    local exception = Exception(nil, err)
    setStackTrace(exception, level)
    return exception
end

function isException(err)
    return (type(err) == "table") and (err.type == "Exception")
end


function TryCatchFinally (try, catch, finally)
    if type(try) ~= "function" then
        error("first parameter need to be a function", 2)
    elseif not ( (catch == nil) or (type(catch) == "function") or (type(catch) == "table") ) then
        error("second parameter need to be nil or a function or a table of functions", 2)
    elseif not ( (finally == nil) or (type(finally) == "function") ) then
        error("third parameter need to be nil or a function", 2)
    end

    local result = {n=0};

    local exception = false
    result = xpack(xpcall(try, function (err)
        if isException(err) then
            exception = err
        else
            exception = ErrorToException(err)
        end
    end))
    table.remove(result,1)

    if exception and catch ~= nil then
        local catchFunc = false
        if type(catch) == "function" then
            catchFunc = catch
        elseif catch[exception.name] then
            catchFunc = catch[exception.name]
        elseif catch[1] then
            catchFunc = catch[1]
        end

        if catchFunc ~= false then
            if type(catchFunc) ~= "function" then
                error("second parameter need to be nil or a function or a table of functions", 2)
            end

            local ex = exception
            exception = false
            xpcall(function ()
                result = xpack(catchFunc(ex))
            end, function (err)
                if isException(err) then
                    exception = err
                else
                    exception = ErrorToException(err)
                end
            end)
        end
    end

    if finally ~= nil then
        local resultFinally = xpack(finally())
        if resultFinally.n > 0 then
            result = resultFinally
        end
    end

    if exception then
        exception:throw()
    end

    if result == nil then
        return nil
    else
        return xunpack(result);
    end
end