-----
-- Random Variable
--
-- Dependencies:
-- @classmod RandomVariable

RandomVariable = class()

---
-- Interval
-- @int from
-- @int to
-- @table Interval

--- create a random variable.
--
-- @string name
-- @string typ  string or number
--
-- @class function
-- @name RandomVariable
-- @usage local random_variable = RandomVariable()
function RandomVariable:_init (name, typ)

    if (type(name) ~= "string") then
        error("parameter 'name' need to be a string")
    end
    if (type(typ) ~= "string") then
        error("parameter 'typ' need to be a string")
    end
    if ((typ ~= "string") and (typ ~= "number")) then
        error("only value 'string' and 'number' are valid for parameter 'typ'")
    end

    self.name = name
    self.typ = typ
    self.data = {}
    self.totalOccurence = 0
    -- self.minValue, self.maxValue
    self.totalBuckets = 0
end

local INDEX_VALUE = 1
local INDEX_OCCURRENCE = 2

function RandomVariable:add(value, occurence)
    if (type(value) ~= self.typ) then
        error("parameter 'value' needs to be of type '" .. self.typ .. "'")
    end
    if (type(occurence) ~= "number") then
        error("parameter 'value' needs to be of type '" .. self.typ .. "'")
    end
    if (occurence < 0) then
        error("parameter 'value' (" .. tostring(occurence) .. ") needs to be >= 0")
    elseif (occurence == 0) then
        return
    end

    if (self.data[value] == nil) then
        self.data[value] = { value, occurence }
        self.totalBuckets = self.totalBuckets + 1
    else
        local item = self.data[value]
        item[INDEX_OCCURRENCE] = item[INDEX_OCCURRENCE] + occurence
    end

    -- update statistics
    self.totalOccurence = self.totalOccurence + occurence
    if self.minValue == nil or self.minValue > value then self.minValue = value end
    if self.maxValue == nil or self.maxValue < value then self.maxValue = value end
end

function RandomVariable:getProbabilityOfValue(value)
    return self:getProbability(self.data[value])
end

function RandomVariable:getProbability(event)
    if (event == nil) then
        return 0
    else
        return event[INDEX_OCCURRENCE] / self.totalOccurence
    end
end

function RandomVariable:parseMartix(name, type, matrix, indexValue, indexOccurrence)
    if (type(matrix) ~= "table") then
        error("Parameter 'matrix' need to be a table")
    end
    if (type(indexValue) ~= "number" or type(indexValue) ~= "string") then
        error("Parameter 'indexValue' need to be a number or string")
    end
    if (type(indexOccurrence) ~= "number" or type(indexOccurrence) ~= "string") then
        error("Parameter 'indexOccurrence' need to be a number or string")
    end

    local var = RandomVariable(name, type)
    for _, row in pairs(matrix) do
        var:addEvent(row[indexValue], row[indexOccurrence])
    end
    return var
end

function RandomVariable:getMinValue()
    return self.minValue or 0
end

function RandomVariable:getMaxValue()
    return self.maxValue or 0
end

function RandomVariable:getValueInterval()
    return { from=self:getMinValue(), to=self:getMaxValue() }
end

---
-- search for minimal occurrence
--
-- @treturn int value of maximum occurrence
-- @treturn int minimal occurrence
--
function RandomVariable:getMinOccurrence()
    local minValue, minOccurrence
    for _,curr in pairs(self.data) do
        local occurrence = curr[INDEX_OCCURRENCE]
        if minOccurrence == nil or minOccurrence > occurrence then
            minValue = curr[INDEX_VALUE]
            minOccurrence = occurrence
        end
    end
    return minValue, minOccurrence
end

---
-- search for maximal occurrence
--
-- @treturn int value of maximum occurrence
-- @treturn int maximal occurrence
--
function RandomVariable:getMaxOccurrence()
    local maxValue, maxOccurrence
    for _,curr in pairs(self.data) do
        local occurrence = curr[INDEX_OCCURRENCE]
        if maxOccurrence == nil or maxOccurrence < occurrence then
            maxValue = curr[INDEX_VALUE]
            maxOccurrence = occurrence
        end
    end
    return maxValue, maxOccurrence
end

---
-- calculates occurrence interval
--
-- @treturn Interval occurrence interval
--
function RandomVariable:getOccurrenceInterval()
    local minOccurrence, maxOccurrence

    for _,curr in pairs(self.data) do
        local occurrence = curr[INDEX_OCCURRENCE]
        if minOccurrence == nil or minOccurrence > occurrence then
            minOccurrence = occurrence
        end
        if maxOccurrence == nil or maxOccurrence < occurrence then
            maxOccurrence = occurrence
        end
    end

    return { from=minOccurrence, to=maxOccurrence }
end

function RandomVariable:getTotalOccurrence()
    return self.totalOccurence
end

