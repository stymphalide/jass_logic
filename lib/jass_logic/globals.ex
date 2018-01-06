defmodule JassLogic.Globals do
  @moduledoc """
  Holder for global values
  """ 
  @doc """
    Returns a list of 4 colors
    ## Example
    iex> Globals.colors()
    ["hearts", "diamonds", "spades", "clubs"]

    `colors/0`
  """  
  def colors do
    ["hearts", "diamonds", "spades", "clubs"]
  end
  @doc """
    Returns a list of 9 numbers.
    
    ## Example
    iex> Globals.numbers()
    ["6", "7", "8", "9", "10", "jack", "queen", "king", "ace"]

    `numbers/0`
  """
  def numbers do
    ["6", "7", "8", "9", "10", "jack", "queen", "king", "ace"]
  end
  @doc """
    Returns a list of 7 game types

    ## Example
    iex> Globals.game_types()
    ["swap", "hearts", "diamonds", "spades", "clubs", "up", "down"]

    `game_types/0`
  """
  def game_types do
    ["swap", "hearts", "diamonds", "spades", "clubs", "up", "down"]
  end

  @doc """
  multiplier(game_type) ==> int
  Provides a multiplier for a score, depending on the game_type
  This function is used for calculating the scores.

  ## Example
  iex> Globals.multiplier("up")
  3

  iex> Globals.multiplier("invalid_game_type")
  :error

  `multiplier/1`
  """
  def multiplier("up"),       do: 3
  def multiplier("down"),     do: 3
  def multiplier("spades"),   do: 2
  def multiplier("clubs"),    do: 2
  def multiplier("hearts"),   do: 1
  def multiplier("diamonds"), do: 1
  def multiplier(_),          do: :error



  @doc """
    Globals.rotate_list(list) ==> list
    Helper function for lists, 
    Sets the head of the list to the tail.
    
    ## Example
    iex> Globals.rotate_list([1,2,3,4,])
    [2,3,4,1,]

    iex> Globals.rotate_list([])
    []


    `rotate_list/1`
  """
  def rotate_list([]), do: []
  def rotate_list([head | tail]), do: [tail, head] |> List.flatten()
end
