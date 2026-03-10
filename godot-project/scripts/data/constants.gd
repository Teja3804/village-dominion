## constants.gd
## Central constants file for Village Dominion

extends Node

# Resource Types
enum Resource {
	FOOD,
	WOOD,
	STONE,
	GOLD,
	WEAPONS
}

const RESOURCE_NAMES: Dictionary = {
	Resource.FOOD: "Food",
	Resource.WOOD: "Wood",
	Resource.STONE: "Stone",
	Resource.GOLD: "Gold",
	Resource.WEAPONS: "Weapons"
}

# Building Types
enum BuildingType {
	TOWN_HALL,
	HOUSE,
	FARM,
	LUMBER_MILL,
	QUARRY,
	MARKET,
	BARRACKS,
	BLACKSMITH,
	WALLS,
	WATCHTOWER,
	WAREHOUSE,
	TEMPLE
}

const BUILDING_NAMES: Dictionary = {
	BuildingType.TOWN_HALL: "Town Hall",
	BuildingType.HOUSE: "House",
	BuildingType.FARM: "Farm",
	BuildingType.LUMBER_MILL: "Lumber Mill",
	BuildingType.QUARRY: "Quarry",
	BuildingType.MARKET: "Market",
	BuildingType.BARRACKS: "Barracks",
	BuildingType.BLACKSMITH: "Blacksmith",
	BuildingType.WALLS: "Walls",
	BuildingType.WATCHTOWER: "Watchtower",
	BuildingType.WAREHOUSE: "Warehouse",
	BuildingType.TEMPLE: "Temple"
}

# AI Personality Types
enum Personality {
	AGGRESSIVE,
	DIPLOMATIC,
	TRADER,
	OPPORTUNIST,
	ISOLATIONIST
}

const PERSONALITY_NAMES: Dictionary = {
	Personality.AGGRESSIVE: "Aggressive",
	Personality.DIPLOMATIC: "Diplomatic",
	Personality.TRADER: "Trader",
	Personality.OPPORTUNIST: "Opportunist",
	Personality.ISOLATIONIST: "Isolationist"
}

# Relationship States
enum RelationState {
	WAR,
	HOSTILE,
	NEUTRAL,
	FRIENDLY,
	ALLIED
}

# Thresholds for relationship states
const RELATION_WAR: int = -80
const RELATION_HOSTILE: int = -30
const RELATION_FRIENDLY: int = 30
const RELATION_ALLIED: int = 70

# Diplomacy Actions
enum DiplomacyAction {
	DECLARE_WAR,
	PROPOSE_PEACE,
	PROPOSE_ALLIANCE,
	BREAK_ALLIANCE,
	SEND_GIFT,
	REQUEST_AID,
	PROPOSE_TRADE,
	CANCEL_TRADE,
	THREATEN,
	SEND_SPY
}

# Battle outcomes
enum BattleOutcome {
	ATTACKER_WINS,
	DEFENDER_WINS,
	DRAW,
	ATTACKER_CAPTURES
}

# Game events
enum EventType {
	FAMINE,
	PLAGUE,
	BANDIT_ATTACK,
	BUMPER_HARVEST,
	GOLD_RUSH,
	REBELLION,
	FESTIVAL,
	EARTHQUAKE,
	TRADE_ROUTE_DISRUPTED,
	WANDERING_TRADER,
	POLITICAL_CONFLICT,
	MIGRATION
}

# Game balance constants
const STARTING_FOOD: int = 200
const STARTING_WOOD: int = 150
const STARTING_STONE: int = 100
const STARTING_GOLD: int = 50
const STARTING_WEAPONS: int = 20

const FOOD_PER_VILLAGER: float = 0.5
const MAX_STORAGE_BASE: int = 500

const SOLDIER_UPKEEP_GOLD: int = 1  # per soldier per turn
const ATTACK_RANDOMNESS: float = 0.2  # ±20% random variance in combat

const MAX_VILLAGES: int = 8
const TURNS_PER_YEAR: int = 12
const MAX_TURNS: int = 120  # 10 years

const RELATION_CHANGE_GIFT: int = 10
const RELATION_CHANGE_TRADE: int = 5
const RELATION_CHANGE_WAR_WIN: int = -20
const RELATION_CHANGE_WAR_LOSE: int = -10
const RELATION_CHANGE_AID: int = 15
const RELATION_CHANGE_THREAT: int = -15
const RELATION_DECAY_PER_TURN: int = 1  
