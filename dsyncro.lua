---
--- Created By 0xWaleed <https://github.com/0xWaleed>
--- DateTime: 30/12/2021 3:54 PM
---

local dsyncroMT      = {}
dsyncro              = {}

dsyncroMT.__index    = function(t, k)
    return t.__store[k]
end

dsyncroMT.__newindex = function(t, key, value)

    if key:find('@') then
        local actualKey         = string.gsub(key, '@', '')
        t.__watchers[actualKey] = value
        return
    end

    local watcher  = t.__watchers[key]

    local oldValue = t.__store[key]

    if oldValue == value then
        return
    end

    t.__store[key] = value

    t:_invokeSetCallbacks(key, value)

    if watcher then
        watcher(oldValue, value)
    end
end

function dsyncroMT:onKeySet(callback)
    self.__settersCallback[tostring(callback)] = callback
end

function dsyncroMT:_invokeSetCallbacks(key, value)
    for _, callback in pairs(self.__settersCallback) do
        callback(key, value)
    end
end

function dsyncro.new()
    local o             = {}
    o.__watchers        = {}
    o.__store           = {}
    o.__settersCallback = {}
    setmetatable(o, dsyncroMT)
    dsyncroMT.__index = function(t, k)
        return t.__store[k] or dsyncroMT[k]
    end
    return o
end
