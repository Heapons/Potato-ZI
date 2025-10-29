PZI_CREATE_SCOPE( "__pzi_bots", "PZI_Bots", "PZI_BotEnt", "PZI_BotGlobalThink" )

PZI_Bots.MAX_BOTS   	  		 <- 50
PZI_Bots.FILL_MODE 				 <- 1 // see tf_bot_quota_mode, 0 1 2 = normal fill match
PZI_Bots.MAX_DOOMED_TIME  		 <- 60.0
PZI_Bots.MIN_KICK_URGENCY 		 <- 2 // min bot diff before we do something beyond REMOVE_ON_DEATH
PZI_Bots.MAX_KICK_URGENCY 		 <- 5 // max bot diff before we go full panic mode and start nuking bots
PZI_Bots.NAV_SNIPER_SPOT_FACTOR  <- 125 // higher value = lower chance.  1/30 chance to be a sniper spot
PZI_Bots.NAV_SENTRY_SPOT_FACTOR  <- 370 // higher value = lower chance.  1/50 chance to be a sentry spot

PZI_Bots.cur_bots   <- null
PZI_Bots.wish_bots  <- 0
PZI_Bots.diff_time  <- 0.0
PZI_Bots.generator  <- null
PZI_Bots.allocating <- false

// bots in this array are scheduled to be kicked
// when they are kicked is handled by PZI_Bots.kick_urgency
PZI_Bots.doomed_bots <- {}

// bots will be scheduled to be kicked when they die to avoid disruptions, but we may want to kick them sooner sometimes
// depending on how large the gap between wish_bots and cur_bots, and how long a gap has been active
// kick urgency will change.  Max urgency means bots get kicked immediately
// regardless of if they can be seen or if they are chasing someone
PZI_Bots.kick_urgency <- 0


PZI_Bots.kick_urgency_funcs <- {

	function step1( bot, b ) {

		// we don't care about humans at low urgency
		if ( bot.GetTeam() == TEAM_HUMAN )
			return false

		// > 1024 hu away from threat, can't see them
		else if ( b.GetCurThreatDistanceSqr() > 0xFFFFF && !b.IsCurThreatVisible() )
			return true
	}

	function step2( bot, b ) {

		// don't kick if we have any players within 1024 hu
		for ( local p; p = FindByClassnameWithin( p, "player", bot.GetOrigin(), 1024 ); )
			return false

		return true
	}

	function step3( bot, b ) {

		// don't kick if we have LOS with any players
		for ( local p; p = FindByClassnameWithin( p, "player", bot.GetOrigin(), 1024 ); )
			if ( b.IsVisible( p ) )
				return false

		return true
	}

	function step4( bot, b ) {

		// kick any bots past their kick time
		if ( doomed_bots[ bot ] + MAX_DOOMED_TIME < Time() )
			return true
	}

	function step5( bot, b ) {

		if ( bot.GetScriptThinkFunc() != "BotRemoveThink" )
			return true
	}
}

// this is incompatible with our new spawner
PZI_Util.ScriptEntFireSafe( "__pzi_bots", "SetValue( `tf_bot_quota`, 0 )", SINGLE_TICK )

