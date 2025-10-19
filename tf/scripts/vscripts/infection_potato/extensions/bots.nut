PZI_CREATE_SCOPE( "__pzi_bots", "PZI_Bots", "PZI_BotSpawner", "PZI_BotSpawnerThink" )

PZI_Bots.NAV_SNIPER_SPOT_FACTOR <- 125 // higher value = lower chance.  1/30 chance to be a sniper spot
PZI_Bots.NAV_SENTRY_SPOT_FACTOR <- 370 // higher value = lower chance.  1/50 chance to be a sentry spot
PZI_Bots.MAX_THREAT_DISTANCE 	<- 64.0 * 64.0 // we use LengthSqr for performance
local STR_PROJECTILES = "tf_projectile*"

PZI_Bots.RandomLoadouts <- {

    [TF_CLASS_SCOUT] = {

		[SLOT_PRIMARY] = [

			"The Soda Popper",
			"The Shortstop",
			"The Force-a-Nature"
		],

		[SLOT_SECONDARY] = [

			"The Winger",
			"Pretty Boy's Pocket Pistol",
			"Mad Milk",
			"Crit-a-Cola",
			"The Flying Guillotine"
		],

		[SLOT_MELEE] = [

			"The Candy Cane",
			"The Fan O'War",
			"The Atomizer",
			"Unarmed Combat",
			"The Holy Mackerel"
		]
	},

    [TF_CLASS_SOLDIER] = {

		[SLOT_PRIMARY] = [

			"The Original",
			"The Liberty Launcher",
			"The Black Box",
			"The Direct Hit"
		],

		[SLOT_SECONDARY] = [

			"Panic Attack Shotgun",
			"The Reserve Shooter",
			"The Buff Banner",
			"The Concheror",
			"The Battalion's Backup"
		],

		[SLOT_MELEE] = [

			"The Disciplinary Action",
			"The Equalizer",
			"The Escape Plan",
			"The Pain Train",
			"The Half-Zatoichi"
		]
	},

	[TF_CLASS_PYRO] = {

		[SLOT_PRIMARY] = [

			"The Backburner",
			"The Degreaser",
			"The Nostromo Napalmer",
			"The Dragon's Fury"
		],

		[SLOT_SECONDARY] = [

			"The Flare Gun",
			"The Scorch Shot",
			"The Detonator",
			"The Manmelter",
			"The Reserve Shooter",
			"Panic Attack Shotgun",
			"The Thermal Thruster"
		],

		[SLOT_MELEE] = [

			"The Third Degree",
			"The Hot Hand",
			"The Back Scratcher",
			"The Homewrecker",
			"The Maul",
			"The Powerjack",
			"The Axtinguisher"
		]
	},

    [TF_CLASS_DEMOMAN] = {

		[SLOT_PRIMARY] = [

			"The Iron Bomber",
			"The Loch-n-Load",
			"Ali Baba's Wee Booties",
			"The Bootlegger"
		],

		[SLOT_SECONDARY] = [

			"The Scottish Resistance",
			"The Quickiebomb Launcher",
			"The Chargin' Targe",
			"The Tide Turner",
			"The Splendid Screen"
		],

		[SLOT_MELEE] = [

			"The Scottish Handshake",
			"The Eyelander",
			"The Scotsman's Skullcutter",
			"The Half-Zatoichi",
			"The Claidheamohmor",
			"The Persian Persuader",
			"The Ullapool Caber"
		]
	},

    [TF_CLASS_HEAVYWEAPONS] = {

		[SLOT_PRIMARY] = [

			"Natascha",
			"Tomislav",
			"The Brass Beast",
			"The Huo Long Heatmaker"
		],

		[SLOT_SECONDARY] = [

			"The Family Business",
			"Panic Attack Shotgun",
			"The Sandvich",
			"Fishcake",
			"The Dalokohs Bar",
			"The Second Banana"
		],

		[SLOT_MELEE] = [

			"The Killing Gloves of Boxing",
			"Gloves of Running Urgently",
			"Gloves of Running Urgently MvM",
			"The Eviction Notice",
			"Fists of Steel",
			"The Holiday Punch",
			"Apoco-Fists"
		]
	},

	[TF_CLASS_ENGINEER] = {

		[SLOT_PRIMARY] = [

			"The Rescue Ranger",
			"The Frontier Justice",
			"The Pomson 6000",
			"The Widowmaker",
			"Panic Attack Shotgun"
		],

		[SLOT_SECONDARY] = [
			"The Short Circuit"
		],

		[SLOT_MELEE] = [

			"The Eureka Effect",
			"The Jag",
			"The Gunslinger",
			"The Southern Hospitality"
		]
	},

	[TF_CLASS_MEDIC] = {

		[SLOT_PRIMARY] = [

			"The Crusader's Crossbow",
			"The Blutsauger",
			"The Overdose"
		],

		[SLOT_SECONDARY] = [

			"The Kritzkrieg",
			"The Vaccinator",
			"The Quick-Fix",
		],

		[SLOT_MELEE] = [
			"The Amputator",
			"The Ubersaw",
			"The Vita-Saw"
		]
	},

	[TF_CLASS_SNIPER] = {

		[SLOT_PRIMARY] = [

			"The Huntsman",
			"The Fortified Compound",
			"The Sydney Sleeper",
			"The Machina",
			"The Hitman's Heatmaker"
		],

		[SLOT_SECONDARY] = [

			"The Cleaner's Carbine",
			"Jarate",
			"Darwin's Danger Shield",
			"The Cozy Camper"
		],

		[SLOT_MELEE] = [

			"The Bushwacka",
			"The Tribalman's Shiv",
			"The Shahanshah"
		]
	},


	[TF_CLASS_SPY] = {

		[SLOT_PRIMARY] = [

			"The Ambassador",
			"The L'etranger",
			"The Enforcer",
			"The Diamondback",
		],

		[SLOT_MELEE] = [

			"You Eternal Reward",
			"The Wanga Prick",
			"The Big Earner",
			"The Conniver's Kunai",
			"The Black Rose"
		]
	},

}

