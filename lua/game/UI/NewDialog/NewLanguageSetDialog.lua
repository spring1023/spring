--语言设置对话框
local countryInfos=GMethod.loadConfig("configs/languages.json")

local LanguageSetDialog = class(DialogViewLayout)

function LanguageSetDialog:ctor(params)
    local language = General.language
    self.lconf = GEngine.lanConfig.languages[language]
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    self.callback = params.callback;
    display.showDialog(self)
end

function LanguageSetDialog:onCreate()
    self:setLayout("userInfo_language_dialog.json");
    self:loadViewsTo()
end

function LanguageSetDialog:initUI()
    self.btn_close:setScriptCallback(ButtonHandler(display.closeDialog, self.priority));

    -- 语言列表加载
    local infos={}
    for i=1,#countryInfos do
        infos[i]={id=i,key=countryInfos[i][1]}
    end

    local scroll = self.scroll_btns
    scroll:setLazyTableData(infos,Handler(self.callCell,self),0)
end
--  cell的刷新函数
function LanguageSetDialog:callCell(cell, scroll, info)
    if not cell then
        cell = scroll:createItem(1)
        cell:loadViewsTo()
    end
    local id=info.id
    -- 设置语言名称
    cell.lb_l1:setString(Localize(countryInfos[id][4]))
    cell.btn_1:setGray(self.lconf[1] == info.key)
  
    cell.btn_1:setScriptCallback(ButtonHandler(function()
        if self.lconf[1] == info.key then
            display.pushNotice(Localize("stringHaveCL"))
        else
            local otherSettings = {callback = function()
                GameLogic.changeLanguage(countryInfos[id][3] or "CN")
                GEngine.restart(true)
            end}
            local dl = AlertDialog.new(3,Localize("labelLanguageSet"),Localize("stringLanguageSet"),otherSettings)
            display.showDialog(dl)    
        end
    end))
    
    
    return cell
end
return LanguageSetDialog