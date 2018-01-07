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
    players
    |> Globals.rotate_list()
    |> Enum.zip(players)
    |> Enum.filter(fn {pl1, _pl2} -> pl1 == onTurnPlayer end)
    |> Enum.map(fn {_pl1, pl2} -> pl2 end)
    |> List.first()
  end
end