PZI_Bots.red_buildings <- {}

PZI_Bots.PZI_PathPoint <- class {

	constructor( area, pos, how ) {

		this.area = area
		this.pos  = pos
		this.how  = how
	}

	area = null
	pos  = null
	how  = null
}

PZI_Bots.PZI_BotBehavior <- class {

	constructor( bot ) {

		this.bot       = bot
		this.scope     = bot.GetScriptScope()
		this.team      = bot.GetTeam()
		this.cur_eye_ang = bot.EyeAngles()
		this.cur_eye_pos = bot.EyePosition()
		this.cur_eye_fwd = bot.EyeAngles().Forward()
		this.locomotion = bot.GetLocomotionInterface()

		this.time = Time()

		this.threat 			 = null
        this.threat_dist         = 0.0
		this.threat_time         = 0.0
		this.threat_lost_time    = 0.0
		this.threat_aim_time     = 0.0
		this.threat_behind_time  = 0.0
		this.threat_visible      = false
		this.fire_next_time      = 0.0
		this.aim_time            = FLT_MAX
		this.random_aim_time     = 0.0

		this.path_points 		 = []
		this.path_index 		 = 0
		this.path_areas 		 = {}
		this.path_goalpoint 	 = null
		this.path_recompute_time = 0.0

		this.bot_level 			 = bot.GetDifficulty()

		this.navdebug = false
	}

	function GiveRandomLoadout() {

		local botcls = bot.GetPlayerClass()
		local loadouts = PZI_Bots.RandomLoadouts[ botcls ]

		bot.AddEFlags( EFL_IS_BEING_LIFTED_BY_BARNACLE )

		foreach ( slot, wepinfo in loadouts ) {

			local wepname = wepinfo[ RandomInt( 0, wepinfo.len() - 1 ) ]
			local wep = PZI_ItemMap[ wepname ]

			if ( wep.item_class[0] == 't' && wep.item_class[6] == 'r' ) // tf_wearable-based weapon, use this instead.
				bot.GenerateAndWearItem( wepname )

			else {

				local cls = wep.item_class

				if ( typeof cls == "array" )
					cls = wep.item_class[ wep.animset.find( PZI_Util.Classes[ botcls ] ) ]

				local wep_ent = PZI_Util.GiveWeapon( bot, cls, wep.id )

				if ( bot.entindex() in PZI_Util.kill_on_death )
					PZI_Util.kill_on_death[ bot ].append( wep_ent )
				else
					PZI_Util.kill_on_death[ bot ] <- [ wep_ent ]
			}
		}

		PZI_Util.SwitchWeaponSlot( bot, SLOT_PRIMARY )

		bot.RemoveEFlags( EFL_IS_BEING_LIFTED_BY_BARNACLE )
	}
	function IsLookingTowards( target, cos_tolerance ) {

		local to_target = target - bot.EyePosition()
		to_target.Norm()
		local dot = cur_eye_fwd.Dot( to_target )
		return ( dot >= cos_tolerance )
	}

	function IsInFieldOfView( target ) {

		local tolerance = 0.5736 // cos( 110/2 )

		local delta = target.GetOrigin() - cur_eye_pos
		delta.Norm()
		if ( cur_eye_fwd.Dot( target ) >= tolerance )
			return true

		delta = target.GetCenter() - cur_eye_pos
		delta.Norm()
		if ( cur_eye_fwd.Dot( delta ) >= tolerance )
			return true

		delta = target.EyePosition() - cur_eye_pos
		delta.Norm()
		return ( cur_eye_fwd.Dot( delta ) >= tolerance )
	}

	function IsVisible( target ) {

		local trace = {
			start  = bot.EyePosition(),
			end    = target.EyePosition(),
			mask   = MASK_OPAQUE,
			ignore = bot
		}
		TraceLineEx( trace )
		return !trace.hit
	}

	function IsThreatVisible( target ) 		{ return threat_visible = ( IsInFieldOfView( target ) && IsVisible( target ) ), threat_visible }

	function GetThreatDistance( target ) 	{ return ( target.GetOrigin() - bot.GetOrigin() ).Length() }

    function GetThreatDistance2D( target ) 	{ return ( target.GetOrigin() - bot.GetOrigin() ).Length2D() }

	function GetThreatDistanceSqr( target ) { return ( target.GetOrigin() - bot.GetOrigin() ).LengthSqr() }	

	function GetCurThreatDistance() 		{ return ( threat - cur_pos ).Length() }

	function GetCurThreatDistanceSqr() 		{ return ( threat - cur_pos ).LengthSqr() }

	function FindClosestThreat( min_dist, must_be_visible = true ) {

		local closest_threat = null
		local closest_threat_dist = min_dist

		foreach ( player in PZI_Util.PlayerArray ) {

			if ( player == bot || !player.IsAlive() || player.GetTeam() == bot.GetTeam() || ( must_be_visible && !IsThreatVisible( player ) ) )
				continue

			local dist = GetThreatDistanceSqr( player )
			if ( dist < closest_threat_dist ) {
				closest_threat = player
				closest_threat_dist = dist
			}
		}
		return closest_threat
	}

	function CollectThreats( maxdist = INT_MAX, disguised = false, invisible = false, alive = true ) {

		local threatarray = []
		foreach ( player in PZI_Util.PlayerArray ) {

			if (
				player == bot
				|| player.GetTeam() == bot.GetTeam()
				|| ( !invisible && player.IsFullyInvisible() )
				|| ( !disguised && player.IsStealthed() )
				|| ( alive && player.IsAlive() )
				|| GetThreatDistanceSqr( player ) > maxdist
			)
				continue

			threatarray.append( player )
		}
		return threatarray
	}

	function SetThreat( target, visible ) {

		if ( !threat || !threat.IsValid() )
			return threat = null

		threat 			   = target
		threat_pos 		   = threat.GetOrigin()
		threat_visible 	   = visible
		threat_behind_time = time + 0.5
	}

	// function SwitchToBestWeapon() { local weapon = bot.GetActiveWeapon() }

	function CheckForProjectileThreat() {

		local projectile
		while ( projectile = FindByClassname( projectile, STR_PROJECTILES ) ) {
			if ( projectile.GetTeam() == team || !IsValidProjectile( projectile ) )
				continue

			local dist = GetThreatDistanceSqr( projectile )
			if ( dist <= 67000 && IsVisible( projectile ) ) {

				switch ( bot_level ) {
				case 1: // Normal Skill, only deflect if in FOV
					if ( !IsInFieldOfView( projectile ) )
						return
				break

				case 2: // Hard skill, deflect regardless of FOV
					LookAt( projectile.GetOrigin(), INT_MAX, INT_MAX )
				break

				case 3: // Expert skill, deflect regardless of FOV back to Sender
					local owner = projectile.GetOwner()
					if ( owner ) {
						// local owner_head = owner.GetAttachmentOrigin( owner.LookupAttachment( "head" ) )
						// LookAt( owner_head, INT_MAX, INT_MAX )
						LookAt( owner.EyePosition(), INT_MAX, INT_MAX )
					}
				break
				}
				bot.PressAltFireButton( 0.5 )
			}
		}
	}

	function LookAt( target_pos, min_rate, max_rate ) {

		local dt  = FrameTime()
		local dir = target_pos - cur_eye_pos
		dir.Norm()
		local dot = cur_eye_fwd.Dot( dir )

		local desired_angles = PZI_Util.VectorAngles( dir )

		local rate_x = PZI_Util.RemapValClamped( fabs( PZI_Util.NormalizeAngle( cur_eye_ang.x ) - PZI_Util.NormalizeAngle( desired_angles.x ) ), 0.0, 180.0, min_rate, max_rate )
		local rate_y = PZI_Util.RemapValClamped( fabs( PZI_Util.NormalizeAngle( cur_eye_ang.y ) - PZI_Util.NormalizeAngle( desired_angles.y ) ), 0.0, 180.0, min_rate, max_rate )

		if ( dot > 0.7 ) {
			local t = PZI_Util.RemapValClamped( dot, 0.7, 1.0, 1.0, 0.05 )
			local d = sin( 1.57 * t ) // pi/2
			rate_x *= d
			rate_y *= d
		}

		cur_eye_ang.x = PZI_Util.NormalizeAngle( PZI_Util.ApproachAngle( desired_angles.x, cur_eye_ang.x, rate_x * dt ) )
		cur_eye_ang.y = PZI_Util.NormalizeAngle( PZI_Util.ApproachAngle( desired_angles.y, cur_eye_ang.y, rate_y * dt ) )

		bot.SnapEyeAngles( cur_eye_ang )
	}

	//260 Hammer Units or 67700 SQR
	function FireWeapon() {

		if ( cur_melee ) {
			if ( threat ) {
				threat_dist = GetThreatDistanceSqr( threat )
				if ( threat_dist < 16384.0 ) // 128
					bot.PressFireButton( 0.2 )
			}

			return true
		}

		if ( fire_next_time > time ) {
			bot.AddBotAttribute( IGNORE_ENEMIES )
			bot.PressFireButton()
			bot.RemoveBotAttribute( IGNORE_ENEMIES )
			return false
		}

		if ( !cur_ammo )
			return false

		local duration     = 0.11
		local velocity_max = 50.0

		if ( 1 )
			if ( cur_vel.Length() < velocity_max )
				bot.PressFireButton( duration )
		else
			fire_next_time = time + RandomFloat( 0.3, 0.6 )

		return true
	}

	function StartAimWithWeapon() {
		if ( aim_time != FLT_MAX )
			return

		bot.PressAltFireButton( INT_MAX )
		aim_time = time
	}

	function EndAimWithWeapon() {
		if ( aim_time == FLT_MAX )
			return

		bot.AddBotAttribute( SUPPRESS_FIRE )
		bot.PressAltFireButton( 0.5 )
		bot.RemoveBotAttribute( SUPPRESS_FIRE )
		aim_time = FLT_MAX
	}

	function OnTakeDamage( params ) {

		if ( params.attacker && params.attacker != this && params.attacker.IsPlayer() ) {

			if ( threat && threat.IsValid() ) {
				threat_dist = GetThreatDistanceSqr( threat ) * 0.8

				if ( threat_dist > 16384.0 ) {
					local attacker_dist = GetThreatDistanceSqr( params.attacker )
					threat_dist   = GetThreatDistanceSqr( threat ) * 0.8

					if ( attacker_dist > threat_dist )
						return
				}
			}

			SetThreat( params.attacker, true )
		}
	}

	function OnUpdate() {

		cur_pos     = bot.GetOrigin()
		cur_vel     = bot.GetAbsVelocity()
		cur_speed   = cur_vel.Length()
		cur_eye_pos = bot.EyePosition()
		cur_eye_ang = bot.EyeAngles()
		cur_eye_fwd = cur_eye_ang.Forward()

		time = Time()

		//SwitchToBestWeapon()
		//DrawDebugInfo()

		return -1
	}
	function FindPathToThreat() {

		if ( path_recompute_time < time ) {

			local threat_cur_pos = threat.GetOrigin()

			if ( ( !path_points.len() ) || ( ( threat_pos - threat_cur_pos ).LengthSqr() > PZI_Bots.MAX_THREAT_DISTANCE ) ) {

				local area = GetNavArea( threat_cur_pos, 0.0 )
				if ( area ) {

					UpdatePathAndMove( threat_cur_pos )
				}

				threat_pos = threat_cur_pos
			}

			path_recompute_time = time + 0.5
		}
	}
	function ResetPath() {

		path_areas.clear()
		path_points.clear()
		path_index = null
		path_recompute_time = 0
	}
	function UpdatePathAndMove( target_pos, lookat = true, turnrate_min = 600, turnrate_max = 1500 ) {

		local dist_to_target = ( target_pos - bot.GetOrigin() ).Length()
        local path_count = path_points.len()

		if ( path_recompute_time < time ) {
			ResetPath()

			local pos_start = bot.GetOrigin()
			local pos_end   = target_pos

			local area_start = GetNavArea( pos_start, 128.0 )
			local area_end   = GetNavArea( pos_end, 128.0 )

			if ( !area_start )
				area_start = GetNearestNavArea( pos_start, 128.0, false, true )
			if ( !area_end )
				area_end   = GetNearestNavArea( pos_end, 128.0, false, true )

			if ( !area_start || !area_end )
				return false
			if ( !GetNavAreasFromBuildPath( area_start, area_end, pos_end, 0.0, team, false, path_areas ) )
				return false
			if ( area_start != area_end && !path_areas.len() )
				return false

			// Construct path_points
			else {
				path_areas["area"+path_areas.len()] <- area_start
				local area = path_areas["area0"]
				local area_count = path_areas.len()

				// Initial run grabbing area center
				for ( local i = 0; i < area_count && area; i++ ) {
					// Don't add a point for the end area
					if ( i > 0 )
						path_points.append( PZI_Bots.PZI_PathPoint( area, area.GetCenter(), area.GetParentHow() ) )

					area = area.GetParent()
				}

				path_points.reverse()
				path_points.append( PZI_Bots.PZI_PathPoint( area_end, pos_end, 9 ) ) // NUM_TRAVERSE_TYPES

				// Go through again and replace center with border point of next area

				for ( local i = 0; i < path_count; i++ ) {

					if ( !( i in path_points) || !(i + 1 in path_points) )
						continue


					local path_from = path_points[i]
					local path_to = ( i < path_count - 1 ) ? path_points[i + 1] : null

					if ( path_to ) {
						local dir_to_from = path_to.area.ComputeDirection( path_from.area.GetCenter() )
						local dir_from_to = path_from.area.ComputeDirection( path_to.area.GetCenter() )

						local to_c1 = path_to.area.GetCorner( dir_to_from )
						local to_c2 = path_to.area.GetCorner( dir_to_from + 1 )
						local fr_c1 = path_from.area.GetCorner( dir_from_to )
						local fr_c2 = path_from.area.GetCorner( dir_from_to + 1 )

						local minarea = {}
						local maxarea = {}
						if ( ( to_c1 - to_c2 ).Length() < ( fr_c1 - fr_c2 ).Length() ) {
							minarea.area <- path_to.area
							minarea.c1 <- to_c1
							minarea.c2 <- to_c2

							maxarea.area <- path_from.area
							maxarea.c1 <- fr_c1
							maxarea.c2 <- fr_c2
						}
						else {
							minarea.area <- path_from.area
							minarea.c1 <- fr_c1
							minarea.c2 <- fr_c2

							maxarea.area <- path_to.area
							maxarea.c1 <- to_c1
							maxarea.c2 <- to_c2
						}

						// Get center of smaller area's edge between the two
						local vec = minarea.area.GetCenter()
						if ( !dir_to_from || dir_to_from == 2 ) { // GO_NORTH, GO_SOUTH
							vec.y = minarea.c1.y
							vec.z = minarea.c1.z
						}
						else if ( dir_to_from == 1 || dir_to_from == 3 ) { // GO_EAST, GO_WEST
							vec.x = minarea.c1.x
							vec.z = minarea.c1.z
						}

						path_from.pos = vec
					}
				}
			}

			// Base recompute off distance to target
			// Every 500hu away increase our recompute time by 0.1s
			local mod = 0.1 * ceil( dist_to_target / 500.0 )
			if ( mod > 1 ) mod = 1

			path_recompute_time = time + mod
		}

		if ( navdebug ) {

			for ( local i = 0; i < path_count; i++ ) {
				if ( i in path_points)
					DebugDrawLine( path_points[i].pos, (i+1 < path_points.len()) ? path_points[i+1].pos : path_points[i].pos, 0, 0, 255, false, 0.1 )
				// else
					// __DumpScope( 0, path_points )
			}
			local area = path_areas["area0"]
			local area_count = path_areas.len()

			for ( local i = 0; i < area_count && area; i++ ) {
				local x = ( ( area_count - i - 0.0 ) / area_count ) * 255.0
				area.DebugDrawFilled( 0, x, 0, 50, 0.075, true, 0.0 )

				area = area.GetParent()
			}
		}

		// if (!(path_index in path_points))
		// 	return

		if ( path_index == null || !(path_index in path_points) )
			path_index = 0

		if ( ( path_points[path_index].pos - bot.GetOrigin() ).Length() < 64.0 ) {
			path_index++
			if ( path_index >= path_count ) {
				ResetPath()
				return
			}
		}

		// if ( !(path_index in path_points) )
		// 	__DumpScope( 0, path_points )

		local point = path_points[path_index].pos
		locomotion.Approach( point, 1.0 )
		// locomotion.DriveTo( point )
		// locomotion.FaceTowards( point )

		local look_pos = Vector( point.x, point.y, cur_eye_pos.z )
		if ( lookat )
			if ( threat )
				LookAt( look_pos, turnrate_min, turnrate_max )
			else
				LookAt( look_pos, 350.0, 600.0 )

		// calc lookahead point

		// set eyeang based on lookahead
		// set loco on lookahead if no obstacles found
		// if found obstacle, modify loco
	}


	bot   				= null
	scope 				= null
	team  				= null
	time  				= null

	bot_level  			= null
	locomotion 			= null

	cur_pos     		= null
	cur_vel     		= null
	cur_speed   		= null
	cur_eye_pos 		= null
	cur_eye_ang 		= null
	cur_eye_fwd 		= null
	cur_weapon  		= null
	cur_ammo    		= null
	cur_melee   		= null

	threat              = null
	threat_dist         = null
	threat_time         = null
	threat_lost_time    = null
	threat_aim_time     = null
	threat_behind_time  = null
	threat_visible      = null
	threat_pos          = null

	path_points		    = null
	path_index			= null
	path_areas			= null
	path_goalpoint      = null
	path_recompute_time	= null

	fire_next_time  	= null
	aim_time        	= null
	random_aim_pos  	= null
	random_aim_time 	= null

	cosmetic 			= null

	navdebug 			= null
}

