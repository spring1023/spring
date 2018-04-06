local Base = GMethod.loadScript("game.GameLogic.LogicTemplates.BaseTemplate")

-- 物品/属性通用模块
GMethod.loadScript("game.GameLogic.LogicTemplates.ItemImplements")
-- 花费/条件通用模块
GMethod.loadScript("game.GameLogic.LogicTemplates.CostImplements")
-- 时间滚动通用模块
GMethod.loadScript("game.GameLogic.LogicTemplates.TimeImplements")
-- 就是作为一个property来使用的通用模块
GMethod.loadScript("game.GameLogic.LogicTemplates.PropertyImplements")

-- 分数有关通用模块
GMethod.loadScript("game.GameLogic.LogicTemplates.ScoreImplement")
-- 购买有关通用模块
GMethod.loadScript("game.GameLogic.LogicTemplates.BuyableImplement")
-- 升级有关通用模块
GMethod.loadScript("game.GameLogic.LogicTemplates.UpgradeImplement")
-- 队列有关通用模块
GMethod.loadScript("game.GameLogic.LogicTemplates.QueueImplement")


-- 关卡有关非通用模块
GMethod.loadScript("game.GameLogic.LogicTemplates.StageImplement")


return Base
