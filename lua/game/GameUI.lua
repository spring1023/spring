local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local Files = cc.FileUtils:getInstance()

local ui = _G.ui
GameUI = {}
local _resSettings = GMethod.loadConfig("configs/ui/resIcons.json")
for k,v in pairs(_resSettings) do
    if type(k)=="string" then
        _resSettings[tonumber(k)] = v
    end
end

function GameUI.addVip(bg,i,x,y,z,params)
    if GameLogic.useTalentMatch then
        return
    end
    if i>10 then
        i=10
    end
    local setting=params or {}
    local scale,r=setting.scale or 1,setting.r or 0
    local rMode=setting.rMode or false
    local node = ui.node()
    node:setScale(scale)
    node:setRotation(r)
    display.adapt(node,x,y,GConst.Anchor.LeftBottom)
    bg:addChild(node,z or 0)

    if setting.withBack then
        local back = ui.sprite("images/vipBack.png",{175/0.896,55/0.896})
        display.adapt(back,70,21,GConst.Anchor.Center)
        node:addChild(back)
    end

    local temp
    local ox=0
    if not rMode then
        temp= ui.sprite("images/vip.png",{97,67})
        display.adapt(temp,0,0,GConst.Anchor.LeftBottom)
        node:addChild(temp)
        if i == 10 then
            temp:setPosition(-15,0)
        end
    else
        temp= ui.sprite("images/vip_v.png",{51*1.2,57*1.2})
        display.adapt(temp,0,0,GConst.Anchor.LeftBottom)
        node:addChild(temp)
        ox=-58
    end
    if i == 0 then
        temp:setSValue(-100)
    end

    temp = ui.sprite("images/vip".. i ..".png")
    if i == 0 then
        temp:setScale(1.18)
    else
        temp:setScale(1.1)
    end
    display.adapt(temp,102+ox,0,GConst.Anchor.LeftBottom)
    if i == 10 and not rMode then
        temp:setPosition(102+ox-15,0)
    end
    node:addChild(temp)
    if i == 0 then
        temp:setSValue(-100)
    end

    return node
end

function GameUI.addMenuVip(bg,i,x,y,z,params)
    if GameLogic.useTalentMatch then
        return
    end
    local setting=params or {}
    local scale=setting.scale or 1
    local node = ui.node()
    node:setScale(scale)
    display.adapt(node,x,y,GConst.Anchor.LeftBottom)
    bg:addChild(node,z or 0)
    local temp
    local bname
    local numName
    if i==0 then
        bname = "images/vipButBack0.png"
    elseif i<=4 then
        bname = "images/vipButBack1.png"
    elseif i<=9 then
        bname = "images/vipButBack2.png"
    else
        bname = "images/vipButBack3.png"
    end
    numName = "images/vipnum" .. i .. ".png"
    temp = ui.sprite(bname)
    display.adapt(temp,0,0,GConst.Anchor.LeftBottom)
    node:addChild(temp)

    if numName then
        local w = 180
        if i == 10 then
            w = 188
        end
        temp = ui.sprite(numName)
        display.adapt(temp,w,34,GConst.Anchor.Right)
        node:addChild(temp)
    end
end

function GameUI.addPlayHead(bg,params)
    local id,scale,x,y,z,anchor,vip,lv,noBut = params.id,params.scale,params.x,params.y,params.z,params.anchor,params.vip,params.lv,params.noBut
    local blackBack = params.blackBack
    local noBlackBack= params.noBlackBack
    if true then
        blackBack = false
    end
    local hid = math.floor(id/100)
    local bkid = id%10
    local bt = ui.button({200,200},nil,{})
    if noBut then
        bt = ui.node({200,200},nil,{})
    end
    scale = scale or 1
    bt:setScale(scale)
    display.adapt(bt,x,y,GConst.Anchor[anchor or "Center"])
    bg:addChild(bt,z or 0)
    local bk
    if blackBack then
        bk = ui.sprite("images/iconBack".. bkid ..".png")
    else
        bk = ui.sprite("images/iconBack".. bkid .."_2.png")
    end
    if bkid == 5 then
        if not blackBack then
            display.adapt(bk,95,112,GConst.Anchor.Center)
        else
            display.adapt(bk,93,107,GConst.Anchor.Center)
        end
    elseif bkid == 4 then
        if not blackBack then
            display.adapt(bk,100,100,GConst.Anchor.Center)
        else
            display.adapt(bk,100,100,GConst.Anchor.Center)
        end
    else
        display.adapt(bk,100,100,GConst.Anchor.Center)
    end
    if not noBlackBack then
        bt:addChild(bk)
    end
    local awakeUp = math.floor(id/10)%10
    if blackBack then
        local sca,oy=0.7,48
        if bkid==3 or bkid==4 then
            sca,oy=0.75,50
        end
        GameUI.addHeroHeadCircle(bt, hid, sca, 101, 90+oy, 0,{lv = awakeUp})
    else
        GameUI.addHeroHeadCircle(bt, hid, 0.66, 94, 107+37, 0,{lv = awakeUp})
    end
    if params.vip then
        --vip
        GameUI.addVip(bt,vip,190,140,0,{scale=0.896/1.2,withBack = true})
    end

    return bt
end

function GameUI.addResourceIcon(bg, resource, scale, x, y,z,mode)
    if not mode then--1有描边,2无描边
        mode=1
    end
    local rs = _resSettings[resource][mode]
    if not rs then
        rs = _resSettings[resource][1]
    end
    if not rs then
        rs = _resSettings[1][mode]
    end
    if not rs then
        log.e("No Resource!",resource)
        return
    end
    local temp = ui.sprite(rs.image)
    temp:setScale(scale*(rs.scale or 1))
    display.adapt(temp, x+(rs.x or 0)*scale, y+(rs.y or 0)*scale, GConst.Anchor.Center)
    bg:addChild(temp,z or 0)
    return temp
end

function GameUI.addArenaStageIcon(bg, astage, scale, x, y, z)
    local temp = ui.sprite("images/icons/arenaStage" .. astage .. ".png")
    if not temp then
        temp = ui.sprite("images/icons/arenaStage1.png")
    end
    temp:setScale(scale or 1)
    display.adapt(temp, x or 0, y or 0, GConst.Anchor.Center)
    bg:addChild(temp, z or 0)
    return temp
end

function GameUI.addArenaStageIcon2(bg, astage, scale, x, y, z)
    local temp = ui.sprite("images/icons/arenaNewStage" .. astage .. ".png")
    temp:setScale(scale or 1)
    display.adapt(temp, x or 0, y or 0, GConst.Anchor.Center)
    bg:addChild(temp, z or 0)
    return temp
end

function GameUI.addArenaBoxIcon(bg, astage, scale, x, y, z)
    local temp = ui.sprite("images/icons/arenaBox.png")
    temp:setScale(scale or 1)
    display.adapt(temp, x or 0, y or 0, GConst.Anchor.Center)
    bg:addChild(temp, z or 0)
    local back =temp
    GameUI.addArenaStageIcon2(back, astage, 0.5, 152, 138, 1)
    return temp
end

local _itemIconConfig = GMethod.loadConfig("configs/ui/itemIcons.json")
GameUI.itemIconConfig=_itemIconConfig
GameUI.itemNameColor={{81,255,28},{0,127,255},{152,18,214},{255,127,0}}

--方形
--TODO 2B只有四个品质, 2A有五个品质, 2B数据还没弄好, 在使用2A数据的情况下临时用张图充当品质5, 后期再改
local _itemIconBacks = {"icon/icon_itemFrame_1.png","icon/icon_itemFrame_2.png","icon/icon_itemFrame_3.png","icon/icon_itemFrame_4.png","icon/icon_itemFrame_4.png"}
local _itemIconBacks2 = {"images/itemIconBackGreen_2.png","images/itemIconBackBlue_2.png","images/itemIconBackPurple_2.png","images/itemIconBackOrange_2.png"}

--添加物品
function GameUI.addItemBack(bg,backColor,scale,x,y,z)
    local temp = ui.sprite(_itemIconBacks[backColor])
    display.adapt(temp, x, y, GConst.Anchor.Center)
    temp:setScale(scale)
    bg:addChild(temp,z or 0)
    return temp
end

--圆形
function GameUI.addItemBack2(bg,backColor,scale,x,y,z)
    local temp = ui.sprite(_itemIconBacks2[backColor])
    display.adapt(temp, x, y, GConst.Anchor.Center)
    temp:setScale(scale)
    bg:addChild(temp,z or 0)
    return temp
end

function GameUI.setItemName(label,resMode,resID,num)
    if resMode == const.ItemRes then
        -- if num==1 then
        --     GameUI.setHeroNameColor(label, 4)
        -- else
        --     ui.setColor(label, GConst.Color.White)
        --     local name = GameLogic.getItemName(resMode, resID)
        --     if num>1 then
        --         name = name .. "x" .. num
        --     end
        --     label:setString(name)
        --     return
        -- end
    elseif resMode==const.ItemHero or resMode==const.ItemFragment then
        local color = math.floor(resID/1000)
        if color>4 then
            color = 4
        end
        local hinfo = SData.getData("hinfos", resID)
        if hinfo then
            color = hinfo.displayColor or hinfo.color or color
        end
        if resMode==const.ItemHero then
            if type(num) == "table" then
                num = #num
            else
                num = 0
            end
        end
        GameUI.setHeroNameColor(label, color)
    elseif resMode==const.ItemEquip then
        GameUI.setHeroNameColor(label, 1)
        num = 0
    elseif resMode==const.ItemEquipFrag then
        local color = 4
        local hinfo = SData.getData("hinfos", resID)
        if hinfo and hinfo.displayColor then
            color = hinfo.displayColor
        end
        GameUI.setHeroNameColor(label, color)
    else
        local key = resMode .. "_" .. resID
        local setting = _itemIconConfig[key]
        if setting then
            GameUI.setHeroNameColor(label, setting[1])
        end
    end
    local name = GameLogic.getItemName(resMode, resID)
    if num>1 then
        name = name .. "x" .. num
    end
    label:setString(name)
end

function GameUI.onShowNotice(params)
    local bg = params[1]
    local tbg = params[2]
    local x = params[3]
    local y = params[4]
    local content = params[5]
    local labelTips
    local labelTipsSize={width=0,height=0}
    if params[8] then
        local tips=params[8]
        labelTips=ui.label(tips,General.font1,40,{width=params[9] or 560, align=GConst.Align.Left})
        labelTipsSize=labelTips:getContentSize()
    end

    local label = ui.label(content, General.font1, 48, {width=params[6] or 560, align=GConst.Align.Left})
    local labelSize = label:getContentSize()

    local p1 = cc.p(x, y)
    local p2 = tbg:convertToWorldSpace(p1)
    local k = 1
    local vscale = ui.getUIScale2()
    if p2.y >= display.winSize[2] - (labelSize.height + labelTipsSize.height + (params[7] or 80)) * vscale then
        k = -1
    end
    local bgWidth=params[8] and (labelSize.width>labelTipsSize.width and labelSize.width or labelTipsSize.width) or labelSize.width
    if p2.x < (bgWidth+80)*vscale/2 then
        p2.x = (bgWidth+80)*vscale/2
    elseif p2.x > (display.winSize[1] - (bgWidth+80)*vscale/2) then
        p2.x = display.winSize[1] - (bgWidth+80)*vscale/2
    end

    local p3 = bg:convertToNodeSpace(p2)
    local visitBg = ui.node({bgWidth+80, labelSize.height+labelTipsSize.height+80})

    local temp
    temp = ui.scale9("images/bgWhiteEdgeGray.9.png", 10, {bgWidth+80, labelSize.height+labelTipsSize.height+80})
    display.adapt(temp, 0, 0)
    visitBg:addChild(temp)
    display.adapt(label, (labelSize.width+80)/2, 40+labelTipsSize.height+labelSize.height/2, GConst.Anchor.Center)
    if params[8] then
        display.adapt(labelTips,(labelTipsSize.width+80)/2,(labelTipsSize.height+80)/2,GConst.Anchor.Center)
        visitBg:addChild(labelTips,1)
    end
    visitBg:addChild(label, 1)
    if k == 1 then
        display.adapt(visitBg, p3.x, p3.y + (params[7] or 80), GConst.Anchor.Bottom)
    else
        display.adapt(visitBg, p3.x, p3.y - (params[7] or 80), GConst.Anchor.Top)
    end

    local oldP = bg:getChildByTag(13)
    if oldP then
        oldP:removeFromParent(true)
    end
    bg:addChild(visitBg,10,13)
end

function GameUI.tipsTouchHandler(params, node, nEventType)
    if nEventType == 0 then
        GameUI.onShowNotice(params)
    elseif nEventType == 3 or nEventType == 4 then
        if params[1]:getChildByTag(13) then
            params[1]:removeChildByTag(13)
        end
    end
end

function GameUI.showHeroDialog(htype, hid)
    if htype == const.ItemHero then
        local _hero = GameLogic.getUserContext().heroData:makeHero(hid)
        display.showDialog(HeroInfoNewDialog.new({hero = _hero}))
    else
        local equip = GameLogic.getUserContext().equipData:makeEquip(hid)
        display.showDialog(EquipInfoNewDialog.new({equip = equip}))
    end
end

function GameUI.registerTipsAction(button, bg, itemType, itemId, x, y, text)
    local bv
    if type(button) == "table" then
        bv = button.view
        if not x then
            local cellSize = button:getContentSize()
            x = cellSize[1] / 2
            y = cellSize[2] / 2
        end
    else
        bv = button
        if not x then
            local cellSize = button:getContentSize()
            x = cellSize.width / 2
            y = cellSize.height / 2
        end
    end
    if (itemType == const.ItemHero and (itemId % 1000) ~= 0) or itemType == const.ItemEquip then
        bv:setScriptCallback(ButtonHandler(GameUI.showHeroDialog, itemType, itemId))
    else
        local tips
        if GameLogic.useTalentMatch then
            if itemType==7 then
                local cnum = GameLogic.getUserContext():getItem(const.ItemFragment, itemId)
                tips=Localizef("labelTipsItems",{a=cnum,b=1500})
            end
        end
        bv:setControlHandler(ButtonHandler(GameUI.tipsTouchHandler, {bg, bv:getDrawNode(), x, y, text or GameLogic.getItemDesc(itemType, itemId),nil,nil,tips}))
    end
end

