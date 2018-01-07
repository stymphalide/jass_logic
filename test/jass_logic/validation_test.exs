defmodule ValidationTest do
  use ExUnit.Case
  alias JassLogic.Validation, as: V
  alias JassLogic.{Card, Wys}


  # validate_card(card, cards_player, cards_on_table, game_type)
  doctest V
  test "One can play anything, when the table is empty" do
    assert V.validate_card(%{}, [], [], "")
  end
  test "play the same color as on table is possible" do
    assert V.validate_card(%Card{color: "hearts", number: "jack"}, 
                            [], 
                            [%{color: "hearts", number: "10"}], 
                            "")
  end
  test "One can play another color if that is forced" do
    assert V.validate_card(%Card{color: "hearts", number: "jack"}, 
                            [%Card{color: "hearts", number: "jack"}], 
                            [%Card{color: "spades", number: "jack"}], 
                            "diamonds")
  end
  test "one can play trumpf, even it is not the required color" do
    assert V.validate_card(%Card{color: "hearts", number: "jack"}, 
                            [%Card{color: "hearts", number: "jack"}, 
                            %Card{color: "spades", number: "10"}], 
                            [%Card{color: "spades", number: "jack"}], 
                            "hearts")
  end
  test "One does not have to play the jack" do
    assert V.validate_card(%Card{color: "spades", number: "10"}, 
                            [%Card{color: "hearts", number: "jack"}, 
                            %Card{color: "spades", number: "10"}], 
                            [%Card{color: "hearts", number: "9"}], 
                            "hearts")
  end
  test "One cann not undertrumpf" do
    refute V.validate_card(%Card{color: "hearts", number: "10"}, 
                            [%Card{color: "hearts", number: "10"}, 
                            %Card{color: "spades", number: "10"}], 
                            [%Card{color: "spades", number: "9"}, 
                            %Card{color: "hearts", number: "9"}], 
                            "hearts")
  end
  test "One can undertrumpf, if that is forced" do
    assert V.validate_card(%Card{color: "hearts", number: "10"}, 
                            [%Card{color: "hearts", number: "10"},
                            %Card{color: "hearts", number: "6"}], 
                            [%Card{color: "spades", number: "9"}, 
                            %Card{color: "hearts", number: "9"}], 
                            "hearts") 
    refute V.validate_card(%Card{color: "hearts", number: "10"}, 
                            [%Card{color: "hearts", number: "10"},
                            %Card{color: "hearts", number: "6"}, 
                            %Card{color: "diamonds", number: "10"}], 
                            [%Card{color: "spades", number: "9"}, 
                            %Card{color: "hearts", number: "9"}], 
                            "hearts")
  end

  # validation action space
  test "validate_action/2 action possible if in action space" do
    action_space = MapSet.new([:end_game])
    assert V.validate_action(action_space, :end_game)
  end
  test "validate_action/2 play_card possible with valid card" do
    action_space = MapSet.new([{:play_card, MapSet.new([Card.new("hearts", "6")])}])
    action = {:play_card, Card.new("hearts", "6")}
    assert V.validate_action(action_space, action)
  end
  test "validate_action/2 play_card not possible if card not valid" do
    action_space = MapSet.new([{:play_card, MapSet.new([Card.new("hearts", "6")])}])
    action = {:play_card, Card.new("clubs", "6")}
    refute V.validate_action(action_space, action)
  end
  test "validate_action/2 action not valid if not in action_space" do
    action_space = MapSet.new([:end_game])
    refute V.validate_action(action_space, :next_round)
  end
  test "validate_action/2 card with wys valid if in action space" do
    cards = MapSet.new([Card.new("hearts", "6"), Card.new("hearts", "7"), Card.new("hearts", "8")])
    wyses = Wys.find_possible_wyses(cards)
    action_space = MapSet.new([{:play_card, %{wys: wyses, card: cards}}])
    action = {:play_card, %{wys: MapSet.new([]), card: Card.new("hearts", "6")}}
    assert V.validate_action(action_space, action)

    action = {:play_card, %{wys: wyses, card: Card.new("hearts", "6")}}
    assert V.validate_action(action_space, action)
  end
  test "validate_action/2 action in first round not valid, if it is a wrong card or wrong wys" do
    cards = MapSet.new([Card.new("hearts", "6"), Card.new("hearts", "7"), Card.new("hearts", "8")])
    wyses = Wys.find_possible_wyses(cards)
    action_space = MapSet.new([{:play_card, %{wys: wyses, card: cards}}])
    action = {:play_card, %{wys: MapSet.new([]), card: Card.new("clubs", "6")}}
    refute V.validate_action(action_space, action)

    false_wys = [%Wys{name: :four_the_same, cards: Wys.generate_four_the_same("jack")}] |> MapSet.new()
    action = {:play_card, %{wys: false_wys, card: Card.new("hearts", "6")}}
    refute V.validate_action(action_space, action)
  end
end
