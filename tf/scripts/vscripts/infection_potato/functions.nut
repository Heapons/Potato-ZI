
/**************************************************************************************************
 *                                                                                                *
 * All Code By: Harry Colquhoun ( https://steamcommunity.com/profiles/76561198025795825 )         *
 * Assets/Game Design by: Diva Dan ( https://steamcommunity.com/profiles/76561198072146551 )      *
 * Modified for Potato.TF by: Braindawg ( https://steamcommunity.com/profiles/76561197988531991 ) *
 *                                                                                                *
***************************************************************************************************
 * utility functions                                                                              *
***************************************************************************************************/

function PrecacheResources() {

    local function PrecacheParticle( name ) { PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = name } ) }

    local prefixes = {
        SFX = "PrecacheSound"
        FX  = "PrecacheParticle"
        MDL = "PrecacheModel"
    }
    local i = 0
    foreach ( _key, _value in getconsttable() ) {

        for ( local j = 4; j < 0; j++ )
            if ( _key.slice( 0, j ) in prefixes )
                this[ prefixes[ _key.slice( 0, j ) ] ]( value )

        i++
        if ( !(i & 2000) )
            yield i || 1
    }

    foreach ( particle in szEyeParticles )
        yield PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = particle } ), i

    return
}

function RoundUp( _fValue ) {

    local _iPart = _fValue.tointeger()

    if( _fValue > _iPart ) {

        return _iPart + 1
    }

    return _iPart
}

function GetPlayerUserID( _hPlayer ) { return GetPropIntArray( TFPlayerManager, "m_iUserID", _hPlayer.entindex() ) }

function PlayerCount( _team = -1 ) {

    // local playerCount   = 0
    // local targetTeamCount = 0

    // for ( local i = 1, player; i <= MaxPlayers; player = PlayerInstanceFromIndex( i ), i++ )
    //     if ( player && ( player.GetTeam() == _team || _team == -1 ) )
    //         playerCount++

    // return playerCount

    PZI_Util.ValidatePlayerTables()
    return (PZI_Util.PlayerArray.filter( @(i, player) _team == -1 || player.GetTeam() == _team ) ).len()
}

function PlayGlobalBell( _bForce = false ) {

    if ( _bForce || Time() - flTimeLastBell > GLOBAL_BELL_DELAY ) {

        SendGlobalGameEvent( "teamplay_broadcast_audio", { team = 255, sound = "Halloween.PlayerEscapedUnderworld" })
        flTimeLastBell = Time()

    }
}

// damage is multiplied by _flDmgMult for each player in range
function DemomanExplosionPreCheck( _vecLocation, _flDmg, _flDmgMult, _flRange, _hInflictor, _flForceMultiplier = 0.0, _flUpwardForce = 0.0, _iTeamnum = TEAM_ZOMBIE ) {

    local _finalDmg = _flDmg.tofloat() / _flDmgMult.tofloat(); // divide once first to effectively skip the first player

    for ( local _buildable, i = 0; _buildable = FindByClassnameWithin( _buildable, "obj_*", _vecLocation, DEMOMAN_CHARGE_RADIUS ); i++ ) {

        if ( GetPropInt( _buildable, "m_iObjectType" ) == 3 ) // skip sappers
            continue

        if ( i >= 3 )
            break

        _buildable.TakeDamage( 999, DMG_BLAST, _hInflictor )
    }

    if ( _flDmgMult && _flDmgMult != 1.0 ) {

        for ( local _player; _player = FindByClassnameWithin( _player, "player", _vecLocation, _flRange ); ) {

            if ( _player.GetTeam() != TEAM_HUMAN )
                continue

            _finalDmg *= _flDmgMult
        }

    }

    // printl( "Final damage: " + _finalDmg )
    CreateExplosion( _vecLocation,
                     _finalDmg,
                     _flRange,
                     _hInflictor )
    return
}

function CreateExplosion( _vecLocation, _flDmg, _flRange, _hInflictor, _flForceMultiplier = 0.0, _flUpwardForce = 0.0, _iTeamnum = TEAM_ZOMBIE ) {

    ScreenShake ( _vecLocation, 5000, 5000, 4, 350, 0, true )

    if ( _hInflictor.IsPlayer() ) {

        _hInflictor.SetHealth( 1 )
    }

    local _hBomb = SpawnEntityFromTable( "tf_generic_bomb", {

        explode_particle = "mvm_loot_explosion",
        sound            = "Halloween.Merasmus_Hiding_Explode",
        damage           = _flDmg.tostring(),
        radius           = _flRange.tostring(),
        friendlyfire     = "0",
        vscripts     = " "
    } )

    local _hPfxEnt = SpawnEntityFromTable( "info_particle_system", {

        effect_name  = FX_DEMOGUTS,
        start_active = "0",
        targetname   = "ZombieDemo_Explosion_PFX_Ent",
        origin       = _vecLocation,
        vscripts     = " "
    } )

    _hPfxEnt.GetScriptScope     ().m_flKillTime <- ( Time() + 2.0 ).tofloat()

    AddThinkToEnt( _hPfxEnt, "KillMeThink" )

    _hBomb.GetScriptScope     ().m_flKillTime <- ( Time() + 0.1 ).tofloat()
    _hBomb.GetScriptScope     ().m_hOwner     <- _hInflictor

    ::DispatchSpawn( _hPfxEnt )

    EntFireByHandle ( _hPfxEnt, "Start",    "", -1, null, null )

    SetPropInt      ( _hBomb, "m_iTeamNum", TEAM_ZOMBIE )
    EmitSoundOn     ( "Breakable.MatFlesh", _hBomb )
    EmitSoundOn     ( "Halloween.Merasmus_Hiding_Explode", _hBomb )

    ::DispatchSpawn( _hBomb )

    _hBomb.SetTeam       ( TEAM_ZOMBIE )
    _hBomb.SetAbsOrigin     ( _vecLocation )
    _hBomb.SetOwner      ( _hInflictor )
    // KnockbackPlayer( _hBomb, _hInflictor, _flForceMultiplier, _flUpwardForce, Vector( 400, 400, 400 ), true )

    // EntFireByHandle ( _hBomb,   "Detonate", "", -1, _hInflictor, _hInflictor )
    _hBomb.KeyValueFromString( "classname", KILLICON_DEMOMAN_BOOM )
    _hBomb.TakeDamage( 1, DMG_CLUB, _hInflictor )
    _hInflictor.TakeDamage( 1, DMG_NEVERGIB, _hInflictor )
    // _hInflictor.TakeDamageEx( _hBomb, _hInflictor, null, Vector( _flForceMultiplier, _flForceMultiplier, _flForceMultiplier * _flUpwardForce ), _hInflictor.GetOrigin(), _flDmg, DMG_CLUB )
    return
}

function _GetAllPlayers( team = null ) {

    for ( local i = 1, player; i <= MaxPlayers; player = PlayerInstanceFromIndex( i ), i++ )
        if ( player && ( team == null || player.GetTeam() == team ) )
            yield player

    return
}

function GetAllPlayers( team = null ) {

    foreach ( player in PZI_Util.PlayerArray )
        if ( player && ( team == null || player.GetTeam() == team ) )
            yield player

    return
}

