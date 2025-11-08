
/**************************************************************************************************
 *                                                                                                *
 * All Code By: Harry Colquhoun ( https://steamcommunity.com/profiles/76561198025795825 )         *
 * Assets/Game Design by: Diva Dan ( https://steamcommunity.com/profiles/76561198072146551 )      *
 * Modified for Potato.TF by: Braindawg ( https://steamcommunity.com/profiles/76561197988531991 ) *
 *                                                                                                *
***************************************************************************************************
 * infection mode main script                                                                     *
***************************************************************************************************/

zi <- this

if ( !( "InfectionLoaded" in getroottable() ) ) {

    printl( "infection Mode Initliazing..." )
    ::root <- getroottable()

    IncludeScript ( "infection_potato/const.nut", root )
    IncludeScript ( "infection_potato/strings.nut", root )
    IncludeScript ( "infection_potato/functions.nut", root )
    IncludeScript ( "infection_potato/think.nut", root )
    IncludeScript ( "infection_potato/ability.nut", root )
    IncludeScript ( "infection_potato/_init.nut", root )
    printl        ( "Infection Mode Loaded." )

}

    // return true


// changes ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 24/10/2024 - v3.0.4 ------------------------------------------------------------------------------------------------- //
// -- General
// -- -- Re-encoded all Zombie Infection sound effects as .WAV
// -- -- -- This fixes issues with sound effects not playing correctly and spewing errors in the console
// -- Bug fixes
// -- -- Fixed a bug that caused Sniper's Spit Pool to deal much more damage than intended
// -- -- Fixed a bug that caused team names to not display correctly when playing on mp_tournament mode
// -- -- Fixed a bug where Engineer would sometimes scream like a charging Demoman while throwing an EMP Grenade
// -- Zombie Changes
// -- -- Sniper's Spit Pool damage vs Survivors no longer stacks when standing in multiple zones
// -- -- Zombie Heavy is no longer immune to Critical Hits
// -- -- Zombie Heavy's max health raised to 525 ( from 450 )
// -- -- Zombie Pyro's max health raised to 250 ( from 175 )
// -- -- Zombie Pyro now drops a medium health kit on death
// -- Survivor Changes
// -- -- Crossbow weapons no longer have a flat damage multiplier against Zombies
// -- -- The B.A.S.E Jumper can no longer be deployed if you are one of the last three survivors
// -- -- Jumper Weapons can no longer store reserve ammunition
// 14/10/2024 - v3.0.3 ------------------------------------------------------------------------------------------------- //
// -- Reduced Zombie Engineer's EMP Grenade Cooldown from 10 seconds to 9 seconds                                        //
// -- Adjusted Zombie Pyro's death explosion to briefly ignite players hit by the blast                                  //
// -- Fixed a bug that allowed Zombie Medic to spawn infinite dispenser entities ( Thanks Psychicpie! )                    //
// -- Fixed Zombie Heavy's ability appearing as an active instead of a passive on the HUD ( Thanks NeoDement! )            //
// -- Fixed a bug that caused Zombie Heavy's knockback to trigger on afterburn when quickly swapping from Pyro to Heavy  //
// 11/10/2024 - v3.0.2 ------------------------------------------------------------------------------------------------- //
// -- Fixed missing overlay material for Sniper's Spit ability                                                           //
// -- Fixed missing particle effects for Pyro's Dragon's Breath ability                                                  //
// -- Fixed a bug that would cause players to get stuck in spectate mode when attempting to join a game in progress      //
// 22/09/2024 - v3.0.1 ------------------------------------------------------------------------------------------------- //
// -- Added unique kill icons for Zombie arms and Zombie abilities                                                       //
// -- Updated localization strings for Zombie abilities                                                                  //
// 19/09/2024 - v3.0.0 BETA -------------------------------------------------------------------------------------------- //
// -- General Changes                                                                                                    //
// -- -- Removed "mp_respawnwavetime" from Infection convars, respawn wave time will now depend on map configuration     //
// -- -- Changed team names to "Survivors" and "Zombies" ( Instead of "RED" and "BLU" )                                    //
// -- -- -- Note: this change is only visible in casual mode or servers with mp_tournament set to 1                      //
// -- -- Survivor Spies can now disguise as Zombie players                                                               //
// -- -- Human Spy can now disguise as a Zombie and will be seen as a Zombie by the enemy team                           //
// -- -- The Pomson 6000 now puts Zombie abilities on cooldown on hit                                                    //
// -- -- Human Pyro can now destroy Zombie Engineer's EMP Grenade by hitting it with the Homewrecker                     //
// -- -- Walking in to Sniper's Spit now consumes the Spycicle and prevents initial damage                               //
// -- -- Standing in Sniper's Spit now emits additional sound effects on the players for better feedback                 //
// -- Zombie Changes                                                                                                     //
// -- -- Removed Out of combat speed buff from all Zombies                                                               //
// -- -- Zombie Pyro                                                                                                     //
// -- -- -- Zombie Pyro has a new ability - "Dragon's Breath"                                                            //
// -- -- -- -- Fires a fireball in a line that explodes on impact                                                        //
// -- -- -- -- The initial cast of the fireball can reflect projectiles and airblast enemies                             //
// -- -- -- Zombie Pyro now deals mini-crits to burning players on melee hit                                             //
// -- -- -- Zombie Pyro now creates a small explosion on death, knocking back enemies in a 125 hu radius                 //
// -- -- Zombie Demoman                                                                                                  //
// -- -- -- Added new sound effects to Zombie Demoman's Blast Charge ability                                             //
// -- -- Zombie Heavy                                                                                                    //
// -- -- -- Zombie Heavy's health reduced to 450 ( from 600 )                                                              //
// -- -- -- Zombie Heavy now drops a Medium Health Kit on death                                                          //
// -- -- Zombie Sniper                                                                                                   //
// -- -- -- Zombie Sniper's Spit damage vs buildables is now reduced by half                                             //
// -- -- -- Zombie Sniper's Spit now applies a screen overlay to players standing in the pool                            //
// -- -- Zombie Medic                                                                                                    //
// -- -- -- Zombie Medic now emits health like a dispenser to nearby Zombies                                             //
// -- -- -- Zombie Medic can no longer attack while using Heal                                                           //
// -- -- -- Added a new sound effect for Zombie Medic's Heal ability                                                     //
// -- -- Zombie Spy                                                                                                      //
// -- -- -- Zombie Spy no longer emits particle effects while cloaked                                                    //
// -- Bug Fixes                                                                                                          //
// -- -- Fixed a bug that allowed Zombie Demoman to survive his own Blast Charge ( Thanks gasous nebule! )                 //
// -- -- Fixed a bug that caused Zombie Demoman to not receive kill credit when killing players with Blast Charge        //
// -- -- Fixed a bug that caused Zombies to not gib correctly                                                            //
// -- -- Fixed a bug that caused Zombie cosmetics to persist on RED players after the round restarts                     //
// -- -- Fixed a bug that caused Zombie Sniper's Spit Pool to nudge players slightly in certain circumstances            //
// -- -- Fixed a bug that caused players to have the incorrect player skin when respawning at round start                //
// -- -- Fixed a bug that would cause players to get stuck in spectate mode when attempting to join a game in progress   //
// -- -- Fixed an issue with "game_text" entities not being correctly cleared after round reset                          //
// -- -- -- Note: this was originally an issue on MacOS, which is no longer supported by Team Fortress 2                 //
// -- -- Fixed various other bugs with performance, entity management, stability, visuals and sound.                     //
// 22/06/2024 - v2.2.2 ------------------------------------------------------------------------------------------------- //
// -- Added experimental Payload logic to Infection mode                                                                 //
// -- -- Payload logic is automatically enabled when the PL hud is detected                                              //
// -- -- Zombie spawns are enabled/disabled by proximity to the payload cart                                             //
// -- -- Humans dying no longer adds time to the clock in payload mode                                                   //
//                                                                                                                       //
// 14/10/2023 - v2.2.1 ------------------------------------------------------------------------------------------------- //
// -- If a game is in progress and there are no players on BLU team or RED team the game will now end.                   //
// -- Fixed a bug that allowed Dead Ringer spies to die without triggering a round loss                                  //
// -- Fixed a bug that caused Zombies to not see combat text correctly                                                   //
// -- Fixed a bug that caused Rocket Launchers and Sticky Bomb Launchers to start with a low ammo                        //
// -- Fixed a bug that caused changing player loadout to kill human players ( particularly on Murky )                      //
// -- Fixed an issue with missing particle effects for Medic's Heal ability                                              //
// -- Adjusted the number of Zombies selected at round start for low player counts                                       //
//                                                                                                                       //
// -- Corrected unintended changes in the last update:                                                                   //
// -- -- Changed the damage dealt by Zombie Soldier's Stomp                                                              //
// -- -- -- In the previous update, Soldier would instantly kill his stomp target. This was not intended                 //
// -- -- -- The new damage calculation is ( 10 + fall damage x 3 ). This is the same as the Mantreads                      //
// -- -- Changed the Sentry Gun to deal 40% damage to Zombies                                                            //
// -- -- -- In the previous update, this was 35%. This was not intended                                                  //
// -- -- Added a sound effect to Pyro's explosion of flames on death                                                     //
// -- -- Removed some debug print statements                                                                             //
//                                                                                                                       //
// -- Reworked Demoman's Blast Charge to fix several exploits and bugs                                                   //
// -- These changes should also make Blast Charge more reliable and less frustrating to use                              //
// -- -- Blast Charge is now triggered based on the player's velocity                                                    //
// -- -- When player's speed drops below a threshold while charging, they explode                                        //
// -- -- Additionally, anything that would usually interrupt a shield charge will now trigger the explosion              //
// -- -- Fixed a bug that caused ÜberCharge applied by Blast Charge to persist longer than intended                      //
// -- -- Fixed a bug that caused Blast Charge to fail to kill the player in situations where the player should be killed //
// -- -- Fixed a bug that caused Blast Charge to briefly display the player's first person view before detonation        //
// -- -- Fixed a bug that caused the player to be unable to attack, jump or duck after surviving Blast Charge            //
// -- -- Fixed many bugs that caused Blast Charge to fail to detonate                                                    //
// -- -- Fixed many bugs related to Blast Charge being cast at the same time as being converted to Zombie                //
//                                                                                                                       //
// 12/10/2023 - v2.2 --------------------------------------------------------------------------------------------------- //
// -- All Zombies ( except for Scout, Heavy and Spy ) have 25 bonus HP ( up from 10 )                                        //
// -- Starting Zombie Factor is now 1/5 of all players ( previous 1/6 )                                                    //
// -- -- The game will also now always round up the number of starting zombies                                           //
// -- Added additional HIDEHUD bits to remove irrelevant HUD elements when playing Zombie                                //
// -- Reduce damage dealt to Zombies by sentry guns by 60% ( previously 40% )                                              //
// -- Removed damage reduction for Human Demoman wearing a shield                                                        //
// -- Zombie Scout now has an additional 25% jump height                                                                 //
// -- Zombie Heavy now has Battalion's Backup effect                                                                     //
// -- Zombie Heavy has an additional 20% melee damage                                                                    //
// -- Zombie Medic Heal cooldown reduced to 7 seconds ( previously 11 )                                                    //
// -- Zombie Spy is now cloaked on spawn                                                                                 //
// -- -- Attacking or using an ability will remove the cloak                                                             //
// -- -- Cloak will be restored after 3 seconds of not attacking or using an ability                                     //
// -- Zombie Pyro no longer drops a small health pack on death                                                           //
// -- Zombie Pyro now bursts in to a firey explosion on death                                                            //
// -- -- All enemies within 256 hu of a dying Zombie Pyro are set on fire                                                //
// -- Zombie Engineer's EMP Grenade no longer slides on sloped surfaces                                                  //
// -- Zombie Engineer's EMP Grenade now deals 110 damage to all buildings hit                                            //
// -- Zombie Engineer's EMP Grenade can now kill buildings                                                               //
// -- Zombie Sniper's Spit now deals damage to sentry guns, teleporters and dispensers                                   //
// -- Zombie Sniper now drops a spit pool on death                                                                       //
// -- Zombie Soldier's Pounce has been adjusted to feel more like a blast jump                                           //
// -- Zombie Soldier's Pounce cooldown reduced to 5 seconds ( previously 10 )                                              //
// -- Fixed a bug where Zombie Demo could detonate himself before the charge had started                                 //
// -- Fixed a bug where Bonk! Atomic Punch could persist through Zombie conversion                                       //
// -- Fixed a bug where Crit-a-Cola could persist through Zombie conversion                                              //
// -- Fixed various issues caused by Zombie Demo surviving his own charge                                                //
// -- Fixed issues with the Zombie HUD not correctly displaying certain strings                                          //
// -- Fixed autoteam exploit                                                                                             //
// --------------------------------------------------------------------------------------------------------------------- //

