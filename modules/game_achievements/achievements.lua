local form = {
    widget              = nil,
    window              = nil,    
    lblPoints           = nil,
    listBoxAchievements = nil,
    listBoxLines        = {},  -- Tabela de labels
}   
   
function init()  
    
    form.widget = modules.client_topmenu.addRightGameToggleButton('achievementsButton', tr('Achievements'), 'icon', toggle)
    form.window = g_ui.loadUI('achievements', modules.game_interface.getRootPanel()) --, modules.game_interface.getRightPanel())
    form.window:setPosition({ x = g_window.getWidth() * 0.4, y = g_window.getHeight() * 0.5})
    form.window:setup()
    --form.window:disableResize()       
    form.window:getChildById('minimizeButton'):destroy()
    form.window:hide()
    
    form.lblPoints           = form.window:getChildById('lblPoints')
    form.listBoxAchievements = form.window:getChildById('listBoxAchievements')

    doBuildWindow(0, {})
    
    ProtocolGame.registerExtendedOpcode(ClientOpcodes.RequestAchievements, function (protocol, opcode, buffer)
        --print(buffer)
        local __buffer = loadstring('return ' .. buffer)()
        if __buffer then
            doBuildWindow(__buffer.points, __buffer.t)    
        end 
    end)

    connect(g_game, {onGameStart = onGameStartCallback})  
end

function terminate()
    form.widget:destroy()
    form.window:destroy()
    disconnect(g_game, {onGameStart = onGameStartCallback})
    ProtocolGame.unregisterExtendedOpcode(ClientOpcodes.RequestAchievements)
end

function toggle()
    if not form.widget:isOn() then
        local protocolGame = g_game.getProtocolGame()
        if protocolGame then
            protocolGame:sendExtendedOpcode(ClientOpcodes.RequestAchievements)
        end
        form.widget:setOn(true)
        form.window:open()        
    else
        form.widget:setOn(false)
        form.window:hide()
    end
end

function onGameStartCallback()  
    if form.widget:isOn() then
        toggle()
    end
    
    local protocolGame = g_game.getProtocolGame()
    if protocolGame then
        protocolGame:sendExtendedOpcode(ClientOpcodes.RequestAchievements)
    end
end

function doBuildWindow(points, achievements)
        
    form.lblPoints:setText('Points: ' .. (tonumber(points) or '?'))
    
    -- Remover linhas de achievements
    for _, label in pairs(form.listBoxLines) do      
      label:destroy()
    end
    form.listBoxLines = {}
    
    -- Re-adicionar linhas
    for index, achievement in pairs(achievements) do        
        local label = g_ui.createWidget('CustomLabel', form.listBoxAchievements)
        label:setId("index" .. index)
        label.index = index
        label:setText(achievement)
        table.insert(form.listBoxLines, label)
    end
    
end