function PZI_Bots::PrepareNavmesh() {

	local sniper_chance = PZI_Bots.NAV_SNIPER_SPOT_FACTOR
	local sentry_chance = PZI_Bots.NAV_SENTRY_SPOT_FACTOR

	function _PrepareNav() {

		yield true

		foreach ( i, nav in PZI_Nav.SafeNavAreas.values() ) {

			if ( !( i % 10 ) )
				yield PZI_Nav.SafeNavAreas.len()

			if ( !(i % sniper_chance) )
				nav.SetAttributeTF( TF_NAV_SNIPER_SPOT )

			else if ( !(i % sentry_chance) )
				nav.SetAttributeTF( TF_NAV_SENTRY_SPOT )

			if ( PZI_Nav.NAV_DEBUG ) {

				local color
				if ( nav.HasAttributeTF( TF_NAV_SNIPER_SPOT ) )
					color = [ 180, 180, 20, 50 ]
				if ( nav.HasAttributeTF( TF_NAV_SENTRY_SPOT ) )
					color = [ 180, 0, 180, 50 ]

				if ( color )
					// DebugDrawCircle( nav.GetCenter() + Vector( 0, 0, 20 ), Vector( color[0], color[1], color[2] ), color[3], 64, false, 15.0 )
					// DebugDrawBox( nav.GetCenter(), nav.GetCorner( SOUTH_EAST ), nav.GetCorner( NORTH_WEST ), color[0], color[1], color[2], color[3], 15.0 )
					nav.DebugDrawFilled( color[0], color[1], color[2], color[3], 15.0, true, 1.0 )

			}
		}
	}

	local gen = _PrepareNav()
	function PZI_Bots::ThinkTable::PrepareNavmeshThink() { 
	
		if ( gen.getstatus() == "dead" )
			return delete this.ThinkTable.PrepareNavmeshThink, 1

		resume gen
		return 0.05
	}
}

