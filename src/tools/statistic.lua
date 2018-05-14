---
-- Statistic functions
-- @module Statistic

Statistic = {}

---
--  sortes a list of floats
--
-- @tparam [float] list list of floats
--
-- @treturn [float] sorted list of floats
--
function Statistic.sortList(list)
  local sortedList = { }
  for _, value in pairs(list) do
    table.insert(sortedList, Float.tonumber(value))
  end
  table.sort(sortedList)
  return sortedList
end


---
--  calculates percentile for a list of floats
--
-- @tparam [float] list list of floats
-- @int p percentile
-- @tparam[opt=false] boolean isSorted is list sorted?
--
-- @treturn float percentile
--
function Statistic.getPercentile(list, p, isSorted)
  local isSorted = isSorted or false
  if (not isSorted) then
    list = Statistic.sortList(list)
  end
  return list[math.ceil(#list * p / 100)]
end


---
--  calculates quantiles for a list of floats
--
-- @tparam [float] list list of floats
-- @tparam[opt=false] boolean isSorted is list sorted?
--
-- @treturn float quantile (25%)
-- @treturn float quantile (75%)
--
function Statistic.getQuantiles(list, isSorted)
  local isSorted = isSorted or false
  if (not isSorted) then
    list = Statistic.sortList(list)
  end
  return list[math.ceil(#list * 1/4)], list[math.ceil(#list * 3/4)]
end


---
--  calculates median for a list of floats
--
-- @tparam [float] list list of floats
-- @tparam[opt=false] boolean isSorted is list sorted?
--
-- @treturn float median
--
function Statistic.getMedian(list, isSorted)
  local isSorted = isSorted or false
  if type(list) ~= 'table' then return list end
  if (not isSorted) then
    list = Statistic.sortList(list)
  end
  if #list %2 == 0 then return (list[#list/2] + list[#list/2+1]) / 2 end
  return list[math.ceil(#list/2)]
end


---
--  calculates average for a list of floats
--
-- @tparam [float] list list of floats
--
-- @treturn float average
--
function Statistic.getAverage(list)
  if type(list) ~= 'table' then return list end
  local sum, num = 0, 0
  for _,value in pairs(list) do
    local value = Float.tonumber(value)
    if (value) then
      sum = sum + value
      num = num + 1
    end
  end
  return sum/num
end


---
--  calculates min and max for a list of floats
--
-- @tparam [float] list list of floats
--
-- @treturn float min
-- @treturn float max
--
function Statistic.getMinMax(list)
  if type(list) ~= 'table' then return list end
  local min, max
  for _,value in pairs(list) do
    local value = Float.tonumber(value)
    if (value) then
      min = math.min(min or value, value)
      max = math.max(max or value, value)
    end
  end
  return min, max
end


---
-- Full Statistic
-- @int num number of elements
-- @tparam float min minimum value of elements
-- @tparam float max maximum value of elements
-- @tparam float sum sum of values of all elements
-- @tparam float avg average of values of all elements
-- @tparam float median median of values of all elements
-- @tparam float lowP low percentil of values of all elements
-- @tparam float highP high percentil of values of all elements
-- @table FullStatistic

---
--  calculates all statistics for a list of floats
--
-- @tparam [float] list list of floats
-- @int lowP low percentile
-- @int highP high percentile
--
-- @treturn FullStatistic
--
function Statistic.getFullStats(list, lowP, highP)
  local lowP = lowP or 25
  local highP = highP or 75
  if type(list) ~= 'table' then return list end
  local stats = {num = 0, sum = 0}
  local sortedList = {}
  for _,value in pairs(list) do
    local value = Float.tonumber(value)
    if (value) then
      stats.num = stats.num + 1
      stats.sum = stats.sum + value
      stats.min = math.min(stats.min or value, value)
      stats.max = math.max(stats.max or value, value)
      table.insert(sortedList, value)
    end
  end
  table.sort(sortedList)
  stats.avg = stats.sum / stats.num
  stats.median = Statistic.getMedian(sortedList, true)
  stats.lowP = Statistic.getPercentile(sortedList, lowP, true)
  stats.highP = Statistic.getPercentile(sortedList, highP, true)
  return stats
end