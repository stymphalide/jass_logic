defmodule JassLogic.Jass do
  @moduledoc """
  Schieber Jass Simulation
  GenServer for the game
  """
  @timeout 24* 60 * 60 *1000 # Timeout after one day.

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
    send(self(), {:set_state, params})
    {:ok, start_game(params)}
  end
  def handle_info({:set_state, params}, _state_data) do
    name = generate_name(params.players)
    state_data =
      case :ets.lookup(:state_data, name) do
        [] -> start_game(params)
        [{_key, state_data}] -> state_data
      end
      :ets.insert(:state_data, {name, state_data})
      {:noreply, state_data, @timeout}
  end
  def handle_info(:timeout, state_data) do
    {:stop, {:shutdown, :timeout}, state_data}
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

  def terminate({:shutdown, :timeout}, state_data) do
    :ets.delete(:state_data, generate_name(state_data.init.players))
    :ok
  end
  def terminate(_reason, _state), do: :ok

  # Helpers
  defp start_game(params = %{players: players}) do
    game_state = GameState.new(players, params)
    action_space = Action.eval_action_space(game_state)
    %{init: game_state, game_state: game_state, actions: [], action_space: action_space}
  end

  
  defp reply_error(state_data) do
    {:reply, :error, state_data, @timeout}
  end

  defp reply_success(state_data, reply) do
    :ets.insert(:state_data, {generate_name(state_data.game_state.players), state_data})
    {:reply, reply, state_data, @timeout}
  end
end