function PZI_Bots::GenericZombie( bot, threat_type = "closest" ) {

    local cooldown = 0.0
    local threat_cooldown = 5.0

    function GenericZombieThink() {

        if ( !bot.IsAlive() || bot.GetTeam() != TEAM_ZOMBIE ) 
            return

		else if ( bot.GetFlags() & FL_ATCONTROLS || ( bot.GetActionPoint() && bot.GetActionPoint().IsValid() ) )
			return

		local b = PZI_Util.GetEntScope( bot ).PZI_BotBehavior
		// for some reason bots don't like to move until they're nudged around a bit
		// if we're stuck just throw us around a bit and hope for the best
		if ( bGameStarted && !b.locomotion.IsStuck() && !bot.GetAbsVelocity().Length() )
			bot.ApplyAbsVelocityImpulse( Vector( RandomInt( 30, 60 ), RandomInt( 30, 60 ), RandomInt( 10, 20 ) ) )

        local threat = b.threat

        if ( !threat || !threat.IsValid() || !threat.IsAlive() || threat.GetTeam() == bot.GetTeam() ) {

            if ( threat_type == "closest" && b.time > cooldown ) {

                    b.threat =  b.FindClosestThreat( INT_MAX, false )
                    cooldown = b.time + threat_cooldown // find new threat every threat_cooldown seconds
            }
            else if ( threat_type == "random" ) {

                    local threats = b.CollectThreats( INT_MAX, true, true )
                    if ( !threats.len() ) 
						return
                    b.threat = threats[RandomInt( 0, threats.len() - 1 )]
            }
        }
        else {

            local distance = b.GetThreatDistanceSqr( threat )

			if ( distance > PZI_Bots.MAX_THREAT_DISTANCE )
				b.UpdatePathAndMove( threat.GetOrigin(), false )

			bot.SetAttentionFocus( threat )

		// we haven't taken/dealt any damage in a while, just respawn us if we're too far away from a player
			if ( m_fTimeLastHit + 25.0 < b.time && !b.IsThreatVisible( threat ) && b.GetThreatDistanceSqr( threat ) > 262144.0 )
				PZI_Util.KillPlayer( bot )
            // else
            //     b.LookAt( threat.EyePosition() - Vector( 0, 0, 20 ), 1500, 1500 )
        }
    }

    PZI_Util.AddThink( bot, GenericZombieThink )
}