// if ( "ZI_Events" in getroottable() ) delete ::ZI_Events

function OnPostSpawn() {

    AddThinkToEnt( self, "GameStateThink" )
    // IncludeScript( "infection_potato/payload_logic.nut", root )
}


PZI_EVENT( "player_spawn", "Infection_PlayerSpawn", function( params ) {

    local _hPlayer = GetPlayerFromUserID( params.userid )

    if ( !_hPlayer )
        return

    if ( !params.team ) {

        _hPlayer.ValidateScriptScope()
        return
    }

    local _iRoundState = GetPropInt( GameRules, "m_iRoundState" )

    _sc <- PZI_Util.GetEntScope( _hPlayer )
    // we use the script overlay material for zombie ability hud
    // so let's make sure it's cleared whenever a player has respawned
    _hPlayer.SetScriptOverlayMaterial( "" )

    // also set their playermodel back to normal
    _hPlayer.SetCustomModelWithClassAnimations( arrTFClassPlayerModels[ _hPlayer.GetPlayerClass() ] )

    // and reset infection specific vars
    _hPlayer.ResetInfectionVars()

    // dumb
    // if ( _hPlayer.GetPlayerClass() ==  TF_CLASS_DEMOMAN || _hPlayer.GetPlayerClass() == TF_CLASS_SOLDIER ) {

    //     _hPlayer.ModifyJumperWeapons()
    // }

    // game hasn't started, player should be a survivor
    if ( !bGameStarted ) {

        // force the player to red team and then respawn them
        if ( _hPlayer.GetTeam() == TEAM_ZOMBIE ) {

            // remove all conditions/attribs that could linger from previous round
            _hPlayer.ClearZombieAttribs()

            // Clean up the player's stuff before respawn
            _hPlayer.RemovePlayerWearables()
            _hPlayer.ResetInfectionVars()
            _hPlayer.ClearZombieEntities()

            ChangeTeamSafe( _hPlayer, TEAM_HUMAN, false )
            _hPlayer.ForceRegenerateAndRespawn()
            return
        }

        // reset all gamemode specific variables
        _hPlayer.ResetInfectionVars()

        // remove all zombie cosmetics/weapons
        _hPlayer.ClearZombieEntities()

        // replaces arm viewmodels and disables zombie skins
        _hPlayer.MakeHuman()

        // make sure the players have the correct amnt of health
        // since we modify all classes' health values when zombie
        // removed with new spawn mechanic

        // _hPlayer.SetHealth( _hPlayer.GetMaxHealth() )
        return
    }
    else { // game has started, player should be a zombie

        if ( _hPlayer.GetTeam() == TEAM_HUMAN ) {

            ChangeTeamSafe( _hPlayer, TEAM_ZOMBIE, false )
            _hPlayer.ForceRegenerateAndRespawn()
            // _hPlayer.TakeDamage( 9999999, DMG_GENERIC, null )
            return
        }

        // add the pending zombie flag
        // the actual zombie conversion is handled in the player's think script
        _sc.m_iFlags <- ( _sc.m_iFlags | ZBIT_PENDING_ZOMBIE )

        // remove all of the player's existing items
        _hPlayer.RemovePlayerWearables()

        // add the zombie cosmetics/skin modifications
        _hPlayer.GiveZombieCosmetics()
        // _hPlayer.GiveZombieEyeParticles()
        // _hPlayer.GiveZombieFXWearable()

        _hPlayer.AddEFlags( EFL_IS_BEING_LIFTED_BY_BARNACLE )
        SendGlobalGameEvent( "post_inventory_application", { userid = GetPlayerUserID( _hPlayer ) } )
        _hPlayer.RemoveEFlags( EFL_IS_BEING_LIFTED_BY_BARNACLE )

        // make sure their health is correct
        _hPlayer.SetHealth ( _hPlayer.GetMaxHealth() )

        // add a tiny delay to zombie conversion for safety
        _hPlayer.SetNextActTime ( ZOMBIE_BECOME_ZOMBIE, 0.1 )
        return
    }

    _hPlayer.ResetInfectionVars()
    return
}, EVENT_WRAPPER_MAIN )

