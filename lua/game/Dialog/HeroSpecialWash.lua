-- 特殊洗练
HeroSpecialWash = class(DialogViewLayout)

local SData = GMethod.loadScript("data.StaticData")

function HeroSpecialWash:onInitDialog()
    self.heroMsg = self.hero
    self.bskillIdx = self.bskill
    self.curIdx = self.idx
    self.isparent = self.parent

    self:setLayout("HeroSpecialWash.json")
    self:loadViewsTo()
    self.context = GameLogic.getUserContext()
    self.title:setString(Localize("btnSpecailSop"))
    self.questionTag = Localize("labelSpeicalHelp")
    self:initData()
    self:initUI()
    self:updateRightUI()
    self:updateChangeBut()
    self:updateLeftUI()
end
function HeroSpecialWash:initData()
    -- body
    local _data = SData.getData("property",const.ItemWashsStone)
    self.data = {}
    for k,v in ipairs(_data) do
        table.insert(self.data,{id=v.value,pid=v.pid})
    end
end

function HeroSpecialWash:initUI()
    -- body
    self.labelWashTab:setString(Localize("labelSelectedBSkill"))
    self.labelCurTab:setString(Localize("labelCurrentBSkill"))
end
function HeroSpecialWash:updateLeftUI()
    self.btnWashs = {}
    self.imageWasha ={}
    local temp,but,filename,text
    for i=1,10 do
        self.btnWashs[i] = self["node" .. i]
        local _image
        temp = ui.button(self.btnWashs[i].size, self.washBtnCallback, {cp1=self, cp2=i,image = "images/heroWashItemBack.png"})
        display.adapt(temp, self.btnWashs[i].size[1]/2, self.btnWashs[i].size[2]/2, GConst.Anchor.Center)
        self.btnWashs[i]:addChild(temp)
        but = temp:getDrawNode()
        _image = GameUI.addItemIcon(but, const.ItemWashsStone, i, self.btnWashs[i].size[1]/230, self.btnWashs[i].size[1]/2, self.btnWashs[i].size[2]/2, false, false)
        -- filename = "images/items/itemIcon20_"..i..".png"
        -- temp = ui.sprite(filename,{125,125})
        -- display.adapt(temp, 50, 50, GConst.Anchor.LeftBottom)
        -- but:addChild(temp)
        -- _image = temp
        text = GameLogic.getUserContext():getItem(const.ItemWashsStone,i) or 0
        temp = ui.label(N2S(text),General.font1,50,{color={255,255,255},align = GConst.Align.Right})
        display.adapt(temp, 120, 0, GConst.Anchor.LeftBottom)
        but:addChild(temp)
        table.insert(self.imageWasha,{id = i,image = _image,label=temp})
    end
    self:refreshUI()
end

function HeroSpecialWash:checkStoneNumRefreshImage()
    local num
    for k,v in ipairs(self.imageWasha) do
        num  = GameLogic.getUserContext():getItem(const.ItemWashsStone,k) or 0
        v.label:setString(num)
        if num<=0 then
            v.image:setSValue(-100)
        end
        self.data[k].curNum = num
    end
end

function HeroSpecialWash:refreshUI()
    self:checkStoneNumRefreshImage()
    self:washBtnCallback(self.curIdx,1)
    self:washBtnCallback(self.curIdx,2)
end

function HeroSpecialWash:updateRightUI()
    self.banners = {}
    self.banners[1] = {name = self.labelCurName,info=self.labelCurInfo,num=self.labelCurBNum,icon = self.curIcon}
    self.banners[2] = {name = self.labelWashName,info=self.labelWashInfo,num=self.labelWashNum,icon = self.hIcon}
end

function HeroSpecialWash:updateChangeBut()
    self.btnLabel:setString(Localize("btnUseItem"))
    self.btnOk:setScriptCallback(ButtonHandler(self.onChangeBSkill,self))
end


function HeroSpecialWash:onChangeBSkill(force)
    if self.inRequest then
        return
    end
    local selectIdx = self.selectIdx
    local hero = self.heroMsg
    if not force then
        display.showDialog(AlertDialog.new(3, Localize("alertTitleNormal"), Localize("alertTextChangeBSkill"), {callback=Handler(self.onChangeBSkill, self, true)}))
        return
    end
    if GameNetwork.lockRequest() then
        self.inRequest = true
        GameLogic.dumpCmds(true)
        GameNetwork.request("blight", {hidx=self.heroMsg.idx, bidx=self.bskillIdx,sid = selectIdx}, self.onBSkillLightOver, self)
    end
end

function HeroSpecialWash:onBSkillLightOver(suc, data)
    GameNetwork.unlockRequest()
    self.inRequest = nil
    if suc then
        local context = self.context
        self.curIdx = self.selectIdx
        local id = self.data[self.curIdx].id
        local lv = self.heroMsg:getTalentSkillMax(id)
        context:changeItem(const.ItemWashsStone,self.curIdx,-1)
        self.context.heroData:changeSpecailHeroBSKill(self.heroMsg, self.bskillIdx, id,lv)
        self.changed = true
        -- 洗练被动技能战斗力
        self.context.heroData:setCombatData(self.heroMsg)
        -- 日常任务被动技能
        GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeHeroPassive,1)
        self:refreshUI()
        GameEvent.sendEvent("refreshBSkillUI")
    end
end

function HeroSpecialWash:washBtnCallback(idx,tap)
    -- body
    self.selectIdx = idx
    local num = tap or 2
    local hero = self.heroMsg
    local itemSetting = self.data[idx]
    local bskill
    if tap==1 then
        bskill = hero.bskills[self.bskillIdx]
        self.bskill = bskill
    else
        bskill = itemSetting
    end

    self:reloadBanner(hero, self.banners[num], bskill,num)
    if not self.selectImage then
        self.selectImage = ui.sprite("images/heroBSkillSelect.png",{370, 370})
        self.view:addChild(self.selectImage, 2)
    end
    if self:contrastBSkill(self.bskill,bskill) or (itemSetting.curNum==0) then
        self.selectImage:setVisible(false)
        self.btnOk:setGray(true)
        self.btnOk:setEnable(false)
    else
        self.selectImage:setVisible(true)
        self.btnOk:setGray(false)
        self.btnOk:setEnable(true)
        local pos = self.btnWashs[idx]._setting
        display.adapt(self.selectImage, pos.x+54,pos.y+35, GConst.Anchor.Center)
    end
end
function HeroSpecialWash:contrastBSkill(cur,select)
    if not GameLogic.isEmptyTable(cur) and not GameLogic.isEmptyTable(select) then
        if (cur.id == select.id) and (cur.level == self.heroMsg:getTalentSkillMax(select.id)) then
            return true
        end
    end
    return false
end

function HeroSpecialWash:reloadBanner(hero, banner, bskill,isMax)
    local maxLv
    if isMax == 2 then
        maxLv = hero:getTalentSkillMax(bskill.id)
    else
        maxLv = bskill.level
    end
    banner.name:setString(hero:getTalentSkillName(bskill.id))
    banner.info:setString(hero:getTalentSkillInfo(bskill.id, maxLv))
    banner.num:setString(maxLv .. "/" .. hero:getTalentSkillMax(bskill.id))
    banner.icon:removeAllChildren(true)
    GameUI.addSkillIcon(banner.icon, 3, bskill.id, 1.1,174,126)
end

