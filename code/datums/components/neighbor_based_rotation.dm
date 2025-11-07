/**
 * # Neighbor-based Rotation Component
 *
 * Sets the direction of an atom according to if it has a certain
 * atom neighboring it in any cardinal direction.
 *
 * Using the icon cutter or mapping airlock/podlock directions in
 * would be misery incarnate so this is the solution.
 */
/datum/component/neighbor_based_rotation
	/// Check for these neighboring types when decorating
	var/static/list/decorate_with = list(
		/turf/closed/wall,
		/obj/structure/window,
		/obj/structure/falsewall,
		/obj/machinery/door/airlock,
		/obj/machinery/door/poddoor,
	)

/datum/component/neighbor_based_rotation/Initialize(...)
	. = ..()
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE
	check_and_rotate()

/datum/component/neighbor_based_rotation/RegisterWithParent()
	var/atom/movable/target = parent
	for(var/direction in GLOB.cardinals)
		var/turf/turf = get_step(target, direction)
		if(!istype(turf))
			continue
		RegisterSignal(turf, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON, PROC_REF(check_wrapper))

/datum/component/neighbor_based_rotation/UnregisterFromParent()
	. = ..()
	var/atom/movable/target = parent
	for(var/direction in GLOB.cardinals)
		var/turf/turf = get_step(target, direction)
		if(!istype(turf))
			continue
		UnregisterSignal(turf, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON)

/// Passed to [COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON],
/// wrapper for [/datum/component/neighbor_based_rotation/proc/check_and_rotate]
/// as passing that directly would break shit in wonderful ways
/datum/component/neighbor_based_rotation/proc/check_wrapper(turf/source, atom/incoming, mapload)
	check_and_rotate()

/// Checks for applicable directions and handles direction if so
/datum/component/neighbor_based_rotation/proc/check_and_rotate()
	set_direction(find_applicable_direction())

/// Returns an applicable cardinal direction to work with
/datum/component/neighbor_based_rotation/proc/find_applicable_direction()
	var/atom/movable/target = parent
	. = 0
	for(var/direction in GLOB.cardinals)
		var/turf/turf_check = get_step(target, direction)
		if(!istype(turf_check))
			continue
		for(var/possible_neighbor in decorate_with)
			if(istype(turf_check, possible_neighbor)) // our candidate is a closed turf
				. |= direction
				break
			for(var/neighbor_content in turf_check)
				if(istype(neighbor_content, possible_neighbor)) // our candidate is a content of an open turf
					. |= direction
					break

/// Sets our parent's direction according to a neighbor's direction
/datum/component/neighbor_based_rotation/proc/set_direction(junction)
	var/atom/movable/target = parent
	if(junction & (NORTH|SOUTH))
		target.setDir(WEST)
	else if(junction & (WEST|EAST))
		target.setDir(NORTH)
