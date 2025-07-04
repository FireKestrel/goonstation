/*
CONTAINS:
NON-CHEM GRENADES
GIMMICK BOMBS
BREACHING CHARGES
FIREWORKS
PIPE BOMBS + CONSTRUCTION
*/

////////////////////////////// Old-style grenades ///////////////////////////////////////

TYPEINFO(/obj/item/old_grenade)
	mats = 6

ADMIN_INTERACT_PROCS(/obj/item/old_grenade, proc/detonate)

/obj/item/old_grenade
	desc = "You shouldn't be able to see this!"
	name = "old grenade"
	var/armed = FALSE
	var/det_time = 3 SECONDS
	var/org_det_time = 3 SECONDS
	var/alt_det_time = 6 SECONDS
	w_class = W_CLASS_SMALL
	icon = 'icons/obj/items/grenade.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_weapons.dmi'
	icon_state = "banana"
	item_state = "banana"
	throw_speed = 4
	throw_range = 20
	flags = TABLEPASS | CONDUCT | EXTRADELAY
	tool_flags = TOOL_ASSEMBLY_APPLIER
	c_flags = ONBELT
	is_syndicate = FALSE
	stamina_damage = 0
	stamina_cost = 0
	stamina_crit_chance = 0
	duration_put = 0.25 SECONDS //crime
	var/is_dangerous = TRUE
	var/sound_armed = null
	var/icon_state_armed = null
	var/issawfly = FALSE //for sawfly remote
	///damage when loaded into a 40mm convesion chamber
	var/launcher_damage = 25
	var/detonating = FALSE
	HELP_MESSAGE_OVERRIDE({"You can use a <b>screwdriver</b> to adjust the detonation time."})

	New()
		..()
		RegisterSignal(src, COMSIG_ITEM_ASSEMBLY_ITEM_SETUP, PROC_REF(assembly_setup))
		RegisterSignal(src, COMSIG_ITEM_ASSEMBLY_APPLY, PROC_REF(assembly_application))
		if(src.is_dangerous)
			src.item_function_flags |= ASSEMBLY_NEEDS_MESSAGING

	disposing()
		UnregisterSignal(src, COMSIG_ITEM_ASSEMBLY_ITEM_SETUP)
		UnregisterSignal(src, COMSIG_ITEM_ASSEMBLY_APPLY)
		..()

	/// ----------- Trigger/Applier/Target-Assembly-Related Procs -----------

	proc/assembly_setup(var/manipulated_grenade, var/obj/item/assembly/parent_assembly, var/mob/user, var/is_build_in)
		//since we have a lot of icons for grenades, but not for the assembly, we go, like with old assemblies, just with the custom chem grenade icon
		parent_assembly.applier_icon_prefix = "chem_grenade"

	proc/assembly_application(var/manipulated_grenade, var/obj/item/assembly/parent_assembly, var/obj/assembly_target)
		//can't qdel them here or we have stuff like smoke grenades creating smoke at the center of the map.... ugh
		parent_assembly.invisibility = INVIS_ALWAYS_ISH
		parent_assembly.qdel_on_tear_apart = TRUE
		parent_assembly.expended = TRUE
		src.detonate()

	/// ----------------------------------------------


	attack_self(mob/user as mob)
		if (!src.armed)
			src.armed = TRUE		//This could help for now. Should leverage the click buffer from combat stuff too.
			if (!isturf(user.loc))
				src.armed = FALSE
				return
			logGrenade(user)
			if (user?.bioHolder.HasEffect("clumsy"))
				boutput(user, SPAN_ALERT("Huh? How does this thing work?!"))
				src.UpdateIcon()
				playsound(src.loc, src.sound_armed, 75, 1, -3)
				src.add_fingerprint(user)
				SPAWN(0.5 SECONDS)
					if (src) detonate(user)
					return
			else
				boutput(user, SPAN_ALERT("You prime [src]! [det_time/10] seconds!"))
				src.UpdateIcon()
				playsound(src.loc, src.sound_armed, 75, 1, -3)
				src.add_fingerprint(user)
				SPAWN(src.det_time)
					if (src) detonate(user)
					return

// warcrimes: Why the fuck is autothrow a feature why would this ever be a feature WHY. Now it wont do it unless it's primed i think.
	afterattack(atom/target as mob|obj|turf, mob/user as mob)
		if (src.armed)
			return
		if (BOUNDS_DIST(user, target) == 0 || (!isturf(target) && !isturf(target.loc)) || !isturf(user.loc) || !src.armed )
			return
		if (user.equipped() == src)
			if (!src.armed)
				src.armed = TRUE
				src.UpdateIcon()
				logGrenade(user)
				boutput(user, SPAN_ALERT("You prime [src]! [det_time/10] seconds!"))
				playsound(src.loc, src.sound_armed, 75, 1, -3)
				SPAWN(src.det_time)
					if (src) detonate(user)
					return
			user.drop_item()
			src.throw_at(get_turf(target), 10, 3)
			src.add_fingerprint(user)

	attackby(obj/item/W, mob/user)
		if (isscrewingtool(W))
			if (src.det_time == src.org_det_time)
				src.det_time = src.alt_det_time
				user.show_message(SPAN_NOTICE("You set [src] for a [det_time/10] second detonation time."))
				src.desc = "It is set to detonate in [det_time/10] seconds."
			else
				src.det_time = src.org_det_time
				user.show_message(SPAN_NOTICE("You set [src] for a [det_time/10] second detonation time."))
				src.desc = "It is set to detonate in [det_time/10] seconds."
			src.add_fingerprint(user)

	update_icon()
		..()
		if (src.armed)
			src.icon_state = src.icon_state_armed
		else
			src.icon_state = initial(src.icon_state)

	ex_act(severity)
		if(!src.detonating)
			src.detonate(null)
		. = ..()

	///clone for grenade launcher purposes only. Not a real deep copy, just barely good enough to work for something that's going to be instantly detonated
	proc/launcher_clone()
		return new src.type

	proc/detonate(mob/user) // Most grenades require a turf reference.
		SHOULD_CALL_PARENT(TRUE)
		var/turf/T = get_turf(src)
		src.detonating = TRUE
		if (!T || !isturf(T))
			return null
		else
			return T

	proc/logGrenade(mob/user)
		var/area/A = get_area(src)
		if(!A.dont_log_combat && user)
			if(is_dangerous)
				message_admins("Grenade ([src]) primed at [log_loc(src)] by [key_name(user)].")
			logTheThing(LOG_COMBAT, user, "primes a grenade ([src.type]) at [log_loc(user)].")

ABSTRACT_TYPE(/obj/item/old_grenade/spawner)
/obj/item/old_grenade/spawner
	desc = "It is set to detonate in 3 seconds."
	det_time = 3 SECONDS
	org_det_time = 3 SECONDS
	alt_det_time = 6 SECONDS
	is_syndicate = TRUE
	sound_armed = 'sound/weapons/armbomb.ogg'
	is_dangerous = FALSE
	var/payload = null
	var/amount_to_spawn = 5

	detonate()
		var/turf/T = ..()
		if (T)
			playsound(T, 'sound/weapons/flashbang.ogg', 25, TRUE)
			if (src.is_dangerous)
				var/mob/living/carbon/human/hero = src.get_hero()
				if(istype(hero))
					for (var/i in 1 to (src.amount_to_spawn / 2))
						new payload(hero) // so they burst out
					qdel(src)
					hero.gib()
					return
			new payload(T)
			for (var/i in 1 to src.amount_to_spawn - 1)
				var/turf/adjacent = get_step(T, cardinal[(i % length(cardinal)) + 1])
				if (!adjacent.density)
					new payload(adjacent)
				else
					new payload(T)
		qdel(src)

	launcher_clone() //for varedit shenanigans
		var/obj/item/old_grenade/spawner/out = ..()
		out.payload = src.payload
		out.amount_to_spawn = src.amount_to_spawn
		return out

/obj/item/old_grenade/spawner/banana
	name = "banana grenade"
	icon_state = "banana"
	icon_state_armed = "banana1"
	payload = /obj/item/bananapeel
	launcher_damage = 10

/obj/item/old_grenade/spawner/cheese_sandwich
	name = "cheese sandwich grenade"
	icon_state = "banana-old"
	icon_state_armed = "banana1-old"
	payload = /obj/item/reagent_containers/food/snacks/sandwich/cheese
	launcher_damage = 10

/obj/item/old_grenade/spawner/banana_corndog
	name = "banana corndog grenade"
	icon_state = "banana-old"
	icon_state_armed = "banana1-old"
	payload = /obj/item/reagent_containers/food/snacks/corndog/banana
	launcher_damage = 10

/obj/item/old_grenade/spawner/wasp
	name = "suspicious looking grenade"
	icon_state = "wasp"
	icon_state_armed = "wasp1"
	payload =/mob/living/critter/small_animal/wasp/angry
	is_dangerous = TRUE

/obj/item/old_grenade/thing_thrower
	desc = "It is set to detonate in 3 seconds."
	name = "banana grenade"
	det_time = 3 SECONDS
	org_det_time = 3 SECONDS
	alt_det_time = 6 SECONDS
	icon_state = "banana"
	item_state = "banana"
	is_syndicate = TRUE
	sound_armed = 'sound/weapons/armbomb.ogg'
	icon_state_armed = "banana1"
	is_dangerous = FALSE
	var/payload = /obj/item/bananapeel
	var/count = 7
	var/throw_radius = 5

	detonate()
		var/turf/T = ..()
		if (T)
			playsound(T, 'sound/weapons/flashbang.ogg', 25, TRUE)
			for(var/i = 1; i <= src.count; i++)
				var/atom/movable/thing = new payload(T)
				var/turf/target = locate(T.x + rand(-throw_radius, throw_radius), T.y + rand(-throw_radius, throw_radius), T.z)
				if(target)
					before_throwing(thing, target)
					thing.throw_at(target, rand(0, 10), rand(1, throw_radius))

		qdel(src)


	launcher_clone() //for varedit shenanigans
		var/obj/item/old_grenade/thing_thrower/out = ..()
		out.payload = src.payload
		out.count = src.count
		return out

	proc/before_throwing(var/thing, var/turf/target)
		return

/obj/item/old_grenade/thing_thrower/aconite
	desc = "It is set to detonate in 3 seconds."
	name = "aconite grenade"
	icon_state = "aconite"
	icon_state_armed = "aconite1"

	payload = /obj/item/plant/herb/aconite
	count = 8

/obj/item/old_grenade/thing_thrower/garlic
	desc = "It is set to detonate in 3 seconds."
	name = "garlic grenade"
	icon_state = "garlic"
	icon_state_armed = "garlic1"

	payload = /obj/item/reagent_containers/food/snacks/plant/garlic
	count = 16

/obj/item/old_grenade/thing_thrower/csword
	desc = "It is set to detonate in 3 seconds."
	name = "cyalume saber grenade"
	icon_state = "fragnade"
	icon_state_armed = "fragnade"
	payload = /obj/item/sword
	count = 12

	before_throwing(var/thing, var/turf/target)
		if (istype(thing, /obj/item/sword))
			var/obj/item/sword/sword = thing
			sword.active = TRUE
			sword.UpdateIcon()
			// SET_BLOCKS(BLOCK_ALL)
			sword.throwforce = 15
			sword.hit_type = DAMAGE_CUT
			sword.stamina_damage = sword.active_stamina_dmg
			if(prob(50))
				playsound(target,'sound/weapons/male_cswordturnon.ogg', 70, FALSE, 5, clamp(1.0 , 0.7, 1.2))
			else
				playsound(target,'sound/weapons/female_cswordturnon.ogg' , 100, 0, 5, clamp(1.0, 0.7, 1.4))
			sword.force = sword.active_force
			sword.stamina_cost = sword.active_stamina_cost
			sword.w_class = W_CLASS_BULKY
			sword.leaves_slash_wound = TRUE
			sword.setItemSpecial(/datum/item_special/swipe/csaber)

		return

