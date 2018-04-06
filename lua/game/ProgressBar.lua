

local ProgressBarMode = {
    BUILD_UP = 1,   --建筑升级进度
    BUILD_PD = 2,   --建筑生产进度
    HERO_MY = 3,    --本方英雄HP
    HERO_HE = 4,    --敌方英雄HP
    SOLDIER_MY = 5, --本方士兵HP
    SOLDIER_HE = 6, --敌方士兵HP
    BUILD_MY = 7,   --本方建筑HP
    BUILD_HE =8     --敌方建筑HP
}

local modeSet = {
    [1] = {
        {"hitpointsBack",{0,0},{59,12}},
        {"build_hitpoints2",{2,2},{55,8}}
    },
    [2] = {
        {"hitpointsBack",{0,0},{59,12}},
        {"hero_jineng",{2,2},{55,8}}
    },
    [3] = {
        {"progressBack",{0,0},{93,14}},
        {"progressGreen",{1,1},{91,12}}
    },
    [4] = {
        {"progressBack",{0,0},{93,14}},
        {"progressViolet",{1,1},{91,12}}
    },
    [5] = {
        {"progressBack",{0,0},{66,10}},
        {"Green",{1,1},{64,8}}
    },
    [6] = {
        {"progressBack",{0,0},{66,10}},
        {"progressViolet",{1,1},{64,8}}
    },
    [7] = {
        {"progressBack",{0,0},{93,14}},
        {"progressGreen",{1,1},{91,12}}
    },
    [8] = {
        {"progressBack",{0,0},{93,14}},
        {"progressViolet",{1,1},{91,12}}
    }
}

local ProgressBar = class2("ProgressBar",function()
    return shellNode.new(ui.node({0,0},true))
end)

--max2是假血的
function ProgressBar:ctor(mode,max,color)
    --英雄血条位置偏移
    self.max = max
    self.value = max
    self.mode = mode

    self._logicViews = {}
    self._ox = 0
    self._oy = 0
    local back = ui.sprite("images/" .. modeSet[mode][1][1] .. ".png",modeSet[mode][1][3])
    display.adapt(back, self._ox, self._oy, GConst.Anchor.LeftBottom)
    self:addChild(back)
    table.insert(self._logicViews, back)
    self:changeTexture(modeSet[mode][2][1])

    local size = back:getContentSize()

    if self.mode>4 then
        self:setCascadeOpacityEnabled(true)
        self:setOpacity(0)
        self:setVisible(false)
    elseif self.mode==3 or self.mode==4 then
        --条纹
        local stripe = ui.sprite("images/progressStripe.png",{57,14})
        display.adapt(stripe,20 + self._ox, self._oy, GConst.Anchor.LeftBottom)
        self:addChild(stripe)
        table.insert(self._logicViews, stripe)
        --等级 颜色
        local iconColor={"Green","Blue","Violet","Orange"}
        local iconLv=color
        local icon = ui.sprite("images/progressHeroLvIcon"..iconColor[iconLv]..".png",{33,32})
        display.adapt(icon,3 + self._ox,7 + self._oy, GConst.Anchor.Right)
        self:addChild(icon)
        table.insert(self._logicViews, icon)

        local lv = ui.label("", General.font1, 18, {color={255,255,255}})
        display.adapt(lv,-14+self._ox,8+self._oy, GConst.Anchor.Center)
        self:addChild(lv)
        self.labelLevel = lv
        table.insert(self._logicViews, lv)
        lv:setGlobalZOrder(2)
    end
    self:setContentSize(size.width,size.height)

    if mode<3 then
        self:initTime()
    end
end

function ProgressBar:setHpOffset(ox, oy)
    local _ox, _oy = self._ox, self._oy
    for _, view in ipairs(self._logicViews) do
        local x, y = view:getPosition()
        view:setPosition(ox-_ox+x, oy-_oy+y)
    end
    self._ox, self._oy = ox, oy
end

