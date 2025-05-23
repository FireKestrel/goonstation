/datum/abilityHolder/revenant
	topBarRendered = 1
	usesPoints = 1
	cast_while_dead = 1
	var/channeling = 0

	var/datum/bioEffect/hidden/revenant/revenant = null
	pointName = "Wraith Points"

	generatePoints(var/mult = 1)
		if (relay)
			relay.generatePoints(mult)

	deductPoints(cost)
		if (relay)
			return relay.deductPoints(cost)
		return 1

	pointCheck(cost, quiet = FALSE)
		if (!relay)
			return 1
		if (!relay.usesPoints)
			return 1
		if (relay.points < 0) // Just-in-case fallback.
			logTheThing(LOG_DEBUG, usr, "'s ability holder ([relay.type]) was set to an invalid value (points less than 0), resetting.")
			relay.points = 0
		if (cost > relay.points)
			if (!quiet)
				boutput(owner, relay.notEnoughPointsMessage)
			return 0
		return 1

	onAbilityStat()
		..()
		.= list()
		if (relay) // Avoids a runtime whilst setting up revenant verbs
			.["Points:"] = round(relay.points)
			.["Gen. rate:"] = round(relay.regenRate + relay.lastBonus)

/datum/bioEffect/hidden/revenant
	name = "Revenant"
	desc = "The subject appears to be possessed by a wraith."
	id = "revenant"
	effectType = EFFECT_TYPE_POWER
	isBad = 0 // depends on who you ask really
	can_copy = 0
	var/isDying = 0
	var/mob/living/intangible/wraith/wraith = null
	var/ghoulTouchActive = 0
	var/list/abilities
	icon_state  = "evilaura"

	var/datum/hud/revenant/hud
	var/hud_path = /datum/hud/revenant

	OnAdd()
		if (ishuman(owner) && isdead(owner))
			switch (owner:decomp_stage)
				if (0)
					owner.max_health = 100
				if (1)
					owner.max_health = 75
				if (2)
					owner.max_health = 50
				if (3)
					owner.max_health = 25
				if (4)
					// todo: send message, tell the player to fuck off, or something
					owner.bioHolder.RemoveEffect("revenant")
					qdel(src)
					return
		else
			// do not possess non-humans; do not possess living people; do not pass go; do not collect $200
			qdel(src)
			return

		owner.full_heal()
		owner.reagents.clear_reagents()
		owner.blinded = 0
		owner.lying = 0
		if (owner)
			overlay_image = image("icon" = 'icons/effects/wraitheffects.dmi', "icon_state" = "evilaura", layer = MOB_EFFECT_LAYER)
		if (owner.bioHolder.HasEffect("husk"))
			owner.bioHolder.RemoveEffect("husk")
		owner.set_mutantrace(null)
		owner.set_face_icon_dirty()
		owner.set_body_icon_dirty()
		hud = new hud_path(owner)
		owner.attach_hud(hud)
		owner.ensure_speech_tree().AddSpeechModifier(SPEECH_MODIFIER_REVENANT)

		animate_levitate(owner)
		LAZYLISTADDUNIQUE(owner.faction, FACTION_WRAITH)

		APPLY_ATOM_PROPERTY(owner, PROP_MOB_STUN_RESIST, "revenant", 100)
		APPLY_ATOM_PROPERTY(owner, PROP_MOB_STUN_RESIST_MAX, "revenant", 100)
		APPLY_MOVEMENT_MODIFIER(owner, /datum/movement_modifier/revenant, src.type)

		..()

	OnRemove()
		if (owner)
			owner.faction -= FACTION_WRAITH
			REMOVE_ATOM_PROPERTY(owner, PROP_MOB_STUN_RESIST, "revenant")
			REMOVE_ATOM_PROPERTY(owner, PROP_MOB_STUN_RESIST_MAX, "revenant")
			REMOVE_MOVEMENT_MODIFIER(owner, /datum/movement_modifier/revenant, src.type)
			owner.detach_hud(hud)
			owner.ensure_speech_tree().RemoveSpeechModifier(SPEECH_MODIFIER_REVENANT)
		..()

	proc/ghoulTouch(var/mob/living/carbon/human/poorSob, var/def_zone)
		if (poorSob.traitHolder.hasTrait("training_chaplain"))
			poorSob.visible_message(SPAN_ALERT("[poorSob]'s faith shields them from [owner]'s ethereal force!"), SPAN_NOTICE("Your faith protects you from [owner]'s ethereal force!"))
			JOB_XP(poorSob, "Chaplain", 2)
			return
		else
			poorSob.visible_message(SPAN_ALERT("[poorSob] is hit by [owner]'s ethereal force!"), SPAN_ALERT("You are hit by [owner]'s ethereal force!"))
			if (def_zone)
				poorSob.TakeDamage(def_zone, 4, 4, 0, DAMAGE_BLUNT)
			else
				poorSob.TakeDamage("All", 4, 4, 0, DAMAGE_BLUNT)
			poorSob.changeStatus("knockdown", 2 SECONDS)
			step_away(poorSob, owner, 15)
			sleep(0.3 SECONDS)
			step_away(poorSob, owner, 15)


	proc/wraithPossess(var/mob/living/intangible/wraith/W)
		if (!W.mind && !W.client)
			return
		if (owner.client || owner.mind)
			var/mob/dead/observer/O = owner.ghostize()
			if (O)
				O.corpse = null
			owner.ghost = null
		if (owner.ghost)
			owner.ghost.corpse = null
			owner.ghost = null
		src.wraith = W
		APPLY_ATOM_PROPERTY(W, PROP_MOB_INVISIBILITY, W, INVIS_WRAITH_VERY)
		W.set_loc(src.owner)
		W.abilityHolder.topBarRendered = 0

		message_admins("[key_name(wraith)] possessed the corpse of [owner] as a revenant at [log_loc(owner)].")
		logTheThing(LOG_COMBAT, usr, "possessed the corpse of [owner] as a revenant at [log_loc(owner)].")


		if (src.wraith.mind) // theoretically shouldn't happen
			src.wraith.mind.transfer_to(owner)
		else
			src.wraith.client.mob = owner

		owner.visible_message(SPAN_ALERT("<strong>[pick("[owner] suddenly rises from the floor!", "[owner] suddenly looks a lot less dead!", "A dark light shines from [owner]'s eyes!")]</strong>"),\
			                  SPAN_NOTICE("[pick("You force your will into [owner]'s corpse.", "Your dark will forces [owner] to rise.", "You assume direct control of [owner].")]"))

		src.addRevenantVerbs()


	proc/RevenantDeath()
		if (isDying)
			return
		isDying = 1
		if (!src.wraith)
			src.owner.bioHolder.RemoveEffect("revenant")
			return
		if (!src.owner.mind && !src.owner.client)
			return

		message_admins("Revenant [key_name(owner)] died at [log_loc(owner)].")
		playsound(owner.loc, 'sound/voice/wraith/revleave.ogg', 60, 0)
		logTheThing(LOG_COMBAT, usr, "died as a revenant at [log_loc(owner)].")
		if (owner.mind)
			owner.mind.transfer_to(src.wraith)
		else if (owner.client)
			owner.client.mob = src.wraith
		APPLY_ATOM_PROPERTY(src.wraith, PROP_MOB_INVISIBILITY, src.wraith, INVIS_SPOOKY)
		src.wraith.set_loc(get_turf(owner))
		src.wraith.abilityHolder.topBarRendered = 1
		src.wraith.abilityHolder.regenRate /= 3
		owner.bioHolder.RemoveEffect("revenant")
		owner:decomp_stage = DECOMP_STAGE_SKELETONIZED
		if (ishuman(owner) && owner:organHolder && owner:organHolder:brain)
			qdel(owner:organHolder:brain)
		particleMaster.SpawnSystem(new /datum/particleSystem/localSmoke("#000000", 5, locate(owner.x, owner.y, owner.z)))
		animate(owner)
		src.wraith = null
		return

	OnLife(var/mult)
		if (..())
			return
		if (!src.wraith)
			return
		if (ghoulTouchActive)
			ghoulTouchActive = max (ghoulTouchActive - mult, 0)
			if (!ghoulTouchActive)
				owner.show_message(SPAN_ALERT("You are no longer empowered by the netherworld."))

		src.wraith.Life()

		owner.max_health -= 1.5*mult

		owner.ailments.Cut()
		owner.take_toxin_damage(-INFINITY)
		owner.take_oxygen_deprivation(-INFINITY)
		owner.take_eye_damage(-INFINITY)
		owner.take_eye_damage(-INFINITY, 1)
		owner.losebreath = 0
		owner.delStatus("disorient")
		owner.delStatus("slowed")
		owner.delStatus("radiation")
		owner.take_ear_damage(-INFINITY)
		owner.take_ear_damage(-INFINITY, 1)
		owner.take_brain_damage(-120)
		owner.bodytemperature = owner.base_body_temp
		setalive(owner)
		hud.update_health()

		if (owner.health < -50 || owner.max_health < -50) // Makes revenants have a definite time limit, instead of being able to just spam abilities in deepcrit.
			boutput(owner, SPAN_ALERT("<strong>This vessel has grown too weak to maintain your presence.</strong>"))
			playsound(owner.loc, 'sound/voice/wraith/revleave.ogg', 60, 0)
			owner.death(FALSE) // todo: add custom death
			return

		var/e_decomp_stage = DECOMP_STAGE_NO_ROT
		if (owner.max_health < 75)
			e_decomp_stage++
			if (owner.max_health < 50)
				e_decomp_stage++
				if (owner.max_health < 25)
					e_decomp_stage++
					if (owner.max_health < 0)
						e_decomp_stage++
		if (ishuman(owner)) // technically we won't let it be anything else but who knows what might happen
			if (owner:decomp_stage != e_decomp_stage)
				owner:decomp_stage = e_decomp_stage
				owner.set_face_icon_dirty()
				owner.set_body_icon_dirty()

	proc/addRevenantVerbs()
		var/datum/abilityHolder/revenant/RH = owner.add_ability_holder(/datum/abilityHolder/revenant)
		RH.relay = src.wraith.abilityHolder
		RH.revenant = src
		src.wraith.abilityHolder.regenRate *= 3
		RH.addAbility(/datum/targetable/revenantAbility/massCommand)
		RH.addAbility(/datum/targetable/revenantAbility/shockwave)
		RH.addAbility(/datum/targetable/revenantAbility/touchOfEvil)
		RH.addAbility(/datum/targetable/revenantAbility/push)
		RH.addAbility(/datum/targetable/revenantAbility/crush)
		RH.addAbility(/datum/targetable/revenantAbility/help)

	/*proc/removeRevenantVerbs()
		if (owner.mind)
			owner.mind.spells.len = 0
		return*/

