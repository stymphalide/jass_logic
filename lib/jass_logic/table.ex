defmodule JassLogic.Table do
  @moduledoc """
  Helper functions for table actions
  """
  alias JassLogic.Globals

  @doc """
    new() ==> List

    Returns an empty table

    iex> Table.new()
    [nil, nil, nil, nil]
  """
  def new() do
    [nil, nil, nil, nil]
  end

  def update_table(table, players, onTurnPlayer, card) do
    table
      |> Enum.zip(players)
      |> Enum.map(fn {old_card, player} -> 
        if player == onTurnPlayer do
          card
        else
          old_card
        end
      end)
  end


  # Returns a list of cards, in the order they were played
  @doc """
    order_table(table, cards, onTurnPlayer) ==> [Card]
    
    iex> Table.order_table([3, 4, 1, 2], ["a", "b", "c", "d"], "c")
    [1,2,3,4]

    `order_table/3`
  """
  def order_table(table = [nil, nil, nil, nil], _players, _first_to_play), do: table
  def order_table(table, players, first_to_play) do
    {sorted_table, _players} =
      table
      |> Enum.zip(players)
      |> order_table(first_to_play)
      |> Enum.unzip()
    sorted_table
  end

  defp order_table(cards_player = [{_card1, onTurnPlayer} | _tail],  onTurnPlayer) do
    cards_player
  end
  defp order_table(cards_player,  onTurnPlayer) do
    order_table(Globals.rotate_list(cards_player), onTurnPlayer)
  end
end