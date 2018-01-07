defmodule JassLogic.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: JassLogic.Worker.start_link(arg)
      # {JassLogic.Worker, arg},
      {Registry, keys: :unique, name: Registry.Jass},
      JassLogic.JassSupervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    :ets.new(:state_data, [:public, :named_table])
    opts = [strategy: :one_for_one, name: JassLogic.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