PZI_EVENT( "teamplay_round_start", "Infection_RoundStart", @( params ) PZI_Util.ScriptEntFireSafe( "player", "self.AddEFlags( EFL_IS_BEING_LIFTED_BY_BARNACLE ); self.ForceRegenerateAndRespawn(); self.RemoveEFlags( EFL_IS_BEING_LIFTED_BY_BARNACLE )", 0.1 ) )

PZI_EVENT( "teamplay_setup_finished", "Infection_SetupFinished", function( params ) {

    bGameStarted = true

    local _iPlayerCountRed    = PlayerCount( TEAM_HUMAN )
    local _numStartingZombies = ( _iPlayerCountRed / ( STARTING_ZOMBIE_FAC - ( _iPlayerCountRed < 12 ? 1 : 0 ) ) ) || 1

    // -------------------------------------------------- //
    // select players to become zombies                   //
    // -------------------------------------------------- //

    SetValue( "mp_humans_must_join_team", "blue" )

    if ( ( _iPlayerCountRed <= 1 ) && ( !DEBUG_MODE ) ) {

        PZI_Util.RoundWin( TEAM_HUMAN )
        return
    }

    // ------------------ //
    // enable glow on RED//
    // ------------------//

    // EntFire( "player", "RunScriptCode", "if ( self.GetTeam() == TEAM_HUMAN ) SetPropBool( self, `m_bGlowEnabled`, true )" )

    // local _szZombieNetNames  =  ""
    local _zombieArr = []
    // if ( PZI_Util.PlayerTables.Bots.len() >= _numStartingZombies )
    //     _zombieArr = PZI_Util.PlayerTables.Bots.keys().slice( 0, _numStartingZombies )
    // else
        _zombieArr = GetRandomPlayers( _numStartingZombies, TEAM_HUMAN )

    local _zombieArr_len = _zombieArr.len()

    if ( !_zombieArr_len )
        return

    // ------------------------------------------ //
    // convert the picked players to zombies      //
    // ------------------------------------------ //

    local dummy = CreateByClassname( "logic_autosave" )
    SetPropString( dummy, STRING_NETPROP_NAME, "__pzi_convert_think" )
    dummy.ValidateScriptScope()

    function ConvertPlayers() {

        foreach ( i, _nextPlayer1 in _zombieArr ) {

            local _sc = _nextPlayer1.GetScriptScope()
            // ------------------------------------------- //
            // make sure heavy doesn't get stuck in t-pose //
            // ------------------------------------------- //

            if ( _nextPlayer1.GetPlayerClass() == TF_CLASS_HEAVYWEAPONS ) {

                local _activeWeapon = _nextPlayer1.GetActiveWeapon()
                if ( _activeWeapon && _activeWeapon.GetClassname() == "tf_weapon_minigun" ) {

                    SetPropInt( _activeWeapon, "m_iWeaponState", 0 )
                }
            }
            // remove player conditions that will cause problems
            // when switching to zombie
            _nextPlayer1.ClearProblematicConds()

            // reset all gamemode specific variables
            _nextPlayer1.ResetInfectionVars()

            if ( bZombiesDontSwitchInPlace ) {

                if ( _nextPlayer1.GetPlayerClass() == TF_CLASS_PYRO )
                    _sc.m_iFlags = _sc.m_iFlags | ZBIT_PYRO_DONT_EXPLODE

                PZI_Util.ScriptEntFireSafe( _nextPlayer1, "self.TakeDamage( INT_MAX, DMG_GENERIC, null )", 0.1 )
                PZI_Util.ScriptEntFireSafe( _nextPlayer1, "self.ForceRespawn()", 0.2 )
                yield _nextPlayer1
                // continue
            }
            else
                ChangeTeamSafe( _nextPlayer1, TEAM_ZOMBIE, false )

            // remove all of the player's existing items
            _nextPlayer1.RemovePlayerWearables()

            // add the zombie cosmetics/skin modifications
            _nextPlayer1.GiveZombieCosmetics()

            _nextPlayer1.GiveZombieEyeParticles()

            _nextPlayer1.AddEFlags( EFL_IS_BEING_LIFTED_BY_BARNACLE )
            SendGlobalGameEvent( "post_inventory_application", { userid = PZI_Util.PlayerTables.All[ _nextPlayer1 ] } )
            _nextPlayer1.RemoveEFlags( EFL_IS_BEING_LIFTED_BY_BARNACLE )

            // add the pending zombie flag
            // the actual zombie conversion is handled in the player's think script
            _sc.m_iFlags <- ( ( _sc.m_iFlags | ZBIT_PENDING_ZOMBIE ) )

            // don't delay zombie conversion when the player is alive.
            _nextPlayer1.SetNextActTime ( ZOMBIE_BECOME_ZOMBIE, INSTANT )
            _nextPlayer1.SetNextActTime ( ZOMBIE_ABILITY_CAST, 0.1 )

            // ------------------------------------------- //
            // build string for chat notification          //
            // ------------------------------------------- //

            // if ( !i ) { // first player in the message

            //     _szZombieNetNames = "\x07FF3F3F" + NetName( _nextPlayer1 ) + "\x07FBECCB" + "\x07FBECCB"
            // }
            // else if ( i + 1 == _zombieArr_len ) { // last player in the message

            //     if ( _zombieArr_len > 1 ) 
            //         _szZombieNetNames += ( "\x07FBECCB " + STRING_UI_AND + " \x07FF3F3F" + NetName( _nextPlayer1 ) + "\x07FBECCB" )
            //     else
            //         _szZombieNetNames += ( "\x07FBECCB, \x07FF3F3F" + NetName( _nextPlayer1 ) + "\x07FBECCB" )

            //     _szZombieNetNames += ( NetName( _nextPlayer1 ) + "\x07FBECCB" )
            // }
            // else { // players in the middle get commas

            //     _szZombieNetNames += ( "\x07FBECCB, \x07FF3F3F" + NetName( _nextPlayer1 ) + "\x07FBECCB" )
            // }
            yield _nextPlayer1
        }

        PlayGlobalBell()

        // show the first infected announce message to all players
        return
    }

    local convert_gen = ConvertPlayers()
    resume convert_gen // run once before thinking

    function ConvertPlayersThink() {

        if ( convert_gen.getstatus() == "dead" )
            return self.Kill(), 1

        return resume convert_gen, -1
    }
    dummy.GetScriptScope().ConvertPlayersThink <- ConvertPlayersThink
    AddThinkToEnt( dummy, "ConvertPlayersThink" )
    SetPropBool( dummy, STRING_NETPROP_PURGESTRINGS, true )

    for ( local _hNextRespawnRoom; _hNextRespawnRoom = FindByClassname( _hNextRespawnRoom, "func_respawnroom" ); ) {

        if ( _hNextRespawnRoom.GetTeam() == TEAM_HUMAN ) {

            EntFireByHandle( _hNextRespawnRoom, "SetInactive", "", -1, null, null )
        }
    }

}, EVENT_WRAPPER_MAIN )

