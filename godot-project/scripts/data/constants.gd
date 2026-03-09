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
	PRAGMATIC
}

enum DiplomacyAction {
	GIFT,
	TRADE,
	REQUEST_ALLIANCE,
	DECLARE_WAR,
	OFFER_PEACE,
	DEMAND_TRIBUTE,
	REFUSE,
	CANCEL_DEAL
}

enum BattleType {
	RAID,
	INVASION
}

enum GameState {
	PLAYING,
	VICTORY,
	DEFEAT
}
