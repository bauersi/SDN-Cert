local lib = {}

lib.mbpsToMpps = function (mbps, pktSize)
    return mbps / (pktSize * 8)
end

lib.mppsToMbps = function (mpps, pktSize)
    return mpps * (pktSize * 8)
end

lib.getWireRate = function (testcases)

    local wire_rate = 1

    for _,test in ipairs(testcases) do
        if (not test:isDisabled()) and (test:getName() == "wire_rate") then
            local filepath = test:getOutputPath() .. "test_" .. test:getId() .. "_result.txt"
            local file = io.open(filepath, "r")
            local line = file:read()
            wire_rate = tonumber(line)
            file:close()
            break
        end
    end

    return wire_rate
end

lib.getLineRate = function (wire_rate, pktSize)
    return math.floor(wire_rate * (pktSize/(pktSize+20)))
end

lib.getEnabledTestcases = function (testcases, ids)
    local result = {}
    for _,id in pairs(ids) do
        local test = testcases[id]
        if not test:isDisabled() then
            table.insert(result, test)
        end
    end
    return result
end

lib.getStatsTable = function (caption, stats)
    local statsTable = TexTable("|c|c|c|c|c|c|c|","H")
    statsTable:setCaption(caption)
    statsTable:add(
        "\\textbf{Min}",
        "\\textbf{Low Perc.}",
        "\\textbf{Median}",
        "\\textbf{High Perc.}",
        "\\textbf{Max}",
        "\\textbf{Mean}",
        "\\textbf{Std. Derivation}"
    )
    statsTable:add(
        string.format("%.4f", stats.min),
        string.format("%.4f", stats.low),
        string.format("%.4f", stats.med),
        string.format("%.4f", stats.high),
        string.format("%.4f", stats.max),
        string.format("%.4f", stats.mean),
        string.format("%.4f", stats.stdDeviation)
    )
    return statsTable
end

lib.getRandomVariableForStat = function (items, statName)
    local var = RandomVariable(statName, 'number')
    for _,item in pairs(items) do
        var:add(item[statName], 1)
    end
    return var
end

lib.calcXBoundaries = function (testcases, parameter, isParameterNumeric)
    if isParameterNumeric then
        return {
            from=testcases[1]:getCurrentValueOfParameter(parameter),
            to=testcases[#testcases]:getCurrentValueOfParameter(parameter)
        }
    else
        return {
            from=testcases[1]:getId(),
            to=testcases[#testcases]:getId()
        }
    end
end

lib.getFileContentForStats = function (filename, parameter, isParameterNumeric, testcases, statsList)
    local filecontent = FileContent(filename)
    filecontent:addCsvLine("parameter, min, low, med, high, max, avg")
    for i=1,#testcases do

        local testcase = testcases[i]
        local parLabel
        if isParameterNumeric then
            parLabel = Tex.sanitize(testcase:getCurrentValueOfParameter(parameter))
        else
            parLabel = testcase:getId()
        end
        local stats = statsList[i]

        local line = ("%s; %.4f; %.4f; %.4f; %.4f; %.4f; %.4f"):format(parLabel, stats.min, stats.low, stats.med, stats.high, stats.max, stats.mean)
        line = string.replaceAll(line, ",", ".")
        filecontent:addCsvLine(string.replaceAll(line, ";", ","))
    end
    return filecontent
end

lib.getGraphsForStats = function (testcases, parameter, isParameterNumeric, filename, metricName, metricInfos, partFig)
    local completeGraph, detailedGraph = TexFigure("H"), TexFigure("H")

    local xBoundaries = lib.calcXBoundaries(testcases, parameter, isParameterNumeric)

    local completeGraphOptions = {
        y = {
            label=metricInfos.y.label,
            interval=metricInfos.y.interval.complete
        },
        boundaries = {
            x=xBoundaries,
            y=metricInfos.y.boundaries,
        },
        caption = string.format("%s For Parameter '%s'", metricName, parameter),
        fig="test_"..Tex.sanitize(parameter)..":grp:"..partFig
    }

    local detailedGraphOptions = {
        y = { label=completeGraphOptions.y.label, interval=metricInfos.y.interval.detailed  },
        boundaries = completeGraphOptions.boundaries,
        caption = "Zoomed " .. completeGraphOptions.caption,
        fig=completeGraphOptions.fig..":detail"
    }

    if metricInfos.y2 then
        completeGraphOptions.boundaries2 = {
            y=metricInfos.y2.boundaries
        }
        completeGraphOptions.y2 = {
            label=metricInfos.y2.label,
            interval=metricInfos.y2.interval.complete
        }

        detailedGraphOptions.boundaries2 = completeGraphOptions.boundaries2
        detailedGraphOptions.y2 = {
            label=completeGraphOptions.y2.label,
            interval=metricInfos.y2.interval.detailed
        }
    end

    if (isParameterNumeric) then
        local unit = testcases[1].config.units[parameter]

        completeGraphOptions.x = {
            label=string.format("Parameter '%s' [%s]", parameter, unit or ''),
            interval={}
        }
        completeGraph:add(Graphs.lineGraphForStats(completeGraphOptions, filename))

        detailedGraphOptions.x = completeGraphOptions.x
        detailedGraph:add(Graphs.lineGraphForStats(detailedGraphOptions, filename))
    else
        local plotOptions = { file = filename, count = #testcases }

        completeGraphOptions.x = { label="Testcase", interval={} }
        completeGraph:add(Graphs.boxGraphForStats(completeGraphOptions, plotOptions))

        detailedGraphOptions.x = completeGraphOptions.x
        detailedGraph:add(Graphs.boxGraphForStats(detailedGraphOptions, plotOptions))
    end

    local caption = string.format("Statistics Of Median For %s in %s", completeGraphOptions.caption, metricInfos.y.unit)
    local statsTable = lib.getStatsTable(caption, metricInfos.y.stats)

    local statsTable2
    if metricInfos.y2 then
        caption = string.format("Statistics Of Median For %s in %s", completeGraphOptions.caption, metricInfos.y2.unit)
        statsTable2 = lib.getStatsTable(caption, metricInfos.y2.stats)
    end

    return completeGraph, detailedGraph, statsTable, statsTable2
end

lib.isParameterNumeric = function (testcases, parameter)
    for _,testcase in pairs(testcases) do
        local param = testcase:getCurrentValueOfParameter(parameter)
        if not Float.tonumber(param) then
            return false
        end
    end
    return true
end

lib.isZoomedGraphUseful = function (min, max) return min / max >= 0.4 end

return lib