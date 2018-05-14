local Metric = {
    output = {"_load_rx.csv", "_latency.csv"},
    advanced = function(testcases, ids)
        local items = {}

        local tests = {}
        for _,id in pairs(ids) do
            local test = testcases[id]
            if not test:isDisabled() then
                local tag = test:getCurrentValueOfParameter("tag")
                if tag ~= nil then
                    tests[tag] = test
logger.debug("metric 'queue-size': found test with tag '" ..tag.."'")
                end
            end
        end

        if tests["lowload"] == nil or tests["overloaded"] == nil then
logger.warn("metric 'queue-size': missing test with tag 'lowload' or 'overloaded' ")
            return items
        end

        local lowloadTest = tests["lowload"]
        local overloadedTest = tests["overloaded"]

        local latency_lowload_csv = CSV:parseFile(lowloadTest:getOutputPath() .. "test_" .. lowloadTest:getId() .. "_latency.csv")
        local latency_overloaded_csv = CSV:parseFile(overloadedTest:getOutputPath() .. "test_" .. overloadedTest:getId() .. "_latency.csv")
        local rx_overloaded_csv = CSV:parseFile(overloadedTest:getOutputPath() .. "test_" .. overloadedTest:getId() .. "_load_rx.csv")

        local var_latency_lowload = RandomVariable('latency low load', 'number')
        for i=1,#latency_lowload_csv.data,1 do
            local row = latency_lowload_csv.data[i]
            var_latency_lowload:add(tonumber(row[1])/1000,tonumber(row[2]))     -- ns -> μs
        end
        local avg_latency_lowload = var_latency_lowload:getMean()

        local var_latency_overloaded = RandomVariable('latency overloaded', 'number')
        for i=1,#latency_overloaded_csv.data,1 do
            local row = latency_overloaded_csv.data[i]
            var_latency_overloaded:add(tonumber(row[1])/1000,tonumber(row[2]))  -- ns -> μs
        end
        local avg_latency_overloaded = var_latency_overloaded:getMean()

        local var_rx_overloaded = RandomVariable('rx overloaded', 'number')
        for i=3,#rx_overloaded_csv.data-2,1 do
            local row = rx_overloaded_csv.data[i]
            var_rx_overloaded:add(tonumber(row[4]),1)    -- mpps is col 4
        end
        local avg_rx_overloaded = var_rx_overloaded:getMean()  -- mpps = (10^6 pkt)/s = (10^6 pkt) / (10^6 μs) = pkt / μs

        local latencyDiff = avg_latency_overloaded - avg_latency_lowload
        local queue_size = math.floor(latencyDiff * avg_rx_overloaded)


        local params = TexTable("|l|r|", "ht")
        params:add("\\textbf{Average Latency Low Load}", string.format("%.2f $\\mu$s", avg_latency_lowload))
        params:add("\\textbf{Average Latency Overloaded}", string.format("%.2f $\\mu$s", avg_latency_overloaded))
        params:add("\\textbf{Average Service Time}", string.format("%.2f pkt / $\\mu$s", avg_rx_overloaded))
        table.insert(items, params)

        local text = TexText()
        text:add("\\begin{center}", "\\textbf{Queue Size is " .. tostring(queue_size) .. " pakets.}", "\\end{center}")
        table.insert(items, text)

        return items
    end
}

return Metric