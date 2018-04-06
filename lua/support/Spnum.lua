
Spnum = class2("Spnum",function()
    return ui.node()
end)

function Spnum:ctor(num,sgin)
    self.sgin = sgin or 0    --1加   2减   3乘
    self:setCascadeOpacityEnabled(true)
    self:setCascadeColorEnabled(true)
    self:initNum(num)
end

function Spnum:initNum(num)
    if not memory.getFrame("spnum_1.png", true) then
        memory.loadSpriteSheet("images/spnum.plist")
    end

    local negative
    if num<0 then
        negative = true
    end
    local tb = {}
    for i=1,100 do
        local n = num%10
        table.insert(tb,n)
        num = math.floor(num/10)
        if num<=0 then
            break
        end
    end

    local allX = 0
    if self.sgin>0 then
        local set = {"z","f","x"}
        local sp = ui.sprite("spnum_" .. set[self.sgin] .. ".png")
        display.adapt(sp,allX,0,GConst.Anchor.LeftBottom)
        self:addChild(sp)
        allX = allX+sp:getContentSize().width-5
    end
    for i=#tb,1,-1 do
        local n = tb[i]
        local sp = ui.sprite("spnum_" .. n .. ".png")
        display.adapt(sp,allX,0,GConst.Anchor.LeftBottom)
        self:addChild(sp)
        allX = allX+sp:getContentSize().width-5
    end
    self:setContentSize(allX,25)
    self:setScale(1.5)
end

