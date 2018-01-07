defmodule JassLogic.Player do


  alias JassLogic.Globals

  def swap_players(players, onTurnPlayer) do
    players
    |> Globals.rotate_list()
    |> Globals.rotate_list()
    |> Enum.zip(players)
    |> Enum.filter(fn {pl1, _pl2} -> pl1 == onTurnPlayer end)
    |> Enum.map(fn {_pl1, pl2} -> pl2 end)
    |> List.first()
  end
  # Finds the next player in the list.
  def next_player(players, onTurnPlayer) do
    new_players =
    players
    |> Globals.rotate_list()
    players
    |> Enum.zip(new_players)
    |> Enum.filter(fn {pl1, _pl2} -> pl1 == onTurnPlayer end)
    |> Enum.map(fn {_pl1, pl2} -> pl2 end)
    |> List.first()
  end
  @doc """
  
    iex> Player.last_player([1,2,3,4], 4)
    3
  """
  def last_player(players, onTurnPlayer) do
    Enum.zip(players, Globals.rotate_list(players))
    |> Enum.filter(fn {_pl1, pl2} -> pl2 == onTurnPlayer end)
    |> Enum.map(fn {pl1, _pl2} -> pl1 end)
    |> List.first()
  end
  @doc """
    iex> Player.first([1,2,3,4], 4, 0)
    4

    iex> Player.first([1,2,3,4], 1, 1)
    4
  """
  def first(_players, onTurnPlayer, 0), do: onTurnPlayer
  def first(players, onTurnPlayer, turn) do
    Enum.reduce 1..turn, onTurnPlayer, fn _, acc -> last_player(players,acc) end
  end
end