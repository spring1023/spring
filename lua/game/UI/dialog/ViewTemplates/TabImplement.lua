local Base = GMethod.loadScript("game.UI.dialog.ViewTemplates.BaseTemplate")

-- 带tab的视图模版
-- onRefreshTab 留给其他部分实现，因为可能是同配置界面也可能就是多配置界面
local TabImplement = {}
Base.registerImplement("TabImplement", TabImplement)

function TabImplement:_static_load(data)
    self._tabs = {}
    self._tabDepth = 0
    self._backNode = data.backNode
    self._backBut = data.backBut
    self._backBut:setScriptCallback(ButtonHandler(self.popTab, self))
end

function TabImplement:pushTab(tabName)
    self._tabDepth = self._tabDepth + 1
    self._tabs[self._tabDepth] = tabName
    self._backNode:setVisible(self._tabDepth > 1)

    self:onRefreshTab(tabName)
end

function TabImplement:popTab()
    local _tabs = self._tabs
    local _tabDepth = self._tabDepth
    if _tabDepth > 1 then
        table.remove(_tabs, _tabDepth)
        _tabDepth = _tabDepth - 1
        self._tabDepth = _tabDepth

        self._backNode:setVisible(_tabDepth > 1)
        self:onRefreshTab(_tabs[_tabDepth])
    end
end

function TabImplement:changeTab(tabName)
    self._tabs[self._tabDepth] = tabName
    self:onRefreshTab(tabName)
end
