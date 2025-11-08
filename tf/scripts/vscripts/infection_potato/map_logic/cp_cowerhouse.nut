local ent, name, i = 0, ents = array( MAX_EDICTS - MAX_CLIENTS )

local function KillCowerhouseEnts() {

    i = 0, ents.resize( MAX_EDICTS - MAX_CLIENTS )

    while ( ent = FindByClassname( ent, "func_brush" ) ) {

        // blu finale brushes
        if ( ( name = ent.GetName() ) != "" && name[0] == 'b' ) {

            SetPropBool( ent, STRING_NETPROP_PURGESTRINGS, true )
            continue
        }
        ents[i++] = ent
    }

    local blu_cap = FindByName( null, "blu_cap_prop" ).GetOrigin()

    // don't kill props around blu cap
    while ( ent = FindByClassname( ent, "prop_dynamic" ) )

        // 1024^2
        if ( ( ent.GetOrigin() - blu_cap ).LengthSqr() > 1048576.0 ) {

            ents[i++] = ent
            continue
        }
        
        SetPropBool( ent, STRING_NETPROP_PURGESTRINGS, true ) // also kill other props in the area

    foreach( cls in [ "trigger_hurt", "phys_bone_follower", "info_particle_system" ] )
        while ( ent = FindByClassname( ent, cls ) )
            ents[i++] = ent

    PZI_Util.EntShredder.extend( ents )
    ents.clear()

    SpawnEntityFromTable( "logic_relay", {
    
        spawnflags = 1

        // cowerhouse uses func_door_rotating for important things, kill_doors.nut would kill these too
        "OnSpawn#1" : "func_door,AddOutput,OnFullyOpened func_door:Kill::0:-1,0,-1"
        "OnSpawn#2" : "func_door,Unlock,,0,-1"
        "OnSpawn#3" : "func_door,Open,,0.1,-1"
        "OnSpawn#4" : "func_door,Kill,,15,-1"
    })
}

KillCowerhouseEnts()
PZI_EVENT( "teamplay_round_start", "PZI_MapLogic_KillCowerhouseEnts", @(_) KillCowerhouseEnts() )
PZI_EVENT( "teamplay_setup_finished", "PZI_MapLogic_KillCowerhouseEnts", @(_) KillCowerhouseEnts() )