--200x200
function GameUI.addItemIcon(bg,resMode,resID,scale,x,y,withBack,withBack_circle,otherSetting)
    local node=ui.shlNode({198,198})
    display.adapt(node, x, y, GConst.Anchor.Center)
    node:setScale(scale)
    bg:addChild(node)
    local params=otherSetting or {}
    local backType = 1
    local temp
    if resMode == const.ItemRes then
        backType = 4
        GameUI.addResourceIcon(node, resID, 1.5, 99, 99)
        if resID==const.ResExp then
            temp = ui.label(Localize("EXP"),General.font1,28)
            temp:setScale(2.5)
            display.adapt(temp, 99, 99, GConst.Anchor.Center)
            node:addChild(temp)
            temp:setGlobalZOrder(2)
        end
    elseif resMode==const.ItemHero then
        backType = math.floor(resID/1000)
        if backType>4 then
            backType = 4
        end
        local hinfo = SData.getData("hinfos", resID)
        if hinfo and not withBack_circle then
            backType = hinfo.displayColor or hinfo.color or backType
        end
        GameUI.addHeadIcon(node,resID,0.876,99,99,otherSetting)
        --添加ssr图标
        if hinfo and hinfo.rating then
            local _scale = 0.3
            GameUI.addSSR(node, hinfo.displayColor and hinfo.displayColor >= 5 and 5 or hinfo.rating, _scale, 5, 5, 10, GConst.Anchor.LeftBottom)
        end
    elseif resMode==const.ItemEquip then
        GameUI.addEquipIcon(node,resID,0.876,99,99)
    elseif resMode==0 then  --色子和3倍
        temp = ui.sprite("images/otherIcon/icon" .. resID .. ".png",{142,139})
        temp:setScale(200/142*0.9)
        display.adapt(temp,99,99,GConst.Anchor.Center)
        node:addChild(temp)
    elseif resMode == const.ItemOther then
        backType = 4
        if resID == const.ProMonthCard then
            temp = ui.sprite("images/storeIconContract2.png")
            temp:setScale(0.7)
            display.adapt(temp, 99, 99, GConst.Anchor.Center)
            node:addChild(temp)
        end
    elseif resMode==const.ItemEquipFrag or resMode==const.ItemFragment then
        backType = 4
        if resMode == const.ItemFragment then
            local hinfo = SData.getData("hinfos", resID)
            if hinfo and not withBack_circle then
                backType = hinfo.displayColor or hinfo.color or backType
            end
        end
        if backType == 5 then
            temp = ui.sprite("images/heroFragBack_red.png",{182*0.8,210*0.8})
        else
            temp = ui.sprite("images/heroFragBack.png",{182*0.8,210*0.8})
        end
        display.adapt(temp, 99, 99, GConst.Anchor.Center)
        node:addChild(temp)
        if resID==0 then
            temp = ui.label("?", General.font1, 60, {color={255,255,255}})
            display.adapt(temp, 99, 99, GConst.Anchor.Center)
            node:addChild(temp)
        else
            if resMode == const.ItemFragment then
                GameUI.addHeadIcon(node, resID, 0.43*0.8, 103, 105, 1)
                if withBack and GameLogic.useTalentMatch then
                    local hinfo = SData.getData("hinfos", resID)
                    GameUI.addSSR(node, hinfo.displayColor and hinfo.displayColor >= 5 and 5 or hinfo.rating, 0.43*0.8, 5, 5, 10, GConst.Anchor.LeftBottom)
                end
            else
                GameUI.addEquipIcon(node, resID, 0.43*0.8, 102, 105)
            end
        end
    else
        local key = resMode .. "_" .. resID
        local setting = _itemIconConfig[key]
        local useDefault = false
        if not setting then
            useDefault = true
        else
            backType = setting[1]
            temp = ui.sprite(setting[5] or ("images/items/itemIcon" .. key ..".png"))
            if not temp then
                useDefault = true
            else
                display.adapt(temp, setting[2], setting[3], GConst.Anchor.LeftBottom)
                temp:setScale(setting[4] or 1)
                node:addChild(temp)
            end
        end
        if useDefault then
            temp=ui.sprite("images/items/itemIcon" .. "1_3001" ..".png")
            display.adapt(temp, 99, 99, GConst.Anchor.Center)
            node:addChild(temp)
            temp = ui.label(key, General.font1, 40, {color=GConst.Color.Black})
            display.adapt(temp, 99, 99, GConst.Anchor.Center)
            node:addChild(temp)
        end
    end
    local label = nil
    if params.itemNum then
        temp = ui.label(Localizef("labelFormatX",{num=params.itemNum}), General.font1, 48, {color={255,255,255},fontW=180,fontH=80})
        display.adapt(temp, 194, 2, GConst.Anchor.RightBottom)
        node:addChild(temp, 2)
        temp:setGlobalZOrder(2)
        label = temp
    end
    local itemBackScale=params.itemBackScale or 1
    if withBack then
        GameUI.addItemBack(node, backType, itemBackScale, 99, 99, -1)
    elseif withBack_circle then
        GameUI.addItemBack2(node, backType, itemBackScale, 99, 99, -1)
    end
    return node, label
end

function GameUI.helpLoadTableView(viewNode, infos, updateFunc)
    viewNode:removeAllChildren(true)
    local ts = viewNode:getSetting("tableSetting")
    local size = viewNode.size
    local tableView = ui.createTableView(viewNode.size, ts.isX, {cellActionType=ts.actionType, size=cc.size(ts.sx,ts.sy), offx=ts.ox, offy=ts.oy, disx=ts.dx, disy=ts.dy, rowmax=ts.rowmax, infos=infos, cellUpdate=updateFunc, sizeChange=true})
    display.adapt(tableView.view, 0, 0, GConst.Anchor.LeftBottom)
    viewNode.view:addChild(tableView.view)
    return tableView
end

local function squeeze(value, min, max)
    if min and value<min then
        return min
    elseif max and value>max then
        return max
    else
        return value
    end
end
function GameUI.fixSizeChangeLength(tableView, info)
    -- body
     if tableView.dataInitedLength < tableView.dataLength then
        local lastItem = tableView.items[tableView.dataInitedLength]
        local cellSetting = tableView.cellSetting
        if lastItem then
            local nsize = info.view:getContentSize()
            local x, y, off, length, endoff
            if tableView.isX then
                x = (lastItem.off or cellSetting.offx) + lastItem.length - cellSetting.offx + cellSetting.disx
                y = 0
                off = cellSetting.offx + x
                length = nsize.width
                endoff = cellSetting.disx/2
            else
                x = 0
                y = (lastItem.off or cellSetting.offy) + lastItem.length - cellSetting.offy + cellSetting.disy
                off = cellSetting.offy + y
                length = nsize.height
                endoff = cellSetting.disy/2
            end
            local newItem = {off = off, length = length, endoff = endoff}
            local size = tableView.size
            if tableView.isX then
                tableView.off_min = squeeze(size[1] - (newItem.off + newItem.length + newItem.endoff), nil, tableView.off_max)
                tableView.view:setScrollContentRect(cc.rect(0,0,size[1]-tableView.off_min,size[2]))
                tableView.maxLength = -tableView.off_min
            else
                tableView.off_max = squeeze(newItem.off + newItem.length + newItem.endoff - size[2], tableView.off_min)
                tableView.view:setScrollContentRect(cc.rect(0,-tableView.off_max,size[1],tableView.off_max+size[2]))
                tableView.maxLength = tableView.off_max
            end
        end
    end
end

--添加正方形的武器图标
function GameUI.addWeaponIcon(bg,wtype,id,scale,x,y,z)
    local skey
    local baseScale = 1
    if wtype==0 then
        skey = "images/skillIcon/weaponIcon" .. id .. ".png"
        if id<1004 then
            baseScale = 226/296
        end
    else
        if wtype>2 then
            wtype = 2
        end
        skey = "images/skillIcon/weaponIcon" .. wtype .. "_" .. id .. ".png"
    end
    local temp = ui.sprite(skey)
    temp:setScale(baseScale*scale)
    display.adapt(temp, x, y, GConst.Anchor.Center)
    bg:addChild(temp, z or 0)
    return temp
end

function GameUI.addDeathHead(bg,sx,sy,x,y,z)
    local temp = ui.sprite("images/iconDeath.png",{sx,sy})
    display.adapt(temp, x, y)
    bg:addChild(temp, z or 0)
    return temp
end

function GameUI.addBuildHead(bg,id,sx,sy,x,y,s,lv,viewid)
    local bnode = ui.shlNode()
    bg:addChild(bnode)
    local newBuild = Build.new(id, lv or 1)
    newBuild:addBuildView(bnode, x, y, sx, sy, s,viewid or nil)
    return bnode
end

--添加长方形的武器图标
function GameUI.addWeaponIcon2(bg, id, scale, x, y, z)
    local sx, sy = 137, 188

    local temp = GameUI.addWeaponIcon(bg, 0, id, sy/226, x, y, z)

    local tsize = temp:getContentSize()
    local width, height = tsize.width * temp:getScaleX(), tsize.height * temp:getScaleY()
    temp:setScale(scale or 1)
    temp:setContentSize(cc.size(width, height))
    temp:setCustomModeNumber(8)
    temp:setCustomPoint(0, 0.187, 0, 0.187, 0)
    temp:setCustomPoint(1, 0.13, 0.057, 0.13, 0.057)
    temp:setCustomPoint(2, 0.13, 0.943, 0.13, 0.943)
    temp:setCustomPoint(3, 0.187, 1, 0.187, 1)
    temp:setCustomPoint(4, 0.813, 1, 0.813, 1)
    temp:setCustomPoint(5, 0.87, 0.943, 0.87, 0.943)
    temp:setCustomPoint(6, 0.87, 0.057, 0.87, 0.057)
    temp:setCustomPoint(7, 0.813, 0, 0.813, 0)
    return temp
end


local _headSquareConfig=GMethod.loadConfig("configs/ui/headPos.json")["square"]
function GameUI.addHeadIcon(bg,id,scale,x,y,z,otherSetting)
    local lv = otherSetting and otherSetting.lv or 0
    if type(z) == "table" then
        lv = z.lv or 0
        z = 0
    end
    if type(scale) == "table" then        --兼容
        x = scale.x
        y = scale.y
        z = scale.z
        scale = scale.size[1]/225
        lv = scale.lv or 0
    end
    local mode = ""
    local temp
    local baseScale = 1

    local sx,sy = 230,221
    --减少使用裁剪模板，因为会影响渲染效率

    local ox, oy = 0, 0
    --神兽
    if id>8000 and id<9000 then
        id = math.floor(id/10)*10
    end
    local shouldClip = false
    if id<1000 then
        if lv<15 then
            mode = 1
        elseif lv<30 then
            mode = 2
        else
            mode = 3
        end
        temp = ui.sprite("images/roles/soldierHead" .. id .."_" .. mode ..".png")
        shouldClip = true
    elseif id%1000==0 then
        temp = ui.sprite("images/roles/heroExp" .. id/1000 .. mode .. ".png")
        baseScale = 0.55
    else
        local key = "heroHead" .. id
        local key2 = ""
        if lv > 0 then
            key2 = "_" ..1
        end
        local config = _headSquareConfig[key..key2] or _headSquareConfig[key] or {x=0,y=0,sx=100,sy=100}
        if cc.FileUtils:getInstance():isFileExist("images/roles/" .. key .. key2 .. ".png") then
            temp = ui.sprite("images/roles/" .. key .. key2 .. ".png",{config.sx,config.sy})
        else
            temp = ui.sprite("images/roles/" .. key .. ".png",{config.sx,config.sy})
        end
        ox = config.x
        oy = config.y
        shouldClip = true
    end
    if not temp then
        temp = ui.sprite("images/roles/heroHead" .. 4001 .. ".png")
        local temp2 = ui.label(StringManager.getString("dataHeroName" .. id), General.font1, 40, {color=GConst.Color.Red})
        display.adapt(temp2, temp:getContentSize().width/2, temp:getContentSize().height/2, GConst.Anchor.Center)
        temp:addChild(temp2, z and z+1 or 1)
        shouldClip = true
    end
    if shouldClip then
        local tsize = temp:getContentSize()
        local width = tsize.width * temp:getScaleX()
        local height = tsize.height * temp:getScaleY()
        local tlx = 109+ox-width/2
        local brx = 109+ox+width/2
        local tly = 106+oy+height/2
        local bry = 106+oy-height/2
        local sx0, sy0 = 0, 0
        if tly < sy then
            sy = tly
        end
        if tlx > sx0 then
            sx0 = tlx
        end
        if bry > sy0 then
            sy0 = bry
        end
        if brx < sx then
            sx = brx
        end
        local tlcx = (sx0-tlx)/width
        local tlcy = (tly-sy)/height
        local brcx = 1+(sx-brx)/width
        local brcy = 1+(bry-sy0)/height
        temp:setCustomPoint(0, tlcx, tlcy, tlcx, tlcy)
        temp:setCustomPoint(1, tlcx, tlcy + (brcy-tlcy)*0.975, tlcx, tlcy + (brcy-tlcy)*0.975)
        temp:setCustomPoint(2, brcx, tlcy, brcx, tlcy)
        temp:setCustomPoint(3, tlcx + (brcx-tlcx)*0.962, brcy, tlcx + (brcx-tlcx)*0.962, brcy)
        temp:setScale(1)
        temp:setContentSize(cc.size(width, height))
        display.adapt(temp, x+(ox+109-sx/2)*scale, y+(oy+106-sy/2)*scale, GConst.Anchor.Center)
    else
        display.adapt(temp, x, y, GConst.Anchor.Center)
    end

    temp:setScale(scale*baseScale)
    bg:addChild(temp, z or 0)

    -- temp.id = id
    -- temp.bg = bg
    return temp
end

function GameUI.addBattleEquipIcon(bg,equip,x,y,z)
    local node = ui.node()
    bg:addChild(node)
    display.adapt(node,bg._ox+x,bg._oy+y,GConst.Anchor.Center)
    GameUI.addItemBack(node,equip.color,1.15,0,0)
    GameUI.addEquipIcon(node,equip.id,1,0,0)
    node:setScale(0.3)
    return node
end

function GameUI.addEquipIcon(bg,id,scale,x,y,z)
    local temp
    local baseScale = 1
    temp = ui.sprite("images/items/equipIcon" .. id .. ".png")
    if not temp then
        temp = ui.label(StringManager.getString("dataEquipName" .. id), General.font1, 40, {color=GConst.Color.Red})
    else
        temp:setScale(scale*baseScale)
    end
    display.adapt(temp,x,y,GConst.Anchor.Center)
    bg:addChild(temp,z or 0)
    return temp
end

function GameUI.addEquipFeature(bg, id, scale, x, y)
    local temp
    if not scale then scale = 1 end
    -- temp = ui.sprite("images/items/iconEquipBase.png")
    -- temp:setScale(scale)
    -- display.adapt(temp, x or 0, (y or 0)-600*scale, GConst.Anchor.Bottom)
    -- bg:addChild(temp)
    -- temp = ui.sprite("images/items/equipFeature" .. id .. ".png")
    -- temp:setScale(scale)
    -- display.adapt(temp, x or 0, (y or 0)+180*scale, GConst.Anchor.Center)
    -- bg:addChild(temp)
    -- 临时处理一下
    temp = ui.sprite("images/items/equipFeature" .. id .. ".png")
    temp:setScale(scale)
    display.adapt(temp, x or 0, y or 0, GConst.Anchor.Center)
    bg:addChild(temp)
    return temp
end

function GameUI.addHeroHead(bg, id, setting)
    local temp = GameUI.addHeroHead2(bg,id,setting.size and setting.size[1] or 200,setting.size and setting.size[2] or 200,setting.x,setting.y,setting.z,setting)
    -- temp.bg = bg
    -- temp.setting = setting
    -- temp.id = id
    return temp
