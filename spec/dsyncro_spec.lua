---
--- Created By 0xWaleed <https://github.com/0xWaleed>
--- DateTime: 30/12/2021 10:27 AM
---

local function hard_require(module)
    local m                = require(module)
    package.loaded[module] = nil
    return m
end

local function internal_compare(value, expected, iterator)
    local hasError = false
    for k, _ in iterator(expected) do
        local expectedValue = expected[k]
        local actualValue   = value[k]

        if type(expectedValue) ~= type(actualValue) then
            return false
        end

        if type(expectedValue) == 'table' then

            if #expectedValue ~= #actualValue then
                return false
            end

            return internal_compare(actualValue, expectedValue, iterator)
        end

        if expectedValue ~= actualValue then
            return false
        end

        if hasError then
            return false
        end
    end
    return true
end

local function object_contain(_, args)
    local expected = args[1]
    return function(value)
        return internal_compare(value, expected, pairs)
    end
end

local function array_contain(_, args)
    local expected = args[1]
    return function(value)
        return internal_compare(value, expected, ipairs)
    end
end

assert:register('matcher', 'object_contain', object_contain)
assert:register('matcher', 'array_contain', array_contain)
assert:register('matcher', 'any', function()
    return function() return true end
end)

describe('dsyncro', function()

    before_each(function()
        hard_require('dsyncro')
    end)

    it('should be table', function()
        assert.is_table(dsyncro)
    end)

    it('should has new', function()
        assert.is_function(dsyncro.new)
    end)

    it('should be able to set a property', function()
        local dsyncro   = dsyncro.new()
        dsyncro['name'] = 'Waleed'
        assert.is_equal('Waleed', dsyncro['name'])
    end)

    describe('watcher', function()
        it('should be able to add watcher to a property', function()
            local dsyncro    = dsyncro.new()
            local watcherSpy = spy()
            dsyncro['@name'] = watcherSpy
            dsyncro['name']  = 'waleed'
            assert.spy(watcherSpy).was_called_with('waleed', match.any())
            dsyncro['name'] = 'Waleed'
            assert.spy(watcherSpy).was_called_with('Waleed', match.any())

            assert.spy(watcherSpy).was_called(2)
        end)

        it('should able to invoke watcher when adding property to a table', function()
            local dsyncro        = dsyncro.new()
            local watcherSpy     = spy()
            dsyncro['@students'] = watcherSpy
            dsyncro['students']  = {}
            assert.spy(watcherSpy).was_called_with(match.object_contain({}), match.any())
            dsyncro['students']['waleed'] = true
            assert.spy(watcherSpy).was_called_with(match.object_contain({ waleed = true }), match.any())
            dsyncro['students']['bisoon'] = true
            assert.spy(watcherSpy).was_called_with(match.object_contain({ waleed = true, bisoon = true }), match.any())
            assert.spy(watcherSpy).was_called(3)
        end)

        it('should able to invoke watcher for a multi nested table when adding property', function()
            local dsyncro                = dsyncro.new()
            local watcherSpy             = spy()
            dsyncro['@class']            = watcherSpy
            dsyncro['class']             = {}
            dsyncro['class']['students'] = {}
            assert.spy(watcherSpy).was_called_with(match.object_contain({}), match.any())
            dsyncro['class']['students']['waleed'] = true
            assert.spy(watcherSpy).was_called_with(match.object_contain({ students = { waleed = true } }), match.any())
            dsyncro['class']['students']['bisoon'] = true
            assert.spy(watcherSpy).was_called_with(match.object_contain({ students = { waleed = true, bisoon = true } }), match.any())
            assert.spy(watcherSpy).was_called(4)
        end)

        it('should be able to invoke watcher for a table array that got a new value inserted', function()
            local dsyncro        = dsyncro.new()
            local watcherSpy     = spy()
            dsyncro['@students'] = watcherSpy
            dsyncro['students']  = {}
            assert.spy(watcherSpy).was_called_with(match.array_contain({}), match.any())
            table.insert(dsyncro['students'], 'Waleed')
            assert.spy(watcherSpy).was_called_with(match.array_contain({ 'Waleed' }), match.any())
            table.insert(dsyncro['students'], 'BISOON')
            assert.spy(watcherSpy).was_called_with(match.array_contain({ 'Waleed', 'BISOON' }), match.any())
            assert.spy(watcherSpy).was_called(3)
        end)

        it('should be able to invoke watcher for multi nested table that got a new value inserted', function()
            local dsyncro                = dsyncro.new()
            local watcherSpy             = spy()
            dsyncro['@class']            = watcherSpy
            dsyncro['class']             = {}
            dsyncro['class']['students'] = {}
            assert.spy(watcherSpy).was_called_with(match.array_contain({ students = {} }), match.any())
            table.insert(dsyncro['class']['students'], 'Waleed')
            assert.spy(watcherSpy).was_called_with(match.array_contain({ students = { 'Waleed' } }), match.any())
            table.insert(dsyncro['class']['students'], 'BISOON')
            assert.spy(watcherSpy).was_called_with(match.array_contain({ students = { 'Waleed', 'BISOON' } }), match.any())
            assert.spy(watcherSpy).was_called(4)
        end)

        it('should execute watcher when inserting a table to an array', function()
            local dsyncro        = dsyncro.new()
            local watcherSpy     = spy()
            dsyncro['@students'] = watcherSpy
            dsyncro['students']  = {}
            assert.spy(watcherSpy).was_called_with(match.array_contain({}), match.any())
            table.insert(dsyncro['students'], { name = 'Waleed' })
            assert.spy(watcherSpy).was_called_with(match.array_contain({ { name = 'Waleed' } }), match.any())
            assert.is_equal('Waleed', dsyncro['students'][1].name)

            table.insert(dsyncro['students'], { name = 'BISOON' })
            assert.spy(watcherSpy).was_called_with(match.array_contain({ { name = 'Waleed' }, { name = 'BISOON' } }), match.any())
            assert.is_equal('BISOON', dsyncro['students'][2].name)

            assert.spy(watcherSpy).was_called(3)
        end)

        it('should execute watcher for init value table as dsyncro instance', function()
            local dsyncro        = dsyncro.new()
            local watcherSpy     = spy()
            dsyncro['@students'] = watcherSpy
            dsyncro['students']  = { t = 99 }
            assert.spy(watcherSpy).was_called(1)
            assert.spy(watcherSpy).was_called_with(match.object_contain({ __store = { t = 99 } }), match.any())
        end)
    end)
end)