function ProgressBar:initTime()
    local num1,str1,num2,str2
    value = self.max - self.value
    if value>60*60*24 then
        local num = value/60/60
        num1 = math.floor(num/24)
        str1 = "天"
        num2 = math.floor(num%24)
        str2 = "小时"
    elseif value>60*60 then
        local num = value/60
        num1 = math.floor(num/60)
        str1 = "小时"
        num2 = math.floor(num%60)
        str2 = "分"
    else
        local num = value
        num1 = math.floor(num/60)
        str1 = "分"
        num2 = math.floor(num%60)
        str2 = "秒"
    end
    local str = "剩余："..num1..str1..num2..str2
    if self.time then
        self.time:setString(str)
    else
        self.time = ui.label(StringManager.getString(str), General.font1, 50, {color={255,255,255}})
        display.adapt(self.time,-23+self._ox,30+self._oy, GConst.Anchor.LeftBottom)
        self:addChild(self.time)
        table.insert(self._logicViews, self.time)
        self.time:setGlobalZOrder(2)
    end 
end

function ProgressBar:changeTexture(textureName)
    if self.textureName ~= textureName then
        self.textureName = textureName
        if self.progress then
            self.progress:removeFromParent(true)
        end
        if self.mode == 5 then
            self.progress = ui.sprite("images/progress" .. textureName .. ".png", modeSet[self.mode][2][3])
        else
            self.progress = ui.sprite("images/" .. textureName .. ".png", modeSet[self.mode][2][3])
        end
        display.adapt(self.progress,modeSet[self.mode][2][2][1] + self._ox, modeSet[self.mode][2][2][2] + self._oy, GConst.Anchor.LeftBottom)
        self:addChild(self.progress)
        table.insert(self._logicViews, self.progress)
    end
end

function ProgressBar:addHpBar(value,value2)
    self.value2 = value2
    self.progress2 = ui.sprite("images/build_hitpoints3.png", modeSet[self.mode][2][3])
    self.progress2:setHValue(111)
    display.adapt(self.progress2,modeSet[self.mode][2][2][1] + self._ox, modeSet[self.mode][2][2][2] + self._oy, GConst.Anchor.LeftBottom)
    self:addChild(self.progress2,3)
    self.progress2:setProcess(true, self.value2/self.max)
    self.progress:setProcess(true,value/self.max)
    table.insert(self._logicViews, self.progress2)
end

function ProgressBar:removeHpBar()
    if self.progress2 then
        for i, v in ipairs(self._logicViews) do
            if v == self.progress2 then
                table.remove(self._logicViews, i)
                break
            end
        end
        self.progress2:removeFromParent(true)
    end
end

function ProgressBar:changeValue2(value)
    if value<0 then value=0 end
    if value==self.value2 then return end
    self.value2 = value
    if not self.progress2 then
        if value>0 then
            self:addHpBar(self.value,value)
        end
        return
    end
    self.progress2:setProcess(true,self.value2/self.max)
end

function ProgressBar:changeValue(value)
    if self.value2 and self.value2>0 then
        self:changeValue2(value)
    else
        if value<0 then value=0 end
        if value==self.value then return end
        self.value = value
        if self.mode == 5 then
            if value*2>self.max then
                self:changeTexture("Green")
            elseif value*10>self.max then
                self:changeTexture("Yellow")
            else
                self:changeTexture("Red")
            end
        end
        self.progress:setProcess(true, self.value/self.max)
        if self.mode<3 then
            self:initTime()
        end
    end
    self:show()
end

function ProgressBar:show()
    if self.mode>4 then
        if self.hideAction then
            self:stopActionByTag(1)
            self.hideAction = nil
        end
        self:setVisible(true)
        self:setOpacity(255)

        local action = ui.action.sequence({{"delay",2},{"fadeOut",0.5},"hide"})
        action:setTag(1)
        self:runAction(action)
        self.hideAction = true
    end
end

function ProgressBar:setLevel(level)
    if self.labelLevel and level then
        self.labelLevel:setString(tostring(level))
    end
end

GEngine.export("ProgressBarMode",ProgressBarMode)
GEngine.export("ProgressBar", ProgressBar)
