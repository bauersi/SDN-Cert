--[[
  Test:   direct pass through with two ports
  Result: throughput and latency
]]

require "testcase_lib"
  
local Test = {}
 
Test.loadGen = "moongen"
Test.files   = "load-wire-rate.lua"
Test.lgArgs  = "$file=1 $id $link=1 $link=2"
Test.ofArgs  = "$link=1 $link=2"

Test.checkFeatures = function(openflowVersion, testcase, isFeatureSupported)
    return TestcaseConfig.checkFeatures({ "match_inport" }, isFeatureSupported)
end

Test.flowEntries = function(openflowVersion, flowData, inPort, outPort)
    local flow = string.format("in_port=%d, actions=output:%d", inPort, outPort)
    table.insert(flowData.flows, flow)
end

Test.afterExecution = function (test, context)
    local row = 3 -- speed
    local csv = CSV:parseFile(test:getOutputPath() .. "test_" .. test:getId() .. "_wire-rate.csv")
    local wire_rate = Statistic.getMinMax(csv:transpose():getRow(row))

    context['wire_rate'] = wire_rate

    context['line_rate'] = function (size)
        return math.floor(wire_rate * (size/(size+20)))
    end

    local file = io.open(test:getOutputPath() .. "test_" .. test:getId() .. "_result.txt", "w")
    file:write(wire_rate)
    file:write('\n')
    file:close()
end
  
Test.metric = { "wire-rate" }

return Test