--领主头像列表对话框
local LordHeadListDialog = class(DialogViewLayout)

function LordHeadListDialog:ctor(params)
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth

    self.callback = params.callback
    self.headBackId = params.headBackId
    self:initData()
    self:initUI()
    display.showDialog(self)
end

function LordHeadListDialog:onCreate()
    self:setLayout("userInfo_head_dialog.json")
    self:loadViewsTo()
end

function LordHeadListDialog:onEnter()
end

function LordHeadListDialog:canExit()
    return true
end

function LordHeadListDialog:initData( ... )
    local SData = GMethod.loadScript("data.StaticData")
    local allHerosData = SData.getData("hinfos")
    
    --英雄已有表
    local heroMap = {}
    local context = GameLogic.getUserContext()
    local heros = context.heroData:getAllHeros()
    for k,v in pairs(heros) do
        if not heroMap[v.hid] or v.awakeUp > heroMap[v.hid] then
            heroMap[v.hid] = v.awakeUp
        end
    end

    -- 好像有些英雄没有觉醒版头像，排除一下
    local noAwakeHeros = {[4014]=0, [4015]=0, [4016]=0, [4019]=0, [4008]=0, [4031]=0}
    -- 初始开放英雄头像；纯走配置
    local initHeads = {}
    for i, hid in KTIPairs(SData.getData("constsNew", 4).data) do
        initHeads[hid] = 1
    end
    --英雄排序
    local heroOrder = {}

    local infos1 = {}
    local infos2 = {}
    local infos3 = {}
    for hid, hinfo in pairs(allHerosData) do
        -- 超过范围不是英雄
        if hid < 5000 and hid % 1000 ~= 0 then
            local order = (hinfo.displayColor or hinfo.color or 0) * 100000
                + (hinfo.rating or 0) * 10000 + hid
            if initHeads[hid] then
                table.insert(infos1, {id=hid, awakeUp=0, have=true, __order=order})
            elseif heroMap[hid] then
                table.insert(infos2, {id=hid, awakeUp=0, have=true, __order=order})
                if heroMap[hid] > 0 and not noAwakeHeros[hid] then
                    table.insert(infos3, {id=hid, awakeUp=1, have=true, __order=order})
                elseif hinfo.awake > 0 and not noAwakeHeros[hid] then
                    table.insert(infos3, {id=hid, awakeUp=1, have=false, __order=order - 10000000})
                end
            else
                order = order - 10000000
                table.insert(infos2, {id=hid, awakeUp=0, have=false, __order=order})
                if hinfo.awake > 0 and not noAwakeHeros[hid] then
                    table.insert(infos3, {id=hid, awakeUp=1, have=false, __order=order})
                end
            end
        end
    end

    GameLogic.mySort(infos1, "__order", true)
    GameLogic.mySort(infos2, "__order", true)
    GameLogic.mySort(infos3, "__order", true)

    self.allInfos={{Localize("labelBaseHead"),infos1},{Localize("labelHeroHead"),infos2},{Localize("labelAwakeHead"),infos3}}
end


function LordHeadListDialog:initUI()
    self.btn_close:setScriptCallback(ButtonHandler(display.closeDialog,self.priority))
    self.lb_system1:setString(Localize("labelLoadHead"))

    local allInfos = self.allInfos
    local scroll = self.scroll_head
    for _,info in ipairs(allInfos) do
        local cell = scroll:createItem(1)
        cell:loadViewsTo()
        self:headListCallCell(cell,scroll,info)
        scroll:addChild(cell)
    end
    self.btn_confirm:setScriptCallback(ButtonHandler(self.confirmCallback,self))
end

function LordHeadListDialog:headListCallCell(cell, scroll, info)
    -- dump(info,"info")
    if not cell then
        cell = scroll:createItem(1)
        cell:loadViewsTo()
    end

    cell.lb_basicHead:setString(info[1])   
    local layout = cell.layout_headList
    for i,v in ipairs(info[2]) do
        local head = layout:createItem(1)
        head:loadViewsTo()
        layout:addChild(head)
        
        local size = head:getContentSize()
        local headIcon = GameUI.addItemIcon(head,9,v.id,0.8,size[1]/2,size[2]/2,true,nil,{lv = info.awakeUp})      
        
        local hid = math.floor(GameLogic.getUserContext():getInfoItem(const.InfoHead)/100)       
        head.img_headFrame:setSValue(v.have and 0 or -100)
        head.img_head:setSValue(v.have and 0 or -100)
        head.img_itemFrame_choose:setVisible(v.id == hid)
        headIcon:setSValue(v.have and 0 or -100)

        head.btn_clip:setScriptCallback(ButtonHandler(function()
            if v.have then
                self:setSelectIcon(head, v.id)
                self.callback(v.id,v.awakeUp)
                display.closeDialog(0)
            else
                display.pushNotice(Localize("stringNoHead"))
            end
        end))

        
        if v.id == hid then
            self.myHead = head
            self.selectedId = v.id
        end
    end
    return cell
end

function LordHeadListDialog:setSelectIcon(cellBut, headId)
    if self.selectedId == headId then
        return
    end
    local myHead = self.myHead
    myHead.img_itemFrame_choose:setVisible(false)
    cellBut.img_itemFrame_choose:setVisible(true)
    self.selectedId = headId 
    self.myHead = cellBut
end


function LordHeadListDialog:confirmCallback()
    if self.selectedId then
        self.callback(self.selectedId)
        self:closeDialog()
    end
end



return LordHeadListDialog
