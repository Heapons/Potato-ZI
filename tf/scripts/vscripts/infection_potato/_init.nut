
/**************************************************************************************************
 *                                                                                                *
 * All Code By: Harry Colquhoun ( https://steamcommunity.com/profiles/76561198025795825 )         *
 * Assets/Game Design by: Diva Dan ( https://steamcommunity.com/profiles/76561198072146551 )      *
 * Modified for Potato.TF by: Braindawg ( https://steamcommunity.com/profiles/76561197988531991 ) *
 *                                                                                                *
***************************************************************************************************
 * init script                                                                                    *
***************************************************************************************************/

if ( "InfectionLoaded" in getroottable() )
    return

::DEBUG_MODE           <- 0
::MaxPlayers           <- MaxClients().tointeger()
::bGameStarted         <- false
::TFPlayerManager      <- FindByClassname( null, "tf_player_manager" )
::GameRules            <- FindByClassname( null, "tf_gamerules" )
::worldspawn           <- FindByClassname( null, "worldspawn" )
::flTimeLastBell       <- 0.0
::flTimeLastSpawnSFX   <- 0.0
::PDLogic              <- null
::bSetupHasEnded       <- false
::bIsPayload           <- false
::g_hAbilityHUD        <- null
::g_hAbilityNameHUD    <- null
::g_hTooltipHUD        <- null

::bNewFirstWaveBehaviour <- false
::bNoPyroExplosionMod    <- false
::bZombiesDontSwitchInPlace     <- true

const GAMEMODE_NAME =  "Potato Zombie Infection"
const PZI_VERSION   =  "10.20.2025.1"

::INFECTION_CONVARS <- {

    sv_alltalk                           = 1
    mp_winlimit                          = 0
    tf_classlimit                        = 0
    mp_idlemaxtime                       = 9999
    mp_forcecamera                       = 0
    mp_forceautoteam                     = 1
    mp_idledealmethod                    = 0
    tf_forced_holiday                    = 2
    mp_autoteambalance                   = 0
    tf_weapon_criticals                  = 1
    mp_scrableteams_auto                 = 0
    mp_scrambleteams_auto                = 0
    mp_stalemate_timelimit               = 9999
    mp_tournament_readymode              = 0
    tf_spawn_glows_duration              = 0
    mp_tournament_stopwatch              = 0
    mp_teams_unbalance_limit             = 0
    mp_disable_respawn_times             = 0
    mp_humans_must_join_team             = "red"
    cl_use_tournament_specgui            = 0
    mp_tournament_redteamname            = STRING_UI_TEAM_RED
    mp_tournament_blueteamname           = STRING_UI_TEAM_BLUE
    tf_dropped_weapon_lifetime           = 0
    tf_stalematechangeclasstime          = 9999
    mp_tournament_readymode_min          = 0
    tf_enable_glows_after_respawn        = 0 
    mp_tournament_readymode_countdown    = 10
    mp_tournament_readymode_team_size    = 0
    sv_vote_issue_autobalance_allowed    = 0
    mp_scrambleteams_auto_windifference  = 0
    sv_vote_issue_scramble_teams_allowed = 0
}

function SetInfectionConvars() {

    foreach( _cvar, _value in INFECTION_CONVARS ) {

        Convars.SetValue ( _cvar, _value )
    }
}

SetInfectionConvars()

// engie nade
PrecacheModel( MDL_WORLD_MODEL_ENGIE_NADE )
PrecacheScriptSound( "Building_Sentry.Damage" )
PrecacheScriptSound( "Halloween.PlayerEscapedUnderworld" )
PrecacheScriptSound( "Weapon_Grenade_Det_Pack.Timer" )
PrecacheScriptSound( "Weapon_GrenadeLauncher.DrumStop" )
PrecacheScriptSound( "Halloween.PumpkinExplode" )
PrecacheScriptSound( "Underwater.BulletImpact" )
PrecacheScriptSound( "Powerup.PickUpRegeneration" )
PrecacheScriptSound( "DemoCharge.HitFlesh" )
PrecacheScriptSound( "Breakable.MatFlesh" )

PrecacheScriptSound ( "WeaponGrapplingHook.ImpactFlesh" )
PrecacheScriptSound ( "Bounce.Flesh" )
PrecacheScriptSound ( "Breakable.MatFlesh" )

arrZombieViewModelPath <-
[
    MDL_ZOMBIE_VIEW_MODEL_SCOUT,
    MDL_ZOMBIE_VIEW_MODEL_SCOUT,
    MDL_ZOMBIE_VIEW_MODEL_SNIPER,
    MDL_ZOMBIE_VIEW_MODEL_SOLDIER,
    MDL_ZOMBIE_VIEW_MODEL_DEMOMAN,
    MDL_ZOMBIE_VIEW_MODEL_MEDIC,
    MDL_ZOMBIE_VIEW_MODEL_HEAVY,
    MDL_ZOMBIE_VIEW_MODEL_PYRO,
    MDL_ZOMBIE_VIEW_MODEL_SPY,
    MDL_ZOMBIE_VIEW_MODEL_ENGINEER,
]

arrZombieCosmeticIDX <-
[
    -1,   // unused
    5617, // scout
    5625, // sniper
    5618, // soldier
    5620, // demoman
    5622, // medic
    5619, // heavy
    5624, // pyro
    5623, // spy
    5621, // engineer
]

