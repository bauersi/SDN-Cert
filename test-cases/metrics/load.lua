local MetricLib = require "metrics/lib"

local addStatsTableRow = function (statsTable, direction, stats)
    statsTable:add(
        direction,
        string.format("%.4f", stats.min),
        string.format("%.4f", stats.low),
        string.format("%.4f", stats.med),
        string.format("%.4f", stats.high),
        string.format("%.4f", stats.max),
        string.format("%.4f", stats.mean),
        string.format("%.4f", stats.stdDeviation)
    )
end

local getStatsTable = function (caption, statsTx, statsRx)
    local statsTable = TexTable("|c|c|c|c|c|c|c|c|","H")
    statsTable:setCaption(Tex.sanitize(caption))
    statsTable:add(
        "\\textbf{Flow}",
        "\\textbf{Min}",
        "\\textbf{Low Perc.}",
        "\\textbf{Median}",
        "\\textbf{High Perc.}",
        "\\textbf{Max}",
        "\\textbf{Mean}",
        "\\textbf{Std. Derivation}"
    )

    local statsDiff = {
        min = statsTx.min-statsRx.min,
        low = statsTx.low-statsRx.low,
        med = statsTx.med-statsRx.med,
        high = statsTx.high-statsRx.high,
        max = statsTx.max-statsRx.max,
        mean = statsTx.mean-statsRx.mean,
        stdDeviation = statsTx.stdDeviation-statsRx.stdDeviation,
    }

    addStatsTableRow(statsTable, "tx", statsTx)
    addStatsTableRow(statsTable, "rx", statsRx)
    addStatsTableRow(statsTable, "diff", statsDiff)
    return statsTable
end

