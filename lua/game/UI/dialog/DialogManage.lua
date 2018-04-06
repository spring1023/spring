GMethod.loadScript("game.UI.BaseView")

--联盟对话框
UnionDialog = GMethod.loadScript("game.UI.dialog.UnionDialog")
--联盟信息对话框
UnionInfoDialog = GMethod.loadScript("game.UI.dialog.UnionInfoDialog")
--领取联盟奖励对话框
ReceiveUnionRewardDialog = GMethod.loadScript("game.UI.dialog.ReceiveUnionRewardDialog")

--联盟宝箱对话框
UnionBoxDialog= GMethod.loadScript("game.UI.dialog.UnionBoxDialog")
--联盟伤害排名对话框
UnionDamageRankDialog = GMethod.loadScript("game.UI.dialog.UnionDamageRankDialog")
--联盟战斗对话框
UnionBattleDialog = GMethod.loadScript("game.UI.dialog.UnionBattleDialog")
--联盟旗帜对话框
UnionFlagDialog = GMethod.loadScript("game.UI.dialog.UnionFlagDialog")
--联盟副本对话框
UnionMapDialog = GMethod.loadScript("game.UI.dialog.UnionMapDialog")
--联盟战斗布阵界面
UnionBattleLineupInterface= GMethod.loadScript("game.UI.interface.UnionBattleLineupInterface")
--鼓舞士气
UnionBattleInspireDialog = GMethod.loadScript("game.UI.dialog.UnionBattleInspireDialog")
--英雄试炼战斗界面
HeroTrialBattleInterface = GMethod.loadScript("game.UI.interface.HeroTrialBattleInterface")

--问号对话框
HelpDialog =GMethod.loadScript("game.UI.dialog.HelpDialog")

--联盟对战偏好（小对话框 ）
UnionVSBias= GMethod.loadScript("game.UI.dialog.UnionVSBias")
--联盟战得分一览对话框
UnionBattleScoreListDialog = GMethod.loadScript("game.UI.dialog.UnionBattleScoreListDialog")
-- --联盟战斗日志对话框
UnionBattleLogDialog = GMethod.loadScript("game.UI.dialog.UnionBattleLogDialog")
--联盟战开启对话框
UnionBattleOpenDialog = GMethod.loadScript("game.UI.dialog.UnionBattleOpenDialog")
--联盟公告
UnionNoticeDialog= GMethod.loadScript("game.UI.dialog.UnionNoticeDialog")
--好友助战
UnionFriendAssistant = GMethod.loadScript("game.UI.dialog.UnionFriendAssistant")

--僵尸来袭对话框
zombieIncomingDialog= GMethod.loadScript("game.UI.dialog.zombieIncomingDialog")
--僵尸来袭挑战对话框
zombieIncomingChallengeDialog= GMethod.loadScript("game.UI.dialog.zombieIncomingChallengeDialog")
--完美通关宝箱对话框
PerfectChestDialog= GMethod.loadScript("game.UI.dialog.PerfectChestDialog")
--章节商店对话框
ChapterShopDialog=GMethod.loadScript("game.UI.dialog.ChapterShopDialog")
--使用体力药剂对话框
UsePhysicalAgentsDialog=GMethod.loadScript("game.UI.dialog.UsePhysicalAgentsDialog")
--扫荡对话框
Sweep2Dialog=GMethod.loadScript("game.UI.dialog.Sweep2Dialog")

