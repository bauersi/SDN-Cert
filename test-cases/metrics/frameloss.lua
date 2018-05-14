local MetricLib = require "metrics/lib"

local Metric = {
    output = {"_load_rx.csv", "_load_tx.csv"},
    basic = function (test)
        local items = {}

        -- load data
        local col = 2 -- total
        local csv_rx = CSV:parseFile(test:getOutputPath() .. "test_" .. test:getId() .. "_load_rx.csv")
        local csv_tx = CSV:parseFile(test:getOutputPath() .. "test_" .. test:getId() .. "_load_tx.csv")

        local to = math.min(csv_rx:getRowCount(), csv_tx:getRowCount())

        -- prepare data
        local csv_loss = CSV()
        csv_loss:addRow({ "time", "totalTx", "totalRx", "totalDiff", "totalDiffPercentage", "tx", "rx", "diff", "diffPercentage" })
        local varFramelossRate = RandomVariable('frameloss rate', 'number')
        local varFrameLostTotalDiff = RandomVariable('totalDiff', 'number')
        for i=2, to, 1 do
            local totalRx = tonumber(csv_rx:getRow(i)[col])
            local totalTx = tonumber(csv_tx:getRow(i)[col])
            local totalDiff = totalTx - totalRx
            local totalDiffPercentage = 0
            if totalTx ~= 0 then
                totalDiffPercentage = totalDiff/totalTx*100
            end
            varFrameLostTotalDiff:add(totalDiff, 1)

            local relRx = totalRx
            local relTx = totalTx
            if (i > 2) then
                relRx = relRx - tonumber(csv_rx:getRow(i-1)[col])
                relTx = relTx - tonumber(csv_tx:getRow(i-1)[col])
            end
            local relDiff = relTx - relRx
            local relDiffPercentage = 0
            if relTx ~= 0 then
                relDiffPercentage = relDiff/relTx*100
            end
            varFramelossRate:add(relDiff, 1)

            csv_loss:addRow({ tostring(i-1), tostring(totalTx), tostring(totalRx), tostring(totalDiff), tostring(totalDiffPercentage), tostring(relTx), tostring(relTx), tostring(relDiff), tostring(relDiffPercentage) })
        end
        csv_loss:toFile(test:getOutputPath() .. "test_" .. test:getId() .. "_paket_loss.csv")

        -- Create csv
        local lossFile = FileContent("test_"..test:getId().."_loss")
        lossFile:addCsvList(csv_loss:getLines())
        table.insert(items, lossFile)

        -- Graph for Total Frame Loss
        local totalLossFigure = TexFigure("H")
        totalLossFigure:add(Graphs.lineGraph({
            x = { label="Time [s]", interval={ from=0, to=to+1 } },
            y = { label="$Tx_i$ - $Rx_i$ [Pakets]", interval= { from=0 } },
            boundaries = {
                x={ from=0, to=to },
                y=varFrameLostTotalDiff:getValueInterval()
            },
            caption = "Difference Between Total Transmitted And Total Received Frames",
            fig = "test_"..test:getId()..":total-frameloss"
        }, {
            { columns="x=time, y=totalDiff", file="test_"..test:getId().."_loss.csv" }
        }))
        table.insert(items, totalLossFigure)

        -- Summary for Total Frame Loss
        local lossLastRow = csv_loss:getRow(csv_loss:getRowCount())
        local totalLossTable = TexTable("|l|r|","H")
        totalLossTable:setCaption(Tex.sanitize("Statistics For Difference Between Transmitted and Received Frames"))
        totalLossTable:add("\\textbf{Total Number Of Frames Transmitted}", lossLastRow[2])
        totalLossTable:add("\\textbf{Total Number Of Frames Lost}", lossLastRow[4])
        totalLossTable:add("\\textbf{Frame Loss Rate}", string.format("%.2f ",lossLastRow[5]).."\\%")
        table.insert(items, totalLossTable)

        -- Graph for Frame Loss Rate
        local relLossFigure = TexFigure("H")
        relLossFigure:add(Graphs.lineGraph({
            x = { label="Time [s]", interval= { from=0, to=to+1 } },
            y = {
                label="($Tx_{i-1}$ - $Rx_{i-1}$) - ($Tx_i$ - $Rx_i$) [Pakets]",
                interval= {}
            },
            boundaries = {
                x={ from=0, to=to },
                y=varFramelossRate:getValueInterval()
            },
            caption = "Change In Difference Between Transmitted And Received Frames At Step i and i-1",
            fig = "test_"..test:getId()..":rel-frameloss"
        }, {
            { columns="x=time, y=diff", file="test_"..test:getId().."_loss.csv" }
        }))
        table.insert(items, relLossFigure)

        -- Summary for Frame Loss Rate
        local caption = "Statistics For Change In Difference Between Transmitted And Received Frames At Step i and i-1"
        local stats = varFramelossRate:getStats()
        local statsTable = MetricLib.getStatsTable(caption, stats)
        table.insert(items, statsTable)

        return items
    end,
    grouped = function(parameter, testcases, ids)
        local elems = {}

        testcases =  MetricLib.getEnabledTestcases(testcases, ids)
        if #testcases < 2 then return elems end

        -- prepare data
        local isParameterNumeric = MetricLib.isParameterNumeric(testcases, parameter)

        local statsData = {}
        local colTotalDiff = 4 -- select totalDiff values
        local colRate = 5
        for _,testcase in pairs(testcases) do
            local param = testcase:getCurrentValueOfParameter(parameter)

            local filepath = string.format("%stest_%s_paket_loss.csv", testcase:getOutputPath(), testcase:getId())
            local csv = CSV:parseFile(filepath)

            local lastRow = csv:getRow(csv:getRowCount())
            local var = RandomVariable:fromCsv('total diff', 'number', csv, colTotalDiff, nil, 2)

            table.insert(statsData, {
                max = var:getMaxValue(),
                total = tonumber(lastRow[colTotalDiff]),
                rate = tonumber(lastRow[colRate])
            })
        end

        -- write csv-data
        local loss = FileContent("loss-grp")
        loss:addCsvLine("parameter, max, total, rate")
        for i=1, #testcases do

            local testcase = testcases[i]
            local parLabel
            if isParameterNumeric then
                parLabel = Tex.sanitize(testcase:getCurrentValueOfParameter(parameter))
            else
                parLabel = testcase:getId()
            end
            local stats = statsData[i]

            local line = ("%s; %s; %s; %.4f"):format(parLabel, stats.max, stats.total, stats.rate)
            line = string.replaceAll(line, ",", ".")
            loss:addCsvLine(string.replaceAll(line, ";", ","))
        end
        table.insert(elems, loss)

        local unit = testcases[1].config.units[parameter] or ''

        -- figure preparation
        local getGraphForStats = function (graphOptions, plotOptions)

            graphOptions.x = { interval={} }
    	    local xBoundaries = MetricLib.calcXBoundaries(testcases, parameter, isParameterNumeric)
            graphOptions.boundaries.x = xBoundaries

            local figure = TexFigure("H")
            if (isParameterNumeric) then
                graphOptions.x.label = string.format("Parameter '%s' [%s]", parameter, unit)
                figure:add(Graphs.lineGraph(graphOptions, {plotOptions}))
            else
                graphOptions.x.label = "Testcase"
                figure:add(Graphs.pointGraph(graphOptions, plotOptions))
            end
            return figure
        end

        -- create figure "Loss Rate For Parameter ..."
        do
            local varRate = MetricLib.getRandomVariableForStat(statsData,'rate')

            local graphOptions = {
                y = { label = "Loss Rate [\\%]", interval={ from=0 } },
                boundaries = { y=varRate:getValueInterval() },
                caption = "Loss Rate For Parameter '" .. parameter .. "'",
                fig="test_"..Tex.sanitize(parameter)..":grp:lossRate"
            }
            if varRate:getMaxValue() <= 0 then graphOptions.y.interval.to=1 end

            local plotOptions = { file="loss-grp.csv", columns="y=rate" }

            local lossRate = getGraphForStats(graphOptions, plotOptions)
            table.insert(elems, lossRate)

            local caption = "Statistics For " .. graphOptions.caption
            local statsTable = MetricLib.getStatsTable(caption, varRate:getStats())
            table.insert(elems, statsTable)
        end

        -- create figure "Total Number Of Frames Lost For Parameter ..."
        do
            local varTotal = MetricLib.getRandomVariableForStat(statsData,'total')

            local graphOptions = {
                y = { label = "Lost Frames [Pakets]", interval={} },
                boundaries = { y=varTotal:getValueInterval() },
                caption="Total Number Of Frames Lost For Parameter '" .. parameter .. "'",
                fig="test_"..Tex.sanitize(parameter)..":grp:lossTotal"
            }
            if varTotal:getMinValue() >= 0 then graphOptions.y.interval.from=0 end
            if varTotal:getMaxValue() <= 0 then graphOptions.y.interval.to=1 end

            local plotOptions = { file="loss-grp.csv", columns="y=total" }

            local totalLoss = getGraphForStats(graphOptions, plotOptions)
            table.insert(elems, totalLoss)

            local caption = "Statistics For " .. graphOptions.caption
            local statsTable = MetricLib.getStatsTable(caption, varTotal:getStats())
            table.insert(elems, statsTable)
        end

        -- create figure "Maximum Difference Between Tx And Rx For Parameter  ..."
        do
            local varMax = MetricLib.getRandomVariableForStat(statsData,'max')

            local graphOptions = {
                y = { label = "Difference [Pakets]", interval={ from=0 } },
                boundaries = { y=varMax:getValueInterval() },
                caption = "Maximum Difference Between Tx And Rx For Parameter '" .. parameter .. "'",
                fig = "test_"..Tex.sanitize(parameter)..":grp:lossMax"
            }

            local plotOptions = { columns="y=max", file="loss-grp.csv" }

            local maxLoss = getGraphForStats(graphOptions, plotOptions)
            table.insert(elems, maxLoss)

            local caption = "Statistics For " .. graphOptions.caption
            local statsTable = MetricLib.getStatsTable(caption, varMax:getStats())
            table.insert(elems, statsTable)
        end

        return elems
    end
}

return Metric