/atom/movable/screen/ability/topBar/revenant
	update_cooldown_cost()
		var/newcolor = null
		var/on_cooldown = round((owner.last_cast - world.time) / 10)

		if (owner.pointCost)
			if (!owner.holder.pointCheck(owner.pointCost, quiet = TRUE))
				newcolor = rgb(64, 64, 64)
				point_overlay.maptext = "<span class='sh vb r ps2p' style='color: #cc2222;'>[owner.pointCost]</span>"
			else
				point_overlay.maptext = "<span class='sh vb r ps2p'>[owner.pointCost]</span>"
		else
			src.maptext = null

		if (on_cooldown > 0)
			newcolor = rgb(96, 96, 96)
			cooldown_overlay.alpha = 255
			cooldown_overlay.maptext = "<span class='sh vb c ps2p'>[min(999, on_cooldown)]</span>"
			point_overlay.alpha = 64
		else
			cooldown_overlay.alpha = 0
			point_overlay.alpha = 255

		if (newcolor != src.color)
			src.color = newcolor

/datum/targetable/revenantAbility
	icon = 'icons/mob/wraith_ui.dmi'
	preferred_holder_type = /datum/abilityHolder/revenant
	theme = "wraith"
	interrupt_action_bars = FALSE

	New()
		var/atom/movable/screen/ability/topBar/revenant/B = new /atom/movable/screen/ability/topBar/revenant(null)
		B.icon = src.icon
		B.icon_state = src.icon_state
		B.owner = src
		B.name = src.name
		B.desc = src.desc
		src.object = B

	cast(atom/target)
		return ..()

	castcheck()
		if (holder?.owner)
			return 1
		else
			boutput(usr, SPAN_ALERT("You're not a revenant, what the heck are you doing?"))
			return 0

	doCooldown()
		if (!holder)
			return
		last_cast = world.time + cooldown
		holder.updateButtons()
		SPAWN(cooldown + 5)
			holder?.updateButtons()


