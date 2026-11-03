app [Model, program] { rr: platform "https://github.com/lukewilliamboswell/roc-ray/releases/download/0.12.0/79nt7eRxopFeMc2RcTHhPmjDxdRZjpNWLa9Na5xVGw9p.tar.zst" }

import rr.App
import rr.Random
import rr.Math
import rr.Draw
import Game
import Render

Model : {
	sprites : Render.Sprites,
	game : Game,
	rng : Random.State,
}

Msg : []

program = { init!, update!, render! }

init! : App.Init(Model, _)
init! = App.init(
	App.default.with_title("Scoundrel"),
	|io| {
		sprites = Render.init!()?
		rng_init = Random.seed(U64.to_u32_wrap(io.entropy!()))
		(game, rng) = Game.new(rng_init)
		Ok({
			sprites,
			game,
			rng,
		})
	},
)

update! : Model, App.Input(Msg), App.Io => Try(Model, [Exit(I64)])
update! = |model, input, _io| {
	mouse = input.devices.mouse

	extra_key = input.devices.key_down(KeyLeftControl)

	var $game = model.game
	$game = $game.check_finished()

	$game = if mouse.button_pressed(Left) {
	    clicked_on = Render.clicked_on(mouse)
		if $game.is_finished != Continue {
			if  clicked_on == DrawPile {
				(g, p) = Game.new(model.rng)
				return Ok({ ..model, game: g, rng: p })
			}
			return Ok(model)
		}

		match clicked_on {
			DrawPile => Game.new_room($game)
			Place1 => Game.play_card($game, Place1, extra_key)
			Place2 => Game.play_card($game, Place2, extra_key)
			Place3 => Game.play_card($game, Place3, extra_key)
			Place4 => Game.play_card($game, Place4, extra_key)
			Nothing => $game
		}
	} else {
		$game
	}
	Ok({ ..model, game: $game })
}



render! : Model, Draw.Frame => Try({}, [Exit(I64)])
render! = |model, frame| {
	Render.draw!(frame, model.sprites, model.game)
}
