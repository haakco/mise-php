package.path = "./?.lua;" .. package.path

local versions = require("lib/php_versions")
local host_config = package.config
local original_popen = io.popen
local expected_command

io.popen = function(command)
    assert(command:sub(1, #expected_command) == expected_command, command)
    return {
        read = function() return "mise ls-remote --prerelease php" end,
        close = function() end,
    }
end

-- Cross-platform lock metadata must not select the shell of the target OS.
RUNTIME = { osType = "windows" }
package.config = "/" .. host_config:sub(2)
expected_command = "ps "
assert(versions.prerelease_flag_enabled({}))

RUNTIME = { osType = "macos" }
package.config = "\\" .. host_config:sub(2)
expected_command = "powershell "
assert(versions.prerelease_flag_enabled({}))

package.config = host_config
io.popen = original_popen
print("Verified host shell selection is independent of the lock target")
