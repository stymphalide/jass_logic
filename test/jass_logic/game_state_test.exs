defmodule GameStateTest do
  use ExUnit.Case
  alias JassLogic.GameState
  alias JassLogic.Group

  @valid_players ["pl1", "pl2", "pl3", "pl4"]
  @invalid_players [[], "hell", :an_atom, ["pl1", "pl2", "pl3"]]
  
  doctest GameState
  test "new with valid players works" do
    {:ok, game_state} = GameState.new(@valid_players)  
    assert game_state.players == @valid_players
  end
  test "new with invalid players yields error" do
    Stream.map @invalid_players, fn invalid_players ->
      assert {:error, {:reason, "invalid players"}} == GameState.new(invalid_players)
    end
  end
  test "new with options works" do
    {:ok, groups} = 
      Group.initialise_groups(@valid_players)
    new_groups =
    Enum.map(groups, fn group -> 
        %Group{group |  points: 42}
      end)
    {:ok, game_state} = GameState.new(@valid_players, %{onTurnPlayer: "pl1", groups: new_groups})
    assert game_state.onTurnPlayer == "pl1"
    assert (hd game_state.groups).points == 42
  end
end