--膜拜大神
WorshipDialog = GMethod.loadScript("game.UI.dialog.WorshipDialog")
--选择膜拜方式
WorshipChoseWayDialog = GMethod.loadScript("game.UI.dialog.WorshipChoseWayDialog")
--英雄试炼对话框
HeroTrialDialog=GMethod.loadScript("game.UI.dialog.heroTrial.HeroTrialDialog")
--英雄试炼查看对话框
HeroTrialSeeDialog=GMethod.loadScript("game.UI.dialog.heroTrial.HeroTrialSeeDialog")
--英雄试炼战斗记录对话框
HeroTrialBattleLogDialog=GMethod.loadScript("game.UI.dialog.heroTrial.HeroTrialBattleLogDialog")
--英雄试炼战队技能对话框
HeroTrialCorpsSkillDialog=GMethod.loadScript("game.UI.dialog.heroTrial.HeroTrialCorpsSkillDialog")
--英雄试炼布阵对话框
HeroTrialLineupDialog=GMethod.loadScript("game.UI.dialog.heroTrial.HeroTrialLineupDialog")
--部分技能变更描述
PartSkillChangeDialog = GMethod.loadScript("game.UI.dialog.PartSkillChangeDialog")
--推广码和奖励对话框
SpreadAndRewardDialog=GMethod.loadScript("game.UI.dialog.ActivityAndAchievement.SpreadAndRewardDialog")
--推广码领取宝石对话框
SpreadReceiveGemstoneDialog=GMethod.loadScript("game.UI.dialog.ActivityAndAchievement.SpreadReceiveGemstoneDialog")
--成就对话框
-- AchievementDialog=GMethod.loadScript("game.UI.dialog.ActivityAndAchievement.AchievementDialog")
AchievementDialog=GMethod.loadScript("game.UI.NewDialog.NewAchievementDialog")
--每日寻宝对话框
EverydayTreasureDialog=GMethod.loadScript("game.UI.dialog.ActivityAndAchievement.EverydayTreasureDialog")
--签到奖励对话框
SignRewardDialog=GMethod.loadScript("game.UI.dialog.ActivityAndAchievement.SignRewardDialog")
--首充礼包对话框
FirstChargePackageDialog=GMethod.loadScript("game.UI.dialog.ActivityAndAchievement.FirstChargePackageDialog")
--二次首充礼包对话框
TwoFirstFlushDialog=GMethod.loadScript("game.UI.dialog.ActivityAndAchievement.TwoFirstFlushDialog")
--排行榜
-- AllRankingListDialog=GMethod.loadScript("game.UI.dialog.AllRankingListDialog")
AllRankingListDialog=GMethod.loadScript("game.UI.NewDialog.NewAllRankingListDialog")
--进攻防守日志，收件箱
LogDialog=GMethod.loadScript("game.UI.dialog.systemDialog.LogDialog")
EmailDialog=GMethod.loadScript("game.UI.dialog.systemDialog.EmailDialog")
EmailUnionDialog=GMethod.loadScript("game.UI.dialog.systemDialog.EmailUnionDialog")
--战斗回放界面
playbackInterface = GMethod.loadScript("game.UI.interface.playbackInterface")
--战斗结束界面
ReplayAgainDialog = GMethod.loadScript("game.UI.dialog.ReplayAgainDialog")

--邀请好友开宝箱对话框
InviteFriendsOpenBoxDialog=GMethod.loadScript("game.UI.dialog.ActivityAndAchievement.InviteFriendsOpenBoxDialog")
--邀请好友奖励对话框
InviteFriendsRewardDialog=GMethod.loadScript("game.UI.dialog.ActivityAndAchievement.InviteFriendsRewardDialog")
--邀请好友对话框
InviteFriendsDialog=require("game.UI.dialog.ActivityAndAchievement.InviteFriendsDialog")

--领主头像
-- LordHeadDialog = GMethod.loadScript("game.UI.dialog.LordHeadDialog")
LordHeadDialog = GMethod.loadScript("game.UI.NewDialog.NewLordHeadDialog")
--头像列表
LordHeadListDialog = GMethod.loadScript("game.UI.dialog.LordHeadListDialog")
--系统设置
-- SystemSetDialog=GMethod.loadScript("game.UI.dialog.systemDialog.SystemSetDialog")
SystemSetDialog=GMethod.loadScript("game.UI.NewDialog.NewSystemSetDialog")
--语言设置
LanguageSetDialog=GMethod.loadScript("game.UI.dialog.systemDialog.LanguageSetDialog")
--连接与关联另一设备
RelatedEquipDialog=GMethod.loadScript("game.UI.dialog.systemDialog.RelatedEquipDialog")
--邮件
EmailDialog=GMethod.loadScript("game.UI.dialog.systemDialog.EmailDialog")

