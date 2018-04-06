local const = GMethod.loadScript("game.GameLogic.Const")
local vipset = {0, 0, 0, 0}
-- local vipset = {0, 1,5,10}
local SData = GMethod.loadScript("data.StaticData")

--领主头像框列表对话框
local LordHeadBackListDialog = class(DialogViewLayout)

function LordHeadBackListDialog:ctor(params)
    self.callback = params.callback
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self.headId = params.headId
    self:initData()
    self:initUI()
    display.showDialog(self)
end

function LordHeadBackListDialog:onCreate()
    self:setLayout("userInfo_head_dialog.json");
    self:loadViewsTo();
end

function LordHeadBackListDialog:initData()
    local context = GameLogic.getUserContext()
    local infos = {{cellType=1, text="labelHeadBackList"}}
    local maxHeads = 4
    local curValue = context:getInfoItem(const.InfoVIPlv)
    local needValues = vipset
    local unlockAdded = false
    local headIds = {1,2,3,4}
    if GameLogic.useTalentMatch then
        needValues = SData.getData("constsNew", 5).data
        curValue = self.context:getInfoItem(const.InfoCryNum)
        headIds = {1,2,5,3,4,6}
        maxHeads = 6
    end
    for i=1, maxHeads do
        local needValue = needValues[i]
        -- if needValue > curValue and not unlockAdded then
        --     unlockAdded = true
        --     table.insert(infos, {cellType = 1, text="labelLockHead",unlockAdded})
        -- end
        table.insert(infos, {cellType = 2, headId = headIds[i],
            curValue=curValue, needValue=needValue})
    end
    self.allInfos = {infos}
    self.selectedId = 1
end

function LordHeadBackListDialog:initUI()
    -- 关闭按钮
    self.btn_close:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))
    self.lb_system1:setString(Localize("labelHeadBackList"))

    -- 确定按钮
    self.btn_confirm:setScriptCallback(ButtonHandler(self.confirmCallback, self))
    
    -- 滚动视图
    local scroll = self.scroll_head
    local infos = self.allInfos;
    for i,info in ipairs(infos) do     
        local cell = scroll:createItem(1);
        scroll:addChild(cell);
        cell:loadViewsTo();
        self:canCell(cell, info);
       
    end
end

function LordHeadBackListDialog:canCell(cell, info)
    cell.lb_basicHead:setString(Localize("labelHeadBackList"));
    local headlayout = cell.layout_headList
    for i,v in ipairs(info) do
        if v.cellType == 2 then
            local frame = headlayout:createItem(1)
            frame:loadViewsTo()
            headlayout:addChild(frame)
            local size = frame:getContentSize()
            local headBackId = v.headId;
            GameUI.setHeadBackIcon(frame, headBackId, false)

            frame.btn_clip:setScriptCallback(ButtonHandler(function()
                -- if v.unlockAdded then
                    
                    self:setSelectIcon(frame,v.headId)
                -- else
                    -- 如果未拥有提示tip
                    -- display.pushNotice(Localize("stringLocked"))
                -- end
            end))
            frame.img_headFrame:setSValue(v.unlockAdded and -100 or 0)
            frame.img_head:setSValue(v.unlockAdded and -100 or 0)
            -- print("v.id,selectedId",v.headId,self.selectedId)
            frame.img_itemFrame_choose:setVisible(v.headId == self.selectedId)
            if v.headId == self.selectedId then
                self.myFrame = frame
                self.selectedId = v.id
            end
        end
    end
end

function LordHeadBackListDialog:setSelectIcon(cellBut, id)
    if self.selectedId == id then
        return
    end
    local myFrame = self.myFrame
    myFrame.img_itemFrame_choose:setVisible(false)
    cellBut.img_itemFrame_choose:setVisible(true)
    self.selectedId = id 
    self.myFrame = cellBut
end

function LordHeadBackListDialog:confirmCallback()
    self.callback(self.selectedId)
    self:closeDialog()
end

function LordHeadBackListDialog:closeDialog()
    display.closeDialog(self.priority)
end

return LordHeadBackListDialog