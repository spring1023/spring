--语言设置对话框
local countryInfos=GMethod.loadConfig("configs/languages.json")

local LanguageSetDialog = class2("LanguageSetDialog",function()
    return BaseView.new("LanguageSetDialog.json",true)
end)

function LanguageSetDialog:ctor()
    local language = General.language
    self.lconf = GEngine.lanConfig.languages[language]
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    display.showDialog(self)
end

function LanguageSetDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.priority))

    local infos={}
    if GEngine.rawConfig.forceLan then
        for i1, lan in ipairs(GEngine.rawConfig.forceLan) do
            for i2, cinfo in ipairs(countryInfos) do
                if cinfo[3] == lan then
                    infos[i1] = {id=i2, key=cinfo[1]}
                end
            end
        end
    else
        for i=1,#countryInfos do
            if i > (GEngine.rawConfig.maxLan or 3) then
                break
            end
            infos[i] = {id=i,key=countryInfos[i][1]}
        end
    end
    self:addTableViewProperty("languageTableView",infos,Script.createBasicHandler(self.callCell,self))
    self:loadView("languageTableView")
end
function LanguageSetDialog:callCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    self:loadView("cellBackViews",bg)
    local i=info.id
    local iconCountry= ui.sprite("images/iconCountry/iconCountry" .. countryInfos[i][2] .. ".png",{99, 102})
    display.adapt(iconCountry, 38, 26, GConst.Anchor.LeftBottom)
    bg:addChild(iconCountry)

    local temp = ui.label(countryInfos[i][4], General.font5, 45, {color={255,255,255},width=210,align=GConst.Align.Left})
    display.adapt(temp, 148, 85, GConst.Anchor.Left)
    bg:addChild(temp)
    if self.lconf[1] == info.key then
        cell:setGray(true)
    end
    ui.setListener(cell,function()
        if self.lconf[1] == info.key then
            display.pushNotice(Localize("stringHaveCL"))
        else
            local otherSettings = {callback = function()
                GameLogic.changeLanguage(countryInfos[i][3] or "CN")
                GEngine.restart()
            end}
            local dl = AlertDialog.new(3,Localize("labelLanguageSet"),Localize("stringLanguageSet"),otherSettings)
            display.showDialog(dl)
        end
    end)
end
return LanguageSetDialog