PZI_EVENT( "teamplay_restart_round", "Infection_RestartRound", function( params ) {

    bGameStarted = false

    local _hNextPlayer = null

    // --------------------------- //
    // set all players to survivor //
    // --------------------------- //
    SetValue( "mp_humans_must_join_team", "red" )

    PZI_Util.ValidatePlayerTables()

    foreach ( _hNextPlayer in PZI_Util.PlayerTables.All.keys() ) {

        _hNextPlayer.ResetInfectionVars()
        _hNextPlayer.ClearZombieEntities()

        _hNextPlayer.MakeHuman()
        _hNextPlayer.SetHealth( _hNextPlayer.GetMaxHealth() )
    }

    EntFire( "__pzi_hud*", "Kill" )

    return

}, EVENT_WRAPPER_MAIN )

PZI_EVENT( "player_death", "Infection_PlayerDeath", function( params ) {

    local _hPlayer      =  GetPlayerFromUserID ( params.userid )
    local _hKiller      =  GetPlayerFromUserID ( params.attacker )
    local _iDamageType  =  params.damagebits
    local _iWeaponIDX   =  params.weapon_def_index

    if ( !_hPlayer )
        return

    local _sc                  =  _hPlayer.GetScriptScope()

    // if ( !_sc ) return
    local _iClassNum           =  _hPlayer.GetPlayerClass()
    local _hPlayerTeam         =  _hPlayer.GetTeam()
    local _bIsEngineerWithEMP  =  ( _hPlayer.GetPlayerClass() == TF_CLASS_ENGINEER && _hPlayer.CanDoAct( ZOMBIE_ABILITY_CAST ) )

    SetPropIntArray( _hPlayer, STRING_NETPROP_MDLINDEX_OVERRIDES, 0, 3 )
    
    _hPlayer.AcceptInput( "DispatchEffect", "ParticleEffectStop", null, null )

    if ( bGameStarted ) {

        // evaluate win condition when a player dies
        ShouldZombiesWin( _hPlayer )

        // player was survivor
        if ( _hPlayerTeam == TEAM_HUMAN ) {

            if ( _hKiller && _hPlayer && _hKiller.IsPlayer() && _hKiller.GetTeam() == TEAM_ZOMBIE ) {

                // show a notifcation to all players in chat.
                local _szDeathMsg = format( STRING_UI_CHAT_INFECT_MSG,
                                            NetName( _hPlayer ),
                                            NetName( _hKiller ) )

                ClientPrint( null, HUD_PRINTTALK, _szDeathMsg )
            }
            else { // player died to enviro/other, announce they were infected with no killer name

                local _szDeathMsg = format ( STRING_UI_CHAT_INFECT_SOLO_MSG,
                                            NetName( _hPlayer ) )

                ClientPrint( null, HUD_PRINTTALK, _szDeathMsg )
            }

            // dead ringer death
            if ( ( params.death_flags & TF_DEATH_FEIGN_DEATH ) ) {

                PlayGlobalBell( true )
                return
            }


            // make sure players can only add time once per round
            if ( "m_bCanAddTime" in _sc && !_sc.m_bCanAddTime )
                return

            // don't add time if we're actively converting players on round start
            else if ( FindByName( null, "__pzi_convert_think" ) )
                return
            // else if ( bIsPayload )
                // return // don't add time to the round timer if it's a payload map

            PlayGlobalBell()
            PZI_MapLogic.GetRoundTimer().AcceptInput( "AddTime", ""+ADDITIONAL_SEC_PER_PLAYER, null, null )
            // EntFire( "team_round_timer", "AddTime", ""+ADDITIONAL_SEC_PER_PLAYER )
            foreach ( player in PZI_Util.PlayerTables.All.keys() )
                StopSoundOn( "Announcer.TimeAdded", player )

            // control this from PlayGlobalBell instead
            // PZI_Util.ScriptEntFireSafe( "player", "StopSoundOn(`Announcer.TimeAdded`, self)" )
            _sc.m_bCanAddTime = false

            return
        }

        if ( _hPlayerTeam == TEAM_ZOMBIE ) { // zombie has died

            // Kill all dropped ammo packs, we replaced health drops with ammo drops
            EntFire( "tf_ammo_pack", "Kill" )

            if ( _iClassNum == TF_CLASS_MEDIC )
                _hPlayer.ClearZombieEntity( "m_hMedicDispenser" )

            else if ( _iClassNum == TF_CLASS_SNIPER && !( _hPlayer.GetFlags() & FL_ATCONTROLS ) ) {

                _sc.m_hZombieAbility.CreateSpitball( true )
            }

            else if ( _iClassNum == TF_CLASS_PYRO ) {

                local _hNextPlayer
                local _hKillicon = KilliconInflictor( KILLICON_PYRO_BREATH )

                // CreateMediumHealthKit( _hPlayer.GetOrigin() )
                CreatePackPickup( _hPlayer.GetOrigin(), "item_ammopack_small" )

                if ( !bNoPyroExplosionMod && !( _sc.m_iFlags & ZBIT_PYRO_DONT_EXPLODE ) ) {

                    while ( _hNextPlayer = FindByClassnameWithin( _hNextPlayer, "player", _hPlayer.GetOrigin(), 125 ) ) {

                        if ( _hNextPlayer && _hNextPlayer.GetTeam() == TEAM_HUMAN && _hNextPlayer != _hPlayer ) {

                            KnockbackPlayer( _hPlayer, _hNextPlayer, 210, 0.85, true )
                            _hNextPlayer.TakeDamageEx( _hKillicon, _hPlayer, _hPlayer.GetActiveWeapon(), Vector(), _hPlayer.GetOrigin(), 10, ( DMG_CLUB | DMG_PREVENT_PHYSICS_FORCE ) )
                        }
                    }

                    _hKillicon.Destroy()

                    EmitSoundOn( SFX_PYRO_FIREBOMB, _hPlayer )
                    PZI_Util.DispatchEffect( _hPlayer, "fireSmokeExplosion_track" )
                }

            }

            else {

                local _szKitType = "item_ammopack_" + ( _iClassNum == TF_CLASS_HEAVYWEAPONS ? "medium" : "small" )
                CreatePackPickup( _hPlayer.GetOrigin(), _szKitType )
            }

            // ------------------------------------- //
            // remove zombie "vgui"                  //
            // ------------------------------------- //
            // we use the script overlay material for zombie ability hud
            // so let's make sure it's cleared whenever a player has respawned
            _hPlayer.SetScriptOverlayMaterial( "" )

            // same thing for the HUD text channels
            if ( _sc.m_hHUDText && _sc.m_hHUDText.IsValid() ) {

                _sc.m_hHUDText.KeyValueFromString( "message", "" )
                _sc.m_hHUDText.AcceptInput( "Display", null, _hPlayer, _hPlayer )
            }

            if ( _sc.m_hHUDTextAbilityName && _sc.m_hHUDText.IsValid() ) {

                _sc.m_hHUDTextAbilityName.KeyValueFromString( "message", "" )
                _sc.m_hHUDTextAbilityName.AcceptInput( "Display", null, _hPlayer, _hPlayer )
            }

            // ------------------------------------- //
            // Zombie Gib Hack                       //
            // ------------------------------------- //
            // when a player has the zombie skin override, they are hard coded to never gib
            // if we remove this skin here it creates gibs for the player
            SetPropInt( _hPlayer, "m_iPlayerSkinOverride", 0 )

            // we set custom model on the player afterwards because otherwise the gibs come out red
            _hPlayer.SetCustomModelWithClassAnimations( arrTFClassPlayerModels[ _iClassNum ] )

            // ------------------------------------- //
            // Check if Need Demoman Explosion       //
            // ------------------------------------- //

            if ( ( _sc.m_iFlags & ZBIT_MUST_EXPLODE ) ) {

                _sc.m_iFlags <- ( _sc.m_iFlags & ~ZBIT_MUST_EXPLODE )
                _sc.m_tblEventQueue <- { }

                // ---------------------------------------- //
                // check for buildings and find the nearest //
                // to become the explosion origin           //
                // ---------------------------------------- //

                if ( "m_hAbilityOwner" in this ) {

                    DemomanExplosionPreCheck( m_hAbilityOwner.GetOrigin(),
                                            DEMOMAN_CHARGE_BASE_DAMAGE,
                                            DEMOMAN_CHARGE_DAMAGE_PER_PLAYER_MULT,
                                            DEMOMAN_CHARGE_RADIUS,
                                            m_hAbilityOwner,
                                            DEMOMAN_CHARGE_FORCE,
                                            DEMOMAN_CHARGE_FORCE_UPWARD_MULT )

                }
            }

            // hide our fx wearable to stop the particles from generating
            SetPropInt( _sc.m_hZombieFXWearable, "m_nRenderMode", kRenderNone )

            _hPlayer.ClearZombieEntity( "m_hZombieWearable" )

            _hPlayer.AddEFlags( EFL_IS_BEING_LIFTED_BY_BARNACLE )
            SendGlobalGameEvent( "post_inventory_application", { userid = GetPlayerUserID( _hPlayer ) } )
            _hPlayer.RemoveEFlags( EFL_IS_BEING_LIFTED_BY_BARNACLE )

            _hPlayer.ClearZombieEntity( "m_hZombieFXWearable" )

            return; // zombie death event ends here
        }
    }
}, EVENT_WRAPPER_MAIN )

