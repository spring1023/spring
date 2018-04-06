local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local Base = GMethod.loadScript("game.GameLogic.LogicTemplates.BaseTemplate")

local _set = Base.sset
local _setReader = Base.ssetReader

do
    -- 可购买逻辑中间件；一定是和购买计数组件、购买花费组件一起用的
    local BuyableImplement = {}
    Base.registerImplement("Buyable", BuyableImplement)

    function BuyableImplement:_static_load(config)
        _set(self, "buyTarget", config["buyTarget"])
    end

    function BuyableImplement:getBuyCount(stime)
        if not stime then
            stime = GameLogic.getSTime()
        end
        return self:getValue(stime)
    end

    function BuyableImplement:getBuyMax()
        return self:getMax()
    end

    function BuyableImplement:getBuyItem(stime)
        return self:getCostItem(self:getBuyCount(stime) + 1)
    end

    -- 购买逻辑；花费、增加购买计数、增加购买的对象
    function BuyableImplement:buyChance(stime)
        if not stime then
            stime = GameLogic.getSTime()
        end
        local costItem = self:getBuyItem(stime)
        -- 花费
        self:useCostItem(self:getBuyCount(stime) + 1)
        -- 增加购买计数
        self:changeValue(1, stime)
        -- 增加购买的对象
        -- 先规定0类型是根节点增加购买的值；其他类型暂时还没用到过
        if self.buyTarget == 0 then
            self._weak_ref.raw:changeValue(costItem["addNum"], stime)
        else
            self._weak_ref.context:changeProperty(self.buyTarget[1], self.buyTarget[2], costItem["addNum"])
        end
    end

end
