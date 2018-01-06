defmodule JassTest do
  use ExUnit.Case


  alias JassLogic.Jass
  alias JassLogic.GameState
  alias JassLogic.Card

    doctest Jass

    {:ok, init} = GameState.new(["pl1", "pl2", "pl3", "pl4"])
    @init init

    test "updates game correctly with valid action" do
      valid_action = {:set_game_type, "swap"}
      {:ok, {init, actions, game_state, _action_space}} = Jass.play(@init, [], valid_action)
      assert init == @init
      assert actions == [valid_action]
      assert game_state.gameType == "swap"
    end
    test "yields error with invalid action" do
      invalid_action = {:play_card, Card.new("hearts", "9")}
      assert {:error, {:reason, "invalid action"}} == Jass.play(@init, [], invalid_action)
    end
end