local special_weapons = { [ID_GOLDEN_WRENCH] = null, [ID_SAXXY] = null, [ID_SPY_CICLE] = null, [ID_GOLD_FRYING_PAN] = null }
PZI_EVENT( "OnTakeDamage", "Infection_OnTakeDamage", function( params ) {

    if ( !params.inflictor || !params.attacker )
        return

    local _hVictim        =   params.const_entity
    local _hAttacker      =   params.attacker
    local _hInflictor     =   params.inflictor
    local _sc             =   _hVictim.GetScriptScope() || ( _hVictim.ValidateScriptScope(), _hVictim.GetScriptScope() )
    local _iWeaponIDX     =   0
    local _szWeaponName   =   "none"
    local _iForceGibDmg   =   ( _hVictim.GetMaxHealth() + 20 )
    local _szKillicon     =   ""
    if ( _hVictim.GetName() == "engie_nade_physprop" ) {

        if ( _hAttacker.IsPlayer() ) { // must check before trying to access active weapon

            if ( _hAttacker.GetPlayerClass() == TF_CLASS_PYRO && _hAttacker.GetActiveWeapon().GetPropInt( STRING_NETPROP_ITEMDEF ) == 153 ) { // homewrecker

                _hVictim.GetScriptScope().m_bMustFizzle <- true
            }
        }
    }
    if ( !_hVictim.IsPlayer() || _hVictim.GetHealth() <= 0 )
        return

    // nasty stuff here //
    try{ _szWeaponName = params.weapon.GetClassname() }
    catch( e ){}

    if ( _hAttacker.GetClassname() == "obj_sentrygun" || _hInflictor.GetClassname() == "obj_sentrygun" ) {

        _szWeaponName = "obj_sentrygun"
    }

    if ( _hAttacker == worldspawn || _hInflictor == worldspawn ) {

        _szWeaponName = "worldspawn"
    }

    if ( _sc && "m_iFlags" in _sc && _sc.m_iFlags & ZBIT_MUST_EXPLODE ) {

        if ( _hVictim == _hAttacker && _hInflictor.GetClassname() == "tf_generic_bomb" )
            params.damage = ( _iForceGibDmg )

        if ( params.damage >= ( _hVictim.GetHealth() ) )
            params.damage = ( _iForceGibDmg )

        return
    }

    local _iOriginalDmgBits = params.damage_type

    if ( _hVictim.GetTeam() == TEAM_ZOMBIE ) {

        // ---------------------------------------------------------------------- //
        // On Zombie receives damage from player                                  //
        // ---------------------------------------------------------------------- //
        // add DMG_BLAST to the damage bits
        // to force the zombie to explode in to gibs
        if ( params.damage_type & ~DMG_BLAST ) {

            // if the damage isn't already blast we add blast
            params.damage_type = _iOriginalDmgBits | DMG_BLAST | DMG_PREVENT_PHYSICS_FORCE
        }

        if ( _szWeaponName != "worldspawn" ) {

            // fall damage is caught and removed
            // so only set this if it's not world damage
            _sc.m_fTimeLastHit <- Time()
        }

        // ---------------------------------------------------------------------- //
        // make sure we're not modifying a weapon with a special kill attribute   //
        // ---------------------------------------------------------------------- //

        try{ _iWeaponIDX = GetPropInt( _hAttacker.GetActiveWeapon(), STRING_NETPROP_ITEMDEF ); }
        catch( e ){}

        if (  _iWeaponIDX in special_weapons ) {

            params.damage_type = _iOriginalDmgBits
        }

        if ( _hVictim.GetPlayerClass() == TF_CLASS_PYRO && ( params.damage_type & DMG_BURN ) ) {

            params.damage *= 0.5
            return
        }

        // base weapon adjustments
        if ( _hAttacker.IsPlayer() && _szWeaponName != "none" ) {

            switch ( _hAttacker.GetPlayerClass() ) {

                // case TF_CLASS_SNIPER:

                //     if ( _szWeaponName == "tf_weapon_compound_bow" ) {

                //         // no longer modified
                //         params.damage = ( params.damage )
                //     }

                //     break

                // case TF_CLASS_MEDIC:

                    // if ( _szWeaponName == "tf_weapon_crossbow" ) {

                    //     // no longer modified
                    //     params.damage = ( params.damage )
                    // }

                    // break

                case TF_CLASS_HEAVYWEAPONS:

                    if ( _szWeaponName == "tf_weapon_minigun" ) {

                        params.damage *= TF_NERF_MINIGUN_Z_DMG
                    }

                    break

                // case TF_CLASS_PYRO:
                //     if ( _hVictim.GetPlayerClass() != TF_CLASS_PYRO )
                //         return

                //     if ( _szWeaponName == "tf_weapon_flamethrower" ||
                //         _szWeaponName == "tf_weapon_flamethrower_rocket" ||
                //         _szWeaponName == "tf_weapon_flaregun"  ) {

                //         params.damage *= 0
                //     }

                //     break

                default:
                    break
            }

        }

        if ( _szWeaponName == "obj_sentrygun" ) {

        params.damage *= TF_NERF_SENTRY_Z_DMG
        }

        if ( params.damage_type & DMG_FALL && _szWeaponName == "worldspawn" ) {

            // solider can mantreads stomp when jumping
            if ( _hVictim.GetPlayerClass() == TF_CLASS_SOLDIER && _hVictim.InCond( TF_COND_BLASTJUMPING ) ) {

                local _flDamage = params.damage
                local _hGroundEnt = GetPropEntity( _hVictim, "m_hGroundEntity" )

                if ( _hGroundEnt.IsPlayer() ) {

                    _flDamage = ( _flDamage * 3 ) + 10
                    if ( _hGroundEnt.GetTeam() == TEAM_ZOMBIE || !( _sc.m_iFlags & ZBIT_SOLDIER_IN_POUNCE ) )
                        return

                    local _hWeapon = _hVictim.GetActiveWeapon()

                    SetPropInt( _hWeapon, STRING_NETPROP_ITEMDEF, 444 ); // mantreads, obviously

                    ScreenShake( _hGroundEnt.GetOrigin(), 12.5, 145.0, 1.0, 490, 0, false )
                    PZI_Util.DispatchEffect( _hVictim, FX_TF_STOMP_TEXT )

                    _hGroundEnt.TakeDamageCustom( _hVictim, _hVictim, _hWeapon,
                                                Vector( 0, 0, 0 ), _hVictim.GetOrigin(),
                                                _flDamage, DMG_FALL, TF_DMG_CUSTOM_BOOTS_STOMP )

                    SetPropInt( _hWeapon, STRING_NETPROP_ITEMDEF, arrZombieCosmeticIDX[ TF_CLASS_SOLDIER ] )
                    EmitAmbientSoundOn( "Weapon_Mantreads.Impact", 10, 1, 100, _hGroundEnt )
                    EmitAmbientSoundOn( "Player.FallDamageDealt", 10, 1, 100, _hGroundEnt )

                    _sc.m_iFlags = (  _sc.m_iFlags & ~ZBIT_SOLDIER_IN_POUNCE )
                }
            }

            params.damage = ( 0 )
        }
    }

    // ----------------------------------------------------------- //
    // zombie applies damage to survivors                          //
    // ----------------------------------------------------------- //

    if ( _hAttacker.IsPlayer() &&
        _hVictim.GetTeam() == TEAM_HUMAN &&
        _hAttacker.GetTeam() == TEAM_ZOMBIE ) {

        local _sc = _hAttacker.GetScriptScope()

        // ----------------------------------------------------------- //
        // zombie heavy knock up effect                                //
        // ----------------------------------------------------------- //

        if ( _hAttacker.GetPlayerClass() == TF_CLASS_HEAVYWEAPONS && _hAttacker.GetTeam() == TEAM_ZOMBIE && params.damage_type & DMG_CLUB ) {

            if ( !_hVictim || !_hVictim.IsPlayer() )
                return

            local _iPushForce  =  HEAVY_KNOCK_BACK_FORCE
            local _vecFwd      =  _hAttacker.EyeAngles().Forward()
            local _vecBump     =  Vector( 0, 0, _iPushForce * 2 )
            local _vecThrow    =  ( ( _vecFwd * _iPushForce ) + _vecBump )

            SetPropEntity         ( _hVictim, "m_hGroundEntity", null )
            _hVictim.AddCond      ( TF_COND_KNOCKED_INTO_AIR )
            _hVictim.RemoveFlag   ( FL_ONGROUND )

            _hVictim.ApplyAbsVelocityImpulse ( _vecThrow )
            EmitSoundOn( "DemoCharge.HitFlesh", _hVictim ); // todo - const
        }

        // ----------------------------------------------------------- //
        // zombie demo charge knock up effect                          //
        // ----------------------------------------------------------- //
        if ( _hAttacker.GetPlayerClass() == TF_CLASS_DEMOMAN && _hAttacker.GetTeam() == TEAM_ZOMBIE && _hInflictor.GetClassname() == KILLICON_DEMOMAN_BOOM ) {

            if ( !_hVictim || !_hVictim.IsPlayer() )
                return

            local _iPushForce  =  DEMOMAN_CHARGE_FORCE
            local _vecFwd      =  _hAttacker.EyeAngles().Forward()
            local _vecBump     =  Vector( 0, 0, _iPushForce * DEMOMAN_CHARGE_FORCE_UPWARD_MULT )
            local _vecThrow    =  ( ( _vecFwd * _iPushForce ) + _vecBump )

            SetPropEntity         ( _hVictim, "m_hGroundEntity", null )
            _hVictim.AddCond      ( TF_COND_KNOCKED_INTO_AIR )
            _hVictim.RemoveFlag   ( FL_ONGROUND )

            _hVictim.ApplyAbsVelocityImpulse ( _vecThrow )
            EmitSoundOn( "DemoCharge.HitFlesh", _hVictim ); // todo - const
        }

        // ----------------------------------------------------------- //
        // zombie pyro on-hit fire effect                              //
        // ----------------------------------------------------------- //

        if ( _hVictim.InCond( TF_COND_BURNING ) && params.damage_type & DMG_CLUB ) {

            _hAttacker.AddCondEx( TF_COND_OFFENSEBUFF, 0.1, _hAttacker )
        }

        if ( _hAttacker.GetPlayerClass() == TF_CLASS_PYRO &&
            _hAttacker.GetTeam() == TEAM_ZOMBIE && params.damage_type & DMG_CLUB ) {

            local _hIgniteTrigger = SpawnEntityFromTable( "trigger_ignite", {

                burn_duration             = 3,
                damage_percent_per_second = 8,
                spawnflags                = 1,
                solid                     = 2,
            })

            _hIgniteTrigger.SetAbsOrigin  ( _hVictim.GetCenter() )

            EntFireByHandle ( _hIgniteTrigger, "StartTouch", null, -1, _hVictim, _hVictim )
            EntFireByHandle ( _hIgniteTrigger, "Kill", null, 0.01, null, null )
        }

        // ----------------------------------------------------------- //
        // zombie deals fatal damage with arms                         //
        // ----------------------------------------------------------- //

        if ( ( params.damage > _hVictim.GetHealth() ) &&
            ( params.damage_type & DMG_CLUB ) ) {

            // killicon switch
            switch ( _hAttacker.GetPlayerClass() ) {
                case TF_CLASS_SCOUT:
                    _szKillicon = KILLICON_SCOUT_MELEE
                    break
                case TF_CLASS_SOLDIER:
                    _szKillicon = KILLICON_SOLDIER_MELEE
                    break
                case TF_CLASS_PYRO:
                    _szKillicon = KILLICON_PYRO_MELEE
                    break
                case TF_CLASS_DEMOMAN:
                    _szKillicon = KILLICON_DEMOMAN_MELEE
                    break
                case TF_CLASS_HEAVYWEAPONS:
                    _szKillicon = KILLICON_HEAVY_MELEE
                    break
                case TF_CLASS_ENGINEER:
                    _szKillicon = KILLICON_ENGIE_MELEE
                    break
                case TF_CLASS_MEDIC:
                    _szKillicon = KILLICON_MEDIC_MELEE
                    break
                case TF_CLASS_SNIPER:
                    _szKillicon = KILLICON_SNIPER_MELEE
                    break
                case TF_CLASS_SPY:
                    _szKillicon = KILLICON_SPY_MELEE
                    break
                default:
                    _szKillicon = "unarmed_combat"
                    break
            }

            SlayPlayerWithSpoofedIDX( _hAttacker,
                                    _hVictim,
                                    _hAttacker.GetActiveWeapon(),
                                    params.damage_force,
                                    params.damage_position,
                                    ZOMBIE_SPOOF_WEAPON_IDX,
                                    _szKillicon )

            params.early_out = true
        }

        // register the time we hit someone
        // and remove out of combat buff
        if ( _sc ) _sc.m_fTimeLastHit <- Time()
        _hAttacker.RemoveOutOfCombat()
        return
    }
}, EVENT_WRAPPER_MAIN )

