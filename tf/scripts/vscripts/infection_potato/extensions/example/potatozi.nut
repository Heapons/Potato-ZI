/*
	work on base logic
		resource caches are highlighted and red gets some annotations explaining their use,
		also annotations explaining to distance from large groups of players

		every 5 minutes swap areas

	make the sickness debuff system
		it is not active during setup or waiting for players
	spawn sparse small ammo packs throughout the map
	use the same system ( with a rarer value ) to spawn 1 time powerups
	again the same system with rarer values for weapon pickups ( the model can be
	a pile of junk that gets highlighted when you get close or something )
		when you interact with it, the pile is consumed and you get a random super
		weapon for your class ( play the voiceline ), and you get highlighted with
		orange to make the enemy team target you more often ( blue will also
		get an annotation when you pick it up telling to target this person )
	make the zombie ghost system and controls
		zombies spawn normally during waiting for players,
			( no ground spawn, no ghost )
		in setup they spawn in their ghost state but cannot rise as zombies yet
		until round start
	make the zombie ground spawn logic
	copy over zombie abilities, etc from zi
*/

local TF_GAMERULES  = FindByClassname( null, "tf_gamerules" )
local TCP_MASTER    = null
local SKY_CAMERA    = null
local NAV_INTERFACE = null

local global_fog     = null
local global_cc      = null
local global_timer   = null
local global_win_red = null
local global_win_blu = null

// Creating this now instead of later allows it to override other non master controllers
local backup_fog = CreateByClassname( "env_fog_controller" )
::DispatchSpawn( backup_fog )

// These can die at the end of the frame of HandleMapSpawn
local MAPSPAWN_ENT_KILL_LIST = [
	"tf_logic_*", "bot_hint_*", "func_nav_*", "func_tfbot_hint", "item_*", "env_sun",
	"beam", "env_beam", "env_lightglow", "env_sprite", "env_soundscape*", "ambient_generic",
	"func_capturezone", "func_dustmotes", "func_smokevolume", "func_regenerate",
	"info_particle_system", "move_rope", "keyframe_rope", "func_respawnroomvisualizer",
	"trigger_capture_area",
]
// These must die immediately ( we need to create them )
local MAPSPAWN_ENT_DESTROY_LIST = [
	"color_correction", "team_round_timer", "game_round_win",
]

PZI_CREATE_SCOPE( "__pzi_potatozi_extension", "PZI_PotatoZI" )

PZI_PotatoZI.Players = {}
PZI_PotatoZI.InSetup   = true
PZI_PotatoZI.ZombieRatio = 0.2

// Balance teams with all players, or find a spot for player provided in args
function PZI_PotatoZI::BalanceTeams( player=null ) {

	// Sort into team tables
	local red   = []
	local blue  = []
	foreach ( p, n in Players ) {

		if ( !p ) continue

		local team = p.GetTeam()
		if ( team == 2 )
			red.append( p )
		else if ( team == 3 )
			blue.append( p )
	}

	local total = red.len() + blue.len()
	if ( total > 1 ) {

		local target_blue_count = ceil( total * ZombieRatio )
		if ( blue.len() != target_blue_count ) {

			local iters = target_blue_count - blue.len()
			local table = ( iters > 0 ) ? red : blue
			iters = abs( iters )

			if ( player )
				player.ForceChangeTeam( (table == red ) ? 3 : 2, false )
			else {

				local indexes = PZI_Misc.RandomUniqueInts( 0, table.len() - 1, iters )
				foreach ( i in indexes )
					table[i].ForceChangeTeam( (table == red ) ? 3 : 2, false )
			}
		}

		foreach ( p, n in Players ) {

			// Don't force unassigned to stay unassigned
			if ( !p.GetTeam() ) continue

			p.ValidateScriptScope()
			local scope = p.GetScriptScope()
			scope.assigned_team <- p.GetTeam()
		}
	}
	else if ( player ) {

		player.ForceChangeTeam( 2, false )

		player.ValidateScriptScope()
		local scope = player.GetScriptScope()
		scope.assigned_team <- player.GetTeam()
	}
}

