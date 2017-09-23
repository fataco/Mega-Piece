infos = {
    hotkey     = "Ctrl+F",     
    slot_count = 24,
    vocation   = nil,
    spells     = {},
    chopper_transformation = 1, -- a cada transformacao, ele recebe o id da transformacao        
}

function setupSlots()
    miniWindow:setHeight(34 + math.ceil(#infos.spells / 4) * 36 + 8)
    for index = 1, infos.slot_count do
        local current = miniWindow:getChildById('m' .. index)
        local progress = miniWindow:getChildById('p' .. index)        
        if index <= #infos.spells then
            current:show()
            progress:show()
        else
            current:hide()
            progress:hide()
        end  
    end
end

function configure_spells()        
    
    setupSlots()        
    
    for index, spell in pairs(infos.spells) do
    
        local current = miniWindow:getChildById('m' .. index)
        local progress = miniWindow:getChildById('p' .. index)

        if index > infos.slot_count then
          print('[ERROR - game_spells/spells.lua :: Not possible to get cd slot with index `' .. (index or '__unknown__') .. '`]')
          return false
        end

        current:setImageSource(spell.image)
        progress.name = spell.name 
        progress:setTooltip(spell.name .. " - lvl " .. spell.level .. " (" .. (spell.mana or '?') .. " en)")
        if spell.mana > 0 then
            progress.onClick = function (self)
                g_game.talk(self.name)
            end
        else
            progress.onClick = function (self)
                -- faz nada, mas substitui o antigo
            end
        end
        progress.var = spell.var            
        progress.onMouseRelease = function(self, mousePosition, mouseButton)
            if mouseButton == MouseRightButton then
                if self.var then
                    g_game.talk(self.var)
                end
            end
        end
    end
end

function toggle()
    doOpen(not spellsButton:isOn())
end

function doOpen(bool)
    spellsButton:setOn(bool)
    if bool then
        miniWindow:show()
    else
        miniWindow:hide()
    end    
end

function doRefreshClient()
    infos.chopper_transformation = 1
    local protocolGame = g_game.getProtocolGame()
    if protocolGame then
        protocolGame:sendExtendedOpcode(ClientOpcodes.RequestCdInformations) -- manda pro server, mandar todas spells
    end
end

function getVocationSpells()        
    if infos.vocation == 7 then
        return CHOPPER_FILTER_SPELLS[infos.chopper_transformation] 
    else
        return VOCATIONS_SPELLS[infos.vocation]
    end
end

function runThread()
    local __clock = os.clock() 
    for index, spell in pairs(infos.spells) do
        local progress = miniWindow:getChildById('p' .. index)            
        if progress then
            if g_game.getLocalPlayer() and g_game.getLocalPlayer():getLevel() >= spell.level then                                                
                progress:setColor('gray')
                local time = math.round((spell.delay - os.clock()) * 10) / 10
                if time <= 0 then
                    progress:setText()                   
                    progress:setPercent(100)             
                else                                                  
                    progress:setText(string.format("%.1f", time)) 
                    progress:setPercent(0)                                                                                                                    
                end
            else
                progress:setColor('pink')
                progress:setText('L' .. spell.level)
                progress:setPercent(0)            
            end
        else
            print('[ERROR - spells.lua :: Invalid progress at spell id `' .. spell.id .. '`]')
        end
    end    
    scheduleEvent(runThread, 100)
end

function init()
    connect(g_game, {onGameStart = doRefreshClient})
    miniWindow = g_ui.loadUI('spells', modules.game_interface.getRightPanel())
    miniWindow:disableResize()
    spellsButton = modules.client_topmenu.addRightGameToggleButton('spellsButton', tr('Spells (' .. infos.hotkey .. ')'), 'images/icon', toggle)
    g_keyboard.bindKeyDown(infos.hotkey, toggle)
    doOpen(true)    
    miniWindow:setup()            
    
    ProtocolGame.registerExtendedOpcode(GameServerOpcodes.CdInformations, function(protocol, opcode, buffer)
        --print(buffer)
        local __buffer = loadstring('return ' .. buffer)()
        if __buffer.vocation or __buffer.Tr then -- Exemplo: `{vocation = 2, ...}` ;
            if __buffer.vocation then
                infos.vocation = (tonumber(__buffer.vocation) or 0) % 10
            end
            if __buffer.Tr then
                infos.chopper_transformation = tonumber(__buffer.Tr)
                if not infos.chopper_transformation then
                    print('[ERROR - game_spells/spells.lua :: Invalid chopper transformation buffer')
                end 
            end
            if not VOCATIONS_SPELLS[infos.vocation] then
                print('[ERROR - game_spells/spells.lua :: Invalid vocation]')
            else
                infos.spells = {}
                local table_spells = getVocationSpells()
                for index, spell_id in pairs(table_spells) do
                    local spell = SPELL_LIST[table_spells[index]]
                    infos.spells[index] = {index  = index, id = spell_id, name = spell.name, level = spell.level, mana = spell.mana, delay = 0, image = spell.image}
                end
                configure_spells() 
            end
        end
        if __buffer.cd then
            for index, cd in pairs(__buffer.cd) do
                local found
                for index, spell in pairs(infos.spells) do
                    --print('> ' .. spell.id)
                    if spell.id == cd[1] then
                        spell.delay = os.clock() + cd[2]
                        found = true
                        break
                    end
                end
                if not found then
                    print('[ERROR - game_spells/spells.lua :: Not found cd slot with spell_id `' .. cd[1] .. '` ; Delay would be set to `' .. cd[2]  .. '`]')
                end                                        
            end            
        end
    end)        
    runThread()
end

function terminate()
    miniWindow:destroy()
    spellsButton:destroy()
    g_keyboard.unbindKeyDown(infos.hotkey)
    disconnect(g_game, {onGameStart = doRefreshClient})
    ProtocolGame.unregisterExtendedOpcode(GameServerOpcodes.CdInformations)
end