/obj/item/old_grenade/thing_thrower/pie
	desc = "It is set to detonate in 3 seconds."
	name = "pie grenade"
	icon_state = "fragnade"
	icon_state_armed = "fragnade"

	payload = /obj/item/reagent_containers/food/snacks/pie/cream
	count = 20


/obj/item/old_grenade/thing_thrower/shuriken
	desc = "It is set to detonate in 3 seconds."
	name = "shuriken grenade"
	icon_state = "fragnade"
	icon_state_armed = "fragnade"

	payload = /obj/item/implant/projectile/shuriken
	count = 12

TYPEINFO(/obj/item/old_grenade/graviton)
	mats = 12

/obj/item/old_grenade/graviton //ITS SPELT GRAVITON
	desc = "It is set to detonate in 10 seconds."
	name = "graviton grenade"
	det_time = 10 SECONDS
	org_det_time = 10 SECONDS
	alt_det_time = 6 SECONDS
	icon_state = "graviton"
	item_state = "emp" //TODO: grenades REALLY need custom inhands, but I'm not submitting them in this PR
	is_syndicate = TRUE
	sound_armed = 'sound/weapons/armbomb.ogg'
	icon_state_armed = "graviton1"
	var/icon_state_exploding = "graviton2"

	attack_self(mob/user as mob)
		if (!src.armed)
			src.armed = TRUE		//This could help for now. Should leverege the click buffer from combat stuff too.
			if (!isturf(user.loc))
				src.armed = FALSE
				return
			logGrenade(user)
			if (user?.bioHolder.HasEffect("clumsy"))
				boutput(user, SPAN_ALERT("Huh? How does this thing work?!"))
				src.icon_state = src.icon_state_exploding
				FLICK(src.icon_state_armed, src)
				playsound(src.loc, src.sound_armed, 75, 1, -3)
				src.add_fingerprint(user)
				SPAWN(0.5 SECONDS)
					if (src) detonate()
					return
			else
				boutput(user, SPAN_ALERT("You prime [src]! [det_time/10] seconds!"))
				src.icon_state = src.icon_state_exploding
				FLICK(src.icon_state_armed, src)
				playsound(src.loc, src.sound_armed, 75, 1, -3)
				src.add_fingerprint(user)
				SPAWN(src.det_time)
					if (src) detonate()
					return
		return

	detonate()
		var/turf/T = ..()
		if (T)
			if (T && isrestrictedz(T.z) || T.loc:sanctuary)
				src.visible_message(SPAN_ALERT("[src] buzzes for a moment, then self-destructs."))
				elecflash(src,power = 4)
				qdel(src)
				return
			playsound(src.loc, 'sound/effects/singsuck.ogg', 75, TRUE)
			var/reach = 9
			var/mob/living/carbon/human/hero = src.get_hero()
			if (istype(hero))
				reach = reach / 2
				hero.TakeDamage("chest", 100, 0, 0, DAMAGE_CRUSH)
			for (var/atom/movable/AM in orange(reach, T))
				if (prob(50)) continue
				if (AM.anchored == ANCHORED_ALWAYS) continue
				if (HAS_ANY_FLAGS(AM.event_handler_flags, IMMUNE_SINGULARITY | IMMUNE_SINGULARITY_INACTIVE)) continue
				if (istypes(AM, list(/obj/effect, /obj/overlay))) continue
				var/area/t = get_area(AM)
				if (t?.sanctuary) continue
				step_towards(AM ,src)
		qdel(src)
		return

TYPEINFO(/obj/item/old_grenade/singularity)
	mats = 12

/obj/item/old_grenade/singularity
	desc = "It is set to detonate in 10 seconds."
	name = "singularity grenade"
	det_time = 10 SECONDS
	org_det_time = 10 SECONDS
	alt_det_time = 6 SECONDS
	icon_state = "graviton"
	item_state = "emp"
	is_syndicate = TRUE
	sound_armed = 'sound/weapons/armbomb.ogg'
	icon_state_armed = "graviton1"
	var/icon_state_exploding = "graviton2"
	var/radius = 3

	attack_self(mob/user as mob)
		if (!src.armed)
			src.armed = TRUE		//This could help for now. Should leverege the click buffer from combat stuff too.
			if (!isturf(user.loc))
				src.armed = FALSE
				return
			logGrenade(user)
			if (user?.bioHolder.HasEffect("clumsy"))
				boutput(user, SPAN_ALERT("Huh? How does this thing work?!"))
				src.icon_state = src.icon_state_exploding
				FLICK(src.icon_state_armed, src)
				playsound(src.loc, src.sound_armed, 75, 1, -3)
				src.add_fingerprint(user)
				SPAWN(0.5 SECONDS)
					if (src) detonate()
					return
			else
				boutput(user, SPAN_ALERT("You prime [src]! [det_time/10] seconds!"))
				src.icon_state = src.icon_state_exploding
				FLICK(src.icon_state_armed, src)
				playsound(src.loc, src.sound_armed, 75, 1, -3)
				src.add_fingerprint(user)
				SPAWN(src.det_time)
					if (src) detonate()
					return
		return

	detonate()
		var/turf/T = ..()
		if (T)
			if (T && isrestrictedz(T.z) || T.loc:sanctuary)
				src.visible_message(SPAN_ALERT("[src] buzzes for a moment, then self-destructs."))
				elecflash(src,power = 4)
				qdel(src)
				return
			src.build_a_singulo()

	proc/build_a_singulo()
		var/turf/C = get_turf(src)
		for(var/turf/T in block(locate(C.x - radius, C.y - radius, C.z), locate(C.x + radius, C.y + radius, C.z)))
			T.ReplaceWith(/turf/simulated/floor/engine, 0, 1, 0, 0)
		new /obj/machinery/the_singularitygen(C)
		for(var/dir in ordinal)
			var/turf/T = get_steps(C, dir, radius)
			var/obj/machinery/field_generator/gen = new(T)
			gen.set_active(1)
			gen.state = 3
			gen.power = 250
			gen.anchored = ANCHORED
			icon_state = "Field_Gen +a"
		qdel(src)

/obj/item/old_grenade/smoke
	desc = "It is set to detonate in 2 seconds."
	name = "smoke grenade"
	icon_state = "smoke"
	det_time = 2 SECONDS
	org_det_time = 2 SECONDS
	alt_det_time = 6 SECONDS
	item_state = "flashbang"
	is_syndicate = TRUE
	sound_armed = 'sound/weapons/armbomb.ogg'
	icon_state_armed = "smoke1"
	var/datum/effects/system/bad_smoke_spread/smoke

	New()
		..()
		src.smoke = new /datum/effects/system/bad_smoke_spread/
		src.smoke.attach(src)
		src.smoke.set_up(10, 0, src.loc)

	detonate()
		var/turf/T = ..()
		if (T)
			var/obj/item/old_grenade/smoke/mustard/M = null
			if (istype(src, /obj/item/old_grenade/smoke/mustard))
				M = src
			playsound(T, 'sound/effects/smoke.ogg', 50, TRUE, -3)

			SPAWN(0)
				if (src)
					if (M && istype(M, /obj/item/old_grenade/smoke/mustard))
						M.mustard_gas.start()
					else
						src.smoke.start()

					sleep(1 SECOND)
					if (M && istype(M, /obj/item/old_grenade/smoke/mustard))
						M.mustard_gas.start()
					else
						src.smoke.start()

					sleep(1 SECOND)
					if (M && istype(M, /obj/item/old_grenade/smoke/mustard))
						M.mustard_gas.start()
					else
						src.smoke.start()

					sleep(1 SECOND)
					if (M && istype(M, /obj/item/old_grenade/smoke/mustard))
						M.mustard_gas.start()
					else
						src.smoke.start()

					if (M && istype(M, /obj/item/old_grenade/smoke/mustard))
						qdel(M)
					else
						qdel(src)
		else
			qdel(src)
		return

/obj/item/old_grenade/smoke/mustard
	name = "mustard gas grenade"
	var/datum/effects/system/mustard_gas_spread/mustard_gas
	icon_state = "mustard"
	icon_state_armed = "mustard1"

	New()
		..()
		if (usr?.loc) //Wire: Fix for Cannot read null.loc
			src.mustard_gas = new /datum/effects/system/mustard_gas_spread/
			src.mustard_gas.attach(src)
			src.mustard_gas.set_up(5, 0, usr.loc)

/obj/item/old_grenade/stinger
	name = "stinger grenade"
	desc = "It is set to detonate in 3 seconds."
	icon_state = "fragnade"
	det_time = 3 SECONDS
	org_det_time = 3 SECONDS
	alt_det_time = 6 SECONDS
	item_state = "fragnade"
	is_syndicate = FALSE
	sound_armed = 'sound/weapons/pindrop.ogg'
	icon_state_armed = "fragnade1"
	var/custom_projectile_type = /datum/projectile/bullet/stinger_ball
	var/pellets_to_fire = 20

	detonate()
		var/turf/T = ..()
		if (T)
			playsound(T, 'sound/weapons/grenade.ogg', 25, TRUE)
			var/mob/living/carbon/human/hero = src.get_hero()
			if(istype(hero) && src.custom_projectile_type)
				for (var/i in 1 to (src.pellets_to_fire / 2 ))
					var/obj/projectile/P = initialize_projectile_pixel_spread(src, new src.custom_projectile_type(), hero, 0, 0)
					P.collide(hero)
				src.pellets_to_fire = src.pellets_to_fire / 4
			explosion(src, T, -1, -1, -0.25, 1)
			var/obj/overlay/O = new/obj/overlay(get_turf(T))
			O.anchored = ANCHORED
			O.name = "Explosion"
			O.layer = NOLIGHT_EFFECTS_LAYER_BASE
			O.icon = 'icons/effects/64x64.dmi'
			O.icon_state = "explo_fiery"
			var/obj/item/old_grenade/stinger/frag/F = null
			if (istype(src, /obj/item/old_grenade/stinger/frag))
				F = src
			if (F)
				playsound(T, 'sound/effects/smoke.ogg', 20, TRUE, -2)
				SPAWN(0)
					if (F?.smoke) //Wire note: Fix for Cannot execute null.start()
						for(var/i = 1 to 6)
							F.smoke.start()
							sleep(1 SECOND)
			var/datum/projectile/special/spreader/uniform_burst/circle/PJ = new /datum/projectile/special/spreader/uniform_burst/circle(T)
			if(src.custom_projectile_type)
				PJ.spread_projectile_type = src.custom_projectile_type
				PJ.pellet_shot_volume = 75 / PJ.pellets_to_fire //anti-ear destruction
			PJ.pellets_to_fire = src.pellets_to_fire
			var/targetx = T.x - rand(-5,5)
			var/targety = T.y - rand(-5,5)
			var/turf/newtarget = locate(targetx, targety, T.z)
			shoot_projectile_ST_pixel_spread(T, PJ, newtarget)
			SPAWN(0.5 SECONDS)
				qdel(O)
				qdel(src)
		else
			qdel(src)
		return


	launcher_clone() //for varedit shenanigans
		var/obj/item/old_grenade/stinger/out = ..()
		out.custom_projectile_type = src.custom_projectile_type
		out.pellets_to_fire = src.pellets_to_fire
		return out

/obj/item/old_grenade/stinger/frag
	name = "frag grenade"
	icon_state = "fragnade-alt"
	icon_state_armed = "fragnade-alt1"
	var/datum/effects/system/bad_smoke_spread/smoke
	custom_projectile_type = /datum/projectile/bullet/grenade_fragment
	launcher_damage = 30

	New()
		..()
		src.smoke = new /datum/effects/system/bad_smoke_spread/
		src.smoke.attach(src)
		src.smoke.set_up(7, 1, src.loc)

