local SData = GMethod.loadScript("data.StaticData")
local ChangeScene = {state="cleanup"}
function ChangeScene:show(ctype,btype,isExit,isRepeat)
    if self.state=="cleanup" then
        local bg = ui.touchNode(display.winSize, 0, true)
        local temp = ui.colorNode(display.winSize, GConst.Color.Black)
        bg:addChild(temp)
        temp = ui.node({0,0}, true)
        display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom, {scale=ui.getUIScale2()})
        bg:addChild(temp,3)
        local temp1 = ui.button({184, 196}, nil, {image="images/btnBlueBack.png", more={{"image","images/btnMTask.png",142,161,-5,55},{"label",StringManager.getString("buttonBackHome"),General.font1, 42, {fontW=160, fontH = 110}, 0, -16}}})
        display.adapt(temp1, 130, 118, GConst.Anchor.Center)
        temp:addChild(temp1,2)
        self.backBut = temp1
        temp = ui.node({256,256}, true)
        display.adapt(temp, 0, 0, GConst.Anchor.RightBottom, {scale=ui.getUIScale2()})
        bg:addChild(temp,2)
        local text="labelLoading2"
        if btype==1 and not isRepeat then
            text="labelLoading3"
        end
        if ctype==2 and isExit then
            text="labelLoading4"
        end
        temp1= ui.label(StringManager.getString(text), General.font2, 55, {color={242,183,19}, fontW = 500, fontH = 100})
        display.adapt(temp1, 208, 130, GConst.Anchor.Right)
        temp:addChild(temp1,2)
        local bbg = ui.node()
        display.adapt(bbg, 0, 0, GConst.Anchor.Bottom, {scale=ui.getUIScale2()})
        bg:addChild(bbg,2)
        local w=1024-208-temp1:getContentSize().width-20
        local labelTips= ui.label("", General.font1, 45, {color={255,255,255},width=2*w})
        display.adapt(labelTips, 0, 130, GConst.Anchor.Center)
        bbg:addChild(labelTips,2)
        local function cgStr()
            local id = self:randomTips()
            labelTips:setString(Localize("tips_" .. id))
        end
        cgStr()
        local allTime = 0
        RegTimeUpdate(labelTips,function(diff)
            allTime = allTime+diff
            if allTime>=10 then
                allTime = 0
                cgStr()
            end
        end, 1)

        temp = ui.node({2048,1536}, true)
        display.adapt(temp, 0, 0, GConst.Anchor.Center, {scale=ui.getUIScale2()})
        bg:addChild(temp)
        self.center = temp
        self.dtype = nil

        display.adapt(bg, 0, 0)
        self.view = display.addLayer(bg, 5, 2)
        self.view:retain()
        RegLife(self.view, Handler(self.lifeCycle, self))
        --RegUpdate(self.view,Handler(self.updateLoading, self), 0)
        self.state = "enter"
    end
    if self.dtype~=ctype then
        self.center:removeAllChildren(true)
        self.dtype = ctype
        local temp = self.center
        local temp1
        local cutscene=GMethod.loadScript("game.GameEffect.Cutscenes").new()
        display.adapt(cutscene, 1024,768,GConst.Anchor.Center)
        temp:addChild(cutscene)
        if ctype==1 then--瓦力
            -- temp1 = ui.label(StringManager.getString("tipsLoading"), General.font2, 54)
            -- display.adapt(temp1, 1280, 676, GConst.Anchor.Center)
            -- temp:addChild(temp1)

            temp1=ui.animateSprite(0.18,"lvdaiLeft",3,{beginNum=0,plist="images/background/loadingChange1.plist",isRepeat=true})
            temp1:setPosition(956, 643)
            temp1:setAnchorPoint(0,0)
            temp:addChild(temp1)
            local waliLeft=temp1
            temp1=ui.animateSprite(0.9,"wali" ,9,{beginNum=0,plist="images/background/loadingChange1.plist",isRepeat=true})
            temp1:setPosition(947, 600)
            temp1:setAnchorPoint(0,0)
            temp:addChild(temp1)
            local wali=temp1
            temp1=ui.animateSprite(0.18,"lvdaiRight" ,3,{beginNum=0,plist="images/background/loadingChange1.plist",isRepeat=true})
            temp1:setPosition(956, 581)
            temp1:setAnchorPoint(0,0)
            temp:addChild(temp1)
            local waliRight=temp1
            temp1=ui.animateSprite(0.9,"waliMoney" ,9,{beginNum=0,plist="images/background/loadingChange1.plist",isRepeat=true})
            temp1:setPosition(657, 579)
            temp1:setAnchorPoint(0,0)
            temp:addChild(temp1)
            local waliMoney=temp1
            local pos={}
            pos[1]={} --ÍßÁ¦ÉíÌåÎ»ÖÃ
            table.insert(pos[1],{947, 600})
            table.insert(pos[1],{947, 620})
            table.insert(pos[1],{947, 636})
            table.insert(pos[1],{947, 630})
            table.insert(pos[1],{947, 608})
            table.insert(pos[1],{947, 602})
            table.insert(pos[1],{947, 623})
            table.insert(pos[1],{947, 637})
            table.insert(pos[1],{947, 626})
            pos[2]={} --ÍßÁ¦×óÂÖ×ÓÎ»ÖÃ
            table.insert(pos[2],{956, 643})
            table.insert(pos[2],{940, 642})
            table.insert(pos[2],{937, 645})
            pos[3]={}  --ÍßÁ¦ÓÒÂÖ×ÓÎ»ÖÃ
            table.insert(pos[3],{956, 581})
            table.insert(pos[3],{940, 580})
            table.insert(pos[3],{937, 583})
            pos[4]={} --ÍßÁ¦½ð±ÒÎ»ÖÃ
            table.insert(pos[4],{657, 579})
            table.insert(pos[4],{829, 593})
            table.insert(pos[4],{786, 578})
            table.insert(pos[4],{772, 604})
            table.insert(pos[4],{701, 564})
            table.insert(pos[4],{841, 597})
            table.insert(pos[4],{797, 600})
            table.insert(pos[4],{765, 580})
            table.insert(pos[4],{719, 565})
            local num1=1
            local function setpos1()
                num1=num1+1
                if num1>9 then
                    num1=1
                end
                wali:setPosition(pos[1][num1][1],pos[1][num1][2])
                waliMoney:setPosition(pos[4][num1][1],pos[4][num1][2])
            end
            local num2=1
            local function setpos2()
                num2=num2+1
                if num2>3 then
                    num2=1
                end
                waliLeft:setPosition(pos[2][num2][1],pos[2][num2][2])
                waliRight:setPosition(pos[3][num2][1],pos[3][num2][2])
            end
            temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",0.1},{"call",setpos1}})))
            temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",0.3},{"call",setpos2}})))
        elseif ctype==2 then--传送门
            cutscene:show_ChuanSongMen()
        elseif ctype==3 then
            cutscene:show_hulkVSjs()
        elseif ctype==4 then
            cutscene:show_NanJsZuiBS()
        elseif ctype==5 then
            cutscene:show_sishenVSleishen()
        elseif ctype==6 then
            cutscene:show_leishenVSjs()
        end
    end