function GetRandomPlayers( _howMany = 1, team = null ) {

    local u = PZI_Util
    local _playerArr =  u.PlayerArray

    if ( team != null && team > TEAM_SPECTATOR )
        _playerArr = u[ u.PLAYER_TABLES[ team == TEAM_HUMAN ? TEAM_HUMAN : TEAM_ZOMBIE ] ].keys()

    local _arrLen = _playerArr.len()

    if ( _howMany >= _arrLen )
        _howMany = _arrLen - 1

    local _selectedPlayers = array( _howMany )

    for ( local i = 0; i < _howMany; i++ )
        _selectedPlayers[i] = _playerArr[RandomInt( 0, _arrLen - 1 )]

    return _selectedPlayers
}

function ChangeTeamSafe( _hPlayer, _iTeamNum, _bForce = false ) {

    if ( !_hPlayer || !_hPlayer.IsValid() || _iTeamNum < TEAM_SPECTATOR )
        return
    else if ( _iTeamNum > TEAM_ZOMBIE || _hPlayer.GetTeam() == _iTeamNum )
        return

    // m_bIsCoaching trick to change team even if player is in a duel ( source: vdc )
    SetPropBool( _hPlayer, "m_bIsCoaching", true  )
    _hPlayer.ForceChangeTeam( _iTeamNum, _bForce  )
    SetPropBool( _hPlayer, "m_bIsCoaching", false )

    return
}

function NetName( _hPlayer ) {

    if ( !_hPlayer )
        return "[UNKNOWN/INVALID PLAYER]"

    local _szNetname = GetPropString( _hPlayer, "m_szNetname" )

    if ( !_szNetname || typeof _szNetname != "string" || _szNetname == "" )
        return "[BAD NETNAME]"

    return _szNetname
}

function PlayerIsValid( _hPlayer ) {

    if ( !_hPlayer )
        return false

    return true
}

function ShouldZombiesWin( _hPlayer ) {

    local _iValidSurvivors = 0
    local _iValidPlayers   = 0

    // count all valid survivors to see if the game should end
    for ( local i = 1; i <= MaxPlayers; i++ ) {

        local _player = PlayerInstanceFromIndex( i )

        if ( _player ) {

            _iValidPlayers++

            // if the player is valid, on survivor ( red ) team, alive, and not the player who just died
            if ( ( _player ) &&
                 ( _player.GetTeam() == TEAM_HUMAN ) &&
                 ( _player.IsAlive() ) && _player != _hPlayer ) {

                 _iValidSurvivors++
            }
        }
    }

    // GetAllPlayers didn't find any players, should never happen
    if ( !_iValidPlayers ) {

        return
    }

    if ( _iValidSurvivors == 3 ) {

        ClientPrint( null, HUD_PRINTTALK, format( STRING_UI_CHAT_LAST_SURV_YELLOW, _iValidSurvivors, STRING_UI_MINI_CRITS ) )
    }

    // check if zombies have killed enough survivors to win
    if ( _iValidSurvivors <= MAX_SURVIVORS_FOR_ZOMBIE_WIN ) {

       PZI_Util.RoundWin( TEAM_ZOMBIE )
       return
    }
    else {

        if ( _iValidSurvivors == 1 ) { // last guy

            foreach( _hNextPlayer in GetAllPlayers() ) {

                if ( _hNextPlayer.GetTeam() == TEAM_HUMAN && _hNextPlayer.IsAlive() ) {

                    if ( !_hNextPlayer || _hNextPlayer == _hPlayer )
                        continue

                    ClientPrint( null, HUD_PRINTTALK, format( STRING_UI_CHAT_LAST_SURV_GREEN, NetName( _hNextPlayer ), STRING_UI_CRITS ) )

                    _hNextPlayer.GetScriptScope().m_bLastManStanding <- true
                    _hNextPlayer.GetScriptScope().m_bLastThree       <- false

                    if ( _hNextPlayer.GetPlayerClass() == TF_CLASS_SOLDIER || _hNextPlayer.GetPlayerClass() == TF_CLASS_DEMOMAN ) {

                        local _bDestroyedParachuteResult = _hNextPlayer.HasThisWeapon( 1101, true )
                    }

                    _hNextPlayer.AddCond( TF_COND_CRITBOOSTED )
                }
            }
        }
        else if ( ( _iValidSurvivors < 4 ) && ( _iValidSurvivors > 1 ) ) { // last 3 get minicrits

            foreach( _hNextPlayer in GetAllPlayers() ) {

                if ( _hNextPlayer.GetTeam() == TEAM_HUMAN && _hNextPlayer.IsAlive() ) {

                    if ( !_hNextPlayer )
                        continue

                    _hNextPlayer.GetScriptScope().m_bLastThree <- true
                    _hNextPlayer.AddCond( TF_COND_OFFENSEBUFF )
                    continue
                }
            }
        }
    }

    return
}

function CreateAmmoPack( _vecLocation, _szClassname ) {

    local _hDroppedPack = CreateByClassname( _szClassname )
    ::DispatchSpawn( _hDroppedPack )
    _hDroppedPack.KeyValueFromInt( "AutoMaterialize", 0 )
    _hDroppedPack.SetAbsOrigin( _vecLocation )
    _hDroppedPack.SetMoveType( MOVETYPE_FLYGRAVITY, MOVECOLLIDE_FLY_BOUNCE )
    
    PZI_Util.ScriptEntFireSafe( _hDroppedPack, "self.Kill()", 20.0 )
}

function CreateSmallHealthKit( _vecLocation ) {

    local _hDroppedHealthkit = SpawnEntityFromTable( "item_healthkit_small", {

        origin          = _vecLocation
        AutoMaterialize = false
        StartDisabled   = false
    })

    _hDroppedHealthkit.ValidateScriptScope()

    // zombie dropped health kits last for 20 seconds
    _hDroppedHealthkit.GetScriptScope().m_flKillTime <- ( Time() + 20.0 )

    _hDroppedHealthkit.SetMoveType( MOVETYPE_FLYGRAVITY, MOVECOLLIDE_FLY_BOUNCE )

    AddThinkToEnt( _hDroppedHealthkit, "KillMeThink" )
}

function CreateMediumHealthKit( _vecLocation ) {

    local _hDroppedHealthkit = SpawnEntityFromTable( "item_healthkit_medium", {

        origin          = _vecLocation,
        AutoMaterialize = false,
        StartDisabled   = false,
    } )

    _hDroppedHealthkit.ValidateScriptScope()

    // zombie dropped health kits last for 20 seconds
    _hDroppedHealthkit.GetScriptScope().m_flKillTime <- ( Time() + 20.0 )

    _hDroppedHealthkit.SetMoveType( MOVETYPE_FLYGRAVITY, MOVECOLLIDE_FLY_BOUNCE )

    AddThinkToEnt( _hDroppedHealthkit, "KillMeThink" )
}

function PrintToChat( _szMessage ) {

    if ( !_szMessage || _szMessage == "" || typeof _szMessage != "string" )
        return

    ClientPrint( null, HUD_PRINTTALK, _szMessage )
    return
}

