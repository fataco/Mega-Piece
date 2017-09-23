local received_first_tick = false
local do_show = false
local ticks   = 0

function window_hide ()
  window:hide()
  received_first_tick = false
  do_show             = false
end

function init()  
    window = g_ui.loadUI('gym', modules.game_interface.getRootPanel())
    window:disableResize()       
    window:setup()
    window_hide ()
    window:getChildById('minimizeButton'):destroy()
    
    connect(g_game, {onGameStart = onGameStart, onAttackingCreatureChange = onAttack})
            
    ProtocolGame.registerExtendedOpcode(GameServerOpcodes.GymTicks, function (protocol, opcode, buffer)
        --print("RECEIVED OPCODE DO GYM")        
        ticks = tonumber(buffer) or 0
        received_first_tick = true         
    end)
    runGymThread()            
end

function terminate()
    window:destroy()
    disconnect(g_game, {onGameStart = onGameStart, onAttackingCreatureChange = onAttack})
    ProtocolGame.unregisterExtendedOpcode(GameServerOpcodes.GymTicks)
end

function quit()
    g_game.talk("!leavegym")
    g_game:cancelAttackAndFollow()
    window_hide()        
end

function request_gym_information()
    local protocolGame = g_game.getProtocolGame()
    if protocolGame then
        protocolGame:sendExtendedOpcode(ClientOpcodes.RequestGymInformations)
    end
end

function onGameStart()
    window_hide()
    request_gym_information()
end

function onAttack(creature)
    if creature and creature:getName() == "Training Machine" then
        do_show = true
        if not received_first_tick then
          request_gym_information()
        end        
    else
        window_hide()
    end  
end

function seconds_to_clock(seconds)
    local seconds = tonumber(seconds)
    if seconds == 0 then
        return "00:00:00";
    end
    hours = string.format("%02.f", math.floor(seconds / 3600))
    mins  = string.format("%02.f", math.floor(seconds / 60 - (hours * 60)))
    secs  = string.format("%02.f", math.floor(seconds - hours * 3600 - mins * 60))
    return hours .. ":" .. mins .. ":" .. secs
end

function runGymThread ()
  
    -- Ja foi destruido
    if not window then
      return
    end
  
    if do_show and received_first_tick then
        window:show()
        window:setPosition({ x = g_window.getWidth() * 0.4, y = g_window.getHeight() * 0.5})
        do_show = false
    end
  
    if window:isVisible() then
        local lblTick = window:getChildById('lblTick')
        if ticks > 0 then            
            lblTick:setText(seconds_to_clock(ticks))
        else                    
            lblTick:setText('Time left!')
        end
    end
    ticks = math.max(0, ticks - 1)
    scheduleEvent(runGymThread, 1000)
end