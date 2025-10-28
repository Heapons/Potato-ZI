// if ( "_CONST" in getconsttable() && _CONST )
//     return
/**************************************************************************************************
 *                                                                                                *
 * All Code By: Harry Colquhoun ( https://steamcommunity.com/profiles/76561198025795825 )         *
 * Assets/Game Design by: Diva Dan ( https://steamcommunity.com/profiles/76561198072146551 )      *
 * Modified for Potato.TF by: Braindawg ( https://steamcommunity.com/profiles/76561197988531991 ) *
 *                                                                                                *
***************************************************************************************************/
const _CONST                           = false
const TF_COND_NO_KNOCKBACK             = 130

const TEAM_HUMAN  = 2
const TEAM_ZOMBIE = 3
::TEAM_HUMAN  <- 2
::TEAM_ZOMBIE <- 3
/////////////////////////////////////////////////////////////////////////////////////////////
// Cooldowns ( in seconds ) |--------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_VIEWPUNCH       = 3;     // Internal Cooldown - viewpunch           //
const MIN_TIME_BETWEEN_VO              = 1;     // Internal Cooldown - zombie vo emit      //
const MIN_TIME_BETWEEN_CONVERT         = 0.1;   // Internal Cooldown - Apply zombie ents   //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_ENGIE_EMP_THROW = 9;     // Ability Cooldown  - Engie EMP Cast      //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_SPIT_START_END  = 0.5;   // Ability Delay     - Sniper Spit Channel //
const MIN_TIME_BETWEEN_SPIT_CAST       = 5;     // Ability Cooldown  - Sniper Spit Cast    //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_SPY_REVEAL      = 10;    // Ability Cooldown  - Spy Reveal Cast     //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_SOLDIER_POUNCE  = 5;     // Ability Cooldown  - Soldier Pounce Cast //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_MEDIC_HEAL      = 7;     // Ability Cooldown  - Medic Heal Cast     //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_DEMO_CHARGE     = 6;     // Ability Cooldown  - Demo Charge Cast    //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_PYRO_BLAST      = 5;     // Ability Cooldown  - Pyro Blast Cast     //
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// Game mode values |--------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
const ADDITIONAL_SEC_PER_PLAYER        = 8;     // Additional time added per player death  //
const ROUND_TIMER_NAME                 = "infection_timer"    // targetname of round timer //
const STARTING_ZOMBIE_FAC              = 5;                                                //
const GLOBAL_BELL_DELAY                = 3;     // delay in seconds for death bell         //
/////////////////////////////////////////////////////////////////////////////////////////////
// Zombie Stats |------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// --------------------------------------------------------------------------------------- //
// Damage Multiplier values for Zombie weapons                                             //
// --------------------------------------------------------------------------------------- //
const ZSCOUT_DMG_MULTI                 = 1;     // Scout    Zombie Damage Multiplier       //
const ZSNIPER_DMG_MULTI                = 1;     // Sniper   Zombie Damage Multiplier       //
const ZSOLDIER_DMG_MULTI               = 1;     // Soldier  Zombie Damage Multiplier       //
const ZDEMOMAN_DMG_MULTI               = 1;     // Demoman  Zombie Damage Multiplier       //
const ZMEDIC_DMG_MULTI                 = 1;     // Medic    Zombie Damage Multiplier       //
const ZHEAVY_DMG_MULTI                 = 2.2;   // Heavy    Zombie Damage Multiplier       //
const ZPYRO_DMG_MULTI                  = 0.7;   // Pyro     Zombie Damage Multiplier       //
const ZSPY_DMG_MULTI                   = 1;     // Spy      Zombie Damage Multiplier       //
const ZENGINEER_DMG_MULTI              = 1;     // Engineer Zombie Damage Multiplier       //
const ZOMBIE_PASSIVE_HEALING           = true;  // enable Zombie Passive Healing           //
// --------------------------------------------------------------------------------------- //
// Item Definition Index ( IDX ) for each class' Zombie weapon                               //
// --------------------------------------------------------------------------------------- //
const ZOMBIE_SPOOF_WEAPON_IDX          = 572;   // idx for killicon for zombie melee       //
// --------------------------------------------------------------------------------------- //
ZOMBIE_WEAPON_IDX <-                            //                                         //
[                                               //                                         //
    5617,                                       // scout                                   //
    5617,                                       // scout                                   //
    5625,                                       // sniper                                  //
    5618,                                       // soldier                                 //
    5620,                                       // demoman                                 //
    5622,                                       // medic                                   //
    5619,                                       // heavyweapons                            //
    5624,                                       // pyro                                    //
    5623,                                       // spy                                     //
    5621,                                       // engineer                                //
];                                              //                                         //
// --------------------------------------------------------------------------------------- //
// tf_weapon* type of each class' Zombie weapon                                            //
// --------------------------------------------------------------------------------------- //
ZOMBIE_WEAPON_CLASSNAME <-[                     //                                         //
    "tf_weapon_fists",                          // scout                                   //
    "tf_weapon_fists",                          // scout                                   //
    "tf_weapon_fists",                          // sniper                                  //
    "tf_weapon_fists",                          // soldier                                 //
    "tf_weapon_fists",                          // demoman                                 //
    "tf_weapon_fists",                          // medic                                   //
    "tf_weapon_fists",                          // heavyweapons                            //
    "tf_weapon_fists",                          // pyro                                    //
    "tf_weapon_fists",                          // spy                                     //
    "tf_weapon_fists",                          // engineer                                //
];                                              //                                         //
// --------------------------------------------------------------------------------------- //
// Zombie Weapon Attributes - Weapon type attributes for each class when playing as zombie //
// --------------------------------------------------------------------------------------- //
// TF_ATTRIB Array | [string condition, fl value, fl duration ( -1 for infinite )]          //
// ( https://wiki.teamfortress.com/wiki/List_of_item_attributes )                            //
// --------------------------------------------------------------------------------------- //
ZOMBIE_WEP_ATTRIBS <- [ /////////////////////////////////////////////////////////////////////
[// attributes applied to all zombie weps ------------------------------------------------ //
["melee range multiplier",   1, -1],            // Increase melee range for zombie         //
["melee bounds multiplier",  1, -1],            // Increase melee range for zombie         //
["crit mod disabled hidden", 0, -1],            // No crits                                //
["zombiezombiezombiezombie", 1, -1],            // enable zombie cosmetic vo               //
["attach particle effect", 3105, -1],            // enable particle effect                 //
["voice pitch scale", 0.7, -1],                       // Makes player voice funny          //
],                                              //                                         //
[// attributes for scout zombie weapon --------------------------------------------------- //
["damage bonus", ZSCOUT_DMG_MULTI, -1 ],        // set class specific damage multi         //
["move speed bonus", 1.75, -1 ],                // extra movement speed for scout passive  //
["increased jump height from weapon", 1.25, -1] // additional jump height                  //
],                                              //                                         //
[// attributes for sniper zombie weapon -------------------------------------------------- //
["damage bonus", ZSNIPER_DMG_MULTI, -1 ],       // set class specific damage multi         //
],                                              //                                         //
[// attributes for soldier zombie weapon ------------------------------------------------- //
["damage bonus", ZSOLDIER_DMG_MULTI, -1 ],      // set class specific damage multi         //
],                                              //                                         //
[// attributes for demo zombie weapon ---------------------------------------------------- //
["damage bonus", ZDEMOMAN_DMG_MULTI, -1 ],      // set class specific damage multi         //
],                                              //                                         //
[// attributes for medic zombie weapon --------------------------------------------------- //
["damage bonus", ZMEDIC_DMG_MULTI, -1 ],        // set class specific damage multi         //
],                                              //                                         //
[// attributes for heavyweaponzombie weapon ---------------------------------------------- //
["damage bonus", ZHEAVY_DMG_MULTI, -1 ],        // set class specific damage multi         //
],                                              //                                         //
[// attributes for pyro zombie weapon ---------------------------------------------------- //
["damage bonus", ZPYRO_DMG_MULTI, -1 ],         // set class specific damage multi         //
["ragdolls become ash", 1, -1],                 //                                         //
],                                              //                                         //
[// attributes for spy zombie weapon ----------------------------------------------------- //
["damage bonus", ZSPY_DMG_MULTI, -1 ],          // set class specific damage multi         //
],                                              //                                         //
[// attributes for engy zombie weapon ---------------------------------------------------- //
["damage bonus", ZENGINEER_DMG_MULTI, -1 ],     // set class specific damage multi         //
],                                              //                                         //
];                                              //                                         //
// --------------------------------------------------------------------------------------- //
// Zombie TF_CONDs - TF Conditions for each class when playing as zombie                   //
// --------------------------------------------------------------------------------------- //
// TF_COND Array | [string TF_COND]                                                        //
// ( https://developer.valvesoftware.com/wiki/Trigger_add_tf_player_condition )              //
// --------------------------------------------------------------------------------------- //
ZOMBIE_PLAYER_CONDS <- [ ////////////////////////////////////////////////////////////////////
[// TF_CONDs applied to all zombies  ----------------------------------------------------- //
    TF_COND_CANNOT_SWITCH_FROM_MELEE,           // For obvious reasons...                  //
    TF_COND_TEAM_GLOWS,                         // outlines for friendly players           //
],                                              //                                         //
[// TF_CONDs applied to scout zombie ----------------------------------------------------- //
    TF_COND_SPEED_BOOST,                        // Speed lines make you go faster          //
],                                              //                                         //
[// TF_CONDs applied to sniper zombie ---------------------------------------------------- //
],                                              //                                         //
[// TF_CONDs applied to soldier zombie --------------------------------------------------- //
],                                              //                                         //
[// TF_CONDs applied to demoman zombie --------------------------------------------------- //
],                                              //                                         //
[// TF_CONDs applied to medic zombie ----------------------------------------------------- //
],                                              //                                         //
[// TF_CONDs applied to heavyweapons zombie ---------------------------------------------- //
    TF_COND_NO_KNOCKBACK,                       // cannot be knocked back                  //
    TF_COND_DEFENSEBUFF_NO_CRIT_BLOCK,          // battalion's backup effect w/o crit block//
],                                              //                                         //
[// TF_CONDs applied to pyro zombie ------------------------------------------------------ //
],                                              //                                         //
[// TF_CONDs applied to spy zombie ------------------------------------------------------- //
],                                              //                                         //
[// TF_CONDs applied to engy zombie ------------------------------------------------------ //
],                                              //                                         //
];///////////////////////////////////////////////////////////////////////////////////////////
// --------------------------------------------------------------------------------------- //
// Zombie Player Attributes - Player type attributes for each class when playing as zombie //
// --------------------------------------------------------------------------------------- //
// TF_ATTRIB Array | [string condition, fl value, fl duration ( -1 for infinite )]          //
// ( https://wiki.teamfortress.com/wiki/List_of_item_attributes )                            //
// --------------------------------------------------------------------------------------- //
ZOMBIE_PLAYER_ATTRIBS <- [ //////////////////////////////////////////////////////////////////
[// attributes applied to all zombie weps ------------------------------------------------ //
    ["crit mod disabled hidden", 0, -1],                  // No crits                          //
    ["maxammo metal reduced", 0.0, -1],                   // Prevent picking up metal          //
    ["maxammo secondary reduced", 0.0, -1],               // Prevent picking up ammo           //
    ["maxammo primary reduced", 0.0, -1],                 // Prevent picking up ammo           //
    ["health from packs decreased", 0, -1],               // Cannot pick up health packs       //
],                                                        //                                   //
[// attributes for scout zombie  --------------------------------------------------------- //
    ["SPELL: set Halloween footstep type", 4552221, -1 ], // corrupted green footsteps        //
    ["hidden maxhealth non buffed", -50, -1 ],            //                                  //
],                                                        //                                  //
[// attributes for sniper zombie  -------------------------------------------------------- //
    ["SPELL: set Halloween footstep type", 4552221, -1 ], // corrupted green footsteps        //
    ["hidden maxhealth non buffed", 25, -1 ],             //                                  //
],                                                        //                                  //
[// attributes for soldier zombie  ------------------------------------------------------- //
    ["SPELL: set Halloween footstep type", 4552221, -1 ], // corrupted green footsteps        //
    ["hidden maxhealth non buffed", 25, -1 ],             //                                  //
],                                                        //                                  //
[// attributes for demo zombie  ---------------------------------------------------------- //
    ["SPELL: set Halloween footstep type", 4552221, -1 ], // corrupted green footsteps        //
    ["hidden maxhealth non buffed", 25, -1 ],             //                                  //
],                                                        //                                  //
[// attributes for medic zombie  --------------------------------------------------------- //
    ["SPELL: set Halloween footstep type", 4552221, -1 ], // corrupted green footsteps        //
    ["hidden maxhealth non buffed", 25, -1 ],             //                                  //
],                                                        //                                  //
[// attributes for heavyweapons zombie  -------------------------------------------------- //
    ["SPELL: set Halloween footstep type", 4552221, -1 ], // corrupted green footsteps        //
    ["move speed penalty", 0.90, -1 ],                    //                                  //
    ["dmg bonus vs buildings", 100, -1 ],                 //                                  //
    ["hidden maxhealth non buffed", 225, -1 ],            //                                  //
],                                                        //                                  //
[// attributes for pyro zombie  ---------------------------------------------------------- //
    ["SPELL: set Halloween footstep type", 4552221, -1 ], // corrupted green footsteps        //
    ["hidden maxhealth non buffed", 75, -1 ],             //                                  //
],                                                        //                                  //
[// attributes for spy zombie  ----------------------------------------------------------- //
    ["hidden maxhealth non buffed", 25, -1 ],             //                                  //
],                                                        //                                  //
[// attributes for engy zombie  ---------------------------------------------------------- //
    ["SPELL: set Halloween footstep type", 4552221, -1 ], // corrupted green footsteps        //
    ["hidden maxhealth non buffed", 25, -1 ],             //                                  //
],                                                        //                                  //
];                                                        //                                  //
/////////////////////////////////////////////////////////////////////////////////////////////
// Zombie Win Condition |----------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
const MAX_SURVIVORS_FOR_ZOMBIE_WIN     = 0;     // if =  x red alive, zombies win          //
/////////////////////////////////////////////////////////////////////////////////////////////
// Entity Think Function Rethink Times |-------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// --------------------------------------------------------------------------------------- //
const PLAYER_RETHINK_TIME              = -1;   // How often the player thinks             //
const ENGIE_EMP_RETHINK_TIME           = 0.01;  // How often the EMP grenade thinks        //
const SNIPER_SPIT_RETHINK_TIME         = 0;     // How often the sniper spit thinks        //
const SNIPER_SPIT_ZONE_RETHINK_TIME    = 0.5;   // How often the sniper spit ZONE thinks   //
const ENGIE_EMP_BUILDING_RETHINK_TIME  = 0.1;   // How often the EMP'd building thimax_nks //
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// ZombieHeavy Passive Values |----------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// --------------------------------------------------------------------------------------- //
const HEAVY_KNOCK_BACK_FORCE           = 125;   // knock back force on heavy punch         //
// --------------------------------------------------------------------------------------- //

