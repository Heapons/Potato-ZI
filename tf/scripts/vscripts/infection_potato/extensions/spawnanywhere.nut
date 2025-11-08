PZI_CREATE_SCOPE( "__pzi_spawnanywhere", "PZI_SpawnAnywhere", null, "SpawnAnywhereThink" )

const SNIPER_SKELETON = "models/bots/skeleton_sniper/skeleton_sniper.mdl"

const NEST_MODEL            = "models/player/heavy.mdl"
const NEST_PARTICLE         = "utaunt_graveparty_parent"
const NEST_EXPLODE_SOUND    = "misc/null.wav"
const NEST_EXPLODE_PARTICLE = " "
const NEST_EXPLODE_DAMAGE   = 120
const NEST_EXPLODE_RADIUS   = 200
const NEST_EXPLODE_HEALTH   = 650

const MAX_SPAWN_DISTANCE   = 2048
const MAX_NAV_VIEW_DISTANCE = 2048

const SUMMON_ANIM_MULT = 0.7
const SUMMON_HEAL_DELAY = 1.5
const SUMMON_MAX_OVERHEAL_MULT = 1
const SUMMON_RADIUS = 512

const PLAYER_HULL_HEIGHT = 82

local USE_NAV_FOR_SPAWN = PZI_Nav.AllNavAreas.len()

CONST.HIDEHUD_GHOST <- ( HIDEHUD_CROSSHAIR|HIDEHUD_HEALTH|HIDEHUD_WEAPONSELECTION|HIDEHUD_METAL|HIDEHUD_BUILDING_STATUS|HIDEHUD_CLOAK_AND_FEIGN|HIDEHUD_PIPES_AND_CHARGE )
CONST.TRACEMASK <- ( CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_PLAYERCLIP|CONTENTS_WINDOW|CONTENTS_MONSTER|CONTENTS_GRATE )

PrecacheModel( NEST_MODEL )
PrecacheModel( SNIPER_SKELETON )

PZI_SpawnAnywhere.ActiveNests <- {}

function PZI_SpawnAnywhere::SetGhostMode( player ) {

    local scope = PZI_Util.GetEntScope( player )

    SetPropInt( player, "m_nRenderMode", kRenderTransColor )
    SetPropInt( player, "m_clrRender", 0 )
    player.DisableDraw() // makes bots stop targeting us

    scope.m_iFlags = scope.m_iFlags | ZBIT_PYRO_DONT_EXPLODE

    scope.playermodel <- player.GetModelName()

    // player.SetPlayerClass( TF_CLASS_SCOUT )
    // SetPropInt( player, "m_Shared.m_iDesiredPlayerClass", TF_CLASS_SCOUT )

    // player.SetScriptOverlayMaterial( "colorcorrection/desaturated.vmt" )

    player.AddHudHideFlags( CONST.HIDEHUD_GHOST )

    for ( local child = player.FirstMoveChild(); child; child = child.NextMovePeer() ) {

        if ( child instanceof CEconEntity ) {
            
            // botkillers, etc
            local extra_wearable = GetPropEntity( child, "m_hExtraWearable" )
            local extra_wearable_vm = GetPropEntity( child, "m_hExtraWearableViewModel" )

            if ( extra_wearable )
                EntFireByHandle( extra_wearable, "Kill", null, -1, null, null )
            
            if ( extra_wearable_vm )
                EntFireByHandle( extra_wearable_vm, "Kill", null, -1, null, null )

            EntFireByHandle( child, "Kill", "", -1, null, null )
            continue
        }

        child.DisableDraw()
    }

    PZI_Util.ScriptEntFireSafe( player, "self.AddCustomAttribute( `dmg taken increased`, 0, -1 )", -1 )
    PZI_Util.ScriptEntFireSafe( player, "self.AddCustomAttribute( `move speed bonus`, 5, -1 )", -1 )
    PZI_Util.ScriptEntFireSafe( player, "self.AddCustomAttribute( `major increased jump height`, 3, -1 )", -1 )
    PZI_Util.ScriptEntFireSafe( player, "self.AddCustomAttribute( `voice pitch scale`, 0, -1 )", -1 )

    // TODO: this sucks
    // Other players won't collide with us, but we still get stuck on them trying to pass through
    player.SetCollisionGroup( COLLISION_GROUP_DEBRIS )
    player.SetSolidFlags( FSOLID_NOT_SOLID )
    player.SetSolid( SOLID_NONE )
    player.AddFlag( FL_DONTTOUCH|FL_NOTARGET )
}

