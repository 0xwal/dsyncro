---
--- Created By 0xWaleed <https://github.com/0xWaleed>
--- DateTime: 30/12/2021 4:24 PM
---

require('dsyncro')

local function global_on_key_set(instance, key, value)
    -- sync to another source on change
    print(instance, ('dispatch to another receiver[%s]'):format(instance.playerServerId), key, value)
end

playerList = dsyncro.new()

-- register set value handling to be invoked everytime value changed globally
playerList:onKeySet(global_on_key_set)

function initPlayer(key)
    return {
        name           = ('name-%s'):format(key),
        playerServerId = key,
        health         = 100,
        friends        = {}
    }
end

function player(id)
    local key = tostring(id)
    local p   = playerList[key]

    if not p then
        p               = initPlayer(key)
        playerList[key] = p
    end

    p['@health']  = function(value, instance)
        if value < 50 then
            print(('%s get medic fast, your health is too low [%s]'):format(instance.name, value))
        else
            print(('%s you still strong, fight back! [%s]'):format(instance.name, value))
        end
    end

    p['@money']   = function(value, instance)
        if value > 100 then
            print(('%s you are rich, can I get some of your money? [$%s]'):format(instance.name, value))
        else
            print(('%s sad to see you broken, find a decent job [$%s]'):format(instance.name, value))
        end
    end

    p['@friends'] = function(value, instance)
        print(('you got a new friend %s'):format(instance.name))
        for _, v in ipairs(value) do
            print(v.name)
        end
    end

    return p
end

function damage_player(playerServerId, damageLevel)
    local old                     = player(playerServerId).health
    player(playerServerId).health = old - damageLevel
end

function add_money(playerServerId, amount)
    local old                    = player(playerServerId).money or 0
    player(playerServerId).money = old + amount
end

function add_friendship(playerServerId, friendServerId)
    table.insert(player(playerServerId).friends, player(friendServerId))
    table.insert(player(friendServerId).friends, player(playerServerId))
end

damage_player(1, 40)
damage_player(3, 40)
damage_player(1, 20)

add_money(1, 40)
add_money(1, 1000)
add_money(3, 10)

add_friendship(1, 3)

print(player(1).health) -- health 50
print(player(3).health) -- health 60
