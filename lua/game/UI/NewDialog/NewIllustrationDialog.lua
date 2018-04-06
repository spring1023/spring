local SData = GMethod.loadScript("data.StaticData");
local const = GMethod.loadScript("game.GameLogic.Const");

local NewShowHeroDialog = GMethod.loadScript("game.Dialog.NewShowHeroDialog")

local pages = {Heros = 1,Equips = 2, Beasts = 3,Zombies = 4}
local heroType = {UR = 1, SSR = 2, SR = 3}

-- 图鉴界面
local IllustrationDialog = class(DialogViewLayout)

local function _sortHeroImages(a, b)
    local context = GameLogic.getUserContext()
    local aNum = context:getItem(const.ItemFragment, a[1])
    local bNum = context:getItem(const.ItemFragment, b[1])
    if aNum > 0 and aNum >= a[2].fragNum then
        a[2].order = 9
    end
    if bNum > 0 and bNum >= b[2].fragNum then
        b[2].order = 9
    end
    local _orderA = (a[2].order or 0) * 100000 + (a[2].displayColor or a[2].color) * 10000 + a[2].rating * 1000
    local _orderB = (b[2].order or 0) * 100000 + (b[2].displayColor or b[2].color) * 10000 + b[2].rating * 1000
    if _orderA ~= _orderB then
        return _orderA > _orderB
    elseif a[2].fragNum~=b[2].fragNum then
        return a[2].fragNum>b[2].fragNum
    else
        return a[1]>b[1]
    end
end

local function _sortHeroImages2(a, b)
    local aNum = GameLogic.getUserContext():getItem(const.ItemEquipFrag, a.eid)
    local bNum = GameLogic.getUserContext():getItem(const.ItemEquipFrag, b.eid)
    local aOrder = a[2].order
    local bOrder = b[2].order
    if aNum > 0 and aNum >= a[2].fragNum then
        aOrder = a[2].order/10
    end
    if bNum > 0 and bNum >= b[2].fragNum then
        bOrder = b[2].order/10
    end
    return aOrder < bOrder
end

function IllustrationDialog:ctor(params)
    self.priority=display.getDialogPri()+1
    self:initData()
    self:initUI()
    display.showDialog(self)
end

function IllustrationDialog:onCreate()
    self:setLayout("illustration_dialog.json")
    self:loadViewsTo()
end

function IllustrationDialog:initData( ... )
    self.context = GameLogic.getUserContext()
    self.hinfos = SData.getData("hinfos")
    self.tagInfos = {}
    self:initHerosData()
    self:initEquipsData()
    self:initBeastsData()
    self:initZombiesData()
end

function IllustrationDialog:initHerosData( ... )
    local context = self.context
    local hinfos = self.hinfos
    local myHeros = context.heroData:getAllHeros()
    
    self.allHeros = {{},{},{}}
    for hid, hinfo in pairs(hinfos) do
        if hid<=6000 then
            if hid%1000==0 then
            else
                local otherInfo = SData.getData("heroInfoNew",hid)

                local isGet = false
                for i,v in ipairs(myHeros) do
                    if v.hid == hid then
                        isGet = true
                        break
                    end
                end

                -- 区分条件--------------------------------------------------------------------
                if hinfo.color <= 3 then                         --N英雄,这个现在应该对应SR了吧
                    table.insert(self.allHeros[heroType.SR], {hid,hinfo,otherInfo,isGet})
                elseif hinfo.displayColor and hinfo.displayColor == 5 then              --UR英雄
                    table.insert(self.allHeros[heroType.UR], {hid,hinfo,otherInfo,isGet})
                else                                             --R\SR\SSR英雄，这个应该就是SSR
                    table.insert(self.allHeros[heroType.SSR], {hid,hinfo,otherInfo,isGet})
                end
            end
        end
    end
    for i, hids in ipairs(self.allHeros) do
        table.sort(hids, _sortHeroImages)
    end
    table.insert(self.tagInfos,self.allHeros)
end

