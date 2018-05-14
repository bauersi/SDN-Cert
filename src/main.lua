#!/usr/bin/env lua

package.path = 'src/?.lua;' ..package.path

require "version"
require "globConst"

require "common/bundle"
require "core/bundle"
require "tools/bundle"
require "tex/bundle"

JSON = require "third-party/JSON"

settings = nil
debugMode = false

local function main()
  logger = Logger.init(global.logFile) 
  local f = io.open(global.configFile, "rb")  
  if f then f:close() else
    logger.printlog("Missing config file, created default")
    local file = io.open(global.configFile, "w")
    file:write(global.default_cfg)
    io.close(file)
  end

  logger.log("Command Line Args: " .. table.concat(arg, ' '))
   
  settings = Settings.create(global.configFile)
  settings.config.evalSingle = true
  settings.config.evalAdvanced = true

  local parser = ArgParser.create()
  parser:addOption("--setup", "installs MoonGen")
  parser:addOption("--init", "initializes MoonGen")
  parser:addOption("--sim", "all operations are printed, instead of executed")
  parser:addOption("--eval", "only starts the evaluation process (single and advanced reports)")
  parser:addOption("--evalSingle", "only starts the evaluation process (single reports)")
  parser:addOption("--evalAdvanced", "only starts the evaluation process (advanced reports)")
  parser:addOption("--nocolor", "disables the colored output")
  parser:addOption("--check", "checks if the test setup is correctly configured")
  parser:addOption("--tar", "creates a tar archive for the current and the final results folder")
  parser:addOption("--clean", "cleans the result folder")
  parser:addOption("--skipfeature", "skips all feature tests")
  parser:addOption("--testfeature=feature", "tests specific feature, nothing more will be done")
  parser:addOption("--verbose", "shows further information")
  parser:addOption("-O=OpenFlowVersion", "specifies the OpenFlow protocol version")
  parser:addOption("--version", "prints version information")
  parser:addOption("--help", "prints this help")
  
  parser:parse(arg)
  if (parser:hasOption("--help")) then parser:printHelp() ; exit() end
  if (parser:hasOption("--version")) then logger.print(Version.getVersion()) ; exit() end
  if (parser:hasOption("--init")) then Setup.initMoongen() ; exit() end
  if (parser:hasOption("--setup")) then Setup.setupMoongen() ; exit() end
  if (parser:hasOption("--tar")) then Setup.archive() ; exit() end
  if (parser:hasOption("--clean")) then Setup.cleanUp() ; exit() end

  if (parser:hasOption("--verbose")) then settings.config.verbose = true end
  if (parser:hasOption("--sim")) then settings.config.simulate = true end
  if (parser:hasOption("--nocolor")) then logger.disableColor() end
  if (parser:hasOption("--eval")) then
    settings.config.evalonly = true
  end
  if (parser:hasOption("--evalSingle")) then
    settings.config.evalonly = true ; settings.config.evalAdvanced = true
  end
  if (parser:hasOption("--evalAdvanced")) then
    settings.config.evalonly = true ; settings.config.evalSingle = true
  end
  settings:verify()

  if (parser:hasOption("--check")) then settings.config.checkSetup = true end
  if (parser:hasOption("--skipfeature")) then settings.config.skipfeature = true end
  if (parser:hasOption("--testfeature")) then settings.config.testfeature = parser:getOptionValue("--testfeature") end
  if (parser:hasOption("-O")) then settings.config[global.ofVersion] = string.gsub(parser:getOptionValue("-O"), "%.", "") end
  
  if settings.config.simulate then 
    print("*******************\n* Simulation-Mode *\n*******************")
    logger.log("*** Simulation-Mode ***")
  end
  
  if (settings.config.checkSetup) then logger.log("Testing, if the setup is correctly configured") end 
  if (settings.config.skipfeature) then logger.log("Skipping feature test, requirements will be ignored") end
  if (settings.config.testfeature) then logger.log("Testing feature '" .. settings.config.testfeature .. "', nothing more will be done") end 
  
  if (parser:getArgCount() ~= 1 and not settings.config.checkSetup and not settings.config.testfeature and not settings.config.evalonly) then
    print("you need to specify a benchmark file!")
    exit()
  end
  local benchmark_file = global.results .. "/all_tests.txt"
  if not settings.config.evalonly then benchmark_file = parser:getArg(1) end
  if (not (settings.config.checkSetup  or settings.config.testfeature) and not localfileExists(benchmark_file)) then
    print("no such file '" .. benchmark_file .. "'")
    exit(1)
  end

  if ((not settings:evalOnly() and not Setup.isReady() and not settings.config.simulate) or settings.config.checkSetup) then
    logger.printBar()
    exit()
  end

  local benchmark = Benchmark.create(benchmark_file)
  if (settings.config.verbose) then settings:print() end
  
  if (settings:evalOnly()) then
    benchmark:testFeatures()
    benchmark:sumFeatures()
    benchmark:prepare()
    benchmark:run()
    Reports.generate(benchmark)
    exit()
  end
  
  Setup.cleanUp()
  benchmark:testFeatures()
  benchmark:sumFeatures()
  benchmark:prepare()
  benchmark:run()
  Reports.generate(benchmark)
  
  if (settings:doArchive()) then Setup.archive() end
  
  logger.finalize()
end


xpcall(main, function (err)
  if isException(err) then
    exit(tostring(err))
  else
    exit(debug.traceback(err,2))
  end
end)