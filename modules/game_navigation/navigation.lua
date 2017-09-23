local form = {
    item          = nil,
    lblNavigation = nil,
    btnStart      = nil,        
    btnExtract    = nil,  
}

function init()  
    
    widget = modules.client_topmenu.addRightGameToggleButton('navigationButton', tr('Navigation'), 'icon', toggle)
    window = g_ui.loadUI('navigation', modules.game_interface.getRightPanel())
    window:setup()
    window:disableResize()       
    window:getChildById('minimizeButton'):destroy()
    window:hide()    
    
    form.item          = window:getChildById("item_boat")
    form.lblNavigation = window:getChildById("lblNavigation")
    form.btnStart      = window:getChildById('btnStart')        
    form.btnExtract    = window:getChildById('btnExtract')
    
    doBuildWindow(false, 0, 0)
    
    connect(g_game, {onGameStart = online})
    
    ProtocolGame.registerExtendedOpcode(GameServerOpcodes.NavigationInformations, function (protocol, opcode, buffer)
        --print(buffer)
        local __buffer = loadstring('return ' .. buffer)()
        if __buffer then
            doBuildWindow(__buffer.active, __buffer.id, __buffer.perc)    
        end 
    end)
end

function terminate()
    widget:destroy()
    window:destroy()
    disconnect(g_game, {onGameStart = online})
    ProtocolGame.unregisterExtendedOpcode(GameServerOpcodes.NavigationInformations)
end

function toggle()
    if not widget:isOn() then
        widget:setOn(true)
        window:open()        
    else
        widget:setOn(false)
        window:hide()
    end
end

function online()  
    if widget:isOn() then
        toggle()
    end        
end

function doBuildWindow(is_navigating, boat_id, percent)
    if percent > 0 then
        form.item:setImageSource('boats/' .. (tonumber(boat_id) or 0))
        form.item:show()
        form.lblNavigation:setText(percent .. '%')
        form.btnStart  :setEnabled(not is_navigating)
        form.btnExtract:setEnabled(not is_navigating)
    else
        form.item:hide()
        form.lblNavigation:setText('None.')
        form.btnStart  :setEnabled(false)
        form.btnExtract:setEnabled(false)        
    end
end