local SData = GMethod.loadScript("data.StaticData")
local ShowHeroMainDialog = {RESULT_NORMAL=0, RESULT_ERROR=-1}
local HValue = {110,-130,0,50}
local colors = {{35,202,248},{188,14,189},{201,131,14},{201,131,14}}
function ShowHeroMainDialog.HotHero(bg,x,y,i)
    local size,nx,ny
    if i == 3 then
        size,nx,ny={670,1064},337,339
    elseif i == 4 then
        size,nx,ny={670,1064},337,339
    else
        size,nx,ny={586,970},284,305
    end
    local tbg = ui.shlNode(size)
    display.adapt(tbg, x, y, GConst.Anchor.Center)
    bg:addChild(tbg)
    local sprite,labelPic
    if i==4 then
        sprite="images/chouka3.png"
        labelPic="images/choukaname3.png"
    else
        sprite="images/chouka"..i..".png"
        labelPic="images/choukaname"..i..".png"
    end
    local temp = ui.sprite(sprite, size)
    display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
    tbg:addChild(temp)
    local choukaname = ui.sprite(labelPic)
    display.adapt(choukaname, nx,ny+530, GConst.Anchor.Center)
    tbg:addChild(choukaname,1)

    local temptitle = ui.label(Localize("temptitle"..i), General.font1, 48,{color=colors[i]})
    display.adapt(temptitle, nx,ny+530, GConst.Anchor.Center)
    tbg:addChild(temptitle,1)
    if i==3 then
        -- 获取所有热点英雄
        local _weekId, _dayIds = GameLogic.getUserContext():getHotItems()
        --print(_weekId, dump(_dayIds))
        local info = SData.getData("popunlock", _weekId)

        if info.unLockType == const.ItemHero then
            local hero = GameLogic.getUserContext().heroData:makeHero(info.unLockId)
            GameUI.addHeroFeature(tbg, info.unLockId, 0.7, 335, 593, 0, true)
            GameUI.addSSR(tbg, hero.info.displayColor and hero.info.displayColor >= 5 and 5 or hero.info.rating,0.5,262,369,3 )
        else
            local _etemp = GameUI.addEquipFeature(tbg, info.unLockId, 0.7, 335, 593)
            if info.unLockId==2005 then
                UIeffectsManage:showEffect_busizhixin(_etemp,300,300)
            elseif info.unLockId==2006  then
                UIeffectsManage:showEffect_zhanzhengwange(_etemp,300,300)
            elseif info.unLockId==2007 then
                UIeffectsManage:showEffect_kuangbao(_etemp,390,370,0,1.3)
            end
        end

        --日热点英雄
        for j=1,3 do
            local dayHerobg = ui.scale9("images/bgWhite.9.png",20,{110,110})
            ui.setColor(dayHerobg, {46,107,137})
            display.adapt(dayHerobg, 35+150*j, 190, GConst.Anchor.Center)
            tbg:addChild(dayHerobg)
            info = SData.getData("popunlock", _dayIds[j])
            if info.unLockType == const.ItemHero then
                GameUI.addHeadIcon(tbg, info.unLockId, 0.45,35+150*j,190,0)
            else
                GameUI.addEquipIcon(tbg, info.unLockId, 0.45,35+150*j,190,0)
            end
        end
    elseif i == 4 then
        local heroLib = ui.button({245,99}, function()
            --金币英雄库
            HeroLibraryInfo.new(3)
        end, {image="images/btnGreen.png"})
        display.adapt(heroLib, 335, 215, GConst.Anchor.Center)
        tbg:addChild(heroLib)
        heroLib:setHValue(-57)
        heroLib:setSValue(34)
        
        GameUI.addHeroFeature(tbg, 4014, 0.6, 335, 573, 0, true)
        local tempHero = ui.label(Localize("heroLibrary"), General.font1, 36)
        display.adapt(tempHero, 122, 55, GConst.Anchor.Center)
        heroLib:getDrawNode():addChild(tempHero)
    else
        local heroLib = ui.button({245,99}, function()
            --英雄库
            HeroLibraryInfo.new(i)
        end, {image="images/btnGreen.png"})
        display.adapt(heroLib, 293, 165, GConst.Anchor.Center)
        tbg:addChild(heroLib)
        heroLib:setHValue(HValue[i])

        local tempHero = ui.label(Localize("heroLibrary"), General.font1, 36)
        display.adapt(tempHero, 122, 55, GConst.Anchor.Center)
        heroLib:getDrawNode():addChild(tempHero)
    end
    return tbg
end