function SlayPlayerWithSpoofedIDX( _hAttacker, _hVictim, _hAttackerWep, _vecDmgForce, _vecDmgPosition, _iIDX = ZOMBIE_SPOOF_WEAPON_IDX, _szKillicon = "" ) {

    if ( !_hAttacker || !_hVictim || !_hAttackerWep )
        return

    local _hKillicon    = KilliconInflictor( _szKillicon )

    // --------------------------------------------------------------------------------------------- //
    // hacky function for technically killing a player with a different weapon to spoof the killicon //
    // this function should only be used when the player has already received lethal damage.         //
    // --------------------------------------------------------------------------------------------- //

    if ( _hVictim.GetClassname() == "obj_sentrygun" ||
         _hVictim.GetClassname() == "obj_dispenser" ||
         _hVictim.GetClassname() == "obj_teleporter" ) {

        // get the existing IDX of the given weapon, so we can swap it back
     //   local _iPreviousIDX = GetPropInt( _hAttacker.GetActiveWeapon(), STRING_NETPROP_ITEMDEF )


        // hack in the IDX of the weapon we want to steal the killicon from
     //   SetPropInt( _hAttackerWep, STRING_NETPROP_ITEMDEF, _iIDX )

        _hVictim.TakeDamageEx( _hKillicon, _hAttacker,
                               _hAttackerWep, _vecDmgForce,
                               _vecDmgPosition, 999, DMG_CLUB ); // using a goofy number is ok
                                                                 // because we've already removed
                                                                 // the player's actual weapons
                                                                 // nobody's stranges will be ruined

        // set the IDX back
     //   SetPropInt( _hAttackerWep, STRING_NETPROP_ITEMDEF, _iPreviousIDX )
    }
    else if ( _hVictim.IsPlayer() ) {

        _hVictim.SetHealth( 1 ); // prep the player to be slain

        // get the existing IDX of the given weapon, so we can swap it back
      //  local _iPreviousIDX = GetPropInt( _hAttacker.GetActiveWeapon(), STRING_NETPROP_ITEMDEF )

        // hack in the IDX of the weapon we want to steal the killicon from
        SetPropInt( _hAttackerWep, STRING_NETPROP_ITEMDEF, _iIDX )

        _hVictim.TakeDamageEx( _hKillicon, _hAttacker,
                               _hAttackerWep, _vecDmgForce,
                               _vecDmgPosition, 1, DMG_CLUB | DMG_ALWAYSGIB )

        // set the IDX back
      //  SetPropInt( _hAttackerWep, STRING_NETPROP_ITEMDEF, _iPreviousIDX )
    }

    _hKillicon.Destroy()
    return
}

// --------------------------------------------------------------------------------------- //
// Infection specific player functions                                                     //
// these functions are added to the player class                                           //
// usage: _playerHandle.<functionName>( _args );                                           //
// --------------------------------------------------------------------------------------- //

function CTFPlayer_HasThisWeapon( _WeaponIndentity, _bDeleteItemOnFind = false ) {

    for ( local i = 0; i < TF_WEAPON_COUNT; i++ ) {

        local _hNextWeapon = GetPropEntityArray( this, STRING_NETPROP_MYWEAPONS, i )

        if ( !_hNextWeapon )
            continue

        if ( typeof _WeaponIndentity == "string" ) {

            if ( _hNextWeapon.GetClassname() == _WeaponIndentity ) {

                if ( _bDeleteItemOnFind ) {

                    _hNextWeapon.Destroy()
                }

                return true
            }
        }
        else if ( typeof _WeaponIndentity == "integer" ) {

            if ( GetPropInt( _hNextWeapon, STRING_NETPROP_ITEMDEF ) == _WeaponIndentity ) {

                if ( _bDeleteItemOnFind ) {

                    _hNextWeapon.Destroy()
                }

                return true
            }
        }
    }

	return false
}

function CTFPlayer_HasThisWearable( _WearableClassname ) {

    local _wearable = null
    while ( _wearable = FindByClassname( _wearable, "tf_wearable*" ) ) {

        if (  _wearable && _wearable.GetOwner() == this ) {

            if ( _wearable.GetClassname() == _WearableClassname ) {

                return true
            }
        }
    }

	return false
}

function CTFPlayer_LockInPlace( _bEnable = true ) {

    if ( _bEnable ) {

        this.AddCustomAttribute( "no_jump", 1, -1 )
        this.AddCustomAttribute( "no_duck", 1, -1 )
        this.AddCustomAttribute( "no_attack", 1, -1 )
        this.AddCustomAttribute( "move speed penalty", 0.01, -1 )
    }
    else {

        this.RemoveCustomAttribute( "no_jump" )
        this.RemoveCustomAttribute( "no_duck" )
        this.RemoveCustomAttribute( "no_attack" )
        this.RemoveCustomAttribute( "move speed penalty" )
    }
}

function CTFPlayer_GiveZombieAbility() {

    local _sc = this.GetScriptScope()

    _sc.m_fTimeNextCast  <- 0.0
    _sc.m_hZombieAbility <- CZombieAbility.m_arrClassAbilities[ this.GetPlayerClass() ]( this )

    _sc.m_iCurrentAbilityType <- _sc.m_hZombieAbility.GetAbilityType()
}

function CTFPlayer_RemovePlayerWearables() {

    for ( local child = this.FirstMoveChild(); child; child = child.NextMovePeer() )
        if ( !(child instanceof CBaseCombatWeapon) && child instanceof CEconEntity )
            EntFireByHandle( child, "Kill", null, -1, null, null )
}

function CTFPlayer_SpawnEffect() {

    EmitSoundOn( "Halloween.spell_lightning_cast",   this )
    EmitSoundOn( "Halloween.spell_lightning_impact", this )

    PZI_Util.DispatchEffect( this, FX_ZOMBIE_SPAWN )
    return
}


function CTFPlayer_GiveZombieCosmetics() {

    local wearable = PZI_Util.GiveWearableItem( this, arrZombieCosmeticIDX[ this.GetPlayerClass() ], arrZombieCosmeticModelStr[ this.GetPlayerClass() ] )
    local _sc = PZI_Util.GetEntScope( this )

    SetPropBool( this, "m_bForcedSkin", true )
    SetPropInt( this, "m_nForcedSkin", this.GetSkin() + (this.GetPlayerClass() == TF_CLASS_SPY ? 22 : 4) )
    SetPropInt( this, "m_iPlayerSkinOverride", 1 )
    PZI_Util.SetTargetname( wearable, format( "__pzi_zombie_cosmetic_%d", this.entindex() ) )
    this.GetScriptScope().m_hZombieWearable <- wearable
}

function CTFPlayer_GiveZombieEyeParticles() {

    local eye_particle = szEyeParticles[RandomInt( 0, szEyeParticles.len() - 1 )]

    if ( this.IsPlayer() && this.GetPlayerClass() != TF_CLASS_DEMOMAN )
        PZI_Util.AttachParticle( this, eye_particle, "eyeglow_L" )

    PZI_Util.AttachParticle( this, eye_particle, "eyeglow_R" )
}

