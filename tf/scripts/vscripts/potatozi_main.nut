// add extensions to this table.
// extensions will be loaded in the order they are defined.
::PZI_ACTIVE_EXTENSIONS <- [
    {"infection_potato/extensions/"    : [ "damageradiusmult", "spawnanywhere", "bots" ] }
]

::ROOT <- getroottable()

try { PZI_Events.ClearEvents( null ) } catch( e ) {}

for ( local ent; ent = Entities.FindByName( ent, "__pzi*" ); )
    EntFireByHandle( ent, "Kill", "", -1, null, null )

Convars.SetValue( "mp_restartgame", 3 )
ClientPrint( null, 3, "[PZI] GAMEMODE RELOADED, RESTARTING..." )
ClientPrint( null, 4, "[PZI] GAMEMODE RELOADED, RESTARTING..." )
EntFire( "player", "RunScriptCode", "self.AddFlag( FL_FROZEN ); AddThinkToEnt( self, null ); self.TerminateScriptScope()" )
EntFire( "player", "RunScriptCode", "self.RemoveFlag( FL_FROZEN )", 4 )

if ( "PZI_GameStrings" in ROOT )
    PZI_GameStrings.StringTable[ "self.AddFlag( FL_FROZEN ); AddThinkToEnt( self, null ); self.TerminateScriptScope()" ] <- "self.RemoveFlag( FL_FROZEN )"

try { delete ::PZI_CREATE_SCOPE } catch( e ) {}

local function Include( script ) { IncludeScript( script, ROOT ) }

// core files
// extensions listed above are always included AFTER these.
local include = [

    // our new utils
    {"infection_potato/util/" : [ "constants", "itemdef_constants", "item_map", "create_scope", "event_wrapper", "gamestrings", "navutils", "util" ] }
    // core zi files
    {"infection_potato/" : [ "strings", "const", "infection" ] }
    // misc map logic scripts for map conversions
    {"infection_potato/map_logic/" : [ "maplogic_main" ] }
]

local function IncludeGen( include ) {

    foreach ( inc in include )
        foreach ( dir, files in inc || {} )
            foreach ( i, file in files || [""] )
                yield Include( dir+file ), file
}

// load core files
local gen = IncludeGen( include )
while ( gen.getstatus() != "dead" )
    resume gen

// now load extensions
// this is done in a separate operation so extensions can access constants immediately
gen = IncludeGen( PZI_ACTIVE_EXTENSIONS )
while ( gen.getstatus() != "dead" )
    resume gen

// IncludeGen( include )