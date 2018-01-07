defmodule WysTest do
  use ExUnit.Case
  alias JassLogic.Wys
  alias JassLogic.Card
  alias JassLogic.Globals

  doctest Wys
  test "new/2 creates new wyses with valid inputs correctly" do
    cards = [%Card{color: "hearts", number: "6"}, %Card{color: "diamonds", number: "6"}, %Card{color: "spades", number: "6"}, %Card{color: "clubs", number: "6"}]
    
    wys_cards = MapSet.new(cards)

    assert Wys.new(:four_the_same, cards) == %Wys{name: :four_the_same, cards: wys_cards}

    cards = [%Card{color: "hearts", number: "6"}, %Card{color: "hearts", number: "7"}, %Card{color: "hearts", number: "8"}]
    wys_cards = MapSet.new(cards)
    assert Wys.new(:n_in_a_row, cards) == %Wys{name: :n_in_a_row, cards: wys_cards}
  end
  test "new/2 yields error with invalid inputs" do
        
    assert Wys.new(:invalid_name, []) == :error
    
    # Wrong cards n_in_a_row
    assert :error == Wys.new(:n_in_a_row, [%Card{color: "hearts", number: "6"}, %Card{color: "hearts", number: "7"}, %Card{color: "hearts", number: "9"}])
    # Wrong cards four the same

    wrong_cards = [%Card{color: "hearts", number: "7"}, %Card{color: "diamonds", number: "6"}, %Card{color: "spades", number: "6"}, %Card{color: "clubs", number: "6"}]
    assert :error  ==  Wys.new(:four_the_same, wrong_cards)
  end
  test "points/2 sets points correctly" do
    
    # Jacks correctly 
    cards =
      [%JassLogic.Card{color: "hearts", number: "jack"}, %JassLogic.Card{color: "diamonds", number: "jack"}, %JassLogic.Card{color: "spades", number: "jack"}, %JassLogic.Card{color: "clubs", number: "jack"}]
      |> MapSet.new()
    assert 600 == Wys.points("up", %{name: :four_the_same, cards: cards})
    # Nells correctly
    cards =
      [%JassLogic.Card{color: "hearts", number: "9"}, %JassLogic.Card{color: "diamonds", number: "9"}, %JassLogic.Card{color: "spades", number: "9"}, %JassLogic.Card{color: "clubs", number: "9"}]
      |> MapSet.new()
    assert 300 == Wys.points("spades", %{name: :four_the_same, cards: cards})
    # 5 in a row
    cards = 
      [%JassLogic.Card{color: "hearts", number: "8"}, %JassLogic.Card{color: "hearts", number: "9"}, %JassLogic.Card{color: "hearts", number: "10"}, %JassLogic.Card{color: "hearts", number: "jack"}, %JassLogic.Card{color: "hearts", number: "queen"}]
      |> MapSet.new()
    assert 100 == Wys.points("hearts", %{name: :n_in_a_row, cards: cards})
    # 4 in a row
    cards =
      [%JassLogic.Card{color: "hearts", number: "7"}, %JassLogic.Card{color: "hearts", number: "8"}, %JassLogic.Card{color: "hearts", number: "9"}, %JassLogic.Card{color: "hearts", number: "10"} ]
      |> MapSet.new()
    assert Wys.points("clubs", %{name: :n_in_a_row, cards: cards}) == 100
    # 3 in a row
    cards = 
      [%JassLogic.Card{color: "hearts", number: "8"}, %JassLogic.Card{color: "hearts", number: "9"}, %JassLogic.Card{color: "hearts", number: "10"} ]
      |> MapSet.new()
    assert Wys.points("down", %{name: :n_in_a_row, cards: cards}) == 60
  end
  test "ordering/4 orders wyses correctly" do
    four_the_sames = 
      Enum.map(Globals.numbers(), fn number ->
        %Wys{name: :four_the_same, cards: Wys.generate_four_the_same(number)
      } 
    end)

    # Regular sort
    sorted = 
      Enum.sort_by(four_the_sames, &(Wys.ordering("up", &1, "pl1", ["pl1", "pl3"])))
    
    assert hd(sorted) == %Wys{name: :four_the_same, cards: Wys.generate_four_the_same("6")}
    assert List.last(sorted) == %Wys{name: :four_the_same, cards: Wys.generate_four_the_same("jack")}
    # Reverse sort
    sorted =
      Enum.sort_by(four_the_sames, &(Wys.ordering("down", &1, "pl1", ["pl1", "pl3"])))
    assert List.last(sorted) == %Wys{name: :four_the_same, cards: Wys.generate_four_the_same("jack")}
    assert hd(sorted) == %Wys{name: :four_the_same, cards: Wys.generate_four_the_same("ace")}

    # Make sure the same applies for n_in_a_row
    n_in_a_row1 =
      %Wys{name: :n_in_a_row, cards: Wys.generate_wys_cards(:n_in_a_row, Card.new("6", "hearts"), 5)}
    n_in_a_row2 =
      %Wys{name: :n_in_a_row, cards: Wys.generate_wys_cards(:n_in_a_row, Card.new("6", "clubs"), 4)}
    #1
    assert Wys.ordering("up", n_in_a_row1, "pl1", ["pl1", "pl3"]) > Wys.ordering("up", n_in_a_row2, "pl1", ["pl1", "pl3"])
    
    n_in_a_row1 =
      %Wys{name: :n_in_a_row, cards: Wys.generate_wys_cards(:n_in_a_row, Card.new("6", "hearts"), 4)}

    #2
    assert Wys.ordering("up", n_in_a_row1, "pl1", ["pl1", "pl3"]) > Wys.ordering("up", n_in_a_row2, "pl2", ["pl1", "pl3"])

    n_in_a_row1 =
      %Wys{name: :n_in_a_row, cards: Wys.generate_wys_cards(:n_in_a_row, Card.new("7", "hearts"), 4)}
    # 3
    assert Wys.ordering("down", n_in_a_row1, "pl1", ["pl1", "pl3"]) < Wys.ordering("down", n_in_a_row2, "pl2", ["pl1", "pl3"])
  end
  test "find_possible_wyses/1 finds all possible wyses" do
    cards = [Card.new("hearts", "6"), Card.new("hearts", "7"), Card.new("hearts", "8"), Card.new("clubs", "6"), Card.new("diamonds", "6"), Card.new("spades", "6")]
    expected = [%Wys{name: :four_the_same, cards: Wys.generate_four_the_same("6")},
                %Wys{name: :n_in_a_row, cards: Wys.generate_wys_cards(:n_in_a_row, Card.new("hearts", "6"))}]
                |> MapSet.new()
    assert expected == Wys.find_possible_wyses(MapSet.new(cards))
  end
  test "generate_stoeck/1 generates stoeck with valid input" do
    cards = 
      [Card.new("hearts", "queen"), Card.new("hearts", "king")]
      |> MapSet.new()
    assert cards == Wys.generate_stoeck("hearts")
  end
  test "generate_stoeck/1 yields error with invalid input" do
    assert :error == Wys.generate_stoeck("up")
    assert :error == Wys.generate_stoeck("down")
  end
  test "four_the_same/1 generates with valid number" do
    cards = 
      [Card.new("hearts", "9"), Card.new("diamonds", "9"), Card.new("spades", "9"), Card.new("clubs", "9")]
      |> MapSet.new()
    assert cards == Wys.generate_four_the_same("9")
  end
  test "four_the_same/1 yields error with invalid number" do
    assert :error == Wys.generate_four_the_same("5")
  end
  test "generate_wys_cards/3 generates correct :four_the_same with valid input" do
    cards =
      [Card.new("hearts", "9"), Card.new("diamonds", "9"), Card.new("spades", "9"), Card.new("clubs", "9")]
      |> MapSet.new()
    assert cards == Wys.generate_wys_cards(:four_the_same, Card.new("hearts", "9"))
  end
  test "generate_wys_cards/3 generates correct :n_in_a_row with valid input" do
    cards = [%Card{color: "hearts", number: "6"}, %Card{color: "hearts", number: "7"}, %Card{color: "hearts", number: "8"}]
    |> MapSet.new()

    assert cards == Wys.generate_wys_cards(:n_in_a_row, Card.new("hearts", "6"), 3)
  end
  test "generate_wys_cards/3 yields :error with invalid inputs" do
    assert :error == Wys.generate_wys_cards(:invalid_name, Card.new("hearts", "6"))
    assert :error == Wys.generate_wys_cards(:n_in_a_row, Card.new("hearts", "ace"))
  end
  test "find_stoeck/2 finds the player with the stoeck, when given valid input" do
    cards = %{"pl1" => [Card.new("hearts", "queen"), Card.new("hearts", "king")]}
    assert "pl1" == Wys.find_stoeck(cards, "hearts")
  end
  test "find_stoeck/2 returns nil if there is no stoeck" do
    assert nil == Wys.find_stoeck(%{}, "up")
    cards = %{"pl1" => [Card.new("hearts", "queen"), Card.new("hearts", "ace")]}
    assert nil == Wys.find_stoeck(cards, "hearts")
  end
  test "find_valid_wyses/3 returns correct wyses for valid input" do
    cards = %{"pl1" => Wys.generate_four_the_same("jack"),
              "pl2" => Wys.generate_wys_cards(:n_in_a_row, Card.new("hearts", "7")),
              "pl3" => Wys.generate_wys_cards(:n_in_a_row, Card.new("clubs", "6")),
              "pl4" => Wys.generate_four_the_same("ace")
            }

    wyses = %{"pl1" => %Wys{cards: cards["pl1"], name: :four_the_same},
              "pl2" => %Wys{cards: cards["pl2"], name: :n_in_a_row},
              "pl3" => %Wys{cards: cards["pl3"], name: :n_in_a_row},
              "pl4" => %Wys{cards: cards["pl4"], name: :four_the_same},
            }
    proposed_wyses =
      [{"pl1", MapSet.new([wyses["pl1"]])}, 
       {"pl2", MapSet.new([wyses["pl2"]])},
       {"pl3", MapSet.new([wyses["pl3"]])},
       {"pl4", MapSet.new([wyses["pl4"]])},
      ]
    valid_wyses = 
      [{"pl1", MapSet.new([wyses["pl1"]])}, 
       {"pl3", MapSet.new([wyses["pl3"]])},
      ]
    assert valid_wyses == Wys.find_valid_wyses(proposed_wyses, "hearts", ["pl1", "pl3"])
    #2
    proposed_wyses =
      [{"pl1", MapSet.new([])}, 
       {"pl2", MapSet.new([wyses["pl2"]])},
       {"pl3", MapSet.new([wyses["pl3"]])},
       {"pl4", MapSet.new([])},
      ]
    valid_wyses =
      [{"pl2", MapSet.new([wyses["pl2"]])}, {"pl4", MapSet.new([])},]
    assert valid_wyses == Wys.find_valid_wyses(proposed_wyses, "hearts", ["pl1", "pl3"])
    #3
    valid_wyses =
      [{"pl1", MapSet.new([])}, {"pl3", MapSet.new([wyses["pl3"]])}]
    assert valid_wyses == Wys.find_valid_wyses(proposed_wyses, "down", ["pl1", "pl3"])
  end
end
