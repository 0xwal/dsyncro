---
--- Created By 0xWaleed <https://github.com/0xWaleed>
--- DateTime: 30/12/2021 3:54 PM
---

local dsyncroMT  = {}

local watchMT    = {
    __newindex = function(t, k, v)
        t.__dsyncroInstance['@' .. k] = v
    end,
}

local accessorMT = {
    __newindex = function(t, k, v)
        t.__dsyncroInstance.__accessors[k] = v
    end,
}

local mutatorMT  = {
    __newindex = function(t, k, v)
        t.__dsyncroInstance.__mutators[k] = v
    end,
}

local function watch(dsyncroInstance)
    local o             = {}
    o.__dsyncroInstance = dsyncroInstance
    setmetatable(o, watchMT)
    return o
end

local function accessor(dsyncroInstance)
    local o             = {}
    o.__dsyncroInstance = dsyncroInstance
    setmetatable(o, accessorMT)
    return o
end

local function mutator(dsyncroInstance)
    local o             = {}
    o.__dsyncroInstance = dsyncroInstance
    setmetatable(o, mutatorMT)
    return o
end

dsyncro = {}

local function explode_string(string, sep)
    sep     = sep or '%s'
    local t = {}
    for str in string.gmatch(string, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

local function reverse(t)
    local out = {}
    for i = #t, 1, -1 do
        table.insert(out, t[i])
    end
    return out
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

        if tonumber(key) then
            key = tonumber(key)
        end

        if not target[key] then
            target[key] = target:createChild(key, {})
        end

        target = target[key]
    end

    if tonumber(lastKey) then
        lastKey = tonumber(lastKey)
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

    if has_silent_modifier(key) then
        key           = sanitize_chars_from_string(key, '%-')
        self.__silent = true
    end

    if has_full_path(key) then
        local targetKey, target = get_target_from_full_path(self, key)
        target[targetKey]       = value
        return
    end

    if type(value) == 'table' and not dsyncro.classOf(value) then
        value = self:createChild(key, value)
    end

    if self.__store[key] == value then
        return
    end

    local mutatorFunc = self.__mutators[key]
    self.__store[key] = mutatorFunc and mutatorFunc(value) or value

    if not self.__silent then
        self:invokeSetCallbacks(key, value)
    end

    self:invokeWatchers(key)
end

function dsyncroMT:onKeySet(callback)
    self.__settersCallback[tostring(callback)] = callback
end

function dsyncroMT:traverseToRoot()
    local currentInstance = self
    return function()
        local instanceToReturn = currentInstance
        if not instanceToReturn then
            return
        end
        currentInstance = rawget(instanceToReturn, '__parent')
        return instanceToReturn
    end
end

function dsyncroMT:invokeWatchers(key)
    local w = self.__watchers[key]

    if w then
        w(self[key], self)
    end

    if not self.__parent then
        return
    end

    self.__parent:invokeWatchers(self.__key)
end

function dsyncroMT:createChild(key, items)
    local newT = dsyncro.new()

    for k, v in pairs(items) do
        newT[k] = v
    end

    rawset(newT, '__parent', self)
    rawset(newT, '__key', key)

    return newT
end

function dsyncroMT:invokeSetCallbacks(key, value)
    local handlers = {}
    local path     = { key }

    for instance in self:traverseToRoot() do
        if instance.__silent then
            return
        end

        for _, setterCallback in pairs(instance.__settersCallback) do
            table.insert(handlers, setterCallback)
        end

        table.insert(path, instance.__key)
    end

    path = table.concat(reverse(path), '.')

    if #handlers < 1 then
        return
    end

    for _, setter in pairs(handlers) do
        setter(self, path, value)
    end
end

function dsyncroMT:rawItems()
    local rawItems = {}
    local items    = self.__store
    for key, value in pairs(items) do
        if dsyncro.classOf(value) then
            rawItems[key] = value:rawItems()
        else
            rawItems[key] = value
        end
    end
    return rawItems
end

function dsyncroMT:__index(key)

    if key == 'watch' then
        return rawget(self, '__watch')
    end

    if key == 'accessor' then
        return rawget(self, '__accessor')
    end

    if key == 'mutator' then
        return rawget(self, '__mutator')
    end

    local value = self.__store[key]

    if value then
        if not self.__accessors[key] then
            return value
        end
        return self.__accessors[key](value)
    end

    value = dsyncroMT[key]

    if value then
        return value
    end

    if key == '__parent' or key == '__key' then
        return
    end

    for instance in self:traverseToRoot() do
        value = rawget(rawget(instance, '__store'), key)
        if value then
            return value
        end
    end

end

function dsyncroMT:__pairs()
    return next, self.__store
end

function dsyncroMT:__len()
    return #self.__store
end

function dsyncro.new()
    local o             = { __dsyncro = true }
    o.__watchers        = {}
    o.__store           = {}
    o.__settersCallback = {}
    o.__accessors       = {}
    o.__mutators        = {}
    o.__watch           = watch(o)
    o.__accessor        = accessor(o)
    o.__mutator         = mutator(o)
    setmetatable(o, dsyncroMT)
    return o
end

function dsyncro.classOf(value)
    return type(value) == 'table' and value.__dsyncro
end
