-- Timber bootstrap loader
-- Use this file as your GitHub raw entrypoint.

local SOURCES = {
    -- Primary: obfuscated/protected script from Jnkie
    "https://api.jnkie.com/api/v1/luascripts/public/bd87f96d1c5aef95c820f28c475d94e97fd1e0b02800c3f3e3d0db715ea5ed2e/download",
    -- Fallback: plain script on GitHub
    "https://raw.githubusercontent.com/insiderins/scriptlua/main/timbermakro.lua"
}

local compiler = loadstring or load
if not compiler then
    error("Executor does not support loadstring/load")
end

local function fetch(url)
    local ok, body = pcall(function()
        return game:HttpGet(url, true)
    end)

    if not ok then
        return nil, "HttpGet failed: " .. tostring(body)
    end

    if type(body) ~= "string" or #body < 16 then
        return nil, "empty/invalid body"
    end

    local probe = string.lower(string.sub(body, 1, 220))
    if string.find(probe, "<!doctype", 1, true)
        or string.find(probe, "<html", 1, true)
        or string.find(probe, "404: not found", 1, true) then
        return nil, "endpoint returned html/404"
    end

    return body
end

local errors = {}
for _, url in ipairs(SOURCES) do
    local src, fetchErr = fetch(url)
    if src then
        local fn, loadErr = compiler(src)
        if fn then
            return fn()
        end
        table.insert(errors, string.format("%s -> compile error: %s", url, tostring(loadErr)))
    else
        table.insert(errors, string.format("%s -> fetch error: %s", url, tostring(fetchErr)))
    end
end

error("All loader sources failed:\n" .. table.concat(errors, "\n"))
