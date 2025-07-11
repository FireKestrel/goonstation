/obj/item/device/ticket_writer/odd
	name = "Security TicketWriter 3000"
	desc = "This new and improved edition features upgraded hardware and extra crime-deterring features."
	icon_state = "ticketwriter-odd"

	ticket(mob/user)
		var/target_key = ..()
		if (isnull(target_key))
			return
		var/mob/M = ckey_to_mob(target_key)
		if (ishuman(M))
			var/mob/living/carbon/human/H = M
			var/limb = pick("l_arm","r_arm","l_leg","r_leg")
			H.sever_limb(limb)

/obj/death_button/hotdog

	attack_hand(mob/user)
		if (current_state < GAME_STATE_FINISHED && !isadmin(user))
			boutput(user, SPAN_ALERT("Looks like you can't press this yet."))
			return
		if (user.stat)
			return
		var/turf/T = get_turf(src)
		T.fluid_react_single("hot_dog", 3000)
		new /obj/effect/supplyexplosion(T)
		playsound(T, 'sound/effects/ExplosionFirey.ogg', 100, TRUE)
		if (ishuman(user))
			var/mob/living/carbon/human/H = user
			H.limbs.sever("all")
		else
			user.gib()

/obj/item/reagent_containers/food/snacks/ingredient/egg/critter/pet
	warm_count = 25

	hatch_check(var/shouldThrow = 0, var/mob/user, var/turf/T)
		var/obj/critter/C = ..()
		if (!C)
			return
		C.AddComponent(/datum/component/pet, user)

/obj/item/reagent_containers/food/snacks/ingredient/egg/critter/pet/cat
	critter_type = /mob/living/critter/small_animal/cat

/datum/component/pet
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/obj/critter/critter
	var/mob/critter_parent

TYPEINFO(/datum/component/pet)
	initialization_args = list(
		ARG_INFO("critter_parent", DATA_INPUT_MOB_REFERENCE, "Critter parent mob")
	)

/datum/component/pet/Initialize(mob/critter_parent)
	. = ..()
	if(!istype(parent, /obj/critter))
		return COMPONENT_INCOMPATIBLE
	src.critter = parent
	src.critter_parent = critter_parent
	RegisterSignal(parent, COMSIG_ATTACKHAND, PROC_REF(try_grab))
	RegisterSignal(critter_parent, COMSIG_MOB_DEATH, PROC_REF(on_parent_die))

/datum/component/pet/proc/try_grab(obj/critter/C, mob/user)
	if(!(user == critter_parent && user.a_intent == INTENT_GRAB && C.alive))
		return
	user.set_pulling(C)
	C.wanderer = FALSE
	C.task = "thinking"
	C.wrangler = user
	C.visible_message(SPAN_ALERT("<b>[user]</b> wrangles [C]."))

/datum/component/pet/proc/on_parent_die()
	if(IN_RANGE(critter, critter_parent, (SQUARE_TILE_WIDTH + 1) / 2))
		critter.visible_message(SPAN_ALERT("<b>[critter]</b> droops their head mournfully."))

/datum/component/pet/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ATTACKHAND)
	UnregisterSignal(critter_parent, COMSIG_MOB_DEATH)
	. = ..()

/datum/betting_controller

/obj/machinery/maptext_junk/timer
	name = "digital timer"
	density = 0
	icon = null
	plane = PLANE_HUD
	layer = 420
	appearance_flags = TILE_BOUND | RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM | KEEP_APART | PIXEL_SCALE
	maptext = ""
	var/time_left = 600
	//maptext_prefix = "<span class='c xfont ol'>"

/obj/machinery/maptext_junk/timer/New()
	..()
	countdown()

