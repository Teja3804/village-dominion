extends RefCounted
class_name GameConstants

## Central IDs and enums for Village Dominion. Single source of truth for type IDs.
## Used by definitions, runtime state, and save/load. Do not store runtime state here.

enum ResourceType {
	NONE,
	FOOD,
	WOOD,
	STONE,
	GOLD,
	IRON
}

enum BuildingType {
	NONE,
	TOWN_HALL,
	FARM,
	LUMBER_CAMP,
	QUARRY,
	BARRACKS,
	HOUSE,
	WAREHOUSE,
	MARKET,
	WALL
}

enum PersonalityType {
	NONE,
	AGGRESSIVE,
	CAUTIOUS,
	MERCANTILE,
	PROUD,
	PRAGMATIC,
	# AI simulation personalities (used by AIManager)
	DIPLOMATIC,
	TRADER,
	OPPORTUNIST
}

enum DiplomacyAction {
	GIFT,
	TRADE,
	REQUEST_ALLIANCE,
	DECLARE_WAR,
	OFFER_PEACE,
	DEMAND_TRIBUTE,
	REFUSE,
	CANCEL_DEAL,
	REQUEST_AID
}

enum BattleType {
	RAID,
	INVASION
}

enum BattleResult {
	VICTORY,   # attacker wins
	DEFEAT,    # defender wins
	DRAW
}

enum GameState {
	PLAYING,
	VICTORY,
	DEFEAT
}

enum WorldEventType {
	FAMINE,
	BANDIT_RAID,
	HARVEST_FESTIVAL,
	POLITICAL_DISPUTE,
	TRADE_BOOM
}
