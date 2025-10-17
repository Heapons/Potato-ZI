// scripts in this folder with the same name as the map will automatically run

// permanently open all doors on tc_hydro

local function OpenAllDoors() {

    EntFire( "func_door", "Open", 1 )
    EntFire( "func_door", "AddOutput", "OnFullyOpen !self:Kill::0:-1", 1 )
    EntFire( "func_brush", "Kill", 1 )
}

OpenAllDoors()

PZI_EVENT( "teamplay_round_start", "PZI_MapStripper_RoundStart", function ( params ) { OpenAllDoors() })
PZI_EVENT( "teamplay_setup_finished", "PZI_MapStripper_SetupFinished", function ( params ) { OpenAllDoors() })