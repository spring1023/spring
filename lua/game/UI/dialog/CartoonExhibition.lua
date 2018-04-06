--漫画展示
local CartoonExhibition = class2("CartoonExhibition",function()
    return BaseView.new("CartoonExhibition.json",true)
end)

function CartoonExhibition:ctor(idx)
    self.idx = idx
    self.config = GMethod.loadConfig("configs/comic.json")[idx]
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    display.showDialog(self,false)
end

function CartoonExhibition:initUI()
    self:loadView("cartoonView1",self.idx)
    self:loadView("endExhibitionView")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.priority))
    if self.idx == 0 then
        self:initView0()
    else
        self:initCartoon()
    end
end

function CartoonExhibition:initView0()

end

function CartoonExhibition:initCartoon()
    -- body
end

return CartoonExhibition