function PZI_SpawnAnywhere::BeginSummonSequence( player, origin ) {

    local scope = PZI_Util.GetEntScope( player )

    printl( player + " : " + NetName( player ) )

    PZI_Util.RemoveThink( player, "GhostThink" )

    // should already be invis but whatever
    SetPropInt( player, "m_nRenderMode", kRenderTransColor )
    SetPropInt( player, "m_clrRender", 0 )

    // force player to duck
    // mitigates some stuck spots
    SetPropInt( player, "m_afButtonForced", IN_DUCK )
    SetPropBool( player, "m_Local.m_bDucked", true )
    player.AddFlag( FL_DUCKING|FL_ATCONTROLS )

    // teleport player to our summon location
    player.SetAbsOrigin( origin + Vector( 0, 0, 20 ) )
    player.SetAbsVelocity( Vector() )

    player.AcceptInput( "SetForcedTauntCam", "1", null, null )

    EntFire( "__pzi_spawn_hint_" + PZI_Util.PlayerTables.All[ player ], "Kill" )

    scope.m_iFlags = scope.m_iFlags|ZBIT_PENDING_ZOMBIE

    if ( "m_hZombieAbility" in scope && scope.m_hZombieAbility instanceof CZombieAbility ) 
        scope.m_hZombieAbility.PutAbilityOnCooldown( scope.m_hZombieAbility.m_fAbilityCooldown + 2.0 )

    local playercls = player.GetPlayerClass()

    /**************************************************************************
     * SKELETON                                                               *
     * ANIMATION BASE FOR PLAYING SKELETON SUMMON ANIMATIONS ON PLAYER MODELS *
     **************************************************************************/
    local dummy_skeleton = CreateByClassname( "funCBaseFlex" )

    dummy_skeleton.SetModel( SNIPER_SKELETON )
    dummy_skeleton.SetAbsOrigin( origin )
    dummy_skeleton.SetAbsAngles( QAngle( 0, player.EyeAngles().y, 0 ) )

    ::DispatchSpawn( dummy_skeleton )
    local dummy_scope = PZI_Util.GetEntScope( dummy_skeleton )

    SetPropInt( dummy_skeleton, "m_nRenderMode", kRenderTransColor )
    SetPropInt( dummy_skeleton, "m_clrRender", 0 )

    // dummy_skeleton.ResetSequence( dummy_skeleton.LookupSequence( format( "spawn0%d", RandomInt( 2, 7 ) ) ) ) //spawn01 is cursed
    // dummy_skeleton.ResetSequence( dummy_skeleton.LookupSequence( "spawn04" ) )

    local spawn_seq = RandomInt( 3, 4 )
    local spawn_seq_name = format( "spawn0%d", spawn_seq )

    dummy_skeleton.ResetSequence( dummy_skeleton.LookupSequence( spawn_seq_name ) )
    dummy_skeleton.SetPlaybackRate( SUMMON_ANIM_MULT )

    /***********************************************
     * DUMMY PLAYER                                *
     * PLAYER MODEL TO BONEMERGE ONTO THE SKELETON *
     ***********************************************/
    local dummy_player = CreateByClassname( "funCBaseFlex" )

    dummy_player.SetModelSimple( format( "models/player/%s.mdl", PZI_Util.Classes[playercls] ) )
    dummy_player.SetAbsOrigin( origin )
    dummy_player.SetSkin( player.GetSkin() + (player.GetPlayerClass() == TF_CLASS_SPY ? 22 : 4) )
    dummy_player.AcceptInput( "SetParent", "!activator", dummy_skeleton, dummy_skeleton )
    SetPropInt( dummy_player, "m_fEffects", EF_BONEMERGE|EF_BONEMERGE_FASTCULL )
    ::DispatchSpawn( dummy_player )
    dummy_scope.dummy_player <- dummy_player

    /***********************************************
     * FAKE WEARABLES                              *
     * Attach zombie cosmetics to our dummy player *
     ***********************************************/
    local fakewearable = CreateByClassname( "prop_dynamic_ornament" )
    fakewearable.SetModelSimple( arrZombieCosmeticModelStr[playercls] )
    fakewearable.SetSkin( 1 )
    ::DispatchSpawn( fakewearable )
    fakewearable.AcceptInput( "SetAttached", "!activator", dummy_player, dummy_player )
    dummy_scope.fakewearable <- fakewearable

    /*********************
     * PLAYER ATTRIBUTES *
     *********************/
    player.RemoveCustomAttribute( "dmg taken increased" )
    player.SetHealth( 1 )
    player.RemoveHudHideFlags( CONST.HIDEHUD_GHOST )
    player.RemoveFlag( FL_NOTARGET|FL_DONTTOUCH )
    player.SetSolid( SOLID_BBOX )
    player.SetSolidFlags( FSOLID_NOT_STANDABLE )
    player.SetCollisionGroup( COLLISION_GROUP_PLAYER )

    PZI_Util.ScriptEntFireSafe( player, "self.AddCond( TF_COND_HALLOWEEN_QUICK_HEAL )", SUMMON_HEAL_DELAY )

    /*******************************************************
     * PRE-SPAWN                                           *
     * remove the quick heal cond when we're at max health *
     *******************************************************/
    function SummonPreSpawn() {

        if ( player.GetHealth() >= player.GetMaxHealth() * SUMMON_MAX_OVERHEAL_MULT ) {

            player.RemoveCond( TF_COND_HALLOWEEN_QUICK_HEAL )
            delete ThinkTable.SummonPreSpawn
        }
    }

    PZI_Util.AddThink( player, SummonPreSpawn )

    //max health attrib is always last
    local attrib = ZOMBIE_PLAYER_ATTRIBS[playercls]
    local lastattrib = attrib[attrib.len() - 1]

    player.AddCustomAttribute( lastattrib[0], lastattrib[1], lastattrib[2] )

    /************************
     * BEGIN SPAWN SEQUENCE *
     ************************/
    function SpawnPlayer() {
        
        // kill dummy if we're not mid-round, player is invalid or dead
        if ( !bGameStarted || !player || !player.IsValid() || !player.IsAlive() ) {

            if ( fakewearable && fakewearable.IsValid() )
                fakewearable.Kill()

            self.Kill()
            return
        }

        // update dummy position to match player
        self.SetAbsOrigin( player.GetOrigin() )
        self.SetAbsAngles( QAngle( 0, player.EyeAngles().y, 0 ) )

        // animation finished, "spawn" player
        if ( GetPropFloat( self, "m_flCycle" ) >= 0.99 ) {

            SendGlobalGameEvent( "hide_annotation", { id = PZI_Util.PlayerTables.All[ player ] } )

            SetPropInt( player, "m_nRenderMode", kRenderNormal )
            SetPropInt( player, "m_clrRender", 0xFFFFFFFF )
            player.EnableDraw()
            player.AcceptInput( "SetForcedTauntCam", "0", null, null )

            player.RemoveCustomAttribute( "no_jump" )
            player.RemoveCustomAttribute( "move speed bonus" )
            player.RemoveCustomAttribute( "major increased jump height" )
            player.RemoveCustomAttribute( "voice pitch scale" )

            for ( local child = player.FirstMoveChild(); child; child = child.NextMovePeer() )
                child.EnableDraw()

            if ( player.GetPlayerClass() == TF_CLASS_PYRO )
                scope.m_iFlags = scope.m_iFlags & ~ZBIT_PYRO_DONT_EXPLODE

            SetPropInt( player, "m_afButtonDisabled", 0 )
            SetPropInt( player, "m_afButtonForced", 0 )
            player.RemoveFlag( FL_ATCONTROLS|FL_DUCKING )
            SetPropBool( player, "m_Local.m_bDucked", false )

            player.GiveZombieCosmetics()
            player.GiveZombieEyeParticles()

            EntFireByHandle( self, "Kill", "", -1, null, null )
            EntFireByHandle( fakewearable, "Kill", "", -1, null, null )
            return 10
        }

        self.StudioFrameAdvance()
        return -1
    }

    dummy_scope.SpawnPlayer <- SpawnPlayer
    AddThinkToEnt( dummy_skeleton, "SpawnPlayer" )
}

