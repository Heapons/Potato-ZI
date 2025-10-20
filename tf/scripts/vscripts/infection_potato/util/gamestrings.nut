// experimental standalone game string handler

/*************************************************************************************************************************************************************
 * PROBLEM:                                                                                                                                                  *
 * All entity access functions will add the entities scriptID and targetname to the string table                                                             *
 * Additionally, "param" arguments passed to Entity I/O related functions ( AcceptInput, EntFire... ) will add the param to the string table                   *
 * these strings don't get cleared until map change, eventually causing a CUtlRBTree overflow                                                                *
 * large amounts of rapid entity spawning, modifying, and Entity I/O calls ( notably RunScriptCode ) will overflow the string table faster                     *
 * freaky fair ( and probably some other vscript-heavy maps ) have this problem on 100 player servers, after ~40 minutes the server will crash with this error *
 *                                                                                                                                                           *
 * Scripters can largely workaround this issue by:                                                                                                           *
 * 1. setting NetProps.SetPropBool( ent, STRING_NETPROP_PURGESTRINGS, true ) on all entities after they are spawned or modified/accessed in any way        *
 * 2. manually hooking and  purging the values passed to the following functions:                                                                            *
 *   - AcceptInput/EntFire/DoEntFire/EntFireByHandle's parameter argument                                                                                    *
 *   - KeyValueFromString                                                                                                                                    *
 *   - SetPropString                                                                                                                                         *
 * 3. constantly purge all targetname/script ID string entries for every entity in a think function to be extra certain.  The risk of doing this are unclear *
 *                                                                                                                                                           *
 * This script does all 3 of these at once, collecting as many strings as possible and batch deleting them in a constantly running generator/think function. *
 *                                                                                                                                                           *
 * It's been recommended by community members to NOT set this netprop until the entity is fully spawned                                                      *
 *  e.g. setting in OnPostSpawn() is safe, setting it in Precache() may break things                                                                         *
 *************************************************************************************************************************************************************/

PZI_CREATE_SCOPE( "__pzi_gamestrings", "PZI_GameStrings", null, "PZI_GameStringsThink" )

local entio_funcs = [ "EntFireByHandle", "DoEntFire", "EntFire" ]

PZI_GameStrings.StringTable <- {}

if ( !( "_SpawnEntityFromTable" in ROOT ) )
    ::_SpawnEntityFromTable <- SpawnEntityFromTable

function PZI_GameStrings::_OnDestroy() {

    foreach ( func in entio_funcs ) {

        local copy_name = format( "_%s", func )
        ROOT[ func ] <- ROOT[ copy_name ]
        delete ROOT[ copy_name ]
    }

    local last_run = StringFixGenerator()

    while ( resume last_run ) continue

    ::SetPropString                  <- NetProps.SetPropString.bindenv( NetProps )
    ::SetPropStringArray             <- NetProps.SetPropStringArray.bindenv( NetProps )
    ::CBaseEntity.KeyValueFromString <- CBaseEntity.__KeyValueFromString.bindenv( CBaseEntity )

    if ( "_SpawnEntityFromTable" in ROOT ) {

        ::SpawnEntityFromTable <- _SpawnEntityFromTable
        delete ::_SpawnEntityFromTable
    }
}

function PZI_GameStrings::PurgeString( str ) {

    if ( !str || str == "" )
        return

    local temp = CreateByClassname( "logic_autosave" )
    SetPropString( temp, STRING_NETPROP_NAME, str )
    SetPropBool( temp, STRING_NETPROP_PURGESTRINGS, true )
    temp.Kill()
    if ( "StringTable" in this && str in StringTable )
        delete StringTable[ str ]
}

// function PopGameStrings::PurgeStringBatch( strings = {} ) {

//     function PurgeStringBatchPostSpawn() {

// 		foreach ( i, ent in ents ) {
//             printl( ent.GetName() )
// 			SetPropBool( ent, STRING_NETPROP_PURGESTRINGS, true )
// 			EntFireByHandle( ent, "Kill", "", i * 0.1, null, null )
// 		}
// 	}

// 	local template = PopExtUtil.PointScriptTemplate( null, PurgeStringBatchPostSpawn )

// 	foreach ( i, k in strings.keys() ) {