function PZI_PotatoZI::HandleMapSpawn() {

	TF_GAMERULES  = FindByClassname( null, "tf_gamerules" )
	TCP_MASTER    = FindByClassname( null, "team_control_point_master" )
	SKY_CAMERA    = FindByClassname( null, "sky_camera" )
	NAV_INTERFACE = FindByClassname( null, "tf_point_nav_interface" )
	if ( !NAV_INTERFACE ) {

		NAV_INTERFACE = SpawnEntityFromTable( "tf_point_nav_interface", {
			targetname = "__potatozi_nav_interface",
		} )
	}
	EntFireByHandle( NAV_INTERFACE, "RecomputeBlockers", "", 1.0, null, null )
	EntFireByHandle( NAV_INTERFACE, "RecomputeBlockers", "", 5.0, null, null )

	Convars.SetValue( "mp_autoteambalance", 0 )
	Convars.SetValue( "mp_scrambleteams_auto", 0 )
	Convars.SetValue( "mp_teams_unbalance_limit", 0 )
	Convars.SetValue( "mp_tournament", 0 )
	Convars.SetValue( "mp_disable_respawn_times", 1 )

	local gmprops = [
		"m_bIsInTraining", "m_bIsWaitingForTrainingContinue", "m_bIsTrainingHUDVisible",
		"m_bIsInItemTestingMode", "m_bPlayingKoth", "m_bPlayingMedieval", "m_bPlayingHybrid_CTF_CP",
		"m_bPlayingSpecialDeliveryMode", "m_bPlayingRobotDestructionMode", "m_bPlayingMannVsMachine",
		"m_bIsUsingSpells", "m_bCompetitiveMode", "m_bPowerupMode", "m_nForceEscortPushLogic",
		"m_bBountyModeEnabled",
	]
	foreach ( prop in gmprops )
		SetPropBool( TF_GAMERULES, prop, false )

	// Open up the map
	for ( local ent = null; ent = FindByClassname( ent, "func_door*" ); ) {

		ent.AcceptInput( "Open", "", null, null )

		// Stay open
		ent.ValidateScriptScope()
		local scope = ent.GetScriptScope()
		scope.InputClose <- function() { return false; }
		scope.Inputclose <- scope.InputClose
	}
	for ( local ent = null; ent = FindByClassname( ent, "func_areaportal*" ); ) {

		ent.AcceptInput( "Open", "", null, null )

		// Stay open
		ent.ValidateScriptScope()
		local scope = ent.GetScriptScope()
		scope.InputClose <- function() { return false; }
		scope.Inputclose <- scope.InputClose
	}
	for ( local ent = null; ent = FindByClassname( ent, "func_respawnroom" ); ) {

		ent.AcceptInput( "Disable", "", null, null )
		ent.AcceptInput( "SetInactive", "", null, null )
	}

	// Remove most huds
	SetPropInt( TF_GAMERULES, "m_nHudType", 2 ); // Change to cp hud
	if ( TCP_MASTER ) {

		// Move it off screen
		SetPropFloat( TCP_MASTER, "m_flCustomPositionX", 1.0 )
		EntFireByHandle( TCP_MASTER, "RoundSpawn", "", 0, null, null )
	}
	// Deleting these with a tcp_master present crashes the game
	// todo disable again after setup?
	EntFire( "team_control_point", "Disable" )
	EntFire( "team_control_point", "HideModel" )

	SetSkyboxTexture( "sky_downpour_heavy_storm" )

	// Fog
	local old_fog = null
	for ( local ent = null; ent = FindByClassname( ent, "env_fog_controller" ); ) {

		// Note any previous fog from manual script loading
		if ( ent.GetName() == "__potatozi_fog" ) {

			old_fog = ent
			continue
		}
		// Hijack master fog controller ( it cannot be overriden or deleted )
		else if ( !global_fog && GetPropInt( ent, "m_spawnflags" ) == 1 ) {

			global_fog = ent
			continue
		}
		// Disable everything else
		ent.AcceptInput( "TurnOff", "", null, null )
		ent.AcceptInput( "Disable", "", null, null )
	}
	// Reuse old fog instead of creating a new one each time we load the script
	if ( old_fog && !global_fog )
		global_fog = old_fog
	if ( !global_fog )
		global_fog = backup_fog

	global_fog.KeyValueFromString( "targetname", "__potatozi_fog" )
	global_fog.KeyValueFromInt( "spawnflags", 1 )
	global_fog.KeyValueFromInt( "fogenable", 1 )
	global_fog.KeyValueFromFloat( "fogstart", 0.0 )
	global_fog.KeyValueFromFloat( "fogend", 2500.0 )
	global_fog.KeyValueFromFloat( "farz", 5000.0 )
	global_fog.KeyValueFromFloat( "fogmaxdensity", 1.0 )
	global_fog.KeyValueFromString( "fogcolor", "77 82 71" )
	global_fog.KeyValueFromInt( "fogblend", 0 )
	::DispatchSpawn( global_fog )

	// Skybox fog
	if ( SKY_CAMERA ) {

		SKY_CAMERA.KeyValueFromInt( "fogenable", 1 )
		SKY_CAMERA.KeyValueFromFloat( "fogstart", 0.0 )
		SKY_CAMERA.KeyValueFromFloat( "fogend", 0.0 )
		SKY_CAMERA.KeyValueFromFloat( "fogmaxdensity", 1.0 )
		SKY_CAMERA.KeyValueFromString( "fogcolor", "77 82 71" )
		SKY_CAMERA.KeyValueFromInt( "fogblend", 0 )
	}

	// Grab nav mesh
	if ( !PZI_NavMesh.ALL_AREAS.len() )
		NavMesh.GetAllAreas( PZI_NavMesh.ALL_AREAS )

	// Generate nav islands and sub areas within
	if ( !PZI_NavMesh.IslandsParsed ) {

		PZI_NavMesh.GenerateIslandAreas()

		// Pick a random island, area, and nav area to start with
		if ( PZI_NavMesh.ISLANDS.len() ) {

			// Island
			local index = RandomInt( 0, PZI_NavMesh.ISLANDS.len() - 1 )
			local island = PZI_NavMesh.ISLANDS[index]
			PZI_NavMesh.ActiveIsland = island

			// Area
			index = RandomInt( 0, PZI_NavMesh.ISLAND_AREAS[island].len() - 1 )
			local isl_area = PZI_NavMesh.ISLAND_AREAS[island][index]
			PZI_NavMesh.ActiveArea = isl_area

			// Nav area ( RED spawn )
			local area_red = PZI_NavMesh.GetRandomArea( isl_area, true )
			PZI_NavMesh.AreaSpawnRed = area_red

			// Nav area ( BLU spawn )
			local area_blue    = null
			local longest_dist = 0
			for ( local i = 0; i < 20; ++i ) {

				local a = PZI_NavMesh.GetRandomArea( isl_area, true )
				local dist = ( area_red.GetCenter() - a.GetCenter() ).Length()
				if ( dist > longest_dist ) {

					area_blue    = a
					longest_dist = dist
				}

				if ( dist > 2048.0 )
					break
			}
			PZI_NavMesh.AreaSpawnBlue = area_blue

			area_red.DebugDrawFilled( 255, 50, 0, 255, 5, true, 0 )
			area_blue.DebugDrawFilled( 50, 50, 200, 255, 5, true, 0 )

			// Kill old resource caches
			for ( local ent = null; ent = FindByName( ent, "__potatozi_resource_cache*" ); )
				ent.AcceptInput( "Kill", "", null, null )

			// How many we create is based on the size of the island
			local count = ceil( island.len() / 100.0 )

			// todo need to store these to associate them with areas
			// todo check distance to make sure we arent spawning too close / on same area
			// todo add size check if we might be blocking a doorway?
			// todo also dont choose near spawn point
			// Spawn resource caches across the island
			for ( local i = 0; i < count; ++i ) {

				local area = PZI_NavMesh.GetRandomArea( island, true )
				area.DebugDrawFilled( 50, 200, 0, 255, 5, true, 0 )

				SpawnEntityFromTable( "prop_dynamic", {
					targetname = format( "__potatozi_resource_cache%d", i ),
					model = "models/props_spytech/radio_tower001.mdl",
					modelscale = 0.1,
					origin = area.GetCenter(),
				} )
			}
		}
	}

	//BalanceTeams()

	for ( local ent = null; ent = FindByClassname( ent, "obj*" ); ) {

		if ( !GetPropEntity( ent, "m_hBuilder" ) ) continue
		ent.AcceptInput( "Kill", "", null, null )
	}

	foreach ( player, n in Players ) {

		if ( !player ) continue

		player.ValidateScriptScope()
		local scope = player.GetScriptScope()

		scope.assigned_team <- null

		// Maps like to use this input and it fucks with our fog
		// todo put this in a function since we need to also do it on player activate
		// also put it at the bottom of the script for late load
		scope.InputSetFogController <- function() {
			if ( caller != global_fog )
				return false
		}
		scope.Inputsetfogcontroller <- scope.InputSetFogController

		if ( SKY_CAMERA ) {

			SetPropFloat( player, "m_Local.m_skybox3d.fog.start", 0.0 )
			SetPropFloat( player, "m_Local.m_skybox3d.fog.maxdensity", 1.0 )
			SetPropFloat( player, "m_Local.m_skybox3d.fog.end", 0.0 )
			SetPropBool( player, "m_Local.m_skybox3d.fog.enable", true )
			SetPropInt( player, "m_Local.m_skybox3d.fog.colorPrimary", 5067335 )
			SetPropBool( player, "m_Local.m_skybox3d.fog.blend", false )
		}

		player.ForceRespawn()
	}

	// Commit mass murder
	// ..immediately
	local del = []
	foreach ( target in MAPSPAWN_ENT_DESTROY_LIST )
		for ( local ent = null; ent = FindByClassname( ent, target ); )
			del.append( ent )
	foreach ( ent in del )
		ent.Destroy()

	// ..at the end of the frame
	foreach ( target in MAPSPAWN_ENT_KILL_LIST )
		EntFire( target, "Kill" )

	// Color correction
	global_cc = SpawnEntityFromTable( "color_correction", {
		targetname = "__potatozi_cc",
		minfalloff = -1,
		maxfalloff = -1,
		filename   = "materials/correction/ravenous.raw",
	} )

	global_timer = SpawnEntityFromTable( "team_round_timer", {
		targetname   = "__potatozi_timer",
		start_paused = 0,
		reset_time   = 1,
		show_in_hud  = 1,
		max_length   = 900,
		timer_length = 900,
		setup_length = 30,
	} )
	global_timer.AcceptInput( "Resume", "", null, null )
	EntityOutputs.AddOutput( global_timer, "OnFinished", "__potatozi_win_red", "RoundWin", "", 0, -1 )

	global_win_red = SpawnEntityFromTable( "game_round_win", {
		targetname      = "__potatozi_win_red",
		force_map_reset = 1,
		switch_teams    = false,
		TeamNum         = 2,
	} )

	global_win_blu = SpawnEntityFromTable( "game_round_win", {
		targetname      = "__potatozi_win_blu",
		force_map_reset = 1,
		switch_teams    = false,
		TeamNum         = 3,
	} )
}
PZI_EVENT( "player_activate", "PZI_PlayerActivate", function( params ) {
	local player = GetPlayerFromUserID( params.userid )
	if ( !player ) return

	PZI_PotatoZI.Players[player] <- null
} )