function PZI_SpawnAnywhere::CreateNest( player, origin = null ) {

    local nest = CreateByClassname( "tf_generic_bomb" )

    nest.KeyValueFromInt( "health", NEST_EXPLODE_HEALTH )
    nest.KeyValueFromFloat( "damage", NEST_EXPLODE_DAMAGE )
    nest.KeyValueFromFloat( "radius", NEST_EXPLODE_RADIUS )
    nest.KeyValueFromString( "targetname", "__pzi_spawn_nest_" + PZI_Util.PlayerTables.All[ player ] )
    nest.KeyValueFromString( "explode_particle", NEST_EXPLODE_PARTICLE )
    nest.KeyValueFromString( "sound", NEST_EXPLODE_SOUND )
    SetPropBool( nest, STRING_NETPROP_PURGESTRINGS, true )
    nest.SetModel( NEST_MODEL )

    nest.ValidateScriptScope()

    nest.SetAbsOrigin( origin || player.GetOrigin() )

    PZI_SpawnAnywhere.ActiveNests[nest.GetName()] <- {

        health          = NEST_EXPLODE_HEALTH
        last_takedamage = 0.0
        nearby_players  = 0
        closest_player  = null
        nest_origin     = nest.GetOrigin()
        nest_generator  = null
    }

    NestScope <- nest.GetScriptScope()

    foreach ( k, v in PZI_SpawnAnywhere.ActiveNests )
        NestScope[k] <- v

    function NestScope::NestGenerator() {

        foreach ( player in PZI_Util.PlayerTables.Survivors.keys() ) {

            local player_origin = player.GetOrigin()

            if ( ( player_origin - nest_origin ).Length() <= SUMMON_RADIUS )
                nearby_players++

            if ( !closest_player || ( player_origin - nest_origin ).Length() < ( closest_player.GetOrigin() - nest_origin ).Length() )
                closest_player = player

            yield player
        }

        // update the nest in the active nests table
        PZI_SpawnAnywhere.ActiveNests[self.GetName()] = NestScope
    }

    function NestScope::NestThink() {

        if ( !PZI_Util.PlayerTables.Survivors.len() )
            return 1

        if ( health != GetPropInt( nest, "m_iHealth" ) ) {

            last_takedamage = Time()
            health = GetPropInt( nest, "m_iHealth" )
        }

        // look for closest player and num players nearby
        if ( !nest_generator || nest_generator.getstatus() == "dead" )
            nest_generator = NestGenerator()

        resume nest_generator

        return -1

    }

    AddThinkToEnt( nest, "NestThink" )
}

