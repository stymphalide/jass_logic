defmodule GroupTest do
  use ExUnit.Case

  alias JassLogic.Group
  alias JassLogic.Card
  @valid_players ["pl1", "pl2", "pl3", "pl4"]
  @invalid_players [[], "hell", :an_atom, ["pl1", "pl2", "pl3"]]

  doctest Group
  test "initialises correctly on valid players" do
    correct_groups =
      [%Group{players: ["pl1", "pl3"], points: 0, wonCards: []}, %Group{players: ["pl2", "pl4"], points: 0, wonCards: []}]
    assert correct_groups == Group.initialise_groups(@valid_players)
  end
  test "yields error with invalid players" do
    Enum.map @invalid_players, fn invalid_players ->
      assert :error == Group.initialise_groups(invalid_players)
    end
  end
end