/obj/item/old_grenade/high_explosive
	name = "HE grenade"
	desc = "A high-explosive grenade. It is set to detonate in 3 seconds."
	icon_state = "fragnade-alt"
	icon_state_armed = "fragnade-alt1"
	det_time = 3 SECONDS
	org_det_time = 3 SECONDS
	alt_det_time = 6 SECONDS
	item_state = "fragnade"
	is_syndicate = FALSE
	sound_armed = 'sound/weapons/pindrop.ogg'
	launcher_damage = 30

	detonate()
		var/turf/T = ..()
		if (T)
			var/power = 5.0
			var/mob/living/carbon/human/hero = src.get_hero()
			if(istype(hero))
				hero.ex_act(1, src, power)
				power = power / 2
			explosion_new(src, T, power, 2)
			playsound(T, 'sound/weapons/grenade.ogg', 25, TRUE)
			var/obj/overlay/O = new/obj/overlay(get_turf(T))
			O.anchored = ANCHORED
			O.name = "Explosion"
			O.layer = NOLIGHT_EFFECTS_LAYER_BASE
			O.icon = 'icons/effects/64x64.dmi'
			O.icon_state = "explo_fiery"
			SPAWN(0.5 SECONDS)
				qdel(O)
				qdel(src)
		else
			qdel(src)
		return

/obj/item/old_grenade/sonic
	name = "sonic grenade"
	desc = "It is set to detonate in 3 seconds."
	icon_state = "sonic"
	det_time = 3 SECONDS
	org_det_time = 3 SECONDS
	alt_det_time = 6 SECONDS
	item_state = "flashbang"
	is_syndicate = TRUE
	sound_armed = 'sound/effects/screech.ogg'
	icon_state_armed = "sonic1"

	detonate()
		var/turf/T = ..()
		if (T)
			if (isrestrictedz(T.z) && !restricted_z_allowed(usr, T))
				src.visible_message(SPAN_ALERT("[src] buzzes for a moment, then self-destructs."))
				elecflash(T)
				qdel(src)
				return

			playsound(T, 'sound/weapons/flashbang.ogg', 25, TRUE)

			var/base_damage = 16

			var/mob/living/carbon/human/hero = src.get_hero()
			if(istype(hero))
				hero.take_ear_damage(base_damage)
				base_damage = base_damage / 2

			for (var/mob/living/M in hearers(8, T))
				if(check_target_immunity(M)) continue
				var/loud = base_damage / (GET_DIST(M, T) + 1)
				if (src.loc == M.loc || src.loc == M)
					loud = base_damage

				var/weak = loud / 3
				var/stun = loud
				var/damage = loud * 2
				var/tempdeaf = loud * 3

				M.apply_sonic_stun(weak, stun, 0, 0, 0, damage, tempdeaf)

			sonic_attack_environmental_effect(T, 8, list("window", "r_window", "displaycase", "glassware"))

		qdel(src)
		return

/obj/item/old_grenade/foam_dart
	name = "foam dart grenade"
	desc = "You can make great fights with these and foam dart guns."
	icon_state = "foam-dart"
	det_time = 3 SECONDS
	org_det_time = 3 SECONDS
	alt_det_time = 6 SECONDS
	item_state = "fragnade"
	sound_armed = 'sound/weapons/pindrop.ogg'
	icon_state_armed = "foam-dart1"
	var/custom_projectile_type = /datum/projectile/bullet/foamdart/biodegradable
	var/pellets_to_fire = 18
	launcher_damage = 5

	detonate()
		var/turf/T = ..()
		if (!T)
			qdel(src)
			return
		var/datum/projectile/special/spreader/uniform_burst/circle/burst_circle = new /datum/projectile/special/spreader/uniform_burst/circle(T)
		if(src.custom_projectile_type)
			burst_circle.spread_projectile_type = src.custom_projectile_type
			burst_circle.pellet_shot_volume = 75 / burst_circle.pellets_to_fire
		burst_circle.pellets_to_fire = src.pellets_to_fire
		var/targetx = T.x - rand(-5,5)
		var/targety = T.y - rand(-5,5)
		var/turf/newtarget = locate(targetx, targety, T.z)
		shoot_projectile_ST_pixel_spread(T, burst_circle, newtarget)
		SPAWN(0.5 SECONDS)
			qdel(src)

	launcher_clone() //for varedit shenanigans
		var/obj/item/old_grenade/foam_dart/out = ..()
		out.custom_projectile_type = src.custom_projectile_type
		out.pellets_to_fire = src.pellets_to_fire
		return out

/obj/item/old_grenade/emp
	desc = "It is set to detonate in 5 seconds."
	name = "emp grenade"
	det_time = 5 SECONDS
	org_det_time = 5 SECONDS
	alt_det_time = 3 SECONDS
	icon_state = "emp"
	item_state = "emp"
	is_syndicate = TRUE
	sound_armed = 'sound/weapons/armbomb.ogg'
	icon_state_armed = "emp1"

	detonate()
		var/turf/T = ..()
		if (T)
			playsound(T, 'sound/items/Welder2.ogg', 25, TRUE)

			var/reach = world.view - 1

			var/mob/living/carbon/human/hero = src.get_hero()
			if(istype(hero))
				var/datum/organHolder/organs = hero.organHolder
				if(istype(organs))
					for(var/organ_slot in organs.organ_list)
						var/obj/item/organ/O = organs.organ_list[organ_slot]
						if(O?.robotic)
							O.emp_act()
				reach = reach / 2

			T.hotspot_expose(700,125)

			var/grenade = src // detaching the proc - in theory
			src = null

			var/obj/overlay/pulse = new/obj/overlay(T)
			pulse.icon = 'icons/effects/effects.dmi'
			pulse.icon_state = "emppulse"
			pulse.name = "emp pulse"
			pulse.anchored = ANCHORED
			SPAWN(2 SECONDS)
				if (pulse) qdel(pulse)

			for (var/turf/tile in range(reach, T))
				for (var/atom/O in tile.contents)
					var/area/t = get_area(O)
					if(t?.sanctuary) continue
					O.emp_act()

			qdel(grenade)
		else
			qdel(src)
		return

TYPEINFO(/obj/item/old_grenade/oxygen)
	mats = list("metal_dense" = 2,
				"conductive" = 2,
				"molitz" = 10,
				"char" = 1)
/obj/item/old_grenade/oxygen
	name = "red oxygen grenade"
	desc = "It is set to detonate in 3 seconds."
	det_time = 3 SECONDS
	org_det_time = 3 SECONDS
	alt_det_time = 6 SECONDS
	icon_state = "oxy"
	item_state = "flashbang"
	sound_armed = 'sound/weapons/armbomb.ogg'
	icon_state_armed = "oxy1"
	is_dangerous = FALSE
	launcher_damage = 20

	detonate()
		var/turf/simulated/T = ..()
		var/datum/gas_mixture/GM = new /datum/gas_mixture
		GM.temperature = T20C + 15
		GM.oxygen = 1830
		GM.carbon_dioxide = 20

		var/obj/effects/explosion/E = new /obj/effects/explosion(T)
		// Uses existing animated icon adjust coloration of explosion to lighter cyan to match oxygen items
		// scaling it to cover a turf, adjusting plane to avoid casting shadows, and wave animation to
		// help differentiate it from a standard explosion (also makes it wispy)
		E.color = list(0,0,0.6,0.2,0, 0.3,0,-0.8,0,0, 0,0.33,0,0,0, 0.9,0.8,0.8,0.7,0)
		E.plane = PLANE_NOSHADOW_ABOVE
		E.transform = matrix(0.75, MATRIX_SCALE)
		animate_wave(E,4)

		if (T && istype(T))
			if (T.air)
				if (T.parent?.group_processing)
					T.parent.air.merge(GM)
				else
					var/count = length(T.parent?.members)
					if (count)
						var/o2_per = GM.oxygen / count
						var/co2_per = GM.carbon_dioxide / count
						for (var/turf/simulated/MT as() in T.parent.members)
							if (GM.disposed)
								GM = new /datum/gas_mixture
							GM.temperature = T20C + 15
							GM.oxygen = o2_per
							GM.carbon_dioxide = co2_per
							MT.assume_air(GM)
					else
						T.assume_air(GM)

			for (var/mob/living/HH in hearers(8, T))
				var/checkdist = GET_DIST(HH.loc, T)
				var/misstep = clamp(1 + 10 * (5 - checkdist), 0, 40)
				var/ear_damage = max(0, 5 * 0.2 * (3 - checkdist))
				var/ear_tempdeaf = max(0, 5 * 0.2 * (5 - checkdist))
				var/stamina = clamp(5 * (5 + 1 * (7 - checkdist)), 0, 120)
				HH.apply_sonic_stun(0, 0, misstep, 0, 2, ear_damage, ear_tempdeaf, stamina)

			animate(E, alpha=0, time=2.5 SECONDS)
			playsound(T, 'sound/weapons/flashbang.ogg', 30, TRUE)
			var/datum/effects/system/steam_spread/steam = new /datum/effects/system/steam_spread
			steam.set_up(10, 0, get_turf(src), color="#0ff", plane=PLANE_NOSHADOW_ABOVE)
			steam.attach(src.loc)
			steam.start()

		else
			animate(E, alpha=0, time=2 SECONDS)
			playsound(T, 'sound/weapons/flashbang.ogg', 15, TRUE)

		E.fingerprintslast = src.fingerprintslast
		qdel(src)
		return

/obj/item/old_grenade/moustache
	name = "moustache grenade"
	desc = "It is set to detonate in 3 seconds."
	det_time = 3 SECONDS
	org_det_time = 3 SECONDS
	alt_det_time = 6 SECONDS
	icon_state = "moustache"
	item_state = "flashbang"
	is_syndicate = TRUE
	sound_armed = 'sound/weapons/armbomb.ogg'
	icon_state_armed = "moustache1"
	launcher_damage = 10

	detonate()
		var/turf/T = ..()
		if (T)
			for (var/mob/living/carbon/human/M in range(5, T))
				if (!(M.wear_mask && istype(M.wear_mask, /obj/item/clothing/mask/moustache)))
					for (var/obj/item/clothing/O in M)
						if (istype(O,/obj/item/clothing/mask))
							M.u_equip(O)
							if (O)
								O.set_loc(M.loc)
								O.dropped(M)
								O.layer = initial(O.layer)

					var/obj/item/clothing/mask/moustache/moustache = new /obj/item/clothing/mask/moustache(M)
					moustache.cant_self_remove = 1
					moustache.cant_other_remove = 1

					M.equip_if_possible(moustache, SLOT_WEAR_MASK)
					M.set_clothing_icon_dirty()

			playsound(T, 'sound/effects/Explosion2.ogg', 100, TRUE)
			var/obj/effects/explosion/E = new /obj/effects/explosion(T)
			E.fingerprintslast = src.fingerprintslast

		qdel(src)
		return