function PZI_Bots::GenericSpecial( bot ) {

	local b = PZI_Util.GetEntScope( bot ).PZI_BotBehavior

	function GenericSpecialThink() {

		local threat = b.threat

		if ( !threat || !threat.IsValid())
			return
		else if ( !threat.IsAlive() || threat.GetTeam() == bot.GetTeam() )
			return
		else if ( b.GetThreatDistanceSqr( threat ) <= PZI_Bots.MAX_THREAT_DISTANCE * 8 && b.IsThreatVisible( threat ) )
			bot.PressAltFireButton( 1.0 )
	}

	PZI_Util.AddThink( bot, GenericSpecialThink )
}

function PZI_Bots::ScoutZombie( bot ) { bot.SetAutoJump( 0.05, 2 ) }

function PZI_Bots::SoldierZombie( bot ) {

	function SoldierZombieThink( bot ) {

		local buttons = GetPropInt( bot, "m_nButtons" )

		if ( !GetPropEntity( bot, "m_hGroundEntity" ) && buttons & IN_BACK ) {

			SetPropInt( bot, "m_afButtonDisabled", IN_BACK )
			SetPropInt( bot, "m_nButtons", buttons & ~IN_BACK )
			return
		}

		SetPropInt( bot, "m_afButtonDisabled", 0 )
	}
}