const DRG_RAYGUN_ZOMBIE_COOLDOWN_MOD = 3; // 3 seconds, set to -1 for full ability cooldown

const ZOMBIE_MEDIC_DISPENSER_RANGE = 128
const ROMEVISION_ATTRIBUTE_IDX = 4

SNIPER_SPIT_ZONE_ENTS <- {

    "tf_pumpkin_bomb" : "ignite",
    "tf_generic_bomb" : "detonate",
    "obj_sentrygun"   : "building",
    "obj_dispenser"   : "building",
    "obj_teleporter"  : "building",
}

PROBLEMATIC_PLAYER_CONDS <-
[
    0,  // TF_COND_AIMING
    1,  // TF_COND_ZOOMED
    2,  // TF_COND_DISGUISING
    3,  // TF_COND_DISGUISED
    4,  // TF_COND_STEALTHED
    5,  // TF_COND_INVULNERABLE
    7,  // TF_COND_TAUNTING
    8,  // TF_COND_INVULNERABLE_WEARINGOFF
    9,  // TF_COND_STEALTHED_BLINK
    11, // TF_COND_CRITBOOSTED
    13, // TF_COND_FEIGN_DEATH
    14, // TF_COND_PHASE
 //   17, // TF_COND_SHIELD_CHARGE
    19, // TF_COND_ENERGY_BUFF
    47, // TF_COND_DISGUISE_WEARINGOFF
    64, // TF_COND_STEALTHED_USER_BUFF
    66, // TF_COND_STEALTHED_USER_BUFF_FADING
]

