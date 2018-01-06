defmodule GameTest do
  use ExUnit.Case

  alias JassLogic.Game
  alias JassLogic.Card

  @initial_state %JassLogic.GameState{cards: %{"pl1" => [%Card{color: "hearts", number: "jack"},
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
   groups: [%JassLogic.Group{players: ["pl1", "pl3"], points: 0, wonCards: []},
    %JassLogic.Group{players: ["pl2", "pl4"], points: 0, wonCards: []}],
   onTurnPlayer: "pl1", players: ["pl1", "pl2", "pl3", "pl4"], proposed_wyses: [],
   round: 0, stoeck: nil, table: [nil, nil, nil, nil], turn: 0, valid_wyses: []}

  

  doctest Game
  test "with valid actions returns correct game state" do
    # 1
    {:ok, game_state } = Game.eval_game(@initial_state, [{:set_game_type, "swap"}])
    assert game_state.onTurnPlayer == "pl3"
    assert game_state.gameType == "swap"
    # 2
    {:ok, game_state} = Game.eval_game(game_state, [{:set_game_type_after_swap, "diamonds"}])
    assert game_state.onTurnPlayer == "pl1"
    assert game_state.gameType == "diamonds"
    # 3
    {:ok, game_state} = Game.eval_game(game_state, [{:play_card, %{wys: [{:four_the_same, [Card.new("hearts", "jack"), Card.new("spades", "jack"), Card.new("diamonds", "jack"), Card.new("clubs", "jack")]}], card: Card.new("diamonds", "jack")}}])

  end
  test "With invalid action returns error" do
    invalid_action = {:invalid_action, :something}
      assert {:error, {:reason, "invalid action"}} == Game.eval_game(@initial_state, [invalid_action])
  end
end
