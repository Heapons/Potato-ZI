// kill the A-D lower trigger_hurt.  Both paths are always open
EntFire( "round_A2D_enablehurt", "Kill" )
PZI_EVENT( "teamplay_round_start", "KillDoors", @(params) EntFire( "round_A2D_enablehurt", "Kill" ) )
PZI_EVENT( "teamplay_setup_finished", "KillDoors", @(params) EntFire( "round_A2D_enablehurt", "Kill" ) )