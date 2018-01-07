defmodule ActionTest do
  use ExUnit.Case

  alias JassLogic.Action
  alias JassLogic.{Globals, Card, Group, Game, Wys, GameState}

  @initial_state %GameState{cards: %{"pl1" => [%Card{color: "hearts", number: "jack"},
    %Card{color: "spades", number: "jack"}, %Card{color: "spades", number: "king"},
    %Card{color: "diamonds", number: "9"}, %Card{color: "diamonds", number: "jack"},
    %Card{color: "diamonds", number: "ace"}, %Card{color: "clubs", number: "jack"},
    %Card{color: "clubs", number: "king"}, %Card{color: "clubs", number: "ace"}],
   "pl2" => [%Card{color: "hearts", number: "8"}, %Card{color: "hearts", number: "10"},
    %Card{color: "hearts", number: "king"}, %Card{color: "spades", number: "9"},
    %Card{color: "spades", number: "queen"}, %Card{color: "diamonds", number: "7"},
    %Card{color: "diamonds", number: "8"}, %Card{color: "clubs", number: "7"},
    %Card{color: "clubs", number: "9"}],
   "pl3" => [%Card{color: "hearts", number: "6"}, %Card{color: "spades", number: "6"},
    %Card{color: "spades", number: "7"}, %Card{color: "spades", number: "8"},
    %Card{color: "spades", number: "10"}, %Card{color: "diamonds", number: "6"},
    %Card{color: "diamonds", number: "10"}, %Card{color: "clubs", number: "6"},
    %Card{color: "clubs", number: "8"}],
   "pl4" => [%Card{color: "hearts", number: "7"}, %Card{color: "hearts", number: "9"},
    %Card{color: "hearts", number: "queen"}, %Card{color: "hearts", number: "ace"},
    %Card{color: "spades", number: "ace"}, %Card{color: "diamonds", number: "queen"},
    %Card{color: "diamonds", number: "king"}, %Card{color: "clubs", number: "10"},
    %Card{color: "clubs", number: "queen"}]}, gameType: nil,
   groups: [%Group{players: ["pl1", "pl3"], points: 0, wonCards: []},
    %Group{players: ["pl2", "pl4"], points: 0, wonCards: []}],
   onTurnPlayer: "pl1", players: ["pl1", "pl2", "pl3", "pl4"], proposed_wyses: %{},
   round: 0, stoeck: nil, table: [nil, nil, nil, nil], turn: 0, valid_wyses: %{}}

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
    wyses = MapSet.new([%Wys{name: :four_the_same, cards: Wys.generate_wys_cards(:four_the_same, Card.new("hearts", "jack"))}])
    expected = [{:play_card, %{wys: wyses, card: cards}}]
    assert expected == Action.eval_action_space(game_state)
  end
  test "evaluates after first card correctly" do
    wyses = MapSet.new([ Wys.new(:four_the_same, [Card.new("hearts", "jack"), Card.new("spades", "jack"), Card.new("diamonds", "jack"), Card.new("clubs", "jack")]) ])
    actions = 
      [{:set_game_type, "diamonds"}, {:play_card, %{wys: wyses, card: Card.new("diamonds", "jack")}}]
      |> Enum.reverse()
    {:ok, game_state} = Game.eval_game(@initial_state, actions)
    wyses = MapSet.new([])
    cards = MapSet.new([Card.new("diamonds", "7"), Card.new("diamonds", "8")])
    expected = [{:play_card, %{wys: wyses, card: cards}}]
    assert expected == Action.eval_action_space(game_state)
  end
  test "evaluates with stoeck correctly" do
    wyses = MapSet.new([])
    actions = 
      [{:set_game_type, "diamonds"}, {:play_card, %{wys: wyses, card: Card.new("diamonds", "jack")}}, {:play_card, %{wys: wyses, card: Card.new("diamonds", "7")}}, {:play_card, %{wys: wyses, card: Card.new("diamonds", "6")}}]
      |> Enum.reverse()
    {:ok, game_state} = Game.eval_game(@initial_state, actions)

    wyses = MapSet.new([])
    cards = MapSet.new([Card.new("diamonds", "queen"), Card.new("diamonds", "king")])
    expected = [{:play_card, %{wys: wyses, card: cards}}, {:play_card_with_stoeck, %{wys: wyses, card: cards}}]
    assert expected == Action.eval_action_space(game_state)
  end
  test "evaluates after first round correctly" do
    wyses = MapSet.new([])
    actions = 
      [{:set_game_type, "diamonds"}, {:play_card, %{wys: wyses, card: Card.new("diamonds", "jack")}}, {:play_card, %{wys: wyses, card: Card.new("diamonds", "7")}}, {:play_card, %{wys: wyses, card: Card.new("diamonds", "6")}}, {:play_card, %{wys: wyses, card: Card.new("diamonds", "queen")}}]
      |> Enum.reverse()
    {:ok, game_state} = Game.eval_game(@initial_state, actions)    
    assert [:next_round] == Action.eval_action_space(game_state)
  end
  test "evaluates first play in second round correctly" do
    wyses = MapSet.new([])
    actions = 
      [{:set_game_type, "diamonds"}, {:play_card, %{wys: wyses, card: Card.new("diamonds", "jack")}}, {:play_card, %{wys: wyses, card: Card.new("diamonds", "7")}}, {:play_card, %{wys: wyses, card: Card.new("diamonds", "6")}}, {:play_card, %{wys: wyses, card: Card.new("diamonds", "queen")}}, :next_round]
      |> Enum.reverse()
    {:ok, game_state} = Game.eval_game(@initial_state, actions)    
    cards = game_state.cards["pl1"] |> MapSet.new()
    assert [{:play_card, cards}] == Action.eval_action_space(game_state)
  end
  test "evaluates end correctly" do
    game_state = %GameState{@initial_state | gameType: "hearts", round: 9, turn: 0}
    assert [:end_game] == Action.eval_action_space(game_state)
  end
end
