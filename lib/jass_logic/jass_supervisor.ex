defmodule JassLogic.JassSupervisor do
  use Supervisor

  alias JassLogic.Jass
  # Client Functions
  def start_link(_options) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end
  def start_game(players, opts \\ false)
  def start_game(players, %{onTurnPlayer: onTurnPlayer, groups: groups}) do
    params = %{players: players, onTurnPlayer: onTurnPlayer, groups: groups}
    Supervisor.start_child(__MODULE__, [params])
  end
  def start_game(players, _opts) do
    params = %{players: players, onTurnPlayer: false, groups: false}
    Supervisor.start_child(__MODULE__, [params])
  end
  def stop_game(players) do
    :ets.delete(:state_data, Jass.generate_name(players))
    Supervisor.terminate_child(__MODULE__, pid_from_players(players))
  end

  # Callbacks
  def init(:ok) do
    Supervisor.init([Jass], strategy: :simple_one_for_one)
  end


  # Helper
  defp pid_from_players(players) do
    players
    |> Jass.generate_name()
    |> Jass.via_tuple()
    |> GenServer.whereis()
  end
end