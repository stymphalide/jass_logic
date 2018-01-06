defmodule ValidationTest do
  use ExUnit.Case
  alias JassLogic.Validation, as: V
  alias JassLogic.Card


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
end
