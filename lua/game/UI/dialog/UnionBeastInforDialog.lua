--联盟神兽信息对话框
local UnionBeastInforDialog = class2("UnionBeastInforDialog",function()
    return BaseView.new("UnionBeastInforDialog.json")
end)

function UnionBeastInforDialog:ctor()
	self.dialogDepth=display.getDialogPri()+1
    self:initUI()
    self.priority=self.dialogDepth
    display.showDialog(self)
end

function UnionBeastInforDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butHelp:setScriptCallback(Script.createCallbackHandler(HelpDialog.new))
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
   
    self:showLeftViews()
    self:createRightViews()
end

function UnionBeastInforDialog:showLeftViews()
    local bg=self
    local temp
    self:loadView("leftViews")
    GameUI.addHeroFeature(self, 5001, 1, 121+417, 181, 0)

   for i=1,6 do
        temp=ui.button({115,106},nil,{image="images/hero_tianfu.png"})
        display.adapt(temp,119+(i-1)*118,74, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
   end
end

function UnionBeastInforDialog:createRightViews()

   local infos={}
   for i=1,15 do
       infos[i]={["id"]=i}
   end
    self:addTableViewProperty("beastTableViews",infos,Script.createBasicHandler(self.callcell,self))
    self:loadView("beastTableViews")

end

function UnionBeastInforDialog:callcell(cell, tableView, info)
    local bg = cell:getDrawNode()

    self:loadView("beastCellBack1",bg)
    if info.id <=4 then
        self:loadView("beastCellViews",bg)
       
        GameUI.addHeroHead(bg,5001,{size={219,206},x=8,y=6}) 

        local function createXuanZhong(cell)
            if not self.cellxz then
                local xuanzhong = ui.sprite("images/dialogItemSelectGrid.png",{289, 278})
                display.adapt(xuanzhong,-25, -25, GConst.Anchor.LeftBottom)
                bg:addChild(xuanzhong)
                self.cellxz=xuanzhong
            else
                self.cellxz:removeFromParent(true)
                local xuanzhong = ui.sprite("images/dialogItemSelectGrid.png",{289, 278})
                display.adapt(xuanzhong,-25, -25, GConst.Anchor.LeftBottom)
                bg:addChild(xuanzhong)
                self.cellxz=xuanzhong
            end
        end
        cell:setScriptCallback(Script.createCallbackHandler(createXuanZhong,cell))

    else
        self:loadView("beastCellBack1",bg)
        self.viewTab.imaBattleCellBg:setSValue(-100)
    end
end

return UnionBeastInforDialog