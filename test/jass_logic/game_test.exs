defmodule GameTest do
  use ExUnit.Case

  alias JassLogic.Game
  alias JassLogic.{GameState, Card, Group, Wys}


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

  

  doctest Game
  test "with valid actions returns correct game state" do
    # 1
    {:ok, game_state} = Game.eval_game(@initial_state, [{:set_game_type, "swap"}])
    assert game_state.onTurnPlayer == "pl3"
    assert game_state.gameType == "swap"
    # 2
    {:ok, game_state} = Game.eval_game(game_state, [{:set_game_type_after_swap, "diamonds"}])
    assert game_state.gameType == "diamonds"
    assert game_state.stoeck == "pl4"
    assert game_state.round == 0
    assert game_state.turn == 0
    assert game_state.onTurnPlayer == "pl1"
    # 3
    wyses = MapSet.new([ Wys.new(:four_the_same, [Card.new("hearts", "jack"), Card.new("spades", "jack"), Card.new("diamonds", "jack"), Card.new("clubs", "jack")]) ])
    {:ok, game_state} = Game.eval_game(game_state, [{:play_card, %{wys: wyses, card: Card.new("diamonds", "jack")}}])
    assert game_state.table == [Card.new("jack", "diamonds"), nil, nil, nil]
    assert game_state.round == 0
    assert game_state.turn == 1
    assert game_state.proposed_wyses == %{"pl1" => MapSet.new([Wys.new(:four_the_same, [Card.new("hearts", "jack"), Card.new("spades","jack"),Card.new("diamonds", "jack"), Card.new( "clubs",  "jack")])]) }
    assert game_state.onTurnPlayer == "pl2"
    # 4
    assert {:error, {:reason, "invalid action"}} = Game.eval_game(game_state, [{:play_card, Card.new("diamonds", "7")}])
    
    wyses = MapSet.new([])
    {:ok, game_state} = Game.eval_game(game_state, [{:play_card, %{wys: wyses, card: Card.new("diamonds", "7")}}])
    assert game_state.table == [Card.new("jack", "diamonds"), Card.new("7", "diamonds"), nil, nil]
    assert game_state.round == 0
    assert game_state.turn == 2
    assert game_state.onTurnPlayer == "pl3"
    #5
    wyses = MapSet.new([Wys.new(:n_in_a_row, [Card.new("spades", "6"),Card.new("spades", "7"), Card.new("spades", "8")])])
    {:ok, game_state} = Game.eval_game(game_state, [{:play_card, %{wys: wyses, card: Card.new("diamonds", "6")}}])
    assert game_state.table == [Card.new("jack", "diamonds"), Card.new("7", "diamonds"), Card.new("diamonds", "6"), nil]
    assert game_state.round == 0
    assert game_state.turn == 3
    assert game_state.onTurnPlayer == "pl4"
    #5 
    wyses = MapSet.new([])
    {:ok, game_state} = Game.eval_game(game_state, [{:play_card_with_stoeck, %{wys: wyses, card: Card.new("diamonds", "queen")}}])
    assert game_state.table == [Card.new("jack", "diamonds"), Card.new("7", "diamonds"), Card.new("diamonds", "6"), Card.new("diamonds", "queen")]
    assert game_state.round == 0
    assert game_state.turn == 4
    assert (List.last game_state.groups).points == 20
    assert hd(game_state.groups).points == 220
    assert game_state.stoeck == nil
    assert game_state.onTurnPlayer == "pl1"
    #6
    {:ok, game_state} = Game.eval_game(game_state, [:next_round])
    assert game_state.table == [nil, nil, nil, nil]
    assert (List.last game_state.groups).points == 20
    assert hd(game_state.groups).points == 243
    assert game_state.round == 1
    assert game_state.turn == 0
    assert game_state.onTurnPlayer == "pl1"
    #7
    {:ok, game_state} = Game.eval_game(game_state, [{:play_card, Card.new("diamonds", "9")}])
    assert game_state.table == [Card.new("diamonds", "9"), nil, nil, nil]
    assert game_state.round == 1
    assert game_state.turn == 1
    assert game_state.onTurnPlayer == "pl2"
    # 8
    {:ok, game_state} = Game.eval_game(game_state, [{:play_card, Card.new("diamonds", "7")}])
    assert game_state.table == [Card.new("diamonds", "9"), Card.new("diamonds", "7"), nil, nil]
    assert game_state.round == 1
    assert game_state.turn == 2
    assert game_state.onTurnPlayer == "pl3"
    # 9
    {:ok, game_state} = Game.eval_game(game_state, [{:play_card, Card.new("diamonds", "10")}])
    assert game_state.table == [Card.new("diamonds", "9"), Card.new("diamonds", "7"), Card.new("diamonds", "10"), nil]
    assert game_state.round == 1
    assert game_state.turn == 3
    assert game_state.onTurnPlayer == "pl4"
    # 10
    {:ok, game_state} = Game.eval_game(game_state, [{:play_card, Card.new("diamonds", "king")}])
    assert game_state.table == [Card.new("diamonds", "9"), Card.new("diamonds", "7"), Card.new("diamonds", "10"), Card.new("diamonds", "king")]
    assert game_state.round == 1
    assert game_state.turn == 4
    assert game_state.onTurnPlayer == "pl1"
    # 11
    {:ok, game_state} = Game.eval_game(game_state, [:next_round])
    assert game_state.table == [nil, nil, nil, nil]
    assert (List.last game_state.groups).points == 20
    assert hd(game_state.groups).points == 271
    assert game_state.round == 2
    assert game_state.turn == 0
    assert game_state.onTurnPlayer == "pl1"
    #12
    {:ok, game_state} = Game.eval_game(game_state, [{:play_card, Card.new("spades", "king")}])
    assert game_state.table == [Card.new("spades", "king"), nil, nil, nil]
    assert game_state.round == 2
    assert game_state.turn == 1
    assert game_state.onTurnPlayer == "pl2"
    # 13
    {:ok, game_state} = Game.eval_game(game_state, [{:play_card, Card.new("spades", "queen")}])
    assert game_state.table == [Card.new("spades", "king"), Card.new("spades", "queen"), nil, nil]
    assert game_state.round == 2
    assert game_state.turn == 2
    assert game_state.onTurnPlayer == "pl3"
    # 14
    {:ok, game_state} = Game.eval_game(game_state, [{:play_card, Card.new("spades", "10")}])
    assert game_state.table == [Card.new("spades", "king"), Card.new("spades", "queen"), Card.new("spades", "10"), nil]
    assert game_state.round == 2
    assert game_state.turn == 3
    assert game_state.onTurnPlayer == "pl4"
    # 15
    {:ok, game_state} = Game.eval_game(game_state, [{:play_card, Card.new("spades", "ace")}])
    assert game_state.table == [Card.new("spades", "king"), Card.new("spades", "queen"), Card.new("spades", "10"), Card.new("spades", "ace")]
    assert game_state.round == 2
    assert game_state.turn == 4
    assert game_state.onTurnPlayer == "pl1"
    # 16
    {:ok, game_state} = Game.eval_game(game_state, [:next_round])
    assert game_state.table == [nil, nil, nil, nil]
    assert (List.last game_state.groups).points == 48
    assert hd(game_state.groups).points == 271
    assert game_state.round == 3
    assert game_state.turn == 0
    assert game_state.onTurnPlayer == "pl4"
  end
  test "With invalid action returns error" do
    invalid_action = {:invalid_action, :something}
      assert {:error, {:reason, "invalid action"}} == Game.eval_game(@initial_state, [invalid_action])
  end
end
