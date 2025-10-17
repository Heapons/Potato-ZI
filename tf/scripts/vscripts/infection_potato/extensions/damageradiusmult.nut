// damage multiplier based on nearby teammates
// intended to encourage less campy gameplay with smaller, separate parties roaming the map

local DMG_MULT_RADIUS = 256 // radius for damage multiplier
local DMG_MULT_MIN = 0.75 // dmg resistance for solo-runners
local DMG_MULT_MAX = 1.75 // dmg vulnerability for groups
local DMG_MULT_PER_PLAYER = 0.15 // dmg vulnerability for each additional nearby teammate
local UPDATE_INTERVAL = 1.0

PZI_EVENT( "player_spawn", "DamageRadiusMult_OnPlayerSpawn", function( params ) {

    local player = GetPlayerFromUserID( params.userid )

    if ( player.GetTeam() != TEAM_HUMAN ) return

    local scope = player.GetScriptScope()
    local dmg_mult = DMG_MULT_MIN
    local cooldown_time = 0.0

    for ( local survivor; survivor = FindByClassnameWithin( survivor, "player", player.GetOrigin(), DMG_MULT_RADIUS ); ) {

        if ( dmg_mult >= DMG_MULT_MAX )
            break

        if ( survivor.GetTeam() == TEAM_HUMAN && survivor != player )
            dmg_mult += DMG_MULT_PER_PLAYER
    }

    // scope.DmgMult <- dmg_mult > DMG_MULT_MAX ? DMG_MULT_MAX : dmg_mult
    scope.DmgMult <- dmg_mult

    function DamageRadiusMult() {

        if ( !bGameStarted || Time() < cooldown_time )
            return

        local _dmg_mult = DMG_MULT_MIN

        for ( local survivor; survivor = FindByClassnameWithin( survivor, "player", player.GetOrigin(), DMG_MULT_RADIUS ); ) {

            if ( _dmg_mult >= DMG_MULT_MAX )
                break

            if ( survivor.GetTeam() == TEAM_HUMAN && survivor != player )
                _dmg_mult += DMG_MULT_PER_PLAYER
        }

        // ClientPrint( player, HUD_PRINTCENTER, "Damage multiplier: " + _dmg_mult )
        // DmgMult <- _dmg_mult > DMG_MULT_MAX ? DMG_MULT_MAX : _dmg_mult
        DmgMult = _dmg_mult

        cooldown_time = Time() + UPDATE_INTERVAL
    }
    PZI_Util.AddThink( player, DamageRadiusMult )
})

PZI_EVENT( "OnTakeDamage", "DamageRadiusMult_OnTakeDamage", function( params ) {

    local victim = params.const_entity
    local victim_scope = PZI_Util.GetEntScope( victim )

    if ( victim.IsPlayer() && victim.GetTeam() == TEAM_HUMAN && "DmgMult" in victim_scope )
        params.damage *= victim_scope.DmgMult

})

PZI_EVENT( "player_say", "DamageRadiusMult_PlayerSay", function( params ) {

    if ( params.text != ".dmg_mult" ) return

    local player = GetPlayerFromUserID( params.userid )

    if ( player.GetTeam() != TEAM_HUMAN ) return

    local scope = player.GetScriptScope()

    if ( "DmgMult" in scope )
        ClientPrint( player, HUD_PRINTCENTER, "Damage multiplier: " + scope.DmgMult )
})