/datum/targetable/revenantAbility/massCommand
	name = "Mass Command"
	desc = "Launch an assortment of nearby objects at a target location."
	icon_state = "masscomm"
	targeted = 1
	target_anything = 1
	pointCost = 500
	cooldown = 30 SECONDS

	cast(atom/target)
		. = ..()
		playsound(target.loc, 'sound/voice/wraith/wraithlivingobject.ogg', 60, 0)
		if (istype(holder, /datum/abilityHolder/revenant))
			var/datum/abilityHolder/revenant/RH = holder
			RH.channeling = 0
		holder.owner.visible_message(SPAN_ALERT("<strong>[holder.owner]</strong> gestures upwards, then at [target] with a swift striking motion!"))
		var/list/thrown = list()
		var/current_prob = 100
		var/turf/destination = get_turf(target)
		if (!destination) return TRUE
		if (ishuman(target))
			var/mob/living/carbon/T = target
			if (T.traitHolder.hasTrait("training_chaplain"))
				target.visible_message(SPAN_ALERT(" [target] gives a rude gesture right back to [holder.owner]!"))
				return TRUE
			else if( check_target_immunity(T) )
				holder.owner.show_message( SPAN_ALERT("That target seems to be warded from the effects!") )
			else
				T.changeStatus("stunned", max(max(T.getStatusDuration("knockdown"), T.getStatusDuration("stunned")), 3))
				T.lying = 0
				T.delStatus("knockdown")
				T.show_message(SPAN_ALERT("A ghostly force compels you to be still on your feet."))
		for (var/obj/O in view(7, holder.owner))
			if (!O.anchored && isturf(O.loc))
				if (prob(current_prob))
					current_prob *= 0.75
					thrown += O
					animate_float(O)
		SPAWN(1 SECOND)
			if (!destination) return
			for (var/obj/O in thrown)
				O.throw_at(destination, 32, 2)