PZI_Bots.RandomLoadouts <- {

    [TF_CLASS_SCOUT] = {

		[SLOT_PRIMARY] = [

			"The Soda Popper"
			"The Shortstop"
			"The Force-a-Nature"
		],

		[SLOT_SECONDARY] = [

			"The Winger"
			"Pretty Boy's Pocket Pistol"
			"Mad Milk"
			"Crit-a-Cola"
			"The Flying Guillotine"
		],

		[SLOT_MELEE] = [

			"The Candy Cane"
			"The Fan O'War"
			"The Atomizer"
			"Unarmed Combat"
			"The Holy Mackerel"
		]
	},

    [TF_CLASS_SOLDIER] = {

		[SLOT_PRIMARY] = [

			"The Original"
			"The Liberty Launcher"
			"The Black Box"
			"The Direct Hit"
		],

		[SLOT_SECONDARY] = [

			"Panic Attack Shotgun"
			"The Reserve Shooter"
			"The Buff Banner"
			"The Concheror"
			"The Battalion's Backup"
		],

		[SLOT_MELEE] = [

			"The Disciplinary Action"
			"The Equalizer"
			"The Escape Plan"
			"The Pain Train"
			"The Half-Zatoichi"
		]
	},

	[TF_CLASS_PYRO] = {

		[SLOT_PRIMARY] = [

			"The Backburner"
			"The Degreaser"
			"The Nostromo Napalmer"
			"The Dragon's Fury"
		],

		[SLOT_SECONDARY] = [

			"The Flare Gun"
			"The Scorch Shot"
			"The Detonator"
			"The Manmelter"
			"The Reserve Shooter"
			"Panic Attack Shotgun"
			"The Thermal Thruster"
		],

		[SLOT_MELEE] = [

			"The Third Degree"
			"The Hot Hand"
			"The Back Scratcher"
			"The Homewrecker"
			"The Maul"
			"The Powerjack"
			"The Axtinguisher"
		]
	},

    [TF_CLASS_DEMOMAN] = {

		[SLOT_PRIMARY] = [

			"The Iron Bomber"
			"The Loch-n-Load"
			"Ali Baba's Wee Booties"
			"The Bootlegger"
		],

		[SLOT_SECONDARY] = [

			"The Scottish Resistance"
			"The Quickiebomb Launcher"
			"The Chargin' Targe"
			"The Tide Turner"
			"The Splendid Screen"
		],

		[SLOT_MELEE] = [

			"The Scottish Handshake"
			"The Eyelander"
			"The Scotsman's Skullcutter"
			"The Half-Zatoichi"
			"The Claidheamohmor"
			"The Persian Persuader"
			"The Ullapool Caber"
		]
	},

    [TF_CLASS_HEAVYWEAPONS] = {

		[SLOT_PRIMARY] = [

			"Natascha"
			"Tomislav"
			"The Brass Beast"
			"The Huo Long Heatmaker"
		],

		[SLOT_SECONDARY] = [

			"The Family Business"
			"Panic Attack Shotgun"
			"The Sandvich"
			"Fishcake"
			"The Dalokohs Bar"
			"The Second Banana"
		],

		[SLOT_MELEE] = [

			"The Killing Gloves of Boxing"
			"Gloves of Running Urgently"
			"Gloves of Running Urgently MvM"
			"The Eviction Notice"
			"Fists of Steel"
			"The Holiday Punch"
			"Apoco-Fists"
		]
	},

	[TF_CLASS_ENGINEER] = {

		[SLOT_PRIMARY] = [

			"The Rescue Ranger"
			"The Frontier Justice"
			"The Pomson 6000"
			"The Widowmaker"
			"Panic Attack Shotgun"
		],

		[SLOT_SECONDARY] = [
			"The Short Circuit"
		],

		[SLOT_MELEE] = [

			"The Eureka Effect"
			"The Jag"
			"The Gunslinger"
			"The Southern Hospitality"
		]
	},

	[TF_CLASS_MEDIC] = {

		[SLOT_PRIMARY] = [

			"The Crusader's Crossbow"
			"The Blutsauger"
			"The Overdose"
		],

		[SLOT_SECONDARY] = [

			"The Kritzkrieg"
			"The Quick-Fix"
		],

		[SLOT_MELEE] = [
			"The Amputator"
			"The Ubersaw"
			"The Vita-Saw"
		]
	},

	[TF_CLASS_SNIPER] = {

		[SLOT_PRIMARY] = [

			"The Huntsman"
			"The Fortified Compound"
			"The Sydney Sleeper"
			"The Machina"
			"The Hitman's Heatmaker"
		],

		[SLOT_SECONDARY] = [

			"The Cleaner's Carbine"
			"Jarate"
			"Darwin's Danger Shield"
			"The Cozy Camper"
		],

		[SLOT_MELEE] = [

			"The Bushwacka"
			"The Tribalman's Shiv"
			"The Shahanshah"
		]
	},


	[TF_CLASS_SPY] = {

		[SLOT_PRIMARY] = [

			"The Ambassador"
			"L'Etranger"
			"The Enforcer"
			"The Diamondback"
		],

		[SLOT_MELEE] = [

			"Your Eternal Reward"
			"The Wanga Prick"
			"The Big Earner"
			"Conniver's Kunai"
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

	STR_PROJECTILES 	= "tf_projectile*"
	MAX_RECOMPUTE_TIME  = 3.0
	MAX_THREAT_DISTANCE = 32.0 * 32.0 // use LengthSqr for performance

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
	skip_corners		= null
	path_index			= null
	path_areas			= null
	path_goalpoint      = null
	path_recompute_time	= null

	fire_next_time  	= null
	aim_time        	= null
	random_aim_pos  	= null
	random_aim_time 	= null

	cosmetic 			= null

	path_debug 			= null

	constructor( bot ) {

		// fold PZI_Bots into this class
		// foreach ( k, v in PZI_Bots )
		// 	if ( k != "PZI_BotBehavior" )
		// 		this[ k ] = v

		this.bot         = bot
		this.scope       = bot.GetScriptScope()
		this.team        = bot.GetTeam()
		this.cur_eye_ang = bot.EyeAngles()
		this.cur_eye_pos = bot.EyePosition()
		this.cur_eye_fwd = bot.EyeAngles().Forward()
		this.locomotion  = bot.GetLocomotionInterface()

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

		this.path_debug			 = false
	}

	function GiveRandomLoadout() {

		local botcls = bot.GetPlayerClass()
		local loadouts = scope.RandomLoadouts[ botcls ]

		bot.AddEFlags( EFL_IS_BEING_LIFTED_BY_BARNACLE )

		foreach ( slot, wepinfo in loadouts ) {

			local wepname = wepinfo[ RandomInt( 0, wepinfo.len() - 1 ) ]
			local wep = PZI_ItemMap[ wepname ]

			// tf_wearable-based weapon
			// NOTE: this function is extremely expensive (~4-8ms per call), but it's the easiest way to give demo shields and other wearable weapons
			// some can be re-implemented in a more efficient way, but this only runs once when bots spawn on red on round reset
			// don't need to be equipped *this* frame anyway, punt each equip to a later frame so they don't hitch.
			if ( wep.item_class[0] == 't' && wep.item_class[6] == 'r' )
				PZI_Util.ScriptEntFireSafe( bot, "self.GenerateAndWearItem( `"+wepname+"` )", slot * 0.1 )

			else {

				local cls = wep.item_class

				if ( typeof cls == "array" )
					cls = wep.item_class[ wep.animset.find( PZI_Util.Classes[ botcls ] ) ]

				local wep_ent = PZI_Util.GiveWeapon( bot, cls, wep.id )

				// heavy lunchbox, heavy bots will eat forever if we don't do something
				// this means low HP bots can potentially hp drain and die but whatever
				if ( cls[10] == 'l' && wep.animset[0] == 'h' )
					wep_ent.AddAttribute( "active health degen", -2.0, -1.0 )

				PZI_Util.KillOnDeath( bot, wep_ent )
			}
		}

		PZI_Util.ScriptEntFireSafe( "__pzi_util", @"

			if ( !activator || !activator.IsValid() )
				return

			SwitchToFirstValidWeapon( activator )

			ForEachItem( activator, @( item ) KillOnDeath( activator, item ) )

			activator.RemoveEFlags( EFL_IS_BEING_LIFTED_BY_BARNACLE )

		", 12.0, bot )
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
			start  = bot.EyePosition()
			end    = target.EyePosition()
			mask   = MASK_OPAQUE
			ignore = bot
		}
		TraceLineEx( trace )
		return !trace.hit
	}

	function IsThreatVisible( target ) 		{ return threat_visible = ( IsInFieldOfView( target ) && IsVisible( target ) ), threat_visible }

	function GetThreatDistance( target ) 	{ return ( ( target.GetOrigin() || Vector() ) - bot.GetOrigin() ).Length() }

    function GetThreatDistance2D( target ) 	{ return ( ( target.GetOrigin() || Vector() ) - bot.GetOrigin() ).Length2D() }

	function GetThreatDistanceSqr( target ) { return ( ( target.GetOrigin() || Vector() ) - bot.GetOrigin() ).LengthSqr() }

	function IsCurThreatVisible() 			{ return threat_visible = ( IsInFieldOfView( threat ) && IsVisible( threat ) ), threat_visible }

	function GetCurThreatDistance() 		{ return ( ( threat_pos || Vector() ) - cur_pos ).Length() }

	function GetCurThreatDistanceSqr() 		{ return ( ( threat_pos || Vector() ) - cur_pos ).LengthSqr() }

	function GetCurThreatDistanceSqr2D() 	{ return ( ( threat_pos || Vector() ) - cur_pos ).Length2DSqr() }

	function FindClosestThreat( min_dist, must_be_visible = true ) {

		local closest_threat = null
		local closest_threat_dist = min_dist

		foreach ( player in PZI_Util.PlayerArray ) {

			if ( !player || !player.IsValid() )
				continue

			else if ( !player.IsAlive() || player.GetTeam() == bot.GetTeam() || ( must_be_visible && !IsThreatVisible( player ) ) )
				continue

			local dist = GetThreatDistanceSqr( player )

			if ( dist < closest_threat_dist ) {

				closest_threat = player
				closest_threat_dist = dist
			}
		}
		if ( closest_threat && path_debug )
			DebugDrawLine( bot.GetOrigin(), closest_threat.GetOrigin(), 255, 0, 0, false, 5.0 )

		return closest_threat
	}

	function CollectThreats( maxdist = INT_MAX, disguised = false, invisible = false, alive = true ) {

		local threatarray = []
		foreach ( player in PZI_Util.PlayerArray ) {

			if ( !player || !player.IsValid() )
				continue

			else if ( player.GetTeam() == bot.GetTeam() || GetThreatDistanceSqr( player ) > maxdist || ( alive && !player.IsAlive() ) )
				continue

			else if ( ( !invisible && player.IsFullyInvisible() ) || ( !disguised && player.IsStealthed() ) )
				continue

			threatarray.append( player )
		}
		return threatarray
	}

	function SetThreat( target, visible = true ) {

		if ( !target || !target.IsValid() )
			return threat = null

		threat 			   = target
		threat_pos 		   = ( threat || PZI_Util.Worldspawn ).GetOrigin()
		threat_visible 	   = visible
		threat_time 	   = time
		threat_behind_time = time + 0.5
	}

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

	// //260 Hammer Units or 67700 SQR
	// function FireWeapon() {

	// 	if ( cur_melee ) {
	// 		if ( threat ) {
	// 			threat_dist = GetThreatDistanceSqr( threat )
	// 			if ( threat_dist < 16384.0 ) // 128
	// 				bot.PressFireButton( 0.2 )
	// 		}

	// 		return true
	// 	}

	// 	if ( fire_next_time > time ) {
	// 		bot.AddBotAttribute( IGNORE_ENEMIES )
	// 		bot.PressFireButton()
	// 		bot.RemoveBotAttribute( IGNORE_ENEMIES )
	// 		return false
	// 	}

	// 	if ( !cur_ammo )
	// 		return false

	// 	local duration     = 0.11
	// 	local velocity_max = 50.0

	// 	if ( 1 )
	// 		if ( cur_vel.Length() < velocity_max )
	// 			bot.PressFireButton( duration )
	// 	else
	// 		fire_next_time = time + RandomFloat( 0.3, 0.6 )

	// 	return true
	// }

	// function StartAimWithWeapon() {

	// 	if ( aim_time != FLT_MAX )
	// 		return

	// 	bot.PressAltFireButton( INT_MAX )
	// 	aim_time = time
	// }

	// function EndAimWithWeapon() {

	// 	if ( aim_time == FLT_MAX )
	// 		return

	// 	bot.AddBotAttribute( SUPPRESS_FIRE )
	// 	bot.PressAltFireButton( 0.5 )
	// 	bot.RemoveBotAttribute( SUPPRESS_FIRE )
	// 	aim_time = FLT_MAX
	// }

	function OnTakeDamage( attacker ) {

		if ( time - threat_time < 3.0 )
			return

		if ( attacker != bot && GetCurThreatDistanceSqr() > GetThreatDistanceSqr( attacker ) )
			SetThreat( attacker )
	}

	function OnUpdate() {

		cur_pos     = bot.GetOrigin()
		cur_vel     = bot.GetAbsVelocity()
		cur_speed   = cur_vel.LengthSqr()
		cur_eye_pos = bot.EyePosition()
		cur_eye_ang = bot.EyeAngles()
		cur_eye_fwd = cur_eye_ang.Forward()
		time = Time()

		if ( !threat || !threat.IsValid() )
			return threat = null, threat_pos = Vector()

		threat_pos  = threat.GetOrigin()

		return -1
	}

	function FindPathToThreat() {

		if ( path_recompute_time > time )
			return

		if ( ( !path_points.len() ) || GetCurThreatDistanceSqr2D() > MAX_THREAT_DISTANCE ) {

			local area = GetNavArea( threat_pos, 0.0 )
			if ( area )
				UpdatePath( threat_pos, true )
		}
	}

	function ResetPath() {

		path_areas.clear()
		path_points.clear()
		path_index = null
		path_recompute_time = 0
	}

	function UpdatePath( target_pos, no_corners = false, move = false, lookat = false ) {

		local dist_to_target = ( target_pos - bot.GetOrigin() ).LengthSqr()
        local path_count = path_points.len()

		skip_corners = no_corners

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

				local to_c1, to_c2, fr_c1, fr_c2
				for ( local i = 0; i < path_count; i++ ) {

					if ( !( i in path_points) || !(i + 1 in path_points) )
						continue


					local path_from = path_points[i]
					local path_to = ( i < path_count - 1 ) ? path_points[i + 1] : null

					if ( path_to ) {

						local dir_to_from = path_to.area.ComputeDirection( path_from.area.GetCenter() )
						local dir_from_to = path_from.area.ComputeDirection( path_to.area.GetCenter() )

						to_c1 = path_to.area.GetCorner( dir_to_from )
						to_c2 = path_to.area.GetCorner( dir_to_from + 1 )
						fr_c1 = path_from.area.GetCorner( dir_from_to )
						fr_c2 = path_from.area.GetCorner( dir_from_to + 1 )

						local minarea = {}
						local maxarea = {}

						if ( ( to_c1 - to_c2 ).LengthSqr() < ( fr_c1 - fr_c2 ).LengthSqr() ) {

							minarea.area <- path_to.area
							maxarea.area <- path_from.area

							if ( !skip_corners ) {

								minarea.c1 <- to_c1
								minarea.c2 <- to_c2

								maxarea.c1 <- fr_c1
								maxarea.c2 <- fr_c2
							}
						}
						else {

							minarea.area <- path_from.area
							maxarea.area <- path_to.area

							if ( !skip_corners ) {

								minarea.c1 <- fr_c1
								minarea.c2 <- fr_c2

								maxarea.c1 <- to_c1
								maxarea.c2 <- to_c2
							}
						}

						// Get center of smaller area's edge between the two
						local vec = minarea.area.GetCenter()

						// don't do any corner shortcuts and follow the strict path
						if ( !skip_corners ) {

							if ( !dir_to_from || dir_to_from == 2 ) { // GO_NORTH, GO_SOUTH
								vec.y = minarea.c1.y
								vec.z = minarea.c1.z
							}
							else if ( dir_to_from == 1 || dir_to_from == 3 ) { // GO_EAST, GO_WEST
								vec.x = minarea.c1.x
								vec.z = minarea.c1.z
							}
						}
						path_from.pos = vec
					}
				}
			}

			// Base recompute off distance to target
			// Every 500hu away increase our recompute time by 0.1s
			local path_recompute_mod = 0.1 * ( dist_to_target / 250000 ) // 500^2 = 250000

			path_recompute_time = time + ( path_recompute_mod > MAX_RECOMPUTE_TIME ? MAX_RECOMPUTE_TIME : path_recompute_mod )
		}

		if ( path_index == null || !(path_index in path_points) )
			path_index = path_points.len() - 1

		if ( path_index == -1 || ( path_points[path_index].pos - bot.GetOrigin() ).LengthSqr() < MAX_THREAT_DISTANCE ) {

			path_index++

			// printf( "path_index: %d path_count: %d dist_to_target: %f\n", path_index, path_count, dist_to_target )
			if ( path_index >= path_count ) {

				ResetPath()
				return
			}
		}

		if ( path_debug ) {

			for ( local i = 0; i < path_count; i++ ) {
				if ( i in path_points && path_debug )
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

		if ( move )
			MoveToThreat( lookat )
	}

	function MoveToThreat( lookat = true, turnrate_min = 600, turnrate_max = 1500 ) {

		// if ( !(path_index in path_points) )
		// 	__DumpScope( 0, path_points )

		// we're underwater and can see our target, just move directly at them
		if ( bot.GetWaterLevel() >= 2 && IsVisible( threat ) ) {

			locomotion.Approach( threat_pos, 0.0 )
			locomotion.FaceTowards( threat_pos )
			return
		}

		if ( path_index == null || !( path_index in path_points ) )
			return UpdatePath( threat_pos, true )

		local point = path_points[0].pos

		if ( bot.GetLastKnownArea() == GetNearestNavArea( point, MAX_THREAT_DISTANCE, false, false ) )
			return path_points.remove( 0 ), path_index ? path_index-- : path_index

		locomotion.Approach( point, 0.0 )
		// locomotion.DriveTo( point )
		locomotion.FaceTowards( point )

		local look_pos = Vector( point.x, point.y, cur_eye_pos.z )

		if ( lookat )
			LookAt( look_pos, turnrate_min, turnrate_max )
		
		if ( path_debug ) {

			DebugDrawLine( bot.GetOrigin(), point, 255, 100, 0, false, 0.1 )

			local area_count = path_areas.len()

			local i = 0
			foreach( area in path_areas ) {
				i++
				local x = ( ( area_count - i - 0.0 ) / area_count ) * 255.0
				area.DebugDrawFilled( x, (x / 2), 0, 50, 0.075, true, 0.0 )
			}
		}
	}
}

function PZI_Bots::ShouldKickBot( bot ) {

	if ( !bot || !bot.IsValid() )
		return false

	if ( !bGameStarted )
		return true

	local scope = bot.GetScriptScope()

	if ( !( "PZI_BotBehavior" in scope ) )
		return true

	local b = scope.PZI_BotBehavior

	// kick urgency too low
	// or we're already about to be kicked
	if ( kick_urgency < MIN_KICK_URGENCY || bot.GetScriptThinkFunc() == "BotRemoveThink" )
		return false

	// we have a step in the kick urgency functions
	// step through all of ones we should run
	// this falls through to kick_urgency >= MAX_KICK_URGENCY if no kick_urgency_funcs return true
	else if ( ("step" + kick_urgency) in kick_urgency_funcs )
		for ( local i = 1; i <= kick_urgency; i++ )
			if ( kick_urgency_funcs[ "step" + i ]( bot, b ) )
				return true

	// else if ( doomed_bots.len() && bot in doomed_bots && doomed_bots[ bot ] + MAX_DOOMED_TIME < Time() )
	// 	return true

	return kick_urgency >= MAX_KICK_URGENCY
}

function PZI_Bots::BotRemoveThink() {

	if ( !self.HasBotAttribute( REMOVE_ON_DEATH ) )
		self.AddBotAttribute( REMOVE_ON_DEATH )

	else if ( self.IsAlive() ) {

		self.AddEFlags( EFL_IS_BEING_LIFTED_BY_BARNACLE )
		PZI_Util.SetNextRespawnTime( self, INT_MAX )
		PZI_Util.KillPlayer( self )
		self.SetTeam( TEAM_SPECTATOR )
		EntFire( "tf_ammo_pack", "Kill" )
	}
	return 1.0
}

function PZI_Bots::ThinkTable::BotQuotaManager() {

	// don't run any quota logic while we're actively spawning/removing bots
	// wait a bit for the map/nav to finish loading
	if ( allocating || "PopulateSafeNav" in PZI_Nav.ThinkTable )
		return

	PZI_Util.ValidatePlayerTables()
	local bots   = PZI_Util.BotArray
	local humans = PZI_Util.HumanArray
	local cur_bots = bots.len() - doomed_bots.len()

	if ( ( !generator || !generator.IsValid() ) )
		return AllocateBots()

	// check fill mode for how many bots we want
	else if ( FILL_MODE )
		wish_bots = FILL_MODE == 2 ? PZI_Util.Max( 0, MAX_BOTS * humans.len() ) : MAX_BOTS - humans.len()

	// printf( "wish: %d cur: %d urgency: (%d) doomed: [%d]\n", wish_bots, PZI_Util.BotArray.len(), kick_urgency, doomed_bots.len() )
	// kick urgency is decided by the difference between how many bots we want and how many we currently have
	// always kick at max urgency in pre-round
	kick_urgency = bGameStarted ? PZI_Util.Min( abs( wish_bots - cur_bots ), MAX_KICK_URGENCY ) : MAX_KICK_URGENCY

	// check if we need more/less bots for our fill mode
	local cmp = wish_bots <=> cur_bots

	// we have the correct amount already
	if ( !cmp ) return

	// we have bots queued to be kicked already, take care of these first
	if ( doomed_bots.len() ) {

		// kick a bot and check again next think
		foreach ( _bot in doomed_bots.keys() ) {

			// local kick = ShouldKickBot( kickme ) 
			// printl( kickme + " : " + kick )
			if ( !ShouldKickBot( _bot ) )
				continue

			local scope = _bot.GetScriptScope()
			scope.BotRemoveThink <- BotRemoveThink.bindenv( scope )
			AddThinkToEnt( _bot, "BotRemoveThink" )
		}

		doomed_bots = doomed_bots.filter( @( _b, _ ) _b && _b.IsValid() )

		return
	}

	// too many bots, schedule one for removal
	if ( cmp == -1 ) {

		local rnd = bots[ RandomInt( 0, cur_bots - 1 ) ]

		local tries = -1

		if ( !rnd || !rnd.IsValid() )
			return PZI_Util.ValidatePlayerTables()

		// already dead or doomed, find another
		while ( tries++, ( rnd in doomed_bots || !rnd.IsAlive() ) && tries < kick_urgency )
			rnd = bots[ RandomInt( 0, cur_bots - 1 ) ]

		rnd.AddBotAttribute( REMOVE_ON_DEATH )
		PZI_Util.SetNextRespawnTime( rnd, INT_MAX )

		doomed_bots[ rnd ] <- Time()
	}

	// not enough bots, add another
	else if ( cmp ) {

		// local node = CreateByClassname( "point_commentary_node" )
		// DispatchSpawn( node )
		// EntFire( "point_commentary_node", "Kill", null, 1.1 )
		generator.AcceptInput( "SpawnBot", null, null, null )
	}

}

function PZI_Bots::AllocateBots( count = PZI_Bots.MAX_BOTS ) {

	// hide bot join messages in chat
	// local node = CreateByClassname( "point_commentary_node" )
	// DispatchSpawn( node )
	// EntFire( "point_commentary_node", "Kill", null, 7 )

	PZI_Util.ValidatePlayerTables()

	if ( PZI_Util.BotArray.len() >= MAX_BOTS )
		return

	// TODO
	// re-running scripts will cause BotArray to get reset back to 0
	// this will cause stacking bot generators that completely break quota logic.
	// fix that instead of manually re-iterating players here!
	local j = 0
	for ( local i = 1; i <= MAX_CLIENTS; i++ )
		if ( PlayerInstanceFromIndex(i) )
			j++

	if ( j >= MAX_BOTS )
		return

	local max = count - PZI_Util.BotArray.len()

	if ( max <= 0 )
		return

	else if ( max > MAX_BOTS )
		return

	else if ( FILL_MODE )
		max = FILL_MODE == 2 ? PZI_Util.Max( 0, MAX_BOTS * PZI_Util.HumanArray.len() ) : max - PZI_Util.HumanArray.len()

	generator = CreateByClassname( "bot_generator" )
	generator.KeyValueFromString( "targetname", "__pzi_bot_generator_" + generator.entindex() )
	generator.KeyValueFromInt( "spawnOnlyWhenTriggered", 1 )
	generator.KeyValueFromInt( "actionOnDeath", 0 )
	generator.KeyValueFromInt( "useTeamSpawnPoint", 0 )
	generator.KeyValueFromInt( "maxActive", INT_MAX )
	generator.KeyValueFromInt( "count", INT_MAX )
	generator.KeyValueFromInt( "difficulty", EXPERT )
	generator.KeyValueFromInt( "disableDodge", 1 )
	generator.KeyValueFromFloat( "interval", SINGLE_TICK ) //this keyvalue is weird, just control the spawning manually
	generator.KeyValueFromString( "team", "red" )
	generator.KeyValueFromString( "class", "medic" ) // we handle bot classes in a game event callback elsewhere
	DispatchSpawn( generator )
	SetPropString( generator, "m_iClassname", "entity_saucer" )

	PZI_Util.SetDestroyCallback( generator, function() {

		self.AcceptInput( "RemoveBots", null, null, null )

		foreach( bot in PZI_Util.BotArray ) {

			doomed_bots[ bot ] <- 0.0
			local scope = bot.GetScriptScope()
			scope.BotRemoveThink <- BotRemoveThink.bindenv( scope )
			AddThinkToEnt( bot, "BotRemoveThink" )
		}
	})

	local i = -1, inc = 0.0
	while ( i++, inc = i * 0.05, i < max ) {

		EntFireByHandle( generator, "RunScriptCode", @"

			self.SetAbsOrigin( PZI_Nav.GetRandomSafeArea().GetCenter() + Vector(0, 0, 20) )
			self.AcceptInput( `SpawnBot`, null, null, null )

		", inc + 5.0, null, null )
	}

	return generator
}

function PZI_Bots::PrepareNavmesh() {

	local sniper_chance = NAV_SNIPER_SPOT_FACTOR
	local sentry_chance = NAV_SENTRY_SPOT_FACTOR

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

    function GenericZombieThink() {

        if ( !bot.IsAlive() || bot.GetTeam() != TEAM_ZOMBIE )
            return

		else if ( bot.GetFlags() & FL_ATCONTROLS || ( bot.GetActionPoint() && bot.GetActionPoint().IsValid() ) )
			return

		local b = PZI_Util.GetEntScope( bot ).PZI_BotBehavior

        local threat = b.threat

        if ( !threat || !threat.IsValid() || !threat.IsAlive() || threat.GetTeam() == bot.GetTeam() ) {

            if ( threat_type == "closest" ) {

                    b.SetThreat( b.FindClosestThreat( INT_MAX, false ), true )
            }
            else if ( threat_type == "random" ) {

                    local threats = b.CollectThreats( INT_MAX, true, true )

                    if ( !threats.len() ) return

                    b.SetThreat( threats[RandomInt( 0, threats.len() - 1 )] )
            }
        }
        else {

			if ( !b.threat_pos )
				return

			b.FindPathToThreat()
			b.MoveToThreat()

			if ( b.GetCurThreatDistanceSqr() > 1048576.0 ) { // 1024^2

				bot.AddCondEx( TF_COND_SPEED_BOOST, 1.0, bot )

				// we haven't taken/dealt any damage in a while, just respawn us if we're too far away from a player
				if ( m_fTimeLastHit && m_fTimeLastHit + 25.0 < b.time && !b.IsCurThreatVisible() ) {

					PZI_Util.SetNextRespawnTime( bot, 1.0 )
					PZI_Util.KillPlayer( bot )
					m_fTimeLastHit = INT_MAX
				}

			}
            else {

				bot.SetAttentionFocus( threat )
				b.LookAt( threat.EyePosition() - Vector( 0, 0, 20 ), 1500, 1500 )
				bot.PressFireButton( 5.0 )
			}
        }
    }

    PZI_Util.AddThink( bot, GenericZombieThink )
}

function PZI_Bots::GenericSpecial( bot ) {

	local b = PZI_Util.GetEntScope( bot ).PZI_BotBehavior

	function GenericSpecialThink() {

		local threat = b.threat

		if ( !threat || !threat.IsValid() )
			return

		else if ( !threat.IsAlive() || threat.GetTeam() == bot.GetTeam() )
			return

		else if ( b.GetCurThreatDistanceSqr() <= b.MAX_THREAT_DISTANCE * 8 && b.IsCurThreatVisible() )
			bot.PressAltFireButton( 1.0 )
	}

	PZI_Util.AddThink( bot, GenericSpecialThink )
}

// doesn't work?
function PZI_Bots::ScoutZombie( bot ) { bot.SetAutoJump( 0.05, 2 ) }

function PZI_Bots::SoldierZombie( bot ) {

	function SoldierZombieThink() {

		local buttons = GetPropInt( bot, "m_nButtons" )

		if ( !GetPropEntity( bot, "m_hGroundEntity" ) && buttons & IN_BACK ) {

			SetPropInt( bot, "m_afButtonDisabled", IN_BACK )
			SetPropInt( bot, "m_nButtons", buttons & ~IN_BACK )
			return
		}
		SetPropInt( bot, "m_afButtonDisabled", 0 )
	}

	GenericSpecial( bot )
	PZI_Util.AddThink( bot, SoldierZombieThink )
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
	local red_buildings	= red_buildings.keys()

	if ( red_buildings.len() )
		b.SetThreat( red_buildings[ RandomInt( 0, red_buildings.len() - 1 ) ] )

	bot[ b.threat ? "SetBehaviorFlag" : "ClearBehaviorFlag" ]( 511 )

    function EngineerZombieThink() {

		if ( bot.IsBehaviorFlagSet( 511 ) && b.threat && b.threat.IsValid() )
			return

		if ( !red_buildings.len() ) {

			bot.ClearBehaviorFlag( 511 )
			return
		}

		b.SetThreat( red_buildings[ RandomInt( 0, red_buildings.len() - 1 ) ] )

		if ( !b.threat || !b.threat.IsValid() )
			red_buildings = red_buildings.filter( @( k, v ) k && k instanceof CBaseEntity && k.IsValid() )
	}

	PZI_Util.AddThink( bot, EngineerZombieThink )
	GenericSpecial( bot )
}

PZI_EVENT( "teamplay_round_start", "PZI_Bots_TeamplayRoundStart", function( params ) {

	EntFire( "__pzi_bots", "CallScriptFunction", "PrepareNavmesh" )

	// payload
	SetValue( "tf_bot_escort_range", INT_MAX)
	SetValue( "tf_escort_recede_time", INT_MAX )
	SetValue( "tf_bot_cart_push_radius", INT_MAX )
	SetValue( "tf_bot_payload_guard_range", INT_MAX )
	SetValue( "tf_escort_recede_time_overtime", INT_MAX )

	// cp
	SetValue( "tf_bot_max_point_defend_range", INT_MAX )
	SetValue( "tf_bot_defense_must_defend_time", 1.0 )
	SetValue( "tf_bot_defend_owned_point_percent", 1.0 )

	// ctf
	SetValue( "tf_bot_flag_escort_range", INT_MAX )
	SetValue( "tf_bot_fetch_lost_flag_time", INT_MAX)
	SetValue( "tf_bot_flag_escort_max_count", 0 )
	SetValue( "tf_bot_flag_escort_give_up_range", 1 )
	SetValue( "tf_bot_capture_seek_and_destroy_min_duration", INT_MAX )
	SetValue( "tf_bot_capture_seek_and_destroy_max_duration", INT_MAX )

	// demo
	SetValue( "tf_bot_stickybomb_density", 0.1 )

	// medic
	SetValue( "tf_bot_medic_max_call_response_range", INT_MAX )

	// sniper
	SetValue( "tf_bot_sniper_spot_max_count", MAX_CLIENTS )
	SetValue( "tf_bot_min_setup_gate_sniper_defend_range", INT_MAX )

	// engineer
	SetValue( "tf_bot_min_teleport_travel", 1024.0 )
	SetValue( "tf_bot_max_teleport_entrance_travel", INT_MAX )
	SetValue( "tf_bot_engineer_exit_near_sentry_range", INT_MAX )
	SetValue( "tf_bot_engineer_max_sentry_travel_distance_to_point", INT_MAX )


	// disable pack pickup behavior
	SetValue( "tf_bot_ammo_search_range", 1 )
	// SetValue( "tf_bot_health_ok_ratio", 0.0 )
	// SetValue( "tf_bot_health_critical_ratio", 0.0 )
	// SetValue( "tf_bot_health_search_far_range", 1 )
	// SetValue( "tf_bot_health_search_near_range", 1 )

	// misc
	SetValue( "tf_bot_always_full_reload", 1 )
	SetValue( "tf_bot_squad_escort_range", INT_MAX )
	SetValue( "tf_bot_offense_must_push_time", 0.0 )
	SetValue( "tf_bot_melee_attack_abandon_range", 64.0 )
	SetValue( "tf_bot_min_setup_gate_defend_range", 0.0 )
	SetValue( "tf_bot_max_setup_gate_defend_range", INT_MAX )
	SetValue( "tf_bot_reevaluate_class_in_spawnroom", 0 )

	SetValue( "nb_update_frequency", 1.0 )
})

PZI_EVENT( "player_spawn", "PZI_Bots_PostInventoryApplication", function( params ) {

    local bot = GetPlayerFromUserID( params.userid )

    if ( !IsPlayerABot( bot ) || bot.IsEFlagSet( EFL_IS_BEING_LIFTED_BY_BARNACLE ) )
		return

	if ( bot.GetDifficulty() != EXPERT )
		bot.SetDifficulty( EXPERT )

    local scope = PZI_Util.GetEntScope( bot )

	// fold PZI_Bots into the bot's scope
	foreach( k, v in PZI_Bots )
		if ( !( k in scope ) && k != "PZI_BotBehavior" )
			scope[ k ] <- v

	if ( !( "PZI_BotBehavior" in scope ) )
		scope.PZI_BotBehavior <- PZI_Bots.PZI_BotBehavior( bot )

	local cls = bot.GetPlayerClass()

	scope.m_fTimeLastHit <- Time()
	bot.RemoveOutOfCombat()

	if ( cls == TF_CLASS_MEDIC ) {

		// tf_bot_reevaluate_class_in_spawnroom falls apart with large numbers of bots.
		// 66% chance the medic bots will switch to a random class
		if ( bot.GetTeam() == TEAM_HUMAN && RandomInt( 0, 2 ) )
			PZI_Util.ForceChangeClass( bot, RandomInt( 1, 9 ) )
		else
			bot.SetMission( NO_MISSION, true )
	}

	// kill bots with a random delay
	// this staggers the bots internal thinks
	// causing less hitching/performance spikes
	if ( !bGameStarted && !("__pzi_firstkill" in scope) && bot.GetTeam() == TEAM_HUMAN ) {

		scope.__pzi_firstkill <- true
		PZI_Util.ScriptEntFireSafe( bot, "PZI_Util.KillPlayer( self )", RandomFloat( 0.2, 1.6 ) )
	}

	else if ( bot.GetTeam() == TEAM_ZOMBIE || cls == TF_CLASS_PYRO || cls == TF_CLASS_SPY )
		bot.SetMission( MISSION_SPY, true )

	else if ( bot.GetTeam() == TEAM_HUMAN ) {

		// non engineers/medics have a rare chance to use sniper AI
		// (periodically right click and melee when enemies are close)
		local mission = NO_MISSION

		if ( cls == TF_CLASS_ENGINEER || cls == TF_CLASS_SPY )
			mission = cls == TF_CLASS_ENGINEER ? MISSION_ENGINEER : MISSION_SPY
		else if ( !RandomInt( 0, 10 ) )
			mission = MISSION_SNIPER

		bot.SetMission( mission, true )

		// scope.PZI_BotBehavior.GiveRandomLoadout()
		PZI_Util.ScriptEntFireSafe( bot, " if ( self.GetTeam() == TEAM_HUMAN ) PZI_BotBehavior.GiveRandomLoadout()", 5.0 )
	}

	// give bots infinite ammo
	PZI_Util.ScriptEntFireSafe( bot, "self.AddCustomAttribute( `ammo regen`, 9999.0, -1 )" , 1.0 )
	PZI_Util.ScriptEntFireSafe( bot, "self.AddCustomAttribute( `metal regen`, 9999.0, -1 )", 1.0 )

	local b = scope.PZI_BotBehavior

	function BotThink() {

		if ( !bot || !bot.IsValid() || !bot.IsAlive() )
			return

		b.OnUpdate()

		// lazy unstuck behavior, just teleport the bot somewhere safe

		local stucktime = b.locomotion.GetStuckDuration()

		if ( stucktime > 5.0 ) {

			local area = bot.GetLastKnownArea() || GetNearestNavArea( bot.GetOrigin(), 192.0, false, false )

			if ( b.path_debug ) {

				SetPropBool( bot, "m_bGlowEnabled", !!stucktime )
				printf( "bot %s STUCK!\n pos: %s\n stuck time: %.2f\n last known area: '%s'\n", bot.tostring(), bot.GetOrigin().ToKVString(), stucktime, ""+area )
			}

			// no nearby nav, just kill and respawn
			if ( !area )
				PZI_Util.KillPlayer( bot )

			else {

				for ( local navdir = 0; navdir < NUM_DIRECTIONS; navdir++ ) {

					local new_area = area.GetRandomAdjacentArea( navdir )

					if ( !new_area || PZI_Nav.SafeNavAreas.values().find( new_area ) == null )
						continue

					local center = new_area.GetCenter()

					if ( b.path_debug )
						new_area.DebugDrawFilled( 255, 255, 0, 50, 2.0, true, 0.0 )
					
					printl( ( center - b.cur_pos ).LengthSqr() )

					// 256 hu^2 
					if ( ( center - b.cur_pos ).LengthSqr() <= 65535.0 ) {

						if ( b.path_debug ) {
							
							printf( "bot %s moved to '%s'\n", bot.tostring(), center.ToKVString() )
							bot.SetAbsOrigin( center + Vector( 0, 0, 20 ) )
						}
							new_area.DebugDrawFilled( 255, 0, 255, 80, 5.0, true, 0.0 )

						b.locomotion.ClearStuckStatus( "Moved to new nav area" )
						b.UpdatePath( b.threat_pos, true )
						break
					}
				}
			}
			// area.MarkAsBlocked( TEAM_ZOMBIE )
		}
	}

	PZI_Util.AddThink( bot, BotThink )

	local thinkname = ""
	foreach ( name, func in PZI_Bots )
		if ( thinkname = name+"Think", thinkname != "BotRemoveThink" && thinkname in scope.ThinkTable )
			PZI_Util.RemoveThink( bot, thinkname )

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

	if ( cls != TF_CLASS_MEDIC )
		PZI_Bots.GenericZombie( bot, "closest" )
})

PZI_EVENT( "player_builtobject", "PZI_Bots_PlayerBuildObject", function( params ) {

    local building = EntIndexToHScript( params.index )

	if ( !( building in PZI_Bots.red_buildings ) )
		PZI_Bots.red_buildings[building] <- GetPlayerFromUserID( params.userid )
})

PZI_EVENT( "player_death", "PZI_Bots_PlayerDeath", function( params ) {

	local bot = GetPlayerFromUserID( params.userid )

	if ( !IsPlayerABot( bot ) )
		return
	if ( bot.HasBotAttribute( REMOVE_ON_DEATH ) )
		if ( bot in PZI_Bots.doomed_bots )
			return ( delete PZI_Bots.doomed_bots[ bot ] )
		else
			return

	local scope = bot.GetScriptScope()

	if ( !scope || !("PZI_BotBehavior" in scope) )
		return

	scope.PZI_BotBehavior.threat = null

})

PZI_EVENT( "player_hurt", "PZI_Bots_PlayerHurt", function( params ) {

    local player = GetPlayerFromUserID( params.userid )

    if ( !IsPlayerABot( player ) || player.GetHealth() - params.damageamount <= 0 )
		return

	local attacker = GetPlayerFromUserID( params.attacker )

	if ( !attacker || !attacker.IsValid() || !attacker.IsPlayer() )
		return

	local scope = player.GetScriptScope()

	if ( scope && "PZI_BotBehavior" in scope ) {

		local b = scope.PZI_BotBehavior

		b.OnTakeDamage( attacker )
	}
})