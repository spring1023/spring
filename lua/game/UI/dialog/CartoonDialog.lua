--漫画对话框
local CartoonDialog = class2("CartoonDialog",function()
    return BaseView.new("CartoonDialog.json",true)
end)

function CartoonDialog:ctor()
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    display.showDialog(self)
end

function CartoonDialog:initUI()
    self.idx = 1
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.priority))

    self:loadView("leftBackView")
    self:loadView("rightUpViews")
    self:loadView("rightDownVies")
    self:insertViewTo()
    self.butWatch:setListener(function()
        display.showDialog(ComicDialog.new(self.idx))
    end)
    local infos={}
    for i=1,6 do
        infos[i]={id=i}
    end
    self:addTableViewProperty("leftTableView",infos,Script.createBasicHandler(self.callCell,self))
    self:loadView("leftTableView")

end
function CartoonDialog:callCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    self:loadView("leftCellViews",bg)
    local viewTab = self:getViewTab()
    viewTab.comicTitle:setString(Localizef("labelPage" .. info.id,{a = Localize("dataComicTitle" .. info.id)}))

    local context = GameLogic.getUserContext()
    -- if context then
    --     local key = context.uid .. "_" .. context.sid .. "comicLook" .. self.num
    --     if GEngine.getConfig(key) then
    --         self:loadView("leftCellAlreadyWatch",bg)
    --     end
    -- end

    if info.id == self.idx then
        self:loadComic()
        self.lastCheckBack = viewTab.cellBack
    else
        ui.setColor(viewTab.cellBack, {69, 199, 217})
    end
    local cellBack = viewTab.cellBack
    ui.setListener(cell,function()
        ui.setColor(self.lastCheckBack, {69, 199, 217})
        ui.setColor(cellBack, {140, 209, 77})
        self.lastCheckBack = cellBack
        self.idx = info.id
        self:loadComic()
    end)
end
function CartoonDialog:loadComic()
    self.itemTitle:setString(Localize("dataComicTitle" .. self.idx))
    if self.kt then
        self.kt:removeFromParent(true)
        self.kt = nil
    end
    self.kt = ComicDialog.new(self.idx,0,"tab")
    display.adapt(self.kt,599,206,GConst.Anchor.LeftBottom)
    self:addChild(self.kt)
    self.kt:setScale(1399/2048)
end
return CartoonDialog