// doesn't apply to ragdolls
function CTFPlayer_GiveZombieCosmetics_OLD() {

    local _iClassnum = this.GetPlayerClass()

    // this.SetCustomModelWithClassAnimations( szArrZombiePlayerModels[ _iClassnum ] )

    local _sc = PZI_Util.GetEntScope( this )

    m_hAbilityOwner.ClearZombieEntity( "m_hZombieWearable" )

    local _zombieCosmetic  =  CreateByClassname( "tf_wearable" )
    local _soulIDX         =  arrZombieCosmeticIDX[ this.GetPlayerClass() ]

    _zombieCosmetic.AddAttribute ( "player skin override", 1, -1 )
    SetPropInt                   ( this, "m_iPlayerSkinOverride", 1 )

    ::DispatchSpawn       ( _zombieCosmetic )
    _zombieCosmetic.SetAbsOrigin ( this.GetLocalOrigin() )
    _zombieCosmetic.SetAbsAngles ( this.GetLocalAngles() )

    // Zombie Cosmetics NetProps // ----------------------------------------------------------------- //
    SetPropInt    ( _zombieCosmetic, "m_iTeamNum",                                     this.GetTeam() )
    SetPropInt    ( _zombieCosmetic, STRING_NETPROP_ITEMDEF,     _soulIDX )
    SetPropBool   ( _zombieCosmetic, STRING_NETPROP_ATTACH,                               true )
    SetPropBool   ( _zombieCosmetic, STRING_NETPROP_INIT,                 true )
    SetPropEntity ( _zombieCosmetic, "m_hOwnerEntity",                                           this )
    SetPropInt    ( _zombieCosmetic, "m_Collision.m_usSolidFlags",                                  4 )
    SetPropInt    ( _zombieCosmetic, STRING_NETPROP_MODELINDEX, arrZombieCosmeticModel[ this.GetPlayerClass() ] )
    // ---------------------------------------------------------------------------------------------- //

    _zombieCosmetic.SetOwner( this )

    SetPropInt      ( _zombieCosmetic, "m_fEffects", ( EF_BONEMERGE ) )
    EntFireByHandle ( _zombieCosmetic, "SetParent",  "!activator", -1, this, this )
}


function CTFPlayer_GiveZombieFXWearable() {

    local _sc = this.GetScriptScope()

    if ( !_sc ) return

    m_hAbilityOwner.ClearZombieEntity( "m_hZombieFXWearable" )

    local _zombieFXWearable = CreateByClassname( "tf_wearable" )

    ::DispatchSpawn         ( _zombieFXWearable )
    _zombieFXWearable.SetAbsOrigin ( this.GetLocalOrigin() )
    _zombieFXWearable.SetAbsAngles ( this.GetLocalAngles() )

    // Zombie FX Wearable NetProps
    SetPropBool   ( _zombieFXWearable,  STRING_NETPROP_ATTACH, true )
    SetPropBool   ( _zombieFXWearable,  STRING_NETPROP_INIT, true )
    SetPropEntity ( _zombieFXWearable,  "m_hOwnerEntity",  this )
    SetPropInt    ( _zombieFXWearable,  "m_Collision.m_usSolidFlags", 4 )
    SetPropInt    ( _zombieFXWearable,  STRING_NETPROP_MODELINDEX, arrZombieFXWearable[ this.GetPlayerClass() ] )

    _zombieFXWearable.SetOwner( this )

    SetPropInt      ( _zombieFXWearable, "m_fEffects", ( EF_BONEMERGE | EF_BONEMERGE_FASTCULL ) )
    EntFireByHandle ( _zombieFXWearable, "SetParent", "!activator", -1, this, this )

    _sc.m_hZombieFXWearable  <-  _zombieFXWearable
    return
}

function CTFPlayer_ApplyOutOfCombat() {

    return

    if ( this.InCond( TF_COND_SHIELD_CHARGE ) ) // todo - hacky demoman fix
        return

    local _sc = this.GetScriptScope()

	// if ( !_sc ) return

    _sc.m_iFlags <- ( _sc.m_iFlags | ZBIT_OUT_OF_COMBAT )

    if ( this.GetPlayerClass() == TF_CLASS_HEAVYWEAPONS || this.GetPlayerClass() == TF_CLASS_SCOUT )
        return

    this.AddCond             ( TF_COND_SPEED_BOOST )
    this.AddCustomAttribute  ( "move speed penalty", ZOMBIE_BOOST_SPEED_DEBUFF, -1 )
}

function CTFPlayer_RemoveOutOfCombat( _bForceCooldown = false ) {

    local _sc = this.GetScriptScope()

	// if ( !_sc ) return

    if ( _bForceCooldown ) {

        _sc.m_fTimeLastHit = Time()
    }

    if ( _sc.m_iFlags & ZBIT_MUST_EXPLODE )
        return

    if ( this.GetPlayerClass() == TF_CLASS_HEAVYWEAPONS || this.GetPlayerClass() == TF_CLASS_SCOUT )
        return

    _sc.m_iFlags = _sc.m_iFlags & ~ZBIT_OUT_OF_COMBAT
    this.RemoveCond( TF_COND_SPEED_BOOST )

    this.RemoveCustomAttribute ( "move speed penalty" )
}

function CTFPlayer_RemoveAmmo() {

    for ( local i = 0; i < 32; i++ ) {

        SetPropIntArray( this, STRING_NETPROP_AMMO, 0, i )
    }
}

function CTFPlayer_GiveZombieWeapon() {

    local _sc = this.GetScriptScope()

	// if ( !_sc ) return

    this.ClearZombieEntity( "m_hZombieFXWearable" )
    this.ClearZombieEntity( "m_hZombieWearable" )

    local _playerClass  =  this.GetPlayerClass()
    local _hPlayerVM    =  GetPropEntity( this, "m_hViewModel" )
    local _zombieWep    =  CreateByClassname( ZOMBIE_WEAPON_CLASSNAME[ _playerClass ] )
    local _idx          =  ZOMBIE_WEAPON_IDX[ _playerClass ]

    SetPropInt  ( _zombieWep, STRING_NETPROP_ITEMDEF, _idx )
    SetPropBool ( _zombieWep, "m_AttributeManager.m_Item.m_bOnlyIterateItemViewAttributes", true )
    SetPropBool ( _zombieWep, STRING_NETPROP_ATTACH, true )

    // default attribs
    foreach( _attrib in ZOMBIE_WEP_ATTRIBS[ 0 ] )
        _zombieWep.AddAttribute( _attrib[ 0 ], _attrib[ 1 ], _attrib[ 2 ] )

    // class specific attribs
    foreach( _attrib in ZOMBIE_WEP_ATTRIBS[ _playerClass ] )
        _zombieWep.AddAttribute( _attrib[ 0 ], _attrib[ 1 ], _attrib[ 2 ] )


    ::DispatchSpawn( _zombieWep )

    this.Weapon_Equip( _zombieWep )

    local _zombieArms = CreateByClassname( "tf_wearable_vm" )

    _zombieArms.SetAbsOrigin  ( this.GetLocalOrigin() )
    _zombieArms.SetAbsAngles  ( this.GetLocalAngles() )
    ::DispatchSpawn( _zombieArms )

    // Zombie Arm Viewmodel Netprops // ------------------------------------------------- //
    SetPropEntity ( _zombieArms, "m_hWeaponAssociatedWith",                    _zombieWep )
    SetPropInt    ( _zombieArms, "m_iViewModelIndex",  arrZombieArmVMPath[ _playerClass ] )
    SetPropInt    ( _zombieArms, STRING_NETPROP_MODELINDEX,      arrZombieArmVMPath[ _playerClass ] )
    SetPropBool   ( _zombieArms, STRING_NETPROP_ATTACH,                       true )
    SetPropBool   ( _zombieArms, STRING_NETPROP_INIT,         true )
    SetPropEntity ( _zombieArms, "m_hOwnerEntity",                                   this )
    // ---------------------------------------------------------------------------------- //

    // Zombie Weapon Netprops // -------------------------------------------------------- //
    SetPropEntity ( _zombieWep,  "m_hExtraWearableViewModel",                 _zombieArms )
    SetPropInt    ( _zombieWep,  "m_iViewModelIndex",  arrZombieArmVMPath[ _playerClass ] )
    SetPropInt    ( _zombieWep,  STRING_NETPROP_MODELINDEX,      arrZombieArmVMPath[ _playerClass ] )
    SetPropInt    ( _zombieWep,  "m_nRenderMode",                       kRenderTransColor )
    SetPropInt    ( _zombieWep,  "m_clrRender",                                         0 )
    SetPropBool   ( _zombieWep,  STRING_NETPROP_INIT,         true )
    SetPropEntity ( _zombieWep,  "m_hOwnerEntity",                                   this )
    // ---------------------------------------------------------------------------------- //

    this.EquipWearableViewModel  ( _zombieArms )

    _sc.m_hZombieWep  <- _zombieWep
    _sc.m_hZombieArms <- _zombieArms

    _hPlayerVM.SetModelSimple           ( arrZombieViewModelPath[ _playerClass ] )
    _sc.m_hZombieWep.SetCustomViewModel ( arrZombieViewModelPath[ _playerClass ] )

    this.Weapon_Switch ( _zombieWep )
    return
}

