for ( local brush, mdlindex; brush = FindByClassname( brush, "func_brush" ); ) {

    mdlindex = GetPropInt( brush, STRING_NETPROP_MODELINDEX )

    // bridge near first point red spawn 
    // stairs near first point red spawn
    if ( mdlindex == 45 || mdlindex == 53 )
        continue

    EntFireByHandle( brush, "Kill", null, -1, null, null )
}

EntFire( "prop_dynamic", "Kill" )