PZI_EVENT( "player_disconnect", "PZI_PlayerDisconnect", function( params ) {

	local player = GetPlayerFromUserID( params.userid )
	if ( !player ) return

	if ( player in PZI_PotatoZI.Players )
		delete PZI_PotatoZI.Players[player]
} )

PZI_EVENT( "player_team", "PZI_PlayerTeam", function( params ) {
	/*
	if ( InSetup ) return

	// While round is active:

	local player = GetPlayerFromUserID( params.userid )
	if ( !player ) return

	player.ValidateScriptScope()
	local scope = player.GetScriptScope()

	// Unassigned gets sent to spectator
	if ( !params.oldteam )
		scope.assigned_team <- 1
	// Red team can join spectator / blue mid round if they want
	else if ( params.oldteam == 2 )
		return

	if ( "assigned_team" in scope )
		if ( scope.assigned_team != params.team )
			EntFireByHandle( player, "RunScriptCode", "self.ForceChangeTeam( assigned_team, false ); self.ForceRespawn()", 0.015, null, null )
	*/
} )

PZI_EVENT( "player_spawn", "PZI_PlayerSpawn", function( params ) {
	local player = GetPlayerFromUserID( params.userid )
	if ( !player ) return

	// Teleport to spawn points
	local area = null
	local team = player.GetTeam()
	if ( team == 2 ) area = PZI_NavMesh.AreaSpawnRed
	else if ( team == 3 ) area = PZI_NavMesh.AreaSpawnBlue
	if ( area ) {

		local center = area.GetCenter()
		center.z += 24

		player.KeyValueFromVector( "origin", center )
		player.SetAbsVelocity( Vector() )

		// Face center of world
		local ang = PZI_Misc.VectorAngles( PZI_Misc.GetWorldCenter() - player.EyePosition() )
		ang.x = 0
		player.SnapEyeAngles( ang )
	}
} )

