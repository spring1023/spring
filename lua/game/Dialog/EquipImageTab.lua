local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

local EquipImageTab = class(DialogTabLayout)

local _heroImageTabHValues = {0, 111, 180, -65}

local function _sortHeroImages(a, b)
    if a[2].fragNum~=b[2].fragNum then
        return a[2].fragNum>b[2].fragNum
    else
        return a[1]>b[1]
    end
end

function EquipImageTab:create()
    self:setLayout("NormalImageTab.json")
    self:loadViewsTo()
    self.tabEids = {}
    local edata = self:getContext().equipData
    for eid=2001,2009 do
        if eid ~= 2004 then
            table.insert(self.tabEids, {eid=eid, equip=edata:makeEquip(eid)})
        end
    end
    return self.view
end

function EquipImageTab:onEnter()
    local dialog = self:getDialog()
    dialog.title:setString(StringManager.getString("labelEquipImage"))
    dialog.title:setVisible(true)
    dialog.questionBut:setVisible(true)
    dialog.questionTag = "dataQuestionEquipImage"
    self.nodeImageTable:loadTableView(self.tabEids, Handler(self.onUpdateEquipImage, self))
end

local function _updateFlipCell(info, isBack2)
    local equip = GameLogic.getUserContext().equipData:makeEquip(info.eid)
    display.showDialog(EquipInfoNewDialog.new({equip = equip}))

    -- local back1, back2
    -- if isBack2 then
    --     back1, back2 = info.back.view, info.back2.view
    -- else
    --     back2, back1 = info.back.view, info.back2.view
    -- end
    -- back1:stopAllActions()
    -- back2:stopAllActions()
    -- back1:setVisible(true)
    -- back1:setScaleX(1)
    -- back1:runAction(ui.action.sequence({{"scaleTo",0.1,0,1},"hide"}))
    -- back2:setVisible(false)
    -- back2:setScaleX(0)
    -- back2:runAction(ui.action.sequence({{"delay",0.1},"show",{"scaleTo",0.1,1,1}}))
end

function EquipImageTab:onUpdateEquipImage(cell, tableView, info)
    local bg, temp = cell:getDrawNode()
    local context = self:getContext()
    if not info.viewLayout then
        info.viewLayout = self:addLayout("EquipImageCell",bg)
        info.viewLayout:loadViewsTo(info)
        info.btnImageInfo:setScriptCallback(ButtonHandler(_updateFlipCell, info, true))
        info.btnFlipBack:setScriptCallback(ButtonHandler(_updateFlipCell, info, false))
        info.btnMergeFrag:setScriptCallback(ButtonHandler(self.mergeEquipFrag, self, info))
    end
    info.labelImageDetails:setString(info.equip:getDesc(2))
    info.labelImageDetails:setColor(GConst.Color.White)
    info.nodeFeature:removeAllChildren()
    GameUI.addEquipFeature(info.nodeFeature, info.eid, 0.85, 0, 0, 0)
    if info.eid==2001 then
        UIeffectsManage:showEffect_leiting(info.nodeFeature.view,0,-7,0.85)
    elseif info.eid==2002 then
        UIeffectsManage:showEffect_julongzhixin(info.nodeFeature.view,0,13,0.85)
    elseif info.eid==2003 then
        UIeffectsManage:showEffect_xueguangzhishu(info.nodeFeature.view,0,-1,0.85)
    elseif info.eid==2005 then
        UIeffectsManage:showEffect_busizhixin(info.nodeFeature.view,70,10,0.85)
    elseif info.eid==2006 then
        UIeffectsManage:showEffect_zhanzhengwange(info.nodeFeature.view,60,0,1)
    elseif info.eid==2007 then
        UIeffectsManage:showEffect_kuangbao(info.nodeFeature.view,80,65,1)
    elseif info.eid==2008 then
        UIeffectsManage:showEffect_rock(info.nodeFeature.view,0,35)
    elseif info.eid==2009 then
        UIeffectsManage:showEffect_wand(info.nodeFeature.view,19,0)
    end
    info.labelHeroName:setString(info.equip:getName())
    GameUI.setHeroNameColor(info.labelHeroName, info.equip.color)
    local cnum = context:getItem(const.ItemEquipFrag, info.eid)
    local _,mnum = info.equip:getFragNum() --const.EquipFragMerge
    if cnum>=mnum then
        info.labelFragNum:setColor(GConst.Color.Green)
        info.btnMergeFrag:setVisible(true)
    else
        info.labelFragNum:setColor(GConst.Color.White)
        info.btnMergeFrag:setVisible(false)
    end
    info.labelFragNum:setString(cnum .. "/" .. mnum)
    GameUI.addItemIcon(info.nodeFragBack,const.ItemEquipFrag,info.eid,0.9,0,0)
end

function EquipImageTab:mergeEquipFrag(info)
    local eid = info.eid
    local _,_fNum = info.equip:getFragNum()
    local context = self:getContext()
    local equipData = context.equipData
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
            info.labelFragNum:setColor(GConst.Color.Green)
            info.btnMergeFrag:setVisible(true)
        else
            info.labelFragNum:setColor(GConst.Color.White)
            info.btnMergeFrag:setVisible(false)
        end
        info.labelFragNum:setString(cnum .. "/" .. mnum)
    end
end

return EquipImageTab
