PZI_CREATE_SCOPE( "__pzi_myextension", "PZI_NavMesh" )

PZI_NavMesh.ALL_AREAS 	  <- {}
PZI_NavMesh.ISLAND_AREAS  <- {}
PZI_NavMesh.ISLANDS   	  <- []
PZI_NavMesh.IslandsParsed <- false
PZI_NavMesh.ActiveIsland  <- null
PZI_NavMesh.ActiveArea    <- null
PZI_NavMesh.AreaSpawnRed  <- null
PZI_NavMesh.AreaSpawnBlue <- null

// Simple Breadth First Search selecting all connected areas
function PZI_NavMesh::FloodSelect( area, max_iters=10000 ) {

	if ( !( area instanceof CTFNavArea ) ) return

	local frontier = Queue()
	local reached  = {}

	frontier.add( area )
	reached[area] <- null

	local iter = 0
	while ( !frontier.isEmpty() ) {

		if ( iter >= max_iters )
			break

		local current = frontier.pop()
		for ( local i = 0; i < 4; ++i ) {

			local buf = {}
			current.GetAdjacentAreas( i, buf )

			foreach ( a in buf ) {

				if ( !( a in reached ) ) {

					frontier.add( a )
					reached[a] <- null
				}
			}
		}
		++iter
	}

	return reached
}

// Simple Breadth First Search with multiple start points
function PZI_NavMesh::MultiFloodSelect( areas, max_iters=10000 ) {

	local data = {}
	foreach ( area in areas ) {

		if ( !( area instanceof CTFNavArea ) ) return
		data[area] <- { frontier=Queue(), reached={} }

		data[area].frontier.add( area )
		data[area].reached[area] <- null
	}

	for ( local i = 0; i < max_iters; ++i ) {

		local finished = true
		foreach ( area, d in data ) {

			if ( d.frontier.isEmpty() ) continue
			finished = false

			local current = d.frontier.pop()
			for ( local i = 0; i < 4; ++i ) {

				local buf = {}
				current.GetAdjacentAreas( i, buf )

				foreach ( a in buf ) {

					local reached = false
					foreach ( area, d in data ) {

						if ( a in d.reached ) {

							reached = true
							break
						}
					}
					if ( !reached ) {

						d.frontier.add( a )
						d.reached[a] <- null
					}
				}
			}
		}

		if ( finished ) break
	}

	local reached = {}
	foreach ( area, d in data )
		reached[area] <- d.reached

	return reached
}

function PZI_NavMesh::GetRandomArea( areas, spawnpoint=false ) {

	local max_iters = 50

	for ( local j = 0; j < max_iters; ++j ) {

		local index = RandomInt( 0, areas.len() - 1 )
		local i = 0

		foreach ( k, v in areas ) {

			if ( i < index ) {

				++i
				continue
			}

			// Islands store areas as {area=null},
			// but NavMesh methods store as {"area<num>"=area}
			local a = ( k instanceof CTFNavArea ) ? k : v

			if ( !spawnpoint )
				return a
			else {

				local center = a.GetCenter()
				local trace = {
					start   = center + Vector( 0, 0, 24 ),
					end     = center + Vector( 0, 0, 106 ),
					hullmin = Vector( -32, -32, 0 ),
					hullmax = Vector( 32, 32, 0 ),
					mask    = 33636363 // MASK_PLAYERSOLID
				}
				TraceHull( trace )
				if ( "hit" in trace && trace.hit )
					continue
				else
					return a
			}
		}
	}
}
// Look for nav mesh islands and generate 3 areas within each
// VERY EXPENSIVE, use only on first teamplay_round_start
function PZI_NavMesh::GenerateIslandAreas() {

	if ( !ALL_AREAS.len() ) return

	// Keep track of these so we can use them for getting the areas later
	// { island : {team : []} }
	local island_spawnpoints = {}
	for ( local ent = null; ent = FindByClassname( ent, "info_player_teamspawn" ); ) {

		local area = NavMesh.GetNearestNavArea( ent.GetOrigin(), 128.0, false, true )
		if ( !area ) continue

		local island = null

		// Is this area in another island?
		local reached = false
		foreach ( isl in PZI_NavMesh.ISLANDS ) {

			if ( area in isl ) {

				island = isl
				reached = true
				break
			}
		}

		// Nope, create a new island
		if ( !reached ) {

			island = PZI_NavMesh.FloodSelect( area )

			// 25 is a quick and dirty arbitrary number to filter out islands that aren't big enough for gameplay
			// in an efficient manner. Typically map islands will be in the thousands in length
			// and iterating that many times just to tally up size is wastefully expensive
			if ( island && island.len() > 25 )
				PZI_NavMesh.ISLANDS.append( island )
		}

		// Keep track of this spawn point's island and team
		if ( island ) {

			if ( !( island in island_spawnpoints ) )
				island_spawnpoints[island] <- {[2]=[],[3]=[]}

			local team = ent.GetTeam()
			if ( team == 2 || team == 3 )
				island_spawnpoints[island][team].append( ent )
		}
	}

	// Generate areas within islands
	foreach ( island in PZI_NavMesh.ISLANDS ) {

		if ( !( island in island_spawnpoints ) ) continue; // This shouldn't happen but just incase
		local spawns = island_spawnpoints[island]

		PZI_NavMesh.ISLAND_AREAS[island] <- []

		// Grab a random spawn from each team
		local redspawn  = null
		local bluespawn = null
		foreach ( team, arr in spawns ) {

			local i = RandomInt( 0, arr.len() - 1 )
			if ( team == 2 )
				redspawn = arr[i]
			else
				bluespawn = arr[i]
		}

		// Get their areas
		local redarea  = NavMesh.GetNearestNavArea( redspawn.GetOrigin(), 128.0, false, true )
		local bluearea = NavMesh.GetNearestNavArea( bluespawn.GetOrigin(), 128.0, false, true )

		// Get an area somewhere inbetween
		local vec  = bluearea.GetCenter() - redarea.GetCenter()
		local dist = vec.Length() / 2
		vec.Norm()
		vec *= dist
		local pos = redarea.GetCenter() + vec

		local middlearea = NavMesh.GetNearestNavArea( pos, 8192.0, false, true )

		// If the above failed then fallback to random nav areas in the island
		local seedareas = [redarea, middlearea, bluearea]
		foreach ( i, area in seedareas )
			if ( !area )
				seedareas[i] = PZI_NavMesh.GetRandomArea( island )

		// Store the areas
		local reached = PZI_NavMesh.MultiFloodSelect( seedareas )
		foreach ( area in seedareas )
			PZI_NavMesh.ISLAND_AREAS[island].append( reached[area] )
	}

	// Delete extra spawnpoints
	foreach ( island, spawns in island_spawnpoints ) {

		foreach ( team, arr in spawns ) {

			if ( arr.len() < 2 ) continue
			foreach ( index, spawn in arr ) {

				// Keep one
				if ( !index ) continue

				EntFireByHandle( spawn, "Kill", "", 0, null, null )
			}
		}
	}

	// Used elsewhere to check if this function should be ran
	PZI_NavMesh.IslandsParsed = true
}