defmodule JassLogic.Jass do
  @moduledoc """
  Schieber Jass Simulation
  GenServer for the game
  """
  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient

  alias JassLogic.Game
  alias JassLogic.GameState
  alias JassLogic.Action
  alias JassLogic.Validation

  def generate_name(players), do: Enum.intersperse(players, "_") |> List.to_string()
  def via_tuple(name) do
    {:via, Registry, {Registry.Jass, name}}
  end
  
  # Client function
  def start_link(%{players: players} = params ) when is_list(players) and length(players) == 4 do
    IO.inspect(players)
    name = generate_name(players)
    GenServer.start_link(__MODULE__, params, name: via_tuple(name))
  end
  def play(game, action) do
    GenServer.call(game, action)
  end


  # Callbacks
  def init(params) do
    state_data =
      start_game(params)
    {:ok, state_data}
  end
  def handle_call(action, _from, %{init: init, action_space: action_space, actions: actions, game_state: game_state}) do
    if Validation.validate_action(action_space, action) do
      {:ok, next_game_state} =
        Game.eval_game(game_state, [action])
      new_action_space =
        Action.eval_action_space(next_game_state)
      next_actions =
        [action | actions]
      state_data = %{init: init, game_state: next_game_state, action_space: new_action_space, actions: next_actions}

      reply_success(state_data, :ok)
    else
      state_data =
        %{init: init, game_state: game_state, actions: actions, action_space: action_space}
      reply_error(state_data)
    end
  end


  defp start_game(params = %{players: players}) do
    game_state = GameState.new(players, params)
    action_space = Action.eval_action_space(game_state)
    %{init: game_state, game_state: game_state, actions: [], action_space: action_space}
  end

  
  defp reply_error(state_data) do
    {:reply, :error, state_data}
  end

  defp reply_success(state_data, reply) do
    {:reply, reply, state_data}
  end
end
