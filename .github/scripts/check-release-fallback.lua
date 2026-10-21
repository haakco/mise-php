package.path = "./?.lua;" .. package.path

package.loaded["lib/env"] = { SKIP_DEPS = true }
package.loaded["lib/static_php"] = { is_requested = function() return false end }
package.loaded["lib/tools"] = { shell_quote = function(value) return value end }

local status, body = 200, ''
package.loaded["http"] = {
    get = function(request)
        assert(request.url:match("^https://raw%.githubusercontent%.com/php/php%-src/php%-"))
        return { status_code = status, body = body }, nil
    end,
}

local versions = require("lib/php_versions")
RUNTIME = { osType = "linux" }
PLUGIN = { Available = function() return { versions.available_record("8.5.11") } end }
dofile("hooks/pre_install.lua")
version_check_before_dependencies = function() end
version_check_after_dependencies = function() end
install_dependencies = function() end

for _, version in ipairs({ "8.3.36", "8.4.27", "8.5.12" }) do
    body = '#define PHP_VERSION "' .. version .. '"'
    local release = PLUGIN:PreInstall({ version = version })
    assert(release.version == version)
    assert(release.url == "https://github.com/php/php-src/archive/php-" .. version .. ".tar.gz")
end

status, body = 404, ''
local ok, err = pcall(function() PLUGIN:PreInstall({ version = "8.5.999" }) end)
assert(not ok and tostring(err):find("Version not found", 1, true))

status, body = 200, '#define PHP_VERSION "8.5.11"'
ok, err = pcall(function() PLUGIN:PreInstall({ version = "8.5.12" }) end)
assert(not ok and tostring(err):find("Version not found", 1, true))

print("Verified release fallback accepts published security tags and rejects missing or mismatched tags")
