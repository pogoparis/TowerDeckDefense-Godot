class_name PlaceholderArt
## Silhouettes provisoires, dessinées en code, pour les mobs dont le sprite
## n'existe pas encore.
##
## ── POURQUOI CE FICHIER ───────────────────────────────────────────────────
## Un mob sans sprite est invisible : impossible de tester son comportement, de
## juger sa vitesse ou de vérifier son équilibrage. On bloque alors le design
## de jeu derrière le dessin, alors que les deux peuvent avancer en parallèle.
##
## Ces formes ne cherchent pas à être belles. Elles doivent seulement être
## LISIBLES à 110 px : une silhouette reconnaissable, la couleur de l'élément
## auquel le mob est faible, et rien d'autre.
##
## ── COMMENT ELLES DISPARAISSENT ───────────────────────────────────────────
## Chaque mob n'appelle son placeholder que si aucune texture ne lui a été
## donnée (`tex_south == null`). Assigner les sprites dans la scène suffit donc
## à les faire disparaître — aucun code à retoucher, aucun risque d'oublier un
## dessin provisoire en production.

## Contour commun : sombre et épais, comme les sprites du jeu.
const EDGE := Color(0.09, 0.07, 0.11, 0.95)
const EDGE_WIDTH := 3.0


## Pastille de l'élément auquel le mob est faible, posée au-dessus de lui.
## C'est l'information la plus utile pendant l'équilibrage : elle dit d'un coup
## d'œil quel deck est censé répondre à ce mob.
static func draw_weakness_dot(c: CanvasItem, at: Vector2, element: int) -> void:
	var color := ElementType.color(element)
	c.draw_circle(at, 11.0, EDGE)
	c.draw_circle(at, 8.5, color)
	c.draw_circle(at, 3.5, Color(1, 1, 1, 0.85))


## Corps rempli + contour, en une seule ligne d'appel.
static func draw_shape(c: CanvasItem, points: PackedVector2Array, fill: Color) -> void:
	c.draw_colored_polygon(points, fill)
	var closed := points.duplicate()
	closed.append(points[0])
	c.draw_polyline(closed, EDGE, EDGE_WIDTH, true)


## Ellipse pleine avec contour. Godot ne dessine pas d'ellipse : on l'échantillonne.
static func draw_ellipse(c: CanvasItem, center: Vector2, radius: Vector2,
		fill: Color, steps: int = 32) -> void:
	var pts := PackedVector2Array()
	for i in steps:
		var a := TAU * float(i) / float(steps)
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_shape(c, pts, fill)


## Rectangle plein avec contour, ancré par son centre.
static func draw_box(c: CanvasItem, center: Vector2, size: Vector2, fill: Color) -> void:
	var h := size * 0.5
	draw_shape(c, PackedVector2Array([
		center + Vector2(-h.x, -h.y), center + Vector2(h.x, -h.y),
		center + Vector2(h.x, h.y), center + Vector2(-h.x, h.y),
	]), fill)
