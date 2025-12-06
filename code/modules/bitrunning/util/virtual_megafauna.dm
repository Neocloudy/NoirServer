/// Removes all the loot and achievements from megafauna for bitrunning related
/mob/living/simple_animal/hostile/megafauna/proc/make_virtual_megafauna()
	var/new_max = clamp(max_health * 0.5, 600, 1300)
	max_health = new_max
	health = new_max

	true_spawn = FALSE

	loot.Cut()
	loot += /obj/structure/closet/crate/secure/bitrunning/encrypted

	crusher_loot.Cut()
	crusher_loot += /obj/structure/closet/crate/secure/bitrunning/encrypted