/datum/targetable/revenantAbility/shockwave
	name = "Shockwave"
	desc = "Emit a shockwave, breaking nearby lights and walls, and stunning nearby humans for a short time."
	icon_state = "shockwave"
	targeted = 0
	pointCost = 750
	cooldown = 35 SECONDS
	var/propagation_percentage = 60
	var/iteration_depth = 6
	var/static/list/prev = list("1" = NORTHWEST, "5" = NORTH, "4" = NORTHEAST, "6" = EAST,  "2" = SOUTHEAST, "10" = SOUTH, "8" = SOUTHWEST, "9" = WEST)
	var/static/list/next = list("1" = NORTHEAST, "5" = EAST,  "4" = SOUTHEAST, "6" = SOUTH, "2" = SOUTHWEST, "10" = WEST,  "8" = NORTHWEST, "9" = NORTH)

	proc/shock(var/turf/T)
		playsound(usr.loc, 'sound/voice/wraith/revshock.ogg', 30, 0)
		SPAWN(0)
			for (var/mob/living/carbon/human/M in T)
				if (M != holder.owner && !M.traitHolder.hasTrait("training_chaplain") && !check_target_immunity(M))
					M.changeStatus("knockdown", 2 SECONDS)
			animate_revenant_shockwave(T, 1, 3)
			sleep(0.3 SECONDS)
			for (var/mob/living/carbon/human/M in T)
				if (M != holder.owner && !M.traitHolder.hasTrait("training_chaplain") && !check_target_immunity(M))
					M.changeStatus("knockdown", 6 SECONDS)
					M.show_message(SPAN_ALERT("A shockwave sweeps you off your feet!"))
			for (var/obj/machinery/light/L in T)
				L.broken()
			for (var/obj/window/W in T)
				W.health = 0
				W.smash()
			if (istype(T, /turf/simulated/wall))
				T:dismantle_wall()
			else if (istype(T, /turf/simulated/floor) && prob(75))
				if (prob(50))
					T:to_plating()
				else
					T:break_tile()
			sleep(1 SECOND)
			T.pixel_y = 0
			T.transform = null

	cast()
		var/list/next = list()
		var/list/NN = list()
		var/turf/origin = get_turf(holder.owner)
		if (!origin)
			return 1
		. = ..()
		if (istype(holder, /datum/abilityHolder/revenant))
			var/datum/abilityHolder/revenant/RH = holder
			RH.channeling = 0
		shock(origin)
		for (var/turf/T in orange(1, origin))
			next += T
			next[T] = get_dir(origin, T)
		SPAWN(0)
			for (var/i = 1, i <= iteration_depth, i++)
				for (var/turf/T in next)
					shock(T)
					if (!T.density)
						var/base_dir = next[T]
						var/left_dir = src.prev["[base_dir]"]
						var/right_dir = src.next["[base_dir]"] // ugly & fuck you byond for making me do this
						if (prob(propagation_percentage / 2))
							var/turf/A = get_step(T, left_dir)
							if (A && !(A in NN))
								NN += A
								NN[A] = left_dir
						if (prob(propagation_percentage))
							var/turf/B = get_step(T, base_dir)
							if (B && !(B in NN))
								NN += B
								NN[B] = base_dir
						if (prob(propagation_percentage / 2))
							var/turf/C = get_step(T, right_dir)
							if (C && !(C in NN))
								NN += C
								NN[C] = right_dir
				next = NN
				NN = list()
				sleep(0.3 SECONDS)
		return 0