function CTFPlayer_AddZombieAttribs() {

    local _iClassNum = this.GetPlayerClass()

    if ( ZOMBIE_PLAYER_CONDS[ 0 ].len() ) {

        foreach ( _cond in ZOMBIE_PLAYER_CONDS[ 0 ] ) // default conds
            this.AddCondEx( _cond, -1, null )
    }

    if ( ZOMBIE_PLAYER_CONDS[ _iClassNum ].len() ) {

        foreach ( _cond in ZOMBIE_PLAYER_CONDS[ _iClassNum ] )  // class specific conds
            this.AddCondEx( _cond, -1, null )
    }

    if ( ZOMBIE_PLAYER_ATTRIBS[ 0 ].len() > 1 ) {

        foreach ( _attrib in ZOMBIE_PLAYER_ATTRIBS[ 0 ]  ) // default attribs
            this.AddCustomAttribute( _attrib[ 0 ], _attrib[ 1 ], _attrib[ 2 ] )
    }

    if ( ZOMBIE_PLAYER_ATTRIBS[ _iClassNum ].len() ) {

        foreach ( _attrib in ZOMBIE_PLAYER_ATTRIBS[ _iClassNum ]  ) // class specific attribs
            this.AddCustomAttribute( _attrib[ 0 ], _attrib[ 1 ], _attrib[ 2 ] )
    }

    return
}

function CTFPlayer_ClearZombieAttribs() {

    local _iClassNum = this.GetPlayerClass()

    if ( ZOMBIE_PLAYER_CONDS[ 0 ].len() )
        foreach ( _cond in ZOMBIE_PLAYER_CONDS[ 0 ] ) // default conds
            this.RemoveCondEx( _cond, true )

    if ( ZOMBIE_PLAYER_CONDS[ _iClassNum ].len() )
        foreach ( _cond in ZOMBIE_PLAYER_CONDS[ _iClassNum ] )  // class specific conds
            this.RemoveCondEx( _cond, true )

    if ( ZOMBIE_PLAYER_ATTRIBS[ 0 ].len() > 1 )
        foreach ( _attrib in ZOMBIE_PLAYER_ATTRIBS[ 0 ]  ) // default attribs
            this.RemoveCustomAttribute( _attrib[ 0 ] )

    if ( ZOMBIE_PLAYER_ATTRIBS[ _iClassNum ].len() )
        foreach ( _attrib in ZOMBIE_PLAYER_ATTRIBS[ _iClassNum ]  ) // class specific attribs
            this.RemoveCustomAttribute( _attrib[ 0 ] )

    return
}

function CTFPlayer_AbilityStateToString() {

    local _sc = this.GetScriptScope()

	// if ( !_sc ) return

    if ( !this.IsAlive() || _sc.m_fTimeNextCast == ACT_LOCKED )
        return "off.vtf"

    local _bCanCast = ( _sc.m_fTimeNextCast <= Time() )

    switch ( _bCanCast ) {

        case true:
            return "on.vtf"
            break
        default:
            return "off.vtf"
            break
    }

    return "off.vtf"
}

function CTFPlayer_BuildZombieHUDString() {

    local _sc = this.GetScriptScope()

	// if ( !_sc ) return

    if ( !_sc.m_hZombieAbility ) {

        _sc.m_szCurrentHUDString = ""
        return
    }

    if ( _sc.m_fTimeNextCast == ACT_LOCKED ) {

        if ( _sc.m_hZombieAbility.m_iAbilityType == ZABILITY_PASSIVE ) {

            _sc.m_szCurrentHUDString = STRING_UI_PASSIVE
            return
        }
        else {

            _sc.m_szCurrentHUDString = STRING_UI_CASTING
        }

        return
    }

    local _flSecondsUntilAbility = ( _sc.m_fTimeNextCast - Time() )
    local _szMessage             = ""

    if ( _flSecondsUntilAbility < 0 ) {

        _sc.m_szCurrentHUDString = STRING_UI_READY
    }
    else {

        local _nWholeSeconds = _flSecondsUntilAbility.tointeger()
        local _nDecimalPart  = ( _flSecondsUntilAbility - floor( _flSecondsUntilAbility ) )

        // todo: need to figure out localized strings and rewrite this
        _szMessage += format( "%s %d", "Ready in", _nWholeSeconds )

        if ( _nDecimalPart <= 0.8 ) {

            _szMessage += "."
        }

        if ( _nDecimalPart <= 0.6 ) {

            _szMessage += "."
        }

        if ( _nDecimalPart <= 0.2 ) {

            _szMessage += "."
        }

        _sc.m_szCurrentHUDString = _szMessage
        return
    }
}

function CTFPlayer_ZombieInitialTooltip() {

    local _hAbilityHUDText = SpawnEntityFromTable( "game_text", {

        x          =  0.287,
        y          =  0.85,
        effect     =  2,
        color      =  "255 255 255",
        color2     =  "127 111 32",
        fadein     =  0.009,
        fadeout    =  0.9,
        holdtime   =  10,
        fxtime     =  0.008,
        channel    =  1,
        message    =  "",
        spawnflags =  0,
    })

    return _hAbilityHUDText
}

