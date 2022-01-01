---
--- Created By 0xWaleed <https://github.com/0xWaleed>
--- DateTime: 30/12/2021 10:27 AM
---

local function hard_require(module)
    local m                = require(module)
    package.loaded[module] = nil
    return m
end

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

    it('should be able to add watcher to a property', function()
        local dsyncro    = dsyncro.new()
        local watcherSpy = spy()
        dsyncro['@name'] = watcherSpy
        dsyncro['name']  = 'waleed'
        assert.spy(watcherSpy).was_called_with(nil, 'waleed')
        dsyncro['name'] = 'Waleed'
        assert.spy(watcherSpy).was_called_with('waleed', 'Waleed')

        assert.spy(watcherSpy).was_called(2)
    end)
end)

describe('sync', function()
    it('should able to add on set', function()
        local dsyncro  = dsyncro.new()
        local onSetSpy = spy()
        dsyncro:onKeySet(onSetSpy)
        dsyncro['name'] = 'Waleed'
        assert.spy(onSetSpy).was_called(1)
        assert.spy(onSetSpy).was_called_with('name', 'Waleed')
    end)

    it('should not invoke when value is not changed', function()
        local value    = 'Waleed'
        local dsyncro  = dsyncro.new()
        local onSetSpy = spy()
        dsyncro:onKeySet(onSetSpy)
        dsyncro['name'] = value
        dsyncro['name'] = value
        assert.spy(onSetSpy).was_called(1)
        assert.spy(onSetSpy).was_called_with('name', 'Waleed')
    end)

    it('should able to set a value without invoking callback', function()
        local dsyncro  = dsyncro.new()
        local onSetSpy = spy()
        dsyncro:onKeySet(onSetSpy)
        dsyncro['-name'] = 'Waleed'
        assert.spy(onSetSpy).was_not_called()
    end)
end)
