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
    scope.dmg_mult <- dmg_mult
    scope.show_mult <- false

    function DamageRadiusMult[scope]() {

        if ( !bGameStarted || Time() < cooldown_time )
            return

        dmg_mult = DMG_MULT_MIN

        for ( local survivor; survivor = FindByClassnameWithin( survivor, "player", self.GetOrigin(), DMG_MULT_RADIUS ); ) {

            if ( dmg_mult >= DMG_MULT_MAX )
                break

            if ( survivor != self && self.IsAlive() && survivor.GetTeam() == TEAM_HUMAN )
                dmg_mult += DMG_MULT_PER_PLAYER
        }

        if ( show_mult )
            ClientPrint( self, HUD_PRINTCENTER, "Damage multiplier: " + dmg_mult )

        cooldown_time = Time() + UPDATE_INTERVAL
    }
    PZI_Util.AddThink( player, DamageRadiusMult )
})

PZI_EVENT( "OnTakeDamage", "DamageRadiusMult_OnTakeDamage", function( params ) {

    local victim = params.const_entity
    local victim_scope = PZI_Util.GetEntScope( victim )

    if ( victim.IsPlayer() && victim.GetTeam() == TEAM_HUMAN && "dmg_mult" in victim_scope )
        params.damage *= victim_scope.dmg_mult

})

PZI_EVENT( "player_say", "DamageRadiusMult_PlayerSay", function( params ) {

    if ( params.text != ".dmg_mult" ) return

    local player = GetPlayerFromUserID( params.userid )

    if ( player.GetTeam() != TEAM_HUMAN ) return

    local scope = player.GetScriptScope()

    if ( "show_mult" in scope )
        scope.show_mult = !scope.show_mult
})