/obj/item/old_grenade/light_gimmick
	name = "light grenade"
	icon_state = "lightgrenade"
	icon = 'icons/obj/items/weapons.dmi'
	desc = "It's a small cast-iron egg-shaped object, with the words \"Pick Me Up\" in gold in it."
	armed = FALSE
	tool_flags = 0 // No
	var/old_light_grenade = 0
	var/destination
	HELP_MESSAGE_OVERRIDE({""})

	New()
		..()
		#ifdef UPSCALED_MAP
		destination = locate(40 * 2,19 * 2,2)
		#else
		destination = locate(40,19,2)
		#endif

	primed
		armed = TRUE

	old
		old_light_grenade = 1

		primed
			armed = TRUE

	afterattack(atom/target as mob|obj|turf|area, mob/user as mob)
		if (BOUNDS_DIST(user, target) == 0 || (!isturf(target) && !isturf(target.loc)) || !isturf(user.loc))
			return
		if (target.storage)
			return ..()
		if (!src.armed && user)
			message_admins("Grenade ([src]) primed at [log_loc(src)] by [key_name(user)].")
			logTheThing(LOG_COMBAT, user, "primes a grenade ([src.type]) at [log_loc(user)].")
			boutput(user, SPAN_ALERT("You pull the pin on [src]. You're not sure what that did, but you throw it anyway."))
			src.armed = TRUE
			src.add_fingerprint(user)
			user.drop_item()
			src.throw_at(get_turf(target), 10, 3)
		return

	attack_self(mob/user as mob)
		if (!isturf(user.loc))
			return
		if (!src.armed && user)
			message_admins("Grenade ([src]) primed at [log_loc(src)] by [key_name(user)].")
			logTheThing(LOG_COMBAT, user, "primes a grenade ([src.type]) at [log_loc(user)].")
			boutput(user, SPAN_ALERT("You pull the pin on [src]. You're not sure what that did. Maybe you should throw it?"))
			src.armed = TRUE
		return

	attack_hand(mob/user)
		if (!src.armed)
			..()
		else
			SPAWN(0.1 SECONDS)
				playsound(src.loc, 'sound/effects/bamf.ogg', 50, 1)
				if (old_light_grenade)
					for (var/obj/item/W in user)
						if (istype(W,/obj/item/clothing))
							user.u_equip(W)
							if (W)
								W.set_loc(user.loc)
								W.dropped(user)
								W.layer = initial(user.layer)
						else if (istype(W,/obj/item/old_grenade/light_gimmick))
							user.u_equip(W)
							if (W)
								W.set_loc(user.loc)
								W.dropped(user)
								W.layer = HUD_LAYER
						else
							qdel(W)
				else if (!issilicon(user)) //borgs could drop all their tools/internal items trying to pull one
					user.unequip_all()

				for (var/mob/N in viewers(user, null))
					if (GET_DIST(N, user) <= 6)
						N.flash(3 SECONDS)
				sleep(0.2 SECONDS)
				if (old_light_grenade)
					random_brute_damage(user, 200)
					sleep(1 DECI SECOND)
					if (isdead(user) || user.nodamage || isAI(user)) return
					logTheThing(LOG_COMBAT, user, "was killed by touching a [src] at [log_loc(src)].")
					if(user.client)
						var/mob/dead/observer/newmob
						newmob = new/mob/dead/observer(user)
						user.client.mob = newmob
						user.mind.transfer_to(newmob)
					qdel(user)
				else
					logTheThing(LOG_COMBAT, user, "was teleported by touching [src] ([src.type]) at [log_loc(src)].")
					if (destination)
						user.set_loc(destination)
					else
						user.set_loc(locate(40,19,2))
		return

	attackby(obj/item/W, mob/user)
		return

////////////////////////// Gimmick bombs /////////////////////////////////
ADMIN_INTERACT_PROCS(/obj/item/gimmickbomb, proc/arm, proc/detonate)
/obj/item/gimmickbomb
	name = "Don't spawn this directly!"
	icon = 'icons/obj/items/grenade.dmi'
	icon_state = ""
	var/armed = FALSE
	var/sound_explode = 'sound/effects/Explosion2.ogg'
	var/sound_beep = 'sound/machines/twobeep.ogg'
	var/is_dangerous = TRUE
	var/icon_state_armed = null
	tool_flags = TOOL_ASSEMBLY_APPLIER

	New()
		..()
		RegisterSignal(src, COMSIG_ITEM_ASSEMBLY_ITEM_SETUP, PROC_REF(assembly_setup))
		RegisterSignal(src, COMSIG_ITEM_ASSEMBLY_APPLY, PROC_REF(assembly_application))

	disposing()
		UnregisterSignal(src, COMSIG_ITEM_ASSEMBLY_ITEM_SETUP)
		UnregisterSignal(src, COMSIG_ITEM_ASSEMBLY_APPLY)
		..()

	/// ----------- Trigger/Applier/Target-Assembly-Related Procs -----------

	proc/assembly_setup(var/manipulated_grenade, var/obj/item/assembly/parent_assembly, var/mob/user, var/is_build_in)
		//since we have a lot of icons for grenades, but not for the assembly, we go, like with old assemblies, just with the custom chem grenade icon
		parent_assembly.applier_icon_prefix = "chem_grenade"

	proc/assembly_application(var/manipulated_grenade, var/obj/item/assembly/parent_assembly, var/obj/assembly_target)
		parent_assembly.invisibility = INVIS_ALWAYS_ISH
		parent_assembly.qdel_on_tear_apart = TRUE
		parent_assembly.expended = TRUE
		//why the fuck is do gimickbombs only vanish after 15 seconds, what the fuck?
		src.detonate()

	/// ----------------------------------------------

	proc/detonate()
		playsound(src.loc, sound_explode, 45, 1)

		var/obj/effects/explosion/E = new /obj/effects/explosion(get_turf(src))
		E.fingerprintslast = src.fingerprintslast

		invisibility = INVIS_ALWAYS_ISH
		SPAWN(15 SECONDS)
			qdel (src)

	proc/beep(i)
		var/k = i/2
		sleep(k*k)

		src.playbeep(src.loc, i, src.sound_beep)

		if(i>=0)
			src.beep(i-1)
		else
			src.detonate()

	proc/logGrenade(mob/user)
		var/area/A = get_area(src)
		if(!A.dont_log_combat && user)
			if(is_dangerous)
				message_admins("Grenade ([src]) primed at [log_loc(src)] by [key_name(user)].")
			logTheThing(LOG_COMBAT, user, "primes a grenade ([src.type]) at [log_loc(user)].")

	proc/arm(mob/user as mob)

		user.show_message(SPAN_ALERT("<B>You have armed the [src.name]!"))
		for(var/mob/O in viewers(user))
			if (O.client)
				O.show_message(SPAN_ALERT("<B>[user] has armed the [src.name]! Run!</B>"), 1)

		if (icon_state_armed)
			icon_state = icon_state_armed

		SPAWN(0)
			src.beep(10)

	proc/playbeep(var/atom/source, i as num, sound)
		var/soundin = sound
		var/vol = 40

		var/sound/S = sound(soundin)
		S.frequency = 32000 + ((10-i)*4000)
		S.wait = 0 //No queue
		S.channel = 0 //Any channel
		S.volume = vol
		S.priority = 0

		for (var/mob/M in range(world.view, source))
			if (M.client)
				if(isturf(source))
					var/dx = source.x - M.x
					S.pan = clamp(dx/8.0 * 100, -100, 100)
				M << S

	attack_self(mob/user as mob)
		if (user.equipped() == src && !src.armed)
			src.arm(user)
			logGrenade(user)
			armed = TRUE

	///Enforce a dress code upon victims
	proc/dress_up(mob/living/carbon/human/H, cant_self_remove=TRUE, cant_other_remove=FALSE)
		return 0

/obj/item/gimmickbomb/owlgib
	name = "Owl Bomb"
	desc = "Owls. Owls everywhere"
	icon_state = "owlbomb"
	sound_beep = 'sound/voice/animal/hoot.ogg'
	icon_state_armed = "owlbomb_beep"

	detonate()
		for(var/mob/living/carbon/human/M in range(5, get_turf(src)))
			var/area/t = get_area(M)
			if(t?.sanctuary) continue
			M.owlgib()
		..()

/obj/item/gimmickbomb/owlclothes
	name = "Owl Bomb"
	desc = "Owls. Owls everywhere"
	icon_state = "owlbomb"
	sound_beep = 'sound/voice/animal/hoot.ogg'
	icon_state_armed = "owlbomb_beep"

	dress_up(mob/living/carbon/human/H, cant_self_remove=TRUE, cant_other_remove=FALSE)
		if (!(H.wear_mask && istype(H.wear_mask, /obj/item/clothing/mask/owl_mask)))
			for(var/obj/item/clothing/O in H)
				if(!O.equipped_in_slot)
					continue
				H.u_equip(O)
				if (O)
					O.set_loc(H.loc)
					O.dropped(H)
					O.layer = initial(O.layer)

				var/obj/item/clothing/under/gimmick/owl/owlsuit = new /obj/item/clothing/under/gimmick/owl(H)
				owlsuit.cant_self_remove = cant_self_remove
				owlsuit.cant_other_remove = cant_other_remove
				var/obj/item/clothing/mask/owl_mask/owlmask = new /obj/item/clothing/mask/owl_mask(H)
				owlmask.cant_self_remove = cant_self_remove
				owlsuit.cant_other_remove = cant_other_remove

				H.equip_if_possible(owlsuit, SLOT_W_UNIFORM)
				H.equip_if_possible(owlmask, SLOT_WEAR_MASK)
				H.set_clothing_icon_dirty()

	detonate()
		var/mob/living/carbon/human/hero = src.get_hero()
		if(istype(hero))
			src.dress_up(hero, cant_self_remove=TRUE, cant_other_remove=TRUE)
			..()
			return

		for(var/mob/living/carbon/human/M in range(5, get_turf(src)))
			var/area/t = get_area(M)
			if(t?.sanctuary) continue
			src.dress_up(M)
		..()

/obj/item/gimmickbomb/hotdog
	name = "hotdog bomb"
	desc = "A hotdog bomb? What the heck does that even mean?!"
	icon_state = "hotdog"
	icon_state_armed = "hotdog_beep"

	dress_up(mob/living/carbon/human/H, cant_self_remove=TRUE, cant_other_remove=FALSE)
		if (!(H.wear_suit && istype(H.wear_suit, /obj/item/clothing/suit/gimmick/hotdog)))
			for(var/obj/item/clothing/O in H)
				if(!O.equipped_in_slot)
					continue
				H.u_equip(O)
				if (O)
					O.set_loc(H.loc)
					O.dropped(H)
					O.layer = initial(O.layer)

			var/obj/item/clothing/suit/gimmick/hotdog/suit = new /obj/item/clothing/suit/gimmick/hotdog(H)
			suit.cant_self_remove = cant_self_remove
			suit.cant_other_remove = cant_other_remove

			H.equip_if_possible(suit, SLOT_WEAR_SUIT)
			H.set_clothing_icon_dirty()
		..()

	detonate()
		var/mob/living/carbon/human/hero = src.get_hero()
		if(istype(hero))
			src.dress_up(hero, cant_self_remove=TRUE, cant_other_remove=TRUE)
			..()
			return
		for(var/mob/living/carbon/human/M in range(5, get_turf(src)))
			var/area/t = get_area(M)
			if(t?.sanctuary) continue
			src.dress_up(M)
		..()

/obj/item/gimmickbomb/gold
	name = "Gold Bomb"
	desc = "Why explode when you can gold!"
	icon_state = "goldbomb"
	icon_state_armed = "goldbomb1"
	sound_beep = 'sound/machines/twobeep.ogg'

	beep(i)
		var/k = i/2
		sleep(k*k)

		src.setMaterial(getMaterial("gold"))

		src.playbeep(src.loc, i, src.sound_beep)

		if (icon_state_armed)
			if (icon_state == src.icon_state)
				icon_state = icon_state_armed
			else
				icon_state = src.icon_state

		if(i>=0)
			src.beep(i-1)
		else
			src.detonate()

	detonate()
		for(var/turf/G in range(5, src))
			G.setMaterial(getMaterial("gold"))
		for(var/obj/item/I in range(5, src))
			I.setMaterial(getMaterial("gold"))
		for(var/obj/machinery/T in range(5, src))
			T.setMaterial(getMaterial("gold"))
		for(var/mob/living/carbon/human/M in range(3, src))
			var/area/t = get_area(M)
			if(t?.sanctuary) continue
			SPAWN(0)
				M.become_statue(getMaterial("gold"))
		..()


/obj/item/gimmickbomb/owlgib/prearmed
	armed = TRUE
	anchored = ANCHORED

	New()
		SPAWN(0)
			src.beep(10)
		return ..()

/obj/item/gimmickbomb/owlclothes/prearmed
	armed = TRUE
	anchored = ANCHORED

	New()
		SPAWN(0)
			src.beep(10)
		return ..()

//dummy type for compile
/obj/item/gimmickbomb/grenyanda/inert

/////////////////////////////// Fireworks ///////////////////////////////////////