arrHUDTextClassXOffsets <-
[
    -0.010,  // scout
    -0.009,  // scout
    0.025,   // sniper
    0.016,   // soldier
    -0.0045, // demoman
    0.023,   // medic
    0.008,   // heavy
    -0.017,   // pyro
    0.020,   // spy
    -0.006,  // engineer
]

arrHUDTextClassYOffsets <-
[
    0.016, // scout
    0.016, // scout
    0.011, // sniper
    0.015, // soldier
    0.015, // demoman
    0.013, // medic
    0.009, // heavy
    0.009, // pyro
    0.016, // spy
    0.016, // engineer
]

::arrClassAttackSpeed <-
[
    0.85, // scout
    0.85, // scout
    0.85, // sniper
    0.85, // soldier
    0.85, // demoman
    0.85, // medic
    1.25, // heavyweapons
    0.85, // pyro
    0.85, // spy
    0.85, // engineer
]

szArrZombieAbilityUI <-
[
    "vgui/infection_potato/zability_scout_",
    "vgui/infection_potato/zability_scout_",
    "vgui/infection_potato/zability_sniper_",
    "vgui/infection_potato/zability_soldier_",
    "vgui/infection_potato/zability_demo_",
    "vgui/infection_potato/zability_medic_",
    "vgui/infection_potato/zability_heavy_",
    "vgui/infection_potato/zability_pyro_",
    "vgui/infection_potato/zability_spy_",
    "vgui/infection_potato/zability_engineer_",
]

