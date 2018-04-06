local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
AccDialog = class()

function AccDialog:ctor(type, param)
    self.type = type

    local temp, bg = nil
    self.priority = display.getDialogPri()+1
    DialogTemplates.loadDefaultTemplate(self, 2, self.priority)
    bg = self.view
    if type==1 then
        self.title:setString(StringManager.getString("titleAccBuild"))
        self.worklist = param.worklist
        self.build = param
    end
    temp = ui.sprite("images/proBack4.png",{1288, 109})
    display.adapt(temp, 164, 630, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    temp = ui.sprite("images/proFillerBlue.png",{1282, 100})
    display.adapt(temp, 167, 635, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    self.process = temp
    temp = ui.sprite("images/dialogItemAccIcon.png",{189, 208})
    display.adapt(temp, 62, 580, GConst.Anchor.LeftBottom)
    bg:addChild(temp)

    temp = ui.label("", General.font1, 60, {color={255,255,255}})
    display.adapt(temp, 806, 688, GConst.Anchor.Center)
    bg:addChild(temp)
    self.timeLabel = temp

    local context = GameLogic.getUserContext()
    local offx = 0
    if not GameLogic.useTalentMatch then
        local num = context:getVipPermission("relbuild")[2]
        temp = ui.label(StringManager.getFormatString("labelNumLeft",{num=num}), General.font1, 55, {color={255,255,255}})
        display.adapt(temp, 189, 426, GConst.Anchor.Center)
        bg:addChild(temp)
        self.remianTime = temp

        temp = ui.button({185, 185}, self.onAccByVip, {cp1=self})
        display.adapt(temp, 97, 203, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        temp:setAutoHoldTime(0.5)
        temp:setAutoHoldTimeTemp(0.1)
        local but = temp:getDrawNode()
        temp = ui.sprite("images/items/itemIconBackBlue.png",{185,185})
        display.adapt(temp, 0, 0)
        but:addChild(temp, -1)
        temp:setHValue(62)
        temp = ui.sprite("images/btnMenuUpgrade.png",{151, 133})
        display.adapt(temp, 11, 32, GConst.Anchor.LeftBottom)
        but:addChild(temp)
        temp = ui.sprite("images/btnMenuBoost1.png",{70, 87})
        display.adapt(temp, 49, 1, GConst.Anchor.LeftBottom)
        but:addChild(temp)
        temp = ui.label(StringManager.getString("labelAccOneHour"), General.font1, 40, {color={255,255,255}})
        display.adapt(temp, 189, 165, GConst.Anchor.Center)
        bg:addChild(temp)
    else
        offx = 262
    end
    temp = ui.label(StringManager.getString("labelAccByItem"), General.font1, 50, {color={255,255,255}})
    display.adapt(temp, 409+502-offx/2, 540, GConst.Anchor.Center)
    bg:addChild(temp)
    temp=ui.colorNode({1005+offx,380},{0,0,0})
    display.adapt(temp, 409-offx, 95, GConst.Anchor.LeftBottom)
    temp:setOpacity(0.5*255)
    bg:addChild(temp)

    temp = ui.button({133, 232}, Handler(self.onChangeLeft, self), {image="images/dialogButNext.png"})
    display.adapt(temp, 381-offx, 280, GConst.Anchor.Center)
    bg:addChild(temp)
    temp = ui.button({133, 232}, Handler(self.onChangeRight, self), {image="images/dialogButNext.png"})
    display.adapt(temp, 1441, 280, GConst.Anchor.Center)
    bg:addChild(temp)
    temp:setFlippedX(true)


    local infos={}
    local infoMap={}
    local item
    local context = GameLogic.getUserContext()
    for i=1,4 do
        local num = context:getItem(const.ItemAccObj, i)
        if num>0 then
            item = {itype=const.ItemAccObj, id=i, num=num}
            infoMap[i] = item
            table.insert(infos, item)
        end
    end
    self.infos = infos
    self.infoMap = infoMap
    local tableView = ui.createTableView({920+offx, 380}, true, {size=cc.size(185,185), offx=46, offy=66, disx=77, disy=0, rowmax=1, infos=infos, cellUpdate=Handler(self.updateItemCell, self)})
    display.adapt(tableView.view, 452-offx, 95, GConst.Anchor.LeftBottom)
    bg:addChild(tableView.view)
    self.tableView = tableView
    RegActionUpdate(self.view, Handler(self.updateTime, self, 0.05), 0.05)
end

function AccDialog:onChangeLeft()
    self.tableView:moveViewTo(-1)
end

function AccDialog:onChangeRight()
    self.tableView:moveViewTo(1)
end

function AccDialog:updateTime(diff)
    local etime = nil
    local ttime = nil
    local stime = GameLogic.getSTime()
    if self.type==1 then
        local wl = self.worklist
        if wl then
            etime = wl[4]
            ttime = wl[4]-wl[3]
        end
    end
    if not etime or not ttime or etime<=stime then
        self.timeLabel:setString("")
        self.process:setProcess(true, 1)
        display.closeDialog()
    else
        local ltime = etime-stime
        self.ltime = ltime
        self.timeLabel:setString(StringManager.getFormatTime(ltime, 3))
        self.process:setProcess(true, (ttime-ltime)/ttime)
    end
end

function AccDialog:updateItemCell(cell, tableView, info)
    local bg= cell:getDrawNode()
    cell:setAutoHoldTime(0.5)
    cell:setAutoHoldTimeTemp(0.1)
    if not info.view then
        info.view = cell
        cell:setScriptCallback(ButtonHandler(self.onAccByItem, self, info))
        local temp = ui.label("", General.font1, 40, {color={255,255,255}, size={200, 100},fontW=260,fontH=100})
        display.adapt(temp, 92, -12, GConst.Anchor.Top)
        bg:addChild(temp, 1)
        info.nameLabel = temp
    end
    if info.id~=info.displayId or info.itype~=info.displayType then
        info.displayType = info.itype
        info.displayId = info.id
        if info.itemView then
            info.itemView:removeFromParent(true)
            info.itemView = nil
            info.numLabel = nil
        end
        info.itemView, info.numLabel = GameUI.addItemIcon(bg, info.itype, info.id, 0.934, 92, 92, true, false, {itemNum=info.num})
        info.nameLabel:setString(StringManager.getString("dataItemName" .. info.itype .. "_" .. info.id))
    end
end

function AccDialog:onAccByItem(item)
    local function acc()
        if not self.deleted then
            local context = GameLogic.getUserContext()
            if context:getItem(item.itype, item.id)>0 then
                if context.buildData:accBuildByItem(self.build, item.id) then
                    item.num = item.num-1
                    if item.num<=0 then
                        for i, info in ipairs(self.infos) do
                            if info==item then
                                self.tableView:removeCell(i)
                                break
                            end
                        end
                    else
                        item.numLabel:setString(tostring(item.num))
                    end
                    display.pushNotice(Localize("noticeAccSuccess"))
                end
            end
        end
    end
    local value = SData.getData("property",const.ItemAccObj,item.id).value
    if value - self.ltime>3600 then
        local otherSettings = {callback = function()
            acc()
        end}
        local dl = AlertDialog.new(3,Localize("btnUseItem"),Localize("stringAccPrompt"),otherSettings)
        display.showDialog(dl)
    else
        acc()
    end
end

function AccDialog:onAccByVip()
    if not self.deleted then
        local context = GameLogic.getUserContext()
        local num = context:getVipPermission("relbuild")[2]
        if num>0 then
            if context.buildData:accBuildByVip(self.build) then
                self.remianTime:setString(Localizef("labelNumLeft",{num = num-1}))
                context.vips[1][2] = GameLogic.getSTime()
                context.vips[1][3] = context.vips[1][3]+1
                display.pushNotice(Localize("noticeAccSuccess"))
            end
        else
            display.pushNotice(Localize("stringNotEnoughtTimes"))
        end
    end
end
