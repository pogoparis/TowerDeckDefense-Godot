extends Node
## Fumigène : vérifie les comportements des trois nouveaux mobs.
## Trois scripts neufs qui n'ont jamais tourné — le contrôle de syntaxe ne dit
## rien d'un soin qui ne soigne pas ou d'un camouflage qui ne réduit rien.

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Runner.new())


class Runner extends Node:
	func _ready() -> void:
		Progress.current_level_id = AtelierPanel.LEVEL_ID
		Progress.selected_deck = null
		get_tree().change_scene_to_file("res://scenes/ui/level.tscn")
		await get_tree().create_timer(2.0).timeout

		var scene := get_tree().current_scene
		var panel = scene.get_node_or_null("AtelierPanel")
		var em = scene.get("enemy_manager")
		if panel == null:
			print("atelier absent"); get_tree().quit(); return

		# ── DRONE FANTÔME : camouflage puis révélation ──────────────────
		panel._on_spawn("fantome")
		await get_tree().create_timer(0.6).timeout
		var f = _premier(em, "PhantomDrone")
		if f:
			var pv0: int = f.hp
			f.take_damage(40, "normal", ElementType.Type.FIRE)
			print("FANTOME camoufle : 40 degats de Feu -> %d PV perdus (attendu 20)"
				% (pv0 - f.hp))
			pv0 = f.hp
			f.take_damage(40, "normal", ElementType.Type.LIGHT)
			print("FANTOME 40 de Lumiere -> %d PV perdus (attendu 80, x2 faiblesse)  revele=%s"
				% [pv0 - f.hp, f.is_revealed()])
			# Il est mort au coup precedent (100 - 20 - 80) : on le rembourse
			# pour mesurer le 3e cas, sinon on taperait sur un cadavre.
			f.hp = f.max_hp
			f._is_dying = false
			pv0 = f.hp
			f.take_damage(40, "normal", ElementType.Type.FIRE)
			print("FANTOME revele : 40 de Feu -> %d PV perdus (attendu 40)" % (pv0 - f.hp))
		panel._on_clear()
		await get_tree().create_timer(0.3).timeout

		# ── ZEPPELIN : repoussee amplifiee ──────────────────────────────
		panel._on_spawn("zeppelin")
		await get_tree().create_timer(0.6).timeout
		var z = _premier(em, "ZeppelinMob")
		if z:
			var pf = z.get_parent()
			pf.progress = 400.0
			z.apply_knockback(30.0)
			print("ZEPPELIN pousse de 30 -> recul reel %.0f px (attendu 90)"
				% (400.0 - pf.progress))
		panel._on_clear()
		await get_tree().create_timer(0.3).timeout

		# ── RÉPARATEUR : soigne les voisins, pas lui-meme ───────────────
		panel._count = 1
		panel._on_spawn("pillard")
		panel._on_spawn("reparateur")
		await get_tree().create_timer(0.6).timeout
		var r = _premier(em, "RepairerMob")
		var p = _autre_que(em, r)
		if r and p:
			p.hp = 10 ; p.update_hp_bar()
			r.hp = maxi(1, r.max_hp / 2)
			var blesse: int = p.hp
			var soigneur: int = r.hp
			r._pulse_heal()
			print("REPARATEUR : voisin %d -> %d PV | lui-meme %d -> %d (doit rester egal)"
				% [blesse, p.hp, soigneur, r.hp])
		get_tree().quit()


	## Un ennemi vivant qui n'est pas celui passe en argument.
	func _autre_que(em, exclu):
		if em == null:
			return null
		for e in em.get_all_enemies():
			if is_instance_valid(e) and e != exclu:
				return e
		return null


	func _premier(em, classe: String):
		if em == null:
			return null
		for e in em.get_all_enemies():
			if is_instance_valid(e) and e.get_script() != null \
				and e.get_script().get_global_name() == classe:
				return e
		return null