idxArrZombiePlayerModels <-
[
    PrecacheModel( "models/player/scout_infected.mdl" ),
    PrecacheModel( "models/player/scout_infected.mdl" ),
    PrecacheModel( "models/player/sniper_infected.mdl" ),
    PrecacheModel( "models/player/soldier_infected.mdl" ),
    PrecacheModel( "models/player/demo_infected.mdl" ),
    PrecacheModel( "models/player/medic_infected.mdl" ),
    PrecacheModel( "models/player/heavy_infected.mdl" ),
    PrecacheModel( "models/player/pyro_infected.mdl" ),
    PrecacheModel( "models/player/spy_infected.mdl" ),
    PrecacheModel( "models/player/engineer_infected.mdl" ),
]

szArrZombiePlayerModels <-
[
    "models/player/scout_infected.mdl",
    "models/player/scout_infected.mdl",
    "models/player/sniper_infected.mdl",
    "models/player/soldier_infected.mdl",
    "models/player/demo_infected.mdl",
    "models/player/medic_infected.mdl",
    "models/player/heavy_infected.mdl",
    "models/player/pyro_infected.mdl",
    "models/player/spy_infected.mdl",
    "models/player/engineer_infected.mdl",
]
szEyeParticles <- [
    "eye_powerup_red_lvl_3",
    "eye_powerup_red_lvl_2"
]