function RandomVariable:getSum()
    if (self.totalOccurence == 0) then return 0 end

    local sum = 0
    for _,item in pairs(self.data) do
        sum = sum + (item[INDEX_VALUE] * item[INDEX_OCCURRENCE])
    end

    return sum
end

function RandomVariable:getLowPercentil()
    return self:getPercentil(0.25)
end

function RandomVariable:getMedian()
    return self:getPercentil(0.5)
end

function RandomVariable:getHighPercentil()
    return self:getPercentil(0.75)
end

local compare = function(a,b)
    return a[INDEX_VALUE] < b[INDEX_VALUE]
end

function RandomVariable:getSortedData()
    local dataSorted = {}
    for _, curr in pairs(self.data) do
        table.insert(dataSorted, curr)
    end
    table.sort(dataSorted, compare)
    return dataSorted, INDEX_VALUE, INDEX_OCCURRENCE
end

function RandomVariable:getPercentil(...)
    local args = {...}
    local results = {}

    for i,value in pairs(args) do
        if value == nil then
            error(string.format("value of position %i is nil", i))
        elseif type(value) ~= "number" then
            error(string.format("value of position %i is not a number (%s)", i, tostring(value)))
        elseif value < 0 or value > 1 then
            error(string.format("value of position %i is <0 or >1 (%s)", i, tostring(value)))
        end
    end

    if (#args == 0) then return end

    if (self.totalOccurence == 0) then
        for _ in pairs(args) do
            table.insert(results, 0)
        end
        return unpack(results)
    end

    table.sort(args)
    local sortedData = self:getSortedData()

    local indexArgs = 1
    local threshold, isEven -- gerade
    local count = 0
    for i=1, #sortedData do
        local curr = sortedData[i]
        count = count + curr[INDEX_OCCURRENCE]
        repeat
            if (threshold == nil) then
                local p = args[indexArgs]
                if p <= 0 or p >= 1 then
                    error("percentil p need to be 0<p<1. but p="..p)
                end
                threshold = self.totalOccurence *  p
                isEven = (threshold == math.ceil(threshold))
            end
            if count >= threshold then
                local percentil
                if isEven then
                    local next = curr
                    if threshold+1 > count then
                        next = sortedData[i+1]
                    end
                    percentil = (curr[INDEX_VALUE] + next[INDEX_VALUE]) / 2
                else
                    percentil = curr[INDEX_VALUE]
                end
                table.insert(results, percentil)
                if (indexArgs == #args) then
                    return unpack(results)
                end
                indexArgs = indexArgs + 1
                threshold = nil
            end
        until (threshold ~= nil)
    end
end

---
-- group values
--
-- @int buckets max number of buckets
--
-- @treturn RandomVariable
--
function RandomVariable:collapse (buckets, firstStep, lastStep)

    local collapsed = RandomVariable(self.name, self.typ)

    -- base case
    if self.totalBuckets <= 1 then
        for _,v in pairs(self.data) do
            collapsed:add(v[INDEX_VALUE], v[INDEX_OCCURRENCE])
        end
        return collapsed
    end

    buckets = buckets or 250

    local sortedData = self:getSortedData()

    if firstStep == nil or firstStep > self.minValue then firstStep = self.minValue end
    if lastStep == nil or lastStep < self.maxValue then lastStep = self.maxValue end
    local stepSize = (lastStep - firstStep) / buckets

    local currStep = self.minValue-stepSize
    local avgValue, sumValue, sumCount = 0, 0, 0
    for i=1, #sortedData, 1 do
        local curr = sortedData[i]
        local value = curr[INDEX_VALUE]
        local count = curr[INDEX_OCCURRENCE]

        if (value <= currStep + stepSize) then
            sumValue = sumValue + count*value
            sumCount = sumCount + count
        else
            avgValue = (sumValue / sumCount)
            collapsed:add(avgValue,sumCount)

            currStep = firstStep+math.floor((value-firstStep)/stepSize)*stepSize
            sumValue = count*value
            sumCount = count
        end
    end
    avgValue = (sumValue / sumCount)
    collapsed:add(avgValue,sumCount)
    collapsed.isSorted = true

    return collapsed
end

---
-- search for important sub intervals
--
-- @int threshold percent of max occurrence, when value is important
-- @int[opt] resolution maximum distance between two important values to merge them into one interval
--
-- @treturn [Interval] intervals list of intervals
--
function RandomVariable:findImportantSubIntervals (threshold, resolution)
    -- @todo definition and implementation of resolution and threshold

    if self.totalBuckets == 0 then return {} end

    local findImportantValues = function (data, threshold)
        local values = {}
        for _,curr in pairs(data) do
            local occurrence = curr[INDEX_OCCURRENCE]
            if occurrence >= threshold then
                -- important point found
                table.insert(values, curr[INDEX_VALUE])
            end
        end
        return values
    end

    local getIntervals = function (values, range)
        local intervals = {}
        if #values == 0 then return intervals end

        table.sort(values)
        local interval = { from=values[1]-range, to=values[1]+range }
        table.insert(intervals, interval)
        for _,value in pairs(values) do
            if value <= interval.to then
                -- merge intervals of important point
                interval.to = value + range
            else
                -- create new interval for important point
                interval = { from=value-range, to=value+range }
                table.insert(intervals, interval)
            end
        end
        return intervals
    end

    local _, max = self:getMaxOccurrence()
    local thresholdValue = max * threshold
    local values = findImportantValues(self.data, thresholdValue)

    resolution = resolution or 20
    local range = (self.maxValue - self.minValue) / resolution
    local intervals = getIntervals(values, range)

    return intervals
end

---
-- calculates extract random variables of subintervals
-- precondition: intervals are sorted and to not intersect
--
-- @tparam [Interval] intervals list of intervals
--
-- @treturn [RandomVariable] list of random variables
--
function RandomVariable:getVariablesForIntervals(intervals)

    local vars = {}
    if #intervals == 0 then return vars end

    for i=1,#intervals do
        local var = RandomVariable(string.format("%s (%i)",self.name,i), self.typ)
        table.insert(vars, var)
    end

    local index = 1
    local interval = intervals[index]
    local data = self:getSortedData()

    for _,item in pairs(data) do
        local value = item[INDEX_VALUE]
        -- value behind last interval?
        if value >= interval.to then
            -- get next interval
            index = index + 1
            -- next interval available?
            if index <= #intervals then
                interval = intervals[index]
            else
                break
            end
        end
        -- value in current interval?
        if value >= interval.from and value < interval.to then
            local occurence = item[INDEX_OCCURRENCE]
            vars[index]:add(value, occurence)
        end
    end

    return vars
end

function RandomVariable:getMean()
    if (self.totalOccurence == 0) then return 0 end

    local mean = 0
    for _, curr in pairs(self.data) do
        local value = curr[INDEX_VALUE] * self:getProbability(curr)
        mean = mean + value
    end

    return mean
end

function RandomVariable:getStandardDeviation(mean)
    return math.sqrt(self:getVariance(mean))
end

function RandomVariable:getStandardDeviationFromVariance(variance)
    return math.sqrt(variance)
end

function RandomVariable:getVariance(mean)
    if (self.totalOccurence == 0) then return 0 end

    if (mean == nil) then
        mean = self:getMean()
    end
    if (type(mean) ~= "number") then
        error("Parameter 'mean' need to be a number")
    end

    local variance = 0
    for _,curr in pairs(self.data) do
        local value = self:getProbability(curr) * math.pow((curr[INDEX_VALUE] - mean), 2)
        variance = variance + value
    end

    return variance
end

function RandomVariable:getStats()
    local low, med, high = self:getPercentil(0.25,0.5,0.75)
    local mean = self:getMean()
    local variance = self:getVariance(mean)
    local stats = {
        num = self.totalOccurence,
        min = self:getMinValue(),
        low = low,
        med = med,
        high = high,
        max = self:getMaxValue(),
        mean = mean,
        variance = variance,
        stdDeviation = self:getStandardDeviationFromVariance(variance)
    }
    return stats
end

function RandomVariable:fromCsv(name, type, csv, colValue, colOccurrence, start)
    local var = RandomVariable(name, type)
    if colOccurrence == nil then
        for i=start,#csv.data,1 do
            local row = csv.data[i]
            var:add(tonumber(row[colValue]),1)
        end
    else
        for i=start,#csv.data,1 do
            local row = csv.data[i]
            var:add(tonumber(row[colValue]),tonumber(row[colOccurrence]))
        end
    end
    return var
end

function RandomVariable:toCsv()
    local csv = CSV()

    for _,curr in pairs(self.data) do
        local value = tostring(curr[INDEX_VALUE])
        local occ = tostring(curr[INDEX_OCCURRENCE])
        csv:addRow({ value, occ })
    end

    return csv
end

function RandomVariable:toList()
    local list = {}

    for _,curr in pairs(self.data) do
        local value = curr[INDEX_VALUE]
        local occ = curr[INDEX_OCCURRENCE]
        for i=1,occ do
            table.insert(list, value)
        end
    end

    return list
end

function RandomVariable:print()
    local sortedData = self:getSortedData()
    for _,curr in pairs(sortedData) do
        local value = curr[INDEX_VALUE]
        local occ = curr[INDEX_OCCURRENCE]
        print(value, occ)
    end
end

function RandomVariable:slice(from, to)
    if to < from then
        error("Parameter 'from' need to be greater than 'to'")
    end

    local var = RandomVariable(self.name, self.typ)

    local sortedData = self:getSortedData()
    for _, curr in pairs(sortedData) do
        local value = curr[INDEX_VALUE]
        if value >= from and value <= to then
            local occurrence = curr[INDEX_OCCURRENCE]
            var:add(value, occurrence)
        end
    end

    return var
end