function IllustrationDialog:initEquipsData()
    local context = self.context
    local myEquips = self.context.equipData:getAllEquips()
    -- dump(myEquips,"myEquips")
    
    local edata = self.context.equipData
    self.allEquips = {}
    for eid=2001,2009 do
        if eid~=2004 then
            local equip = edata:makeEquip(eid)
            local otherInfo = SData.getData("equipInfoNew", eid)
            local mfrag = SData.getData("elevels",eid,1).mfrag
            local isGet = false
            for i,v in ipairs(myEquips) do                
                if v.eid == eid then
                    isGet = true
                    break
                end
            end
            equip.order = otherInfo.order
            equip.fragNum = mfrag
            table.insert(self.allEquips, {eid, equip, otherInfo, isGet})
        end
    end
    table.sort(self.allEquips, _sortHeroImages2)
    table.insert(self.tagInfos,self.allEquips)
    -- dump(self.allEquips,"=================initEquipsData=======================")
end

function IllustrationDialog:initBeastsData()
    local context = self.context
    self.allBeasts = {}
    local myHeros = context.heroData:getAllHeros()
    local hinfos = self.hinfos

    for i=1,10 do
        for bid,hinfo in pairs(hinfos) do
            if bid == i*10 + 8000 then
                -- 表里没有神兽信息
                local otherInfo = SData.getData("heroInfoNew",bid)
                local isGet = true
                -- for i,v in ipairs(myHeros) do
                --     if v.hid == bid then
                --         isGet = true
                --         break
                --     end
                -- end
                table.insert(self.allBeasts,{bid,hinfo,otherInfo,isGet})
            end
        end
    end
    table.insert(self.tagInfos,self.allBeasts)
end

function IllustrationDialog:initZombiesData()
    local context = self.context
    local hinfos = self.hinfos
    self.allZombies = {}
    for zid,hinfo in pairs(hinfos) do
            if zid >= 9000 then
                -- 表里没有僵尸信息
                local otherInfo = SData.getData("heroInfoNew",zid)
                -- dump(otherInfo,"otherInfo")
                local isGet = true
                -- for i,v in ipairs(myHeros) do
                --     if v.hid == bid then
                --         isGet = true
                --         break
                --     end
                -- end
                table.insert(self.allZombies,{zid,hinfo,otherInfo,isGet})
            end
        end

    table.insert(self.tagInfos,self.allZombies)
    -- dump(self.allZombies,"Zombies")
end


function IllustrationDialog:initUI()
    self.btn_close:setScriptCallback(ButtonHandler(display.closeDialog,self.priority))
    
    -- 图鉴标题
    self.lb_title:setString(Localize("btnHeroImage"))
    local btnTags = {"wordHero","tabEquip","wordLBoss","僵尸"}
    for i=1,4 do
        self["img_tabLight"..i]:setVisible(false)
        -- 按钮标签
        self["lb_itemInfo"..i]:setString(Localize(btnTags[i]))
        self["tab"..i]:setScriptCallback(ButtonHandler(self.selectPage,self,i))
    end 
    self:selectPage(pages.Heros)
end

function IllustrationDialog:selectPage(idx)
    if self.idx == idx then
        return
    end
        
    if self.selCell then
        self.selCell = nil
    end

    if not self.idx then
        self.idx = idx
        self["img_tabLight"..idx]:setVisible(true)
        self:refreshDownScroll()
    else
        self["img_tabLight"..self.idx]:setVisible(false) 
        self["img_tabLight"..idx]:setVisible(true)
        self.idx = idx 
        -- 英雄默认全部显示
        if idx == pages.Heros then
            self:refreshDownScroll()
        else
            self:refreshDownScroll(self.tagInfos[idx])
        end
    end

    self.choose:setVisible(idx == pages.Heros)
    self.left_hero:setVisible(idx == pages.Heros)


    for i=1,3 do
        self["img_confirm"..i]:setVisible(false)
        local btn_confirm = self["btn_confirm"..i]
        local heroInfos = self.allHeros[i]
        btn_confirm:setScriptCallback(ButtonHandler(function ( ... )
            -- 每次切换英雄先默认选中第一个,以前选中的要取消掉
            if self.selCell then
                self.selCell = nil
            end
            if not self.confirmId then
                self.confirmId = i
                self["img_confirm"..i]:setVisible(true)
                self:refreshDownScroll(heroInfos)
            else
                self["img_confirm"..self.confirmId]:setVisible(false)
                if i ~= self.confirmId then
                    self["img_confirm"..i]:setVisible(true)
                    self.confirmId = i
                    self:refreshDownScroll(heroInfos)
                else
                    self:refreshDownScroll()
                    self.confirmId = nil
                end
            end
        end))
    end
end