const MDL_ZOMBIE_VIEW_MODEL_SCOUT          = "models/player/infection_potato/v_models/v_infected_scout.mdl"
const MDL_ZOMBIE_VIEW_MODEL_SNIPER         = "models/player/infection_potato/v_models/v_infected_sniper.mdl"
const MDL_ZOMBIE_VIEW_MODEL_SOLDIER        = "models/player/infection_potato/v_models/v_infected_soldier.mdl"
const MDL_ZOMBIE_VIEW_MODEL_DEMOMAN        = "models/player/infection_potato/v_models/v_infected_demo.mdl"
const MDL_ZOMBIE_VIEW_MODEL_MEDIC          = "models/player/infection_potato/v_models/v_infected_medic.mdl"
const MDL_ZOMBIE_VIEW_MODEL_HEAVY          = "models/player/infection_potato/v_models/v_infected_heavy.mdl"
const MDL_ZOMBIE_VIEW_MODEL_PYRO           = "models/player/infection_potato/v_models/v_infected_pyro.mdl"
const MDL_ZOMBIE_VIEW_MODEL_SPY            = "models/player/infection_potato/v_models/v_infected_spy.mdl"
const MDL_ZOMBIE_VIEW_MODEL_ENGINEER       = "models/player/infection_potato/v_models/v_infected_engineer.mdl"
const MDL_ZOMBIE_PLAYER_MODEL_SCOUT        = "models/player/items/scout/scout_zombie.mdl"
const MDL_ZOMBIE_PLAYER_MODEL_SNIPER       = "models/player/items/sniper/sniper_zombie.mdl"
const MDL_ZOMBIE_PLAYER_MODEL_SOLDIER      = "models/player/items/soldier/soldier_zombie.mdl"
const MDL_ZOMBIE_PLAYER_MODEL_DEMOMAN      = "models/player/items/demo/demo_zombie.mdl"
const MDL_ZOMBIE_PLAYER_MODEL_MEDIC        = "models/player/items/medic/medic_zombie.mdl"
const MDL_ZOMBIE_PLAYER_MODEL_HEAVY        = "models/player/items/heavy/heavy_zombie.mdl"
const MDL_ZOMBIE_PLAYER_MODEL_PYRO         = "models/player/items/pyro/pyro_zombie.mdl"
const MDL_ZOMBIE_PLAYER_MODEL_SPY          = "models/player/items/spy/spy_zombie.mdl"
const MDL_ZOMBIE_PLAYER_MODEL_ENGINEER     = "models/player/items/engineer/engineer_zombie.mdl"
const MDL_FX_WEARABLE_SCOUT                = "models/player/infection_potato/scout_zombie_wearable.mdl"
const MDL_FX_WEARABLE_SNIPER               = "models/player/infection_potato/sniper_zombie_wearable.mdl"
const MDL_FX_WEARABLE_SOLDIER              = "models/player/infection_potato/soldier_zombie_wearable.mdl"
const MDL_FX_WEARABLE_DEMOMAN              = "models/player/infection_potato/demo_zombie_wearable.mdl"
const MDL_FX_WEARABLE_MEDIC                = "models/player/infection_potato/medic_zombie_wearable.mdl"
const MDL_FX_WEARABLE_HEAVY                = "models/player/infection_potato/heavy_zombie_wearable.mdl"
const MDL_FX_WEARABLE_PYRO                 = "models/player/infection_potato/pyro_zombie_wearable.mdl"
const MDL_FX_WEARABLE_SPY                  = "models/player/infection_potato/spy_zombie_wearable.mdl"
const MDL_FX_WEARABLE_ENGINEER             = "models/player/infection_potato/engineer_zombie_wearable.mdl"
const MDL_WORLD_MODEL_ENGIE_NADE           = "models/player/infection_potato/w_grenade_emp.mdl"
const MDL_GUNSLINGER_PATH                  = "models/weapons/c_models/c_engineer_gunslinger.mdl"

