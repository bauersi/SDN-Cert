Reports = {}
Reports.__index = Reports

--------------------------------------------------------------------------------
--  class for generating the LaTeX reports
--------------------------------------------------------------------------------

Reports.allReports = {}
Reports.frontReport = 1

--- Adds a report to the list. The list has two points for adding new elements
-- Either at the end, or if front is specified to the priority position.
function Reports.addReport(doc, title, front)
  if (front == nil) then fron = false end
  local item = {
    file = string.replace(doc:getFile(), settings:getLocalPath() .. "/" .. global.results, ".") .. ".tex",
    title = title
  }
  if (front) then
    table.insert(Reports.allReports, Reports.frontReport, item)
    Reports.frontReport = Reports.frontReport + 1
  else
    table.insert(Reports.allReports, item)
  end
end

function Reports.generateBasicReports(testcases)
  for id,testcase in pairs(testcases) do
    logger.printlog("Generating reports ( " .. id .. " / " .. #testcases .. " ): " .. testcase:getName(), nil, global.headline1)
    if (not testcase:isDisabled()) then
      local doc = Reports.createBasicTestReport(testcase)
      doc:saveToFile(settings:getLocalPath() .. "/" .. global.results .. "/" .. testcase:getName() .. "/eval", testcase:getCompleteName())
      doc:generatePDF()
      Reports.addReport(doc, "Basic Report Test " .. testcase:getId() .. " - " .. testcase:getName())
    elseif (settings:doSimulate()) then logger.print("skipping report, no data available")
    else logger.warn("Test failed, skipping report") end
  end
end

function Reports.generateGroupedReports(globalDB, testcases)
  for currentTestName,testDB in pairs(globalDB) do
    -- iterate and create one report over every testname
    local reports = {}
    for currentParameter,_ in pairs(globalDB[currentTestName].paramaterList) do
      -- iterate over all parameters of the current test
      local set = {}
      for id,testParameter in pairs(testDB.testParameter) do
        -- create configuration key, containing all other parameters
        local conf = {}
        for parameter,value in pairs(testParameter) do
          if (parameter ~= currentParameter) then
            table.insert(conf, parameter .. "=" .. value)
          end
        end
        table.sort(conf)
        conf = table.concat(conf, ",")
        logger.debug("processing " .. currentParameter .. " with conf-key: " .. conf)
        -- count all test with the same conf-key
        if (not set[conf]) then set[conf] = {num = 0, ids = {}} end
        set[conf].num = set[conf].num + 1
        -- insert current test id to the list
        table.insert(set[conf].ids, id)
      end
      for conf,data in pairs(set) do
        if (data.num > 1) then
          logger.debug(conf .. " #:" .. data.num)
          if (not reports[currentParameter]) then
            logger.printlog("Generating advanced report for " .. currentTestName .. "/" .. currentParameter, nil, global.headline1)
            local doc = Reports.createGroupedReport(currentTestName, currentParameter)
            reports[currentParameter] = doc
          end
          if (not settings:doSimulate()) then
            local doc = reports[currentParameter]
            Reports.extendGroupedReport(doc, testcases, currentParameter, data.ids)
          end
        end
      end
    end
    for par,report in pairs(reports) do
      report:saveToFile(settings:getLocalPath() .. "/" .. global.results .. "/" .. currentTestName .. "/eval", "parameter_" .. par)
      report:generatePDF()
      Reports.addReport(report, "Advanced Report " .. currentTestName .. "-" .. par, true)
    end
  end
end

function Reports.generateAdvancedReports(globalDB, testcases)
  for currentTestName, testDB in pairs(globalDB) do
    logger.printlog("Generating advanced report for " .. currentTestName, nil, global.headline1)
    local doc = Reports.createAdvancedReport(testcases, testDB.ids)
    if (doc ~= nil) then
      doc:saveToFile(settings:getLocalPath() .. "/" .. global.results .. "/" .. currentTestName .. "/eval", "advanced")
      doc:generatePDF()
      Reports.addReport(doc, "Advanced Report " .. currentTestName, true)
    end
  end
end

--- Generates the single-test reports and the accumulated advanced reports
function Reports.generate(benchmark)
  if (settings.config.evalSingle) then
    Reports.generateBasicReports(benchmark.testcases)
  end

  if (settings.config.evalAdvanced) then
    local globalDB = benchmark:generateTestDB()
    Reports.generateGroupedReports(globalDB, benchmark.testcases)
    Reports.generateAdvancedReports(globalDB, benchmark.testcases)
  end

  if (not benchmark:checkExit()) then
    Reports.summarize()
  end
  logger.printBar()
end

--- Generates the feature report.
function Reports.generateFeatureReport(featureList)
  local doc = TexDocument.create()
  local colorDef = TexText()
  colorDef:add("\\definecolor{darkgreen}{rgb}{0, 0.45, 0}")
  colorDef:add("\\definecolor{darkred}{rgb}{0.9, 0, 0}")
  doc:addElement(colorDef)
  local title = TexText()
  title:add("\\begin{center}", "\\begin{LARGE}", "\\textbf{Summary Feature-Tests}", "\\end{LARGE}", "\\end{center}")
  local ofvers = TexText()
  title:add("\\begin{center}", "\\begin{huge}", "Version: " .. Tex.sanitize(settings:getOFVersion()), "\\end{huge}", "\\end{center}")
  doc:addElement(ofvers)
  doc:addElement(title)
  local features = TexTable("|l|l|l|l|","ht")
  features:add("\\textbf{feature}", "\\textbf{type}", "\\textbf{version}", "\\textbf{status}")
  for _,feature in pairs(featureList) do
    features:add(Tex.sanitize(feature:getName()), Tex.sanitize(feature:getState()), Tex.sanitize(feature:getRequiredOFVersion()), feature:getTexStatus())
  end
  doc:addElement(features)
  doc:saveToFile(settings:getLocalPath() .. "/" .. global.results .. "/features/eval", "Feature-Tests")
  doc:generatePDF()
  Reports.addReport(doc, "Feature-Tests", true)
end

--- Creates a single test report from a testcase.
function Reports.createBasicTestReport(testcase, error)
  local doc = TexDocument.create()
  local title = TexText()
  if (not error) then
    title:add("\\begin{center}", "\\begin{LARGE}", "\\textbf{" .. Tex.sanitize("Test " .. testcase:getId() .. ": " .. testcase:getName()) .. "}", "\\end{LARGE}", "\\end{center}")
  else
    title:add("\\begin{center}", "\\begin{LARGE}", "\\textbf{" .. Tex.sanitize("FAILED - Test " .. testcase:getId() .. ": " .. testcase:getName()) .. "}", "\\end{LARGE}", "\\end{center}")
  end
  doc:addElement(title)
  doc:addElement(testcase:getParameterTable())

  for _,metric_name in pairs(testcase:getMetric()) do
    local config = require("metrics/"..metric_name)
    if type(config.basic) == "function" then
      logger.debug("apply metric '" .. metric_name .. ".basic'", 1, global.headline2)
      local items = config.basic(testcase)
      for _,item in pairs(items) do
        doc:addElement(item)
      end
    else
      logger.debug("metric '" .. metric_name .. ".basic' not defined", 1, global.headline2)
    end
  end

  return doc
end

function Reports.createGroupedReport(currentTest, currentParameter)
  local doc = TexDocument.create()
  local title = TexText()
  title:add("\\begin{center}", "\\begin{LARGE}", "\\textbf{Test: " .. Tex.sanitize(currentTest) .. "}", "\\end{LARGE}", "\\end{center}")
  doc:addElement(title)
  local subtitle = TexText()
  subtitle:add("\\begin{center}", "\\begin{huge}", "parameter: " .. Tex.sanitize(currentParameter), "\\end{huge}", "\\end{center}")
  doc:addElement(subtitle)
  return doc
end

--- Creates an advanced report and adds it to the list of reports for
-- the current parameter.
function Reports.extendGroupedReport(doc, testcases, currentParameter, ids)
  local testcase = testcases[ids[1]]

  local metric_names = testcase:getMetric()
  if #metric_names == 0 then return end

  local elems = {}
  for _,metric_name in pairs(metric_names) do
    local metric = require("metrics/"..metric_name)
    if type(metric.grouped) == "function" then
      logger.debug("apply metric '" .. metric_name .. ".grouped'", 1, global.headline2)
      local paramElems = metric.grouped(currentParameter, testcases, ids)
      if paramElems then
        for _,elem in pairs(paramElems) do
          table.insert(elems, elem)
        end
      end
    else
      logger.debug("metric '" .. metric_name .. ".grouped' not defined", 1, global.headline2)
    end
  end
  if #elems == 0 then
    logger.debug("metric '" .. metric_name .. ".grouped' empty result", 1, global.headline2)
    return
  end

  local parameter = testcase:getParameterTable(currentParameter)
  parameter:add("involved tests", Tex.sanitize(table.concat(ids, ", ")), "IDs")
  doc:addElement(parameter)
  for _,elem in pairs(elems) do
    doc:addElement(elem)
  end
  doc:addClearPage()
end

function Reports.createAdvancedReport(testcases, ids)
  local testcase = testcases[ids[1]]
  local metric_names = testcase:getMetric()
  if #metric_names == 0 then return end

  local elems = {}
  for _,metric_name in pairs(metric_names) do
    local metric = require("metrics/"..metric_name)
    if type(metric.advanced) == "function" then
      logger.debug("apply metric '" .. metric_name .. ".advanced'", 1, global.headline2)
      local paramElems = metric.advanced(testcases, ids)
      if paramElems then
        for _,elem in pairs(paramElems) do
          table.insert(elems, elem)
        end
      end
    else
      logger.debug("metric '" .. metric_name .. ".advanced' not defined", 1, global.headline2)
    end
  end
  if #elems == 0 then return end

  local doc = TexDocument.create()
  local title = TexText()
  title:add("\\begin{center}", "\\begin{LARGE}", "\\textbf{Test: " .. Tex.sanitize(testcase:getName()) .. "}", "\\end{LARGE}", "\\end{center}")
  doc:addElement(title)

  for _,elem in pairs(elems) do
    doc:addElement(elem)
  end
  doc:addClearPage()
  return doc
end

--
function Reports.handleInfoTex(doc)
  local localPath = settings:getLocalPath()
  if absfileExists(localPath .. '/info.tex') then
    local cmd = CommandLine.create("cd " .. localPath)
    cmd:addCommand(string.format("cp %s %s", localPath .. '/info.tex', localPath..'/'..global.results..'/info.tex'))
    cmd:execute(true)

    local item = TexText()
    item:add("\\chapter{Information}")
    item:add("\\input{./info.tex}")
    doc:addElement(item)
  end
end

--- Creates the full sumary report containing all existing reports.
function Reports.summarize()
  logger.printlog("Generating full report, may take a while", nil, global.headline1)
  local doc = TexDocument.create()
  doc:usePackage("standalone")
  doc:usePackage("hyperref")
  local pre = TexText()
  pre:add("\\tableofcontents")
  pre:add("\\renewcommand{\\chaptername}{}")
  pre:add("\\renewcommand{\\thechapter}{}")
  doc:addElement(pre)

  Reports.handleInfoTex(doc)

  for _,report in pairs(Reports.allReports) do
    local item = TexText()
    item:add("\\chapter{" .. Tex.sanitize(report.title) .. "}")
    item:add("\\input{" .. report.file .. "}")
    doc:addElement(item)
  end
  doc:saveToFile(settings:getLocalPath() .. "/" .. global.results, "Report")
  doc:generatePDF()
end

return Reports