defmodule JassLogic.Group do
  @moduledoc false
  defstruct players: [], points: 0, wonCards: []
  @doc """
  Takes in a list of 4 players
  returns a list of two groups, with two players each.

  

  ## Example
  iex> Group.initialise_groups(["pl1", "pl2", "pl3", "pl4"])
  {:ok, [%Group{players: ["pl1", "pl3"], points: 0, wonCards: []}, %Group{players: ["pl2", "pl4"], points: 0, wonCards: []}]}

  iex> Group.initialise_groups([])
  {:error, {:reason, "invalid players"}}

  `initialise_groups/1`

  """
  def initialise_groups([pl1, pl2, pl3, pl4]) do
    {:ok, [%__MODULE__{players: [pl1, pl3]}, %__MODULE__{players: [pl2, pl4]}]}
  end
  def initialise_groups(_players) do
    {:error, {:reason, "invalid players"}}
  end

end
  