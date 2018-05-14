require "common/class"
require "tools/strings"
require "tools/csv"
require "tools/float"
require "tools/histogram"


TestHistogram = {}

function TestHistogram:testBasic1()

    local csv = CSV()
    local hist = Histogram:parseCsv(csv)
    local collapsedHist = hist:collapse(1000)
    local intervals = collapsedHist:findImportantSubIntervals(0.05, 20)
    local detailHists = hist:getHistogramsForIntervals(intervals)
    for i,detailLatency in pairs(detailHists) do
        detailLatency:collapse(1000):toCsv():getLines()
    end

end

function TestHistogram:testBasic2()

    local csv = CSV()
    csv:addLine('21656,1')
    local hist = Histogram:parseCsv(csv)
    local collapsedHist = hist:collapse(1000)
    local intervals = collapsedHist:findImportantSubIntervals(0.05, 20)
    local detailHists = hist:getHistogramsForIntervals(intervals)
    for i,detailLatency in pairs(detailHists) do
        detailLatency:collapse(1000):toCsv():getLines()
    end

end

function TestHistogram:testBasic3()

    local csv = CSV()
    csv:addLine('21656,1')
    csv:addLine('21657,1')
    local hist = Histogram:parseCsv(csv)
    local collapsedHist = hist:collapse(1000)
    local intervals = collapsedHist:findImportantSubIntervals(0.05, 20)
    local detailHists = hist:getHistogramsForIntervals(intervals)
    for i,detailLatency in pairs(detailHists) do
        detailLatency:collapse(1000):toCsv():getLines()
    end

end