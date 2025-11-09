PZI_CREATE_SCOPE( "__PZI_MapLogic", "PZI_MapLogic", null, "PZI_MapLogicThink" )

// Strip all logic from all maps to replace with ZI logic
SetValue( "mp_autoteambalance", 0 )
SetValue( "mp_scrambleteams_auto", 0 )
SetValue( "mp_teams_unbalance_limit", 0 )
SetValue( "mp_tournament", 0 )
SetValue( "mp_respawnwavetime", 2 )

local BASE_RESPAWN_TIME = 3.0
::LOCALTIME <- {}
LocalTime(LOCALTIME)

//TODO: move this somewhere more fitting than the map logic scripts
::SERVER_DATA <- {

	endpoint_url			  = "https://archive.potato.tf/api/serverstatus"
	server_name				  = ""
	server_key				  = ""
    server_tags               = GetStr( "sv_tags" )
	address					  = 0
	wave 					  = 0
	max_wave				  = -1
	players_blu				  = 0
	players_connecting		  = 0
	players_max				  = MaxClients().tointeger()
	players_red				  = 0
	matchmaking_disable_time  = 0
	map					      = GetMapName()
	mission					  = "Zombie Infection"
	region					  = ""
	password 				  = ""
	classes					  = ""
    domain 					  = GetStr( "sv_downloadurl" )
	campaign_name 			  = "Other Gamemodes"
	status 					  = "Eating your brains..."
	// in_protected_match		  = false
	// is_fake_ip				  = false
	// steam_ids				  = []

	// update_time 			  = {
	// 	year	= LOCALTIME.year
	// 	month	= LOCALTIME.month
	// 	day		= LOCALTIME.day
	// 	hour	= LOCALTIME.hour
	// 	minute	= LOCALTIME.minute
	// 	second	= LOCALTIME.second
	// }
}

PZI_MapLogic.payload_tracks <- {}

