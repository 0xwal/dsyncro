---
--- Created By 0xWaleed <https://github.com/0xWaleed>
--- DateTime: 30/12/2021 3:54 PM
---

local dsyncroMT         = {}

dsyncro                 = setmetatable({}, dsyncroMT)
dsyncro.__index         = dsyncro

local g_settersCallback = {}

local g_watchers        = {}

local g_store           = {}

dsyncroMT.__index       = g_store

local function invoke_callback_on(key, value)
    for _, setter in pairs(g_settersCallback) do
        setter(key, value)
    end
end

dsyncroMT.__newindex = function(_, key, value)
    if key:find('@') then
        local actualKey       = string.gsub(key, '@', '')
        g_watchers[actualKey] = value
        return
    end

    local watcher  = g_watchers[key]

    local oldValue = g_store[key]

    g_store[key]   = value

    invoke_callback_on(key, value)

    if watcher then
        watcher(oldValue, value)
    end
end

function dsyncro.on_set(callback)
    g_settersCallback[tostring(callback)] = callback
end
