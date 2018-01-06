defmodule JassLogic.Card do
  @enforce_keys [:color, :number]
  defstruct [:color, :number] 

  @moduledoc """
    Functions Connected to cards
  """
  alias __MODULE__
  alias JassLogic.Globals

  @colors Globals.colors()
  @numbers Globals.numbers()
  @doc """
    new(color, number) ==> %Card{}
    Takes two strings, color and number and returns a %Card{struct}
    ## Example

    iex> Card.new("hearts", "6")
    %Card{color: "hearts", number: "6"}

    iex> Card.new("up", "5")
    :error

    `new/2`
  """
  def new(color, number) when color in @colors and number in @numbers do
    %__MODULE__{color: color, number: number}
  end
  def new(_color, _number) do
    :error
  end

  @doc """
    generate_deck() ==> List of length 36
    Generates a deck of cards, meaning a list of all possible cards, occurring exactly once.

    `generate_deck/0`
  """
  def generate_deck do
    deck =
      Enum.map @colors, fn color ->
        Enum.map @numbers, fn number ->
          new(color, number)
        end
      end
    List.flatten(deck)
  end

  @doc """
    next_card(card) ==> %Card{}
    Returns the next higher card of the same color, nil if the card is an ace

    `next_card/1`
  """
  def next_card(%Card{number: "ace"}), do: nil
  def next_card(%Card{number: number, color: color}) do
    {^number, next_number} =
      Enum.zip @numbers, Globals.rotate_list(@numbers)
      |> Enum.find(fn n -> 
        n == number
      end)
    Card.new(color, next_number)
  end

  @doc """
    sorting(card) ==> int
    Provides a ranking for cards, starting at "hearts 6" = 1 and
    "clubs ace" = 49
    To be used in combination with `Enum.sort_by/2`
    The number is acquired by the basic order 
    The order for the color is as follows hearts > spades > diamonds > clubs
    
    ## Example
    iex> Card.sorting(%JassLogic.Card{color: "hearts", number: "6"})
    1
    
    iex> Card.sorting(%JassLogic.Card{color: "clubs", number: "ace"})
    39

    `sorting/1`
  """
  def sorting(%Card{color: "hearts", number: number}), do: basic_order(number)
  def sorting(%Card{color: "spades", number: number}), do: basic_order(number) + 10
  def sorting(%Card{color: "diamonds", number: number}), do: basic_order(number) + 20
  def sorting(%Card{color: "clubs", number: number}), do: basic_order(number) + 30


  @doc """
    ordering(game_type, required_color, card) ==> int
    Provides a ranking for the cards. In contrary to `sorting/1`,
    `ordering/3` is dependant on the game type, the first played color and the given card.

    The ranking behaves differently for each game_type, but has for every combination a different value.
    
    In the down scenario, the lowest card matching the required color is ranked highest
    In the up scenarios, the highest card matching the required color is required highest
    In the trumpf scenarios, trumpf is valued highest, then it follows the up scenario.
    
    ## Example
    iex> Card.ordering("up", "hearts", %Card{color: "hearts", number: "ace"})
    90
    iex> Card.ordering("up", "hearts", %Card{color: "spades", number: "ace"})
    9
    
    iex> Card.ordering("down", "hearts", %Card{color: "hearts", number: "ace"})
    10
    iex> Card.ordering("down", "hearts", %Card{color: "spades", number: "ace"})
    1

    iex> Card.ordering("hearts", "spades", %Card{color: "hearts", number: "jack"})
    900
    iex> Card.ordering("hearts", "spades", %Card{color: "spades", number: "ace"})
    90    

    `ordering/3`
  """
  def ordering("up", req_color, %Card{color: color, number: number}) do
    if color == req_color do
      basic_order(number) * 10
    else
      basic_order(number)
    end
  end
  def ordering("down", req_color, %Card{color: color, number: number}) do
    if color == req_color do
      reversed_order(number) * 10
    else
      reversed_order(number)
    end
  end
  def ordering(game_type, req_color, %Card{color: color, number: number}) do
    if game_type == color do
      trumpf_order(number) * 100
    else if color == req_color do
        basic_order(number) * 10
      else
        basic_order(number)
      end
    end
  end


  @doc """
    points(game_type, card) ==> int
    Returns the amount of point a card gives under a certain game type.

    ## Example
    iex> Card.points("up", %Card{color: "hearts", number: "8"})
    24
    
    iex> Card.points("hearts", %Card{color: "hearts", number: "jack"})
    20
    
    iex> Card.points("hearts", %Card{color: "hearts", number: "9"})
    14


    `points/2`
  """
  def points("up", %{number: number}) do
    up_scores(number) * Globals.multiplier("up")
  end
  def points("down", %{number: number}) do
    down_scores(number) * Globals.multiplier("down")
  end
  def points(game_type, %{number: number, color: game_type}) do
    trumpf_scores(number) * Globals.multiplier(game_type)
  end
  def points(game_type, %{number: number}) do
    basic_scores(number) * Globals.multiplier(game_type)
  end

  ## HELPERS

  # Helpers for the sorting functions
  defp basic_order("6"),        do: 1
  defp basic_order("7"),        do: 2
  defp basic_order("8"),        do: 3
  defp basic_order("9"),        do: 4
  defp basic_order("10"),       do: 5
  defp basic_order("jack"),     do: 6
  defp basic_order("queen"),    do: 7
  defp basic_order("king"),     do: 8
  defp basic_order("ace"),      do: 9

  defp trumpf_order("6"),       do: 1
  defp trumpf_order("7"),       do: 2
  defp trumpf_order("8"),       do: 3
  defp trumpf_order("9"),       do: 8
  defp trumpf_order("10"),      do: 4
  defp trumpf_order("jack"),    do: 9
  defp trumpf_order("queen"),   do: 5
  defp trumpf_order("king"),    do: 6
  defp trumpf_order("ace"),     do: 7

  defp reversed_order("6"),     do: 9
  defp reversed_order("7"),     do: 8
  defp reversed_order("8"),     do: 7
  defp reversed_order("9"),     do: 6
  defp reversed_order("10"),    do: 5
  defp reversed_order("jack"),  do: 4
  defp reversed_order("queen"), do: 3
  defp reversed_order("king"),  do: 2
  defp reversed_order("ace"),   do: 1

  # Helpers for the points function
  defp basic_scores("ace"),   do: 11
  defp basic_scores("10"),    do: 10
  defp basic_scores("king"),  do:  4
  defp basic_scores("queen"), do:  3
  defp basic_scores("jack"),  do:  2
  defp basic_scores(_),       do:  0

  defp up_scores("ace"),      do: 11
  defp up_scores("10"),       do: 10
  defp up_scores("8"),        do:  8
  defp up_scores("king"),     do:  4
  defp up_scores("queen"),    do:  3
  defp up_scores("jack"),     do:  2
  defp up_scores(_),          do:  0

  defp down_scores("6"),      do: 11
  defp down_scores("10"),     do: 10
  defp down_scores("8"),      do:  8
  defp down_scores("king"),   do:  4
  defp down_scores("queen"),  do:  3
  defp down_scores("jack"),   do:  2
  defp down_scores(_),        do:  0

  defp trumpf_scores("jack"), do: 20
  defp trumpf_scores("9"),    do: 14
  defp trumpf_scores("10"),   do: 10
  defp trumpf_scores("queen"),do:  3
  defp trumpf_scores("king"), do:  4
  defp trumpf_scores("ace"),  do: 11
  defp trumpf_scores(_),      do:  0
end