function IllustrationDialog:refreshDownScroll( infos)
    -- dump(infos,"==================refreshDownScroll======================")
    self.scroll1:setVisible(self.idx == pages.Heros)
    self.scroll2:setVisible(self.idx ~= pages.Heros)
   
    local scroll = self.idx == pages.Heros and self.scroll_list1 or self.scroll_list2
    scroll:clearAll()
    if not infos then
        local allHeros = self.allHeros
        local ainfos = {}
        for _,vv in ipairs(allHeros) do
            for _,v in ipairs(vv) do
                table.insert(ainfos,v)
            end
        end
        scroll.view:setScriptHandler(Script.createCObjectHandler(scroll))
        scroll:setDatas({datas = ainfos,cellUpdate = self.updateCell,target = self})
        for _,v in ipairs(ainfos) do
            local cell = scroll:createItem(1)
            scroll:addCell(cell)              
        end  
        self:selectCell(scroll.children[1],ainfos[1])      
    else
        scroll.view:setScriptHandler(Script.createCObjectHandler(scroll))
        scroll:setDatas({datas = infos,cellUpdate = self.updateCell,target = self})
        for _,v in ipairs(infos) do
            local cell = scroll:createItem(1)
            scroll:addCell(cell)
        end
        self:selectCell(scroll.children[1],infos[1])
    end  
end

function IllustrationDialog:updateCell(cell,scroll,info)
    -- dump(info,"=============updateCellinfo==========================")
    local size = cell.img_heroHead:getContentSize()
    local head 
    if self.idx == pages.Equips then
        head = GameUI.addEquipIcon(cell.img_heroHead,info[1],0.8,size[1]/2,size[2]/2)
    else
        head = GameUI.addHeroHead(cell.img_heroHead,info[1],{size = size,x = 0,y = 0})
    end
    head:setSValue(info[4] and 0 or -100)
    cell.btn_head:setScriptCallback(ButtonHandler(function ( ... )
       self:selectCell(cell,info)
    end))
end

function IllustrationDialog:selectCell(cell,info)
    if not self.selCell then
        self.selCell = cell
    else
        local selCell = self.selCell
        selCell.img_itemFrame_choose:setVisible(false)
    end
    cell.img_itemFrame_choose:setVisible(true)
    self.selCell = cell
    self:refreshCenter(info)
end

function IllustrationDialog:refreshCenter( info )
    local idx = self.idx
    self.left_hero:setVisible(idx == pages.Heros)
    self.hero:setVisible(idx == pages.Heros)
    self.equip:setVisible(idx == pages.Equips)
    self.heroAndEquip:setVisible(idx == pages.Heros or idx == pages.Equips)
    self.zbAndBeast:setVisible(idx == pages.Beasts or idx == pages.Zombies)

    self:refreshCenterUI(info)

    if idx == pages.Heros then
        self:refreshHeroUI(info)
    elseif idx == pages.Equips then
        self:refreshEquipUI(info)
    else
        self:refreshBeastAndZombieUI(info)
    end
end

function IllustrationDialog:refreshCenterUI( info )
    local context = self.context
    local idx = self.idx
    local heroName = {"dataHeroName"..info[1],"dataEquipName"..info[1],"dataHeroName"..info[1]}
    self.lb_heroName:setString(Localize(heroName[idx]))

    -- 左侧图片
    local feature = 1
    local size = self.img_Feature:getContentSize()
    self.img_Feature:removeAllChildren()
    if idx == pages.Equips then
        feature =  GameUI.addEquipFeature(self.img_Feature, info[1], 1, size[1]/2, size[2]/2)
    else
        feature = GameUI.addHeroFeature(self.img_Feature,info[1],1.1,size[1]/2,0,0)
    end

    -- 英雄职位
    -- self.img_job:removeAllChildren()
    -- size = self.img_job:getContentSize()
    -- GameUI.addHeroJobIcon(self.img_job.view, info[2].job, 1, size[1]/2-20, size[2]/2-20)

    -- 佣兵头像
    -- local size = self.shead:getContentSize()
    -- self.shead:removeAllChildren()
    -- GameUI.addHeadIcon(self.shead.view, info[2].sid, 0.5, size[1]/2, size[2]/2)

    -- 背景故事，公共部分
    self.lb_storyTitle:setString(Localize("故事背景"))
    self.lb_story:setString(Localize(info[3].bgStory))

    -- self.lb_infoTitle:setVisible(false)
    -- self.lb_frap:setVisible(false)
    -- print("self.idx",self.idx)

    if self.idx == pages.Heros or self.idx == pages.Equips then
        -- self.lb_infoTitle:setVisible(true)
        -- self.lb_frap:setVisible(true)
        -- 信息标题
        self.lb_infoTitle:setString(Localize("信息"))
        self.lb_frap:setString(Localize("碎片数量"))

        -- 碎片数量
        local cnum = {context:getItem(const.ItemFragment, info[1]),context:getItem(const.ItemEquipFrag, info[1])}
        self.lb_frapNum:setString(cnum[idx].."/"..info[2].fragNum)

        -- 合成碎片
        self.btn_collect:setGray(cnum[idx] < info[2].fragNum)
        self.btn_collect:setEnable(cnum[idx] >= info[2].fragNum)

        local function mergeFrag()
            if idx == pages.Heros then
                self:mergeHeroFrag(info)
            else
                self:mergeEquipFrag(info)
            end  
        end

        self.btn_collect:setScriptCallback(ButtonHandler(mergeFrag))

        -- 获得途径
        self.lb_getWay:setString(Localize("labelAccessTo")..":"..Localize(info[3].getWay))
        -- self.btn_go:setScriptCallback(ButtonHandler())
    end
