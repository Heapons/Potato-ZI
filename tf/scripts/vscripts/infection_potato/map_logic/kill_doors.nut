// very lazy brute-force approach that just kills every brush/prop
// this works fine for most older maps, but anything particularly fancy (cp_cowerhouse last point)
// uses dynamic brushes/props for much more significant things than doors/blockers
// come up with something more map-agnostic

PZI_MapLogic.KILL_DOORS_ON_MAP <- {

    cp_fastlane          = null
    cp_foundry           = null
    cp_gorge_event       = null
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


local relay_table = {

    spawnflags = 1

    "OnSpawn#1" : "func_door*,AddOutput,OnFullyOpened func_door*:Kill::0:-1,0,-1"
    "OnSpawn#2" : "func_door*,Unlock,,0,-1"
    "OnSpawn#3" : "func_door*,Open,,0.1,-1"
    "OnSpawn#4" : "func_door*,Kill,,15,-1"
}

local ent, scope, ents = array( MAX_EDICTS - MAX_CLIENTS )
local _true = @() true, _false = @() false
local function KillDoors() {

    ents.resize( MAX_EDICTS - MAX_CLIENTS )
    // kill all props and brushes associated with the doors
    foreach( i, d in [ "func_door*", "func_areaportal*", "func_brush", "prop_dynamic*", "phys_bone_follower" ] ) {

        while ( ent = FindByClassname( ent, d ) ) {

            if ( i > 1 ) {

                ents[i++] = ent
                continue
            }

            scope = PZI_Util.GetEntScope( ent )

            scope.InputClose <- _false
            scope.Inputclose <- _false
            scope.InputLock  <- _false
            scope.Inputlock  <- _false

            scope.InputOpen  <- _true
            scope.Inputopen  <- _true
            scope.InputUnlock <- _true
            scope.Inputunlock <- _true
        }
    }

    PZI_Util.EntShredder.extend( ents )
    ents.clear()

    SpawnEntityFromTable( "logic_relay", relay_table )
}

KillDoors()
PZI_EVENT( "teamplay_round_start", "PZI_MapLogic_KillDoors", @(_) KillDoors() )
PZI_EVENT( "teamplay_setup_finished", "PZI_MapLogic_KillDoors", @(_) KillDoors() )