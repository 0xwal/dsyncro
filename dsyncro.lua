---
--- Created By 0xWaleed <https://github.com/0xWaleed>
--- DateTime: 30/12/2021 3:54 PM
---

local dsyncroMT = {}
dsyncro         = {}

local function explode_string(string, sep)
    sep     = sep or '%s'
    local t = {}
    for str in string.gmatch(string, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

local function invoke_watcher_recursively(t, k)
    local w = t.__watchers[k]

    if w then
        w(t[k])
    end

    if not t.__parent then
        return
    end

    invoke_watcher_recursively(t.__parent, t.__parentName)
end

local function reverse(t)
    local out = {}
    for i = #t, 1, -1 do
        table.insert(out, t[i])
    end
    return out
end

local function create_child_for(key, parent, items)
    local newT = dsyncro.new()

    for k, v in pairs(items) do
        newT.__store[k] = v
    end

    rawset(newT, '__parent', parent)
    rawset(newT, '__parentName', key)
    rawset(newT, '__settersCallback', parent.__settersCallback)

    return newT
end

local function has_watcher_modifier(key)
    return type(key) == 'string' and key:find('@')
end

local function has_full_path(key)
    return type(key) == 'string' and key:find('%.')
end

local function get_target_from_full_path(root, path)
    local keys      = explode_string(path, '.')
    local target    = root
    local keysCount = #keys
    local lastKey   = keys[keysCount]
    for i = 1, keysCount do
        local key = keys[i]
        if key == lastKey then
            break
        end

        if not target[key] then
            target[key] = create_child_for(key, root, {})
        end

        target = target[key]
    end
    return lastKey, target
end

local function has_silent_modifier(key)
    return string.find(key, '^-') ~= nil
end

local function sanitize_chars_from_string(key, char)
    return string.gsub(key, char, '')
end

function dsyncroMT:__newindex(key, value)
    if has_watcher_modifier(key) then
        local actualKey            = sanitize_chars_from_string(key, '@')
        self.__watchers[actualKey] = value
        return
    end

    if has_full_path(key) then
        local targetKey, target = get_target_from_full_path(self, key)
        target[targetKey]       = value
        return
    end

    local shouldBeSilent = has_silent_modifier(key)

    if shouldBeSilent then
        key = sanitize_chars_from_string(key, '%-')
    end

    if type(value) == 'table' then
        value = create_child_for(key, self, value)
    end

    if type(key) ~= 'number' then
        self.__store[key] = value
    else
        table.insert(self.__store, value)
    end

    if not shouldBeSilent then
        self:_invokeSetCallbacks(key, value)
    end

    invoke_watcher_recursively(self, key)
end

function dsyncroMT:onKeySet(callback)
    self.__settersCallback[tostring(callback)] = callback
end

function dsyncroMT:_invokeSetCallbacks(key, value)
    local path     = { key }
    local currentT = self
    while currentT do
        table.insert(path, currentT.__parentName)
        currentT = currentT.__parent
    end
    path = reverse(path)

    local instance

    if type(value) == 'table' and value.__store then
        instance = value
    else
        instance = self
    end

    for _, setter in pairs(self.__settersCallback) do
        setter(instance, table.concat(path, '.'), value)
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
