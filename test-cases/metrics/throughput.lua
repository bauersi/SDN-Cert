local MetricLib = require "metrics/lib"

local COLUMN_NUMBER_OF_LOST_FRAMES = 4  -- totalDiff
local COLUMN_LOSS_RATE = 5              -- diffPercentage

local function findMaxThroughput(data, threshold)

    local maxThroughputRate = { rate=0, loss_rate=0 }

    for _,item in pairs(data) do
        if (item.loss_rate > threshold) then
            break;
        end
        maxThroughputRate = item
    end

    return maxThroughputRate
end

local Metric = {
    grouped = function(parameter, testcases, ids)
        local elems = {}

        if parameter ~= "rate" then
            return elems
        end

        local allTestcases = testcases
        testcases =  MetricLib.getEnabledTestcases(testcases, ids)
        if #testcases < 2 then return elems end

        -- prepare data
        local data = {}
        for _,testcase in pairs(testcases) do
            local rate = testcase:getCurrentValueOfParameter(parameter)
            local csv = CSV:parseFile(testcase:getOutputPath() .. "test_" .. testcase:getId() .. "_paket_loss.csv")
            local loss_rate = csv:getRow(csv:getRowCount())[COLUMN_LOSS_RATE]
            local lost_frames = csv:getRow(csv:getRowCount())[COLUMN_NUMBER_OF_LOST_FRAMES]
            table.insert(data, { id= testcase:getId(), rate=tonumber(rate), lost_frames=tonumber(lost_frames), loss_rate=tonumber(loss_rate) })
        end
        local compare = function(a,b) return a.rate < b.rate end
        table.sort(data, compare)

        -- calculate max throughput
        local wire_rate = MetricLib.getWireRate(allTestcases)
        local pktSize = testcases[1]:getCurrentValueOfParameter(normalizeKey('pktSize'))
        local line_rate = MetricLib.getLineRate(wire_rate, pktSize)
        local maxThroughputRfc2544 = findMaxThroughput(data, 0)
        local maxThroughputOnePercLossRate = findMaxThroughput(data, 1)

        -- write csv-data
        local filecontent = FileContent("maxThroughput")
        filecontent:addCsvLine("rate,lossRate")
        for _,item in pairs(data) do
            filecontent:addCsvLine(string.format("%.0f,%.2f", item.rate / line_rate * 100, item.loss_rate))
        end
        table.insert(elems, filecontent)

        -- create figure
        local figure = TexFigure("H")
        local labels = {
            x = Tex.sanitize('Line rate [%]'), y = Tex.sanitize('Frameloss [%]'),
            caption = string.format('Maximal Throughput (Line Rate = %i MBit/s)', line_rate),
            fig = 'throughput:' .. testcases[1]:getName() .. ':' .. parameter
        }
        figure:add(Graphs.Throughput(labels, "x=rate, y=lossRate", 'maxThroughput.csv', maxThroughputRfc2544.rate / line_rate * 100))
        table.insert(elems, figure)

        -- create additional text
        local throughputTable = TexTable("|c|c|c|","ht")
        throughputTable:add("", "\\textbf{max. Throughput (RFC 2544)}", string.format("\\textbf{max. Throughput (%s Threshold)}", Tex.sanitize("1%")))
        throughputTable:add("\\textbf{Throughput}",
            string.format("%0.2f MBit/s (%0.2f mpps)", maxThroughputRfc2544.rate, MetricLib.mbpsToMpps(maxThroughputRfc2544.rate, pktSize)),
            string.format("%0.2f MBit/s (%0.2f mpps)", maxThroughputOnePercLossRate.rate, MetricLib.mbpsToMpps(maxThroughputOnePercLossRate.rate, pktSize))
        )
        throughputTable:add("\\textbf{Line Rate}",
            string.format("%0.2f %s", maxThroughputRfc2544.rate / line_rate * 100, Tex.sanitize("%")),
            string.format("%0.2f %s", maxThroughputOnePercLossRate.rate / line_rate * 100, Tex.sanitize("%"))
        )
        throughputTable:add("\\textbf{Loss Rate}",
            string.format("%0.2f %s", maxThroughputRfc2544.loss_rate, Tex.sanitize("%")),
            string.format("%0.2f %s", maxThroughputOnePercLossRate.loss_rate, Tex.sanitize("%"))
        )
        throughputTable:add("\\textbf{Lost Frames}",
            string.format("%i Pakets", maxThroughputRfc2544.lost_frames),
            string.format("%i Pakets", maxThroughputOnePercLossRate.lost_frames)
        )
        table.insert(elems, throughputTable)

        return elems
    end
}

return Metric