PZI_EVENT( "post_inventory_application", "PZI_PostInventoryApplication", function( params ) {

	local player = GetPlayerFromUserID( params.userid )

	if ( player.IsEFlagSet( EFL_IS_BEING_LIFTED_BY_BARNACLE ) ) 
		return

	player.ValidateScriptScope()
	local scope = player.GetScriptScope()

	player.AcceptInput( "SetFogController", "__potatozi_fog", global_fog, global_fog )

	// todo after winning a round spawning as red from blue makes you not have your weapons
	/*
	local team  = player.GetTeam()
	local melee = null
	for ( local child = player.FirstMoveChild(); child != null; child = child.NextMovePeer() ) {

		if ( child instanceof CBaseCombatWeapon && child.GetSlot() == 2 ) melee = child

		if ( !child || !child.IsValid() ) continue
		if ( child.GetClassname() == "tf_viewmodel" ) continue
		if ( team == 2 && child instanceof CBaseCombatWeapon ) continue
		if ( team == 3 && child == melee ) continue

		EntFireByHandle( child, "Kill", "", 0, null, null )
	}

	if ( team == 3 && melee )
		player.Weapon_Switch( melee )
	*/
} )

PZI_EVENT( "player_death", "PZI_PlayerDeath", function( params ) {
	/*
	local player = GetPlayerFromUserID( params.userid )
	if ( !player ) return

	player.ValidateScriptScope()
	local scope = player.GetScriptScope()

	local team = player.GetTeam()
	if ( !InSetup && team == 2 ) {

		scope.assigned_team <- 3
		EntFireByHandle( player, "RunScriptCode", "self.ForceChangeTeam( 3, false );", 0.015, null, null )
	}
	*/
} )

