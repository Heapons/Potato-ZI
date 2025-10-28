class Queue {

	items = null; // Table instead of array for speed ( shifting arrays is expensive )
	head  = null; // Index of the first element
	tail  = null; // Index for the next element to be added

	constructor() {

		items = {}
		head  = 0
		tail  = 0
	}

	// Check if the queue is empty
	function isEmpty()
		return head >= tail

	// Get the size of the queue
	function size()
		return tail - head

	// Add an element to the end of the line
	function add( value ) {

		items[tail] <- value
		++tail
	}

	// Remove and return the element first in line
	function pop() {

		if ( isEmpty() ) {

			items = {}
			head  = 0
			tail  = 0
			return
		}

		local value = items[head]
		delete items[head]
		++head; // Next in line

		return value
	}

	// Return the element first in line
	function peek() {

		if ( isEmpty() ) return
		return items[head]
	}
}

::PZI_Misc <- {

	function GetWorldCenter() {

		local world = FindByClassname( null, "worldspawn" )
		local mins  = NetProps.GetPropVector( world, "m_WorldMins" )
		local maxs  = NetProps.GetPropVector( world, "m_WorldMaxs" )

		return ( maxs - mins ) * 0.5 + mins
	},

	function VectorAngles( forward ) {
		local yaw, pitch
		if ( !forward.y && !forward.x ) {
			yaw = 0.0
			if ( forward.z > 0.0 )
				pitch = 270.0
			else
				pitch = 90.0
		}
		else {
			yaw = ( atan2( forward.y, forward.x ) * 180.0 / Pi )
			if ( yaw < 0.0 )
				yaw += 360.0
			pitch = ( atan2( -forward.z, forward.Length2D() ) * 180.0 / Pi )
			if ( pitch < 0.0 )
				pitch += 360.0
		}

		return QAngle( pitch, yaw, 0.0 )
	},
}