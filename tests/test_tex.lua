require "../globConst"
require "tools/general"
require "tools/strings"
require "tex/general"

Test_Tex = {

    test_sanitize_basis = function ()

        local text = " Test & % $ # _ { } ~ ^ \\ & % $ # _ { } ~ ^ \\ "

        local actual1, actual2 = Tex.sanitize(text)

        local expected = " Test \\& \\% \\$ \\# \\_ \\{ \\} \\textasciitilde{} \\textasciicircum{} \\textbackslash{} \\& \\% \\$ \\# \\_ \\{ \\} \\textasciitilde{} \\textasciicircum{} \\textbackslash{} "

        luaunit.assertEquals(actual1, expected)
        luaunit.assertEquals(actual2, nil)
    end

}