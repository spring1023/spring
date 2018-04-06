local GameEvent = Event
Event.init()
_G["GameEvent"] = GameEvent

GameEvent.addEvent({"EventFocus","EventBuyBuild","EventBuildMove","EventBuilderCome", "EventBuilderGo", 
    "EventStartPlan","EventEndPlan", "EventPlanMode", "EventPlanItem", "EventPlanSeted", "EventPlanRecovery",
    "EventBattleBegin", "EventBattleTouch", "EventFreshUnionMenu", "EventVisitBegin", "addKncokGuide", 
    "openKnockGetInfo", "showKnockTip", "KonckRefreshReward", "DelYouthDayGuide"})
