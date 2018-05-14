local MetricLib = require "metrics/lib"

local Metric = {
    output = {"_latency.csv"},
    basic = function (test)
        local items = {}

        -- read data
        local csv = CSV:parseFile(test:getOutputPath().."test_"..test:getId().."_latency.csv")
        if csv:getRowCount() == 0 then
            csv:toFile(test:getOutputPath().."test_"..test:getId().."_latency_trimed.csv")
            return {}
        end

        -- create trimed data (remove first and last 2,5%)
        local var = RandomVariable:fromCsv('Test', 'number', csv, 1, 2, 1)
        local q_2_5, q_97_5 = var:getPercentil(0.025,0.975)
        var:slice(q_2_5,q_97_5):toCsv():toFile(test:getOutputPath().."test_"..test:getId().."_latency_trimed.csv")

        -- create histogram
        local hist = Histogram:parseCsv(csv)
        local collapsedHist = hist:collapse()
        local stats = collapsedHist:getStats()

        -- write csv
        local latency = FileContent("test_"..test:getId().."_latency")
        latency:addCsvList(collapsedHist:toCsv():getLines())
        table.insert(items, latency)

        -- find imported subintervals of histogram
        local intervals = collapsedHist:findImportantSubIntervals(0.05, 20)
        do
            -- remove useless hist details (zoom factor to low)
            local i = 1
            local histInterval = collapsedHist:getValueInterval()
            local histIntervalDist = histInterval.to - histInterval.from
            while i <= #intervals do
                local detailedHistInterval = intervals[i]
                local detailedHistIntervalDist = detailedHistInterval.to - detailedHistInterval.from
                if MetricLib.isZoomedGraphUseful(histIntervalDist-detailedHistIntervalDist, histIntervalDist) then
                    i = i + 1
                else
                    table.remove(intervals,i)
                end
            end
        end

        -- calc detailed histogram and write csv
        local detailHists = hist:getHistogramsForIntervals(intervals)   -- important: use hist and not collapsedHist
        for i=1,#detailHists do

            local detailHist = detailHists[i]
            detailHist = detailHist:slice(detailHist:getPercentil(0.025,0.975))
            detailHist = detailHist:collapse()
            detailHists[i] = detailHist

            local fileContent = FileContent("test_"..test:getId().."_latency-detail-"..i)
            fileContent:addCsvList(detailHist:toCsv():getLines())
            table.insert(items, fileContent)
        end

        -- create cummulativ distribution function figure
        local cumLatency = TexFigure("H")
        cumLatency:add(Graphs.lineGraph({
            x = { label="Latency [$\\mu$s]", interval={ from=0 } },
            y = { label="Probability [\\%]", interval={ from=0 } },
            boundaries = { x={from=stats.min, to=stats.max}, y={ from=0, to=100 } },
            caption = "Cumulative Distribution Function For Latency Distribution",
            fig = "test_"..test:getId()..":cumulated_latency"
        }, {
            { color="blue", marker="none", columns="x=time, y=totalPercentage", file="test_"..test:getId().."_latency.csv" }
        }))
        table.insert(items, cumLatency)

        -- create histogram figure
        do
            stats.normalDist = NormalDistribution(stats.mean, stats.variance):getTexFunction()

            local latency = TexFigure("H")
            latency:add(Graphs.Histogram({
                x="Latency [$\\mu$s]", y="Probability [\\%]",
                fig="test_"..test:getId()..":latency", caption="Latency Histogram (" .. stats.num .. " Samples)"
            }, "x=time, y=percentage", string.format("xmin=0,xmax=%s,ymin=0",stats.max*1.1), "test_" .. test:getId() .. "_latency.csv", stats.normalDist))
            table.insert(items, latency)

            local statsTable = MetricLib.getStatsTable("Statistics For Latency Histogram", stats)
            table.insert(items, statsTable)
        end

        -- create detailed figures
        for i=1,#detailHists do
            local statsDetail = detailHists[i]:getStats()
            statsDetail.normalDist = NormalDistribution(statsDetail.mean, statsDetail.variance):getTexFunction()
            local buffer = (statsDetail.max - statsDetail.min) * 0.1

            local latencyDetail = TexFigure("H")
            latencyDetail:add(Graphs.Histogram({
                x="Latency [$\\mu$s]", y="Probability [\\%]",
                fig="test_"..test:getId()..":latency-detail-"..i, caption="Zoomed Latency Histogram "..i .. " (" .. statsDetail.num .. " Samples)"
            }, "x=time, y=percentage", string.format("xmin=%s,xmax=%s,ymin=0",statsDetail.min-buffer,statsDetail.max+buffer), "test_"..test:getId().."_latency-detail-"..i..".csv", statsDetail.normalDist))
            table.insert(items, latencyDetail)

            local detailStatsTable = MetricLib.getStatsTable("Statistics For Zoomed Latency Histogram "..i, statsDetail)
            table.insert(items, detailStatsTable)
        end

        -- detailed latency occurrence figure
        TryCatchFinally(function ()

            -- read data and write csv
            local csvDetailedOccurrence = CSV:parseFile(test:getOutputPath().."test_"..test:getId().."_latency_detail.csv")
            local csvDetailedOccurrenceTrimed = CSV()
            local latencyDetailedOccurrence = FileContent("test_"..test:getId().."_latency_detailed_occurrence")
            latencyDetailedOccurrence:addCsvLine("time,latency")
            if #csvDetailedOccurrence.data > 1 then
                local i = 1
                local stepSize = math.ceil(#csvDetailedOccurrence.data/1000)

                local isTimeStamped = #csvDetailedOccurrence.data[1] > 1
                local baseTime = 2.001
                if isTimeStamped then baseTime = tonumber(csvDetailedOccurrence.data[1][1]) - tonumber(csvDetailedOccurrence.data[1][2]/1000000000) - baseTime end

                while (i <  #csvDetailedOccurrence.data) do
                    local item = csvDetailedOccurrence.data[i]
                    local time, value
                    if isTimeStamped then
                        time = tonumber(item[1]) - baseTime
                        value = tonumber(item[2])
                    else
                        baseTime = baseTime + 0.001
                        time = baseTime
                        value = tonumber(item[1])
                    end

                    if value < q_2_5 or value > q_97_5 then
                        i = i + 1
                    else
                        csvDetailedOccurrenceTrimed:addRow({time,value})
                        latencyDetailedOccurrence:addCsvLine(tostring(time)..","..tostring(value/1000))
                        i = i + stepSize
                    end
                end
            end
            csvDetailedOccurrenceTrimed:toFile(test:getOutputPath().."test_"..test:getId().."_latency_detail_trimed.csv")
            table.insert(items, latencyDetailedOccurrence)

            -- create figure
            local latencyDetailedOccurrenceFigure = TexFigure("H")
            latencyDetailedOccurrenceFigure:add(Graphs.lineGraph({
                x = { label="Time [s]", interval= { from=0 } },
                y = { label="Latency [$\\mu$s]", interval= { from=0 } },
                boundaries = {
                    x={ from=0, to=tonumber(csvDetailedOccurrenceTrimed.data[#csvDetailedOccurrenceTrimed.data][1]) },
                    y={ from=0, to=q_97_5/1000 }
                },
                caption = Tex.sanitize("Detailed Latency Occurrence (Using only data within 2.5% and 97.5% percentil)"),
                fig = "test_"..test:getId()..":latency-detailed-occurrence"
            }, {
                { color="blue", marker="none", columns="x=time, y=latency", file="test_"..test:getId().."_latency_detailed_occurrence.csv" }
            }))
            table.insert(items, latencyDetailedOccurrenceFigure)

        end, { LoadingFileException=function () end })

        return items
    end,
    grouped = function(parameter, testcases, ids)
        local elems = {}

        testcases =  MetricLib.getEnabledTestcases(testcases, ids)

        do
            local i = 1
            while i < #testcases do
                local testcase = testcases[i]
                if tonumber(testcase:getCurrentValueOfParameter("pktsize")) < 80 then
                    table.remove(testcases,i)
                else
                    i = i+1
                end
            end
        end

        if #testcases < 2 then return elems end

        -- prepare data

        local stats = {}
        for _,testcase in pairs(testcases) do
            local param = testcase:getCurrentValueOfParameter(parameter)

            local filepath = string.format("%stest_%s_latency_trimed.csv", testcase:getOutputPath(), testcase:getId())
            local csv = CSV:parseFile(filepath)
            local hist = Histogram:parseCsv(csv):collapse(1000)

            table.insert(stats, hist:getStats())
        end

        local isParameterNumeric = MetricLib.isParameterNumeric(testcases, parameter)

        -- write csv-data
        local latency = MetricLib.getFileContentForStats("latency", parameter, isParameterNumeric, testcases, stats)
        table.insert(elems, latency)

        -- create figures and statistics

        local min = MetricLib.getRandomVariableForStat(stats,'min'):getMinValue()
        local max = MetricLib.getRandomVariableForStat(stats,'max'):getMaxValue()
        local med = MetricLib.getRandomVariableForStat(stats,'med'):getStats()
        local zoomEnabled = MetricLib.isZoomedGraphUseful(min, max)

        local completeGraph, detailedGraph, statsTable = MetricLib.getGraphsForStats(
            testcases, parameter, isParameterNumeric, "latency.csv",
            Tex.sanitize("Latency (Using only data within 2.5% and 97.5% percentil)"), {
                y={
                    label="Latency [$\\mu$s]",
                    unit="$\\mu$s",
                    interval={
                        complete={ from=0 },
                        detailed={}
                    },
                    stats = med,
                    boundaries = { from=min, to=max }
                }
            }, "latency"
        )
        table.insert(elems, completeGraph)
        if (zoomEnabled) then table.insert(elems, detailedGraph) end
        table.insert(elems, statsTable)

        return elems
    end
}

return Metric