/obj/item/firework
	name = "firework"
	desc = "A consumer-grade pyrotechnic, often used in celebrations."
	icon = 'icons/obj/items/items.dmi'
	icon_state = "firework"
	opacity = 0
	density = 0
	anchored = UNANCHORED
	force = 1
	throwforce = 1
	throw_speed = 1
	throw_range = 5
	w_class = W_CLASS_TINY
	var/det_time = 20
	stamina_damage = 5
	stamina_cost = 5
	stamina_crit_chance = 5
	var/slashed = FALSE // has it been emptied out? if so, better dud!
	var/primer_burnt = FALSE // avoid priming a firework multiple times, that doesn't make sense!
	var/primed = FALSE // cutting open lit fireworks is a BAD idea
	var/bootleg_level = 0 // 0 = normal, 1 = unstable, 2 = unstable and you arm fall off

	New()
		..()
		create_reagents(10)
		reagents.add_reagent("magnesium", 10)

	afterattack(atom/target as mob|obj|turf, mob/user as mob)
		if (user.equipped() == src)
			if (src.primer_burnt)
				boutput(user, SPAN_ALERT("You accidentally strike the primer, but it's already burnt!"))
				return

			else if (src.slashed)
				boutput(user, SPAN_ALERT("You accidentally prime the firework! [det_time/10] seconds!"))
				SPAWN( src.det_time )
					boutput(user, SPAN_ALERT("The firework probably should have exploded by now."))
					src.primer_burnt = TRUE
					return

			else if (user.bioHolder.HasEffect("clumsy"))
				boutput(user, SPAN_ALERT("Huh? How does this thing work?!"))
				src.primed = TRUE
				SPAWN( 5 )
					boom(user)
					return

			else
				boutput(user, SPAN_ALERT("You accidentally prime the firework! [det_time/10] seconds!"))
				src.primed = TRUE
				SPAWN( src.det_time )
					boom(user)
					return

	proc/boom(mob/user as mob)
		var/turf/location = get_turf(src.loc)

		if(location)
			if((prob(10)) || (src.bootleg_level == 2))
				explosion(src, location, 0, 0, 1, 1)

				if ((src.bootleg_level == 2) && (ishuman(user)))
					var/mob/living/carbon/human/H = user
					H.sever_limb(H.hand == LEFT_HAND ? "l_arm" : "r_arm") // copied from weapon_racks.dm

			else
				elecflash(src,power = 2)

				if (src.bootleg_level == 0)
					playsound(src.loc, 'sound/effects/Explosion1.ogg', 75, 1)
				else
					playsound(src.loc, 'sound/effects/Explosion2.ogg', 75, 1)

		src.visible_message(SPAN_ALERT("\The [src] explodes!"))

		qdel(src)

	attack_self(mob/user as mob)
		if (user.equipped() == src)
			if (src.primer_burnt)
				boutput(user, SPAN_ALERT("You can't light a firework more than once!"))
				return

			else if (src.slashed)
				boutput(user, SPAN_ALERT("You prime the firework! [det_time/10] seconds!"))
				SPAWN( src.det_time )
					boutput(user, SPAN_ALERT("The firework probably should have exploded by now. Fuck."))
					src.primer_burnt = TRUE
					return

			else if (user.bioHolder.HasEffect("clumsy"))
				boutput(user, SPAN_ALERT("Huh? How does this thing work?!"))
				src.primed = TRUE
				SPAWN( 5 )
					boom(user)
					return

			else
				boutput(user, SPAN_ALERT("You prime the firework! [det_time/10] seconds!"))
				src.primed = TRUE
				SPAWN( src.det_time )
					boom(user)
					return

	attackby(obj/A, mob/user) // adapted from iv_drips.dm
		if (iscuttingtool(A) && !(src.slashed) && !(src.primed))
			boutput(user, "You carefully cut [src] open and dump out the contents.")
			src.slashed = TRUE
			src.name = "empty [src.name]" // its empty now!
			src.desc = "[src.desc] It has been cut open and emptied out."

			make_cleanable(/obj/decal/cleanable/magnesiumpile, get_turf(src.loc)) // create magnesium pile
			src.reagents.clear_reagents() // remove magnesium from firework
			return

		else if (iscuttingtool(A) && !(src.slashed) && (src.primed)) // cutting open a lit firework is a bad idea!
			boutput(user, SPAN_ALERT("You cut open [src], but the lit primer ignites the contents!"))
			boom(user)
			return

		else if (iscuttingtool(A) && (src.slashed))
			boutput(user, "[src] has already been cut open and emptied.")
			return

/obj/item/firework/bootleg
	name = "bootleg firework"
	desc = "A consumer-grade pyrotechnic, often used in celebrations. This one seems to be missing a label, weird."

	New()
		..()
		create_reagents(10)

		if (prob(30))
			reagents.add_reagent("flashpowder", 5) // must've been a mix-up!

			if (prob(15))
				reagents.add_reagent("blackpowder", 5) // thats one hell of a mix-up
				src.bootleg_level = 2
			else
				reagents.add_reagent("flashpowder", 5) // this way every firework has 10u reagents
				src.bootleg_level = 1

		else
			reagents.add_reagent("magnesium", 10)

	afterattack(atom/target as mob|obj|turf, mob/user as mob)
		if (src.bootleg_level > 0)
			boutput(user, SPAN_ALERT("You accidentally prime the firework, and the contents ignite immediately!"))
			boom(user)
			return

		..()

	attack_self(mob/user as mob)
		if (src.bootleg_level > 0)
			boutput(user, SPAN_ALERT("You try to prime the firework, but the contents ignite immediately!"))
			boom(user)
			return

		..()

	attackby(obj/A, mob/user) // adapted from iv_drips.dm
		if (iscuttingtool(A) && !(src.slashed) && (src.bootleg_level > 0))
			boutput(user, "You try to cut [src] open, but the contents spontaneously ignite!")
			boom(user)
			return

		..()


#define ROMAN_CANDLE_UNLIT 0
#define ROMAN_CANDLE_LIT 1
#define ROMAN_CANDLE_BURNT 2

/obj/item/roman_candle
	name = "roman candle"
	desc = "Contains 10 exploding stars. Only use outdoors. Only point towards sky. All liability is waived."
	icon = 'icons/obj/items/sparklers.dmi'
	icon_state = "sparkler-off"
	inhand_image_icon = 'icons/obj/items/sparklers.dmi'
	item_state = "sparkler-off"
	w_class = W_CLASS_SMALL
	var/base_icon_state = "sparkler-"
	var/state = ROMAN_CANDLE_UNLIT
	var/charges = 10

/obj/item/roman_candle/New()
	. = ..()
	src.charges = rand(8,10) // cheap ass fireworks

/obj/item/roman_candle/attackby(obj/item/W, mob/user, params)
	if (src.state == ROMAN_CANDLE_UNLIT)
		if (isweldingtool(W) && W:try_weld(user,0,-1,0,0))
			src.light(user, SPAN_ALERT("<b>[user]</b> casually lights [src] with [W], what a badass."))

		else if (istype(W, /obj/item/clothing/head/cakehat) && W:on)
			src.light(user, SPAN_ALERT("Did [user] just light [his_or_her(user)] [src] with [W]? Holy Shit."))

		else if (istype(W, /obj/item/device/igniter))
			src.light(user, SPAN_ALERT("<b>[user]</b> fumbles around with [W]; sparks erupt from [src]."))

		else if (istype(W, /obj/item/device/light/zippo) && W:on)
			src.light(user, SPAN_ALERT("With a single flick of their wrist, [user] smoothly lights [src] with [W]. Damn they're cool."))

		else if ((istype(W, /obj/item/match) || istype(W, /obj/item/device/light/candle)) && W:on)
			src.light(user, SPAN_ALERT("<b>[user] lights [src] with [W]."))

		else if (W.burning)
			src.light(user, SPAN_ALERT("<b>[user]</b> lights [src] with [W]. Goddamn."))
	else
		return ..()

/obj/item/roman_candle/temperature_expose(datum/gas_mixture/air, temperature, volume)
	if((temperature > T0C+400))
		src.light(src.loc, SPAN_ALERT("\The [src] cooks off!"))
	..()

/obj/item/roman_candle/reagent_act(reagent_id, volume, datum/reagentsholder_reagents)
	if (src.state == ROMAN_CANDLE_LIT)
		if (reagent_id == "ff-foam" || reagent_id == "water" && volume >= 10)
			src.snuff(src.loc)
	. = ..()

/obj/item/roman_candle/process()
	if (src.state != ROMAN_CANDLE_LIT)
		processing_items -= src
		return

	var/turf/T = get_turf(src.loc)

	if (T)
		T.hotspot_expose(700,5)

	if (prob(66))
		var/direction = pick(alldirs)
		var/turf/location = src.loc
		if (ismob(location))
			var/mob/M = location
			if (M.find_in_hand(src))
				location = M.loc
				direction = M.dir
		src.shoot_firework(T, direction)

/obj/item/roman_candle/update_icon()
	. = ..()
	var/new_state = src.base_icon_state
	switch (src.state)
		if(ROMAN_CANDLE_UNLIT)
			new_state += "off"
		if(ROMAN_CANDLE_LIT)
			new_state += "on"
		if(ROMAN_CANDLE_BURNT)
			new_state += "burnt"
	src.icon_state = new_state
	src.item_state = new_state

/obj/item/roman_candle/proc/light(mob/user, message)
	if (!src) return
	if (src.state != ROMAN_CANDLE_UNLIT) return
	src.state = ROMAN_CANDLE_LIT
	logTheThing(LOG_STATION, user, "lights the [src] at [log_loc(src)].")
	src.hit_type = DAMAGE_BURN
	src.force = 3
	src.UpdateIcon()
	processing_items |= src
	if(istype(user))
		user.update_inhands()

/obj/item/roman_candle/proc/shoot_firework(turf/T, direction)
	var/datum/projectile/special/firework/firework = new
	shoot_projectile_ST_pixel_spread(src.loc, firework, get_step(src.loc, direction))
	src.charges--
	if (src.charges <= 0)
		src.snuff(src.loc)

/obj/item/roman_candle/proc/snuff(mob/user)
	if (!src) return
	if (src.state != ROMAN_CANDLE_LIT) return
	src.state = ROMAN_CANDLE_BURNT
	src.UpdateIcon()
	processing_items -= src
	if (istype(user))
		user.update_inhands()

#undef ROMAN_CANDLE_UNLIT
#undef ROMAN_CANDLE_LIT
#undef ROMAN_CANDLE_BURNT


//////////////////////// Breaching charges //////////////////////////////////