function CTFPlayer_InitializeZombieHUD() {

    local _sc = this.GetScriptScope()

    this.ClearZombieEntity( "m_hHUDText" )
    this.ClearZombieEntity( "m_hHUDTextAbilityName" )

    local userid = GetPlayerUserID( this )

    // previous checks apparently don't work, just kill by targetname
    for ( local ent = worldspawn, name ; ent = FindByClassname( ent, "game_text"); )
        if ( ( name = ent.GetName() ), startswith( name, "__pzi" ) && endswith( name, userid.tostring() ) )
            EntFireByHandle( ent, "Kill", "", -1, null, null )

    local _hAbilityHUDText = SpawnEntityFromTable( "game_text", {

        targetname = "__pzi_hud_text_abilityvalue" + userid
        x          =  ZHUD_X_POS
        y          =  0.895
        effect     =  0
        color      =  "255 255 255"
        color2     =  "0 0 0"
        fadein     =  0
        fadeout    =  0
        holdtime   =  10
        fxtime     =  0
        channel    =  2
        message    =  ""
        spawnflags =  0
    } )

    local _hAbilityNameHUDText = SpawnEntityFromTable( "game_text", {

        targetname = "__pzi_hud_text_abilityname" + userid
        x          =  ZHUD_X_POS
        y          =  0.80
        effect     =  0
        color      =  "255 255 255"
        color2     =  "0 0 0"
        fadein     =  0
        fadeout    =  0
        holdtime   =  10
        fxtime     =  0
        channel    =  4
        message    =  ""
        spawnflags =  0
    } )

    _sc.m_hHUDText             <- _hAbilityHUDText
    _sc.m_hHUDTextAbilityName  <- _hAbilityNameHUDText

    return _sc.m_hHUDText
}

function CTFPlayer_CheckIfLoser() {

    local _iRoundState = GetPropInt( GameRules, "m_iRoundState" )

    if ( _iRoundState != GR_STATE_TEAM_WIN )
        return false

    if ( GetWinningTeam() != this.GetTeam() )
        return true

    // if ( you are reading this )
        // return true

    return false
}

function CTFPlayer_CanDoAct( _iAct ) {

    local _sc    =  this.GetScriptScope()
    local _temp  =  ACT_LOCKED

    switch ( _iAct ) {

        case ZOMBIE_ABILITY_CAST:

            if ( this.CheckIfLoser() )
                return false

            _temp = _sc.m_fTimeNextCast
            break

        case ZOMBIE_TALK:
            _temp = _sc.m_fTimeNextTalk
            break
        case ZOMBIE_DO_ATTACK1:
            _temp = _sc.m_fTimeNextViewpunch
            break
        case ZOMBIE_BECOME_ZOMBIE:
            _temp = _sc.m_fTimeBecomeZombie
            break
        case ZOMBIE_BECOME_SURVIVOR:
            _temp = _sc.m_fTimeRemoveZombie
            break
        case ZOMBIE_NEXT_QUEUED_EVENT:
            _temp = _sc.m_fTimeNextQueuedEvent
            break
        case ZOMBIE_KILL_GLOW:
            _temp = _sc.m_fKillGlowTime
            break
        case ZOMBIE_REMOVE_HEALRING:
            _temp = _sc.m_fTimeRemoveHeal
            break
        case ZOMBIE_CAN_CLIENTPRINT:
            _temp = _sc.m_fTimeNextClientPrint
            break
        case SURVIVOR_CAN_CLEAR_SCRIPT_SCREEN_OVERLAY:
            _temp = _sc.m_fTimeRemoveScreenOverlay
            break
        default:
            return false
    }

    if ( _temp == ACT_LOCKED )
        return false

    if ( _temp <= Time() ) {

        return true
    }
    else {

        return false
    }
}

function CTFPlayer_ProcessEventQueue(  ) {

    local _sc = this.GetScriptScope()

	if ( !_sc ) return

    if ( !_sc.m_tblEventQueue.len() )
        return

    local _nearestEvent     =  null
    local _nearestFireTime  =  null

    foreach ( _event, _fireTime in _sc.m_tblEventQueue ) {

        if ( !_nearestEvent || ( _fireTime < _nearestFireTime ) ) {

            _nearestEvent     =  _event
            _nearestFireTime  =  _fireTime
        }
    }

    if ( _nearestEvent && ( Time() > _nearestFireTime ) ) {

        switch ( _nearestEvent ) {

            case EVENT_SNIPER_SPITBALL:
                SetPropFloat( _sc.m_hZombieWep, "m_flNextPrimaryAttack", 0.0 )
                _sc.m_hZombieAbility.CreateSpitball()
                break

            case EVENT_ENGIE_EXIT_MINIROOT:
                SetPropFloat( _sc.m_hZombieWep, "m_flNextPrimaryAttack", 0.0 )
                _sc.m_hZombieAbility.ExitRoot()
                break

            case EVENT_ENGIE_THROW_NADE:
                _sc.m_hZombieAbility.ThrowNadeProjectile()
                break

            case EVENT_DEMO_CHARGE_START:
                _sc.m_hZombieAbility.StartDemoCharge()
                break

            case EVENT_DEMO_CHARGE_EXIT:
                SetPropFloat( _sc.m_hZombieWep, "m_flNextPrimaryAttack", 0.0 )
                _sc.m_hZombieAbility.ExitDemoCharge()
                break

            case EVENT_PUT_ABILITY_ON_CD:
                SetPropFloat( _sc.m_hZombieWep, "m_flNextPrimaryAttack", 0.0 )
                _sc.m_hZombieAbility.PutAbilityOnCooldown()
                break

            case EVENT_DOWNWARDS_VIEWPUNCH:
                local _angSecondViewPunch = QAngle( 3, 0, 0 )
                this.ViewPunch( _angSecondViewPunch )
                break

            case EVENT_KILL_TEMP_ENTITY: // todo mess

                if ( "m_hTempEntity" in _sc && _sc.m_hTempEntity && _sc.m_hTempEntity.IsValid() )
                    _sc.m_hTempEntity.Destroy()

                this.SetForcedTauntCam ( 0 )
                this.RemoveCond        ( TF_COND_TAUNTING )

                _sc.m_hZombieAbility.PutAbilityOnCooldown()
                this.RemoveCustomAttribute ( "no_attack" )
                break

            case EVENT_SPY_RECLOAK:

                // start with standard cloak for spawn fx
                this.AddCondEx( TF_COND_STEALTHED, 0.3, null )

                // then swap to TF_COND_STEALTHED_USER_BUFF for the rest of the duration
                this.AddEventToQueue( EVENT_SPY_SWAP_CLOAK, 0.2 )
                break

            case EVENT_SPY_SWAP_CLOAK:
                this.AddCondEx( TF_COND_STEALTHED_USER_BUFF, -1, null )
                break

            case EVENT_DEMO_CHARGE_RESET:

                this.ClearZombieEntity( "m_hZombieWearable" )
                this.ClearZombieEntity( "m_hZombieFXWearable" )

                // this.GiveZombieFXWearable()
                this.GiveZombieCosmetics()

                this.SetForcedTauntCam ( 0 )

                this.RemoveCond ( TF_COND_CRITBOOSTED_PUMPKIN )
                this.RemoveCond ( TF_COND_TAUNTING )
                this.RemoveCond ( TF_COND_INVULNERABLE_USER_BUFF )
                this.RemoveCond ( TF_COND_RADIUSHEAL )

                _sc.m_iFlags <- ( _sc.m_iFlags & ~ZBIT_DEMOCHARGE )
                _sc.m_iFlags <- ( _sc.m_iFlags & ~ZBIT_MUST_EXPLODE )
                break

            case EVENT_RESET_ZOMBIE_WEP:

                this.DestroyAllWeapons()
                this.GiveZombieWeapon()
                this.RemoveAmmo()
                break

            default:
                _sc.m_tblEventQueue.rawdelete( _nearestEvent )
                return
        }

        _sc.m_tblEventQueue.rawdelete( _nearestEvent )
    }

    return
}

