// very lazy brute-force approach that just kills every brush/prop
// this works fine for most older maps, but anything particularly fancy (cp_cowerhouse last point)
// uses dynamic brushes/props for much more significant things than doors/blockers
// come up with something more map-agnostic

PZI_MapLogic.KILL_DOORS_ON_MAP <- {

    cp_dustbowl          = null
    cp_fastlane          = null
    cp_foundry           = null
    cp_gravelpit         = null
    cp_gravelpit_snowy   = null
    cp_lavapit_final     = null
    cp_snakewater_final1 = null
    pl_goldrush          = null
    pl_hasslecastle      = null
    pl_hoodoo_final      = null
    tc_hydro             = null
}

if ( !( MAPNAME in PZI_MapLogic.KILL_DOORS_ON_MAP ) )
    return

local function KillDoors() {

    EntFire( "func_brush", "Kill" )
    EntFire( "prop_dynamic", "Kill" )
}

PZI_EVENT( "teamplay_round_start", "KillDoors", @(_) KillDoors() )
PZI_EVENT( "teamplay_setup_finished", "KillDoors", @(_) KillDoors() )