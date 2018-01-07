defmodule JassLogic.Card do
  @enforce_keys [:color, :number]
  defstruct [:color, :number] 

  @moduledoc """
    Functions Connected to cards
  """
  alias __MODULE__
  alias JassLogic.Globals
  alias JassLogic.Validation
  @colors Globals.colors()
  @numbers Globals.numbers()

  @doc """
    new(color, number) ==> %Card{}
    Takes two strings, color and number and returns a %Card{struct}
    ## Example

    iex> Card.new("hearts", "6")
    %Card{color: "hearts", number: "6"}

    iex> Card.new("6", "hearts")
    %Card{color: "hearts", number: "6"}

    iex> Card.new("up", "5")
    :error

    `new/2`
  """
  def new(color, number) when color in @colors and number in @numbers, do: %__MODULE__{color: color, number: number}
  def new(number, color)  when color in @colors and number in @numbers, do: %__MODULE__{color: color, number: number}
  def new(_color, _number), do: :error

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

    iex> Card.next_card(%Card{number: "6", color: "hearts"})
    %Card{number: "7", color: "hearts"}

    iex> Card.next_card(%Card{number: "ace", color: "hearts"})
    nil

    `next_card/1`
  """
  def next_card(%Card{number: "ace"}), do: nil
  def next_card(%Card{number: number, color: color}) do
    {^number, next_number} =
      Enum.zip(@numbers, Globals.rotate_list(@numbers))
      |> Enum.find(fn {n, _new} -> 
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
  def points("up", %Card{number: number}) do
    up_scores(number) * Globals.multiplier("up")
  end
  def points("down", %Card{number: number}) do
    down_scores(number) * Globals.multiplier("down")
  end
  def points(game_type, %Card{number: number, color: game_type}) do
    trumpf_scores(number) * Globals.multiplier(game_type)
  end
  def points(game_type, %Card{number: number}) do
    basic_scores(number) * Globals.multiplier(game_type)
  end

  ## HELPERS

  # Helpers for the sorting functions
  def basic_order("6"),        do: 1
  def basic_order("7"),        do: 2
  def basic_order("8"),        do: 3
  def basic_order("9"),        do: 4
  def basic_order("10"),       do: 5
  def basic_order("jack"),     do: 6
  def basic_order("queen"),    do: 7
  def basic_order("king"),     do: 8
  def basic_order("ace"),      do: 9

  def trumpf_order("6"),       do: 1
  def trumpf_order("7"),       do: 2
  def trumpf_order("8"),       do: 3
  def trumpf_order("9"),       do: 8
  def trumpf_order("10"),      do: 4
  def trumpf_order("jack"),    do: 9
  def trumpf_order("queen"),   do: 5
  def trumpf_order("king"),    do: 6
  def trumpf_order("ace"),     do: 7

  def reversed_order("6"),     do: 9
  def reversed_order("7"),     do: 8
  def reversed_order("8"),     do: 7
  def reversed_order("9"),     do: 6
  def reversed_order("10"),    do: 5
  def reversed_order("jack"),  do: 4
  def reversed_order("queen"), do: 3
  def reversed_order("king"),  do: 2
  def reversed_order("ace"),   do: 1

  # Helpers for the points function
  def basic_scores("ace"),   do: 11
  def basic_scores("10"),    do: 10
  def basic_scores("king"),  do:  4
  def basic_scores("queen"), do:  3
  def basic_scores("jack"),  do:  2
  def basic_scores(_),       do:  0

  def up_scores("ace"),      do: 11
  def up_scores("10"),       do: 10
  def up_scores("8"),        do:  8
  def up_scores("king"),     do:  4
  def up_scores("queen"),    do:  3
  def up_scores("jack"),     do:  2
  def up_scores(_),          do:  0

  def down_scores("6"),      do: 11
  def down_scores("10"),     do: 10
  def down_scores("8"),      do:  8
  def down_scores("king"),   do:  4
  def down_scores("queen"),  do:  3
  def down_scores("jack"),   do:  2
  def down_scores(_),        do:  0

  def trumpf_scores("jack"), do: 20
  def trumpf_scores("9"),    do: 14
  def trumpf_scores("10"),   do: 10
  def trumpf_scores("queen"),do:  3
  def trumpf_scores("king"), do:  4
  def trumpf_scores("ace"),  do: 11
  def trumpf_scores(_),      do:  0


  @doc """
    find_possible(cards_player, cards_on_table, game_type) ==> [Card]

  """
  def find_possible(cards_player, cards_on_table, game_type) do
    Enum.filter cards_player, fn card ->
      Validation.validate_card(card, cards_player, cards_on_table, game_type)
    end
  end

end