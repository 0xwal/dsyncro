---
--- Created By 0xWaleed <https://github.com/0xWaleed>
--- DateTime: 30/12/2021 3:54 PM
---

local dsyncroMT   = {}
dsyncro           = {}

dsyncroMT.__index = function(t, k)
    return t.__store[k]
end

local function invoke_watcher_recursively(t, k, v)
    local w = t.__watchers[k]

    if w then
        w(v)
    end

    if not t.__parent then
        return
    end

    invoke_watcher_recursively(t.__parent, t.__parentName, t.__parent.__store[t.__parentName])
end

dsyncroMT.__newindex = function(t, key, value)
    if type(key) == 'string' and key:find('@') then
        local actualKey         = string.gsub(key, '@', '')
        t.__watchers[actualKey] = value
        return
    end

    local shouldBeSilent = string.find(key, '^-') ~= nil

    if shouldBeSilent then
        key = string.gsub(key, '-', '')
    end

    if type(value) ~= 'table' then
        if type(key) == 'number' then
            table.insert(t.__store, value)
        else
            t.__store[key] = value
        end
    else
        local newT = dsyncro.new()
        for k, v in pairs(value) do
            newT[k] = v
        end

        rawset(newT, '__parent', t)
        rawset(newT, '__parentName', key)

        if type(key) == 'number' then
            table.insert(t.__store, value)
        else
            t.__store[key] = newT
        end
    end

    if not shouldBeSilent then
        t:_invokeSetCallbacks(key, value)
    end

    invoke_watcher_recursively(t, key, value)
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
