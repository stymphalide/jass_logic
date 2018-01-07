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


  # Returns a list of cards, in the order they were played
  @doc """
    order_table(table, cards, onTurnPlayer) ==> [Card]
    
    iex> Table.order_table([3, 4, 1, 2], ["a", "b", "c", "d"], "b")
    [1,2,3,4]

    `order_table/3`
  """
  def order_table(table, players, onTurnPlayer) do
    {sorted_table, _players} =
      table
      |> Enum.zip(players)
      |> order_table(onTurnPlayer)
      |> Enum.unzip()
    sorted_table
  end

  defp order_table(cards_player = [{_card1, onTurnPlayer} | _tail],  onTurnPlayer) do
    Globals.rotate_list(cards_player)
  end
  defp order_table(cards_player,  onTurnPlayer) do
    order_table(Globals.rotate_list(cards_player), onTurnPlayer)
  end


end