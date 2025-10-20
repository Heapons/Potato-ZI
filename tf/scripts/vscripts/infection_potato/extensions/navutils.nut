// nav utils for generating navmesh on complex multi-stage maps
// also collecting "safe" nav areas (areas that aren't too small, in death pits, or around the edges of the map)

PZI_CREATE_SCOPE( "__pzi_nav", "PZI_Nav", null, "PZI_NavThink" )

PZI_Nav.nav_generation_state <- {
	generator = null,
	is_running = false
}

PZI_Nav.AllNavAreas    <- {}
PZI_Nav.SafeNavAreas   <- {}
PZI_Nav.WalkablePoints <- []
PZI_Nav.NAV_DEBUG      <- false // draw nav areas
PZI_Nav.MAX_AREAS_PER_TICK <- 150
// function PZI_Nav::FindWalkablePoints() {

// }

GetAllAreas( PZI_Nav.AllNavAreas )

// we don't support maps with no nav for now
if ( !PZI_Nav.AllNavAreas.len() ) {

	local msg = "NO NAVMESH FOUND FOR" + MAPNAME + "! SWITCHING TO NEXT MAP\n"

	local fmt = format( "\n%s%s%s\n", msg, msg, msg )

	ClientPrint( null, 3, "\x07FF0000" + msg )
	ClientPrint( null, 3, "\x07FF0000" + msg )
	ClientPrint( null, 3, "\x07FF0000" + msg )

	EntFire( "__pzi_eventwrapper", "Kill" )
	EntFire( "player", "TerminateScriptScope" )
	EntFire( "__pzi_util", "CallScriptFunction", "ChangeLevel", 3 )

	return Assert( false, msg.slice( 0, -1 ) )
}

// pre-collect safe nav areas on load
function PZI_Nav::GetSafeNavAreas() {

	if ( !AllNavAreas.len() )
		return

	PZI_Util.ScriptEntFireSafe( self, "print( `\\n\\n Collecting nav areas, performance warnings will go away shortly...\\n\\n`)", 0.1 )

	local i = 0
	local color_valid  = [   0, 180,  20, 50  ]
	local color_small  = [   0,  20, 180, 50  ]
	local color_edge   = [   0, 180, 180, 50  ]
	local color_warn   = [ 180, 180,  20,  50 ]
	local color_danger = [ 180,   0,  20,  50 ]

	local color = color_valid
	local trace = {}

	// filter out areas that are too small or inside a trigger_hurt
	foreach( name, area in AllNavAreas ) {

		color = color_valid

		if ( area.GetSizeX() < 50 )
			color = color_small

		else if ( area.GetSizeY() < 50 )
			color = color_small

		else if ( PZI_Util.IsPointInTrigger( area.GetCenter(), "trigger_hurt" ) )
			color = color_danger

		else {

			// this is too broken atm
			// for ( local i = 0; i < NUM_DIRECTIONS; i++ )
				// if ( !area.GetAdjacentArea(i, 1) ) {
// 
					// color = color_edge
					// break
				// }

			if ( color != color_edge ) {
	
				trace.clear()
				trace.start <- area.GetCenter()
				trace.end 	<- area.GetCenter() + Vector( 0, 0, INT_MAX )
				trace.mask  <- CONTENTS_SOLID
				trace.hullmin <- area.GetCorner( NORTH_WEST )
				trace.hullmax <- area.GetCorner( SOUTH_EAST )
	
				TraceHull( trace )
	
				if ( trace.hit && trace.enthit && trace.enthit.GetClassname() == "trigger_hurt" )
					color = color_warn

			}
		}

		if ( color == color_valid )
			SafeNavAreas[name] <- area

		if ( NAV_DEBUG )
			area.DebugDrawFilled( color[0], color[1], color[2], color[3], 3.0, true, 0.0 )

		i++

		if ( !(i % MAX_AREAS_PER_TICK) ) // process this many nav areas per tick
			yield SafeNavAreas.len()
	}

	print("\n\nSafe nav areas collected\n\n")
}

local gen = PZI_Nav.GetSafeNavAreas()
// resume gen // do one step right away before thinking

function PZI_Nav::ThinkTable::PopulateSafeNav() {

	if ( gen.getstatus() == "dead" ) {

		delete this.ThinkTable.PopulateSafeNav
		return 1
	}
	local result = resume gen || SafeNavAreas.len()
	printf("Safe Areas: %s / %s\n", result.tostring(), AllNavAreas.len().tostring() )
}

function PZI_Nav::GetRandomSafeArea() { return SafeNavAreas.values()[RandomInt(0, SafeNavAreas.len() - 1)] }

function PZI_Nav::NavGenerate( only_this_arena = null ) {

	local player = GetListenServerHost()

	local progress = 0

	local points_len = WalkablePoints.len()

	foreach( point in WalkablePoints ) {

		local generate_delay = 0.0
		progress++
		// Process spawn points for current arena
		foreach( spawn_point in WalkablePoints ) {

			generate_delay += 0.01
			EntFireByHandle( player, "RunScriptCode", format( @"

				local origin = Vector( %f, %f, %f )
				self.SetAbsOrigin( origin )
				self.SnapEyeAngles( QAngle( 90, 0, 0 ) )
					SendToConsole( `nav_mark_walkable` )
					printl( `Marking Spawn Point: ` + origin )

			", spawn_point[0].x, spawn_point[0].y, spawn_point[0].z ), generate_delay, null, null )
		}

		// Schedule nav generation for current arena
		EntFire( "bignet", "RunScriptCode", format( @"

			ClientPrint( null, 3, `Areas marked!` )
			ClientPrint( null, 3, `Generating nav...` )
			SendToConsole( `host_thread_mode -1` )
			SendToConsole( `nav_generate_incremental` )
			ClientPrint( null, 3, `Progress: ` + %d +`/`+ %d )

		", progress, points_len ), generate_delay + GENERIC_DELAY )

		yield
	}
}

function PZI_Nav::ResumeNavGeneration() {

	if ( nav_generation_state.generator.getstatus() == "dead" )
		return nav_generation_state.is_running = false, null

	resume nav_generation_state.generator
}

function PZI_Nav::CreateNav( only_this_arena = null ) {

	player.SetMoveType( MOVETYPE_NOCLIP, MOVECOLLIDE_DEFAULT )

	scope <- PZI_Util.GetEntScope( player )

	function scope::NavThink() {

		if ( !GetInt( "host_thread_mode" ) )
			ResumeNavGeneration()

		return 1

	}
	AddThinkToEnt( player, "NavThink" )

	// Start generating
	nav_generation_state.generator = NavGenerate( only_this_arena )
	nav_generation_state.is_running = true
}