import rr.Random

Game := {
	draw_pile : List(Card),
	card_place1 : MaybeCard,
	card_place2 : MaybeCard,
	card_place3 : MaybeCard,
	card_place4 : MaybeCard,
	weapon : [Weapon(Weapon), NoWeapon],
	health : U8,
	reset_last_round : Bool,
	drink_potion : Bool,
	is_finished : [Continue, Won(U8), Loose(U8)],

}.{
	new : Random.State -> (Game, Random.State)
	new = |rng| {
		x = Random.step(rng, Random.shuffle(full_deck))
		(
			{
				draw_pile: x.value,
				card_place1: Empty,
				card_place2: Empty,
				card_place3: Empty,
				card_place4: Empty,
				weapon: NoWeapon,
				health: 20,
				reset_last_round: Bool.False,
				drink_potion: Bool.False,
				is_finished: Continue,
			},
			x.state,
		)
	}

	check_finished : Game -> Game
	check_finished = |game| {
	    {..game, is_finished: is_finished(game)}
	}

	new_room : Game -> Game
	new_room = |game| {
		open_cards = count_open_cards(game)
		if open_cards == 2 or open_cards == 3 {
			return game
		}

		ngame = if open_cards == 4 {
			if game.reset_last_round {
				return game
			}
			{ ..clear_open_cards(game), reset_last_round: Bool.True }
		} else {
			{ ..game, reset_last_round: Bool.False }
		}

		$pile : List(Card)
		var $pile = ngame.draw_pile

		(card_place1, $pile) = draw_from_pile(ngame.card_place1, $pile)
		(card_place2, $pile) = draw_from_pile(ngame.card_place2, $pile)
		(card_place3, $pile) = draw_from_pile(ngame.card_place3, $pile)
		(card_place4, $pile) = draw_from_pile(ngame.card_place4, $pile)

		{
			..ngame,
			card_place1,
			card_place2,
			card_place3,
			card_place4,
			draw_pile: $pile,
			drink_potion: Bool.False,
		}
	}

	play_card : Game, [Place1, Place2, Place3, Place4], Bool -> Game
	play_card = |game, place, extra| {
		if game.is_finished != Continue {
			return game
		}
		if count_open_cards(game) <= 1 {
			return game
		}
		mcard = match place {
			Place1 => game.card_place1
			Place2 => game.card_place2
			Place3 => game.card_place3
			Place4 => game.card_place4
		}

		card = match mcard {
			Empty => return game
			OpenCard(c) => c
		}

		ngame = match card.color {
			Club | Spade => fight_monster(game, card, extra)
			Diamond => activate_weapon(game, card.value)
			Heart => drink_potion(game, card.value)
		}

		match place {
			Place1 => { ..ngame, card_place1: Empty }
			Place2 => { ..ngame, card_place2: Empty }
			Place3 => { ..ngame, card_place3: Empty }
			Place4 => { ..ngame, card_place4: Empty }
		}
	}
}

Card : { color : CardColor, value : U8 }

CardColor : [Club, Diamond, Heart, Spade]

MaybeCard : [OpenCard(Card), Empty]

Weapon : {
	value : U8,
	used_on : [Monster(Card), NoMonster],
}

count_open_cards : Game -> U8
count_open_cards = |game| {
	[game.card_place1, game.card_place2, game.card_place3, game.card_place4]
		.count_if(|p| p != Empty)
		.to_u8_wrap()
}

clear_open_cards : Game -> Game
clear_open_cards = |game| {
	draw_pile =
		[game.card_place1, game.card_place2, game.card_place3, game.card_place4]
			.keep_oks(
				|v| {
					match v {
						OpenCard(c) => Ok(c)
						Empty => Err({})
					}
				},
			)
			.concat(game.draw_pile)
	{
		..game,
		draw_pile,
		card_place1: Empty,
		card_place2: Empty,
		card_place3: Empty,
		card_place4: Empty,
	}
}

draw_from_pile : MaybeCard, List(Card) -> (MaybeCard, List(Card))
draw_from_pile = |m, pile| {
	if m != Empty {
		return (m, pile)
	}

	c = match pile.last() {
		Ok(v) => OpenCard(v)
		Err(_) => Empty
	}
	p = pile.drop_last(1)
	(c, p)
}

activate_weapon : Game, U8 -> Game
activate_weapon = |game, value| {
	{ ..game, weapon: Weapon({ value, used_on: NoMonster }) }
}

drink_potion : Game, U8 -> Game
drink_potion = |game, value| {
	if game.drink_potion {
		return game
	}

	{ ..game, drink_potion: Bool.True, health: U8.min(20, game.health + value) }
}

fight_monster : Game, Card, Bool -> Game
fight_monster = |game, card, skip_weapon| {
	(dmg, weapon) =
		match game.weapon {
			Weapon(w) => {
				match w.used_on {
					Monster(monster_card) => {
						if monster_card.value <= card.value or skip_weapon {
							(card.value, Weapon(w))
						} else {
							if w.value >= card.value {
								(0, Weapon({ ..w, used_on: Monster(card) }))
							} else {
								(card.value - w.value, Weapon({ ..w, used_on: Monster(card) }))
							}
						}
					}
					NoMonster => {
					    if skip_weapon {
							(card.value, Weapon(w))
						} else if w.value >= card.value {
							(0, Weapon({ ..w, used_on: Monster(card) }))
						} else {
							(card.value - w.value, Weapon({ ..w, used_on: Monster(card) }))
						}
					}
				}
			}
			NoWeapon => (card.value, NoWeapon)
		}
	{ ..game, health: game.health - U8.min(game.health, dmg), weapon }
}

full_deck : List(Card)
full_deck = {
	List.concat(
		[Club, Diamond, Spade].fold(
			List.with_capacity(13 * 3 + 10),
			|state, color| {
				state.concat(
					U8.range_inclusive_to(2, 14).iter().map(|value| { color, value })
						|> List.from_iter,
				)
			},
		),
		U8.range_inclusive_to(2, 10).iter().map(|value| { color: Heart, value })
			|> List.from_iter,
	)
}

is_finished : Game -> [Continue, Won(U8), Loose(U8)]
is_finished = |game| {
	if game.health == 0 {
		v = game.draw_pile
			|> List.fold(
				0,
				|cur, card| {
					match card.color {
						Club | Spade => cur + card.value
						Diamond | Heart => cur
					}
				},
			)
		return Loose(v)
	}

	if game.draw_pile.len() == 0 and count_open_cards(game) <= 1 {
		last_card =
			match game.card_place1 {
				OpenCard(card) => card
				Empty => match game.card_place2 {
					OpenCard(card) => card
					Empty => match game.card_place3 {
						OpenCard(card) => card
						Empty => match game.card_place4 {
							OpenCard(card) => card
							Empty => crash ("no card left")
						}
					}
				}
			}
		points = match last_card.color {
			Heart => {
				if game.health == 20 {
					20 + last_card.value
				} else {
					game.health
				}
			}
			_ => game.health
		}
		return Won(points)
	}
	Continue
}
