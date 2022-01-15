# Dsyncro

A single file declarative library to extend a table and make it reactive to changes

## Motivation

* I wanted a way to update values in FiveM server side and the effect should be carried out to 
  client without creating an event in both client/server to just synchronize the data.
* I want to have the ability to encapsulate logic for accessors and mutators to transform value on setting/getting them.
* I want the table to be smart and aware of my needs/logic.

## Features

* Field Watchers
* Field Accessors
* Field Mutators
* Instance Global Handlers

## Usage

### Synchronize data to other remote/local processes

#### Examples

#### In this example I want to use dsyncro to synchronize data between server and client.

```lua
local player = dsyncro.new()

player:onKeySet(function(instance, key, value)
    -- execute your logic on all changes
    -- send to server login
end)

function on_message_received(key, value) 
    -- this line to set the change received from other processes
    player[key] = value
end

-- all changes below will trigger onKeySet callback

player.name = 'Waleed'

player.coords = {}

player.coords.x = 12.6
player.coords.y = 88.0
player.coords.z = 98.2
```

### Execute logic on any specific value changes

#### Examples

##### Settings changes (String/Number)

```lua
local settings = dsyncro.new()

-- register a change watcher to be triggered on `theme` change
settings['@theme'] = function(value)
    -- do the logic to chane the UI
end

-- in later time value changed by user
settings.theme = 'dark'  -- will trigger the `@theme` handler
settings.theme = 'light' -- will trigger the `@theme` handler
```

##### User Notifications (Table as array)

```lua
local user = dsyncro.new()

-- init
user.notifications = {}
user.name = 'Waleed'

-- register a change watcher to be triggered on `theme` change
-- **user.watch.notifications same user['@notifications']**
user.watch.notifications = function(notifications)
    print(('you got %s notifications'):format(#notifications))
    -- ...
end


table.insert(user.notifications, 'You got a new friend request')
table.insert(user.notifications, 'Your disk space is full')
```

##### Config (Table as dictionary)

```lua
local user = dsyncro.new()

-- init
user.config = { 
    channel = 'stable',
    autoupdate = true,
    telemetry = true
}

user.watch.config = function(config)
    -- dump to file
    json.encode(config:rawItems()) -- rawItems to void dumping metadata
end

-- in later time, user changes
user.config.channel = 'beta'
user.config.autoupdate = false
user.config.telemetry = false
```

### Mutators

With mutators, you can transform value on change

#### Examples

```lua
local data = dsyncro.new()

data.mutator.password = function(value)
  return fake_hash(value)
end

data.password = '12345'

print(data.password) -- hashed
```

### Accessors

With accessors, you can transform value on change

#### Examples

```lua
local data = dsyncro.new()

data.mutator.price = function(value)
  return value * 100
end

data.accessor.price = function(value) 
  return value / 100
end

data.price = '12.8'

print(data.price) -- price here is 12.8
print(json.encode(data:rawItems())) -- now price in data is 1280
```
