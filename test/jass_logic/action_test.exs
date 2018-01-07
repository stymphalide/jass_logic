defmodule ActionTest do
  use ExUnit.Case

  alias JassLogic.Action
  alias JassLogic.Globals
  alias JassLogic.Card
  alias JassLogic.Game
  alias JassLogic.Wys


  @initial_state %JassLogic.GameState{cards: %{"pl1" => [%{color: "hearts", number: "jack"},
    %{color: "spades", number: "jack"}, %{color: "spades", number: "king"},
    %{color: "diamonds", number: "9"}, %{color: "diamonds", number: "jack"},
    %{color: "diamonds", number: "ace"}, %{color: "clubs", number: "jack"},
    %{color: "clubs", number: "king"}, %{color: "clubs", number: "ace"}],
   "pl2" => [%{color: "hearts", number: "8"}, %{color: "hearts", number: "10"},
    %{color: "hearts", number: "king"}, %{color: "spades", number: "9"},
    %{color: "spades", number: "queen"}, %{color: "diamonds", number: "7"},
    %{color: "diamonds", number: "8"}, %{color: "clubs", number: "7"},
    %{color: "clubs", number: "9"}],
   "pl3" => [%{color: "hearts", number: "6"}, %{color: "spades", number: "6"},
    %{color: "spades", number: "7"}, %{color: "spades", number: "8"},
    %{color: "spades", number: "10"}, %{color: "diamonds", number: "6"},
    %{color: "diamonds", number: "10"}, %{color: "clubs", number: "6"},
    %{color: "clubs", number: "8"}],
   "pl4" => [%{color: "hearts", number: "7"}, %{color: "hearts", number: "9"},
    %{color: "hearts", number: "queen"}, %{color: "hearts", number: "ace"},
    %{color: "spades", number: "ace"}, %{color: "diamonds", number: "queen"},
    %{color: "diamonds", number: "king"}, %{color: "clubs", number: "10"},
    %{color: "clubs", number: "queen"}]}, gameType: nil,
   groups: [%JassLogic.Group{players: ["pl1", "pl3"], points: 0, wonCards: []},
    %JassLogic.Group{players: ["pl2", "pl4"], points: 0, wonCards: []}],
   onTurnPlayer: "pl1", players: ["pl1", "pl2", "pl3", "pl4"], proposed_wyses: [],
   round: 0, stoeck: nil, table: [nil, nil, nil, nil], turn: 0, valid_wyses: []}

  doctest Action
  test "evaluates the initial action space correctly" do
    # After initialised game.
    possible_types = Globals.game_types() |> MapSet.new()
    expected = [{:set_game_type, possible_types}]
    
    assert expected == Action.eval_action_space(@initial_state)
  end
  test "evaluates the after swap action space correctly" do
    action = {:set_game_type, "swap"}
    {:ok, game_state} = Game.eval_game(@initial_state, [action])

    possible_types = tl(Globals.game_types()) |> MapSet.new
    expected = [{:set_game_type_after_swap, possible_types}]

    assert expected == Action.eval_action_space(game_state)
  end
  test "evaluates after set type correctly" do
    actions = [{:set_game_type, "diamonds"}]
    {:ok, game_state} = Game.eval_game(@initial_state, actions)
    cards = @initial_state.cards["pl1"] |> MapSet.new()
    wyses = %Wys{name: :four_the_same, cards: Wys.generate_wys_cards(:four_the_same, Card.new("hearts", "jack"))}
    expected = [{:play_card, %{wys: wyses, card: cards}}]
    assert expected == Action.eval_action_space(game_state)
  end

end