--战斗回放界面
playbackInterface=GMethod.loadScript("game.UI.interface.playbackInterface")

--游戏公告
GameAnnouncement =GMethod.loadScript("game.UI.dialog.GameAnnouncement")
--游戏更新
GameUpdateSuccess =GMethod.loadScript("game.UI.dialog.GameUpdateSuccess")
--服务器
ServerDialog=GMethod.loadScript("game.UI.dialog.ServerDialog")
--漫画对话框
CartoonDialog=GMethod.loadScript("game.UI.dialog.CartoonDialog")
ComicDialog = GMethod.loadScript("game.UI.dialog.ComicDialog")

--漫画展示
CartoonExhibition=GMethod.loadScript("game.UI.dialog.CartoonExhibition")

--拜访英雄
VisitHeroDialog=GMethod.loadScript("game.UI.dialog.VisitHeroDialog")

--新手引导
GuideHand=GMethod.loadScript("game.UI.dialog.GuideHand")

--排行榜
-- AllRankingListDialog=GMethod.loadScript("game.UI.dialog.AllRankingListDialog")
AllRankingListDialog=GMethod.loadScript("game.UI.NewDialog.NewAllRankingListDialog")
--排行榜奖励说明
RewardDescription=GMethod.loadScript("game.UI.dialog.RewardDescription")

--炼金对话框
MeltingDialog= GMethod.loadScript("game.UI.dialog.MeltingDialog")
--添加英雄熔炼对话框
MeltingAddHeroDialog=GMethod.loadScript("game.UI.dialog.MeltingAddHeroDialog")
--选择熔炼英雄对话框
MeltingChoseHeroDialog=GMethod.loadScript("game.UI.dialog.MeltingChoseHeroDialog")
--英雄礼包
HeroPackageDialog=GMethod.loadScript("game.UI.dialog.ActivityAndAchievement.HeroPackageDialog")

--助战英雄对话框
HeroAssistantDialog = GMethod.loadScript("game.UI.dialog.HeroAssistantDialog")
--设置阵容
SetBattleArrDialog = GMethod.loadScript("game.UI.dialog.SetBattleArrDialog")

--英雄升星对话框
UpgradeStartsDialog = GMethod.loadScript("game.UI.dialog.UpgradeStartsDialog")
--登陆战报
WarReportIn = GMethod.loadScript("game.UI.dialog.WarReportIn")
WarReportOut = GMethod.loadScript("game.UI.dialog.WarReportOut")
--竞技场查看阵容
SeeArenaArrDialog = GMethod.loadScript("game.UI.dialog.SeeArenaArrDialog")

--关注facebook对话框
FacebookDialog=GMethod.loadScript("game.UI.dialog.systemDialog.FacebookDialog")

--进攻防守日志，收件箱
PvcLogDialog=GMethod.loadScript("game.UI.dialog.systemDialog.PvcLogDialog")

--联盟战详细战报
UnionBattleDetailLogDialog=GMethod.loadScript("game.UI.dialog.UnionBattleDetailLogDialog")
--联盟战分配奖励
UnionBattleAssignRewardsDialog=GMethod.loadScript("game.UI.dialog.UnionBattleAssignRewardsDialog")
--举报
ReportDialog=GMethod.loadScript("game.UI.dialog.systemDialog.ReportDialog")
--facebook社群连接
CommunityDialog=GMethod.loadScript("game.UI.dialog.ActivityAndAchievement.CommunityDialog")