/obj/item/breaching_charge
	name = "Breaching Charge"
	icon = 'icons/obj/items/grenade.dmi'
	icon_state = "bcharge"
	var/armed = FALSE
	var/det_time = 50
	w_class = W_CLASS_SMALL
	item_state = "flashbang"
	throw_speed = 4
	throw_range = 20
	flags = TABLEPASS | CONDUCT
	c_flags = ONBELT
	var/expl_devas = 0
	var/expl_heavy = 0
	var/expl_light = 1
	var/expl_flash = 2
	var/expl_range = 1
	desc = "A timed device that releases a relatively strong concussive force, strong enough to destroy rock and metal."
	stamina_damage = 1
	stamina_cost = 1
	stamina_crit_chance = 0

	attack_hand(var/mob/user)
		if (src.armed)
			boutput(user, SPAN_ALERT("\The [src] is firmly anchored into place!"))
			return
		return ..()

	afterattack(atom/target as mob|obj|turf|area, mob/user as mob)
		if (user.equipped() == src)
			if (!src.armed)
				if (!src.check_placeable_target(target))
					return
				if (user.bioHolder && user.bioHolder.HasEffect("clumsy"))
					boutput(user, SPAN_ALERT("Huh? How does this thing work?!"))
					var/area/A = get_area(src)
					if(!A.dont_log_combat)
						logTheThing(LOG_COMBAT, user, "accidentally triggers [src] (clumsy bioeffect) at [log_loc(user)].")
					SPAWN(0.5 SECONDS)
						user.u_equip(src)
						src.boom()
						return
				else
					message_ghosts("[src] has been attached at [log_loc(target, ghostjump=TRUE)].")
					boutput(user, SPAN_ALERT("You slap the charge on [target], [det_time/10] seconds!"))
					user.visible_message(SPAN_ALERT("[user] has attached [src] to [target]."))
					src.icon_state = "bcharge2"
					user.u_equip(src)
					src.set_loc(get_turf(target))
					src.anchored = ANCHORED
					src.armed = TRUE

					// Yes, please (Convair880).
					var/area/A = get_area(src)
					if(!A.dont_log_combat)
						logTheThing(LOG_COMBAT, user, "attaches a [src] to [target] at [log_loc(target)].")

					SPAWN(src.det_time)
						if (src)
							src.boom()
						return
		return

	proc/boom()
		if (!src || !istype(src))
			return

		var/turf/location = get_turf(src)
		if (location && istype(location) && !location.loc:sanctuary)
			if (isrestrictedz(location.z))
				src.visible_message(SPAN_ALERT("[src] buzzes for a moment, then self-destructs."))
				elecflash(location)
				qdel(src)
				return

			location.hotspot_expose(700, 125)

			//Explosive effect for breaching charges only
			if (!(istype(src, /obj/item/breaching_charge/mining)))
				// NT charge shake
				if (expl_heavy)
					for(var/client/C in clients)
						if(C.mob && (C.mob.z == src.z))
							shake_camera(C.mob, 8, 24) // remove if this is too laggy
							playsound(C.mob, explosions.distant_sound, 70, 0)
							new /obj/effects/explosion (src.loc)
				else
					playsound(src.loc, pick(sounds_explosion), 75, 1)
					new/obj/effect/supplyexplosion(src.loc)
			else
				playsound(src.loc, 'sound/weapons/flashbang.ogg', 50, 1)

			explosion(src, location, src.expl_devas, src.expl_heavy, src.expl_light, src.expl_flash)
			// Breaching charges should be, you know, actually be decent at breaching walls and windows (Convair880).
			for (var/turf/simulated/wall/W in range(src.expl_range, location))
				if (W && istype(W) && !location.loc:sanctuary)
					W.ReplaceWithFloor()
			for (var/obj/O in range(src.expl_range, location))
				var/area/area = get_area(O)
				if (area?.sanctuary)
					continue
				if (istype(O, /obj/structure/girder))
					qdel(O)
					continue
				if (istype(O, /obj/window))
					var/obj/window/window = O
					if (prob(max(0, 100 - (window.health / 3))))
						window.smash()
					continue
				if (istype(O, /obj/mesh/grille))
					var/obj/mesh/grille/grille = O
					if (!grille.ruined)
						grille.ex_act(2)
					continue
				if (istype(O, /obj/machinery/door/firedoor))
					var/obj/machinery/door/firedoor/firelock = O
					qdel(firelock)
					continue
				if (istype(O, /obj/machinery/door))
					O.ex_act(1)
					continue
				if (istype(O, /obj/storage))
					O.ex_act(2)
					continue
		qdel(src)
		return

	proc/check_placeable_target(atom/A)
		if (A.plane == PLANE_HUD) //stop putting mining charges on your HUD buttons
			return FALSE
		if (!istype(A, /obj/item))
			return TRUE
		if (A.storage) // no blowing yourself up if you have full storage
			return FALSE
		return A.density

/obj/item/breaching_charge/NT
	name = "NanoTrasen Experimental EDF-7 Breaching Charge"
	expl_devas = 0
	expl_heavy = 1
	expl_light = 4
	expl_flash = 10
	expl_range = 2
	stamina_damage = 1
	stamina_cost = 1
	stamina_crit_chance = 0

/obj/item/breaching_charge/thermite
	name = "Thermite Breaching Charge"
	desc = "When applied to a wall, causes a thermite reaction which totally destroys it."
	c_flags = ONBELT
	object_flags = NO_GHOSTCRITTER
	w_class = W_CLASS_TINY
	expl_range = 2

	afterattack(atom/target as mob|obj|turf|area, mob/user as mob)
		if (user.equipped() == src)
			if (!src.armed)
				if (istype(target, /obj/item/storage)) // no blowing yourself up if you have full backpack
					return
				if (user.bioHolder && user.bioHolder.HasEffect("clumsy"))
					boutput(user, SPAN_ALERT("Huh? How does this thing work?!"))
					var/area/A = get_area(src)
					if(!A.dont_log_combat)
						logTheThing(LOG_COMBAT, user, "accidentally triggers [src] (clumsy bioeffect) at [log_loc(user)].")
					SPAWN(0.5 SECONDS)
						user.u_equip(src)
						src.boom()
						return
				else
					message_ghosts("[src] has been attached at [log_loc(target, ghostjump=TRUE)].")
					boutput(user, SPAN_ALERT("You slap the charge on [target], [det_time/10] seconds!"))
					user.visible_message(SPAN_ALERT("[user] has attached [src] to [target]."))
					src.icon_state = "bcharge2"
					user.u_equip(src)
					src.set_loc(get_turf(target))
					src.anchored = ANCHORED
					src.armed = TRUE

					// Yes, please (Convair880).
					var/area/A = get_area(src)
					if(!A.dont_log_combat)
						logTheThing(LOG_COMBAT, user, "attaches a [src] to [target] at [log_loc(target)].")

					SPAWN(src.det_time)
						if (src)
							src.boom()
		return

	boom()
		if (!src || !istype(src))
			return

		var/turf/location = get_turf(src.loc)
		if (location && istype(location))
			if (isrestrictedz(location.z))
				src.visible_message(SPAN_ALERT("[src] buzzes for a moment, then self-destructs."))
				elecflash(location)
				qdel(src)
				return

			playsound(location, 'sound/effects/bamf.ogg', 100, 0.5)
			src.invisibility = INVIS_ALWAYS

			for (var/turf/T in range(src.expl_range, location))
				if( T?.loc:sanctuary ) continue
				if (!istype(T, /turf/simulated/wall) && !istype(T, /turf/simulated/floor))
					continue


				var/distance = GET_DIST(T, location)
				if (distance < 2)
					var/turf/simulated/floor/F = null

					if (istype(T, /turf/simulated/wall/auto/feather))
						var/turf/simulated/wall/auto/feather/flockwall = T
						flockwall.takeDamage("fire", 1)
						if (flockwall.health <= 0)
							flockwall.destroy()
					else if (istype(T, /turf/simulated/wall))
						var/turf/simulated/wall/W = T
						F = W.ReplaceWithFloor()
					else if (istype(T, /turf/simulated/floor/))
						F = T

					if (F && istype(F))
						F.to_plating()
						F.burn_tile()

			for (var/obj/machinery/door/DR in src.loc)
				var/area/a = get_area(DR)
				if (!DR.cant_emag && !a.sanctuary)
					DR.take_damage(DR.health)

			for (var/obj/O in range(src.expl_range, location))
				var/area/area = get_area(O)
				if (area?.sanctuary)
					continue
				if (istype(O, /obj/structure/girder))
					qdel(O)
					continue
				if (istype(O, /obj/window))
					var/obj/window/window = O
					if (prob(max(0, 100 - (window.health / 3))))
						window.damage_heat(500)
					continue
				if (istype(O, /obj/mesh/grille))
					var/obj/mesh/grille/grille = O
					if (!grille.ruined)
						grille.damage_heat(500)
					continue
				if (istype(O, /obj/machinery/door/firedoor))
					var/obj/machinery/door/firedoor/firelock = O
					qdel(firelock)
					continue

			// placed here so that fire appears in place of destroyed turfs
			fireflash(location, src.expl_range, 2000, checkLos = FALSE, chemfire = CHEM_FIRE_DARKRED)

			for (var/mob/living/M in range(src.expl_range, location))
				if(check_target_immunity(M)) continue
				var/damage = 30 / (GET_DIST(M, src) + 1)
				M.TakeDamage("chest", 0, damage)
				M.update_burning(damage)

			SPAWN(10 SECONDS)
				qdel(src)
		else
			qdel(src)

		return

//////////////////////////////////////////
// PIPE BOMBS (INCLUDES CONSTRUCTION)
//////////////////////////////////////////

/obj/item/pipebomb
	icon = 'icons/obj/items/assemblies.dmi'
	item_state = "r_hands"
	duration_put = 0.5 SECONDS //crime

