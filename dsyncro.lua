---
--- Created By 0xWaleed <https://github.com/0xWaleed>
--- DateTime: 30/12/2021 3:54 PM
---

local dsyncroMT   = {}
dsyncro           = {}

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

local function createChildFor(key, parent, items)
    local newT = dsyncro.new()
    for k, v in ipairs(items) do
        newT[k] = v
    end

    for k, v in pairs(items) do
        newT[k] = v
    end

    rawset(newT, '__parent', parent)
    rawset(newT, '__parentName', key)
    rawset(newT, '__settersCallback', parent.__settersCallback)
    return newT
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

    if type(value) == 'table' then
        local newT = createChildFor(key, t, value)
        value      = newT
    end

    if type(key) ~= 'number' then
        t.__store[key] = value
    else
        table.insert(t.__store, value)
    end

    if not shouldBeSilent then
        t:_invokeSetCallbacks(key, value)
    end

    invoke_watcher_recursively(t, key, value)
end

function dsyncroMT:onKeySet(callback)
    self.__settersCallback[tostring(callback)] = callback
end

local function reverse(t)
    local out = {}
    for i = #t, 1, -1 do
        table.insert(out, t[i])
    end
    return out
end

function dsyncroMT:_invokeSetCallbacks(key, value)
    local path     = { key }
    local currentT = self
    while currentT do
        table.insert(path, currentT.__parentName)
        currentT = currentT.__parent
    end
    path = reverse(path)
    for _, setter in pairs(self.__settersCallback) do
        setter(table.concat(path, '.'), value)
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