function PZI_Bots::MedicZombie( bot ) {

	// heal nearby teammates
    function MedicZombieThink() {

		for (local player; player = FindByClassnameWithin( player, "player", bot.GetOrigin(), MEDIC_HEAL_RANGE );)
			if ( player.GetTeam() == TEAM_ZOMBIE && player.GetHealth() < player.GetMaxHealth() * 0.85 )
				return bot.PressAltFireButton( 1.0 )
    }

	PZI_Util.AddThink( bot, MedicZombieThink )
}

function PZI_Bots::EngineerZombie( bot ) {

	local scope 		= PZI_Util.GetEntScope( bot )
	local b 			= scope.PZI_BotBehavior
	local red_buildings	= PZI_Bots.red_buildings.keys()

	if ( red_buildings.len() )
		b.threat = red_buildings[ RandomInt( 0, red_buildings.len() - 1 ) ]

	b.threat ? bot.SetBehaviorFlag( 511 ) : bot.ClearBehaviorFlag( 511 )

    function EngineerZombieThink() {

		if ( bot.IsBehaviorFlagSet( 511 ) && b.threat && b.threat.IsValid() )
			return

		if ( !red_buildings.len() ) {

			bot.ClearBehaviorFlag( 511 )
			return
		}

		b.threat = red_buildings[ RandomInt( 0, red_buildings.len() - 1 ) ]

		if ( !b.threat || !b.threat.IsValid() )
			red_buildings = red_buildings.filter( @( k, v ) k != null )
	}

	PZI_Util.AddThink( bot, EngineerZombieThink )
	PZI_Bots.GenericSpecial( bot )
}