describe('dsyncro set handler', function()

    before_each(function()
        hard_require('dsyncro')
    end)

    it('should able to add on set', function()
        local dsyncro  = dsyncro.new()
        local onSetSpy = spy()
        dsyncro:onKeySet(onSetSpy)
        dsyncro['name'] = 'Waleed'
        assert.spy(onSetSpy).was_called(1)
        assert.spy(onSetSpy).was_called_with(match._, 'name', 'Waleed')
    end)

    --todo required for later, we don't want to execute watcher for uncached value
    --it('should not invoke when value is not changed', function()
    --    local value    = 'Waleed'
    --    local dsyncro  = dsyncro.new()
    --    local onSetSpy = spy()
    --    dsyncro:onKeySet(onSetSpy)
    --    dsyncro['name'] = value
    --    dsyncro['name'] = value
    --    assert.spy(onSetSpy).was_called(1)
    --    assert.spy(onSetSpy).was_called_with('name', 'Waleed')
    --end)

    it('should able to set a value without invoking callback', function()
        local dsyncro  = dsyncro.new()
        local onSetSpy = spy()
        dsyncro:onKeySet(onSetSpy)
        dsyncro['-name'] = 'Waleed'
        assert.spy(onSetSpy).was_not_called()
        assert.is_equal('Waleed', dsyncro['name'])
    end)

    it('should invoke the handler with full key path', function()
        local dsyncro  = dsyncro.new()
        local onSetSpy = spy()
        dsyncro:onKeySet(onSetSpy)
        dsyncro['students']           = {}
        dsyncro['students']['waleed'] = true
        assert.spy(onSetSpy).was_called(2)
        assert.spy(onSetSpy).was_called_with(match._, 'students.waleed', true)
    end)

    it('should invoke the handler with full key path for nested multi level nested table', function()
        local dsyncro  = dsyncro.new()
        local onSetSpy = spy()
        dsyncro:onKeySet(onSetSpy)
        dsyncro['class']                       = {}
        dsyncro['class']['students']           = {}
        dsyncro['class']['students']['waleed'] = true
        assert.spy(onSetSpy).was_called(3)
        assert.spy(onSetSpy).was_called_with(match._, 'class.students.waleed', true)
    end)

    it('should invoke the handler with full key path that has array', function()
        local dsyncro  = dsyncro.new()
        local onSetSpy = spy()
        dsyncro:onKeySet(onSetSpy)
        dsyncro['students'] = {}
        table.insert(dsyncro['students'], 'waleed')
        assert.spy(onSetSpy).was_called(2)
        assert.spy(onSetSpy).was_called_with(match._, 'students.1', 'waleed')
    end)

    it('should invoke the handler with instance', function()
        local dsyncro  = dsyncro.new()
        local onSetSpy = spy()
        dsyncro:onKeySet(onSetSpy)
        dsyncro['students'] = {}
        assert.spy(onSetSpy).was_called_with(dsyncro['students'], 'students', match.any())
        table.insert(dsyncro['students'], 'waleed')
        assert.spy(onSetSpy).was_called_with(dsyncro['students'], 'students.1', 'waleed')
        assert.spy(onSetSpy).was_called(2)
    end)
end)

describe('set value using path', function()
    it('should be able to set value using path', function()
        local data          = dsyncro.new()
        data['person']      = {}
        data['person.name'] = 'Waleed'
        assert.is_equal(data['person']['name'], 'Waleed')
    end)

    it('should be able to set value in nested table using path', function()
        local data                 = dsyncro.new()
        data['class']              = {}
        data['class']['student']   = {}
        data['class.student.name'] = 'Waleed'
        assert.is_equal(data['class']['student']['name'], 'Waleed')
    end)

    it('should be able to set value using path', function()
        local data          = dsyncro.new()
        data['person.name'] = 'Waleed'
        assert.is_equal(data['person']['name'], 'Waleed')
    end)

end)
