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
		draw_draw_pile!(game, frame, sprites.cards)
		draw_card_place1!(game, frame, sprites.cards)
		draw_card_place2!(game, frame, sprites.cards)
		draw_card_place3!(game, frame, sprites.cards)
		draw_card_place4!(game, frame, sprites.cards)
		draw_weapon!(game, frame, sprites.cards)

		text = match game.is_finished {
			Won(p) =>
				":) ${p.to_str()}"
			Loose(p) =>
				"-_- -${p.to_str()}"
			Continue =>
				game.health.to_str()
		}
		frame.text_at!({ pos: { x: rect_weapon.x + rect_weapon.width + border * 10, y: rect_weapon.y + rect_weapon.height / 2 }, text, size: 10 * scale, color: Color.white })

		Ok({})
	}

	clicked_on : _ -> [DrawPile, Place1, Place2, Place3, Place4, Nothing]
	clicked_on = |mouse| {
		pt = mouse.position()

		if Math.contains(rect_draw_pile, pt) {
			return DrawPile
		}

		if Math.contains(rect_card_place1, pt) {
			return Place1
		}

		if Math.contains(rect_card_place2, pt) {
			return Place2
		}

		if Math.contains(rect_card_place3, pt) {
			return Place3
		}

		if Math.contains(rect_card_place4, pt) {
			return Place4
		}

		Nothing
	}
}

draw_draw_pile! = |game, frame, card_sprite| {
	if game.draw_pile.is_empty() {
		draw_card_empty!(frame, card_sprite, rect_draw_pile)
	} else {
		draw_card_background!(frame, card_sprite, rect_draw_pile)
	}
}

draw_card_place1! = |game, frame, card_sprite| {
	match game.card_place1 {
		Empty => draw_card_empty!(frame, card_sprite, rect_card_place1)
		OpenCard(card) => draw_card!(frame, card_sprite, card, rect_card_place1)
	}
}

draw_card_place2! = |game, frame, card_sprite| {
	match game.card_place2 {
		Empty => draw_card_empty!(frame, card_sprite, rect_card_place2)
		OpenCard(card) => draw_card!(frame, card_sprite, card, rect_card_place2)
	}
}

draw_card_place3! = |game, frame, card_sprite| {
	match game.card_place3 {
		Empty => draw_card_empty!(frame, card_sprite, rect_card_place3)
		OpenCard(card) => draw_card!(frame, card_sprite, card, rect_card_place3)
	}
}

draw_card_place4! = |game, frame, card_sprite| {
	match game.card_place4 {
		Empty => draw_card_empty!(frame, card_sprite, rect_card_place4)
		OpenCard(card) => draw_card!(frame, card_sprite, card, rect_card_place4)
	}
}

draw_weapon! : Game, Draw.Frame, Draw.Texture => {}
draw_weapon! = |game, frame, card_sprite| {
	match game.weapon {
		NoWeapon => draw_card_empty!(frame, card_sprite, rect_weapon)
		Weapon(weapon) => {
			draw_card!(frame, card_sprite, { color: Diamond, value: weapon.value }, rect_weapon)
			match weapon.used_on {
				Monster(card) => {
					draw_card!(frame, card_sprite, card, rect_weapon_monster)
				}
				NoMonster => {}
			}
		}
	}
}

draw_card! = |frame, card_sprite, card, rect| {
	frame.texture!({
		texture: card_sprite,
		source: card_texture_source(card),
		dest: rect,
		origin: Math.zero,
		rotation: 0,
		tint: Color.white,
	})
}

draw_card_background! = |frame, card_sprite, rect| {
	frame.texture!({
		texture: card_sprite,
		source: card_texture_background,
		dest: rect,
		origin: Math.zero,
		rotation: 0,
		tint: Color.white,
	})
}

draw_card_empty! = |frame, card_sprite, rect| {
	frame.texture!({
		texture: card_sprite,
		source: card_texture_empty,
		dest: rect,
		origin: Math.zero,
		rotation: 0,
		tint: Color.white,
	})
}

scale = 3

border = 5 * scale

card_source_width = 42

card_source_height = 60

card_texture_background = {
	width = card_source_width
	height = card_source_height
	x = 13 * (width - 1)
	y = height - 1
	{ x, y, width, height }
}

card_texture_empty = {
	width = card_source_width
	height = card_source_height
	x = 13 * (width - 1)
	y = 0
	{ x, y, width, height }
}

card_texture_source : Game.Card -> Math.Rect
card_texture_source = |card| {
	width = card_source_width
	height = card_source_height
	value = if (card.value == 14) 1 else card.value
	cv = (value - 1) |> U8.mod_by(13)
	x = cv.to_f32() * (width - 1)
	y = (
		match card.color {
			Heart => 0
			Diamond => 1
			Club => 2
			Spade => 3
		}
	) * (height - 1)

	{ x, y, width, height: 60 }
}

rect_draw_pile = {
	x: border,
	y: border,
	width: card_source_width * scale,
	height: card_source_height * scale,
}

rect_card_place1 = {
	x: rect_draw_pile.x + rect_draw_pile.width + border,
	y: border,
	width: card_source_width * scale,
	height: card_source_height * scale,
}

rect_card_place2 = {
	x: rect_card_place1.x + rect_card_place1.width + border,
	y: border,
	width: card_source_width * scale,
	height: card_source_height * scale,
}

rect_card_place3 = {
	x: rect_card_place2.x + rect_card_place2.width + border,
	y: border,
	width: card_source_width * scale,
	height: card_source_height * scale,
}

rect_card_place4 = {
	x: rect_card_place3.x + rect_card_place3.width + border,
	y: border,
	width: card_source_width * scale,
	height: card_source_height * scale,
}

rect_weapon = {
	x: rect_draw_pile.x + rect_draw_pile.width + border,
	y: rect_card_place1.y + rect_card_place1.height + border * 2,
	width: card_source_width * scale,
	height: card_source_height * scale,
}

rect_weapon_monster = {
	x: rect_weapon.x,
	y: rect_weapon.y + 5 * border,
	width: card_source_width * scale,
	height: card_source_height * scale,
}