//https://wiki.teamfortress.com/w/images/thumb/3/31/Unusual_Charged_Arcane.png/600px-Unusual_Charged_Arcane.png
const FX_ZOMBIE_BODY                 = "zombie_body_parent"
const FX_ZOMBIE_BODY_AURA            = "zombie_body_aura"
const FX_ZOMBIE_BODY_FLIES           = "zombie_body_flies"
const FX_ZOMBIE_SPARKS               = "zombie_body_sparks"

// const FX_ZOMBIE_EYEFLARE             = "zombie_eyeflare"
// const FX_ZOMBIE_EYEFLARE             = "killstreak_t1_lvl2"
const FX_ZOMBIE_EYEFLARE             = "killstreak_t7_lvl2"
const FX_ZOMBIE_LIGHTNING            = "wrenchmotron_teleport_beam"
const FX_ZOMBIE_LIGHTNING_CONTROLLER = "wrenchmotron_teleport_beam"

const FX_ZOMBIE_SPAWN                = "wrenchmotron_teleport_beam"
const FX_ZOMBIE_SPAWN_BURST          = "zombie_spawn_burst"
const FX_ZOMBIE_SPAWN_SMOKE          = "zombie_spawn_smoke"
const FX_ZOMBIE_SPAWN_FLASH          = "zombie_spawn_flash"
const FX_ZOMBIE_SPAWN_SKYFLASH       = "zombie_spawn_skyflash"

const FX_EMP_PARENT                  = "taunt_conga_fireworks_flash"
const FX_EMP_ELECTRIC                = "drg_cow_explosioncore_charged_blue"
const FX_EMP_GIBS                    = "drg_cow_explosioncore_charged_blue"
const FX_EMP_FLASH                   = "taunt_conga_fireworks_flash"
const FX_EMP_BURST                   = "drg_cow_explosioncore_charged_blue"
const FX_EMP_SPARK                   = "halloween_boss_axe_hit_sparks"

// const FX_SPIT_SMOKE                 = "zombie_spit"
// const FX_SPIT_TRAIL                 = "zombie_spit_trail"
// const FX_SPIT_TRAIL2                = "zombie_spit_trail2"
// const FX_SPIT_IMPACT                = "zombie_spit_impact"
// const FX_SPIT_IMPACT_BITS           = "zombie_spit_impact_bits"
// const FX_SPIT_HIT_PLAYER            = "zombie_spit_impact_cloud"
// const FX_SPIT_IMPACT_GROUND         = "zombie_spit_impact_ground"
// const FX_SPIT_IMPACT_SMOKE          = "zombie_spit_impact_smoke"
// const FX_SPIT_IMPACT_SPLAT          = "zombie_spit_impact_splat"
// const FX_SPIT_IMPACT_SPURTS         = "zombie_spit_impact_spurts"

// const FX_SPIT_SMOKE                 = "utaunt_spirit_festive_parent"
const FX_SPIT_SPLAT                 = "spell_skeleton_goop_green"
const FX_SPIT_SMOKE                 = "superrare_flies"
const FX_SPIT_TRAIL                 = "unusual_robot_radioactive"
const FX_SPIT_TRAIL2                = "unusual_robot_radioactive"
const FX_SPIT_IMPACT                = false
const FX_SPIT_IMPACT_BITS           = "superrare_flies"
const FX_SPIT_HIT_PLAYER            = "breadjar_impact"
const FX_SPIT_IMPACT_GROUND         = "unusual_robot_radioactive"
const FX_SPIT_IMPACT_SMOKE          = "spell_skeleton_goop_green"
const FX_SPIT_IMPACT_SPLAT          = "spell_skeleton_goop_green"
const FX_SPIT_IMPACT_SPURTS         = "superrare_flies"

const FX_EMITTER_FX                 = "powerup_supernova_explode_blue_spikes"

const FX_DEMOGUTS                   = "env_sawblood_mist"

const FX_MEDIC_HEAL                 = "spell_overheal_blue"
// const FX_MEDIC_HEAL                 = "zombie_heal_parent"
// const FX_FIREBALL_FIREBALL          = "zombie_fireball_fireball"
// const FX_FIREBALL_SMOKEBALL         = "zombie_fireball_smokeball"
// const FX_FIREBALL_SMOKEPUFF         = "zombie_fireball_smokepuff"
// const FX_FIREBALL_TRAIL             = "zombie_fireball_trail"
// const FX_ZOMBIE_FIREBALL            = "zombie_fireball"

const FX_FIREBALL_TRAIL             = "projectile_fireball"
const FX_FIREBALL_SMOKEBALL         = false
const FX_FIREBALL_SMOKEPUFF         = "zombie_fireball_smokepuff"