PZI_EVENT( "player_hurt", "Infection_PlayerHurt", function( params ) {

    local _hPlayer   = GetPlayerFromUserID ( params.userid )
    local _hAttacker = GetPlayerFromUserID ( params.attacker )
    local _sc        = _hPlayer.GetScriptScope()

    // if ( !_sc ) return

    local _iTeamNum  = _hPlayer.GetTeam()

    if ( _iTeamNum == TEAM_ZOMBIE ) {

        // on zombie death
        if ( params.health <= 0 ) {

            // force gibs on zombie death
            SetPropInt( _hPlayer, "m_iPlayerSkinOverride", 0 )
            _hPlayer.SetHealth( -20 ); // force overkill threshhold
            _hPlayer.AcceptInput( "DispatchEffect", "ParticleEffectStop", null, null )

            _hPlayer.SetCustomModelWithClassAnimations( arrTFClassPlayerModels[ _hPlayer.GetPlayerClass() ] )
            return
        }

        else if ( _hAttacker && _hAttacker.IsPlayer() ) {

            local _hAttackerWeapon = _hAttacker.GetActiveWeapon()

            if ( _hAttackerWeapon && _hAttackerWeapon.GetClassname() == "tf_weapon_drg_pomson" ) {

                local _flCooldownMod = DRG_RAYGUN_ZOMBIE_COOLDOWN_MOD

                if ( _flCooldownMod == -1 ) {

                    _flCooldownMod = _sc.m_hZombieAbility.m_fAbilityCooldown
                }

                _hPlayer.SetNextActTime( ZOMBIE_ABILITY_CAST, _flCooldownMod )
            }
        }
    }
    else if ( _iTeamNum == TEAM_HUMAN ) {

        // on survivor death
        if ( params.health <=  0 ) {

            // clear script overlay material ( probably imcookin green )
            _hPlayer.SetScriptOverlayMaterial( "" )
        }
    }
}, EVENT_WRAPPER_MAIN )