/obj/item/pipebomb/frame
	name = "pipe frame"
	desc = "Two small pipes joined together with grooves cut into the side."
	icon_state = "Pipe_Frame"
	burn_possible = FALSE
	material_amt = 0.3
	HELP_MESSAGE_OVERRIDE("") // so there's the verb and stuff, actual message provided below
	var/state = 1
	var/strength = 5
	var/list/item_mods = new/list() //stuff something into one or both of the pipes to change the finished product
	var/list/allowed_items = list(/obj/item/device/light/glowstick, /obj/item/clothing/head/butt, /obj/item/paper, /obj/item/reagent_containers/food/snacks/ingredient/meat,\
	 							/obj/item/reagent_containers/food/snacks/ectoplasm, /obj/item/scrap, /obj/item/raw_material/scrap_metal, /obj/item/cell,/obj/item/cable_coil,\
	 							/obj/item/item_box/medical_patches, /obj/item/item_box/gold_star, /obj/item/item_box/assorted/stickers, /obj/item/material_piece/cloth,\
	 							/obj/item/raw_material/shard, /obj/item/raw_material/telecrystal, /obj/item/instrument, /obj/item/reagent_containers/food/snacks/ingredient/butter,\
	 							/obj/item/rcd_ammo, /obj/item/raw_material/plasmastone, /obj/item/material_piece/plasmastone)

	get_help_message(dist, mob/user)
		switch(src.state)
			if (1) // Default state
				return "You can use a <b>welding tool</b> to hollow out the frame."
			if (2) // Hollowed out
				return "You can add fuel to begin making a pipebomb, a staple gun to create a zip gun, a pipe frame to create a slam gun, or use <b>wirecutters</b> to create hollow pipe hulls."
			if (3) // Hollowed out with chem inside
				return "You can add a cable coil to continue making a pipebomb."
			if (4) // Hollowed out Pipeshot
				return "You can add fuel and glass shards or scrap to make pipeshot."

	attack_self(mob/user as mob)
		if (state == 3)
			if(tgui_alert(user, "Pour out the pipebomb reagents?", "Empty reagents", list("Yes", "No")) != "Yes")
				return
			boutput(user, SPAN_NOTICE("The reagents inside spill out!"))
			src.reagents = null
			state = 2
		return

	New()
		. = ..()
		// unwelded frame + welder -> hollow frame
		src.AddComponent(/datum/component/assembly, TOOL_WELDING, PROC_REF(pipeframe_welding), FALSE)
		// unwelded frame + hollow frame -> slamgun
		src.AddComponent(/datum/component/assembly, /obj/item/pipebomb/frame, PROC_REF(slamgun_crafting), TRUE)

	// Pipebomb/shot assembly procs

	/// Pipeframe welding proc
	proc/pipeframe_welding(var/atom/to_combine_atom, var/mob/user)
		if(!to_combine_atom:try_weld(user, 1))
			return FALSE
		boutput(user, SPAN_NOTICE("You hollow out the pipe."))
		src.state = 2
		src.icon_state = "Pipe_Hollow"
		src.desc = "Two small pipes joined together. The pipes are empty."
		if (src.material)
			src.name = "hollow [src.material.getName()] pipe frame"
		else
			src.name = "hollow pipe frame"
		src.flags |= NOSPLASH
		//Since we changed the state, remove all assembly components and add the next state ones
		src.RemoveComponentsOfType(/datum/component/assembly)
		// hollow frame + cutters  -> unfilled pipeshot
		src.AddComponent(/datum/component/assembly, TOOL_SNIPPING, PROC_REF(pipeshot_crafting), FALSE)
		// hollow frame + *stuff*  -> hollow frame + pipebomb special effects
		src.AddComponent(/datum/component/assembly, src.allowed_items, PROC_REF(pipebomb_stuffing), TRUE)
		// hollow frame + staple gun  -> zipgun
		src.AddComponent(/datum/component/assembly, /obj/item/staple_gun, PROC_REF(zipgun_crafting), TRUE)
		// hollow frame + fuel  -> unwired pipebombs
		src.AddComponent(/datum/component/assembly, list(/obj/item/reagent_containers/glass, /obj/item/reagent_containers/food/drinks,), PROC_REF(pipebomb_filling), FALSE)
		// Since the assembly was done, return TRUE
		return TRUE

	/// Zipgun crafting proc
	proc/zipgun_crafting(var/atom/to_combine_atom, var/mob/user)
		user.show_text("You combine [to_combine_atom] and [src]. This looks pretty unsafe!")
		user.u_equip(to_combine_atom)
		user.u_equip(src)
		playsound(src, 'sound/items/Deconstruct.ogg', 50, TRUE)
		var/obj/item/gun/kinetic/zipgun/new_gun = new/obj/item/gun/kinetic/zipgun
		user.put_in_hand_or_drop(new_gun)
		qdel(to_combine_atom)
		qdel(src)

	/// Slamgun crafting proc
	proc/slamgun_crafting(var/atom/to_combine_atom, var/mob/user)
		var/obj/item/pipebomb/frame/other_frame = to_combine_atom
		if(other_frame.state == 2) // the other pipe needs to be welded
			user.u_equip(src)
			user.u_equip(to_combine_atom)
			playsound(src, 'sound/items/Deconstruct.ogg', 50, TRUE)
			var/obj/item/gun/kinetic/slamgun/S = new/obj/item/gun/kinetic/slamgun
			user.put_in_hand_or_drop(S)
			qdel(to_combine_atom)
			qdel(src)
			// Since the assembly was done, return TRUE
			return TRUE

	///pipeshot crafting proc
	proc/pipeshot_crafting(var/atom/to_combine_atom, var/mob/user)
		src.name = "hollow pipe hulls"
		boutput(user, SPAN_NOTICE("You cut the pipe into four neat hulls."))
		src.state = 4
		src.icon_state = "Pipeshot"
		src.desc = "Four open pipe shells. They're currently empty."
		//Since we changed the state, remove all assembly components and add the next state ones
		src.RemoveComponentsOfType(/datum/component/assembly)
		// unfilled pipeshot + fuel  -> filled pipeshot
		src.AddComponent(/datum/component/assembly, list(/obj/item/reagent_containers/glass, /obj/item/reagent_containers/food/drinks,), PROC_REF(pipeshot_filling), FALSE)
		// Since the assembly was done, return TRUE
		return TRUE

	/// Pipebomb special effect filling proc
	proc/pipebomb_stuffing(var/atom/to_combine_atom, var/mob/user)
		var/obj/item/stuffable_item = to_combine_atom
		if (length(item_mods) < 3)
			boutput(user, SPAN_NOTICE("You stuff [stuffable_item] into the [length(item_mods) == 0 ? "first" : "second"] pipe."))
			item_mods += stuffable_item
			user.u_equip(stuffable_item)
			stuffable_item.set_loc(src)
			//once we begun stuffing items in the frame, only pipebombs are the way to go
			if (length(item_mods) == 1)
				src.RemoveComponentsOfType(/datum/component/assembly)
				// hollow frame + *stuff*  -> hollow frame + pipebomb special effects
				src.AddComponent(/datum/component/assembly, src.allowed_items, PROC_REF(pipebomb_stuffing), TRUE)
				// hollow frame + fuel  -> unwired pipebombs
				src.AddComponent(/datum/component/assembly, list(/obj/item/reagent_containers/glass, /obj/item/reagent_containers/food/drinks,), PROC_REF(pipebomb_filling), FALSE)
			// Since the assembly was done, return TRUE
			return TRUE
		else
			boutput(user, SPAN_NOTICE("There are already too many items in the frame."))

	/// Pipebomb fuel filling proc
	proc/pipebomb_filling(var/atom/to_combine_atom, var/mob/user)
		//There is less room for explosive material when you use item mods
		var/obj/item/reagent_containers/filling_glass = to_combine_atom
		var/max_allowed = 20
		if(filling_glass.reagents.total_volume < max_allowed)
			boutput(user, SPAN_NOTICE("There is not enough chemicals in [filling_glass] to fill the frame."))
		else
			src.state = 3
			var/avg_volatility = 0
			src.reagents = new /datum/reagents(max_allowed)
			src.reagents.my_atom = src
			filling_glass.reagents.trans_to(src, max_allowed)
			boutput(user, SPAN_NOTICE("You fill the pipe with [src.reagents.total_volume] units of the reagents."))
			for (var/id in src.reagents.reagent_list)
				var/datum/reagent/R = src.reagents.reagent_list[id]
				avg_volatility += R.volatility * R.volume / src.reagents.maximum_volume

			qdel(src.reagents)
			src.reagents = null
			if (avg_volatility < 1) // B A D.
				src.strength = 0
			else
				src.strength *= avg_volatility

			src.icon_state = "Pipe_Filled"
			src.state = 3
			src.desc = "Two small pipes joined together. The pipes are filled."

			if (src.material)
				src.name = "filled [src.material.getName()] pipe frame"
			else
				src.name = "filled pipe frame"
			//Since we changed the state, remove all assembly components and add the next state ones
			src.RemoveComponentsOfType(/datum/component/assembly)
			// cables + unwired pipebomb -> wired pipebomb
			src.AddComponent(/datum/component/assembly, /obj/item/cable_coil, PROC_REF(pipebomb_cabling), TRUE)

		// We return true here even if the volatility was not high enough, so we don't spill chemicals on the frame for no reason
		// Since the assembly was done, return TRUE
		return TRUE

	/// Pipeshot fuel filling proc
	proc/pipeshot_filling(var/atom/to_combine_atom, var/mob/user)
		var/obj/item/reagent_containers/filling_glass = to_combine_atom
		var/amount = 20
		var/avg_volatility = 0
		if(filling_glass.reagents.total_volume < amount)
			boutput(user, SPAN_NOTICE("There is not enough chemicals in [filling_glass] to fill [src]."))
			//since we don't want to spill on the frame, still return true
		else
			for (var/id in to_combine_atom.reagents.reagent_list)
				var/datum/reagent/R = to_combine_atom.reagents.reagent_list[id]
				avg_volatility += R.volatility
			avg_volatility /= length(to_combine_atom.reagents.reagent_list)

			if (avg_volatility < 1) // invalid ingredients/concentration
				boutput(user, SPAN_NOTICE("You realize that the contents of [filling_glass] aren't actually all too explosive and decide not to pour it into the [src]."))
			else
				//consume the reagents
				src.reagents = new /datum/reagents(amount)
				src.reagents.my_atom = src
				filling_glass.reagents.trans_to(src, amount)
				qdel(src.reagents)
				//make the hulls
				boutput(user, SPAN_NOTICE("You add some propellant to the hulls."))
				new /obj/item/pipehulls(get_turf(src))
				qdel(src)
		// Since the assembly was done, return TRUE
		// We return true here even if the volatility was not high enough, so we don't spill chemicals on the frame for no reason
		return TRUE

	/// Pipebomb cabling proc
	proc/pipebomb_cabling(var/atom/to_combine_atom, var/mob/user)
		var/obj/item/cable_coil/used_cables = to_combine_atom
		if(used_cables.amount >= 3)
			boutput(user, SPAN_NOTICE("You link the cable, fuel and pipes."))
			var/turf/target_turf = get_turf(src)
			var/obj/item/pipebomb/bomb/complete_bomb = new /obj/item/pipebomb/bomb(target_turf)
			complete_bomb.strength = src.strength
			if (src.material)
				complete_bomb.setMaterial(src.material)
			//add properties from item mods to the finished pipe bomb
			complete_bomb.set_up_special_ingredients(src.item_mods)
			user.u_equip(src)
			qdel(src)
			used_cables.change_stack_amount(-3)
			user.put_in_hand_or_drop(complete_bomb)
		else
			boutput(user, SPAN_NOTICE("You need more cables for this step."))
		// Since the assembly was done, return TRUE
		return TRUE