PZI_EVENT( "teamplay_round_start", "PZI_Bots_TeamplayRoundStart", function( params ) { 

	EntFire( "__pzi_bots", "CallScriptFunction", "PrepareNavmesh" ) 
	SetValue( "tf_bot_ammo_search_range", 0 )
	SetValue( "tf_bot_health_search_far_range", 0 )
	SetValue( "tf_bot_health_search_near_range", 0 )
	SetValue( "tf_bot_sniper_spot_max_count", 50 )
	SetValue( "tf_bot_always_full_reload", 1 )
	SetValue( "tf_bot_flag_escort_max_count", 0 )
	SetValue( "tf_bot_squad_escort_range", INT_MAX )
	SetValue( "tf_bot_flag_escort_range", INT_MAX )
	SetValue( "tf_bot_payload_guard_range", INT_MAX )
	SetValue( "tf_bot_capture_seek_and_destroy_min_duration", INT_MAX )
	SetValue( "tf_bot_capture_seek_and_destroy_max_duration", INT_MAX )
})

PZI_EVENT( "post_inventory_application", "PZI_Bots_PostInventoryApplication", function( params ) {

    local bot = GetPlayerFromUserID( params.userid )

    if ( !IsPlayerABot( bot ) || bot.IsEFlagSet( EFL_IS_BEING_LIFTED_BY_BARNACLE ) )
		return

	if ( bot.GetDifficulty() != EXPERT )
		bot.SetDifficulty( EXPERT )

    local scope = PZI_Util.GetEntScope( bot )
	
	local cls = bot.GetPlayerClass()

    scope.PZI_BotBehavior <- PZI_Bots.PZI_BotBehavior( bot )

	if ( cls == TF_CLASS_MEDIC ) {

		// tf_bot_reevaluate_class_in_spawnroom falls apart with large numbers of bots.
		// 66% chance the medic bots will switch to a random class
		if ( bot.GetTeam() == TEAM_HUMAN && RandomInt( 0, 2 ) )
			return PZI_Util.ForceChangeClass( bot, RandomInt( 1, 9 ) )
		else 
			bot.SetMission( NO_MISSION, true ) 
	}

	else if ( bot.GetTeam() == TEAM_ZOMBIE || cls == TF_CLASS_PYRO || cls == TF_CLASS_SPY )
		bot.SetMission( MISSION_SPY, true )

	else if ( bot.GetTeam() == TEAM_HUMAN ) {

		local sniper_roll = RandomInt( 0, 10 )
		bot.SetMission( cls == TF_CLASS_ENGINEER ? MISSION_ENGINEER : !sniper_roll ? MISSION_SNIPER : MISSION_SPY, true )
		scope.PZI_BotBehavior.GiveRandomLoadout()
	}

	// give bots infinite ammo
	PZI_Util.ScriptEntFireSafe( bot, "self.AddCustomAttribute( `ammo regen`, 9999.0, -1 )" , 0.1 )
	PZI_Util.ScriptEntFireSafe( bot, "self.AddCustomAttribute( `metal regen`, 9999.0, -1 )", 0.1 )

	local b = scope.PZI_BotBehavior

	function BotThink() {

		if ( !bot || !bot.IsValid() || !bot.IsAlive() )
			return

		b.OnUpdate()

		// lazy unstuck behavior, just teleport the bot somewhere safe
		if ( b.locomotion.GetStuckDuration() > 15.0 ) {

			local area = bot.GetLastKnownArea()

			if ( !area ) {

				local areas = {}

				GetNavAreasInRadius( bot.GetOrigin(), 192.0, areas )

				if ( areas.len() )
					area = areas.values()[ RandomInt( 0, areas.len() - 1 ).GetCenter() ]
			}

			// still no nearby nav, just kill and respawn
			if ( !area )
				return PZI_Util.KillPlayer( bot ), 1

			for ( local navdir = 0; navdir < NUM_DIRECTIONS; navdir++ )

				if ( area.GetAdjacentArea( navdir, 1 ) ) {

					bot.SetAbsOrigin( area.GetAdjacentArea( navdir, 1 ).GetCenter() ) 
					b.locomotion.ClearStuckStatus( "Moved to new nav area" )
				}

			// area.MarkAsBlocked( TEAM_ZOMBIE )
		}
	}

	PZI_Util.AddThink( bot, BotThink )

	// if ( bot.GetTeam() != TEAM_ZOMBIE ) {
	// 	 foreach ( func in [ "GenericZombieThink", "GenericSpecialThink", "ScoutZombieThink", "SoldierZombieThink", "MedicZombieThink", "EngineerZombieThink" ] )
	// 		PZI_Util.RemoveThink( bot, func )
	// 	return
	// }

	PZI_Bots.GenericZombie( bot, "closest" )

	local cls = bot.GetPlayerClass()

	if ( cls == TF_CLASS_SCOUT )
		PZI_Bots.ScoutZombie( bot )
	if ( cls == TF_CLASS_SOLDIER )
		PZI_Bots.SoldierZombie( bot )
	else if ( cls == TF_CLASS_MEDIC )
		PZI_Bots.MedicZombie( bot )
	else if ( cls == TF_CLASS_ENGINEER )
		PZI_Bots.EngineerZombie( bot )
	else if ( cls != TF_CLASS_SCOUT && cls != TF_CLASS_HEAVYWEAPONS )
		PZI_Bots.GenericSpecial( bot )
})

PZI_EVENT( "player_builtobject", "PZI_Bots_PlayerBuildObject", function( params ) {

    local building = EntIndexToHScript( params.index )

	if ( !( building in PZI_Bots.red_buildings ) )
		PZI_Bots.red_buildings[building] <- GetPlayerFromUserID( params.userid )
})

// PZI_EVENT( "player_hurt", "PZI_Bots_PlayerHurt", function( params ) {

//     local player = GetPlayerFromUserID( params.userid )

//     if ( !IsPlayerABot( player ) || player.GetHealth() - params.damageamount <= 0 )
// 		return

// 	local attacker = GetPlayerFromUserID( params.attacker )

// 	if ( !attacker || !attacker.IsPlayer() )
// 		return

// 	local scope = player.GetScriptScope()

// 	if ( scope && "PZI_BotBehavior" in scope ) {

// 		local threat = scope.PZI_BotBehavior.threat
// 	}
// })