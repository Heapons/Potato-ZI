for ( local brush, mdlindex; brush = FindByClassname( brush, "func_brush" ); ) {

    mdlindex = GetPropInt( brush, STRING_NETPROP_MODELINDEX )

    // bridge near first point red spawn 
    // stairs near first point red spawn
    if ( mdlindex == 45 || mdlindex == 53 )
        continue

    PZI_Util.EntShredder.append( brush )
}

EntFire( "prop_dynamic", "Kill" )

PZI_EVENT( "teamplay_round_start", "KillDustbowlProps", @(_) EntFire( "prop_dynamic", "Kill" ) )