-- @brief 检查是否可以进行该次抽奖，含抽奖券、资源是否充足、背包空位是否足够
-- @params rtype 1-4 代表 免费单抽、付费单抽、十连抽、魂匣
-- @params inExtract 是否在HeroExtractNewTab界面
-- @return RESULT_ERROR\RESULT_NORMAL\const.TicketOne\const.TicketTen
function ShowHeroMainDialog.checkExtractMethod(rtype, inExtractTab)
    local context = GameLogic.getUserContext()
    local ret = ShowHeroMainDialog.RESULT_ERROR
    if ShowHeroMainDialog.inAnimate then
        return ret
    end
    local hlsetting = SData.getData("hlsetting", rtype)
    if rtype == 2 and context:getItem(const.ItemTicket, const.TicketOne) > 0 then
        ret = const.TicketOne
    elseif rtype == 3 and context:getItem(const.ItemTicket, const.TicketTen) > 0 then
        ret = const.TicketTen
    else
        --判断钻石是否足够
        local ctype, cvalue = const.ResCrystal, hlsetting.cvalue
        --有折扣
        if rtype==3 and GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffWishDiscount)[4]~=0 then
            cvalue=cvalue*GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffWishDiscount)[4]
        end
        
        -- 是魂匣抽取且在抽奖池界面可以不做钻石判断
        if inExtractTab and rtype == 4 then
            cvalue = 0
        end
        -- 金币单抽也先不做判断
        if inExtractTab and (rtype == 6 or rtype == 7) then
            cvalue = 0
        elseif rtype == 6 or rtype == 7 then
            ctype, cvalue = const.ResGold, math.floor(hlsetting.cvalue*context:getResMax(const.ResGold)/100)
        end
        --对金币抽许愿池做个次数的检测
        local chance
        if GameLogic.useTalentMatch then chance=GameLogic:getGoldExtractChance() end
        if rtype == 6 or rtype == 7 then
            if (const.GoldExtractLimit-chance)>=10 then
                    
            elseif  (const.GoldExtractLimit-chance)<10 and (const.GoldExtractLimit-chance)>0 then
                if rtype == 7 then
                    return ret
                end
            else
                return ret
            end
        end
        if context:getRes(ctype) < cvalue then
            display.showDialog(AlertDialog.new({ctype=ctype, cvalue=cvalue}))
            return ret
        else
            ret = ShowHeroMainDialog.RESULT_NORMAL
        end
    end
    -- 判断仓库位置是否足够
    if context.heroData:getHeroNum()+hlsetting.num>context.heroData:getHeroMax() then
        display.pushNotice(StringManager.getString("noticeHeroPlaceFull"))
        return ShowHeroMainDialog.RESULT_ERROR
    end
    return ret
end

-- @brief 进行一次类型为rtype的抽奖
-- @params rtype 1-4 代表 免费单抽、付费单抽、十连抽、魂匣 5-6 代表金币单抽和十连
-- @params btn 需要变灰的按钮
-- @params dialog 需要抽奖完成后回调的对话框
function ShowHeroMainDialog.onExtractMethod(rtype, btn, dialog)
    local cstate = ShowHeroMainDialog.checkExtractMethod(rtype)
    if cstate == ShowHeroMainDialog.RESULT_ERROR then
        return
    end
    if GameNetwork.lockRequest() then
        for i=1,#btn do
            btn[i]:setGray(true)
        end
        ShowHeroMainDialog.inAnimate = true
        GameLogic.dumpCmds(true)
        GameNetwork.request("extract", {rtype=rtype, isHaveItem=true, ticket = cstate}, ShowHeroMainDialog.onExtractMethodOver, {rtype,dialog})
    end
end

function ShowHeroMainDialog.onExtractMethodOver(settings, suc, data)
    local rtype=settings[1]
    local dialog=settings[2]
    data.rtype=rtype
    GameNetwork.unlockRequest()
    if suc then
        local context = GameLogic.getUserContext()
        if data.ftime then
            --刷新下次免费的时间
            context:setProperty(const.ProFreeTime, data.ftime)
        end
        local heros = data.heros
        -- 日常任务许愿池
        local times = #heros
        if times == 6 then
            local vip = context:getInfoItem(const.InfoVIPlv)
            local crystal = context:getProperty(const.ResCrystal)
            -- 获取所有热点英雄
            local _weekId, _dayIds = context:getHotItems()
            local info = SData.getData("popunlock", _weekId)
            GameLogic.addStatLog(11205, vip, info.unLockId, crystal)
        end
        if data.cost and data.cost > 0 then
            if rtype==6 or rtype==7 then
                --扣金币的
                context:changeRes(const.ResGold,-data.cost)
                GameLogic.statCrystalCost("抽取英雄消耗金币",const.ResGold, -data.cost)
            else
                --扣钻石的
                context:changeRes(const.ResCrystal, -data.cost)
                GameLogic.statCrystalCost("抽取英雄消耗",const.ResCrystal, -data.cost)
            end
        end
        if data.ticket and data.ticket > 0 then
            context:changeItem(const.ItemTicket, data.ticket, -1)
        end
        if data.special>0 then
            if rtype==6 or rtype==7 then
                --金币抽增加经验碎片的数量
                GameLogic.addRewards{{16,2,data.special}}
            else
            --增加黑晶的数量
                context:changeRes(const.ResSpecial, data.special)
                dialog.getSpecial = data.special
            end
        end
        if data.chance then
            context:setProperty(const.ProGoldExtractChance, data.chance)
        end
        if data.ctime then
            context:setProperty(const.ProGoldExtractTimes, data.ctime)
        end
        --增加幸运值
        context:changeProperty(const.ProLuck, data.luck)
        if times == 6 then
            context.activeData:finishActCondition(const.ActTypeHunXia,1)
        end
        context.activeData:finishActCondition(const.ActTypeWishGet,times)

        --增加抽取碎片
        for _, hero in ipairs(heros) do
            --物品
            if hero[3] then
                GameLogic.addRewards({hero})
            else
                context.heroData:addNewHero(hero[1], hero[2])
            end
        end
        context.heroData:checkHeroNum()
        dialog:onExtractMethodOverBack(data)
        GameEvent.sendEvent("refreshHeroAwakeEnsureDialog")
    end
end
return ShowHeroMainDialog