const FX_FLAMER               = "flamethrower_blue"
const FX_TF_STOMP_TEXT        = "stomp_text"

const SFX_ZOMBIE_SPIT_START   = "infection_potato/sniper_spit_start.wav"
const SFX_ZOMBIE_SPIT_END     = "infection_potato/sniper_spit_end.wav"
const SFX_ENGI_EMP            = "infection_potato/engineer_emp_0%d.wav"
const SFX_EMP_EXPLODE         = "infection_potato/sfx_infection_emp_grenade_explode1.wav"
const SFX_EMP_BEEP            = "Weapon_Grenade_Det_Pack.Timer"
const SFX_EMP_BUILDING_DMGED  = "Building_Sentry.Damage"
const SFX_SPIT_POP            = "Underwater.BulletImpact"
const SFX_SPIT_SPLATTER       = "Halloween.PumpkinExplode"
const SFX_SPIT_MISS           = "Mud.StepRight"
const SFX_SPY_REVEAL_ONCAST   = "spy_reveal_0%d.wav"
const SFX_ABILITY_USE         = "Halloween.Merasmus_Spell"
const SFX_PYRO_FIREBOMB       = "Halloween.spell_fireball_impact"
const SFX_DEMO_CHARGE         = "infection_potato/demo_charge_0%d.wav"
const SFX_DEMO_CHARGE_RAMP    = "infection_potato/demo_charge_rampup_0%d.wav"
const SFX_ZMEDIC_HEAL         = "infection_potato/medic_zombie_heal.wav"
const SFX_SOLDIER_POUNCE      = "infection_potato/soldier_pounce_0%d.wav"

const KILLICON_SCOUT_MELEE      = "infection_scout"
const KILLICON_SOLDIER_MELEE    = "infection_soldier"
const KILLICON_PYRO_MELEE       = "infection_pyro"
const KILLICON_PYRO_BREATH      = "firedeath"
const KILLICON_DEMOMAN_MELEE    = "infection_demoman"
const KILLICON_DEMOMAN_BOOM     = "soldier_taunt"
const KILLICON_HEAVY_MELEE      = "infection_heavy"
const KILLICON_ENGIE_MELEE      = "infection_engineer"
const KILLICON_ENGIE_EMP        = "infection_emp"
const KILLICON_MEDIC_MELEE      = "infection_medic"
const KILLICON_SNIPER_MELEE     = "infection_sniper"
const KILLICON_SNIPER_SPITPOOL  = "infection_acid_puddle"
const KILLICON_SNIPER_SPIT      = "infection_acid_ball"
const KILLICON_SPY_MELEE        = "unarmed_combat"

// debug icons
//const KILLICON_SCOUT_MELEE      = "megaton"
//const KILLICON_SOLDIER_MELEE    = "piranha"
//const KILLICON_PYRO_MELEE       = "helicopter"
//const KILLICON_PYRO_BREATH      = "firedeath"
//const KILLICON_DEMOMAN_MELEE    = "crocodile"
//const KILLICON_DEMOMAN_BOOM     = "taunt_soldier"
//const KILLICON_HEAVY_MELEE      = "krampus_ranged"
//const KILLICON_ENGIE_MELEE      = "krampus_melee"
//const KILLICON_ENGIE_EMP        = "resurfacer"
//const KILLICON_MEDIC_MELEE      = "salmann"
//const KILLICON_SNIPER_MELEE     = "shark"
//const KILLICON_SNIPER_SPITPOOL  = "gas_blast"
//const KILLICON_SNIPER_SPIT      = "hot_hand"
//const KILLICON_SPY_MELEE        = "unarmed_combat"

const MAT_SPIT_OVERLAY  = "effects/imcookin_green_potato"

const STRING_NETPROP_ITEMDEF  = "m_AttributeManager.m_Item.m_iItemDefinitionIndex"

const FLT_MAX     = 3.40282347e+38
const ALIVE       = 0
const ACT_LOCKED  = -2
const INSTANT     = 0.0

const ZHUD_X_POS  = 0.867
const ZHUD_Y_POS  = 0.887

const CLIENTPRINT_DELAY            = 0.5
const MEDIC_HEAL_TICK_RATE         = 0.25
const ENGIE_EMP_STATE_IN_TRANSIT   = 0
const SPIT_STATE_IN_TRANSIT        = 0
const SPIT_STATE_ZONE              = 1
const SPIT_STATE_REJECTED          = 2
const SPIT_STATE_FINDING_GROUND    = 3