/obj/machinery/maptext_junk/timer/proc/countdown()
	while (time_left)
		sleep(1 SECOND)
		var/time_color
		time_left--
		switch (time_left)
			if (90 to INFINITY)
				time_color = "#33dd33"
			if (60 to 90)
				time_color = "#ffff00"
			if (30 to 60)
				time_color = "#ffb400"
			if (0 to 30)
				time_color = "#ff6666"
		maptext = "<span class='vb c ol ps2p' style='color: [time_color];'>[round(time_left / 60)]:[add_zero(num2text(time_left % 60), 2)]</span>"

/obj/machinery/maptext_junk/timer/proc/reset(var/new_time)
	time_left = new_time

/obj/machinery/maptext_junk/timer/t10
	time_left = 10

/obj/machinery/maptext_junk/timer/t30
	time_left = 30

/obj/machinery/maptext_junk/timer/t60
	time_left = 60

/obj/machinery/maptext_junk/timer/t120
	time_left = 120

/obj/machinery/maptext_junk/timer/t180
	time_left = 180

/obj/machinery/maptext_junk/timer/t360
	time_left = 360

/obj/item/photo/incriminating
	name = "incriminating photo"
	desc = "This photo depicts something quite incriminating."

/obj/mail_booth/New()
	..()
	var/datum/game_server/game_server = global.game_servers.find_server("main3")
	if (!game_server.is_me())
		qdel(src)

/obj/item/random_trinket_spawner
	name = "random trinket spawner"
	icon = 'icons/obj/item_spawn.dmi'
	icon_state = "itemspawn"
	density = 0
	anchored = ANCHORED
	invisibility = INVIS_ALWAYS
	layer = 99

	New()
		..()
		SPAWN(1 DECI SECOND)
			var/T = pick(trinket_safelist)
			var/obj/item/trinket = new T(get_turf(src))
			var/datum/db_record/R = pick(data_core.general.records)
			trinket.name = "[R["name"]][pick_string("trinkets.txt", "modifiers")] [trinket.name]"
			trinket.real_name = trinket.name
			trinket.quality = rand(5,80)
			sleep(1 SECOND)
			qdel(src)

var/list/possible_lost_items = list(
	/obj/item/extinguisher,
	/obj/item/device/light/flashlight,
	/obj/item/crowbar/red,
	/obj/item/weldingtool,
	/obj/item/wirecutters,
	/obj/item/screwdriver,
	/obj/item/wrench,
	/obj/item/device/multitool,
	/obj/item/device/reagentscanner,
	/obj/item/reagent_containers/food/drinks/bottle/soda/grones,
	/obj/item/reagent_containers/food/drinks/bottle/soda/bottledwater,
	/obj/item/reagent_containers/food/drinks/cola/random,
	/obj/item/reagent_containers/food/drinks/peach,
	/obj/item/reagent_containers/food/snacks/onionchips,
	/obj/item/reagent_containers/food/snacks/chips,
	/obj/item/reagent_containers/food/snacks/candy/nougat,
	/obj/item/reagent_containers/food/snacks/candy/wrapped_candy/pb_cup,
	/obj/item/kitchen/peach_rings,
	/obj/item/reagent_containers/food/snacks/cookie/dog,
	/obj/item/toy/plush/small/bee,
	/obj/item/toy/plush/small/monkey,
	/obj/item/plant/herb/cannabis/mega/spawnable,
	/obj/item/clothing/head/NTberet
)

/obj/item/random_lost_item_spawner
	name = "random lost item spawner"
	icon = 'icons/obj/item_spawn.dmi'
	icon_state = "itemspawn"
	density = 0
	anchored = ANCHORED
	invisibility = INVIS_ALWAYS
	layer = 99

	New()
		..()
		SPAWN(1 DECI SECOND)
			var/T = pick(possible_lost_items)
			var/obj/item/I = new T(get_turf(src))
			var/datum/db_record/R = pick(data_core.general.records)
			I.name = "lost [I.name]"
			I.desc = "Didn't [R["name"]] lose one of these?"
			sleep(1 SECOND)
			qdel(src)