// 		template.AddTemplate( "logic_autosave", { targetname = k.tostring() } )
// 		template.AddTemplate( "logic_autosave", { targetname = strings[k].tostring() } )

// 		if ( !( i % 8 ) && i ) {

// 			template.AcceptInput( "ForceSpawn", "", null, null )
//             EntFire( template.GetName(), "Kill", "", 0.1 )
//             template = PopExtUtil.PointScriptTemplate( null, PurgeStringBatchPostSpawn )
//             continue
//         }
// 	}

// 	template.AcceptInput( "ForceSpawn", "", null, null )
// 	template.Kill()
// }

function PZI_GameStrings::StringFixGenerator() {

    if ( !( "PZI_GameStrings" in ROOT ) )
        return

    local PurgeString = PZI_GameStrings.PurgeString

    local i = 1
    foreach ( k, v in ( clone StringTable ) ) {

        PurgeString( k )
        PurgeString( v )

    //    printl( format( "GAME STRINGS : %s : %s : %d", k.tostring(), v ? v.tostring() : "null", i ) )
        if ( !( i % 4 ) )
            yield k || true

        i++
    }
}

local gen = null
local cooldown = 0.0
function PZI_GameStrings::ThinkTable::StringFixThink() {

    if ( Time() < cooldown )
        return

    if ( !StringTable.len() ) {

        cooldown = Time() + 0.2
        return
    }

    if ( !gen || gen.getstatus() == "dead" )
        gen = StringFixGenerator()

    local result = resume gen
}

foreach ( i, func in entio_funcs ) {

    local copy_name = format( "_%s", func )

    if ( copy_name in ROOT )
        continue

    ROOT[ copy_name ] <- ROOT[ func ]

    local _func = ROOT[ copy_name ]

    ROOT[ func ] <- function( ... ) {

        local target    = vargv[0]
        local copy_name = format( "_%s", func )

        if ( "PZI_GameStrings" in ROOT )
            PZI_GameStrings.StringTable[ vargv[1] ] <- 2 in vargv ? vargv[2] : null

        if ( func == "EntFireByHandle" && target && target.IsValid() )
            SetPropBool( target, STRING_NETPROP_PURGESTRINGS, true )

        return _func.acall( [ this ].extend( vargv ) )
    }

}

function CBaseEntity::KeyValueFromString( key, value ) {

    if ( "PZI_GameStrings" in ROOT && value != "" && key == "message" )
        PZI_GameStrings.StringTable[ value ] <- null

    SetPropBool( this, STRING_NETPROP_PURGESTRINGS, true )
    return this.__KeyValueFromString( key, value )
}

function SetPropStringArray( ent, prop, value, index = 0 ) {

    if ( "PZI_GameStrings" in ROOT && value != "" && prop == "m_iszMessage" )
        PZI_GameStrings.StringTable[ value ] <- null

    SetPropBool( ent, STRING_NETPROP_PURGESTRINGS, true )

    return NetProps.SetPropStringArray( ent, prop, value, index )
}

::SetPropString <- SetPropStringArray

// function CreateByClassname( classname ) {

//     local ent = Entities.CreateByClassname( classname )
//     return ent
// }

function SpawnEntityFromTable( classname, table ) {

    if ( !( "_SpawnEntityFromTable" in ROOT ) )
        return SpawnEntityFromTable( classname, table )

    local ent = _SpawnEntityFromTable( classname, table )
    SetPropBool( ent, STRING_NETPROP_PURGESTRINGS, true )

    if ( "PZI_GameStrings" in ROOT )
        PZI_GameStrings.StringTable[ ent.GetScriptId() ] <- null

    return ent
}

function PZI_GameStrings::PurgeAllStrings() {

    EntFire( "*", "RunScriptCode", "PZI_GameStrings.StringTable[self.GetScriptId()] <- null" )
    EntFire( "*", "RunScriptCode", "SetPropBool( self, STRING_NETPROP_PURGESTRINGS, true )" )
    StringTable["PZI_GameStrings.StringTable[self.GetScriptId()] <- null"] <- "SetPropBool( self, STRING_NETPROP_PURGESTRINGS, true )"
}

foreach ( event in [ "teamplay_round_start", "teamplay_setup_finished" ] )
    PZI_EVENT( event, format( "GameStrings%s", event ), @( _ ) PZI_GameStrings.PurgeAllStrings() )