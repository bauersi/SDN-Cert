
Tex = {}

-- source: http://www.cespedes.org/blog/85/how-to-escape-latex-special-characters
local SPECIAL_CHARS = {
    ['&'] = "\\&",
    ['%'] = "\\%",
    ['$'] = "\\$",
    ['#'] = "\\#",
    ['_'] = "\\_",
    ['{'] = "\\{",
    ['}'] = "\\}",
    ['\\'] = "\\textbackslash{}",
    ['~'] = "\\textasciitilde{}",
    ['^'] = "\\textasciicircum{}"
}

function Tex.sanitize(text)
    if type(text) ~= "string" then return text end
    local result = string.gsub(text, "[&%%$#_{}^~\\]", SPECIAL_CHARS)
    return result
end