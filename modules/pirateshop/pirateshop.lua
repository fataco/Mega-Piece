local shop = {
    ["Outfits"] = {
        icon = "outfits", 
        items = {
            {name = "Luffy 1st Outfit", description = "Luffy Outfit, mude a outfit do seu personagem!(isso é um teste).", spriteId = "4000", price = 15, count = 1},
        }
    },
    ["Market"] = {
        icon = "market", 
        items = {
            {name = "Zoro Sword", description = "A zoro sword tem ataque 50(isso é um teste).", spriteId = 2160, price = 10, count = 1},
            {name = "Zoro Cap", description = "A zoro cap tem arm 20(isso é um teste).", spriteId = 3120, price = 10, count = 1},
        }
    },
    ["Boats"] = {
        icon = "boats", 
        items = {
            {name = "Boat", description = "(isso é um teste)", spriteId = "4200", price = 15, count = 1},
        }
    }
}



local shopWindow
local shopButton
local shopPanel
local shopItemsPanel
local selected
local pirateCoins
local pirateCoinsLabel
local panelItems = {}


function init()

        shopWindow = g_ui.displayUI('pirateshop.otui')
        shopWindow:hide()
        shopButton = modules.client_topmenu.addRightButton('shopButton', tr('Pirate Coin Shop'), 'images/pirateCoin', onoff, true)
        
        shopPanel = shopWindow:getChildById('shopPanel')
        shopItemsPanel = shopWindow:getChildById('shopItemsPanel')
        pirateCoinsLabel = shopWindow:getChildById('pirateCoinLabel')
       
        
        
        local i = 0
        for button, value in pairs(shop) do
            i = i + 1
            local wid = g_ui.createWidget('ShopCategory', shopPanel)
            wid:addAnchor(AnchorTop, 'parent', AnchorTop)
            wid:addAnchor(AnchorLeft, 'parent', AnchorLeft)
            
            --local label = wid:getChildById('shopCategoryLabel')
            --label:setText(button)
            --label:setTooltip(button)
            
            local image = wid:getChildById('shopCategoryImage')
            image:setImageSource("images/"..value.icon)
            
            if i > 1 then
                wid:addAnchor(AnchorTop, 'prev', AnchorTop)
                wid:setMarginTop(72)
            end

            wid.onMouseRelease = function()
                if selected ~= wid then
                    selected = wid
                    wid:setBorderColor("#94d6ea")
                    --label:setColor("#94d6ea")
                    image:setOpacity(1)
                    if #panelItems >= 1 then
                        for id, _ in pairs(panelItems) do
                            shopItemsPanel:getChildById(id):destroy()
                            panelItems = {}
                        end
                    end 
                end
                if #panelItems == 0 then
                    local t = 0
                    for _, item in pairs(value.items) do
                        t = t + 1
                        local it = g_ui.createWidget('ShopItem', shopItemsPanel)
                        it:addAnchor(AnchorTop, 'parent', AnchorTop)
                        it:addAnchor(AnchorLeft, 'parent', AnchorLeft)
                    
                        if t > 1 then
                            it:addAnchor(AnchorTop, 'prev', AnchorTop)
                            it:setMarginTop(63)
                        end
                    
                        it:getChildById('spriteItem'):setItemId(item.spriteId)
                        it:getChildById('spriteItem'):setTooltip("Description:\n"..item.description)
                        it:getChildById('label'):setText(item.name)
                        it:getChildById('costLabel'):setText("x"..item.price)
                        it:setId(t)
                        table.insert(panelItems, it)
                    end
                end
            end

            wid.onMouseMove = function()  
                local widPos = wid:getPosition()
                local pos = g_window.getMousePosition()
                if (pos.x <= (widPos.x+wid:getWidth()) and pos.x >= widPos.x) and (pos.y <= (widPos.y+wid:getHeight()) and pos.y >= widPos.y) then
                    wid:setBorderColor("#94d6ea")
                    --label:setColor("#94d6ea")
                    image:setOpacity(1)
                else
                    if selected ~= wid then
                        wid:setBorderColor("#000000")
                        --label:setColor("#ffffff")
                        image:setOpacity(0.6)
                    end
                end
            end
            
        end
    connect(g_game, 'onTextMessage', serverComunication)
end

function terminate()
    shopWindow:hide()
    disconnect(g_game, 'onTextMessage', serverComunication)
end

function serverComunication(mode, text)
    if not g_game.isOnline() then
        return
    end

    if mode == MessageModes.Failure then
        local txt = text:explode(" ")
        if text:find("$#pirateShopRefresh") then
            pirateCoinsLabel:setText("x"..txt[2])
            pirateCoins = tonumber(txt[2])
        end
    end
end


function requestPirateCoins()
    --return g_game.talk("/$#pirateshop refresh")
end

function onoff()
    if shopWindow:isVisible() then
        shopWindow:hide()
    else
        requestPirateCoins()
        shopWindow:show()
    end
end