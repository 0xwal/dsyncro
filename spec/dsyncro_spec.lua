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

    it('should not wrap the table if its already dsyncro instance', function()
        local playerList               = dsyncro.new()
        playerList['player-1']         = { name = 'player-name-1' }
        playerList['player-2']         = {  }
        playerList['player-2'].name    = 'player-name-2'
        playerList['player-1'].friends = {}
        table.insert(playerList['player-1'].friends, playerList['player-2'])
        assert.is_equal('player-name-2', playerList['player-1'].friends[1].name)
    end)

    it('should traverse key to parent if not exist in child', function()
        local dsyncro              = dsyncro.new()
        dsyncro['parent']          = { name = 'the-parent' }
        dsyncro['parent']['child'] = {}
        assert.is_equal('the-parent', dsyncro['parent']['child'].name)
    end)

    it('should prioritize key that exist in the instance', function()
        local dsyncro              = dsyncro.new()
        dsyncro['parent']          = { name = 'the-parent' }
        dsyncro['parent']['child'] = { name = 'the-child' }
        assert.is_equal('the-child', dsyncro['parent']['child'].name)
    end)

    it('should not iterate only on instance user items', function()
        local dsyncro = dsyncro.new()
        local spy     = spy()
        for _, _ in pairs(dsyncro) do
            spy()
        end
        assert.spy(spy).was_not_called()
    end)

    it('should be able to get the length of an array', function()
        local dsyncro       = dsyncro.new()
        dsyncro['students'] = {}
        table.insert(dsyncro['students'], 'Waleed')
        table.insert(dsyncro['students'], 'BISOON')
        assert.is_equal(2, #dsyncro['students'])
    end)

    it('expect __parent to be a function', function()
        local dsyncro       = dsyncro.new()
        dsyncro['students'] = {}
        assert.is_function(dsyncro['students'].__parent)
    end)

    it('expect __parent to be nil on direct instance of dsyncro', function()
        local dsyncro = dsyncro.new()
        assert.is_nil(dsyncro.__parent)
    end)

    describe('rawItems', function()
        local dsyncroInstance

        before_each(function()
            dsyncroInstance = dsyncro.new()
        end)

        it('exist', function()
            assert.is_function(dsyncroInstance.rawItems)
        end)

        it('should return items without returning the instance itself', function()
            dsyncroInstance['name']    = 'Waleed'
            dsyncroInstance['country'] = 'ksa'
            assert.are_same({ name = 'Waleed', country = 'ksa' }, dsyncroInstance:rawItems())
        end)

        it('should return items for nested tables', function()
            local githubObj            = {
                repositories = {
                    HelloWorld = {
                        desc  = 'hello world',
                        files = {
                            'file1',
                            'file2'
                        }
                    },
                    demo       = {
                        desc  = 'code demo',
                        files = {
                            'file1',
                            'file2',
                            'file3'
                        }
                    }
                },
                followers    = 50,
                following    = 30,
                bio          = {
                    name  = 'Waleed Al7arbi',
                    url   = 'http://github.com/0xWaleed',
                    email = 'imwaleed@outlook.sa'
                }
            }
            dsyncroInstance['name']    = 'Waleed'
            dsyncroInstance['address'] = { country = 'ksa', code = 966 }
            dsyncroInstance['github']  = githubObj
            assert.are_same({
                name    = 'Waleed',
                address = { country = 'ksa', code = 966 },
                github  = githubObj
            }, dsyncroInstance:rawItems())
        end)
    end)

    describe('watcher', function()
        it('should be able to add watcher to a property', function()
            local dsyncro    = dsyncro.new()
            local watcherSpy = spy()
            dsyncro['@name'] = watcherSpy
            dsyncro['name']  = 'waleed'
            assert.spy(watcherSpy).was_called_with('waleed', match.any)
            dsyncro['name'] = 'Waleed'
            assert.spy(watcherSpy).was_called_with('Waleed', match.any)

            assert.spy(watcherSpy).was_called(2)
        end)

        it('should able to invoke watcher when adding property to a table', function()
            local dsyncro        = dsyncro.new()
            local watcherSpy     = spy()
            dsyncro['@students'] = watcherSpy
            dsyncro['students']  = {}
            assert.spy(watcherSpy).was_called_with(match.object_contain({}), match.any)
            dsyncro['students']['waleed'] = true
            assert.spy(watcherSpy).was_called_with(match.object_contain({ waleed = true }), match.any)
            dsyncro['students']['bisoon'] = true
            assert.spy(watcherSpy).was_called_with(match.object_contain({ waleed = true, bisoon = true }), match.any)
            assert.spy(watcherSpy).was_called(3)
        end)

        it('should able to invoke watcher for a multi nested table when adding property', function()
            local dsyncro                = dsyncro.new()
            local watcherSpy             = spy()
            dsyncro['@class']            = watcherSpy
            dsyncro['class']             = {}
            dsyncro['class']['students'] = {}
            assert.spy(watcherSpy).was_called_with(match.object_contain({}), match.any)
            dsyncro['class']['students']['waleed'] = true
            assert.spy(watcherSpy).was_called_with(match.object_contain({ students = { waleed = true } }), match.any)
            dsyncro['class']['students']['bisoon'] = true
            assert.spy(watcherSpy).was_called_with(match.object_contain({ students = { waleed = true, bisoon = true } }), match.any)
            assert.spy(watcherSpy).was_called(4)
        end)

        it('should be able to invoke watcher for a table array that got a new value inserted', function()
            local dsyncro        = dsyncro.new()
            local watcherSpy     = spy()
            dsyncro['@students'] = watcherSpy
            dsyncro['students']  = {}
            assert.spy(watcherSpy).was_called_with(match.array_contain({}), match.any)
            table.insert(dsyncro['students'], 'Waleed')
            assert.spy(watcherSpy).was_called_with(match.array_contain({ 'Waleed' }), match.any)
            table.insert(dsyncro['students'], 'BISOON')
            assert.spy(watcherSpy).was_called_with(match.array_contain({ 'Waleed', 'BISOON' }), match.any)
            assert.spy(watcherSpy).was_called(3)
        end)

        it('should be able to invoke watcher for multi nested table that got a new value inserted', function()
            local dsyncro                = dsyncro.new()
            local watcherSpy             = spy()
            dsyncro['@class']            = watcherSpy
            dsyncro['class']             = {}
            dsyncro['class']['students'] = {}
            assert.spy(watcherSpy).was_called_with(match.array_contain({ students = {} }), match.any)
            table.insert(dsyncro['class']['students'], 'Waleed')
            assert.spy(watcherSpy).was_called_with(match.array_contain({ students = { 'Waleed' } }), match.any)
            table.insert(dsyncro['class']['students'], 'BISOON')
            assert.spy(watcherSpy).was_called_with(match.array_contain({ students = { 'Waleed', 'BISOON' } }), match.any)
            assert.spy(watcherSpy).was_called(4)
        end)

        it('should execute watcher when inserting a table to an array', function()
            local dsyncro        = dsyncro.new()
            local watcherSpy     = spy()
            dsyncro['@students'] = watcherSpy
            dsyncro['students']  = {}
            assert.spy(watcherSpy).was_called_with(match.array_contain({}), match.any)
            table.insert(dsyncro['students'], { name = 'Waleed' })
            assert.spy(watcherSpy).was_called_with(match.array_contain({ { name = 'Waleed' } }), match.any)
            assert.is_equal('Waleed', dsyncro['students'][1].name)

            table.insert(dsyncro['students'], { name = 'BISOON' })
            assert.spy(watcherSpy).was_called_with(match.array_contain({ { name = 'Waleed' }, { name = 'BISOON' } }), match.any)
            assert.is_equal('BISOON', dsyncro['students'][2].name)

            assert.spy(watcherSpy).was_called(3)
        end)

        it('should execute watcher for init value table as dsyncro instance', function()
            local dsyncro          = dsyncro.new()
            local watcherSpy       = spy()
            dsyncro.watch.students = watcherSpy
            dsyncro['students']    = { t = 99 }
            assert.spy(watcherSpy).was_called(1)
            assert.spy(watcherSpy).was_called_with(match.object_contain({ __store = { t = 99 } }), match.any)
        end)

        it('should execute watcher when add a table with inline child as table', function()
            local watcherSpy                    = spy()
            local data                          = dsyncro.new()
            data['@class']                      = watcherSpy
            data['class']                       = { students = {} }
            data['class']['students']['waleed'] = true
            assert.spy(watcherSpy).was_called_with(match.object_contain({ students = { waleed = true } }), match.any)
            data['class']['students']['bisoon'] = true
            assert.spy(watcherSpy).was_called_with(match.object_contain({ students = { waleed = true, bisoon = true } }), match.any)
            assert.spy(watcherSpy).was_called(3)
        end)

        it('should able to register a watcher using instance.watch.variable', function()
            local dsyncro      = dsyncro.new()
            local watcherSpy   = spy()
            dsyncro.watch.name = watcherSpy
            dsyncro.name       = 'waleed'
            assert.spy(watcherSpy).was_called_with('waleed', match.any)
            dsyncro.name = 'Waleed'
            assert.spy(watcherSpy).was_called_with('Waleed', match.any)
            assert.spy(watcherSpy).was_called(2)
        end)
    end)

    describe('accessor', function()
        it('should allow to add accessor', function()
            local data            = dsyncro.new()
            data.accessor['name'] = function(value)
                return string.upper(value)
            end
            data['name']          = 'waleed'
            assert.is_equal('WALEED', data['name'])
        end)
    end)

    describe('mutator', function()
        it('should allow to add mutator', function()
            local data           = dsyncro.new()
            data.mutator['name'] = function(value)
                return string.upper(value)
            end
            data['name']         = 'waleed'
            assert.is_equal('WALEED', data['name'])
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

    it('should not invoke when value is not changed', function()
        local value    = 'Waleed'
        local dsyncro  = dsyncro.new()
        local onSetSpy = spy()
        dsyncro:onKeySet(onSetSpy)
        dsyncro['name'] = value
        dsyncro['name'] = value
        assert.spy(onSetSpy).was_called(1)
        assert.spy(onSetSpy).was_called_with(match.any, 'name', 'Waleed')
    end)

    it('should able to set a value without invoking callback', function()
        local dsyncro  = dsyncro.new()
        local onSetSpy = spy()
        dsyncro:onKeySet(onSetSpy)
        dsyncro['-name'] = 'Waleed'
        assert.spy(onSetSpy).was_not_called()
        assert.is_equal('Waleed', dsyncro['name'])
    end)

    it('should able to set a value without invoking callback using silent property', function()
        local dsyncro  = dsyncro.new()
        local onSetSpy = spy()
        dsyncro:onKeySet(onSetSpy)
        dsyncro.silent['name'] = 'Waleed'
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
        table.insert(dsyncro['students'], 'bisoon')
        assert.spy(onSetSpy).was_called(3)
        assert.spy(onSetSpy).was_called_with(match._, 'students.1', 'waleed')
        assert.spy(onSetSpy).was_called_with(match._, 'students.2', 'bisoon')
    end)

    it('should invoke the handler with instance', function()
        local dsyncro  = dsyncro.new()
        local onSetSpy = spy()
        dsyncro:onKeySet(onSetSpy)
        dsyncro['students'] = {}
        assert.spy(onSetSpy).was_called_with(dsyncro, 'students', dsyncro['students'])
        table.insert(dsyncro['students'], 'waleed')
        assert.spy(onSetSpy).was_called_with(dsyncro['students'], 'students.1', 'waleed')
        assert.spy(onSetSpy).was_called(2)
    end)

    it('should invoke the handler with instance that correspond to instance when value is table', function()
        local dsyncro  = dsyncro.new()
        local onSetSpy = stub()
        dsyncro:onKeySet(onSetSpy)
        dsyncro['students']    = {}
        dsyncro['students'][1] = { name = 'Waleed' }
        assert.spy(onSetSpy).was_called_with(dsyncro['students'], 'students.1', match.object_contain { name = 'Waleed' })
        dsyncro['students'][2] = { name = 'BISOON' }
        assert.spy(onSetSpy).was_called_with(dsyncro['students'], 'students.2', match.object_contain { name = 'BISOON' })
        assert.spy(onSetSpy).was_called(3)
    end)

    it('should not invoke the handler when using the silent modifier with full path', function()
        local dsyncro  = dsyncro.new()
        local onSetSpy = spy()
        dsyncro:onKeySet(onSetSpy)
        dsyncro['-students.name'] = 'Waleed'
        assert.spy(onSetSpy).was_not_called()
        assert.is_equal('Waleed', dsyncro['students']['name'])
    end)

    it('should not invoke the handler when using the silent modifier with full path index', function()
        local dsyncro  = dsyncro.new()
        local onSetSpy = spy()
        dsyncro:onKeySet(onSetSpy)
        dsyncro['-students.1'] = 'Waleed'
        assert.spy(onSetSpy).was_not_called()
        assert.is_equal('Waleed', dsyncro['students'][1])
    end)

    it('should have the ability to register set handler on an instance level', function()
        local dsyncro                = dsyncro.new()
        local onSetSpy               = spy()
        dsyncro['students']          = {}
        dsyncro['students']['first'] = { name = 'Waleed' }
        dsyncro['students']['first']:onKeySet(onSetSpy)
        dsyncro['students']['first'].name  = '0xWaleed'
        dsyncro['students']['second']      = { name = 'Bisoon' }
        dsyncro['students']['second'].name = '0xBISOON'
        assert.spy(onSetSpy).was_called(1)
        assert.spy(onSetSpy).was_called_with(match.any, 'students.first.name', '0xWaleed')
        assert.spy(onSetSpy).was_not_called_with(match.any, 'students.second', match.any)
        assert.spy(onSetSpy).was_not_called_with(match.any, 'students.second.name', match.any)
    end)

    it('should able silent only a field in a table without silencing its siblings', function()
        local data     = dsyncro.new()
        local onSetSpy = spy()
        data:onKeySet(onSetSpy)
        data['students']         = {}
        data['students']['-id']  = 1
        data['students']['name'] = 'Waleed'
        assert.spy(onSetSpy).was_called(2)
        assert.spy(onSetSpy).was_called_with(match.any, 'students', match.any)
        assert.spy(onSetSpy).was_called_with(match.any, 'students.name', 'Waleed')
    end)

    it('should not silent a field that previously silenced', function()
        local data     = dsyncro.new()
        local onSetSpy = spy()
        data:onKeySet(onSetSpy)
        data['students']         = {}
        data['students']['-id']  = 1
        data['students']['id']   = 2
        data['students']['name'] = 'Waleed'
        assert.spy(onSetSpy).was_called(3)
        assert.spy(onSetSpy).was_called_with(match.any, 'students', match.any)
        assert.spy(onSetSpy).was_called_with(match.any, 'students.name', 'Waleed')
        assert.spy(onSetSpy).was_called_with(match.any, 'students.id', 2)
    end)

    it('should not silent a field that has a silenced parent', function()
        local data     = dsyncro.new()
        local onSetSpy = spy()
        data:onKeySet(onSetSpy)
        data['-student']        = {}
        data['student']['name'] = 'BISOON'

        data['student']['-id']  = 1
        data['student']['name'] = 'Waleed'
        data['student']['id']   = 2
        assert.spy(onSetSpy).was_called(3)
        assert.spy(onSetSpy).was_called_with(match.any, 'student.name', 'BISOON')
        assert.spy(onSetSpy).was_called_with(match.any, 'student.name', 'Waleed')
        assert.spy(onSetSpy).was_called_with(match.any, 'student.id', 2)
    end)
end)

describe('set value using path', function()

    before_each(function()
        hard_require('dsyncro')
    end)

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

    it('should convert key to number when number is last', function()
        local data         = dsyncro.new()
        data['students']   = {}
        data['students.1'] = 'Waleed'

        assert.is_equal('Waleed', data['students'][1])
    end)

    it('should convert key to number when number in the middle', function()
        local data              = dsyncro.new()

        data['students']        = {}
        data['students.1.name'] = 'Waleed'

        assert.is_equal('Waleed', data['students'][1]['name'])
    end)
end)