local gamemode_funcs = {

    // delete payload cart and tracks
    function PL() {

        EntFire( "mapobj_cart_dispenser", "Kill" )

        local tracks = {}
        local first, last, prev, altpath, altname

        local function _altpath() {

            if ( altpath ) {

                tracks[ altpath ] <- altpath.GetName()

                if ( altpath = GetPropEntity( altpath, "m_paltpath" ) )
                    tracks[ altpath ] <- altpath.GetName()                    

                while ( altpath = GetPropEntity( altpath, "m_pnext" ) ) {

                    if ( altpath == first )
                        continue

                    tracks[ altpath ] <- altpath.GetName()
                }
            }

            if ( altname != "" )
                while ( altpath = FindByName( altpath, altname ) )
                    tracks[ altpath ] <- altname
        }

        // grab the tracks and cart entity from the watcher
        // NOTE: deleting stuff related to team_train_watcher crashes the game for many reasons!
        // bot logic and other things try to read team_train_watcher properties and get NULL ptrs for missing tracks etc.

        local cart_stuff = []
        for ( local watcher, cart; watcher = FindByClassname( watcher, "team_train_watcher" ); ) {

            while ( cart = FindByName( cart, GetPropString( watcher, "m_iszTrain" ) ) ) {

                cart_stuff.append( cart )

                for ( local child = cart.FirstMoveChild(); child; child = child.NextMovePeer() )
                    cart_stuff.append( child )
            }

            // grab the start and end tracks
            while ( first = FindByName( first, GetPropString( watcher, "m_iszStartNode" ) ) )
                break
            while ( last = FindByName( last, GetPropString( watcher, "m_iszGoalNode" ) ) )
                break

            prev  = GetPropEntity( last, "m_pprevious" )

            altpath = GetPropEntity( prev, "m_paltpath" )
            altname = GetPropString( prev, "m_altName" )

            foreach ( path in [ altpath, first, last, prev ] ) {

                if ( !path || !path.IsValid() )
                    continue

                altpath = GetPropEntity( path, "m_paltpath" )
                altname = GetPropString( path, "m_altName" )
                _altpath()
            }

            if ( prev )
                tracks[ prev ] <- prev.GetName()

            // iterate backwards to the starting node
            while ( prev = GetPropEntity( prev, "m_pprevious" ) ) {

                if ( prev == first ) {

                    // keep start/end and link them together to keep working bot logic
                    // delete every track in between
                    SetPropEntity( first, "m_pnext", last )
                    continue
                }

                tracks[ prev ] <- prev.GetName()
                altpath = GetPropEntity( prev, "m_paltpath" )
                altname = GetPropString( prev, "m_altName" )
                _altpath()
            }
        }

        PZI_MapLogic.payload_tracks <- tracks

        foreach ( cart in cart_stuff ) {

            cart.DisableDraw()
            SetPropInt( cart, "m_clrRender", 0 )
            cart.AcceptInput( "Disable", null, null, null )
            SetPropInt( cart, "m_nRenderMode", kRenderTransColor )
            SetPropBool( cart, "m_bGlowEnabled", false )

            cart.SetSolid( SOLID_NONE )
            cart.SetSolidFlags( FSOLID_NOT_SOLID )
            cart.SetCollisionGroup( COLLISION_GROUP_DEBRIS )

            cart.AddFlag( FL_DONTTOUCH )
            cart.AddEFlags( EFL_NO_THINK_FUNCTION|EFL_NO_GAME_PHYSICS_SIMULATION )
        }
    
        // PZI_Util.EntShredder.extend( tracks.keys() )
    }

    // delete mvm entities
    function MvM() {

        foreach( ent in [ "func_capturezone", "info_populator", "tf_logic_mann_vs_machine" ] )
            EntFire( ent, "Kill" )

        PZI_Util.ScriptEntFireSafe( "item_teamflag", @"

            AddOutput( self, `OnPickup`, `item_teamflag`, `ForceResetSilent`, null, 0, -1 )

            self.ValidateScriptScope()

            self.SetModelSimple( `models/empty.mdl` )
            self.DisableDraw()
            self.AddFlag( FL_DONTTOUCH )

            // move me around to make bots move around the map more.
            function FlagMoveThink() {

                self.SetAbsOrigin( PZI_Nav.GetRandomSafeArea().GetCenter() )
                self.AcceptInput( `ForceResetSilent`, null, null, null )
                SetPropBool( self, `m_bGlowEnabled`, false )
                return 10.0
            }

            self.GetScriptScope().FlagMoveThink <- FlagMoveThink
            AddThinkToEnt( self, `FlagMoveThink` )
        ")
    }

    function PD() {

        EntFire( "func_capturezone", "Kill" )

        PZI_EVENT( "player_death", "PZI_MapLogic_PlayerDeath", function ( params ) {

            EntFire( "item_teamflag", "Kill" )
        })
    }
}

gamemode_funcs.RD  <- gamemode_funcs.PD
gamemode_funcs.PLR <- gamemode_funcs.PL
gamemode_funcs.CTF <- gamemode_funcs.MvM

// disable gamemode logic
local gamemode_props = [

    "m_bIsInTraining"
    "m_bIsWaitingForTrainingContinue"
    "m_bIsTrainingHUDVisible"
    "m_bIsInItemTestingMode"
    "m_bPlayingKoth"
    "m_bPlayingMedieval"
    "m_bPlayingHybrid_CTF_CP"
    "m_bPlayingSpecialDeliveryMode"
    "m_bPlayingRobotDestructionMode"
    "m_bPlayingMannVsMachine"
    "m_bIsUsingSpells"
    "m_bCompetitiveMode"
    "m_bPowerupMode"
    "m_nForceEscortPushLogic"
    "m_bBountyModeEnabled"
]

foreach ( prop in gamemode_props )
    SetPropBool( PZI_Util.GameRules, prop, false )

try { IncludeScript( "infection_potato/map_logic/" + MAPNAME, ROOT ) } catch ( e ) { printl( e ) }
IncludeScript( "infection_potato/map_logic/kill_doors", ROOT )

local ents_to_kill = [

    // passtime
    "passtime*"
    "func_passtime*"
    "info_passtime*"
    "trigger_passtime*"

    // logic/gameplay ents
    "tf_robot*"
    "tf_logic_*"
    "info_powerup*"
    "item_powerup*"
    "func_regenerate"
    "func_capturezone"
    "trigger_capture_area"
    "func_respawnroomvisualizer"

    // misc edict wasters
	"beam" // light glow effect on all lights
    "env_sun" // sun
    "env_beam"
    "move_rope"
    "env_sprite"
    "game_text_tf"
    "env_lightglow"
    "keyframe_rope"
]

local logic_ents = {

    tf_logic_koth                    = "KOTH"
    tf_logic_arena                   = "Arena"
    tf_logic_medieval                = "Medieval"
    tf_logic_bounty_mode             = "Bounty"
    tf_logic_hybrid_ctf_cp           = "CTF/CP"
    tf_logic_mann_vs_machine         = "MvM"
    tf_logic_multiple_escort         = "PLR"
    tf_logic_special_delivery_mode   = "SD"
    tf_logic_robot_destruction_mode  = "RD"
    tf_logic_player_destruction_mode = "PD"
}

// local spawns = []

// for ( local spawn; spawn = FindByClassname( spawn, "info_player_teamspawn" ); ) {

//     // SetPropInt( spawn, "m_iTeamNum", TEAM_UNASSIGNED )

//     if ( spawn.GetName() == "" )
//         SetPropString( spawn, STRING_NETPROP_NAME, format( "teamspawn_%d", spawn.entindex() ) )

//     spawns.append( spawn.GetName() )
// }

PZI_Util.ScriptEntFireSafe("__pzi_util", @"

	local server_name  = GetStr(`hostname`)

	SERVER_DATA.server_name = server_name
    SERVER_DATA.server_tags = GetStr(`sv_tags`)
	SERVER_DATA.server_key	= GetServerKey( server_name )
	SERVER_DATA.region		= GetServerRegion( server_name )

	if ( SERVER_DATA.domain == `ustx.potato.tf` )
		SERVER_DATA.domain += `:22443`

", 5)

function PZI_Util::GetServerKey( hostname = SERVER_DATA.server_name ) { return strip( hostname.slice( hostname.find("#") + 1, hostname.find(" [") ) ) }
function PZI_Util::GetServerRegion( hostname = SERVER_DATA.server_name ) { return strip( hostname.slice( hostname.find("[") + 1, hostname.find("]") ) ) }

if ( !PZI_Util.IsLinux ) {
    function PZI_Util::GetServerKey( ... ) { return "-1" }
    function PZI_Util::GetServerRegion( ... ) { return "US" }
}

local function GetGamemode() {

    local ent
    while ( ent = FindByClassname( ent, "tf_logic*" ) )
        if ( ent.GetClassname() in logic_ents )
            return logic_ents[ ent.GetClassname() ]

    while ( ent = FindByClassname( ent, "team_train_watcher" ) )
        return "PL"

    while ( ent = FindByClassname( ent, "passtime_logic" ) )
        return "PASS"

    while ( ent = FindByClassname( ent, "item_teamflag" ) ) {

        for ( local spawner; spawner = FindByClassname( spawner, "info_powerup_spawn" ); )
            return "Mannpower"

        for ( local cap; cap = FindByClassname( cap, "func_capturezone" ); )
            return "CTF"
    }

    return split( MAPNAME, "_" )[0].toupper()
}

local GAMEMODE = GetGamemode()

function PZI_MapLogic::GetRoundTimer[this]( replace = false ) {

    local timer

    if ( !replace )
        while ( timer = FindByName( timer, "__pzi_timer" ) )
            return timer

    for ( local _timer; _timer = FindByClassname( _timer, "team_round_timer" ); )
        EntFireByHandle( _timer, "Kill", null, -1, null, null )

    timer = SpawnEntityFromTable( "team_round_timer", {

        targetname          = "__pzi_timer"
        vscripts            = " "
        auto_countdown      = 1
        max_length          = 180
        reset_time          = 1
        setup_length        = 45
        show_in_hud         = 1
        force_map_reset     = true
        show_time_remaining = 1
        start_paused        = 0
        timer_length        = 120
        StartDisabled       = 0
        "OnFinished#1"      : "__pzi_util,CallScriptFunction,RoundWin,0,-1"
        "OnSetupFinished#1" : "self,RunScriptCode,base_timestamp = Time() + 240,1,-1"
    })

    if ( PlayerCount(TEAM_HUMAN) + PlayerCount(TEAM_ZOMBIE) )
        EntFire( "__pzi_timer", "Resume", null, 1 )

    local scope = timer.GetScriptScope()
    scope.end_timestamp <- GetPropFloat( timer, "m_flTimerEndTime" )
    scope.time_left <- scope.end_timestamp - Time()

    if ( "VPI" in ROOT )
    {
        function TimerThink()
        {
            time_left = (end_timestamp - Time()).tointeger()
            if ( !(time_left % 10) )
            {
                local players = PlayerCount( TEAM_HUMAN ) + PlayerCount( TEAM_ZOMBIE )

                if ( players <= 1 )
                    timer.AcceptInput("SetTime", "30", null, null)

                // LocalTime(LOCALTIME)
                // SERVER_DATA.update_time = LOCALTIME
                SERVER_DATA.max_wave = end_timestamp
                SERVER_DATA.wave = time_left
                SERVER_DATA.server_name = GetStr("hostname")
                SERVER_DATA.server_tags = GetStr("sv_tags")

                SERVER_DATA.domain = GetStr( "sv_downloadurl" )
                if ( 7 in SERVER_DATA.domain )
                    SERVER_DATA.domain = SERVER_DATA.domain.slice( 7, SERVER_DATA.domain.find( "/gameassets" ) )

                if ( SERVER_DATA.server_key == "" )
                    SERVER_DATA.server_key = PZI_Util.GetServerKey( SERVER_DATA.server_name )

                if ( SERVER_DATA.region == "" )
                    SERVER_DATA.region = PZI_Util.GetServerRegion( SERVER_DATA.server_name )

                local players = array(2, 0)
                local spectators = 0
                foreach ( player, userid in PZI_Util.PlayerTables.All ) {

                    if ( !player || !player.IsValid() )
                        continue

                    if ( player.GetTeam() == TEAM_SPECTATOR )
                        spectators++
                    else if ( !player.IsBotOfType( TF_BOT_TYPE ) )
                        players[player.GetTeam() == TEAM_HUMAN ? 0 : 1]++
                }

                SERVER_DATA.players_red = players[0]
                SERVER_DATA.players_blu = players[1]
                SERVER_DATA.players_connecting = spectators

                VPI.AsyncCall({
                    func   = "VPI_UpdateServerData"
                    kwargs = SERVER_DATA

                    // callback = function(response, error) {

                    //     assert(!error)

                    //     if (SERVER_DATA.address == 0 && "address" in response)
                    //         SERVER_DATA.address = response.address
                    // }
                })
                return 1.1
            }
            return -1
        }

        function UpdateTimestamp() { return end_timestamp = GetPropFloat( timer, "m_flTimerEndTime" ), time_left = end_timestamp - Time() }

        scope.InputSetTime <- UpdateTimestamp
        scope.Inputsettime <- UpdateTimestamp
        scope.InputAddTime <- UpdateTimestamp
        scope.Inputaddtime <- UpdateTimestamp

        scope.TimerThink <- TimerThink
        AddThinkToEnt(timer, "TimerThink")
    }
    return timer
}

local timer = PZI_MapLogic.GetRoundTimer()

local doors = ["func_door*", "func_areaportal*"]
local cls   = ["prop_dynamic", "func_brush"]
local nearest

local round_start_relay_table = {

    targetname = "__pzi_round_start_relay"
    spawnflags = 1
    "OnTrigger#1" : "func_areaportal*,Open,,0,-1"
    "OnTrigger#2" : "__pzi_nav_interface,RecomputeBlockers,,0,-1"
    // "OnTrigger#3" : "team_control_point,Disable,,0,-1" // keep these enabled so bots know what to do
    "OnTrigger#4" : "tf_pumpkin_bomb,RunScriptCode,if ( self.IsValid() ) self.TakeDamage( INT_MAX DMG_GENERIC null ),,0,-1"
    "OnTrigger#5" : "team_control_point,SetOwner,0,1,-1"
    "OnTrigger#6" : "team_control_point,HideModel,,0,-1"
}

local setup_finished_relay_table = {

    targetname = "__pzi_setup_finished_relay"
    spawnflags = 1
    "OnSpawn#1" : "func_areaportal*,Open,,0,-1"
    "OnSpawn#2" : "__pzi_nav_interface,RecomputeBlockers,,0,-1"
    "OnSpawn#3" : "func_respawnroom,Disable,,0,-1"
    "OnSpawn#4" : "func_respawnroom,SetInactive,,0,-1"
    "OnSpawn#5" : "func_regenerate,Kill,,0,-1"
    // "OnSpawn#6" : "team_control_point,SetOwner,0,1,-1"
}

function PZI_MapLogic::ThinkTable::KillWastefulEnts() {
    
    // face flexes/animations for vo/pain feedback
    for ( local scene; scene = FindByClassname( scene, "instanced_scripted_scene" ); )
        PZI_Util.EntShredder.append( scene )
}

PZI_EVENT( "teamplay_round_start", "PZI_MapLogic_RoundStart", function ( params ) {

    if ( GAMEMODE in gamemode_funcs )
        gamemode_funcs[ GAMEMODE ]()

    // kill these immediately
    for ( local ent; ent = FindByClassname( ent, "team_round_timer" ); )
        EntFireByHandle( ent, "Kill", null, -1, null, null )

    for ( local ent; ent = FindByClassname( ent, "game_round_win" ); )
        EntFireByHandle( ent, "Kill", null, -1, null, null )

    local _relay = SpawnEntityFromTable( "logic_relay", round_start_relay_table )

    foreach( name in ents_to_kill )
        AddOutput( _relay, "OnTrigger", name, "Kill", null, 0, -1 )

    EntFireByHandle( _relay, "Trigger", null, 0.2, null, null )

    timer = PZI_MapLogic.GetRoundTimer()

    // Disables most huds
    SetPropInt( PZI_Util.GameRules, "m_nHudType", 2 )

    // disable control points hud elements
    for ( local tcp; tcp = FindByClassname( tcp, "team_control_point*" ); ) {

        tcp_scope <- PZI_Util.GetEntScope( tcp )
        if ( tcp.GetClassname() == "team_control_point_master" ) {

            SetPropFloat( tcp, "m_flCustomPositionX", 1.0 )
            SetPropFloat( tcp, "m_flCustomPositionY", 1.0 )
            tcp.AcceptInput( "RoundSpawn", "", null, null )
            function tcp_scope::InputSetWinner() { return false }
            function tcp_scope::Inputsetwinner() { return false }
            continue
        }

        for ( local i = 0; i < 3; i++ )
            tcp.KeyValueFromString( "team_previouspoint_2_" + i, tcp.GetName() )

        for ( local i = 0; i < 3; i++ )
            tcp.KeyValueFromString( "team_previouspoint_3_" + i, tcp.GetName() )

        SetPropInt( tcp, "m_iDefaultOwner", 0 )
    
        function tcp_scope::InputSetLocked() { return false }
        function tcp_scope::Inputsetlocked() { return false }
        tcp_scope.locked <- GetPropBool( tcp, "m_bLocked" )

        function tcp_scope::ToggleRandomControlPoint() {

            SetPropBool( self, "m_bLocked", !locked )
            return RandomInt( 5, 20 )
        }

        AddThinkToEnt( tcp, "ToggleRandomControlPoint" )

        EntFireByHandle( tcp, "RoundSpawn", null, -1, null, null )
    }
})

PZI_EVENT( "teamplay_setup_finished", "PZI_MapLogic_SetupFinished", @ ( params ) SpawnEntityFromTable( "logic_relay", setup_finished_relay_table ) )

PZI_EVENT( "player_spawn", "PZI_MapLogic_PlayerSpawn", function ( params ) {

    local player = GetPlayerFromUserID( params.userid )

    // if ( player.IsEFlagSet( EFL_IS_BEING_LIFTED_BY_BARNACLE ) )
        // return

    if ( player.IsBotOfType( TF_BOT_TYPE ) && player.HasBotAttribute( REMOVE_ON_DEATH ) )
        return

    PZI_Util.SetNextRespawnTime( player, BASE_RESPAWN_TIME )

    // we control this with a respawn_override trigger instead
    EntFire( "tf_gamerules", "SetBlueTeamRespawnWaveTime", "999999", -1 )
    EntFire( "tf_gamerules", "SetRedTeamRespawnWaveTime", "999999", -1 )
    EntFire( "tf_weapon_passtime_gun", "Kill", null, 0.05 )
})