PZI_EVENT( "player_hurt", "SpawnAnywhere_RemoveQuickHeal", function( params ) {

    local player = GetPlayerFromUserID( params.userid )

    if ( player.InCond( TF_COND_HALLOWEEN_QUICK_HEAL ) && player.GetTeam() == TEAM_ZOMBIE )
        player.RemoveCond( TF_COND_HALLOWEEN_QUICK_HEAL )

} )

PZI_EVENT( "player_activate", "SpawnAnywhere_PlayerActivate", function( params ) { GetPlayerFromUserID( params.userid ).ValidateScriptScope() } )

PZI_EVENT( "player_spawn", "SpawnAnywhere_PlayerSpawn", function( params ) {

    local player = GetPlayerFromUserID( params.userid )

    // make everyone non-solid
    // TODO: this is a hack because the ghost mode solidity changes shown above are useless
    // the only way to make an individual non-solid player is to use TF_COND_GHOST_MODE
    // which has a ton of side-effects I'm not interested in dealing with right now
    // player.SetCollisionGroup( TFCOLLISION_GROUP_COMBATOBJECT )

    local scope = PZI_Util.GetEntScope( player )

    if ( GetPropInt( player, "m_nRenderMode" ) == kRenderTransColor ) {

        SetPropInt( player, "m_nRenderMode", kRenderNormal )
        SetPropInt( player, "m_clrRender", 0xFFFFFFFF )
        player.EnableDraw()
    }

    // teleport to a random nav square on spawn
    if ( USE_NAV_FOR_SPAWN ) {

        local _random_pos = @() PZI_Nav.GetRandomSafeArea().GetCenter() + Vector( 0, 0, 20 )
        local random_pos = _random_pos()

        local mins = player.GetBoundingMaxs()
        local maxs = player.GetBoundingMaxs()

        // make sure we can fit here, find another if we can't
        while ( !PZI_Util.IsSpaceToSpawnHere( random_pos, mins, maxs ) )
            random_pos = _random_pos()

        player.SetAbsOrigin( random_pos )
    }
    // BLU LOGIC BEYOND THIS POINT
    if ( player.GetTeam() != TEAM_ZOMBIE ) {
        
        if ( "ThinkTable" in scope && "GhostThink" in scope.ThinkTable )
            PZI_Util.RemoveThink( player, "GhostThink" )

        player.ResetInfectionVars()
        return
    }

    else if ( !bGameStarted )
        return

    scope.spawn_nests <- []
    scope.tracepos    <- Vector()
    scope.spawnpos    <- null

    // PZI_Util.ScriptEntFireSafe( player, "PZI_SpawnAnywhere.SetGhostMode( self )", -1 )
    PZI_SpawnAnywhere.SetGhostMode( player )

    // make bots spawn in like mvm spy bots
    if ( player.IsBotOfType( TF_BOT_TYPE ) ) {

        PZI_Util.ScriptEntFireSafe( player, @"

            local players = GetRandomPlayers( 1, TEAM_HUMAN )
            if ( !( 0 in players ) )
                return

            PZI_Util.TeleportNearVictim( self, players[0], 0.25, true )
            PZI_Util.ScriptEntFireSafe( self, `PZI_SpawnAnywhere.BeginSummonSequence( self, self.GetOrigin() )`, 0.5 )

        ", RandomFloat( 0.1, 1.2 ) ) // random delay to avoid predictable spawn waves

        return
    }

    local players = GetRandomPlayers( 1, TEAM_HUMAN )

    if ( !( 0 in players ) )
        return

    PZI_Util.TeleportNearVictim( player, players[0], 0.25, true )

    local spawn_hint = CreateByClassname( "move_rope" )
    spawn_hint.KeyValueFromString( "targetname",  "__pzi_spawn_hint_" + PZI_Util.PlayerTables.All[ player ] )
    DispatchSpawn( spawn_hint )

    SetPropBool( spawn_hint, STRING_NETPROP_PURGESTRINGS, true )

    PZI_Util.ScriptEntFireSafe( spawn_hint, @"

        if ( !activator || !activator.IsValid() || !activator.IsAlive() || activator.GetTeam() == TEAM_HUMAN )
            return

        local player_idx = PZI_Util.PlayerTables.All[ activator ]

        local origin = self.GetOrigin()

        SendGlobalGameEvent( `show_annotation`, {

            text = `Spawn Here!`
            lifetime = -1
            show_distance = true
            visibilityBitfield = 1 << activator.entindex()
            follow_entindex = self.entindex()
            worldposX = origin.x
            worldposY = origin.y
            worldposZ = origin.z
            id = player_idx
        })

    ", 0.5, player )

    function GhostThink() {

        // find the nav we're looking at
        local nav_trace = {

            start  = player.EyePosition()
            end    = player.EyeAngles().Forward() * INT_MAX
            mask   = CONST.TRACEMASK
            ignore = player
        }
        
        player.AcceptInput( "DispatchEffect", "ParticleEffectStop", null, null )

        TraceLineEx( nav_trace )

        // no world geometry found
        if ( !nav_trace.hit )
            return ClientPrint( player, HUD_PRINTCENTER, "No valid spawn point found!" )

        tracepos = nav_trace.pos

        // trace too far away
        if ( ( player.GetOrigin() - tracepos ).Length2D() > MAX_SPAWN_DISTANCE )
            return ClientPrint( player, HUD_PRINTCENTER, "Too far away from spawn point!" )

        // not a valid area
        if ( USE_NAV_FOR_SPAWN ) {

            local nav_area = GetNearestNavArea( tracepos, SUMMON_RADIUS * 2, true, true )

            if ( !nav_area || !nav_area.IsFlat() )
                return ClientPrint( player, HUD_PRINTCENTER, "Not a valid spawn area!" )

            spawnpos = nav_area.GetCenter()
        }
        else
            // no nav, fallback to just the normal trace pos
            // All maps should use the nav and not rely on this
            // but this atleast stops the gamemode from softlocking
            spawnpos = tracepos

        if ( !spawnpos )
            return ClientPrint( player, HUD_PRINTCENTER, "No valid spawn point found!" )

        // avoid lambdas for perf counter.
        local function in_triggerhurt( pos ) { return PZI_Util.IsPointInTrigger( pos, "trigger_hurt" ) }

        if ( in_triggerhurt( spawnpos ) || in_triggerhurt( spawnpos + Vector( 0, 0, 64 ) ) )
            return ClientPrint( player, HUD_PRINTCENTER, "Too close to a trigger_hurt!" )

        // check if we can fit here
        else if ( !PZI_Util.IsSpaceToSpawnHere( spawnpos + Vector( 0, 0, 20 ), player.GetBoundingMins(), player.GetBoundingMaxs() ) )
            return DebugDrawBox( spawnpos + Vector( 0, 0, 20 ), player.GetBoundingMins(), player.GetBoundingMaxs(), 255, 0, 0, 255, 0.1 )

        if ( spawn_hint && spawn_hint.IsValid() )
            spawn_hint.KeyValueFromVector( "origin", spawnpos + Vector( 0, 0, 20 ) )

        // DebugDrawBox( nav_area.GetCenter(), hull_trace.hullmin, hull_trace.hullmax, spawnpos ? 0 : 255, spawnpos ? 255 : 0, 0, 255, 0.1 )

        local buttons = GetPropInt( player, "m_nButtons" )

        if ( buttons ) {

            // NORMAL GROUND SPAWN
            // snap the spawn point to the nav area center
            if ( buttons & IN_ATTACK && !( buttons & IN_ATTACK2 ) ) {
                
                foreach ( cls in ["player", "obj_*"] ) {

                    local ent = FindByClassnameNearest( cls, tracepos, SUMMON_RADIUS )

                    if ( ent && ent.GetTeam() == TEAM_HUMAN ) {

                        ClientPrint( player, HUD_PRINTCENTER, "Too close to a " + ( cls == "player" ? "survivor!" : "building!" ) )

                        if ( !("mdl" in scope) || !scope.mdl || !scope.mdl.IsValid() ) {

                            local mdl = PZI_Util.ShowModelToPlayer( player, [ent.GetModelName(), ent.GetSkin()], ent.GetOrigin(), ent.GetAbsAngles(), 1.0 )
                            mdl.SetTeam( TEAM_SPECTATOR ) // white outline
                            mdl.SetSequence( ent.GetSequence() )
                            SetPropInt( mdl, "m_nRenderFX", kRenderTransColor )
                            SetPropInt( mdl, "m_clrRender", 0 )
                            SetPropBool( mdl, "m_bGlowEnabled", true )
                            scope.mdl <- mdl
                        }
                        return
                    }
                }

                PZI_SpawnAnywhere.BeginSummonSequence( player, spawnpos )
            }

            // NEST SPAWN
            // loop through active nests and find the one with the most players nearby
            else if ( buttons & IN_ATTACK2 && PZI_SpawnAnywhere.ActiveNests.len() ) {

                spawn_nests = PZI_SpawnAnywhere.ActiveNests.keys().filter( @( nest ) PZI_SpawnAnywhere.ActiveNests[nest].last_takedamage < Time() - 2.0 )

                if ( !spawn_nests.len() ) return

                PZI_SpawnAnywhere.BeginSummonSequence( player, spawn_nests.sort( @( a, b ) a.nearby_players > b.nearby_players )[0].nest_origin )

                return
            }
        }
    }
    PZI_Util.AddThink( player, GhostThink )
} )

PZI_EVENT( "player_death", "SpawnAnywhere_PlayerDeath", function( params ) {

    local player = GetPlayerFromUserID( params.userid )

    if ( player.GetTeam() == TEAM_ZOMBIE && player.IsEFlagSet( FL_DONTTOUCH ) ) {

        player.RemoveFlag( FL_ATCONTROLS|FL_DUCKING|FL_DONTTOUCH|FL_NOTARGET )
        // player.ForceRespawn()

        // both engi and sniper drop a projectile on death, kill this if we die in ghost/summon mode
        for ( local proj, scope; proj = FindByClassnameWithin( proj, "prop_physics_override", player.GetOrigin(), 128 ); )
            if ( scope = proj.GetScriptScope() && "m_hOwner" in scope && scope.m_hOwner == player )
                EntFireByHandle( proj, "Kill", null, -1, null, null )
    }

    // we died in ghost mode.
    if ( !GetPropInt( player, "m_clrRender" ) ) {

        EntFireByHandle( GetPropEntity( player, "m_hRagdoll"), "Kill", null, 0.1, null, null )
        PZI_Util.ScriptEntFireSafe( player, "self.ForceRespawn()", 0.1 )
    }
})



// local spawn_hint_teleporter = CreateByClassname( "obj_teleporter" )
// spawn_hint_teleporter.KeyValueFromString( "targetname", hint_teleporter_name )

// spawn_hint_teleporter.::DispatchSpawn()
// spawn_hint_teleporter.AddEFlags( EFL_NO_THINK_FUNCTION )

// spawn_hint_teleporter.SetSolid( SOLID_NONE )
// spawn_hint_teleporter.SetSolidFlags( FSOLID_NOT_SOLID )
// spawn_hint_teleporter.DisableDraw()

// // spawn_hint_teleporter.SetModel( "models/player/heavy.mdl" )
// SetPropBool( spawn_hint_teleporter, "m_bPlacing", true )
// SetPropInt( spawn_hint_teleporter, "m_fObjectFlags", 2 )
// SetPropEntity( spawn_hint_teleporter, "m_hBuilder", player )

// // SetPropString( spawn_hint_teleporter, "m_iClassname", "__no_distance_text_hack" )
// spawn_hint_teleporter.KeyValueFromString( "classname", "__no_distance_text_hack" )

// local spawn_hint_text = CreateByClassname( "point_worldtext" )

// spawn_hint_text.KeyValueFromString( "targetname", format( "spawn_hint_text%d", player.entindex() ) )
// spawn_hint_text.KeyValueFromString( "message", "Press[Attack] to spawn" )
// spawn_hint_text.KeyValueFromString( "color", "0 0 255 255" )
// spawn_hint_text.KeyValueFromString( "orientation", "1" )
// spawn_hint_text.AcceptInput( "SetParent", "!activator", spawn_hint_teleporter, spawn_hint_teleporter )
// spawn_hint_text.::DispatchSpawn()