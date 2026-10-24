@tool
extends Node2D
class_name PathEditorGuides
## Repères de composition, dessinés DANS L'ÉDITEUR sous le chemin d'un niveau.
##
## ── À QUOI ÇA SERT ────────────────────────────────────────────────────────
## Tracer un chemin à la souris est facile ; le tracer AU BON ENDROIT ne l'est
## pas, parce que rien dans l'éditeur ne montre les trois limites qui comptent
## vraiment :
##   • la grille de construction (17 × 8 cases de 96 px depuis 200, 200) ;
##   • le bord de l'écran, qu'il faut franchir pour entrer et sortir ;
##   • la hauteur à laquelle la barre de cartes recouvre le terrain — un
##     chemin qui passe dessous devient invisible en jeu, et c'est exactement
##     l'erreur qui a été commise sur les Ruines.
##
## Ces repères ne sont dessinés qu'en édition (`Engine.is_editor_hint()`) : la
## scène n'est de toute façon jamais instanciée en jeu, seule sa courbe est lue.

const SCREEN := Vector2(1920, 1080)
const GRID_ORIGIN := Vector2(200, 200)
const GRID_COLS := 17
const GRID_ROWS := 8
const CELL := 96.0

## Hauteur à laquelle la barre de cartes commence à masquer le terrain.
## Doit rester alignée sur `offset_top` de CardBarBackground dans level.tscn.
const CARD_BAR_TOP := 890.0


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var grid_end := GRID_ORIGIN + Vector2(GRID_COLS * CELL, GRID_ROWS * CELL)

	# La grille, discrète : elle situe, elle ne doit pas concurrencer le décor.
	for col in GRID_COLS + 1:
		var x := GRID_ORIGIN.x + col * CELL
		draw_line(Vector2(x, GRID_ORIGIN.y), Vector2(x, grid_end.y),
			Color(1, 1, 1, 0.16), 1.0)
	for row in GRID_ROWS + 1:
		var y := GRID_ORIGIN.y + row * CELL
		draw_line(Vector2(GRID_ORIGIN.x, y), Vector2(grid_end.x, y),
			Color(1, 1, 1, 0.16), 1.0)

	# Zone jouable.
	draw_rect(Rect2(GRID_ORIGIN, grid_end - GRID_ORIGIN),
		Color(1, 0.25, 0.25, 0.9), false, 3.0)

	# Bord de l'écran : au-delà, le mob est hors champ — c'est là que le chemin
	# doit commencer et finir.
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0.4, 0.8, 1.0, 0.5), false, 2.0)

	# Barre de cartes : tout ce qui passe sous ce trait est invisible en jeu.
	var dash := 26.0
	var x_pos := 0.0
	while x_pos < SCREEN.x:
		draw_line(Vector2(x_pos, CARD_BAR_TOP), Vector2(x_pos + dash * 0.6, CARD_BAR_TOP),
			Color(1.0, 0.55, 0.15, 0.95), 4.0)
		x_pos += dash
	draw_rect(Rect2(Vector2(0, CARD_BAR_TOP), Vector2(SCREEN.x, SCREEN.y - CARD_BAR_TOP)),
		Color(1.0, 0.55, 0.15, 0.10))
