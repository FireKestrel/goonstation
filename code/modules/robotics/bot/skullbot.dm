// fart

TYPEINFO(/obj/machinery/bot/skullbot)
	start_listen_effects = list(LISTEN_EFFECT_SKULLBOT)
	start_listen_inputs = list(LISTEN_INPUT_OUTLOUD)
	start_speech_modifiers = list(SPEECH_MODIFIER_BOT, SPEECH_MODIFIER_ACCENT_CLACK)

/obj/machinery/bot/skullbot
	name = "skullbot"
	desc = "A skull on a leg. Useful, somehow. I guess."
	icon = 'icons/obj/bots/aibots.dmi'
	icon_state = "skullbot"
	layer = 5.0 //TODO LAYER
	density = 0
	anchored = UNANCHORED
	on = 1
	health = 5
	no_camera = 1
	/// a bonehead on a stick doesnt need to process a million times a sec
	dynamic_processing = 0

	voice_sound_override = 'sound/misc/talk/skelly.ogg'
	speech_verb_say = list("rattles", "clacks")

	process()
		. = ..()
		if (prob(10) && src.on == 1)
			var/message = pick("clak clak", "clak")
			src.say(message)
		if (prob(33) && src.emagged == 1)
			var/message = pick("i have a bone to pick with you", "make no bones about it", "this is very humerus", "my favorite singer is pelvis presley", "im going to give you a sternum talking to", "i play the trombone", "don't be a coccyx", "this is sacrum ground", "im only ribbing you", "this is going tibia fun experience", "ill vertabreak you in two", "im the skeleton crew", "you're bone-idle", "my favourite drink is bone jack, but it goes right through me", "i can't feel my head, im a numbskull", "once i get to you, youre boned", "id eat you, but i don't have the stomach for it", "im just skullking around", "can i thorax you a question", "thats a load of mandibleshit", "reticulataing spines...")
			playsound(src.loc, 'sound/items/Scissor.ogg', 50, 1)
			src.say(message)

	emag_act(var/mob/user, var/obj/item/card/emag/E)
		if (!src.emagged)
			if (user)
				user.show_text("You short out the vocal emitter on [src].", "red")
			src.audible_message(SPAN_COMBAT("<B>[src] buzzes oddly!</B>"))
			playsound(src.loc, 'sound/items/Scissor.ogg', 50, 1)
			src.emagged = 1
			return 1
		return 0

	demag(var/mob/user)
		if (!src.emagged)
			return 0
		if (user)
			user.show_text("You repair [src]'s vocal emitter.", "blue")
		src.emagged = 0
		return 1


	attackby(obj/item/W, mob/user)
		src.visible_message(SPAN_COMBAT("[user] hits [src] with [W]!"))
		src.health -= W.force * 0.5
		if (src.health <= 0)
			src.explode()

	gib()
		return src.explode()

	explode()
		if(src.exploding) return
		src.exploding = 1
		src.on = 0
		src.visible_message(SPAN_COMBAT("<B>[src] blows apart!</B>"))
		playsound(src.loc, 'sound/impact_sounds/Machinery_Break_1.ogg', 40, 1)
		elecflash(src, radius=1, power=3, exclude_center = 0)
		qdel(src)
		return

/obj/machinery/bot/skullbot/crystal
	name = "crystal skullbot"
	icon_state = "skullbot-crystal"

/obj/machinery/bot/skullbot/strange
	name = "strange skullbot"
	icon_state = "skullbot-P"

/obj/machinery/bot/skullbot/peculiar
	name = "peculiar skullbot"
	icon_state = "skullbot-strange"

/obj/machinery/bot/skullbot/odd
	name = "odd skullbot"
	icon_state = "skullbot-A"

/obj/machinery/bot/skullbot/faceless
	name = "faceless skullbot"
	icon_state = "skullbot-noface"

/obj/machinery/bot/skullbot/gold
	name = "golden skullbot"
	icon_state = "skullbot-gold"

/obj/machinery/bot/skullbot/ominous
	name = "ominous skullbot"
	icon_state = "skullbot-ominous"