function CTFPlayer_RemoveEventFomQueue( _event ) {

    local _sc = this.GetScriptScope()

	// if ( !_sc ) return

    if ( _event == -1 ) {

        _removedCount = _sc.m_tblEventQueue.len()
        _sc.m_tblEventQueue.clear()
    }
    else {

        while ( _event in _sc.m_tblEventQueue ) {

            delete _sc.m_tblEventQueue[ _event ]
        }
    }

    return
}

function CTFPlayer_AddEventToQueue( _event, _delay ) {

    local _sc        =  this.GetScriptScope()
    local _fireTime  =  ( Time() + _delay )

    // if ( !_sc ) return

    if ( _event in _sc.m_tblEventQueue ) {

        _sc.m_tblEventQueue[ _event ] = _fireTime
    }
    else {

        _sc.m_tblEventQueue[ _event ] <- _fireTime
    }

    return
}

function CTFPlayer_ResetInfectionVars() {

    local _sc = this.GetScriptScope()

	if ( !_sc ) return

    // AddThinkToEnt( this, null )

    if ( !this.IsPlayer() )
        return __DumpScope(0, getstackinfos(2))

    if ( ( "m_iUserConfigFlags" in _sc ) ) {

        _sc.m_iUserConfigFlags <- ( _sc.m_iUserConfigFlags )
    }
    else {

        _sc.m_iUserConfigFlags <- ZBIT_HAS_HUD
    }

    // if ( !bGameStarted )
        // _sc.m_bCanAddTime <- true

    _sc.m_iFlags                <- ZBIT_SURVIVOR
    _sc.m_tblEventQueue         <- { }
    _sc.m_szCurrentHUDString    <- ""

    _sc.m_bCanPlay              <- false
    _sc.m_bDeathWasModified     <- false
    _sc.m_bLastManStanding      <- false
    _sc.m_bZombieHUDInitialized <- false
    _sc.m_bLastThree            <- false
    _sc.m_bStandingOnSpit       <- false

    _sc.m_hZombieWep            <- null
    _sc.m_hZombieArms           <- null
    _sc.m_hZombieWearable       <- null
    _sc.m_hZombieFXWearable     <- null
    _sc.m_hZombieAbility        <- null
    _sc.m_hTempEntity           <- null
    _sc.m_hHUDText              <- null
    _sc.m_hHUDTextAbilityName   <- null
    _sc.m_hLinkedSpitPool       <- null

    _sc.m_fTimeNextCast         <- 0.0
    _sc.m_fTimeNextTalk         <- 0.0
    _sc.m_fTimeNextViewpunch    <- 0.0
    _sc.m_fTimeRemoveZombie     <- 0.0
    _sc.m_fTimeBecomeZombie     <- 0.0
    _sc.m_fTimeNextQueuedEvent  <- 0.0
    _sc.m_fKillGlowTime         <- 0.0
    _sc.m_fTimeRemoveHeal       <- 0.0
    _sc.m_fTimeNextHealTick     <- 0.0
    _sc.m_fTimeNextClientPrint  <- 0.0
    _sc.m_fTimeLastHit          <- 0.0
    _sc.m_fTimeRemoveScreenOverlay <- 0.0

    _sc.m_iCurrentAbilityType   <- 0
    _sc.m_iAbilityState         <- 0

    PZI_Util.AddThink( this, PZI_PlayerThink )

    return true
}

function CTFPlayer_ModifyJumperWeapons() {

    if ( this.GetPlayerClass() == TF_CLASS_SOLDIER ) {

        // rocket jumper
        if ( this.HasThisWeapon( 237 ) ) {

            local _hWeapon = GetPropEntityArray( this, STRING_NETPROP_MYWEAPONS, 1 )

            _hWeapon.AddAttribute ( "maxammo primary reduced", 0.0, -1 )
            SetPropIntArray       ( this, STRING_NETPROP_AMMO, 0, 1 )

            _hWeapon.ReapplyProvision()
            return
        }
    }

    if ( this.GetPlayerClass() == TF_CLASS_DEMOMAN ) {

        // sticky jumper
        if ( this.HasThisWeapon( 265 ) ) {

            local _hWeapon = GetPropEntityArray( this, STRING_NETPROP_MYWEAPONS, 2 )

            _hWeapon.AddAttribute ( "hidden secondary max ammo penalty", 0.02, -1 )
            SetPropIntArray       ( this, STRING_NETPROP_AMMO, 0, 2 )

            _hWeapon.ReapplyProvision()
            return
        }
    }
}

function CTFPlayer_MakeHuman() {

    local _hPlayerVM = GetPropEntity( this, "m_hViewModel" )

    SetPropBool( this, "m_bForcedSkin", false )

    if ( this.GetPlayerClass() == TF_CLASS_ENGINEER ) {

        // make sure we give the correct view model to the gun slinger engineers
        if ( this.HasThisWeapon( "tf_weapon_robot_arm" ) ) {

            _hPlayerVM.SetModelSimple( MDL_GUNSLINGER_PATH )
            return
        }
    }

    _hPlayerVM.SetModelSimple( arrTFClassDefaultArmPath[ this.GetPlayerClass() ] )
    return
}

function CTFPlayer_HowLongUntilAct( _iAct ) {

    local _sc = this.GetScriptScope()

	// if ( !_sc ) return

    switch ( _iAct ) {

        case ZOMBIE_ABILITY_CAST:
            return ( _sc.m_fTimeNextCast < 0 ? 0 : _sc.m_fTimeNextCast - Time() )

        case ZOMBIE_TALK:
            return ( _sc.m_fTimeNextTalk < 0 ? 0 : _sc.m_fTimeNextTalk - Time() )

        case ZOMBIE_DO_ATTACK1:
            return ( _sc.m_fTimeNextViewpunch < 0 ? 0 : _sc.m_fTimeNextViewpunch - Time() )

        case ZOMBIE_BECOME_ZOMBIE:
            return ( _sc.m_fTimeBecomeZombie < 0 ? 0 : _sc.m_fTimeBecomeZombie - Time() )

        case ZOMBIE_BECOME_SURVIVOR:
            return ( _sc.m_fTimeRemoveZombie < 0 ? 0 : _sc.m_fTimeRemoveZombie - Time() )

        case ZOMBIE_KILL_GLOW:
            return ( _sc.m_fKillGlowTime < 0 ? 0 : _sc.m_fKillGlowTime - Time() )

        case ZOMBIE_REMOVE_HEALRING:
            return ( _sc.m_fTimeRemoveHeal < 0 ? 0 : _sc.m_fTimeRemoveHeal - Time() )

        case ZOMBIE_CAN_CLIENTPRINT:
            return ( _sc.m_fTimeNextClientPrint < 0 ? 0 : _sc.m_fTimeNextClientPrint - Time() )

        case SURVIVOR_CAN_CLEAR_SCRIPT_SCREEN_OVERLAY:
            return ( _sc.m_fTimeRemoveScreenOverlay < 0 ? 0 : _sc.m_fTimeRemoveScreenOverlay - Time() )

        default:
            return false
    }
}

function CTFPlayer_PlayZombieVO() {

    return
}

function CTFPlayer_ClearProblematicConds() {

    foreach ( _iCond in PROBLEMATIC_PLAYER_CONDS ) {

        this.RemoveCond( _iCond )
    }

    return
}