/obj/item/pipebomb/bomb
	name = "pipe bomb"
	desc = "An improvised explosive made primarily out of two pipes. It needs some kind of ignition switch."
	icon_state = "Pipe_Wired"
	contraband = 4

	var/strength = 5
	var/is_dangerous = TRUE

	var/glowsticks = 0
	var/butt = 0
	var/confetti = 0
	var/meat = 0
	var/ghost = 0
	var/extra_shrapnel = 0
	var/charge = 0
	var/cable = 0
	var/bleed = 0
	var/tele = 0
	var/sound_effect = 0
	var/rcd = 0
	var/plasma = 0
	var/rcd_mat = "steel"
	//if it contains reagents, those will be splashed on the floor

	var/list/throw_objs = new /list()


	/// This proc handles the addition of special effects to the pipebomb. Pass a list with the items to items_to_account for this
	proc/set_up_special_ingredients(var/list/items_to_account)
		if(length(items_to_account) > 0)
			src.name = "modified pipe bomb"
		else
			return
		for (var/checked_item in items_to_account)
			if (istype(checked_item, /obj/item/device/light/glowstick))
				src.glowsticks += 1
			if (istype(checked_item, /obj/item/clothing/head/butt))
				src.butt += 1
			if (istype(checked_item, /obj/item/paper))
				src.confetti += 1
			if (istype(checked_item, /obj/item/reagent_containers/food/snacks/ingredient/meat))
				src.meat += 1
			if (istype(checked_item, /obj/item/reagent_containers/food/snacks/ectoplasm))
				src.ghost += 1
			if (istype(checked_item, /obj/item/scrap) || istype(checked_item,/obj/item/raw_material/scrap_metal))
				src.extra_shrapnel += 1
			if (istype(checked_item,/obj/item/cable_coil))
				src.cable += 1
			if (istype(checked_item, /obj/item/cell))
				var/obj/item/cell/C = checked_item
				src.charge += C.charge
				if (C.rigged || istype(checked_item, /obj/item/cell/erebite))
					src.strength += 3
			if (istype(checked_item, /obj/item/material_piece/cloth))
				src.strength = src.strength / 5
			if (istype(checked_item, /obj/item/raw_material/shard))
				var/obj/item/raw_material/shard/S = checked_item // fix for duplication glitch because someone may have forgot to assign M to S, whoops!
				src.bleed += 1
				if (S && (S.material.hasProperty("hard") || istype(S, /obj/item/raw_material/shard/plasmacrystal)))
					src.bleed += 1
			if (istype(checked_item, /obj/item/raw_material/telecrystal))
				src.tele += 2
			if (istype(checked_item, /obj/item/instrument))
				var/obj/item/instrument/R = checked_item
				src.sound_effect = islist(R.sounds_instrument) ? pick(R.sounds_instrument) : R.sounds_instrument
			if (istype(checked_item, /obj/item/reagent_containers/food/snacks/ingredient/butter))
				if (!src.reagents)
					var/datum/reagents/R = new/datum/reagents(20)
					src.reagents = R
				src.reagents.add_reagent("water", 5)
			if (istype(checked_item, /obj/item/rcd_ammo))
				src.rcd += 1
				if (istype(checked_item, /obj/item/rcd_ammo/big))
					src.rcd += 1
			if (istype(checked_item, /obj/item/item_box/medical_patches) || istype(checked_item,/obj/item/item_box/gold_star))
				var/obj/item/item_box/B = checked_item
				src.throw_objs += B.contained_item
			if (istype(checked_item, /obj/item/item_box/assorted/stickers))
				var/obj/item/item_box/assorted/B = checked_item
				src.throw_objs += B.contained_items
			if (istype(checked_item, /obj/item/material_piece/plasmastone) || istype(checked_item, /obj/item/raw_material/plasmastone))
				src.plasma += 1

	ex_act(severity)
		do_explode()
		. = ..()

	proc/do_explode()
		if (src.strength)
			if (src.material)
				var/strength_mult = 1
				if (findtext(material.getID(), "erebite"))
					strength_mult = 2
				else if (findtext(material.getID(), "plasmastone"))
					strength_mult = 1.25
				src.strength *= strength_mult

			///Explosion center point
			var/turf/origin = get_turf(src.loc)

			///Mob who is diving on the bomb
			var/mob/living/carbon/human/hero = src.get_hero()

			//do mod effects : pre-explosion
			if (glowsticks)
				make_cleanable( /obj/decal/cleanable/generic,origin)
				var/radium_amt = 6 * glowsticks
				if (istype(hero))
					hero.reagents.add_reagent("radium", 10 * radium_amt, null, T0C + 300)
				else // leave a radium puddle instead
					for (var/turf/splat in view(1,origin))
						make_cleanable( /obj/decal/cleanable/greenglow,splat)
					for (var/mob/M in view(3,origin))
						if(iscarbon(M))
							if (M.reagents)
								M.reagents.add_reagent("radium", radium_amt, null, T0C + 300)
						boutput(M, SPAN_ALERT("You are splashed with hot green liquid!"))
			if (butt)
				if (butt > 1)
					playsound(origin, 'sound/voice/farts/superfart.ogg', 90, 1, channel=VOLUME_CHANNEL_EMOTE)
				else
					playsound(origin, 'sound/voice/farts/poo2.ogg', 90, 1, channel=VOLUME_CHANNEL_EMOTE)
				for (var/mob/M in view(istype(hero) ? 1 : 3 + butt,origin))
					ass_explosion(M, 0, 5)
			if (confetti)
				if (confetti > 1)
					particleMaster.SpawnSystem(new /datum/particleSystem/confetti_more(origin))
				else
					particleMaster.SpawnSystem(new /datum/particleSystem/confetti(origin))
			if (meat)
				if (meat > 1)
					gibs(origin)
				for (var/turf/splat in view(meat,origin))
					make_cleanable( /obj/decal/cleanable/blood,splat)
			if (ghost) //throw objects towards bomb center
				if (ghost > 1)
					for (var/mob/M in view(2+ghost,origin))
						if(iscarbon(M))
							boutput(M, SPAN_ALERT("You are yanked by an unseen force!"))
							var/yank_distance = 1
							if (prob(50))
								yank_distance = 2
							M.throw_at(origin, yank_distance, 2)
				for (var/obj/O in view(1,origin))
					O.throw_at(origin, 2, 2)
			if (extra_shrapnel)
				throw_shrapnel(origin, 4, extra_shrapnel * (istype(hero) ? 1 : 3))
			if (cable && charge) //arc flash
				var/target_count = 0
				for (var/mob/living/L in view(5, origin))
					target_count++
				if (target_count)
					for (var/mob/living/L in oview(5, origin))
						// reducing range increases impact, reduce mob shock intensity instead
						arcFlash(src, L, max((charge*7) / (target_count * (istype(hero) ? 2 : 1)), 1))
				else
					for (var/turf/T in oview(3,origin))
						if (prob(2))
							arcFlashTurf(src, T, max((charge*6) * rand(),1))
			if (bleed)
				for (var/mob/M in view(istype(hero) ? 1 : 3,origin))
					take_bleeding_damage(M, null, bleed * 3, DAMAGE_CUT)
			if (src.reagents)
				if (istype(hero))
					src.reagents.trans_to_direct(hero, src.reagents.total_volume / 2)
				for (var/turf/T in oview(1+ round(src.reagents.total_volume * 0.12), origin))
					src.reagents.reaction(T,1,5)

			if (istype(hero))
				hero.ex_act(1, src, src.strength)
				src.strength = max((src.strength * 0.75), (src.strength - 3))

			src.blowthefuckup(src.strength, 0)

			//do mod effects : post-explosion
			if (tele)
				for (var/mob/M in view(4,origin))
					if(isturf(M.loc) && !isrestrictedz(M.loc.z))
						var/turf/warp_to = get_turf(pick(orange(3 * tele, M.loc)))
						if (isturf(warp_to))
							playsound(M.loc, "warp", 50, 1)
							M.visible_message(SPAN_ALERT("[M] is warped away!"))
							boutput(M, SPAN_ALERT("You suddenly teleport ..."))
							M.set_loc(warp_to)
			if (rcd)
				playsound(origin, 'sound/items/Deconstruct.ogg', 70, TRUE)
				for (var/turf/T in view(rcd,origin))
					if (istype(T, /turf/space))
						var/turf/simulated/floor/F = T:ReplaceWithFloor()
						F.setMaterial(getMaterial(rcd_mat))
				if (rcd > 1)
					for (var/turf/T in view(3,origin))
						if (prob(rcd * 10))
							new /obj/mesh/grille/steel(T)

			if (plasma)
				for (var/turf/simulated/floor/target in range(1,origin))
					if(!target.gas_impermeable && target.air)
						if(target.parent?.group_processing)
							target.parent.suspend_group_processing()

						var/datum/gas_mixture/payload = new /datum/gas_mixture
						payload.toxins = plasma * 100
						payload.temperature = T20C
						payload.volume = R_IDEAL_GAS_EQUATION * T20C / 1000
						target.air.merge(payload)

			if (throw_objs.len && length(throw_objs) > 0)
				var/count = 20
				var/obj/spawn_item
				for (var/mob/living/L in oview(5, origin))
					spawn_item = pick(throw_objs)
					var/obj/O = new spawn_item(origin)
					if (istype(O,/obj/item/reagent_containers/patch))
						var/obj/item/reagent_containers/patch/P = O
						P.good_throw = 1
					O.throw_at(L, istype(hero) ? 2 : 5, 3) // thrown short of far targets
					count--
				if (count > 0)
					for (var/turf/target in oview(4,origin))
						if (prob(4))
							spawn_item = pick(throw_objs)
							var/obj/O = new spawn_item(origin)
							if (istype(O,/obj/item/reagent_containers/patch))
								var/obj/item/reagent_containers/patch/P = O
								P.good_throw = 1
							O.throw_at(target, istype(hero) ? 2 : 4, 3) // thrown short of far targets
							count--
						if (count <= 0)
							break;

			qdel(src)
		else
			visible_message(SPAN_ALERT("[src] sparks and emits a small cloud of smoke, crumbling into a pile of dust."))
			qdel(src)


/obj/item/pipebomb/bomb/miniature_syndicate
	name = "pipe bomb"
	desc = "This pipe bomb seems funny. You can hear muffled tiny screams inside. It needs some kind of ignition switch."
	icon_state = "Pipe_Wired_Syndicate"
	strength = 1
	var/how_many_miniatures = 4

	do_explode()
		for (var/i = 1, i <= how_many_miniatures, i++)
			var/obj/critter/gunbot/drone/miniature_syndie/O = new /obj/critter/gunbot/drone/miniature_syndie(get_turf(src))
			var/atom/target = get_edge_target_turf(src, pick(alldirs))
			O.throw_at(target,4,3)
		..()

/obj/item/pipebomb/bomb/engineering
	name = "controlled demolition pipe"
	desc = "A weak explosive designed to blast open holes in the sea floor. It needs some kind of ignition switch."
	icon_state = "Pipe_Wired_Yellow"
	strength = 1
	is_dangerous = FALSE

	on_blowthefuckup(strength) //always blow hole!
		..(strength)
		if (istype(get_turf(src),/turf/space/fluid))
			var/turf/space/fluid/T = get_turf(src)
			T.blow_hole()

/obj/effects/explosion/tiny_baby
	New()
		..()
		src.transform = matrix(0.5, MATRIX_SCALE)

/obj/proc/on_blowthefuckup(strength)
	new /obj/effects/explosion/tiny_baby (get_turf(src))
	src.material_trigger_on_temp(T0C + strength * 100)
	src.material_trigger_on_explosion(1)

/obj/item/pipebomb/bomb/on_blowthefuckup(strength)
	..()

/obj/proc/throw_shrapnel(var/T, var/sqstrength, var/shrapnel_range)
	for (var/mob/living/carbon/human/M in view(T, shrapnel_range))
		if(check_target_immunity(M)) continue
		M.TakeDamage("chest", 15/M.get_ranged_protection(), 0)
		if (M.get_ranged_protection()>=1.5)
			boutput(M, SPAN_ALERT("<b>Your armor blocks the shrapnel!</b>"))
		else
			var/obj/item/implant/projectile/shrapnel/implanted = new /obj/item/implant/projectile/shrapnel
			implanted.implanted(M, null, 25 * sqstrength)
			boutput(M, SPAN_ALERT("<b>You are struck by shrapnel!</b>"))
			if (!M.stat)
				M.emote("scream")


/turf/proc/throw_shrapnel(var/T, var/sqstrength, var/shrapnel_range)
	for (var/mob/living/carbon/human/M in view(T, shrapnel_range))
		if(check_target_immunity(M)) continue
		M.TakeDamage("chest", 15/M.get_ranged_protection(), 0)
		if (M.get_ranged_protection()>=1.5)
			boutput(M, SPAN_ALERT("<b>Your armor blocks the shrapnel!</b>"))
		else
			var/obj/item/implant/projectile/shrapnel/implanted = new /obj/item/implant/projectile/shrapnel
			implanted.implanted(M, null, 25 * sqstrength)
			boutput(M, SPAN_ALERT("<b>You are struck by shrapnel!</b>"))
			if (!M.stat)
				M.emote("scream")

/obj/proc/blowthefuckup(var/strength = 1, var/delete = 1) // dropping this to object-level so that I can use it for other things
	var/T = get_turf(src)
	src.visible_message(SPAN_ALERT("[src] explodes!"))
	var/sqstrength = sqrt(strength)
	var/shrapnel_range = 3 + sqstrength
	if (strength >= 1)
		src.throw_shrapnel(T, sqstrength, shrapnel_range)
	on_blowthefuckup(strength)

	explosion_new(src, T, strength, 1)
	if (delete)
		qdel(src)

/mob/proc/blowthefuckup(var/strength = 1,var/visible_message = 1) // similar proc for mobs
	var/T = get_turf(src)
	if(visible_message) src.visible_message(SPAN_ALERT("[src] explodes!"))
	var/sqstrength = sqrt(strength)
	var/shrapnel_range = 3 + sqstrength
	for (var/mob/living/carbon/human/M in view(T, shrapnel_range))
		if(check_target_immunity(M)) continue
		if (M != src)
			M.TakeDamage("chest", 15/M.get_ranged_protection(), 0)
			if (M.get_ranged_protection()>=1.5)
				boutput(M, SPAN_ALERT("<b>Your armor blocks the chunks of [src.name]!</b>"))
			else
				var/obj/item/implant/projectile/shrapnel/implanted = new /obj/item/implant/projectile/shrapnel
				implanted.implanted(M, null, 25 * sqstrength)
				boutput(M, SPAN_ALERT("<b>You are struck by chunks of [src.name]!</b>"))
				if (!M.stat)
					M.emote("scream")

	explosion_new(src, T, strength, 1)
	src.gib()

/turf/proc/blowthefuckup(var/strength = 1, var/delete = 1) // simulate spalling damage. could use a new sprite though
	var/T = get_turf(src)
	src.visible_message(SPAN_ALERT("[src] explodes!"))
	var/sqstrength = sqrt(strength)
	var/shrapnel_range = 3 + sqstrength
	if (strength >= 1)
		src.throw_shrapnel(T, sqstrength, shrapnel_range)
	new /obj/effects/explosion/tiny_baby (src.loc)
	explosion_new(src, T, strength, 1)
	if (delete)
		qdel(src)

///Pick one human trying to cover the object
/obj/item/proc/get_hero()
	if (!istype(src.loc, /turf)) // must be on the floor/tile directly
		return null
	var/turf/origin = src.loc
	var/list/sacrifices = list()
	for (var/mob/living/carbon/human/H in origin.contents)
		// The deliberate act of using one's body to cover a live time-fused hand grenade
		if(isalive(H) && H.lying && H.hasStatus("blocking"))
			sacrifices.Add(H)
	if (!length(sacrifices))
		return null
	var/mob/living/carbon/human/hero = pick(sacrifices)
	if (istype(hero))
		src.visible_message(SPAN_COMBAT("<B>[hero] dives onto [src], covering it with [his_or_her(hero)] body!</B>"))
	return hero