const ZOMBIE_ABILITY_CAST          = 1
const ZOMBIE_TALK                  = 2
const ZOMBIE_DO_ATTACK1            = 3
const ZOMBIE_BECOME_ZOMBIE         = 4
const ZOMBIE_BECOME_SURVIVOR       = 5
const ZOMBIE_NEXT_QUEUED_EVENT     = 6
const ZOMBIE_KILL_GLOW             = 7
const ZOMBIE_REMOVE_HEALRING       = 8
const ZOMBIE_CAN_CLIENTPRINT       = 9
const ZOMBIE_CAN_SENTIENTDERGE     = 10
const SURVIVOR_CAN_CLEAR_SCRIPT_SCREEN_OVERLAY = 11

const EVENT_SNIPER_SPITBALL        = 1
const EVENT_ENTER_SPY_REVEAL       = 2
const EVENT_EXIT_SPY_REVEAL        = 3
const EVENT_ENTER_MEDIC_HEAL       = 4
const EVENT_EXIT_MEDIC_HEAL        = 5
const EVENT_ENGIE_EXIT_MINIROOT    = 6
const EVENT_ENGIE_THROW_NADE       = 7
const EVENT_DEMO_CHARGE_START      = 8
const EVENT_DEMO_CHARGE_EXIT       = 9
const EVENT_PUT_ABILITY_ON_CD      = 10
const EVENT_DOWNWARDS_VIEWPUNCH    = 11
const EVENT_KILL_TEMP_ENTITY       = 12
const EVENT_DEMO_CHARGE_RESET      = 13
const EVENT_SPY_RECLOAK            = 14
const EVENT_SPY_SWAP_CLOAK         = 15
const EVENT_RESET_ZOMBIE_WEP       = 16

const ZBIT_PARTICLE_HACK           = 0x1
const ZBIT_PENDING_ZOMBIE          = 0x2
const ZBIT_PENDING_UNZOMBIE        = 0x4
const ZBIT_IS_UNJUMBLER            = 0x4
const ZBIT_DEAD_ZOMBIE             = 0x8
const ZBIT_ZOMBIE                  = 0x10
const ZBIT_SURVIVOR                = 0x20
const ZBIT_SNIPER_CHARGING_SPIT    = 0x40
const ZBIT_SPY_IN_REVEAL           = 0x80
const ZBIT_REVEALED_BY_SPY         = 0x100
const ZBIT_HASNT_HEARD_READY_SFX   = 0x400
const ZBIT_MEDIC_IN_HEAL           = 0x800
const ZBIT_HEALING_FROM_ZMEDIC     = 0x1000
const ZBIT_HASNT_HEARD_DENY_SFX    = 0x2000
const ZBIT_IS_ULTING               = 0x4000
const ZBIT_HAS_HUD                 = 0x8000
const ZBIT_WAS_GIVEN_HUD_INFO      = 0x10000
const ZBIT_IS_DEVELOPER            = 0x40000
const ZBIT_IS_NOT_DEVELOPER        = 0x80000
const ZBIT_MUST_EXPLODE            = 0x40000
const ZBIT_OUT_OF_COMBAT           = 0x80000
const ZBIT_THE_OMBUDSMAN           = 0x100000
const ZBIT_SOLDIER_IN_POUNCE       = 0x400000
const ZBIT_SCOUT_HAS_TRIPLE_JUMPED = 0x800000
const ZBIT_DEMOCHARGE              = 0x1000000
const ZBIT_PYRO_DONT_EXPLODE       = 0x2000000

const ZABILITY_THROWABLE           = 0
const ZABILITY_PROJECTILE          = 1
const ZABILITY_EMITTER             = 2
const ZABILITY_PASSIVE             = 3
const ZABILITY_STATE_READY         = 0
const ZABILITY_STATE_NOT_READY     = 1

const ZHUD_X_READY_OFFSET          = 0.014
const ZHUD_X_PASSIVE_OFFSET        = 0.006

const TF_NERF_MINIGUN_Z_DMG        = 0.6
const TF_NERF_SENTRY_Z_DMG         = 0.4
const Z_NERF_SHIELD_TF_DMG         = 0.5

const TF_IDX_UNDEFINED             = -1
const TF_IDX_GWRENCH               = 169
const TF_IDX_MEDIC_CROSSBOW        = 305
const TF_IDX_SAXXY                 = 423
const TF_IDX_SPYCICLE              = 649
const TF_IDX_GOLDENPAN             = 1071
const TF_IDX_GRAPPLING_HOOK        = 1152

const TF_COND_SPEED_BOOST          = 32
const TF_WEAPON_COUNT              = 7
const TF_DEATH_FEIGN_DEATH         = 32
const TF_DEATH_GIBBED              = 0x0080

const HIDEHUD_BUILDING_STATUS     =  0x1000
const HIDEHUD_CLOAK_AND_FEIGN     =  0x2000
const HIDEHUD_PIPES_AND_CHARGE    =  0x4000
const HIDEHUD_METAL               =  0x8000

foreach(k, v in CONST)
    ROOT[k] <- v