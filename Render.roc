import "assets/cardsLarge_tilemap_packed.png" as card_sprite_bytes : List(U8)

import rr.Color
import rr.Draw
import rr.Assets
import rr.Math
import Game

Render := [].{
	Sprites := {
		cards : Draw.Texture,
	}

	init! : () => Try(Sprites, _)
	init! = || {
		texture_bytes = { format: Png, bytes: card_sprite_bytes }
		card_sprite = Assets.texture_from_bytes!(texture_bytes)?
		Ok({ cards: card_sprite })
	}

	draw! : Draw.Frame, Sprites, Game => Try({}, _)
	draw! = |frame, sprites, game| {
		frame.clear!(Color.from_hex_rgb(0x1d2b53))

		scale = calc_scale(frame.size!().width)

		[
			draw_draw_pile(game, sprites.cards, scale),
			draw_card_place1(game, sprites.cards, scale),
			draw_card_place2(game, sprites.cards, scale),
			draw_card_place3(game, sprites.cards, scale),
			draw_card_place4(game, sprites.cards, scale),
		].concat(draw_weapon(game, sprites.cards, scale))
			.for_each!(|td| Draw.texture!(frame, td))

		text = match game.is_finished {
			Won(p) =>
				":) ${p.to_str()}"
			Loose(p) =>
				":( -${p.to_str()}"
			Continue =>
				game.health.to_str()
		}
		frame.text_at!({
			pos: {
				x: (rect_weapon.x + rect_weapon.width + border * 10) * scale,
				y: (rect_weapon.y + rect_weapon.height / 2) * scale,
			},
			text,
			size: 10 * scale,
			color: Color.white,
		})

		Ok({})
	}

	clicked_on : _, F32 -> [DrawPile, Place1, Place2, Place3, Place4, Nothing]
	clicked_on = |mouse, window_width| {
		pt = mouse.position()

		scale = calc_scale(window_width)

		if Math.contains(scale_rect(rect_draw_pile,scale), pt) {
			return DrawPile
		}

		if Math.contains(scale_rect(rect_card_place1, scale), pt) {
			return Place1
		}

		if Math.contains(scale_rect(rect_card_place2, scale), pt) {
			return Place2
		}

		if Math.contains(scale_rect(rect_card_place3, scale), pt) {
			return Place3
		}

		if Math.contains(scale_rect(rect_card_place4, scale), pt) {
			return Place4
		}

		Nothing
	}
}

calc_scale = |width| {
    base_width = ((rect_draw_pile.x + rect_draw_pile.width) * 5 + border)
	width / base_width
}

draw_draw_pile = |game, card_sprite, scale| {
	if game.draw_pile.is_empty() {
		draw_card_empty(card_sprite, rect_draw_pile, scale)
	} else {
		draw_card_background(card_sprite, rect_draw_pile, scale)
	}
}

draw_card_place1 = |game, card_sprite, scale| {
	match game.card_place1 {
		Empty => draw_card_empty(card_sprite, rect_card_place1, scale)
		OpenCard(card) => draw_card(card_sprite, card, rect_card_place1, scale)
	}
}

draw_card_place2 = |game, card_sprite, scale| {
	match game.card_place2 {
		Empty => draw_card_empty(card_sprite, rect_card_place2, scale)
		OpenCard(card) => draw_card(card_sprite, card, rect_card_place2, scale)
	}
}

draw_card_place3 = |game, card_sprite, scale| {
	match game.card_place3 {
		Empty => draw_card_empty(card_sprite, rect_card_place3, scale)
		OpenCard(card) => draw_card(card_sprite, card, rect_card_place3, scale)
	}
}

draw_card_place4 = |game, card_sprite, scale| {
	match game.card_place4 {
		Empty => draw_card_empty(card_sprite, rect_card_place4, scale)
		OpenCard(card) => draw_card(card_sprite, card, rect_card_place4, scale)
	}
}

draw_weapon = |game, card_sprite, scale| {
	match game.weapon {
		NoWeapon => [draw_card_empty(card_sprite, rect_weapon, scale)]
		Weapon(weapon) => {
			[draw_card(card_sprite, { color: Diamond, value: weapon.value }, rect_weapon, scale)]
				.concat(
					match weapon.used_on {
						Monster(card) => {
							[draw_card(card_sprite, card, rect_weapon_monster, scale)]
						}
						NoMonster => []
					},
				)
		}
	}
}

draw_card = |card_sprite, card, rect, scale| {
	..Draw.texture_draw(card_sprite),
	source: card_texture_source(card),
	dest: scale_rect(rect, scale),
}

draw_card_background = |card_sprite, rect, scale| {
	..Draw.texture_draw(card_sprite),
	source: card_texture_background,
	dest: scale_rect(rect, scale),
}

draw_card_empty = |card_sprite, rect, scale| {
	..Draw.texture_draw(card_sprite),
	source: card_texture_empty,
	dest: scale_rect(rect, scale),
}

scale_rect = |rect, scale| {
	{
		x: rect.x * scale,
		y: rect.y * scale,
		width: rect.width * scale,
		height: rect.height * scale,
	}
}

card_source_base = {
	x: 0,
	y: 0,
	width: 42,
	height: 60,
}

card_texture_background = {
	x = 13 * (card_source_base.width - 1)
	y = card_source_base.height - 1
	{ ..card_source_base, x, y }
}

card_texture_empty = {
	x = 13 * (card_source_base.width - 1)
	{ ..card_source_base, x }
}

card_texture_source : Game.Card -> Math.Rect
card_texture_source = |card| {
	value = if (card.value == 14) 1 else card.value
	cv = (value - 1) |> U8.mod_by(13)
	x = cv.to_f32() * (card_source_base.width - 1)
	y = (
		match card.color {
			Heart => 0
			Diamond => 1
			Club => 2
			Spade => 3
		}
	) * (card_source_base.height - 1)

	{ ..card_source_base, x, y }
}

border = 5

rect_base = {
	x: 0,
	y: 0,
	width: card_source_base.width,
	height: card_source_base.height,
}

rect_draw_pile = {
	..rect_base,
	x: border,
	y: border,
}

rect_card_place1 = {
	..rect_draw_pile,
	x: rect_draw_pile.x + rect_draw_pile.width + border,
}

rect_card_place2 = {
	..rect_card_place1,
	x: rect_card_place1.x + rect_card_place1.width + border,
}

rect_card_place3 = {
	..rect_card_place2,
	x: rect_card_place2.x + rect_card_place2.width + border,
}

rect_card_place4 = {
	..rect_card_place3,
	x: rect_card_place3.x + rect_card_place3.width + border,
}

rect_weapon = {
	..rect_draw_pile,
	y: rect_draw_pile.y + rect_draw_pile.height + border * 2,
}

rect_weapon_monster = {
	..rect_weapon,
	y: rect_weapon.y + 5 * border,
}