/datum/targetable/revenantAbility/touchOfEvil
	name = "Touch of Evil"
	desc = "Empower your hand-to-hand attacks for a short time, causing additional damage and knockdown."
	icon_state = "eviltouch"
	targeted = 0
	pointCost = 1000
	cooldown = 30 SECONDS

	cast()
		. = ..()
		playsound(usr.loc, 'sound/voice/wraith/revtouch.ogg', 70, 0)
		if (istype(holder, /datum/abilityHolder/revenant))
			var/datum/abilityHolder/revenant/RH = holder
			RH.channeling = 0
			var/datum/bioEffect/hidden/revenant/R = RH.revenant
			R.ghoulTouchActive = 4
			holder.owner.visible_message(SPAN_ALERT("[holder.owner] glows with ethereal power!"), SPAN_NOTICE("You feel ghostly strength pulsing through you."))
			return 0
		holder.owner.show_message(SPAN_ALERT("You cannot cast that ability!"))

/datum/targetable/revenantAbility/push
	name = "Push"
	desc = "Pushes a target object or mob away from the revenant."
	icon_state = "push"
	targeted = 1
	target_anything = 1
	pointCost = 50
	cooldown = 15 SECONDS

	cast(atom/target)
		playsound(target.loc, "sound/voice/wraith/revpush[rand(1, 2)].ogg", 70, 0)
		if (isturf(target))
			holder.owner.show_message(SPAN_ALERT("You must target an object or mob with this ability."))
			return 1
		. = ..()
		if (istype(holder, /datum/abilityHolder/revenant))
			var/datum/abilityHolder/revenant/RH = holder
			RH.channeling = 0
		var/mob/source = src.holder.owner
		var/throwat = get_edge_target_turf(target, get_dir(source, target))
		var/atom/movable/M = target

		if (ismob(target))
			var/mob/T = target
			if (T.bioHolder && T.traitHolder.hasTrait("training_chaplain"))
				holder.owner.show_message(SPAN_ALERT("Some mysterious force protects [target] from your influence."))
				return 1
			else if( check_target_immunity(T) )
				holder.owner.show_message(SPAN_ALERT("[target] seems to be warded from the effects!"))
				return 1
			else
				holder.owner.show_message(SPAN_NOTICE("You hurl [target] away from you!"))
				T.throw_at(throwat, 32, 2)
				T.show_message(SPAN_ALERT("An unknown force hurls you away!"))
		else
			holder.owner.show_message(SPAN_NOTICE("You hurl [target] away from you!"))
			M.throw_at(throwat, 32, 2)

		return 0

