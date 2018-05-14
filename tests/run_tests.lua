luaunit = require('luaunit')

package.path = '../src/?.lua;' .. package.path

require "test_exception"
require "test_strings"
require "test_general"
require "test_csv"
require "test_histogram"
require "test_random_variable"
require "test_commonTest"
require "test_tex"

os.exit( luaunit.LuaUnit.run() )