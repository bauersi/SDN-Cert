---
-- Histogram
--
-- Dependencies: CSV, Float
-- @classmod Histogram

Histogram = class()

---
-- Interval
-- @int from
-- @int to
-- @table Interval

--- create a histogram.
-- @class function
-- @name Histogram
-- @usage local histogram = Histogram()
function Histogram:_init ()
    self.isSubinterval = false
    self.data = RandomVariable("hist", "number")
    self.occurrenceTotalParent = 0
end

---
-- boolean, true if histogram is a subinterval
Histogram.isSubinterval = nil
---
-- random variable (value=time in µs, occurence=occurence)
Histogram.data = nil
---
-- int, totel number of occurrence in field occurrence of parent, useful if field isSubiterval=true
Histogram.occurrenceTotalParent = nil

---
-- insert new data into histogram
--
-- @int time time in µs
-- @int occurrence
--
function Histogram:insert(time, occurrence)
    self.data:add(time, occurrence)
end

---
-- parse csv without header.<br/>
-- file-structure: &lt;measured time in ns&gt;, &lt;occurrence of packets with measured time&gt;
--
-- @tparam CSV csv
--
-- @treturn Histogram
--
function Histogram:parseCsv (csv)
    local hist = Histogram()

    for currRow = 1, csv:getRowCount(), 1 do
        local row = csv:getRow(currRow)
        local time, value = Float.tonumber(row[1]) / 1000, tonumber(row[2])    -- change time ns to µs    TODO: better way
        hist:insert(time, value)
    end

    return hist
end

---
-- parses ',' separated csv-file without header.<br/>
-- file-structure: &lt;measured time in ns&gt;, &lt;occurrence of packets with measured time&gt;
--
-- @string filepath path to the csv-file
--
-- @treturn Histogram
--
function Histogram:parseCsvFile(filepath)
    local csv = CSV:parseFile(filepath)
    local hist = Histogram:parseCsv(csv)
    return hist
end

---
-- group points in histogram
--
-- @int buckets max number of buckets
--
-- @treturn Histogram
--
function Histogram:collapse (buckets)
    local collapsed = Histogram()
    collapsed.isSubinterval = self.isSubinterval
    collapsed.occurrenceTotalParent = self.data:getTotalOccurrence()
    collapsed.data = self.data:collapse(buckets, self:getValueInterval().from)
    return collapsed
end

---
-- get value interval of histogram
--
-- @treturn Interval value interval
--
function Histogram:getValueInterval()
    if self.data:getTotalOccurrence() == 0 then
        return { from = 0, to = 0 }
    elseif self.isSubinterval then
        return self.data:getValueInterval()
    else
        return { from = 0, to = self.data:getMaxValue() }
    end
end

---
-- get occurrence interval of histogram
--
-- @treturn Interval occurrence interval
--
function Histogram:getOccurrenceInterval()
    if self.data:getTotalOccurrence() == 0 then
        return { from = 0, to = 0 }
    else
        return self.data:getOccurrenceInterval()
    end
end

---
-- calculate important histograms
--
-- @int threshold percent of max occurrence, when value is important
-- @int[opt] resolution maximum distance between two important points to merge them into one interval
--
function Histogram:getImportantHistograms(threshold, resolution)
    return self:getHistogramsForIntervals(self:findImportantSubIntervals(threshold, resolution))
end

---
-- search for important sub intervals in histogram
--
-- @int threshold percent of max occurrence, when time is important
-- @int[opt] resolution maximum distance between two important points to merge them into one interval
--
function Histogram:findImportantSubIntervals (threshold, resolution)
    return self.data:findImportantSubIntervals (threshold, resolution)
end

---
-- calculates histograms for subintervals
-- precondition: intervals are sorted and to not intersect
--
-- @tparam [Interval] intervals list of intervals
--
-- @treturn [Histogram] list of histograms
--
function Histogram:getHistogramsForIntervals(intervals)
    local hists = {}
    local vars = self.data:getVariablesForIntervals(intervals)

    for _,var in pairs(vars) do
        local hist = Histogram()
        hist.isSubinterval = true
        hist.occurrenceTotalParent = self.occurrenceTotalParent
        hist.data = var
        table.insert(hists, hist)
    end

    return hists
end

function Histogram:getPercentil(...)
    return self.data:getPercentil(...)
end

function Histogram:slice(from,to)
    local hist = Histogram()
    hist.isSubinterval = true
    hist.occurrenceTotalParent = self.occurrenceTotalParent
    hist.data = self.data:slice(from,to)
    return hist
end

function Histogram:getStats()
    return self.data:getStats()
end

function Histogram:getMaxOccurrence()
    return self.data:getMaxOccurrence()
end

---
-- transforms histogram to csv
--
-- @treturn [CSV]
--
function Histogram:toCsv()
    local csv = CSV()
    local data, index_value, index_occurrence = self.data:getSortedData()
    local total = 0;
    local totalPakets = self.data:getTotalOccurrence()
    if self.isSubinterval then totalPakets = self.occurrenceTotalParent end

    csv:addRow({'time','count','total','percentage','totalPercentage'})
    if not self.isSubinterval then csv:addRow({'0','0','0','0','0'}) end
    for _,item in pairs(data) do
        local time = string.replace(""..item[index_value], ",", ".")
        local count = item[index_occurrence]
        total = total + count
        local percentage = count / totalPakets * 100
        local totalPercentage = total / totalPakets * 100
        csv:addRow({time,string.format('%i',count),string.format('%i',total),string.format('%s',percentage),string.format('%s',totalPercentage)})
    end
    return csv
end