arrTFClassDefaultArmPath <-
[
    "models/weapons/c_models/c_scout_arms.mdl",
    "models/weapons/c_models/c_scout_arms.mdl",
    "models/weapons/c_models/c_sniper_arms.mdl",
    "models/weapons/c_models/c_soldier_arms.mdl",
    "models/weapons/c_models/c_demo_arms.mdl",
    "models/weapons/c_models/c_medic_arms.mdl",
    "models/weapons/c_models/c_heavy_arms.mdl",
    "models/weapons/c_models/c_pyro_arms.mdl",
    "models/weapons/c_models/c_spy_arms.mdl",
    "models/weapons/c_models/c_engineer_arms.mdl",
]

arrTFClassPlayerModels <-
[
    "models/player/scout.mdl",
    "models/player/scout.mdl",
    "models/player/sniper.mdl",
    "models/player/soldier.mdl",
    "models/player/demo.mdl",
    "models/player/medic.mdl",
    "models/player/heavy.mdl",
    "models/player/pyro.mdl",
    "models/player/spy.mdl",
    "models/player/engineer.mdl",
]

arrZombieArmVMPath <-
[
    PrecacheModel( MDL_ZOMBIE_VIEW_MODEL_SCOUT ),
    PrecacheModel( MDL_ZOMBIE_VIEW_MODEL_SCOUT ),
    PrecacheModel( MDL_ZOMBIE_VIEW_MODEL_SNIPER ),
    PrecacheModel( MDL_ZOMBIE_VIEW_MODEL_SOLDIER ),
    PrecacheModel( MDL_ZOMBIE_VIEW_MODEL_DEMOMAN ),
    PrecacheModel( MDL_ZOMBIE_VIEW_MODEL_MEDIC ),
    PrecacheModel( MDL_ZOMBIE_VIEW_MODEL_HEAVY ),
    PrecacheModel( MDL_ZOMBIE_VIEW_MODEL_PYRO ),
    PrecacheModel( MDL_ZOMBIE_VIEW_MODEL_SPY ),
    PrecacheModel( MDL_ZOMBIE_VIEW_MODEL_ENGINEER ),
]

arrZombieCosmeticModel <-
[
    PrecacheModel( MDL_ZOMBIE_PLAYER_MODEL_SCOUT ),
    PrecacheModel( MDL_ZOMBIE_PLAYER_MODEL_SCOUT ),
    PrecacheModel( MDL_ZOMBIE_PLAYER_MODEL_SNIPER ),
    PrecacheModel( MDL_ZOMBIE_PLAYER_MODEL_SOLDIER ),
    PrecacheModel( MDL_ZOMBIE_PLAYER_MODEL_DEMOMAN ),
    PrecacheModel( MDL_ZOMBIE_PLAYER_MODEL_MEDIC ),
    PrecacheModel( MDL_ZOMBIE_PLAYER_MODEL_HEAVY ),
    PrecacheModel( MDL_ZOMBIE_PLAYER_MODEL_PYRO ),
    PrecacheModel( MDL_ZOMBIE_PLAYER_MODEL_SPY ),
    PrecacheModel( MDL_ZOMBIE_PLAYER_MODEL_ENGINEER ),
]

arrZombieCosmeticModelStr <-
[
    MDL_ZOMBIE_PLAYER_MODEL_SCOUT,
    MDL_ZOMBIE_PLAYER_MODEL_SCOUT,
    MDL_ZOMBIE_PLAYER_MODEL_SNIPER,
    MDL_ZOMBIE_PLAYER_MODEL_SOLDIER,
    MDL_ZOMBIE_PLAYER_MODEL_DEMOMAN,
    MDL_ZOMBIE_PLAYER_MODEL_MEDIC,
    MDL_ZOMBIE_PLAYER_MODEL_HEAVY,
    MDL_ZOMBIE_PLAYER_MODEL_PYRO,
    MDL_ZOMBIE_PLAYER_MODEL_SPY,
    MDL_ZOMBIE_PLAYER_MODEL_ENGINEER,
]

arrZombieFXWearable <-
[
    PrecacheModel( MDL_FX_WEARABLE_SCOUT ),
    PrecacheModel( MDL_FX_WEARABLE_SCOUT ),
    PrecacheModel( MDL_FX_WEARABLE_SNIPER ),
    PrecacheModel( MDL_FX_WEARABLE_SOLDIER ),
    PrecacheModel( MDL_FX_WEARABLE_DEMOMAN ),
    PrecacheModel( MDL_FX_WEARABLE_MEDIC ),
    PrecacheModel( MDL_FX_WEARABLE_HEAVY ),
    PrecacheModel( MDL_FX_WEARABLE_PYRO ),
    PrecacheModel( MDL_FX_WEARABLE_SPY ),
    PrecacheModel( MDL_FX_WEARABLE_ENGINEER ),
]

local dummy = SpawnEntityFromTable( "entity_saucer", { vscripts = " "} )

local gen = PrecacheResources()
resume gen

function PrecacheThink() {

    if ( gen.getstatus() == "dead" )
        return self.Kill(), 1

    local result = resume gen

    if ( !result )
        return 1

    // printf( "PRECACHING RESOURCES (%d / %d)\n", result, getconsttable().len() )
    return -1
}
dummy.GetScriptScope().PrecacheThink <- PrecacheThink
AddThinkToEnt( dummy, "PrecacheThink" )

printl( "_init.nut Complete." )
printl( GAMEMODE_NAME + "\n" + PZI_VERSION )
// InfectionLoaded <- true