end

function IllustrationDialog:refreshHeroUI(info)
    self.img_job:removeAllChildren()
    local size = self.img_job:getContentSize()
    GameUI.addHeroJobIcon(self.img_job.view, info[2].job, 1, size[1]/2, size[2]/2)

    local quality = info[2].displayColor or info[2].color
    --英雄品质
    self.img_imageQuality3:setImage("icon/icon_imageQuality"..quality..".png")
    
    -- 佣兵头像
    local size = self.shead:getContentSize()
    self.shead:removeAllChildren()
    GameUI.addHeadIcon(self.shead.view, info[2].sid, 0.5, size[1]/2, size[2]/2)

    -- self.lb_storyTitle:setString(Localize("故事背景"))
    -- self.lb_story:setString(Localize(info[3].bgStory))
    -- 技能标题
    self.lb_skillTitle:setString(Localize("技能介绍"))
    -- self.lb_infoTitle:setString(Localize("信息"))
    -- self.lb_frap:setString(Localize("碎片数量"))

    local hero = self.context.heroData:makeHero(info[1])
    -- dump(hero,"hero")
    
    GameUI.addSkillIcon(self.img_skillIcon1, 1, info[2].mid, 0.81, 130, 87)
    -- GameUI.addSkillIcon(self.img_skillIcon2, 5, info[2].hsid, 0.81, 130, 87)


    -- 主动技能
    local skillInfos = {{name = "btnMainSkill",des = hero:getSkillName().."\n"..hero:getSkillDesc(1)}}

    -- 天神技
    if info[3].isAwake == 1 then
        local godsSkill = hero:getAwakeSkill(5)
        skillInfos[2] = {neme = "btnGodsSkill",des = awakeInfo5.name.."\n"..awakeInfo5.info}
    end

    self.btn_skill2:setVisible(info[3].isAwake == 1)
    self.btn_skill1:setAutoHoldTime(0.3)
    self.btn_skill2:setAutoHoldTime(0.3)
    self.btn_skill1:setControlScriptCallback(ButtonHandler(self.isHoldTips,self,{skillInfos[1],1}))
    self.btn_skill2:setControlScriptCallback(ButtonHandler(self.isHoldTips,self,{skillInfos[2],2}))


    local function tryPlay()
        local gk=info[3].guankaId
        GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=2,ptype=true,idx=gk,bparams={stage = const.HeroInfoNewTry,id = info[1]}})
    end
    -- 试玩
    self.btn_tryPlay:setScriptCallback(ButtonHandler(tryPlay))
end



function IllustrationDialog:refreshEquipUI( info )
    -- 属性
    local data = SData.getData("elevels",info[1],215).effect
    local layout = self.layout_equip
    layout:removeAllChildren()
    for i=1,6 do
        local cell = layout:createItem(1)
        cell:loadViewsTo()
        layout:addChild(cell)
        -- cell.img_property:setImage("")
        cell.lb_property1:setString(Localizef("dataItemEffect"..i,{value=data[i]}))
        cell.lb_propertyNum:setString(Localize(data[i]))
    end
end