function CTFPlayer_SetNextActTime( _iAct, _fTime ) {

    local _sc = this.GetScriptScope()

	if ( !_sc ) return

    local _nextTime = ( _fTime == ACT_LOCKED ? ACT_LOCKED : ( Time() + _fTime ).tofloat() )

    switch ( _iAct ) {

        case ZOMBIE_ABILITY_CAST:
            _sc.m_fTimeNextCast        <- ( _nextTime )
            break
        case ZOMBIE_TALK:
            _sc.m_fTimeNextTalk        <- ( _nextTime )
            break
        case ZOMBIE_DO_ATTACK1:
            SetPropFloat( _sc.m_hZombieWep, "m_flNextPrimaryAttack", _nextTime )
            _sc.m_fTimeNextViewpunch   <- ( _nextTime )
            break
        case ZOMBIE_BECOME_ZOMBIE:
            _sc.m_fTimeBecomeZombie    <- ( _nextTime )
            break
        case ZOMBIE_BECOME_SURVIVOR:
            _sc.m_fTimeRemoveZombie    <- ( _nextTime )
            break
        case ZOMBIE_NEXT_QUEUED_EVENT:
            _sc.m_fTimeNextQueuedEvent <- ( _nextTime )
            break
        case ZOMBIE_KILL_GLOW:
            _sc.m_fKillGlowTime        <- ( _nextTime )
            break
        case ZOMBIE_REMOVE_HEALRING:
            _sc.m_fTimeRemoveHeal      <- ( _nextTime )
            break
        case ZOMBIE_CAN_CLIENTPRINT:
            _sc.m_fTimeNextClientPrint <- ( _nextTime )
            break
        case SURVIVOR_CAN_CLEAR_SCRIPT_SCREEN_OVERLAY:
            _sc.m_fTimeRemoveScreenOverlay <- ( _nextTime )
            break
        default:
            return false
    }

    return
}

function CTFPlayer_DestroyAllWeapons() {

    for ( local i = 0, _hNextWeapon; i < TF_WEAPON_COUNT; i++ )
        if ( _hNextWeapon = GetPropEntityArray( this, STRING_NETPROP_MYWEAPONS, i ) )
            EntFireByHandle( _hNextWeapon, "Kill", null, -1, null, null )

    return
}

function CTFPlayer_ClearZombieEntity( ent ) {

    local _sc = this.GetScriptScope()

    if ( ent in _sc && _sc[ent] && _sc[ent].IsValid() )
        _sc[ent].Destroy()
}

function CTFPlayer_ClearZombieEntities() {

    local _sc = this.GetScriptScope()

    local _ents = [ "m_hHUDText", "m_hHUDTextAbilityName", "m_hZombieWep", "m_hZombieFXWearable", "m_hZombieWearable" ]

    local _ent
    foreach( m in _ents )
        if ( m in _sc && (_ent = _sc[m]) && _ent.IsValid() )
            _ent.Destroy()

    return
}

function CTFPlayer_AlreadyInSpit() {

    local _sc = this.GetScriptScope()

	// if ( !_sc ) return

    return _sc.m_bStandingOnSpit
}

function CTFPlayer_GetLinkedSpitPoolEnt() {

   // printl( "Getting linked spit pool entity from player..." )
    local _sc = this.GetScriptScope()

	// if ( !_sc ) return

    if ( !_sc.m_bStandingOnSpit )
        return null

    if ( _sc.m_hLinkedSpitPool && _sc.m_hLinkedSpitPool.IsValid() )
        return _sc.m_hLinkedSpitPool

    return null
}

function CTFPlayer_SetLinkedSpitPoolEnt( _hSpitPool ) {

    local _sc = this.GetScriptScope()

	// if ( !_sc ) return

    if ( !_hSpitPool || !_hSpitPool.IsValid() )
        return

   // printl( "Setting linked spit pool entity for player..." )

    _sc.m_bStandingOnSpit = true
    _sc.m_hLinkedSpitPool = _hSpitPool
    return
}

function CTFPlayer_ClearSpitStatus() {

    local _sc = this.GetScriptScope()

	// if ( !_sc ) return

   // printl( "Clearing spit status for player..." )

    _sc.m_bStandingOnSpit = false
    _sc.m_hLinkedSpitPool = null
    return
}

function CTFPlayer_GetWeaponHandle( _szWeaponClassname ) {

    for ( local i = 0; i < TF_WEAPON_COUNT; i++ ) {

        local _hNextWeapon = GetPropEntityArray( this, STRING_NETPROP_MYWEAPONS, i )

        if ( !_hNextWeapon )
            continue

        if ( _hNextWeapon.GetClassname() == _szWeaponClassname )
            return _hNextWeapon
    }

    return null
}

// --------------------------------------------------------------------------------------- //
// Since CTFBot inherits from CTFPlayer_ before VScripts run, we need to manually put these //
// functions in to the CTFBot class to make them functional.                               //
// --------------------------------------------------------------------------------------- //

foreach ( key, value in this ) {

    if ( typeof( value ) == "function" && startswith( key, "CTFPlayer_" ) ) {

        local func_name = key.slice( 10 )
        CTFPlayer[ func_name ] <- value
        CTFBot[ func_name ] <- value
        delete this[ key ]
    }
}

function KnockbackPlayer( _hInflictor, _hVictim, _flForceMultiplier = 500.0, _flUpwardForce =  0.25, _vecDirOverride = Vector( 0, 0, 0 ), _bRemoveOnGround = false ) {

    if ( !_hInflictor || !_hVictim || !_hInflictor.IsValid() || !_hVictim.IsValid() )
         return

    if ( _bRemoveOnGround ) {

        _hVictim.RemoveFlag ( FL_ONGROUND )
        SetPropEntity       ( _hVictim, "m_hGroundEntity", null )
        _hVictim.AddCond    ( TF_COND_KNOCKED_INTO_AIR )
    }

    local _vecInflictorPos  = _hInflictor.GetOrigin()
    local _vecVictimPos     = _hVictim.GetOrigin()
    local _vecDirection     = _vecVictimPos - _vecInflictorPos

    if ( !_vecDirection.Length() && _vecDirOverride.Length() )
        _vecDirection = _vecDirOverride

    local _vecLength = sqrt( ( _vecDirection.x * _vecDirection.x ) +
                            ( _vecDirection.y * _vecDirection.y ) +
                            ( _vecDirection.z * _vecDirection.z ) )

    if ( _vecLength ) {

        _vecDirection.x /= _vecLength
        _vecDirection.y /= _vecLength
        _vecDirection.z /= _vecLength
    }

    _vecDirection.z += _flUpwardForce

    local _vecImpulse = _vecDirection * _flForceMultiplier

    _hVictim.ApplyAbsVelocityImpulse( _vecImpulse )

    local _vecAngularImpulse = Vector( RandomFloat( -50.0, 50.0 ), RandomFloat( -50.0, 50.0 ), RandomFloat( -50.0, 50.0 ) )
    _hVictim.ApplyLocalAngularVelocityImpulse( _vecAngularImpulse * 5 )

    return
}

function KilliconInflictor( _szKillIconName ) {

    local _hKillIcon = SpawnEntityFromTable( "point_template", {
        classname = _szKillIconName
    } )

    return _hKillIcon
}