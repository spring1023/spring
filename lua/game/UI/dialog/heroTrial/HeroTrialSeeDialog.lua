

--英雄试炼查看对话框
local HeroTrialSeeDialog = class2("HeroTrialSeeDialog",function()
    return BaseView.new("HeroTrialSeeDialog.json")
end)

function HeroTrialSeeDialog:ctor(params,parent,callback)
    self.parent = parent
    self.params,self.callback = params,callback
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    display.showDialog(self)
    self:initBack()
end

function HeroTrialSeeDialog:initBack()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))

    self:loadView("leftViews")
    self:loadView("rightViews")
    self:initCenterView()

    self:insertViewTo()
    self.butChallenge:setListener(function()
        self.callback()
    end)
    if self.parent and self.parent.cantAttack then
        self.butChallenge:setGray(true)
    end
    if not self.parent or not self.parent.pvtbeginbattle then
        display.closeDialog(self.dialogDepth)
    end
    self.titleHeroTrialSee:setString(Localizef("stringSeeArr",{name = self.params.uinfo[2]}))

end
function HeroTrialSeeDialog:initCenterView()
    local heros = {}
    for i,v in ipairs(self.params.hinfo) do
        local num = math.floor(v[2]/10000)
        local idx = math.floor(num/10)
        local t = num%10

        if t == 1 then
            heros[idx] = v
        end
    end


    local bg,temp
    for i=0,8 do
        local v = heros[i+1]
        local k=math.floor(i/3)
        local j=i%3

        temp = ui.button({238, 229}, nil, {})
        display.adapt(temp, 354+j*323, 850-k*333, GConst.Anchor.LeftBottom)
        self:addChild(temp)
        bg=temp:getDrawNode()
        self:loadView("backViews",bg)
        
        if v then
            -- self:loadView("lvViews",bg)
            -- self:insertViewTo()
            -- self.heroLvValue:setString(v[4])
            -- local colorSet = {180,-57,0,111,57}
            -- self.heroLvIcon:setHValue(colorSet[math.floor(v[3]/1000)])
            -- --GameUI.addHeroHead(bg,v[3],{size={225,211},x=0,y=7})
            -- GameUI.addHeroHead(bg,v[3],{size={225,211},x=0,y=7})
            self.viewTab.heroBack:setVisible(false)
            self.viewTab.heroBackShadow:setVisible(false)
            local HeroData = GMethod.loadScript("game.GameLogic.HeroData")
            local hm = HeroData.new():makeHero(v[3])
            hm.level = v[4]
            GameUI.updateHeroTemplate(bg, {}, hm)
        else
            self.viewTab.heroBack:setSValue(-100)
        end
    end
end
return HeroTrialSeeDialog
