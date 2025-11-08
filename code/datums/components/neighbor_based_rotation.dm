/atom/movable
	/// If true, neighbors will ignore us when checking if they should rotate
	var/neighbor_based_rotation_ignore
	/// If true, we will never receive [/datum/component/neighbor_based_rotation]
	var/never_set_neighbor_based_rotation

/**
 * # Neighbor-based Rotation Component
 *
 * Sets the direction of an atom according to if it has a certain
 * atom neighboring it in any cardinal direction.
 *
 * Using the icon cutter or mapping airlock/podlock directions in
 * would be misery incarnate so this is the solution.
 *
 * ## Options for *when* this is being dumb:
 * * Prevent atoms from receiving this using [/obj/effect/mapping_helpers/no_neighbor_based_rotation]
 *   * Makes it so an atom will never be affected by this component
 * * Manually prevent an atom that's in `decorate_with` from being checked using [/obj/effect/mapping_helpers/neighbor_based_rotation_blacklist]
 *   * Makes it so atoms with this component will not mind another atom even if it's in `decorate_with`
 */
/datum/component/neighbor_based_rotation
	/// Check for these neighboring types when decorating
	var/static/list/decorate_with = list(
		/turf/closed,
		/obj/structure/window/fulltile,
		/obj/structure/window/reinforced/fulltile,
		/obj/structure/falsewall,
		/obj/machinery/door/airlock,
		/obj/machinery/door/poddoor,
	)

/datum/component/neighbor_based_rotation/Initialize(...)
	. = ..()
	var/atom/movable/target = parent
	if(!ismovable(target) || target.never_set_neighbor_based_rotation)
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
	SIGNAL_HANDLER
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
			for(var/atom/neighbor_content as anything in turf_check)
				if(istype(neighbor_content, possible_neighbor) && !neighbor_content.neighbor_based_rotation_ignore) // our candidate is a content of an open turf
					. |= direction
					break

/// Sets our parent's direction according to a neighbor's direction
/datum/component/neighbor_based_rotation/proc/set_direction(junction)
	var/atom/movable/target = parent
	if(!junction)
		junction |= SOUTH
	if(junction & (NORTH|SOUTH))
		target.setDir(WEST)
	else if(junction & (WEST|EAST))
		target.setDir(NORTH)
