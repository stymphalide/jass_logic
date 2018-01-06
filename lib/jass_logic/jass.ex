defmodule JassLogic.Jass do
  @moduledoc """
  Schieber Jass Simulation
  """

  alias JassLogic.Game
  alias JassLogic.GameState
  alias JassLogic.Action
  alias JassLogic.Validation

  @doc """
    start_game(players, opts \\ %{onTurnPlayer, groups})
    Takes a list of 4 unique players and an option map

    Returns a tuple {:ok, game_state}
    Or {:error, error}
  """
  def start_game(players, opts \\ false) do
    if opts do
      GameState.new(players, opts)
    else
      GameState.new(players, %{onTurnPlayer: false, groups: false})
    end
  end


  @doc """
    play(init, actions, action)
    Takes an initial game_state, a list of actions and a particular action.

    Returns a tuple {:ok, {init, actions, game_state, action_space}}
    Or {:error, {:reason, reason}}
  """
  def play(init, actions, action) do
    {:ok, current_game_state} = 
      Game.eval_game(init, actions)
    current_action_space =
      Action.eval_action_space(current_game_state)
    if Validation.validate_action(current_action_space, action) do
      {:ok, next_game_state} =
        Game.eval_game(current_game_state, [action])
      new_action_space =
        Action.eval_action_space(next_game_state)
      next_actions =
        [action | actions]

      {:ok, {init, next_actions, next_game_state, new_action_space,}}
    else
      {:error, {:reason, "invalid action"}}
    end
  end


end
