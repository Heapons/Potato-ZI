local function KillDoors() {

    EntFire( "func_brush", "Kill" )
    EntFire( "prop_dynamic", "Kill" )
}

PZI_EVENT( "teamplay_round_start", "KillDoors", @(params) KillDoors() )
PZI_EVENT( "teamplay_setup_finished", "KillDoors", @(params) KillDoors() )