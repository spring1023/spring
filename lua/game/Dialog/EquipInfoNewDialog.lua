EquipInfoNewDialog = class(DialogViewLayout)
local SData = GMethod.loadScript("data.StaticData")
function EquipInfoNewDialog:onInitDialog()
    self:setLayout("EquipInfoNewDialog.json")
    self:loadViewsTo()
    self.backBut:setVisible(true)
    self.backBut:setScriptCallback(ButtonHandler(self.backCallBack,self))
    self.questionTag = "dataEquipInfoNewHelp"
    self.title:setString(Localize(""))
    self.bgImage:setTexture("images/dialogBackHero2.png")

    self.equip = self.equip or {}
    self.context = GameLogic.getUserContext()
    self.data = self:getAllInfoData()
    self:initUI()
end

function EquipInfoNewDialog:backCallBack()
    display.closeDialog(self.priority)
end

function EquipInfoNewDialog:getAllInfoData()
    local allData = SData.getData("equipInfoNew")
    table.sort(allData, function (a,b)
        return a.order<b.order
    end )
    local data = {}
    for k,v in pairs(allData) do
        if not data[k] then
            data[k] = {}
        end
        data[k] = v
    end

    return data
end


function EquipInfoNewDialog:initOther()
    self.labelName:setString(Localize("dataEquipName"..self.equip.eid))
    GameUI.addEquipFeature(self.imgEquipFeature.view,self.equip.eid,1,0,0)

    local tnode = ui.node()
    if self.equip.eid==2001 then
        UIeffectsManage:showEffect_leiting(tnode,0,-7,0.85)
    elseif self.equip.eid==2002 then
        UIeffectsManage:showEffect_julongzhixin(tnode,0,13,0.85)
    elseif self.equip.eid==2003 then
        UIeffectsManage:showEffect_xueguangzhishu(tnode,0,-1,0.85)
    elseif self.equip.eid==2005 then
        UIeffectsManage:showEffect_busizhixin(tnode,70,10,0.85)
    elseif self.equip.eid==2006 then
        UIeffectsManage:showEffect_zhanzhengwange(tnode,60,0,1)
    elseif self.equip.eid==2007 then
        UIeffectsManage:showEffect_kuangbao(tnode,80,65,1)
    elseif self.equip.eid==2008 then
        UIeffectsManage:showEffect_rock(tnode,0,35)
    elseif self.equip.eid==2009 then
        UIeffectsManage:showEffect_wand(tnode,19,0)
    end
    display.adapt(tnode, 0, 0)
    tnode:setScale(1/0.85)
    self.imgEquipFeature.view:addChild(tnode)
end

function EquipInfoNewDialog:initUI()
    self:initOther()
    self:bgStory()
    self:initUISpecial()
    self:initFullLVAttribute()
    self:initAccessTo()
end

function EquipInfoNewDialog:bgStory()
    -- body
    self.labelBGStory:setString(Localize("labelInfoBgStory"))
    self.labelBGStoryInfo:setString(Localize(self.data[self.equip.eid].bgStory or ""))
end

function EquipInfoNewDialog:initUISpecial()
    self.labelTSJN:setString(Localize("labelEquipSkill"))
    local parmas = self.equip:getSkillParams(0)
    self.labelTSJNInfo:setString(Localizef(self.data[self.equip.eid].special,parmas))
end


function EquipInfoNewDialog:initFullLVAttribute()
    local data = SData.getData("elevels",self.equip.eid,215).effect
    local num = SData.getData("einstalls",self.equip.eid,1).equipParamsSet
    self.labelSX:setString(Localize("labelBasisLvAttribute"))
    local sxIcons = {self.sxIcon1,self.sxIcon2,self.sxIcon3,self.sxIcon4,self.sxIcon5,self.sxIcon6}
    for k=1,6 do
        local n = num[k]
        local path = "images/infoIcon1.png"
        if n==1 or n==8 or n==10 then
            path = "images/infoIcon1.png"
        elseif n==2 or n==11 then
            path = "images/infoIcon2.png"
        elseif n==3 or n==4 then
            path = "images/infoIcon3.png"
        elseif n==6 or n==9 then
            path = "images/infoIcon4.png"
        elseif n==5 or n==7 then
            path = "images/infoIcon5.png"
        end
        sxIcons[k].view:setTexture(path)
    end

    self.labelGJ:setString(Localizef("dataItemEffect"..num[1],{value=data[1]}))
    self.labelSM:setString(Localizef("dataItemEffect"..num[2],{value=data[2]}))
    self.labelMZ:setString(Localizef("dataItemEffect"..num[3],{value=data[3]}))
    self.labelBJ:setString(Localizef("dataItemEffect"..num[4],{value=data[4]}))
    self.labelYBGJ:setString(Localizef("dataItemEffect"..num[5],{value=data[5]}))
    self.labelYXKB:setString(Localizef("dataItemEffect"..num[6],{value=data[6]}))

    self.labelBF:setString(Localize("labelOutBreak"))
    self.lableSC:setString(Localize("labelOutPut"))
    self.labelFY:setString(Localize("labelDefense"))
    self.labelKZ:setString(Localize("labelControl"))

    --爆发
    local info = self.data[self.equip.eid]
    local pro = info.bnum/100
    self.imgPBar1:setProcess(true,pro)
    --输出
    pro = info.onum/100
    self.imgPBar2:setProcess(true,pro)
    --防护
    pro = info.dnum/100
    self.imgPBar3:setProcess(true,pro)
    --控制
    pro = info.cnum/100
    self.imgPBar4:setProcess(true,pro)
end

function EquipInfoNewDialog:initAccessTo()
    self.labelHD:setString(Localize("labelAccessTo"))
    self.labelHDTJ:setString(Localize(self.data[self.equip.eid].getWay or ""))
end