function IllustrationDialog:refreshBeastAndZombieUI( info )
    -- self.lb_storyTitle:setString(Localize("labelInfoBgStory"))
    -- self.lb_story:setString(Localize(info[3].bgStory))

    -- 神兽僵尸的技能
    --技能1
    GameUI.addSkillIcon(self.img_skillIcon1, 1, info[1]+100, 0.81, 130, 87)
    self.lb_bzskillTitle:setString(Localize("btnMainSkill"))

    local hero = self.context.heroData:makeHero(info[1])

    self.lb_bzSkillDes1:setString(hero:getSkillName().."\n"..hero:getSkillDesc(1))

    -- self.lb_bzSkillName1:setString("lb_bzSkillName1")
    -- self.lb_bzSkillDes1:setString("lb_bzSkillDes1")

    -- 技能2
    -- GameUI.addSkillIcon(self.img_skillIcon2, 1, info[1]+100, 0.81, 130, 87)
    -- self.lb_bzSkillName2:setString("lb_bzSkillName2")
    -- self.lb_bzSkillDes2:setString("lb_bzSkillDes2")
end

function IllustrationDialog:mergeHeroFrag( info )
    local hid = info[1]
    local hinfo = info[2]
    local context = self.context
    local heroData = context.heroData
    if heroData:getHeroNum()>=heroData:getHeroMax() then
        display.pushNotice(Localize("noticeHeroPlaceFull"))
        return
    end
    if hinfo.fragNum>0 and hinfo.fragNum<=context:getItem(const.ItemFragment, hid) then
        local rate = hinfo.displayColor and hinfo.displayColor >=5 and 5 or hinfo.rating
        context.heroData:mergeHero(hid,rate)
        display.pushNotice(Localizef("noticeGetItem",{name=GameLogic.getItemName(const.ItemHero, hid)}))
        local cnum = context:getItem(const.ItemFragment, hid)
        local mnum = hinfo.fragNum
        if cnum>=mnum then
            self.lb_frapNum:setColor(GConst.Color.Green)
            self.btn_collect:setVisible(true)
        else
            self.lb_frapNum:setColor(GConst.Color.White)
            self.btn_collect:setVisible(false)
        end
        self.lb_frapNum:setString(cnum .. "/" .. mnum)
        local _hero = context.heroData:makeHero(hid)
        NewShowHeroDialog.new({rhero=_hero,shareIdx = _hero.info.rating})
        self:initHerosData()
        if self.confirmId then
            self:refreshDownScroll(self.allHeros[self.confirmId])
        else
            self:refreshDownScroll()
        end
    end
end

function IllustrationDialog:mergeEquipFrag(info)
    local eid = info[1]
    local context = self.context
    local equipData = context.equipData
    local equip = equipData:makeEquip(eid)
    local _,_fNum = equip:getFragNum()

    if equipData:getEquipNum()>=equipData:getEquipMax() then
        display.pushNotice(Localize("noticeEquipPlaceFull"))
        return
    end

    if _fNum<=context:getItem(const.ItemEquipFrag, eid) then
        context.equipData:mergeEquip(eid)
        display.pushNotice(Localizef("noticeGetItem",{name=GameLogic.getItemName(const.ItemEquip, eid)}))
        local cnum = context:getItem(const.ItemEquipFrag, eid)
        local mnum = _fNum --const.EquipFragMerge
        if cnum>=mnum then
            self.lb_frapNum:setColor(GConst.Color.Green)
            self.btn_collect:setVisible(true)
        else
            self.lb_frapNum:setColor(GConst.Color.White)
            self.btn_collect:setVisible(false)
        end
        self.lb_frapNum:setString(cnum .. "/" .. mnum)
        self:initEquipsData()
        self:refreshDownScroll(self.allEquips)
    end
end

function IllustrationDialog:isHoldTips(params,btn,nEventType)
    if nEventType == 5 or nEventType == 1 then
        self:skillTips(params,true)
    elseif nEventType == 2 or nEventType == 4 or nEventType == 3 then
        self:skillTips(params,false)
    end
end


function IllustrationDialog:skillTips( params ,flag)
    self.tips:setVisible(flag)

    self.img_tip1:setVisible(params[2] == 1)
    self.img_tip2:setVisible(params[2] == 2)
   
    self.lb_skillName:setString(Localize(params[1].name))
    self.lb_skillDes:setString(Localize(params[1].des))
end

return IllustrationDialog;
