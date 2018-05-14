local Metric = {
    output = {"_wire-rate.csv"},
    basic = function (test)
        local items = {}

        local csv = CSV:parseFile(test:getOutputPath() .. "test_" .. test:getId() .. "_wire-rate.csv")

        local devices = TexTable("|c|c|c|", "ht")
        devices:add("\\textbf{Link}", "\\textbf{MAC-Address}", "\\textbf{Rate}")
        for i=2,csv:getRowCount() do
            local row = csv:getRow(i)
            devices:add(tostring(row[1]), tostring(row[2]), tostring(row[3]))
        end
        table.insert(items, devices)

        local filepath = test:getOutputPath() .. "test_" .. test:getId() .. "_result.txt"
        local file = io.open(filepath, "r")
        local wire_rate = tonumber(file:read())
        file:close()

        local text = TexText()
        text:add("\\begin{center}", "\\textbf{Wire-Rate is ", tostring(wire_rate), ".}", "\\end{center}")
        table.insert(items, text)

        return items
    end
}

return Metric