/datum/targetable/revenantAbility/crush
	name = "Crush"
	desc = "Channel your telekinetic abilities at a human target, causing damage as long as you stand still. Casting any other spell will interrupt this!"
	icon_state = "crush"
	targeted = 1
	pointCost = 2500
	cooldown = 1 MINUTE

	cast(atom/target)
		if (!ishuman(target))
			holder.owner.show_message(SPAN_ALERT("You must target a human with this ability."))
			return TRUE
		var/mob/living/carbon/human/H = target
		if (!isturf(holder.owner.loc))
			holder.owner.show_message(SPAN_ALERT("You cannot cast this ability inside a [holder.owner.loc]."))
			return TRUE
		if (holder.owner.equipped())
			holder.owner.show_message(SPAN_ALERT("You require a free hand to cast this ability."))
			return TRUE
		. = ..()
		playsound(target.loc, 'sound/voice/wraith/revfocus.ogg', 80, 0)
		if (H.traitHolder.hasTrait("training_chaplain"))
			holder.owner.show_message(SPAN_ALERT("Some mysterious force shields [target] from your influence."))
			JOB_XP(H, "Chaplain", 2)
			return TRUE
		else if( check_target_immunity(H) )
			holder.owner.show_message(SPAN_ALERT("[target] seems to be warded from the effects!"))
			return TRUE

		holder.owner.visible_message(SPAN_ALERT("[holder.owner] reaches out towards [H], making a crushing motion."), SPAN_NOTICE("You reach out towards [H]."))
		H.changeStatus("knockdown", 2 SECONDS)
		actions.start(new/datum/action/bar/crush(holder.owner, H), holder.owner)
		return FALSE

/datum/action/bar/crush
	duration = 8 SECONDS
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_STUNNED | INTERRUPT_ACT
	var/mob/living/casting_mob = null
	var/mob/living/target_mob = null

	New(var/mob/living/caster, var/mob/living/target)
		src.casting_mob = caster
		src.target_mob = target
		..()

	onStart()
		..()
		if (src.casting_mob == null || src.target_mob == null || !isalive(src.casting_mob) || !can_act(src.casting_mob) || (GET_DIST(src.casting_mob, src.target_mob) > 7))
			interrupt(INTERRUPT_ALWAYS)
			return

	onUpdate()
		..()
		if (src.casting_mob == null || src.target_mob == null || !isalive(src.casting_mob) || !can_act(src.casting_mob) || (GET_DIST(src.casting_mob, src.target_mob) > 7))
			interrupt(INTERRUPT_ALWAYS)
			return
		src.target_mob.changeStatus("knockdown", 2 SECONDS)
		src.target_mob.TakeDamage("chest", 5, 0, 0, DAMAGE_CRUSH)
		if (prob(25))
			src.target_mob.visible_message(SPAN_ALERT("[src.target_mob]'s bones crack loudly!"), SPAN_ALERT("You feel like you're about to be [pick("crushed", "destroyed", "vaporized")]."))
			playsound(src.target_mob.loc, 'sound/impact_sounds/Flesh_Tear_1.ogg', 70, 1)

	onEnd()
		..()
		src.target_mob.visible_message(SPAN_ALERT("[src.target_mob]'s body gives in to the telekinetic grip!"), SPAN_ALERT("You are completely crushed."))
		logTheThing(LOG_COMBAT, src.casting_mob, "gibs [constructTarget(src.target_mob,"combat")] with the Revenant crush ability at [log_loc(casting_mob)].")
		src.target_mob.gib()

	onInterrupt()
		..()
		boutput(src.casting_mob, SPAN_ALERT("You were interrupted!"))

/datum/targetable/revenantAbility/help
	name = "Toggle Help Mode"
	desc = "Enter or exit help mode."
	icon_state = "help0"
	targeted = 0
	cooldown = 0
	helpable = 0
	do_logs = FALSE

	cast(atom/target)
		if (..())
			return 1
		if (holder.help_mode)
			holder.help_mode = 0
			boutput(holder.owner, SPAN_HINT("<strong>Help Mode has been deactivated.</strong>"))
		else
			holder.help_mode = 1
			boutput(holder.owner, SPAN_HINT("<strong>Help Mode has been activated. To disable it, click on this button again.</strong>"))
			boutput(holder.owner, SPAN_HINT("Hold down Shift, Ctrl or Alt while clicking the button to set it to that key."))
			boutput(holder.owner, SPAN_HINT("You will then be able to use it freely by holding that button and left-clicking a tile."))
			boutput(holder.owner, SPAN_HINT("Alternatively, you can click with your middle mouse button to use the ability on your current tile."))
		src.object.icon_state = "help[holder.help_mode]"
		holder.updateButtons()
		return 0