local Metric = {
    output = {"_load_rx.csv", "_load_tx.csv"},
    basic = function (test)
        local items = {}

        -- Perpare Data

        local txCsv = CSV:parseFile(test:getOutputPath() .. "test_" .. test:getId() .. "_load_tx.csv")
        local rxCsv = CSV:parseFile(test:getOutputPath() .. "test_" .. test:getId() .. "_load_rx.csv")

	-- Add row for displaying graph correctly (Timenew starting at 0 (Seconds))
        local timenew = {"Timenew"}
          for i=0,txCsv:getRowCount()-1 do
          table.insert(timenew,i)
        end

        txCsv:addColumn(timenew)
        txCsv:toFile(test:getOutputPath() .. "test_" .. test:getId() .. "_load_tx.csv")

        timenew = {"Timenew"}
          for i=0,rxCsv:getRowCount()-1 do
          table.insert(timenew,i)
        end

        rxCsv:addColumn(timenew)
        rxCsv:toFile(test:getOutputPath() .. "test_" .. test:getId() .. "_load_rx.csv")

	-- Add csv contents to tex-File
        local txFileContent = FileContent("test_"..test:getId().."_tx")
        txFileContent:addCsvList(txCsv:getLines())
        table.insert(items, txFileContent)

        local rxFileContent = FileContent("test_"..test:getId().."_rx")
        rxFileContent:addCsvList(rxCsv:getLines())
        table.insert(items, rxFileContent)

	-- Select relevant data for statistic
        local duration = test:getCurrentValueOfParameter('duration')
        local first, last = 3, 3+duration-1
        local selectedTxCsv = txCsv:select(first+1, last+1)
        local selectedRxCsv = rxCsv:select(first+1, last+1)

        local colMpps = 4 -- mpps
        local colMbps = 5 -- mbit/s
        local txRndVarMbps = RandomVariable:fromCsv('tx mbps', 'number', selectedTxCsv, colMbps, nil, 1)
        local rxRndVarMbps = RandomVariable:fromCsv('rx mbps', 'number', selectedRxCsv, colMbps, nil, 1)
        local txRndVarMpps = RandomVariable:fromCsv('tx mpps', 'number', selectedTxCsv, colMpps, nil, 1)
        local rxRndVarMpps = RandomVariable:fromCsv('rx mpps', 'number', selectedRxCsv, colMpps, nil, 1)

        table.insert(selectedTxCsv.data, 1, txCsv.data[1])
        selectedTxCsv:toFile(test:getOutputPath() .. "test_" .. test:getId() .. "_load_tx_section.csv")
        table.insert(selectedRxCsv.data, 1, rxCsv.data[1])
        selectedRxCsv:toFile(test:getOutputPath() .. "test_" .. test:getId() .. "_load_rx_section.csv")

        -- Graph

        local graph = TexFigure("H")
        graph:add(Graphs.lineGraph({
            x = { label="Time [s]", interval={ from=0, to=#rxCsv.data+1 } },
            y = { label=Tex.sanitize("Throughput [Mio. Pakets/s]"), interval={ from=0 } },
            y2 = { label=Tex.sanitize("Throughput [MBit/s]"), interval={ from=0 } },
            boundaries = { x={ from=0, to=#rxCsv.data }, y=txRndVarMpps:getValueInterval() },
            boundaries2 = { x={ from=0, to=#rxCsv.data }, y=txRndVarMbps:getValueInterval() },
            caption = "Throughput Packets/s and Bits/s",
            fig = "test_"..test:getId()..":throughput:load"
        }, {
            { label="transmit (tx)", color="red", marker="*", columns="x=Timenew, y=PacketRate", file="test_"..test:getId().."_tx.csv" },
            { label="receive (rx)", color="blue", marker="x", columns="x=Timenew, y=PacketRate", file="test_"..test:getId().."_rx.csv" }
        }))
        table.insert(items, graph)

        local caption = string.format("Statistics For Throughput in Mio. Packets/s (%ss - %ss)", first, last)
        local statsTable = getStatsTable(caption, txRndVarMpps:getStats(), rxRndVarMpps:getStats())
        table.insert(items, statsTable)

        caption = string.format("Statistics For Throughput in MBit/s (%ss - %ss)", first, last)
        statsTable = getStatsTable(caption, txRndVarMbps:getStats(), rxRndVarMbps:getStats())
        table.insert(items, statsTable)

        return items
    end,
    grouped = function(parameter, testcases, ids)
        local elems = {}

        testcases =  MetricLib.getEnabledTestcases(testcases, ids)
        if #testcases < 2 then return elems end

        -- prepare data

        local colMpps = 4 -- select Mpps values
        local colMbps = 5 -- select Mbps values
        local statsMpps = {}
        local statsMbps = {}
        for _,testcase in pairs(testcases) do
            local filepath = string.format("%stest_%s_load_rx_section.csv", testcase:getOutputPath(), testcase:getId())
            local csv = CSV:parseFile(filepath)
            table.insert(statsMpps, RandomVariable:fromCsv('var', 'number', csv, colMpps, nil, 2):getStats())
            table.insert(statsMbps, RandomVariable:fromCsv('var', 'number', csv, colMbps, nil, 2):getStats())
        end

        local isParameterNumeric = MetricLib.isParameterNumeric(testcases, parameter)

        -- create csv files

        local rxMpps = MetricLib.getFileContentForStats("rxMpps", parameter, isParameterNumeric, testcases, statsMpps)
        table.insert(elems, rxMpps)
        local rxMbps = MetricLib.getFileContentForStats("rxMbps", parameter, isParameterNumeric, testcases, statsMbps)
        table.insert(elems, rxMbps)

        if (not isParameterNumeric) then
            local labelTable = TexTable("|r|l|","H")
            labelTable:add("\\textbf{Test}",  "\\textbf{Parameter}")
            for i=1, #testcases do
                local testcase = testcases[i]
                local id = testcase:getId()
                local param = Tex.sanitize(testcase:getCurrentValueOfParameter(parameter))
                labelTable:add(string.format("\\textbf{%s}", id), param)
            end
            table.insert(elems, labelTable)
        end

        -- create figures

        local minMpps = MetricLib.getRandomVariableForStat(statsMpps,'min'):getMinValue()
        local minMbps = MetricLib.getRandomVariableForStat(statsMbps,'min'):getMinValue()
        local maxMpps = MetricLib.getRandomVariableForStat(statsMpps,'max'):getMaxValue()
        local maxMbps = MetricLib.getRandomVariableForStat(statsMbps,'max'):getMaxValue()
        local medMpps = MetricLib.getRandomVariableForStat(statsMpps,'med'):getStats()
        local medMbps = MetricLib.getRandomVariableForStat(statsMbps,'med'):getStats()

        local zoomEnabled = MetricLib.isZoomedGraphUseful(minMpps, maxMpps)

        -- mpps and mbps not equal
        if parameter ~= normalizeKey('pktSize') then
            local completeGraph, detailedGraph, statsTable, statsTable2 = MetricLib.getGraphsForStats(
                testcases, parameter, isParameterNumeric, "rxMpps.csv",
                "Throughput", {
                y={
                    label=Tex.sanitize("Throughput [Mio. Pakets/s]"),
                    unit=Tex.sanitize("Mio. Pakets/s"),
                    interval={
                        complete={ from=0 },
                        detailed={}
                    },
                    stats = medMpps,
                    boundaries = { from=minMpps, to=maxMpps }
                },
                y2={
                    label=Tex.sanitize("Throughput [MBit/s]"),
                    unit=Tex.sanitize("MBit/s"),
                    interval={
                        complete={ from=0 },
                        detailed={}
                    },
                    stats = medMbps,
                    boundaries = { from=minMbps, to=maxMbps }
                }
            }, "load:rx"
            )
            table.insert(elems, completeGraph)
            if (zoomEnabled) then table.insert(elems, detailedGraph) end
            table.insert(elems, statsTable)
            table.insert(elems, statsTable2)
        else
            local completeGraph, detailedGraph, statsTable = MetricLib.getGraphsForStats(
                testcases, parameter, isParameterNumeric, "rxMpps.csv",
                "Throughput", {
                    y={
                        label=Tex.sanitize("Throughput [Mio. Pakets/s]"),
                        unit=Tex.sanitize("Mio. Pakets/s"),
                        interval={
                            complete={ from=0 },
                            detailed={}
                        },
                        stats = medMpps,
                        boundaries = { from=minMpps, to=maxMpps }
                    }
                }, "load:rx-mpps"
            )
            table.insert(elems, completeGraph)
            if (zoomEnabled) then table.insert(elems, detailedGraph) end
            table.insert(elems, statsTable)

            completeGraph, detailedGraph, statsTable = MetricLib.getGraphsForStats(
                testcases, parameter, isParameterNumeric, "rxMbps.csv",
                "Throughput", {
                    y={
                        label=Tex.sanitize("Throughput [MBit/s]"),
                        unit=Tex.sanitize("MBit/s"),
                        interval={
                            complete={ from=0 },
                            detailed={}
                        },
                        stats = medMbps,
                        boundaries = { from=minMbps, to=maxMbps }
                    }
                }, "load:rx-mbps"
            )
            table.insert(elems, completeGraph)
            if (zoomEnabled) then table.insert(elems, detailedGraph) end
            table.insert(elems, statsTable)
        end

        return elems
    end
}

return Metric