end
function ChangeScene:randomTips()
    local key = "tips"
    local info = {}
    if GEngine.getConfig(key) then
        info = json.decode(GEngine.getConfig(key))
    else
        info.lv = 1
        info.list = {}
    end
    local ids = SData.getData("tipsConfig", info.lv)

    local id
    local nids = {}
    local excepts = {}
    for _, oid in ipairs(info.list) do
        excepts[oid] = 1
    end
    for _, nid in KTIPairs(ids) do
        if not excepts[nid] then
            table.insert(nids, nid)
        end
    end
    id = nids[math.random(#nids)]
    table.insert(info.list, id)
    if #info.list > 3 then
        table.remove(info.list, 1)
    end
    GEngine.setConfig(key, json.encode(info), true)
    return id
end

function ChangeScene:setExitCallback(handler)
    if handler then
        self.backBut:setScriptCallback(handler)
        self.backBut:setVisible(true)
    else
        self.backBut:setVisible(false)
    end
end

function ChangeScene:delete()
    if self.state=="enter" then
        self.view:removeFromParent(true)
    elseif self.state=="exit" then
        self.view:cleanup(true)
    end
end

function ChangeScene:lifeCycle(event)
    if event=="cleanup" then
        self.state = "cleanup"
        self.view:release()
        self.view = nil
    elseif event=="exit" then
        ResAsyncLoader:getInstance():removeTask(self.view)
        self.state = "exit"
    elseif event=="enter" then
        self.state = "enter"
    end
end

return ChangeScene