end
local _headRectangleConfig=GMethod.loadConfig("configs/ui/headPos.json")["rectangle"]
function GameUI.addHeroHead2(bg, id, scx, scy, x, y, z, setting)
    local lv = setting and setting.lv or 0
    if type(z) == "table" then
        lv = z.lv or 0
    end
    if id >= 8000 and id < 9000 then
        id = id - (id%10)
    end

    local sx, sy = 158, 216

    local key = "heroHead" .. id
    local key2 = ""
    if lv>0 then
        key2 = "_" .. 1
    end
    local config = _headRectangleConfig[key..key2] or _headRectangleConfig[key] or {x=0,y=0,sx=100,sy=100}
    local path = "images/roles/" .. key .. key2 .. ".png"
    if not cc.FileUtils:getInstance():isFileExist(path) then
        path = "images/roles/" .. key .. ".png"
    end
    local temp = ui.sprite(path, {config.sx, config.sy})
    local ox,oy = 0,0
    if config then
        ox = config.x or 0
        oy = config.y or 0
    end
    if not temp then
        temp = ui.sprite("images/roles/heroHead" .. 4001 .. ".png")
        local temp2 = ui.label(StringManager.getString("dataHeroName" .. id), General.font1, 40, {color=GConst.Color.Red})
        display.adapt(temp2, temp:getContentSize().width/2, temp:getContentSize().height/2, GConst.Anchor.Center)
        temp:addChild(temp2, 1)
        ox, oy = 0, 0
    end

    local tsize = temp:getContentSize()
    local width = tsize.width * temp:getScaleX()
    local height = tsize.height * temp:getScaleY()
    local tlx = sx/2+ox-width/2
    local brx = sx/2+ox+width/2
    local tly = sy/2+oy+height/2
    local bry = sy/2+oy-height/2
    local sx0, sy0 = 0, 0
    if tly < sy then
        sy = tly
    end
    if tlx > sx0 then
        sx0 = tlx
    end
    if bry > sy0 then
        sy0 = bry
    end
    if brx < sx then
        sx = brx
    end
    local tlcx = (sx0-tlx)/width
    local tlcy = (tly-sy+2)/height
    local brcx = 1+(sx+1-brx)/width
    local brcy = 1+(bry-sy0)/height

    temp:setCustomModeNumber(8)
    temp:setCustomPoint(0, tlcx + (brcx - tlcx) * 0.057, tlcy, tlcx + (brcx - tlcx) * 0.057, tlcy)
    temp:setCustomPoint(1, tlcx, tlcy + (brcy - tlcy) * 0.057, tlcx, tlcy + (brcy - tlcy) * 0.057)
    temp:setCustomPoint(2, tlcx, tlcy + (brcy - tlcy) * 0.943, tlcx, tlcy + (brcy - tlcy) * 0.943)
    temp:setCustomPoint(3, tlcx + (brcx - tlcx) * 0.057, brcy, tlcx + (brcx - tlcx) * 0.057, brcy)
    temp:setCustomPoint(4, tlcx + (brcx - tlcx) * 0.943, brcy, tlcx + (brcx - tlcx) * 0.943, brcy)
    temp:setCustomPoint(5, brcx, tlcy + (brcy - tlcy) * 0.943, brcx, tlcy + (brcy - tlcy) * 0.943)
    temp:setCustomPoint(6, brcx, tlcy + (brcy - tlcy) * 0.057, brcx, tlcy + (brcy - tlcy) * 0.057)
    temp:setCustomPoint(7, tlcx + (brcx - tlcx) * 0.943, tlcy, tlcx + (brcx - tlcx) * 0.943, tlcy)

    temp:setScale(1)
    temp:setContentSize(cc.size(width * 1.02 * scx / sx, height * 1.02 * scy / sy))
    display.adapt(temp, x+scx/2 + ox*scx/sx, y+scy/2 + oy*scx/sx, GConst.Anchor.Center)
    bg:addChild(temp, z or 0)

    return temp
end

local _featureConfig = GMethod.loadConfig("configs/ui/featureIcons.json")
--scale为缩放比例； centerMode表示这里为居中显示，所以对于高度不同的特写需要做一定调整
--amode为进化等级

function GameUI.getHeroFeature(id, centerMode, amode)
    local info = SData.getData("hinfos", id)
    local baseScale = 1
    local ox, oy = 0, 0
    local config
    local fkey
    if info then
        if amode and amode > 0 then
            fkey = info.featureA
        end
        if not fkey then
            fkey = info.feature
        end
        if fkey then
            if type(fkey) == "table" then
                if centerMode then
                    config = fkey[2]
                else
                    config = fkey[3] or fkey[2]
                end
                fkey = fkey[1]
                if config then
                    ox = config[1]
                    oy = config[2]
                    baseScale = config[3] or 1
                end
            else
                if centerMode then
                    config = _featureConfig[1][fkey]
                else
                    config = _featureConfig[2][fkey]
                end
                if config then
                    ox = config.x or 0
                    oy = config.y or 0
                    baseScale = config.scale or 1
                end
            end
        end
    end
    if not fkey then
        if id>0 and id%1000 == 0 then
            fkey = "heroExp" .. id/1000
            baseScale = 1.43
            if not centerMode then
                oy = 50
            end
        else
            if id == 0 then
                id = 1001
            end
            fkey = "heroFeature" .. id
            if amode and amode>0 then
                local fkey2 = fkey .. "_" .. 1
                if Files:isFileExist("images/roles/" .. fkey2 .. ".png") then
                    fkey = fkey2
                end
            end
            local config
            if not centerMode then
                config = _featureConfig[1][fkey]
            else
                config = _featureConfig[2][fkey]
            end
            if config then
                ox = config.x or 0
                oy = config.y or 0
                baseScale = config.scale or 1
            end
        end
    end
    return "images/roles/" .. fkey .. ".png", ox, oy, baseScale
end
function GameUI.addHeroFeature(bg, id, scale, x, y, z, centerMode, amode, flipped)
    local temp
    local fkey, ox, oy, baseScale = GameUI.getHeroFeature(id, centerMode, amode)
    temp = ui.sprite(fkey, nil, nil, true)
    if not temp then
        temp = ui.colorNode({400, 400}, {255, 0, 0})
        ox, oy, baseScale = 0, 0, 1
    end
    scale = scale*baseScale
    temp:setScale(scale)
    if flipped then
        temp:setFlippedX(true)
        ox = -ox
    end
    if centerMode then
        display.adapt(temp, x+ox*scale, y+oy*scale, GConst.Anchor.Center)
    else
        display.adapt(temp, x+ox*scale, y+oy*scale, GConst.Anchor.Bottom)
    end
    bg:addChild(temp, z or 0)
    return temp
end

