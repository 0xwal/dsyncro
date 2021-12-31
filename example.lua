---
--- Created By 0xWaleed <https://github.com/0xWaleed>
--- DateTime: 30/12/2021 4:24 PM
---

require('dsyncro')

local function global_on_key_set(client, key, value)
    print(client, 'has set and we dispatch', key, value)
end

playerList = dsyncro.new()

function player(id)
    local p = playerList[tostring(id)]
    if not p then
        playerList[tostring(id)] = dsyncro.new()
        p                        = playerList[tostring(id)]
        p:onKeySet(function(key, value)
            global_on_key_set(id, key, value)
        end)
    end
    return p
end

player(1).name = 'Waleed'
player(2).name = '0xWaleed'
player(3).name = 'BISOON'
player(3).name = 'Mohammed'
player(3).name = 'Waleed'