PZI_EVENT( "teamplay_setup_finished", "PZI_TeamplaySetupFinished", function( params ) {
	PZI_PotatoZI.InSetup = false

	//BalanceTeams()
	/*
	foreach ( player, n in Players )
		player.ForceRespawn()
	*/
} )

PZI_EVENT( "teamplay_round_start", "PZI_TeamplayRoundStart", function( params ) {
	PZI_PotatoZI.InSetup = true
	PZI_PotatoZI.HandleMapSpawn()
} )

// function OnScriptHook_OnTakeDamage( params )
// {
// 	if ( InSetup )
// 	{
// 		params.damage = 0
// 		params.early_out = true
// 		return
// 	}
// }

function PZI_PotatoZI::ThinkTable::PotatoZIThink() {

	local tickcount = Time() / 0.015

	// Pause the setup timer if there's only one person
	if ( PZI_PotatoZI.InSetup ) {

		if ( global_timer ) {

			local paused = GetPropBool( global_timer, "m_bTimerPaused" )
			if ( PZI_PotatoZI.Players.len() < 2 && !paused )
				global_timer.AcceptInput( "Pause", "", null, null )
			else if ( PZI_PotatoZI.Players.len() > 1 && paused )
				global_timer.AcceptInput( "Resume", "", null, null )
		}
	}
	else {

		if ( !(tickcount % 11) ) {

			local reds_dead  = true
			local blue_empty = true
			foreach ( player, n in PZI_PotatoZI.Players ) {

				if ( player.GetTeam() == 2 )
					reds_dead = false
				else if ( player.GetTeam() == 3 )
					blue_empty = false

				if ( !reds_dead && !blue_empty )
					break
			}

			if ( reds_dead )
				global_win_blu.AcceptInput( "RoundWin", "", null, null )
			else if ( blue_empty )
				global_win_red.AcceptInput( "RoundWin", "", null, null )
		}
	}

	return -1
}

// Late load
if ( TF_GAMERULES ) {

	for ( local i = 1, player; i <= MAX_CLIENTS; player = PlayerInstanceFromIndex( i ), i++ ) {

		if ( !player ) continue

		PZI_PotatoZI.Players[player] <- {}
		player.ValidateScriptScope()
	}
	PZI_PotatoZI.HandleMapSpawn()
}
