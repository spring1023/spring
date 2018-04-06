local SData = GMethod.loadScript("data.StaticData")
local const = GMethod.loadScript("game.GameLogic.Const")
local BU = GMethod.loadScript("game.Build.Util")
local Build = GMethod.loadScript("game.Build.Build")

local function updateBattleItemsCell(cell,scrollView,info)
    local bg, temp
    bg = cell:getDrawNode()
    cell:setEnable(false)
    temp = ui.sprite("images/storeCellBg2.png",{155, 203})
    display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    if info[1]==0 then
        temp:setSValue(-100)
        temp:setOpacity(153)
    else
        temp = ui.colorNode({115, 46},{34,120,166})
        display.adapt(temp, 7, 9, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        if info[1]==1 then
            SoldierHelper.addSoldierHead(bg, info[2], 0.64, 77, 125)
        elseif info[1]==2 then
            WeaponHelper.addWeaponHead(bg, info[2], 0.64, 77, 125)
        end
        temp = ui.sprite("images/iconLvBack.png",{67, 61})
        display.adapt(temp, -2, 53, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        temp = ui.label(tostring(info[3]), General.font1, 32, {color={255,255,255}})
        display.adapt(temp, 32, 85, GConst.Anchor.Center)
        bg:addChild(temp)
        temp = ui.label("x", General.font1, 35, {color={170,159,159}})
        display.adapt(temp, 15, 32, GConst.Anchor.Left)
        bg:addChild(temp)
        local w = temp:getContentSize().width * temp:getScaleX()
        temp = ui.label(tostring(info[4]), General.font1, 35, {color={255,255,255}})
        display.adapt(temp, 21+w, 32, GConst.Anchor.Left)
        bg:addChild(temp)
    end
end

local function updateUnlockBuildCell(cell,scrollView,info)
    local bid = info[1]
    local nnum = info[2]
    local onum = info[3]
    local bg, temp
    bg = cell:getDrawNode()
    cell:setEnable(false)
    temp = ui.sprite("images/dialogCellWhite.png",{162, 154})
    display.adapt(temp, 0, 0)
    bg:addChild(temp)

    local newBuild = Build.new(bid,1)
    newBuild:addBuildView(bg, 81, 77, 162, 154, 0.8)

    temp=ui.scale9("images/bgWhite.9.png", 20, {70, 48})
    temp:setColor(cc.c3b(169, 192, 200))
    display.adapt(temp, 13, 97, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    local tempStr
    if onum==0 then
        tempStr = StringManager.getString("labelBuildNew")
    else
        tempStr = "x" .. (nnum-onum)
    end
    temp = ui.label(tempStr, General.font1, 30, {color={255,255,255},fontW=58,fontH=40})
    display.adapt(temp, 20, 122, GConst.Anchor.Left)
    bg:addChild(temp)
end

InfoDialog = {}

function InfoDialog.show(build,itype)
    local temp, bg = nil
    local dialog = {}
    DialogTemplates.loadDefaultTemplate(dialog, 1)
    bg = dialog.view
	temp = ui.sprite("images/dialogInfoLight.png",{608, 581})
    display.adapt(temp, -41+608/2,420+581/2, GConst.Anchor.Center)
    bg:addChild(temp)
    
    local bsetting = build.bsetting
    local bdid = bsetting.bdid
    --local maxData = SData.getData("bdatas", bdid, build.info.maxLv or 10)
    local lv5 = build.level+5
    local maxLv = build.info.maxLv or 10
    lv5 = lv5>maxLv and maxLv or lv5
    local maxData = SData.getData("bdatas", bdid, lv5)
    maxData.hp = maxData.hp or 0
    local curData = build.data
    local newBuild = build
    local nextData = curData
    local binfo = build.info
    local maxArmor, armor, nextArmor
    if binfo.maxArmor and binfo.maxArmor>0 then
        maxArmor = SData.getData("armors", bdid, build.info.maxArmor)
        armor = {armor=0}
        local alv = build.armor or 0
        if alv>0 then
            armor = SData.getData("armors",bdid, alv)
        end
        nextArmor = {armor=nil}
        if itype==3 and alv<binfo.maxArmor then
            nextArmor = SData.getData("armors",bdid, alv+1)
        end
    end
    if itype==2 then
        newBuild = Build.new(build.bid, build.level+1)
        nextData = newBuild.data
    end
    newBuild:addBuildView(bg, 252, 684, 318, 318, 1.2)
    local rtitems = {}
    local infoType
    if itype==2 then
        dialog.title:setString(StringManager.getFormatString("titleUpgrade",{level=newBuild.level}))
        temp = ui.scale9("images/bgWhiteGrid2.9.png", 20, {253, 111})
        ui.setColor(temp, {191, 184, 170})
        display.adapt(temp, 39, 520, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        temp = ui.scale9("images/bgWhiteGrid2.9.png", 20, {249, 107})
        ui.setColor(temp, {255, 215, 107})
        display.adapt(temp, 41, 522, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        temp = ui.label(StringManager.getString("labelUpgradeTime"), General.font2, 28, {color={84,68,52}, fontW = 260, fontH=50})
        display.adapt(temp, 165, 606, GConst.Anchor.Center)
        bg:addChild(temp)
        temp = ui.label(StringManager.getTimeString(newBuild.data.ctime), General.font1, 40, {color={255,255,255}})
        display.adapt(temp, 165, 558, GConst.Anchor.Center)
        bg:addChild(temp)
        temp = ui.label(BU.getBuildName(build.bid), General.font1, 36, {color={254,254,221}})
        display.adapt(temp, 252, 859, GConst.Anchor.Center)
        bg:addChild(temp)
        
        local exts = bsetting.upgradeExts or bsetting.infoExts
        if exts then
            local eitem
            for i, ext in ipairs(exts) do
                local dkey = ext.dkey
                eitem = {icon=ext.icon, format=ext.text, value=curData[dkey], next=nextData[dkey], max=maxData[dkey], isUpgrade=true}
                table.insert(rtitems, eitem)
            end
        end
        if maxData.hp>0 then
            table.insert(rtitems, {icon="hp",format="formatHp",value=curData.hp, next=nextData.hp, max=maxData.hp})
        end
        infoType = bsetting.upgradeType or bsetting.infoType
    else
        if itype==3 then
            if (build.armor or 0)==0 then
                dialog.title:setString(StringManager.getString("titleUnlockArmor"))
            else
                dialog.title:setString(StringManager.getFormatString("titleUpgradeArmor",{level=(build.armor or 0)+1}))
            end
        else
            dialog.title:setString(BU.getBuildTitle(build))
        end
        local exts = bsetting.infoExts
        if exts then
            local eitem
            for i, ext in ipairs(exts) do
                eitem = {icon=ext.icon, format=ext.text}
                local dkey = ext.dkey
                if ext.info then
                    local ep = build
                    if ep and ep[ext.info] then
                        eitem.value = Script.createBasicHandler(ep[ext.info], build)
                    else
                        local context = GameLogic.getCurrentContext()
                        eitem.value = Script.createBasicHandler(context.getValue, context, ext.info)
                    end
                    eitem.max = curData[dkey]
                else
                    eitem.value = curData[dkey]
                    eitem.max = maxData[dkey]
                end
                table.insert(rtitems, eitem)
            end
        end
        if maxData.hp>0 then
            table.insert(rtitems, {icon="hp",format="formatHp",value=Script.createBasicHandler(build.getHp, build), max=curData.hp})
        end
        infoType = bsetting.infoType
    end
    if armor then
        table.insert(rtitems, {icon="armor",format="formatArmor", value=armor.armor, next=nextArmor.armor, max=maxArmor.armor})
    end
    local initx, inity, offy = 648, 787, 107
    if #rtitems==4 then
        offy = 77
    end
    InfoDialog.addInfoItems(bg, initx, inity, offy, rtitems)
    local infoY = 464
    if infoType==1 then
        temp = ui.label(StringManager.getString("labelUnlockWeapon"), General.font2, 32, {color={84,68,52}})
        display.adapt(temp, 695, 521, GConst.Anchor.Center)
        bg:addChild(temp)
    elseif infoType==2 then
        temp = ui.label(StringManager.getString("propertyRange"), General.font2, 35, {color={30,91,165},width=389,align=GConst.Align.Left})
        display.adapt(temp, 206, 422, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        local binfo = build.info
        local tempStr = tostring(binfo.maxRange/10)
        if binfo.minRange>0 then
            tempStr = tostring(binfo.minRange/10) .. "~" .. tempStr
        end
        temp = ui.label(tempStr .. StringManager.getString("unitRange"), General.font2, 30, {color={0,0,0},width=389,align=GConst.Align.Right})
        display.adapt(temp, 1191, 422, GConst.Anchor.RightBottom)
        bg:addChild(temp)
        temp = ui.label(StringManager.getString("propertyDType"), General.font2, 35, {color={30,91,165},width=389,align=GConst.Align.Left})
        display.adapt(temp, 206, 353, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        temp = ui.label(StringManager.getString("enumDType" .. binfo.dtype), General.font2, 30, {color={0,0,0},width=389,align=GConst.Align.Right})
        display.adapt(temp, 1191, 353, GConst.Anchor.RightBottom)
        bg:addChild(temp)
        temp = ui.label(StringManager.getString("propertyAUType"), General.font2, 35, {color={30,91,165},width=389,align=GConst.Align.Left})
        display.adapt(temp, 206, 287, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        temp = ui.label(StringManager.getString("enumAUType" .. binfo.autype), General.font2, 30, {color={0,0,0},width=389,align=GConst.Align.Right})
        display.adapt(temp, 1191, 287, GConst.Anchor.RightBottom)
        bg:addChild(temp)
        temp = ui.label(StringManager.getString("propertyFavorite"), General.font2, 35, {color={30,91,165},width=389,align=GConst.Align.Left})
        display.adapt(temp, 206, 219, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        if binfo.fav and binfo.fav>0 then
            if binfo.fav>10 then
                tempStr = StringManager.getString("dataSoldierName" .. binfo.fav)
            else
                tempStr = StringManager.getString("enumFType" .. binfo.fav)
            end
        else
            tempStr = StringManager.getString("wordAny")
        end
        temp = ui.label(tempStr, General.font2, 30, {color={0,0,0},width=389,align=GConst.Align.Right})
        display.adapt(temp, 1191, 219, GConst.Anchor.RightBottom)
        bg:addChild(temp)
        -- temp = ui.colorNode({994, 4},{144,146,127})
		temp=ui.sprite("images/dialogItemDarkLineX.png",{994, 3})
        display.adapt(temp, 204, 415, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        -- temp = ui.colorNode({994, 4},{144,146,127})
		temp=ui.sprite("images/dialogItemDarkLineX.png",{994, 3})
        display.adapt(temp, 204, 347, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        -- temp = ui.colorNode({994, 4},{144,146,127})
		temp=ui.sprite("images/dialogItemDarkLineX.png",{994, 3})
        display.adapt(temp, 204, 279, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        -- temp = ui.colorNode({994, 4},{144,146,127})
		temp=ui.sprite("images/dialogItemDarkLineX.png",{994, 3})
        display.adapt(temp, 204, 211, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        infoY = 206
    elseif infoType==3 then
        temp = ui.label(StringManager.getString("labelUnlockBuild"), General.font2, 32, {color={84,68,52}})
        display.adapt(temp, 695, 521, GConst.Anchor.Center)
        bg:addChild(temp)
        temp = ui.label(StringManager.getFormatString("textUpgradeTown",{level=newBuild.level}), General.font2, 30, {width=1230, color={84,68,52}})
        display.adapt(temp, 702, 301, GConst.Anchor.Top)
        bg:addChild(temp)
        local bbinfos = {}
        local allBuilds = SData.getData("binfos")
        for bdid, binfo in pairs(allBuilds) do
            local bbid = BU.getBidByDid(bdid)
            if bbid and binfo.btype~=4 and binfo.levels[newBuild.level]>binfo.levels[build.level] then
                table.insert(bbinfos, {bbid, binfo.levels[newBuild.level], binfo.levels[build.level]})
            end
        end
        table.sort(bbinfos, GMethod.getSortFunction(1))
        local tableView = ui.createTableView({1265,158}, true, {size=cc.size(162,154), offx=6, offy=3, disx=8, disy=0, rowmax=1, infos=bbinfos, cellUpdate=updateUnlockBuildCell})
        display.adapt(tableView.view, 60, 316, GConst.Anchor.LeftBottom)
        bg:addChild(tableView.view)
    end
    if itype>1 then
        temp = ui.button({361, 141}, nil, {cp1=build, image="images/btnGreen.png"})
        display.adapt(temp, 710, 133, GConst.Anchor.Center)
        bg:addChild(temp,1)

        --引导
        local context = GameLogic.getUserContext()
        if context.guide:getStep().type == "upgradeTown" then
            if build.bid == 1 then
                context.guideHand:showArrow(temp,180,100)
            end
        end
        local but = temp
        local context = GameLogic.getUserContext()
        local ctype, cvalue
        local nlv, clv, nbid
        if itype==2 then
            ctype = newBuild.data.ctype
            cvalue = newBuild.data.cvalue
            nlv = newBuild.data.needLevel
            nbid = const.Town
            clv = context.buildData:getMaxLevel(nbid)
            but:setScriptCallback(Script.createCallbackHandler(build.onBeginUpgrade, build, build.level))
            if build.bid == const.Town then       --主城判断玩家经营等级
                nlv = SData.getData("townLimit",build.level+1)
                clv = context:getInfoItem(const.InfoLevel)
            end
        else
            ctype = const.ResZhanhun
            cvalue = nextArmor.cvalue
            nlv = nextArmor.needLevel
            nbid = build.bid
            clv = build.level
            but:setScriptCallback(Script.createCallbackHandler(build.onBeginUpgradeArmor, build, build.armor or 0))
        end
        GameUI.addResourceIcon(but:getDrawNode(), ctype, 0.75, 288, 85)
        temp = ui.label(tostring(cvalue), General.font1, 48,{fontW=220,fontH=120})
        display.adapt(temp, 245, 87, GConst.Anchor.Right)
        but:getDrawNode():addChild(temp)
        if cvalue>context:getRes(ctype) then
            ui.setColor(temp, GConst.Color.Red)
        end
        if nlv>clv then
            temp = ui.scale9("images/bgWhiteGrid2.9.png",20,{1254, 129})
            ui.setColor(temp, {226, 63, 56})
            display.adapt(temp, 56, 75, GConst.Anchor.LeftBottom)
            bg:addChild(temp)
            temp = ui.sprite("images/dialogBack_3_repeat.png")
            ui.setColor(temp, {226, 63, 56})
            local texture = temp:getTexture()
            texture:setTexParameters(gl.NEAREST, gl.NEAREST, gl.REPEAT, gl.REPEAT)
            temp:setTextureRect(cc.rect(0, 0, 1254, 129))
            temp:setOpacity(25)
            display.adapt(temp, 56, 75, GConst.Anchor.LeftBottom)
            bg:addChild(temp)
            temp = ui.label(StringManager.getString("labelNotice"), General.font1, 40, {color=GConst.Color.White})
            display.adapt(temp, 1088, 204, GConst.Anchor.Center)
            bg:addChild(temp)
            if build.bid == const.Town then
                temp = ui.label(Localizef("stringToLvCanUpTown",{a = nlv}),General.font1,30,{color = GConst.Anchor.White, width=360,fontW=360,fontH=110})
            else
                temp = ui.label(StringManager.getFormatString("noticeNeedLevel2",{level=nlv, name=BU.getBuildName(nbid)}), General.font2, 30, {color=GConst.Anchor.White,width=360})
            end
            display.adapt(temp, 1102, 134, GConst.Anchor.Center)
            bg:addChild(temp)
            but:setGray(true)
        end
    else
        local binfo
        if build:isStatue() then
            if (build.bid == 186) or (build.bid == 187) then
                local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
                -- local kind = KnockMatchData:getStatueKind(build.bid)
                local kind = build.level
                local bdata = SData.getData("bdatas", bsetting.bdid, build.level)
                binfo = BU.getBuildInfo(build.bid,kind, {a = bdata.hpRate.."%"})
            else
                binfo = BU.getBuildInfo(build.bid, build.level)
            end
        else
            binfo = BU.getBuildInfo(build.bid)
        end
        if binfo then
            temp = ui.label(binfo, General.font2, 40, {width=1204, color={57,117,165}})
            display.adapt(temp, 690, infoY, GConst.Anchor.Top)
            bg:addChild(temp)
        end
    end
    display.showDialog(dialog)
end

local _iconSetting = {
    armor={image="images/dialogInfoIconArmor.png"},
    gold={image="images/dialogInfoIconGold.png",y=2},
    troop={image="images/dialogInfoIconTroopS.png",x=8,y=5},
    hp={image="images/dialogInfoIconHp.png",x=1,y=-1},
    range={image="images/dialogInfoIconRange.png",y=2},
    atk={image="images/dialogInfoIconDps.png",x=-2,y=3},
    gmax={image="images/dialogInfoIconGoldS.png",x=-5,y=-3},
    wmax={image="images/dialogInfoIconWeaponS.png"},
    gaEnery = {image="images/dialogIconRecoveryUplimit.png",scale=0.8,x=2},
    gaEnerySp = {image="images/gaEnerySp.png",scale=0.95},
}

function InfoDialog.addInfoItems(bg, initx, inity, offy, rtitems)
    local temp, tempStr
    for i,item in ipairs(rtitems) do
        temp = ui.sprite("images/proBack4.png",{676, 48})
        display.adapt(temp, initx, inity, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        local v = item.value
        if not v then
            log.e(json.encode(item))
        end
        local updateItem = nil
        if type(v)=="function" then
            v = v()
            updateItem = {item=item}
        end
        tempStr = tostring(v)
        if item.next and item.next>v then
            temp = ui.colorNode({668*item.next/item.max, 40},{222,255,115})
            display.adapt(temp, initx+4, inity+4, GConst.Anchor.LeftBottom)
            bg:addChild(temp)
            tempStr = tempStr .. "+" .. tostring(item.next-v)
        elseif v~=item.value then
            tempStr = tempStr .. "/" .. tostring(item.max)
        end
        temp = ui.sprite("images/proFillerGreen.png",{668*v/item.max, 40})
        display.adapt(temp, initx+4, inity+4, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        if updateItem then
            updateItem.process=temp
        end
        local iconSetting = _iconSetting[item.icon]
        temp = ui.sprite(iconSetting.image)
        temp:setScale(iconSetting.scale or 1)
        display.adapt(temp, initx-53+(iconSetting.x or 0), inity+27+(iconSetting.y or 0), GConst.Anchor.Center)
        bg:addChild(temp)
        temp = ui.label(StringManager.getFormatString(item.format,{num=tempStr}), General.font1, 30, {color={255,255,255}})
        display.adapt(temp, initx+16, inity+48, GConst.Anchor.Left)
        bg:addChild(temp)
        if updateItem then
            updateItem.label=temp
            updateItem.value = v
            RegTimeUpdate(temp, Handler(InfoDialog.updateInfoItem, updateItem), 0.2)
        end
        inity = inity-offy
    end
end

function InfoDialog.updateInfoItem(uitem)
    local item = uitem.item
    local v = item.value()
    if v~=uitem.value then
        local tempStr = tostring(v) .. "/" .. item.max
        -- uitem.label:setString(StringManager.getFormatString(item.format,{num=tempStr}))
        uitem.process:setScaleContentSize(668*v/item.max, 40, false)
        uitem.value = v
    end
end
