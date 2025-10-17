local function KillDoors() {

    EntFire( "func_brush", "Kill" )
     // kill the lower path trigger_hurt A->D
    EntFire( "round_A2D_enablehurt", "Kill" )
}

PZI_EVENT( "teamplay_round_start", "KillDoors", @(params) KillDoors() )
PZI_EVENT( "teamplay_setup_finished", "KillDoors", @(params) KillDoors() )