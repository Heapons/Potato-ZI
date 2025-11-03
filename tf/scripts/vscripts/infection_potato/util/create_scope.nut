
/*********************************************************************************************
 * Namespacing wrapper for creating self-contained extension/module scopes.			         *
 * All code is scoped to an entity to allow for easier cleanup.  Code is killed with the ent *
 * - name: Targetname of the entity.  "pzi" in the name is recommended for consistency	     *
 * - namespace: Root table reference to the scope.                                           *
 * - entity_ref: Root table reference to the entity.                                         *
 * - think_func: Create a think function for this entity/scope, depending on argument type.  *
 * 	  - String: Create a new think function that iterates over a 'ThinkTable' table.		 *
 * 	  - Function: Does NOT create 'ThinkTable', sets the think function directly.			 *
 * - classname: overrides the spawned entity classname to something else                     *
 *********************************************************************************************/

// EXAMPLE USAGE:

/*****************************************************************************************************
 * // Place this at the top of your file                                                             *
 *                                                                                                   *
 * PZI_CREATE_SCOPE( "__pzi_myextension", "MyExtension", "MyExtensionEntity", "MyExtensionThink" )   *
 *****************************************************************************************************
 * Rest of your extension code goes below here                                                       *
 *****************************************************************************************************
 *                                                                                                   *
 * // create a function scoped to our extension                                                      *
 * function MyExtension::MyFunction() {                                                              *
 *                                                                                                   *
 *     __DumpScope( 0, this )                                                                        *
 * }                                                                                                 *
 * MyExtension.MyFunction()                                                                          *
 *                                                                                                   *
 * // add a think function scoped to our extension that iterates all players.  Runs automatically    *
 * function MyExtension::ThinkTable::IterateAllPlayers() {                                           *
 *                                                                                                   *
 *     for ( local i = 1, player; i <= MAX_CLIENTS; i++ )                                            *
 *         if ( player = PlayerInstanceFromIndex( i ) )                                              *
 *             printl( player )                                                                      *
 * }                                                                                                 *
 *                                                                                                   *
 * // _OnDestroy will fire automatically when the entity is removed from the game                    *
 * // you can use this to clean up any game events or global variables                               *
 * // to allow for server owners to more easily resolve extension conflicts.                         *
 * ::MyExtensionGlobalVar <- "blah"                                                                  *
 * function MyExtension::_OnDestroy() {                                                              *
 *                                                                                                   *
 *     delete ::MyExtensionGlobalVar                                                                 *
 *     printl( "The zombies ate your extension! Goodbye cruel world..." )                            *
 * }                                                                                                 *
 *                                                                                                   *
 * // Sub-components of your extension                                                               *
 * MyExtension.PlayerHandler <- {                                                                    *
 *                                                                                                   *
 *     function ChangeAllPlayerTeams( team = TEAM_SPECTATOR ) {                                      *
 *                                                                                                   *
 *         foreach ( player in PZI_Util.PlayerArray )                                                *
 *             player.ForceChangeTeam( team, true )                                                  *
 *     }                                                                                             *
 * }                                                                                                 *
 *                                                                                                   *
 * //alternative syntax                                                                              *
 * function MyExtension::PlayerHandler::FindPlayerByName( name ) {                                   *
 *                                                                                                   *
 *     foreach ( player in PZI_Util.PlayerArray )                                                    *
 *         if ( Convars.GetClientConvarValue( "name", player.entindex() ) == name )                  *
 *             return player                                                                         *
 * }                                                                                                 *
 *                                                                                                   *
 * // functions can be called from their parent scope for less ugly code                             *
 * // this can cause naming conflicts for different functions with identical names                   *
 * // if you want to disable this behavior, set table_auto_delegate to false in PZI_CREATE_SCOPE     *
 * MyExtension.FindPlayerByName()                                                                    *
 *                                                                                                   *
 * MyExtensionEntity.Kill() // delete the entity and the global ::MyExtension reference alongside it *
 * EntFire( "__pzi_myextension", "Kill" ) // same thing                                              *
 *****************************************************************************************************/

if ( !( "__pzi_active_scopes" in ROOT ) )
	::__pzi_active_scopes <- {}

function PZI_CREATE_SCOPE( name = "", namespace = null, entity_ref = null, think_func = null, classname = null, table_auto_delegate = true ) {

	local ent = FindByName( null, name )

	if ( !ent || !ent.IsValid() ) {

		ent = CreateByClassname( classname || "logic_autosave" )
		SetPropString( ent, STRING_NETPROP_NAME, name )
		ent.ValidateScriptScope()
		::DispatchSpawn( ent )
	}

	SetPropBool( ent, STRING_NETPROP_PURGESTRINGS, true )
	__pzi_active_scopes[ ent ] <- namespace

	// don't spawn an actual preserved ent to save an edict
	if ( !classname )
		SetPropString( ent, "m_iClassname", "entity_saucer" )

	local ent_scope = ent.GetScriptScope()

	local namespace  =  namespace  || format( "%s_Scope", name )
	local entity_ref =  entity_ref || format( "%s_Entity", name )
	ROOT[ namespace ]  <- ent_scope
	ROOT[ entity_ref ] <- ent

	ent_scope.setdelegate( {

		function _newslot( k, v ) {

			if ( k == "_OnDestroy" && !_OnDestroy )
				_OnDestroy = v.bindenv( ent_scope )

			ent_scope.rawset( k, v )

            if ( typeof v == "function" ) {

                if ( k == "_OnCreate" )
                    _OnCreate.call( ent_scope )

                // fix anonymous function declarations in perf counter
                else if ( !v.getinfos().name ) 
                    compilestring( format( @" local _%s = %s; function %s() { _%s() }", k, k, k, k ) ).call( ent_scope )
            }

            // delegate variables to ent_scope for less verbose writing
            // e.g. Scope.MyTable.MyFunc() can be written instead as Scope.MyFunc() in more places
            else if ( typeof v == "table" && table_auto_delegate )
                v.setdelegate( ent_scope )
		}

	}.setdelegate( {

			parent     = ent_scope.getdelegate()
			id         = ent.GetScriptId()
			index      = ent.entindex()
			_OnDestroy = null

			function _get( k ) { return parent[k] }

			function _delslot( k ) {

				if ( k == id ) {

					if ( _OnDestroy )
						_OnDestroy.call( ent_scope )

                    // delete root references to ourself
					if ( namespace in ROOT )
						delete ROOT[ namespace ]

					if ( entity_ref in ROOT )
						delete ROOT[ entity_ref ]
				}

				delete parent[k]
			}
		} )
	)

	if ( think_func ) {

		// function passed, Add the think function directly to the entity
		if ( endswith( typeof think_func, "function" ) ) {

			local think_name = think_func.getinfos().name || format( "%s_Think", name )

			ent_scope[ think_name ] <- think_func
			AddThinkToEnt( ent, think_name )
			return
		}

        // String passed, set up think table and assume we're defining the actual function later
		ent_scope.ThinkTable <- {}

		compilestring( format( "function %s() { foreach( func in ThinkTable ) func.call( this ); return -1 }", think_func ) ).call( ent_scope )

		AddThinkToEnt( ent, think_func )
	}

	return { Entity = ent, Scope = ent_scope }
}