local _headCircleConfig = GMethod.loadConfig("configs/ui/headPos.json")["circle"]
local _maskCircle1 = {{264.5,94},
{262.6938163579,75.661509730484},
{257.34467605606,58.027757357682},
{248.65814355644,41.776398096157},
{236.96803743154,27.531962568465},
{222.72360190384,15.841856443561},
{206.47224264232,7.1553239439391},
{188.83849026952,1.8061836420963},
{170.5,0},
{152.16150973048,1.8061836420963},
{134.52775735768,7.155323943939},
{118.27639809616,15.841856443561},
{104.03196256846,27.531962568465},
{92.341856443561,41.776398096157},
{83.655323943939,58.027757357682},
{78.306183642096,75.661509730484},
{76.5,94},{0,292},{341,292}}
--scale为缩放比例； centerMode表示这里为居中显示，所以对于高度不同的特写需要做一定调整
--amode为进化等级
--裁剪为半圆形
function GameUI.addHeroHeadCircle(bg, id, scale, x, y, z, amode)
    local temp
    local baseScale = 1
    local ox, oy = 0, 0
    if GEngine.rawConfig.DEBUG_HEAD then
        local sx, sy = 341, 292
        local maskBg = ui.shlNode({sx, sy})
        -- local maskImg = ui.sprite("images/headClippingMode.png", {sx, sy})
        -- display.adapt(maskImg, sx/2, sy/2, GConst.Anchor.Center)
        -- local maskNode = cc.ClippingNode:create(maskImg)
        -- maskNode:setCascadeOpacityEnabled(true)
        -- maskNode:setContentSize(cc.size(sx, sy))
        -- maskNode:setAlphaThreshold(0.1)

        local key = "heroHead" .. id
        local key2 = ""
        if amode and amode.lv>0 then
            key2 = "_" .. 1
        end
        local config = _headCircleConfig[key..key2] or _headCircleConfig[key] or {x=0,y=0,sx=100,sy=100}
        temp = ui.sprite("images/roles/" .. key .. key2 .. ".png",{config.sx,config.sy})
        if not temp then
            temp = ui.sprite("images/roles/" .. key .. ".png",{config.sx,config.sy})
        end
        if config then
            ox = config.x or 0
            oy = config.y or 0
        end
        if not temp then
            temp = ui.colorNode({100, 100}, {255, 0, 0})
            ox, oy = 0, 0
        else
            local _cx, _cy = 173, 93

            local tsize = temp:getContentSize()
            local width = tsize.width * temp:getScaleX()
            local height = tsize.height * temp:getScaleY()
            local tlx = _cx+ox-width/2
            local brx = _cx+ox+width/2
            local tly = _cy+oy+height/2
            local bry = _cy+oy-height/2

            local rmax = 32
            temp:setCustomModeNumber(#_maskCircle1)
            for i, pos in ipairs(_maskCircle1) do
                local px = pos[1]
                local py = pos[2]
                if px < tlx then
                    px = tlx
                elseif px > brx then
                    px = brx
                end
                if py > tly then
                    py = tly
                elseif py < bry then
                    py = bry
                end
                temp:setCustomPoint(i-1, (px-tlx)/width, (tly-py)/height, (px-tlx)/width, (tly-py)/height)
            end
            -- local sx0, sy0 = 0, 0
            -- if tly < sy then
            --     sy = tly
            -- end
            -- if tlx > sx0 then
            --     sx0 = tlx
            -- end
            -- if bry > sy0 then
            --     sy0 = bry
            -- end
            -- if brx < sx then
            --     sx = brx
            -- end
            -- local tlcx = (sx0-tlx)/width
            -- local tlcy = (tly-sy+2)/height
            -- local brcx = 1+(sx+1-brx)/width
            -- local brcy = 1+(bry-sy0)/height

            -- temp:setCustomModeNumber(8)
            -- temp:setCustomPoint(0, tlcx + (brcx - tlcx) * 0.057, tlcy, tlcx + (brcx - tlcx) * 0.057, tlcy)
            -- temp:setCustomPoint(1, tlcx, tlcy + (brcy - tlcy) * 0.057, tlcx, tlcy + (brcy - tlcy) * 0.057)
            -- temp:setCustomPoint(2, tlcx, tlcy + (brcy - tlcy) * 0.943, tlcx, tlcy + (brcy - tlcy) * 0.943)
            -- temp:setCustomPoint(3, tlcx + (brcx - tlcx) * 0.057, brcy, tlcx + (brcx - tlcx) * 0.057, brcy)
            -- temp:setCustomPoint(4, tlcx + (brcx - tlcx) * 0.943, brcy, tlcx + (brcx - tlcx) * 0.943, brcy)
            -- temp:setCustomPoint(5, brcx, tlcy + (brcy - tlcy) * 0.943, brcx, tlcy + (brcy - tlcy) * 0.943)
            -- temp:setCustomPoint(6, brcx, tlcy + (brcy - tlcy) * 0.057, brcx, tlcy + (brcy - tlcy) * 0.057)
            -- temp:setCustomPoint(7, tlcx + (brcx - tlcx) * 0.943, tlcy, tlcx + (brcx - tlcx) * 0.943, tlcy)

        end
        display.adapt(temp,173+ox,93+oy, GConst.Anchor.Center)
        -- maskNode:addChild(temp)

        -- display.adapt(maskNode, sx/2, sy/2, GConst.Anchor.Center)
        -- maskBg:addChild(maskNode)
        maskBg:addChild(temp)

        maskBg:setScale(scale)
        display.adapt(maskBg, x, y, GConst.Anchor.Center)
        if bg then
            bg:addChild(maskBg, z or 0)
        end
        return maskBg
    end

    local key = "heroHeadCircle" .. id
    local key2 = ""
    if amode and amode.lv>0 then
        key2 = "_" .. 1
    end
    local config = _headCircleConfig[key]
    temp = ui.sprite("images/roles/" .. key .. key2 .. ".png")
    if not temp then
        temp = ui.sprite("images/roles/" .. key .. ".png")
    end
    if config then
        ox = config.x or 0
        oy = config.y or 0
        baseScale = config.scale or 1
    end
    if not temp then
        temp = ui.colorNode({100, 100}, {255, 0, 0})
        ox, oy, baseScale = 0, 0, 1
    end
    scale = scale*baseScale
    temp:setScale(scale)
    display.adapt(temp, x+ox*scale, y+oy*scale, GConst.Anchor.Center)
    if bg then
        bg:addChild(temp, z or 0)
    end
    return temp
end

--裁剪为圆形
function GameUI.addHeroHeadCircle2(bg, id, scale, x, y, z, amode)
    local temp
    local baseScale = 1
    local ox, oy = 0, 0

    local sx, sy = 189, 189
    local maskBg = ui.shlNode({sx, sy})
    -- local maskImg = ui.sprite("images/pveCheckState2.png", {sx, sy})
    -- display.adapt(maskImg, sx/2, sy/2, GConst.Anchor.Center)
    -- local maskNode = cc.ClippingNode:create(maskImg)
    --     maskNode:setCascadeOpacityEnabled(true)
    -- maskNode:setContentSize(cc.size(sx, sy))
    -- maskNode:setAlphaThreshold(0.1)

    local key = "heroHead" .. id
    local key2 = ""
    if amode and amode.lv>0 then
        key2 = "_" .. 1
    end
    local config = _headCircleConfig[key..key2] or _headCircleConfig[key] or {x=0,y=0,sx=100,sy=100}
    temp = ui.sprite("images/roles/" .. key .. key2 .. ".png",{config.sx,config.sy})
    if not temp then
        temp = ui.sprite("images/roles/" .. key .. ".png",{config.sx,config.sy})
    end
    if config then
        ox = config.x or 0
        oy = config.y or 0
    end
    if not temp then
        temp = ui.colorNode({100, 100}, {255, 0, 0})
        ox, oy = 0, 0
    else
        local _cx, _cy = 94, 89

        local tsize = temp:getContentSize()
        local width = tsize.width * temp:getScaleX()
        local height = tsize.height * temp:getScaleY()
        local tlx = _cx+ox-width/2
        local brx = _cx+ox+width/2
        local tly = _cy+oy+height/2
        local bry = _cy+oy-height/2

        local rmax = 32
        local tmpRd = math.rad(360/rmax)
        temp:setCustomModeNumber(rmax)
        for i=0, rmax-1 do
            local px = sx/2 + sx/2*math.sin(i*tmpRd)
            local py = sy/2 + sy/2*math.cos(i*tmpRd)
            if px < tlx then
                px = tlx
            elseif px > brx then
                px = brx
            end
            if py > tly then
                py = tly
            elseif py < bry then
                py = bry
            end
            temp:setCustomPoint(i, (px-tlx)/width, (tly-py)/height, (px-tlx)/width, (tly-py)/height)
        end
    end
    display.adapt(temp,94+ox,89+oy, GConst.Anchor.Center)
    -- maskNode:addChild(temp)

    -- display.adapt(maskNode, sx/2, sy/2, GConst.Anchor.Center)
    -- maskBg:addChild(maskNode)
    maskBg:addChild(temp)

    maskBg:setScale(scale)
    display.adapt(maskBg, x, y, GConst.Anchor.Center)
    if bg then
        bg:addChild(maskBg, z or 0)
    end
    return maskBg
end

function GameUI.addHeroJobIcon(bg, id, scale, x, y, z)
    local temp = ui.sprite("images/roles/jobIcon" .. id .. ".png")
    if not temp then
        temp = ui.sprite("images/roles/jobIcon1.png")
    end
    temp:setScale(scale)
    display.adapt(temp, x, y, GConst.Anchor.Center)
    bg:addChild(temp, z or 0)
    return temp
end

local _heroFontColors = {{0,255,127},{0,127,255},{219,112,219},{255,127,0},{255,0,0}}

function GameUI.setHeroNameColor(temp, color)
    if type(temp)=="table" and temp.setColor then
        temp:setColor(_heroFontColors[color])
    else
        ui.setColor(temp, _heroFontColors[color])
    end
end

local _skillImageFixMap = {
    ["6_3"] = "images/skillIcon/skill6_2.png",
    ["6_6"] = "images/skillIcon/skill6_5.png",
    ["6_13"] = "images/skillIcon/skill6_16.png",
    ["2_701"] = "images/skillIcon/skill2_201.png",
    ["2_601"] = "images/skillIcon/skill2_301.png",
    ["5_403102"] = "images/skillIcon/skill5_4031202.png",
    ["5_4031202"] = "images/skillIcon/skill5_403102.png"
}
function GameUI.addBtnSkillIcon(bg, stype, id, scale, x, y)
    local temp = ui.sprite("images/skillIcon/skill2_100.png")
    local size = temp:getContentSize()
    local btn_bg = ui.button({size.width, size.height},nil,{})
    display.adapt(btn_bg, x, y, GConst.Anchor.Center)
    bg:addChild(btn_bg)
    local bgSkill = btn_bg:getDrawNode()
    GameUI.addSkillIcon(bgSkill, stype, id, scale, size.width/2, size.height/2)
    return btn_bg
end

function GameUI.addSkillIcon(bg, stype, id, scale, x, y, z,notHasShadow)
    if type(id)=="table" then
        scale = id.scale or 1
        x = id.x or 0
        y = id.y or 0
        z = id.z or 0
        id = id.id
    end
    local skey = stype
    if id then
        skey = skey .. "_" .. id
    end
    if _skillImageFixMap[skey] then
        skey = _skillImageFixMap[skey]
    else
        skey = "images/skillIcon/skill" .. skey .. ".png"
    end
    local temp = ui.sprite(skey)
    if not temp then
        temp = ui.sprite("images/skillIcon/skill2_100.png")
        local tmp2 = ui.label(StringManager.getString("dataSkillName" .. stype .. "_" .. id), General.font1, 40)
        display.adapt(tmp2, 113, 113, GConst.Anchor.Center)
        temp:addChild(tmp2)
    end
    --local bscale = 1.2989
    local bscale = 1.2
    if stype>=6 then
        bscale = 1
    end
    temp:setScale((scale or 1)*bscale)
    display.adapt(temp, x or 0, y or 0, GConst.Anchor.Center)
    bg:addChild(temp, z or 0)
    if not notHasShadow then
        local temp2 = ui.scale9("images/bgWhite.9.png", 20, {188,181})
        temp2:setColor(cc.c3b(0,0,0))
        temp2:setOpacity(79)
        temp2:setCustomPoint(0,0.025,0,0,0)
        temp2:setCustomPoint(1,0,0.945,0,1)
        temp2:setCustomPoint(2,1,0.029,1,0)
        temp2:setCustomPoint(3,0.935,1,1,1)
        display.adapt(temp2, -3, -11, GConst.Anchor.LeftBottom)
        temp:addChild(temp2,-1)
    end
    return temp
end

function GameUI.addSkillIcon2(bg, stype, id, sx, sy, x, y, z)
    local temp = GameUI.addSkillIcon(bg, stype, id, 1.05, x + sx/2, y + sy/2, z, true)
    local tsize = temp:getContentSize()
    local width, height = tsize.width * temp:getScaleX(), tsize.height * temp:getScaleY()
    temp:setScale(1)
    temp:setContentSize(cc.size(width * sx/160, height * sy/216))
    temp:setCustomModeNumber(8)
    temp:setCustomPoint(0, 0.187, 0, 0.187, 0)
    temp:setCustomPoint(1, 0.13, 0.057, 0.13, 0.057)
    temp:setCustomPoint(2, 0.13, 0.943, 0.13, 0.943)
    temp:setCustomPoint(3, 0.187, 1, 0.187, 1)
    temp:setCustomPoint(4, 0.813, 1, 0.813, 1)
    temp:setCustomPoint(5, 0.87, 0.943, 0.87, 0.943)
    temp:setCustomPoint(6, 0.87, 0.057, 0.87, 0.057)
    temp:setCustomPoint(7, 0.813, 0, 0.813, 0)

    return temp
end

--联盟旗帜
local flagBoxSet = {
    [1]={{299,290},1,12},
    [2]={{299,290},1,12},
    [3]={{299,290},1,12},
    [4]={{355,290},1,12},
    [5]={{355,290},1,12},
    [6]={{355,290},1,12},
    [7]={{318,310},2,22},
    [8]={{318,310},2,22},
    [9]={{320,310},1,22},

    [71]={{304,318},1,26},
    [72]={{302,318},2,26},
    [73]={{304,318},1,26},
    [74]={{304,318},1,26},
    [75]={{338,329},1,32},
    [76]={{338,329},1,32},
    [77]={{338,329},1,32},
    [78]={{338,329},1,32},
    [79]={{370,332},1,33},
    [80]={{370,332},1,33},
    [81]={{370,332},1,33},
    [82]={{370,332},1,33},
    [83]={{380,329},2,32},
    [84]={{380,329},2,32},
    [85]={{380,329},2,32},
    [86]={{382,329},1,32},
}
local flagShapeSet = {
    [2]={{118,253},60,0},
    [3]={{237,176},0,-39},
    [4]={{237,252},0,0},
    [5]={{237,209},0,5},
    [6]={{112,253},0,0},
    [7]={{237,252},0,-1},
    [8]={{199,132},0,-61},
    [9]={{199,132},0,-61},
    [10]={{237,134},0,39},
    [11]={{237,252},0,0},
    [12]={{237,252},0,-1},
    [13]={{237,252},0,-1},
    [14]={{195,91},-1,-42},
    [15]={{238,233},0,-10},
    [16]={{237,252},0,-1},
    [17]={{237,252},0,0},
    [18]={{238,253},1,1},
    [19]={{236,205},1,2},
    [20]={{238,121},0,66},

    [71]={{198,209},0,1},
    [72]={{181,212},-4,2},
    [73]={{225,231},0,-3},
    [74]={{229,212},0,6},
    [75]={{212,193},0,13},
    [76]={{225,232},0,1},
    [77]={{223,218},-1,1},
    [78]={{218,219},0,0},
    [79]={{197,198},0,3},
    [80]={{178,200},1,-3},
    [81]={{237,170},0,-7},
    [82]={{237,216},0,-20},
}
--色相，饱和度，明度
local flagColorSet = {
    [1] = {0,0,0},
    [2] = {170,17,16},
    [3] = {11,-19,-21},
    [4] = {-153,21,8},
    [5] = {93,-39,28},
    [6] = {5,-2,-9},
    [7] = {54,-41,-53},
    [8] = {148,-27,-2},
    [9] = {71,-58,-18},
    [10] = {0,13,16},
    [11] = {163,-66,68},
    [12] = {-71,-7,-53},
    [13] = {0,-100,-100},
}

function GameUI.addUnionFlag(ps1,ps2,ps3)
    if not ps2 then
        local ps = ps1
        ps1 = math.floor(ps/10000)
        ps2 = math.floor((ps-ps1*10000)/100)
        ps3 = ps%100
    end
    local node = ui.node()
    local st = flagBoxSet[ps3] or {{355,290},1,12}
    local temp
    if ps3>70 then
        temp = ui.sprite("images/flag/badgeBoxPay"..(ps3-70)..".png",st[1])
    else
        temp = ui.sprite("images/flag/badgeBox"..ps3..".png",st[1])
    end
    display.adapt(temp,st[2],st[3],GConst.Anchor.Center)
    node:addChild(temp)

    temp = ui.sprite("images/flag/flagShadow.png",{285,139})
    display.adapt(temp,2,-77,GConst.Anchor.Center)
    node:addChild(temp)

    local color = flagColorSet[ps2]
    local temp = ui.sprite("images/flag/flagBackBlue.png",{238,253})
    display.adapt(temp,0,0,GConst.Anchor.Center)
    node:addChild(temp)
    temp:setHValue(color[1])
    temp:setSValue(color[2])
    temp:setLValue(color[3])

    st = flagShapeSet[ps1]
    if ps1>1 then --形状1无图案
        if ps1>70 then
            temp = ui.sprite("images/flag/flagShapePay"..(ps1-70)..".png",st[1])
        else
            temp = ui.sprite("images/flag/flagShape"..ps1..".png",st[1])
        end
        display.adapt(temp,st[2],st[3],GConst.Anchor.Center)
        node:addChild(temp)
    end

    temp = ui.sprite("images/flag/flagShade.png",{238,254})
    display.adapt(temp,0,0,GConst.Anchor.Center)
    node:addChild(temp)
    return node
end

function GameUI.addFlag1(ps1)
    local node = ui.node()
    local temp = ui.sprite("images/flag/flagBackBlue.png",{238,253})
    display.adapt(temp,0,0, GConst.Anchor.Center)
    node:addChild(temp)
    temp:setHValue(-163)
    temp:setSValue(-93)
    temp:setLValue(11)

    if ps1>1 then --形状1无图案
        local st = flagShapeSet[ps1]
        if ps1>70 then
            temp = ui.sprite("images/flag/flagShapePay"..(ps1-70)..".png",st[1])
         else
            temp = ui.sprite("images/flag/flagShape"..ps1..".png",st[1])
        end
        display.adapt(temp,st[2],st[3], GConst.Anchor.Center)
        node:addChild(temp)
    end
    node:setScale(0.7)
    return node
end
function GameUI.addFlag2(ps2)
    local node = ui.node()
    local color = flagColorSet[ps2]
    local temp = ui.sprite("images/flag/flagBackBlue.png",{238,253})
    display.adapt(temp,0,0,GConst.Anchor.Center)
    node:addChild(temp)
    print_r(color)
    temp:setHValue(color[1])
    temp:setSValue(color[2])
    temp:setLValue(color[3])
    node:setScale(0.7)
    return node
end
function GameUI.addFlag3(ps3)
    local node = ui.node()

    local st = flagBoxSet[ps3] or {{355,290},0,12}
    local temp
    if ps3>70 then
        temp = ui.sprite("images/flag/badgeBoxPay"..(ps3-70)..".png",st[1])
    else
        temp = ui.sprite("images/flag/badgeBox"..ps3..".png",st[1])
    end
    display.adapt(temp,st[2],st[3],GConst.Anchor.Center)
    node:addChild(temp)

    temp = ui.sprite("images/flag/flagLockShading.png",{238,253})
    display.adapt(temp,0,0,GConst.Anchor.Center)
    node:addChild(temp)
    node:setScale(0.6)

    return node
end


local _heroColorSet = {180, -57, 0, 111, 80}

--显示英雄头像的模板
function GameUI.updateHeroTemplate(bg, info, hero, setting)
    local hid = 0
    local awakeUp = 0
    if hero then
    hid = hero.hid
        awakeUp = hero.awakeUp
    end

    local backType = 1
    local temp
    if info.type=="add" then
        backType = 2
    end
    if backType~=info.displayBackType then
        info.displayBackType = backType
        if info.back then
            info.back:removeFromParent(true)
            info.back = nil
        end
        if backType==1 then
            info.back = ui.shlNode(nil, true)
            if info.btype==1 then
                temp = ui.sprite("images/heroheadBack1.png",{267, 276})
                display.adapt(temp,-14, -24, GConst.Anchor.LeftBottom)
                info.back:addChild(temp,1)
                temp = ui.sprite("images/heroheadBack2.png",{241, 243})
                display.adapt(temp, -3, -5, GConst.Anchor.LeftBottom)
                info.back:addChild(temp)
            else
                temp = ui.scale9("images/bgWhite.9.png", 20, {248, 238})
                temp:setColor(cc.c3b(0,0,0))
                temp:setOpacity(79)
                temp:setCustomPoint(0,0.025,0,0,0)
                temp:setCustomPoint(1,0,0.945,0,1)
                temp:setCustomPoint(2,1,0.029,1,0)
                temp:setCustomPoint(3,0.935,1,1,1)
                display.adapt(temp, 3, -14)
                info.back:addChild(temp)
                temp = ui.scale9("images/bgDarkEdgeWhite.9.png", 20, {240,231})
                temp:setColor(cc.c3b(57,89,99))
                temp:setCustomPoint(1,0,0.975,0,1)
                temp:setCustomPoint(3,0.962,1,1,1)
                display.adapt(temp, -1, -1)
                info.back:addChild(temp)
            end
            info.back2 = temp
        else
            info.back = ui.sprite("images/btnAddHero.png",{238, 229})
            display.adapt(info.back, 0, 0)
        end
        bg:addChild(info.back, -1)
    end
    if backType==1 and info.btype~=1 then
        if hid>0 then
            ui.setColor(info.back2, {57,89,99})
        else
            ui.setColor(info.back2, {78,78,78})
        end
    end
    if hid~=info.displayHid or awakeUp~=info.displayAwakeUp  then
        if info.content then
            info.content:removeFromParent(true)
            info.content = nil
            info.stateIcon = nil
            info.labelLevel = nil
            info.labelDead = nil
        end
        info.displayHid = hid
        info.displayAwakeUp = awakeUp
        if hid>0 then
            temp = ui.node(nil, true)
            bg:addChild(temp)
            info.content = temp
            info.icon = GameUI.addHeadIcon(info.content, hid, 1, 119, 115,{lv = awakeUp})
            info.icon:setGlobalZOrder(1)
            if info.btype==1 then
                temp = ui.sprite("images/xuanzhong3.png",{226, 237})
                display.adapt(temp, 3, -2, GConst.Anchor.LeftBottom)
                info.content:addChild(temp)
                temp = ui.sprite("images/heroheadBackdian.png",{56, 56})
                display.adapt(temp, -17, 198, GConst.Anchor.LeftBottom)
                info.content:addChild(temp, 2)
                temp:setGlobalZOrder(1.1)
                temp = ui.sprite("images/heroheadBackdian.png",{56, 56})
                display.adapt(temp, 197, 198, GConst.Anchor.LeftBottom)
                info.content:addChild(temp, 2)
                temp:setGlobalZOrder(1.1)
                temp = ui.sprite("images/heroheadBackdian.png",{56, 56})
                display.adapt(temp, 197, -16, GConst.Anchor.LeftBottom)
                info.content:addChild(temp, 2)
                temp:setGlobalZOrder(1.1)
            end
            if info.lvUpZ then
                local z=info.lvUpZ
                temp = ui.sprite("images/heroLevelBack.png", {84, 89})
                display.adapt(temp, 25, 25, GConst.Anchor.Center)
                bg:addChild(temp,z)
                temp:setGlobalZOrder(1.1)
                temp:setHValue(_heroColorSet[hero.info.displayColor or hero.info.color])
                temp = ui.label("", General.font1, 32, {color=GConst.Anchor.White})
                display.adapt(temp, 25, 29, GConst.Anchor.Center)
                bg:addChild(temp,z)
                info.labelLevel = temp
                temp:setGlobalZOrder(2)
            end
            if not info.noLv and not info.lvUpZ then
                if info.lvRT then
                    temp = ui.sprite("images/heroLevelBack.png", {84, 89})
                    display.adapt(temp, 212, 208, GConst.Anchor.Center)
                    info.content:addChild(temp)
                    temp:setGlobalZOrder(1.1)
                    temp:setHValue(_heroColorSet[hero.info.displayColor or hero.info.color])
                    temp = ui.label("", General.font1, 32, {color=GConst.Anchor.White})
                    display.adapt(temp, 212, 212, GConst.Anchor.Center)
                    info.content:addChild(temp)
                    info.labelLevel = temp
                    temp:setGlobalZOrder(2)
                else
                    temp = ui.sprite("images/heroLevelBack.png", {84, 89})
                    display.adapt(temp, 25, 25, GConst.Anchor.Center)
                    info.content:addChild(temp)
                    temp:setGlobalZOrder(1.1)
                    temp:setHValue(_heroColorSet[hero.info.displayColor or hero.info.color])
                    temp = ui.label("", General.font1, 32, {color=GConst.Anchor.White})
                    display.adapt(temp, 25, 29, GConst.Anchor.Center)
                    info.content:addChild(temp)
                    info.labelLevel = temp
                    temp:setGlobalZOrder(2)
                end
            end
            GameUI.updateHeroDead(info)
        end
    end
    if hid>0 and info.labelLevel then
        info.labelLevel:setString(tostring(hero.level))
    end
    if setting then
        if setting.flagState and hid>0 then
            GameUI.resetHeroState(bg, info, hero)
        end
        if setting.flagEquip and hid>0 then
            GameUI.resetHeroEquip(bg, info, hero)
        end
    end
    GameUI.resetTemplateSelect(bg, info)
end

function GameUI.updateHeroDead(info)
    local stime = GameLogic.getSTime()
    if info.deadTime and info.deadTime>stime then
        if not info.labelDead then
            local temp = ui.label("", General.font1, 32, {color=GConst.Color.Red})
            display.adapt(temp, 119, 115, GConst.Anchor.Center)
            info.content:addChild(temp)
            info.labelDead = temp
            temp:setGlobalZOrder(2)
            temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",0.5},{"call", Handler(GameUI.updateHeroDead, info)}})))
            info.icon:setSValue(-100)
            info.back2:setColor(cc.c3b(78,78,78))
        end
        info.labelDead:setString(Localizet(info.deadTime-stime))
    else
        if info.labelDead then
            info.icon:setSValue(0)
            info.back2:setColor(cc.c3b(57,89,99))
            info.labelDead:removeFromParent(true)
            info.labelDead = nil
            info.deadTime = nil
        end
    end
end

--红色数字提示
function GameUI.addRedNum(bg,x,y,z,scale,maxNum)
    local node = ui.node()
    function node:setNum(num)
        self.bg = bg
        self.x = x
        self.y = y
        self.scale = scale
        self.maxNum = maxNum
        if not self.tanhao then
            self.tanhao = ui.sprite("images/redgantang.png",{64,65})
            display.adapt(self.tanhao,0,0,GConst.Anchor.LeftBottom)
            self:addChild(self.tanhao)

            self.back = ui.sprite("images/noticeBackRed.png",{64,65})
            display.adapt(self.back,0,0,GConst.Anchor.LeftBottom)
            node:addChild(self.back)
            self.lb = ui.label("1",General.font1,40,{color = {255,255,255}})
            display.adapt(self.lb,30,34,GConst.Anchor.Center)
            node:addChild(self.lb)
            self.lb:setGlobalZOrder(2)
        end
        if num>=self.maxNum then
            self.tanhao:setVisible(true)
            self.back:setVisible(false)
            self.lb:setVisible(false)
        elseif num<=0 then
            self.tanhao:setVisible(false)
            self.back:setVisible(false)
            self.lb:setVisible(false)
        else
            self.tanhao:setVisible(false)
            self.back:setVisible(true)
            self.lb:setVisible(true)
            self.lb:setString(num)
        end
    end
    node:setNum(1)
    display.adapt(node,x,y,GConst.Anchor.LeftBottom)
    bg:addChild(node,z)
    return node
end

--活动图片
function GameUI.addActiveImg(bg,id,sx,sy,x,y,z)
    local config={[204]={0,0,0.85},[202]={40,0,1},[206]={40,0,1},[207]={40,0,1},[104]={0,0,1.6},[106]={0,0,1.6},[60]={-20,0,1.6},[108]={0,0,0.9},[109]={0,0,1.5},[102]={-20,20,1},[20]={0,0,0.8},[21]={0,0,0.8}}

    local ox=0
    local oy=0
    local scal=1
    if config[id] then
        ox=config[id][1]
        oy=config[id][2]
        scal=config[id][3]
    end
    local ss=""
    if id==106 then
        local limitActive = GameLogic.getUserContext().activeData.limitActive
        local type,id=limitActive[106][4][1],limitActive[106][4][2]
        if id==const.ResCrystal then
            ss="_"..1
        elseif id==const.ResSpecial then
            ss="_"..2
        elseif id==const.ResZhanhun then
            ss="_"..3
        end
    end
    local key = "images/otherIcon/iconActivity" .. id .. ss ..".png"

    local acts = GameLogic.getUserContext().activeData:getConfigableActs()
    local suitableSize = nil
    if acts[id] and (acts[id].dialogIcon or acts[id].menuIcon) then
        key = (acts[id].dialogIcon or acts[id].menuIcon)
        suitableSize = acts[id].dialogIconSize
    end
    if cc.FileUtils:getInstance():isFileExist(key) then
        local temp = ui.sprite(key, suitableSize)
        display.adapt(temp,x+ox,y+oy,GConst.Anchor.Center)
        bg:addChild(temp)
        temp:setScale(scal)
        return temp
    end
end

--刷新英雄状态显示图标
function GameUI.resetHeroState(bg, info, hero)
    if not bg then
        return
    end
    local state = 0
    if info.forceState then
        state = 1
    else
        if info.forceLayouts then
            local layout = info.forceLayouts:getLayout(hero)
            if layout then
                if layout.type==1 then
                    state = 3
                else
                    state = 4
                end
            end
        else
            local layouts = hero:getLayouts()
            for lid, ltype in pairs(layouts) do
                if not info.lid or info.lid==lid then
                    if ltype.type==1 then
                        state = 3
                        break
                    elseif ltype.type>1 then
                        state = 4
                    end
                end
            end
        end
        if state==0 and hero.lock==1 then
            state = 2
        end
    end
    if state~=info.displayState then
        if info.stateIcon then
            info.stateIcon:removeFromParent(true)
            info.stateIcon = nil
        end

        info.displayState = state
        local temp = nil
        if state==1 then
            temp = ui.sprite("images/dialogItemYes.png",{90, 108})
            display.adapt(temp, 173, 154, GConst.Anchor.LeftBottom)
        elseif state==2 then
            temp = ui.sprite("images/btnHeroLockOn.png",{71, 84})
            display.adapt(temp, 220, 212, GConst.Anchor.Center)
        elseif state==3 then
            temp = ui.sprite("images/heroStateFight.png", {102, 102})
            display.adapt(temp, 206, 208, GConst.Anchor.Center)
        elseif state==4 then
            temp = ui.sprite("images/heroStateHelp.png", {102, 102})
            display.adapt(temp, 206, 208, GConst.Anchor.Center)
        end
        if temp then
            info.content:addChild(temp)
            info.stateIcon = temp
            temp:setGlobalZOrder(1.1)
        end
    end
end

--刷新英雄装备显示图标
function GameUI.resetHeroEquip(bg, info, hero)
    if not bg then
        return
    end
    local eid = 0
    if hero and hero.equip then
        eid = hero.equip.eid*10+hero.equip.color
    end
    if eid~=info.displayEid then
        if info.equipIcon then
            info.equipIcon:removeFromParent(true)
            info.equipIcon = nil
        end
        info.displayEid = eid
        if eid>0 then
            info.equipIcon = ui.node()
            display.adapt(info.equipIcon, 25, 208)
            bg:addChild(info.equipIcon)
            local temp
            temp = GameUI.addItemBack(info.equipIcon, hero.equip.color, 0.4, 0, 0)
            temp:setGlobalZOrder(1.1)
            temp = GameUI.addEquipIcon(info.equipIcon, hero.equip.eid, 0.35, 0, 0)
            temp:setGlobalZOrder(1.2)
        end
    end
end

--显示装备框的显示模板
function GameUI.updateEquipTemplate(bg, info, equip, setting)
    setting=setting or {}
    local eid = 0
    local backType = 1
    if equip then
        eid = equip.eid*10+equip.color
    end
    local temp
    -- if info.type=="add" then
    --     backType = 2
    -- end
    -- if backType~=info.displayBackType then
    --     info.displayBackType = backType
    --     if info.back then
    --         info.back:removeFromParent(true)
    --         info.back = nil
    --     end
    --     if backType==1 then
    --         info.back = ui.node(nil, true)
    --         temp = ui.scale9("images/bgWhite.9.png", 20, {248, 238})
    --         temp:setColor(cc.c3b(0,0,0))
    --         temp:setOpacity(79)
    --         temp:setCustomPoint(0,0.025,0,0,0)
    --         temp:setCustomPoint(1,0,0.945,0,1)
    --         temp:setCustomPoint(2,1,0.029,1,0)
    --         temp:setCustomPoint(3,0.935,1,1,1)
    --         display.adapt(temp, 3, -14)
    --         info.back:addChild(temp)
    --         if setting.shadowAgin then
    --             temp:setOpacity(158)
    --         end
    --         temp = ui.scale9("images/bgDarkEdgeWhite.9.png", 20, {240,231})
    --         temp:setColor(cc.c3b(57,89,99))
    --         temp:setCustomPoint(1,0,0.975,0,1)
    --         temp:setCustomPoint(3,0.962,1,1,1)
    --         display.adapt(temp, -1, -1)
    --         info.back:addChild(temp)
    --         info.back2 = temp
    --     else
    --         info.back = ui.sprite("images/btnAddHero.png",{238, 229})
    --         display.adapt(info.back, 0, 0)
    --     end
    --     bg:addChild(info.back, -1)
    -- end

    -- if backType==1 then
    --     if eid>0 then
    --         info.back2:setColor(cc.c3b(57,89,99))
    --     else
    --         info.back2:setColor(cc.c3b(78,78,78))
    --     end
    -- end
    if eid~=info.displayEid then
        if info.content then
            info.content:removeFromParent(true)
            info.content = nil
            info.labelLevel = nil
            info.stateIcon = nil
        end
        info.displayEid = eid
        if eid>0 then
            temp = ui.node(nil, true)
            bg:addChild(temp)
            info.content = temp
            GameUI.addItemBack(info.content,equip.color,1,119,115)
            GameUI.addEquipIcon(info.content,equip.eid,0.9,119,115)
            if not info.noLv then
                temp = ui.sprite("images/equipLevelBack.png",{90, 94.5})
                display.adapt(temp, 25+5, 22+5, GConst.Anchor.Center)
                info.content:addChild(temp)
                temp = ui.label("", General.font1, 43)
                display.adapt(temp, 25+2, 29+3, GConst.Anchor.Center)
                info.content:addChild(temp)
                info.labelLevel = temp
                temp:setGlobalZOrder(2)
                temp = ui.label("", General.font1, 54)
                display.adapt(temp, 10, 203, GConst.Anchor.Left)
                info.content:addChild(temp)
                info.labelLevelAdd = temp
                temp:setGlobalZOrder(2)
            end
        end
    end
    if eid>0 and info.labelLevel then
        info.labelLevel:setString(tostring(equip.level))
        if equip.elvup%4==0 then
            info.labelLevelAdd:setString("")
        else
            info.labelLevelAdd:setString("+" .. (equip.elvup%4))
        end
    end
    if setting and setting.flagHero then
        local state = 0
        if eid>0 and equip.hidx>0 then
            state = 1
        end
        if state~=info.displayState then
            if info.stateIcon then
                info.stateIcon:removeFromParent(true)
                info.stateIcon = nil
            end
            info.displayState = state
            local temp = nil
            if state==1 then
                temp = ui.sprite("images/dialogItemYes.png",{90, 108})
                display.adapt(temp, 173, -10, GConst.Anchor.LeftBottom)
            end
            if temp then
                info.content:addChild(temp)
                info.stateIcon = temp
            end
        end
    end
    GameUI.resetTemplateSelect(bg, info)
end

--刷新选中状态
function GameUI.resetTemplateSelect(bg, info, reuse)
    if not bg then
        return
    end
    if info.selected then
        local reuseGrid = info.displayGrid
        if not reuseGrid then
            if reuse then
                reuseGrid = reuse
            else
                reuseGrid = ui.sprite("images/dialogItemSelectGrid.png", {289,278})
                display.adapt(reuseGrid, -25, -25)
            end
            bg:addChild(reuseGrid)
            info.displayGrid = reuseGrid
            if info.scale then
                reuseGrid:setScale(info.scale)
            end
        end
    else
        local grid = info.displayGrid
        if grid then
            grid:removeFromParent(not reuse)
            grid = nil
            info.displayGrid = nil
            return grid
        end
    end
end

--更新关卡显示的通用模板；目前先用于Pvj；默认大小为154*154
function GameUI.updateStageTemplate(bg, info, setting)
    local stage = info.stage
    local stype = info.stype or 1
    local temp
    if not info.back then
        temp = ui.sprite("images/guankaBack.png",{154, 154})
        display.adapt(temp,0,0, GConst.Anchor.LeftBottom)
        bg:addChild(temp, -1)
        info.back = temp
    end
    local state = 0
    if info.isBoss then
        state = 1
        stype = 3
        stage = 1
    elseif info.isStore then
        state = 2
        stype = 2
        stage = 6
    elseif info.state then
        state = info.state
    end
    if state~=info.displayState then
        if info.stateIcon then
            info.stateIcon:removeFromParent(true)
            info.stateIcon = nil
        end
        info.displayState = state
        if state>0 then
            if state==1 then
                temp = ui.sprite("images/zombieIncomingBoss.png",{174, 89})
                display.adapt(temp,82,8, GConst.Anchor.Center)
                bg:addChild(temp,1)
            elseif state==2 then
                temp = ui.sprite("images/guankaDianLiang.png",{440, 450})
                display.adapt(temp,67,83, GConst.Anchor.Center)
                bg:addChild(temp)
            end
            info.stateIcon = temp
        end
    end
    if stage~=info.displayStage or stype~=info.displayStype then
        if info.stageIcon then
            info.stageIcon:removeFromParent(true)
            info.stageIcon = nil
        end
        if stype==1 then
            temp = ui.sprite("images/unionCity" .. stage .. ".png")
        elseif stype==2 then
            temp = ui.sprite("images/guankatubiao" .. stage .. ".png")
        else
            --for boss only
            temp = ui.sprite("images/pveCheckState3_" .. stage .. ".png")
        end
        info.stageIcon = temp
        display.adapt(temp,77,77, GConst.Anchor.Center)
        bg:addChild(temp,2)
    end
    if info.lock then
        info.stageIcon:setSValue(-100)
        if setting and setting.flagLockIcon then
            temp = ui.sprite("images/iconStageLock.png",{49, 57})
            display.adapt(temp, 77, 77, GConst.Anchor.Center)
            bg:addChild(temp,3)
            info.lockIcon = temp
        end
    else
        info.stageIcon:setSValue(0)
        if info.lockIcon then
            info.lockIcon:removeFromParent(true)
            info.lockIcon = nil
        end
    end
end

function GameUI.registerCountDownAction(label, dt)
    local lv = label
    if label.view then
        lv = label.view
    end
    local function updateTimeFunc()
        local stime = GameLogic.getSTime()
        label:setString(Localizet(dt-stime))
    end
    updateTimeFunc()
    lv:stopAllActions()
    lv:runAction(ui.action.arepeat(ui.action.sequence({{"delay",1},{"call", updateTimeFunc}})))
end

--更新用户头像用的模板；此为加在一个0*0的节点上；默认大小为159*186
function GameUI.updateUserHeadTemplate(bg, info)
    if not bg or not info then
        return
    end
    local temp
    local iconType = info.iconType
    if info.noHead then
        iconType = 0
    end
    if iconType~=info.displayIconType then
        info.displayIconType = iconType
        if info.head then
            info.head:removeFromParent(true)
            info.head = nil
            if info.labelLevel then
                info.labelLevel:removeFromParent(true)
                info.labelLevel = nil
            end
            if info._levelBack then
                info._levelBack:removeFromParent(true)
                info._levelBack = nil
            end
        end
        if iconType>0 then
            info.head = GameUI.addPlayHead(bg,{id=iconType,scale=info.headScale or 1,x=0,y=0,z=0,blackBack=(not info.notBlack), noBut=info.noBut})
        end
    end

    if not info.labelLevel and not info.noHead then
        local ox,oy=74,-50
        if info.lvRT then
            ox=-74
        end
        if iconType%10==0 or iconType%10==1 then
            temp = ui.sprite("images/headLvBack.png")
            temp:setSValue(-100)
        elseif iconType%10==2 or iconType % 10 > 4 then
            temp = ui.sprite("images/headLvBack.png")
        elseif iconType%10==3 then
            temp = ui.sprite("images/headLvBack3.png")
        elseif iconType%10==4 then
            oy=-65
            temp = ui.sprite("images/headLvBack4.png")
        else
            temp = ui.sprite("images/headLvBack.png")
        end
        display.adapt(temp, ox, oy, GConst.Anchor.Center)
        bg:addChild(temp)
        info._levelBack = temp
        temp = ui.label("", General.font1, 30)
        display.adapt(temp, ox, oy, GConst.Anchor.Center)
        bg:addChild(temp)
        info.labelLevel = temp
        temp:setGlobalZOrder(2)
    end
    if info.labelLevel then
        info.labelLevel:setString(tostring(info.level))
    end
    if info.name then
        local ox, oy = 110, info.hy or 18
        local fontSize = 40
        if info.noHead then
            ox = -40
            fontSize = 80
            oy = 38
        end
        if info.isLeft then
            temp = ui.label("", General.font5, 45)
            display.adapt(temp, ox, oy, GConst.Anchor.Left)
        else
            temp = ui.label("", General.font5, 45)
            display.adapt(temp, -ox, oy, GConst.Anchor.Right)
        end
        --temp:setGlobalZOrder(2)
        bg:addChild(temp)
        info.labelName = temp
        info.labelName:setString(info.name)
    end
end

--初始化菜单上的英雄按钮模板
function GameUI.updateBattleHeroTemplate(info)
    local bg = info.view
    local temp
    local buttonIdx = info.idx
    local groupData = info.groupData
    local hitem = groupData.hitems[buttonIdx]
    local back = 0
    local hero = nil
    local state = 0
    if hitem.hpos then
        back = 1
        hero = groupData.heros[hitem.hpos]
        if hero and type(hero) == "table" then
            if hero.deleted then
                state = 3
            else
                state = 2
                hero.params.hpos = hitem.hpos
            end
        else
            state = 1
        end
    end
    if back~=info.displayBack then
        info.displayBack = back
        if info.backView then
            info.backView:removeFromParent(true)
            info.backView = nil
        end
        local backNode = ui.node(nil,true)
        if back==1 then
            temp = ui.scale9("images/bgCellBack1.9.png", 48, {178, 245})
        else
            temp = ui.sprite("images/dialogCellBackBattle2.png",{178, 245})
        end
        display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
        backNode:addChild(temp)
        if back==1 then
            temp = ui.scale9("images/bgCellBack2.9.png", 15, {161, 219})
            ui.setColor(temp, GConst.Color.Black)
            display.adapt(temp, 9, 19, GConst.Anchor.LeftBottom)
            backNode:addChild(temp)
        end
        display.adapt(backNode, 0, 0, GConst.Anchor.LeftBottom)
        bg:addChild(backNode, -1)
        info.backView = temp
    end
    if state~=info.displayState then
        info.displayState = state
        if info.content then
            info.content:removeFromParent(true)
            info.content = nil
        end
        if state>0 then
            local content = ui.node(nil, true)
            display.adapt(content, 0, 0, GConst.Anchor.LeftBottom)
            bg:addChild(content)
            if state==1 then
                --加载英雄图片和士兵数量
                if hitem.hid == 4031 then
                    temp = GameUI.addHeroHead2(content, 40312, 200,360,-13,-40,nil,{lv=0})
                else
                    temp = GameUI.addHeroHead2(content, hitem.hid, 158,216,10,21,nil,{lv=hitem.awake})
                end
                temp:setGlobalZOrder(1)
                if hitem.sid then
                    temp = ui.sprite("images/bgWhite.9.png",{60, 59})
                    ui.setColor(temp, GConst.Color.Black)
                    display.adapt(temp, 11, 249, GConst.Anchor.LeftBottom)
                    content:addChild(temp)
                    temp = GameUI.addHeadIcon(content,hitem.sid,0.22,40,278,{lv = hitem.hero.soldierLevel})
                    temp:setGlobalZOrder(1)
                    temp = ui.label("", General.font1, 42, {color={255,255,255}})
                    display.adapt(temp, 168, 278, GConst.Anchor.Right)
                    content:addChild(temp)
                    info.numLabel = temp
                    temp:setGlobalZOrder(2)
                end
            elseif state==2 then
                --加载主动技能和英雄血条
                info.skillIcon = GameUI.addSkillIcon2(content, 1, hitem.mid, 158,216,10,21)
                info.skillIcon:setGlobalZOrder(1)
                temp = ui.sprite("images/bgWhite.9.png",{60, 59})
                ui.setColor(temp, GConst.Color.Black)
                display.adapt(temp, -21, 249, GConst.Anchor.LeftBottom)
                content:addChild(temp)
                local mode = hitem.hero.awakeUp
                if hitem.hid == 4031 then
                    info.miniHeroState = hitem.hero.heroState
                    info.content2 = content
                    info.miniHeroIcon = GameUI.addHeadIcon(content,hitem.hid,0.22,8,278,{lv = mode})
                    info.miniHeroIcon:setGlobalZOrder(1)
                else
                    temp = GameUI.addHeadIcon(content,hitem.hid,0.22,8,278,{lv = mode})
                    temp:setGlobalZOrder(1)
                end
                temp = ui.sprite("images/bgWhite.9.png")
                temp:setColor(cc.c3b(255, 0, 0))
                display.adapt(temp, -22, 248, GConst.Anchor.LeftBottom)
                content:addChild(temp,3)
                temp:setOpacity(127)
                temp:setVisible(false)
                info.headTwinkle = temp

                temp = ui.scale9("images/proBack1_2.png", 27, {130, 23})
                display.adapt(temp, 45, 264, GConst.Anchor.LeftBottom)
                content:addChild(temp)
                temp = ui.sprite("images/proFillerGreen.png",{127, 20})
                display.adapt(temp, 47, 265, GConst.Anchor.LeftBottom)
                content:addChild(temp)
                temp:setHValue(-79)
                info.hp = temp

                temp = ui.sprite("images/battleWhiteBck.png")
                display.adapt(temp, 10, 20, GConst.Anchor.LeftTop)
                content:addChild(temp)
                temp:setRotation(-90)
                temp:setVisible(false)
                temp:setGlobalZOrder(1.9)
                info.coldNode = temp
                temp = ui.sprite("images/iconDouqizhi.png",{84, 89})
                display.adapt(temp, -21, -3, GConst.Anchor.LeftBottom)
                content:addChild(temp,2)
                temp:setGlobalZOrder(1.1)
                info.angerBack = temp
                temp = ui.label("", General.font1, 43, {color={255,255,255}})
                display.adapt(temp, 21, 48, GConst.Anchor.Center)
                content:addChild(temp,2)
                temp:setGlobalZOrder(2)
                info.angerValue = temp
                temp = ui.label("", General.font1, 43, {color={255,255,255}, fontW = 180, fontH = 80})
                display.adapt(temp, 89, 124, GConst.Anchor.Center)
                content:addChild(temp,1)
                info.coldValue = temp
                temp:setGlobalZOrder(2)
                --能释放技能按钮上特效
                temp=UIeffectsManage:showEffect_zhanduiUI(content,86,113)
                temp:setVisible(false)
                info.btnEffect = temp

            elseif state==3 then
                --加载死亡图片
                temp = ui.sprite("images/iconDeath.png",{158,216})
                display.adapt(temp, 10, 21)
                content:addChild(temp, 1)
            end
            info.content = content
            info.role = hero
        end
    end
    if state==1 then
        if info.numLabel then
            info.numLabel:setString("x" .. hitem.num)
        end
    elseif state==2 then
        if hero.actSkillParams.x/10>groupData.anger and not groupData.inSkillGB10Godstate then
            info.skillIcon:setSValue(-100)
        else
            info.skillIcon:setSValue(0)
        end

        if hero.coldTime and hero.coldTime>0 then
            info.coldNode:setVisible(true)
            info.coldNode:setProcess(true,hero.coldTime/hero.actSkillParams.z)
            info.coldValue:setVisible(true)
            info.coldValue:setString(Localizet(hero.coldTime))
        else
            info.coldNode:setVisible(false)
            info.coldValue:setVisible(false)
        end

        if (hero.actSkillParams.x/10<=groupData.anger or groupData.inSkillGB10Godstate) and (not hero.coldTime or hero.coldTime<=0) then
            info.btnEffect:setVisible(true)

            --引导
            local context = GameLogic.getUserContext()
            if context.guide:getStep().type == "pauseForSkill" and context.guide:getStepState() == 0 then
                context.guideHand:removeHand("putHero")
                context.guideHand:showArrow(bg,79,216,20)
                display.pushGuide(Localize("stringCkickUseSkill"))
                context.guide:setStepState(1)
            elseif groupData.showGuide == 1 then
                groupData.showGuide = 2
                context.guideHand:removeHand("pve")
                context.guideHand:showArrow(bg,79,216,20)
            end

            local scene = GMethod.loadScript("game.View.Scene")
            local stage = scene.battleParams.stage
            if stage and 1<=stage and stage<=3 and context.pve:getPveMaxStage()<=3 then
                if not context.guideHand.hand then
                    context.guideHand:showArrow(info.content,79,216,z)
                    display.pushGuide(Localize("stringCkickUseSkill"))
                end
            end

        else
            info.btnEffect:setVisible(false)
        end
        info.angerValue:setString(tostring(hero.actSkillParams.x/10))
        info.hp:setProcess(true, hero.avtInfo.nowHp/hero.avtInfo.maxHp)
        if not info.nowHp then
            info.nowHp=hero.avtInfo.nowHp
        elseif info.nowHp~=hero.avtInfo.nowHp then
            info.nowHp=hero.avtInfo.nowHp
            info.headTwinkle:runAction(ui.action.sequence({{"show"},{"delay",0.2},{"hide"}}))
        end
        if hero.actSkillParams.x == 0 then
            info.angerValue:setVisible(false)
            info.angerBack:setVisible(false)
        end
        --萨满
        if hero.sid == 4021 then
            if #hero.battleMap2.diedHero<=0 then
                info.skillIcon:setSValue(-100)
                info.btnEffect:setVisible(false)
            end
        end
        if hero.sid == 4031 and hero.heroState ~= info.miniHeroState then
            info.miniHeroState = hero.heroState
            info.miniHeroIcon:removeFromParent(true)
            if hero.heroState == 0 then
                info.miniHeroIcon = GameUI.addHeadIcon(info.content2, 4031,0.22,8,278,{lv = 0})
            elseif hero.heroState == 1 then
                info.miniHeroIcon = GameUI.addHeadIcon(info.content2, 40312,0.52,-7,260,{lv = 0})
            end
        end
    end
    if info.selected then
        if not info.selectedView then
            temp = ui.sprite("images/dialogCellSelectedBattle.png",{198, 262})
            display.adapt(temp, 178/2, 245/2, GConst.Anchor.Center)
            bg:addChild(temp)
            info.selectedView = temp
            temp:setGlobalZOrder(3)
        end
    else
        if info.selectedView then
            info.selectedView:removeFromParent(true)
            info.selectedView = nil
        end
    end
end

--武器显示模板
function GameUI.updateBattleWeaponTemplate(info)
    local bg = info.view
    local temp
    if not info.numLabel then
        temp = ui.sprite("images/superweaponback.png",{160, 221})
        display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        temp = ui.scale9("images/bgCellBack2.9.png", 15, {142, 193})
        display.adapt(temp, 9, 18, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        ui.setColor(temp, GConst.Color.Black)
        temp = GameUI.addWeaponIcon2(bg, info.wid, 1, 80, 114, 0)
        temp:setGlobalZOrder(1)
        info.image = temp
        temp = ui.label("", General.font1, 42, {color={255,255,255}})
        display.adapt(temp, 139, 43, GConst.Anchor.Right)
        bg:addChild(temp)
        info.numLabel = temp
        temp:setGlobalZOrder(2)
    end
    info.numLabel:setString("x" .. (info.witem.num-info.witem.use))
    if info.witem.num == info.witem.use then
        info.image:setSValue(-100)
    else
        info.image:setSValue(0)
    end
    if info.selected then
        if not info.selectedView then
            temp = ui.sprite("images/dialogCellSelectedBattle.png",{180,238})
            display.adapt(temp, 160/2,221/2, GConst.Anchor.Center)
            bg:addChild(temp)
            info.selectedView = temp
        end
    else
        if info.selectedView then
            info.selectedView:removeFromParent(true)
            info.selectedView = nil
        end
    end
end

--敌方英雄显示模板
function GameUI.updateEnemyHeroTemplate(info)
    local bg, temp
    bg = info.view
    local buttonIdx = info.idx
    local groupData = info.groupData
    local hitem = groupData.hitems[buttonIdx]
    local hero = groupData.heros[hitem.hpos]
    local state = 0
    if hero then
        if hero.deleted then
            state = 2
        else
            state = 1
        end
    end
    if state~=info.displayState then
        info.displayState = state
        if state==0 then
            bg:removeAllChildren(true)
            info.back = nil
            info.content = nil
        else
            if not info.back then
                temp = ui.sprite("images/superweaponback.png",{146, 202})
                display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
                bg:addChild(temp, -1)
                info.back = temp
                temp = ui.scale9("images/bgCellBack2.9.png", 15, {116, 156})
                ui.setColor(temp, GConst.Color.Black)
                display.adapt(temp, 15, 18, GConst.Anchor.LeftBottom)
                bg:addChild(temp, -1)
            end
            if info.content then
                info.content:removeFromParent(true)
                info.content = nil
            end
            local content = ui.node(nil, true)
            display.adapt(content, 0, 0, GConst.Anchor.LeftBottom)
            bg:addChild(content)
            if state==1 then
                --加载英雄图片和士兵数量
                --1889, 1116
                GameUI.addHeroHead2(content, hitem.hid, 120,154,17,19)
                temp = ui.scale9("images/bgCellBack2.9.png", 15, {116, 156})
                display.adapt(temp, 15, 18, GConst.Anchor.LeftBottom)
                content:addChild(temp)
                ui.setColor(temp, GConst.Color.Red)
                temp:setOpacity(127)

                temp:setVisible(false)
                info.headTwinkle = temp

                temp = ui.sprite("images/proBack4.png",{97, 17})
                display.adapt(temp, 34, 178, GConst.Anchor.LeftBottom)
                content:addChild(temp)
                temp = ui.sprite("images/proFillerBlue.png",{95, 15})
                display.adapt(temp, 35, 179, GConst.Anchor.LeftBottom)
                content:addChild(temp)
                info.hp = temp
                temp = ui.sprite("images/hp2.png",{27, 24})
                display.adapt(temp, 5, 173, GConst.Anchor.LeftBottom)
                content:addChild(temp)
                if hitem.sid then
                    temp = ui.sprite("images/bgWhite.9.png",{48, 46})
                    ui.setColor(temp, GConst.Color.Black)
                    display.adapt(temp, -6, -2, GConst.Anchor.LeftBottom)
                    content:addChild(temp)
                    info.sdIcon = GameUI.addHeadIcon(content,hitem.sid,0.17,18,21,{lv = hitem.hero.soldierLevel})
                else
                    temp = ui.sprite("images/iconDouqizhi.png",{54, 57})
                    display.adapt(temp, -8, -5, GConst.Anchor.LeftBottom)
                    content:addChild(temp)
                end
                temp = ui.sprite("images/progressBack.png", {88, 13})
                display.adapt(temp, 43, 18, GConst.Anchor.LeftBottom)
                content:addChild(temp)
                temp = ui.sprite("images/proFillerOrange.png",{86, 13})
                display.adapt(temp, 44, 18, GConst.Anchor.LeftBottom)
                content:addChild(temp)
                info.anger = temp
            elseif state==2 then
                --加载死亡图片
                temp = ui.sprite("images/iconDeath.png",{120,174})
                display.adapt(temp, 17, 19)
                content:addChild(temp, 1)
            end
            info.content = content
        end
    end
    if state==1 then
        info.hp:setProcess(true, hero.avtInfo.nowHp/hero.avtInfo.maxHp)
        if hitem.sid then
            local troops = groupData.troops[hitem.hpos]
            local mhp, chp = 0, 0
            for _, troop in ipairs(troops) do
                mhp = mhp+troop.avtInfo.maxHp
                if not troop.deleted then
                    chp = chp+troop.avtInfo.nowHp
                end
            end
            info.anger:setProcess(true, chp/mhp)
            if chp<=0 then
                info.sdIcon:setSValue(-100)
            end
        end
        info.nowHp = info.nowHp or hero.M.nowHp
        if info.nowHp~=hero.M.nowHp then
            info.nowHp = hero.M.nowHp
            info.headTwinkle:runAction(ui.action.sequence({{"show"},{"delay",0.2},{"hide"}}))
        end
    end
end

function GameUI.updateBattleBossTemplate(info)
    local bg,temp
    local boss = info.role
    local state = 0
    bg = info.view
    if boss.deleted then
        state = 2
    else
        state = 1
    end
    if state ~= info.displayState then
        info.displayState = state
        if state == 0 then
            bg:removeAllChildren(true)
            info.back = nil
            info.content = nil
        else
            if not info.back then
                info.back = true
                temp = ui.sprite("images/proBack4.png",{266, 48})
                display.adapt(temp, 69, 1, GConst.Anchor.LeftBottom)
                bg:addChild(temp)
                temp = ui.sprite("images/proFillerBlue.png",{263, 40})
                display.adapt(temp, 68, 5, GConst.Anchor.LeftBottom)
                bg:addChild(temp)
                info.hp = temp
                local hpPct = boss.avtInfo.nowHp/boss.avtInfo.maxHp
                hpPct = math.floor(hpPct*10000)/100
                temp = ui.label(hpPct .. "%",General.font1,33,{color = {255,255,255}})
                display.adapt(temp, 198, 26, GConst.Anchor.Center)
                bg:addChild(temp)
                info.hpLb = temp
                temp:setGlobalZOrder(2)
                temp = ui.scale9("images/bgCellBack2.9.png", 15, {73, 100})
                display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
                bg:addChild(temp)
                ui.setColor(temp, GConst.Color.Black)
            end
            if info.content then
                info.content:removeFromParent(true)
                info.content = nil
            end
            local content = ui.node(nil, true)
            display.adapt(content, 0, 0, GConst.Anchor.LeftBottom)
            bg:addChild(content)
            if state == 1 then
                if boss.sid then
                    GameUI.addHeroHead(content,boss.sid,{size={77,98},x=0,y=1,z=2})
                else
                    GameUI.addBuildHead(content,boss.bid,77,98,38,49,1,boss.vstate.level)
                end
            elseif state == 2 then
                temp = ui.sprite("images/iconDeath.png",{77,98})
                display.adapt(temp, 1, 2)
                content:addChild(temp, 1)
                info.hp:setProcess(true,0)
                info.hpLb:setString("0%")
            end
            info.content = content
        end
    end
    if state == 1 then
        local hpPct = boss.avtInfo.nowHp/boss.avtInfo.maxHp
        info.hp:setProcess(true,hpPct)
        hpPct = math.floor(hpPct*10000)/100
        info.hpLb:setString(hpPct .. "%")
        GameUI.headTwinkle(info,boss.M.nowHp,73,100,0,0,3)
    end
end

function GameUI.headTwinkle(info,nowHp,sx,sy,x,y,z,anchor)
    if info.headTwinkle then
        info.headTwinkle.nowHp = info.headTwinkle.nowHp or nowHp
        if info.headTwinkle.nowHp ~= nowHp then
            info.headTwinkle:runAction(ui.action.sequence({{"show"},{"delay",0.2},{"hide"}}))
            info.headTwinkle.nowHp = nowHp
        end
    else
        -- local temp = ui.colorNode({sx, sy},{255,0,0,127})
        -- display.adapt(temp, x, y, anchor or GConst.Anchor.LeftBottom)
        -- info.content:addChild(temp,z or 0)
        local temp = ui.scale9("images/bgCellBack2.9.png", 15, {sx, sy})
        display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
        info.content:addChild(temp, z or 0)
        ui.setColor(temp, GConst.Color.Red)
        temp:setOpacity(127)
        temp:setVisible(false)
        info.headTwinkle = temp
    end
end

function GameUI.addAngerUp(bg, sx, sy, ox, oy)
    --1608, "sy": 28, "x": 80, "y": 25, --14,12,  3,18
    local dx = sx/20
    local temp
    for i=1,10 do
        temp = ui.sprite("images/angerSanJiao.png")
        display.adapt(temp, dx*(i*2-1)+ox, sy+oy, GConst.Anchor.Top)
        bg:addChild(temp)
        if i~=10 then
            temp = ui.sprite("images/angerSuTiao.png",{4,22})
            display.adapt(temp, dx*i*2+ox, oy, GConst.Anchor.Bottom)
            bg:addChild(temp)
        end
    end
end

function GameUI.addHaveGet(bg,text,scale,x,y,z)
    local node = ui.shlNode()
    local back = ui.sprite("images/unionSelectionRedBack.png",{317,207})
    node:addChild(back)
    local label = ui.label(text, General.font2, 65, {color={252,41,41},fontW=220,fontH=130})
    label:setRotation(-16)
    node:addChild(label,z or 0)
    node:setPosition(x or 0,y or 0)
    bg:addChild(node)
    node:setScale(scale or 1)
    return node
end

function GameUI.bubbleBut(bg,pos,limitH,content)
    local posH = pos[2]
    local butNum = #content
    local upLimitH=limitH[1] + (720-144*butNum)/2
    local downLimitH=limitH[2] - (720-144*butNum)/2
    local cursorH=0
    if posH<downLimitH then
        cursorH=posH-downLimitH
        posH=downLimitH
    elseif posH>upLimitH then
        cursorH=posH-upLimitH
        posH=upLimitH
    end
    local sizeH=144*butNum+140
    cursorH=cursorH+sizeH/2
    if cursorH>sizeH-48 then
        cursorH=sizeH-48
    elseif cursorH<64 then
        cursorH=64
    end
    local back=ui.button({443,sizeH},nil,{image = "images/unionOperationBack.png",priority=-3,actionType=0})
    display.adapt(back,pos[1] ,posH, GConst.Anchor.Left)
    bg:addChild(back)

    local temp = ui.sprite("images/unionOperationBackTriangle.png",{46,188})
    display.adapt(temp,-41,cursorH, GConst.Anchor.Left)
    back:addChild(temp)
    for i=1,butNum do
        local but = ui.button({340,133},nil,{image="images/btnGreen.png"})
        display.adapt(but,210,139+144*(i-1), GConst.Anchor.Center)
        back:addChild(but)
        local lb = ui.label(content[i][1], General.font1, 40, {color={255,255,255}})
        lb:setPosition(170,80)
        but:addChild(lb)
        but:setListener(function()
            content[i][2]()
        end)
    end

    return back
end

function GameUI.addFacebookHead(bg,fbId,params)
    local headIcon="images/iconFacebook1.png"
    local fname=Plugins.fbHead[fbId]
    if cc.FileUtils:getInstance():isFileExist(fname) then
        headIcon=fname
    end
    local size=params.size or {200,200}
    local temp=ui.sprite(headIcon,size)
    display.adapt(temp,0,0,GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    return temp
end

function GameUI.initLoadingEffects()
    if not GameUI.loadingEffects then
        GameUI.loadingEffects = {}
    end
    local scale = ui.getUIScale2()
    local viewsNode
    viewsNode = ui.touchNode(display.winSize, -10)
    display.adapt(viewsNode, display.winSize[1]/2, display.winSize[2]/2, GConst.Anchor.Center)
    display.removeLayer(20)
    display.addLayer(viewsNode, 20, 20)
    local back = ui.colorNode(display.winSize, {0,0,0,178})
    display.adapt(back, 0, 0, GConst.Anchor.LeftBottom)
    viewsNode:addChild(back)
    local p = ui.animateSprite(0.8, "loading_", 12, {beginNum=0, plist="effects/UIeffectsRes/loading.plist", isRepeat=true})
    display.adapt(p, 0, 0, GConst.Anchor.Center, {scale=scale})
    viewsNode:addChild(p)

    viewsNode:setVisible(false)
    GameUI.loadingEffects.loading = viewsNode
    GameUI.loadingEffects.loadingCount = 0

    viewsNode = ui.touchNode({0, 0}, -10, false)
    display.adapt(viewsNode, 0, 0, GConst.Anchor.Center, {scale=scale})
    display.removeLayer(19)
    display.addLayer(viewsNode, 19, 19)

    p = ui.sprite("effects/UIeffectsRes/wiff_back.png")
    display.adapt(p, 0, 0, GConst.Anchor.Center)
    p:setOpacity(89)
    viewsNode:addChild(p)
    p = ui.sprite("effects/UIeffectsRes/wiff.png")
    display.adapt(p, 0, 0, GConst.Anchor.Center)
    p:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",10/60,102},{"fadeTo",10/60,255}})))
    viewsNode:addChild(p)

    viewsNode:setVisible(false)
    GameUI.loadingEffects.wifi = viewsNode
    GameUI.loadingEffects.wifiCount = 0
end

function GameUI.refreshLoading()
    local effects = GameUI.loadingEffects
    if not effects then
        return
    end
    if effects.loadingCount > 0 then
        effects.loading:setVisible(true)
        effects.wifi:setVisible(false)
    elseif effects.wifiCount > 0 and not effects.inLoading then
        effects.loading:setVisible(false)
        effects.wifi:setVisible(true)
    else
        effects.loading:setVisible(false)
        effects.wifi:setVisible(false)
    end
end

function GameUI.setLoadingState(inScene)
    local effects = GameUI.loadingEffects
    if not effects then
        return
    end
    effects.inLoading = inScene
    GameUI.refreshLoading()
end

function GameUI.setLoadingShow(effectName, show, wait)
    local effects = GameUI.loadingEffects
    if not effects then
        return
    end
    local view = effects[effectName]
    local cname = effectName .. "Count"
    local atag = 11
    if show then
        if effects[cname] < 0 then
            effects[cname] = 0
        end
        effects[cname] = effects[cname] + 1
        if wait and wait <= 0 then
            GameUI.refreshLoading()
        elseif effects[cname] == 1 then
            local action = view:getActionByTag(atag)
            if action then
                view:stopAction(action)
            end
            action = ui.action.sequence({{"delay", wait or 1}, {"call", GameUI.refreshLoading}})
            action:setTag(atag)
            view:runAction(action)
        end
    else
        effects[cname] = effects[cname] - 1
        if effects[cname] < 0 then
            effects[cname] = 0
        end
        if effects[cname] == 0 then
            local action = view:getActionByTag(atag)
            if action then
                view:stopAction(action)
            end
            GameUI.refreshLoading()
        end
    end
end

--对话框背景重做下
function GameUI.createDialogShadow(size)
    local temp = ui.scale9("images/bgWhite2.9.png", 20, {size[1]/2, size[2]/2})
    ui.setColor(temp, GConst.Color.Black)
    temp:setOpacity(127)
    temp:setCustomPoint(0, 0.006, 0.010, 0, 0)
    temp:setCustomPoint(1, 0.004, 0.980, 0, 1)
    temp:setCustomPoint(2, 0.994, 0.017, 1, 0)
    temp:setCustomPoint(3, 0.993, 0.990, 1, 1)
    temp:setScale(2)
    return temp
end

-- 对话框背景的实际实现原理
function GameUI.createRealDialogBack(backSize, whiteRect)
    -- 先创建一个根节点
    local node = ui.node(backSize)
    -- 然后加上蓝色底图的scale9
    local sprite = ui.scale9("images/dialogBack_1.png",{11, 3, 67, 100}, backSize)
    display.adapt(sprite,0,0,GConst.Anchor.LeftBottom)
    node:addChild(sprite)
    -- 然后如果有白色框，则加上白色部分
    if whiteRect then
        sprite = ui.scale9("images/dialogBack_2.png", 60, {whiteRect[3], whiteRect[4]})
        display.adapt(sprite, whiteRect[1], whiteRect[2],GConst.Anchor.LeftBottom)
        sprite:setColor(cc.c3b(239,218,180))
        node:addChild(sprite)
    end
    -- 最后加上杂色图层
    local scale = 618 / 128
    local texture = memory.loadTexture("images/dialogBack_3_repeat.png")
    texture:setTexParameters(gl.NEAREST, gl.NEAREST, gl.REPEAT, gl.REPEAT)
    local cnode = ui.sprite("images/dialogBack_3_repeat.png")
    cnode:setTexture(texture)
    cnode:setTextureRect(cc.rect(0, 0, backSize[1]/scale, backSize[2]/scale))
    cnode:setScale(scale)
    cnode:setOpacity(25)
    display.adapt(cnode,0,0,GConst.Anchor.LeftBottom)
    node:addChild(cnode)
    return node
end

function GameUI.createDialogBack(filename, size)
    local whiteRect
    if filename=="images/dialogBack1.png" then
        local scaX=size[1]/1559
        local scaY=size[2]/1021
        whiteRect = {13*scaX, 14*scaY, size[1]-26*scaX, size[2]-134*scaY}
    elseif filename=="images/dialogBack2.png" then
        local scaX=size[1]/2048
        local scaY=size[2]/1536
        whiteRect = {22*scaX, 24*scaY, size[1]-44*scaX, size[2]-184*scaY}
    elseif filename=="images/dialogBackSmall.png" then
        local scaX=size[1]/866
        local scaY=size[2]/576
        whiteRect = {20*scaX, 22*scaY, size[1]-40*scaX, size[2]-142*scaY}
    end
    return GameUI.createRealDialogBack(size, whiteRect)
end

--添加英雄评级
function GameUI.addSSR( bg,ssrID,scale,x,y,z,anchor )
    if not ssrID or not bg then
        return
    end
    local temp = ui.sprite("images/btnImageQuality"..ssrID..".png")
    if not temp then
        return
    end
    local _anchor = anchor or GConst.Anchor.Center
    temp:setScale(scale)
    display.adapt(temp,x,y,_anchor)
    bg:addChild(temp,z or 0)
    return temp
end
--添加活动角标
function GameUI.addCornerSgin( bg,text,scale,x,y,z )
    if not bg then
        return
    end
    local node = ui.node()
    node:setScale(scale)
    display.adapt(node,x,y)
    bg:addChild(node,z or 1)

    local temp = ui.sprite("images/icon_biaoqian.png")
    node:addChild(temp)

    local label = ui.label(text, General.font2, 42, {color={255,255,255},fontW=60,fontH=45})
    display.adapt(label,-20,20,GConst.Anchor.Center)
    label:setRotation(-45)
    node:addChild(label)

    return node
end

-- 用数学公式计算象限和点坐标
local function _innerComputeCircle(normalPts, angle, centerX, centerY)
    local angleIdx
    for i=1, 5 do
        if normalPts[i][3] <= angle then
            angleIdx = i
        end
    end
    if angleIdx == 5 then
        angleIdx = 1
    end
    local edgeX, edgeY
    local radAngle = math.rad(angle)
    local sinv, cosv = math.sin(radAngle), math.cos(radAngle)
    if angleIdx % 2 == 1 then
        edgeY = (angleIdx - 1) / 2
        edgeX = centerX - (edgeY - centerY) * sinv / cosv
    else
        edgeX = (4 - angleIdx) / 2
        edgeY = centerY - (edgeX - centerX) * cosv / sinv
    end
    return angleIdx, edgeX, edgeY
end

-- 设置圆形进度，参数为：
-- img 图片本身，如果是View.lua系列注意用.view，必须
-- process 进度百分比（0~1），必须
-- startAngle 起始角度 0~360度，按顺时针方向取值，默认0度表示12点方向
-- angleDir 进度增加方向（顺时针1，逆时针-1）
-- centerX, centerY 圆心在图片的百分比，标准圆形应该都是0.5、0.5
function GameUI.setCircleProcess(img, process, startAngle, angleDir, centerX, centerY)
    if not startAngle then
        startAngle = 0
    else
        while startAngle < 0 do
            startAngle = startAngle + 360
        end
        startAngle = startAngle % 360
    end
    if not angleDir then
        angleDir = 1
    end
    if not centerX then
        centerX = 0.5
    end
    if not centerY then
        centerY = 0.5
    end
    if process <= 0 then
        img:setVisible(false)
        return
    end
    img:setVisible(true)
    -- 中心点
    local points = {{centerX, centerY}}
    local normalPts = {{centerX, 0}, {1, 0}, {1, 1}, {0, 1}, {0, 0}}
    for _, pt in ipairs(normalPts) do
        pt[3] = -math.deg(math.atan2(pt[1]-centerX, pt[2]-centerY))+180
    end

    if process > 1 then
        process = 1
    end
    local startAngleIdx, endAngleIdx, x, y
    -- 起始点
    startAngleIdx, x, y = _innerComputeCircle(normalPts, startAngle, centerX, centerY)
    table.insert(points, {x, y})

    endAngleIdx, x, y = _innerComputeCircle(normalPts, (startAngle + process * 360 * angleDir + 360) % 360, centerX, centerY)
    -- 中间需要插入象限点
    while true do
        local _sidx = (startAngleIdx + 7) % 4
        if _sidx == (endAngleIdx + 7) % 4 then
            -- 区分只有小于90度的小角和大于270度的大角
            if process <= 0.25 or #points > 2 then
                --结束点
                table.insert(points, {x, y})
                break
            end
        end
        startAngleIdx = startAngleIdx + angleDir
        --象限点
        table.insert(points, normalPts[_sidx + 2])
    end
    img:setCustomModeNumber(#points)
    for i, pt in ipairs(points) do
        img:setCustomPoint(i-1, pt[1], pt[2], pt[1], pt[2])
    end
end

--参观玩家
function GameUI.addVisitNode(bg, x, y, params)
    local _params = params or {}
    local zorder = params.zorder
    local priority = _params.priority
    local btnVisitPlayerFunc = _params.func1
    local btnVisitUnionFunc = _params.func2
    local lb_name1 = _params.lb_name1
    local lb_name2 = _params.lb_name2

    local btn_visitPlayer
    local btn_visitUnion

    -- temp = ui.button({212, 82} ,nil, {image="images/btnOrange.png"})
    local node = ui.node()
    display.adapt(node, x, y, GConst.Anchor.Center)
    bg:setLocalZOrder(zorder)
    bg:addChild(node)

    local sprite = ui.sprite("images/unionOperationBackTriangle.png", {46, 188})
    display.adapt(sprite, -41, 0, GConst.Anchor.Left)
    node:addChild(sprite)

    sprite = ui.sprite("images/unionOperationBack.png", {400, 300})
    display.adapt(sprite, 0, 0, GConst.Anchor.Left)
    node:addChild(sprite)

    btn_visitPlayer = ui.button({272, 106}, btnVisitPlayerFunc, {image = "images/btnGreen.png", priority = priority})
    display.adapt(btn_visitPlayer, 190, 58, GConst.Anchor.Center)
    node:addChild(btn_visitPlayer)

    local label = ui.label(lb_name1, General.font1, 36, {fontW = 250, fontH = 60})
    display.adapt(label, 136, 60, GConst.Anchor.Center)
    btn_visitPlayer:getDrawNode():addChild(label)

    btn_visitUnion = ui.button({272, 106}, btnVisitPlayerFunc, {image = "images/btnGreen.png", priority = priority})
    display.adapt(btn_visitUnion, 190, -68, GConst.Anchor.Center)
    node:addChild(btn_visitUnion)

    label = ui.label(lb_name2, General.font1, 36, {fontW = 250, fontH = 60})
    display.adapt(label, 136, 60, GConst.Anchor.Center)
    btn_visitUnion:getDrawNode():addChild(label)

    return node, btn_visitPlayer, btn_visitUnion
end

-- 加入测试代码来注入display模块
if not display.rawShowDialog then
    display.rawShowDialog = display.showDialog
    display.rawCloseDialog = display.closeDialog
end

do
    --UI层的对话框列表
    local _newDialogs = {}
    local _newDialogDepth = 0

    --按优先级关闭对话框，可支持多级对话框关闭
    function display.closeDialog(pri, closeWhenShow)
        local maxPri = display.getDialogPri()

        display.rawCloseDialog(pri, closeWhenShow)
        local depth = 0
        local depDialog = {}
        depDialog[0] = GMethod.loadScript("game.View.Scene")
        for i=1, maxPri do
            if _newDialogs[i] then
                if not _newDialogs[i].deleted then
                    depth = depth + 1
                    depDialog[depth] = _newDialogs[i]
                else
                    _newDialogs[i] = nil
                end
            end
        end
        local visibleDepth = depth - 1
        if depDialog[depth].isFullColor then
            visibleDepth = depth
        end
        for i=0, depth do
            if depDialog[i].view then
                depDialog[i].view:setVisible(i >= visibleDepth)
            end
        end
        GameEvent.sendEvent("EventCloseFinish")
    end

    --对话框进出动画，接受可定制方法
    function display.showDialog(dialog, autoPop, fullscreen, opPct)
        if display.lock then
            return
        end
        if type(dialog)=="table" and not dialog.view then
            if dialog.new then
                dialog = dialog.new()
            else
                dialog:create()
            end
        end
        if type(dialog)=="userdata" then
            dialog = {view=dialog, priority=dialog.priority, swallow=dialog.swallow, enterAnimate=dialog.enterAnimate, exitAnimate=dialog.exitAnimate, autoCloseCallback=dialog.autoCloseCallback}
        end
        if not dialog.view or dialog.deleted then
            return
        end
        display.rawShowDialog(dialog, autoPop, fullscreen, opPct)
        -- 穿透型透明对话框，不计入层级
        if not dialog.swallow then
            local maxPri = dialog.priority or 1
            _newDialogs[maxPri] = dialog
            local depth = 0
            local depDialog = {}
            depDialog[0] = GMethod.loadScript("game.View.Scene")
            for i=1, maxPri do
                if _newDialogs[i] then
                    if not _newDialogs[i].deleted then
                        depth = depth + 1
                        depDialog[depth] = _newDialogs[i]
                    else
                        _newDialogs[i] = nil
                    end
                end
            end
            local visibleDepth = depth - 1
            if depDialog[depth].isFullColor then
                visibleDepth = depth
            end
            for i=0, depth do
                depDialog[i].view:setVisible(i >= visibleDepth)
            end
        end
    end

    -- 仿android的一种实现方案
    function display.sendIntent(intent)
        if not intent then
            return
        end
        local intentType = intent.type or "dialog"
        if intentType == "dialog" then
            local className = intent.class
            local params = intent.params
            local newDialogClass = GMethod.execute(className)
            --GMethod.loadScript(className)
            --GMethod.execute(className)
            local newDialog = newDialogClass.new(params)
            newDialog.__intent = intent
            if not intent.autoShowed then
                display.showDialog(newDialog, intent.autoPop or newDialog._autoPop or true)
            end
        end
    end

    -- 就是需要做个暂时屏蔽下层所有点击的层
    function display.addTempLayer(callback)
        local dialog = {view=ui.button(display.winSize, callback, {}), priority=display.getDialogPri()+1}
        display.showDialog(dialog, false, true, 0)
    end
end

-- @brief 封装增加logo接口
function GameUI.addLogo(bg, scale, x, y, anchor)
    local temp
    if GEngine.rawConfig.logoSpecial then
        temp = ui.sprite(GEngine.rawConfig.logoSpecial[1])
    elseif GEngine.rawConfig.logoSpecialQianxun then
        local language = General.language
        temp = ui.sprite(GEngine.rawConfig.logoSpecialQianxun[1][language])
    else
        local channel = string.gsub(GEngine.rawConfig.channel, "(.-)%d*$", "%1")
        if scale < 0.4 and cc.FileUtils:getInstance():isFileExist("images/shares/fbShareLogoEN.png")
            and (channel == "com.bettergame.heroclash_our" or channel == "com.bettergame.heroclash_ios"
                or channel == "com.bettergame.heroclash_google") then
            scale = scale * 10 / 3
            if General.language == "CN" or General.language == "HK" then
                temp = ui.sprite("images/shares/fbShareLogoCN.png")
            else
                temp = ui.sprite("images/shares/fbShareLogoEN.png")
            end
        else
            if General.language == "CN" or General.language == "HK" then
                temp = ui.sprite("images/coz2logo3.png")
            else
                temp = ui.sprite("images/coz2logo3_2.png")
            end
        end
    end
    if temp then
        temp:setScale(scale)
        display.adapt(temp, x, y, anchor)
        bg:addChild(temp)
        return temp
    end
end

function GameUI.setNormalIcon(bg, icon, noBack, withNum)
    bg:removeAllChildren(true)
    if type(icon) == "string" then
        local tmp = ui.sprite(icon, bg.size, true)
        display.adapt(tmp, bg.size[1]/2, bg.size[2]/2, GConst.Anchor.Center)
        bg:addChild(tmp)
    elseif type(icon) == "table" then
        GameUI.addItemIcon(bg, icon[1], icon[2], bg.size[1]/200, bg.size[1]/2, bg.size[2]/2, not noBack, false, withNum and {itemNum=icon[3]})
    end
end

function GameUI.setHeadBackIcon(bg, headBackId, useBlack)
    local width, height
    if type(bg) == "table" then
        if bg.__icon then
            bg.__icon:removeFromParent(true)
            bg.__icon = nil
        end
        width = bg.size[1]
        height = bg.size[2]
    end
    local tmp
    local ox, oy, os = 0, 0, 1
    if useBlack then
        tmp = ui.sprite("images/iconBack".. headBackId ..".png")
    else
        tmp = ui.sprite("images/iconBack".. headBackId .."_2.png")
        os = bg.size[1] / 200
        if headBackId == 5 then
            ox = -5
            oy = 12
        end
    end
    tmp:setScale(os)
    display.adapt(tmp, bg.size[1]/2 + ox * os, bg.size[2]/2 + oy*os, GConst.Anchor.Center)
    bg:addChild(tmp)
    bg.__icon = tmp
end
