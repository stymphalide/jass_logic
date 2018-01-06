defmodule JassLogic.Wys do
  @moduledoc """
  Provides functions to work with wyses
  Provides a struct with two required keys, :name and :cards
  the name is either :four_the_same or :n_in_a_row
  """
  @enforce_keys [:name, :cards]
  defstruct [:name, :cards]

  alias __MODULE__
  alias JassLogic.Card
  alias JassLogic.Globals

  @name_space [:four_the_same, :n_in_a_row]
  @colors Globals.colors()
  @numbers Globals.numbers()

  @doc """
    Wys.new(name, cards)
    assumes as name argument either of these:
      :four_the_same, :n_in_a_row
    Cards is a list of sorted cards, that get's converted into a 
    MapSet.
    Returns a %Wys{} struct.
    
    returns :error with invalid arguments
  
    ## Example

    iex> new(:four_the_same, [%Card{color: "hearts", number: "6"}, %Card{color: "diamonds", number: "6"}, %Card{color: "spades", number: "6"}, %Card{color: "clubs", number: "6"}])
    %Wys{name: :four_the_same, cards: #MapSet<[%Card{color: "hearts", number: "6"}, %Card{color: "diamonds", number: "6"}, %Card{color: "spades", number: "6"}, %Card{color: "clubs", number: "6"}]>}
    
    iex> new(:n_in_a_row, [%Card{color: "hearts", number: "6"}, %Card{color: "hearts", number: "7"}, %Card{color: "hearts", number: "8"}])
    %Wys{name: :n_in_a_row, cards: #MapSet<[%Card{color: "hearts", number: "6"}, %Card{color: "hearts", number: "7"}, %Card{color: "hearts", number: "8"}]>}

    iex> new(:invalid_name, [])
    :error

    iex> new(:n_in_a_row, [%Card{color: "hearts", number: "6"}, %Card{color: "hearts", number: "7"}, %Card{color: "hearts", number: "9"}])
    :error


    `Wys.new/2`
  """
  def new(name, cards) when name in @name_space do
    valid_wys =
      generate_wys(name, hd(cards), length(cards))
    set_cards =
      MapSet.new(cards)
    if MapSet.equal? valid_wys.cards, set_cards do
      %__MODULE__{name: name, cards: set_cards}
    else
      :error
    end
  end
  def new(_name, _cards) do
    :error
  end

  @doc """
    Wys.points(game_type, wys)

    Returns the amount of points a certain wys can be accounted for, also takes the game type into account, to multiply by a certain factor.
    
    ## Example 
    iex> Wys.points("up", %{name: :four_the_same, cards: [%JassLogic.Card{color: "hearts", number: "jack"}, %JassLogic.Card{color: "diamonds", number: "jack"}, %JassLogic.Card{color: "spades", number: "jack"}, %JassLogic.Card{color: "clubs", number: "jack"}]})
    600

    iex> Wys.points("spades", %{name: :four_the_same, cards: [%JassLogic.Card{color: "hearts", number: "9"}, %JassLogic.Card{color: "diamonds", number: "9"}, %JassLogic.Card{color: "spades", number: "9"}, %JassLogic.Card{color: "clubs", number: "9"}]})
    300

    iex> Wys.points("hearts", %{name: :n_in_a_row, cards: [%JassLogic.Card{color: "hearts", number: "8"}, %JassLogic.Card{color: "hearts", number: "9"}, %JassLogic.Card{color: "hearts", number: "10"}, %JassLogic.Card{color: "hearts", number: "jack"}, %JassLogic.Card{color: "hearts", number: "queen"}, ]})
    100
    
    iex> Wys.points("clubs", %{name: :n_in_a_row, cards: [%JassLogic.Card{color: "hearts", number: "7"}, %JassLogic.Card{color: "hearts", number: "8"}, %JassLogic.Card{color: "hearts", number: "9"}, %JassLogic.Card{color: "hearts", number: "10"} ]})
    100

    iex> Wys.points("down", %{name: :n_in_a_row, cards: [%JassLogic.Card{color: "hearts", number: "8"}, %JassLogic.Card{color: "hearts", number: "9"}, %JassLogic.Card{color: "hearts", number: "10"} ]})
    60
  """
  # Clauses for wyses
  def points(game_type, %{name: :four_the_same, cards: cards}) do
    jacks = 
      Card.generate_four_the_same("jack")
    nells = 
      Card.generate_four_the_same("9")
    case cards do
      ^jacks ->
        200 * Globals.multiplier(game_type)
      ^nells ->
        150 * Globals.multiplier(game_type)
      _ ->
        100 * Globals.multiplier(game_type)
    end
  end
  def points(game_type, %{name: :n_in_a_row, cards: cards}) do
    case length cards do
      3 ->
        20 * Globals.multiplier(game_type)
      4 ->
        50 * Globals.multiplier(game_type)
      _ ->
        100 * Globals.multiplier(game_type)
    end
  end

  @doc """
    ordering(game_type, wys)

    Provides a ranking for the wyses, 
    Can be used in combination with `Enum.sort_by/2`

    four the sames are much more important than n in a row.
    But they follow the trumpf order.
    for n in a  row, up order or down order matters respectively.
    

    iex> Wys.ordering("down", %{name: :four_the_same, cards: [%JassLogic.Card{color: "hearts", number: "6"}, %JassLogic.Card{color: "diamonds", number: "6"}, %JassLogic.Card{color: "spades", number: "6"}, %JassLogic.Card{color: "clubs", number: "6"}]})
    90_000

    iex> Wys.ordering("down", %{name: :four_the_same, cards: [%JassLogic.Card{color: "hearts", number: "jack"}, %JassLogic.Card{color: "diamonds", number: "jack"}, %JassLogic.Card{color: "spades", number: "jack"}, %JassLogic.Card{color: "clubs", number: "jack"}]})
    200_000

    iex> Wys.ordering("down", %{name: :four_the_same, cards: [%JassLogic.Card{color: "hearts", number: "9"}, %JassLogic.Card{color: "diamonds", number: "9"}, %JassLogic.Card{color: "spades", number: "9"}, %JassLogic.Card{color: "clubs", number: "9"}]})
    140_000
  """
  def ordering("down", %{name: wys_name, cards: cards}) do
    case wys_name do
      :four_the_same ->
        case (hd cards).number do
          "jack" ->
            200_000
          "9" ->
            140_000
          _ -> 
            Card.reversed_order((hd cards).number) * 10_000
        end
      :n_in_a_row ->
        Card.reversed_order((Enum.fetch! cards, 0).number) * (length cards) * 10
    end
  end
  def ordering(_game_type, %{name: wys_name, cards: cards}) do
    case wys_name do
      :four_the_same ->
        Card.trumpf_order((hd cards).number) * 10000
      :n_in_a_row ->
        n = length cards
        Card.basic_order((Enum.fetch! cards, (n-1)).number) * n * 10 
    end
  end



  @doc """
    find_possible_wyses(cards) ==> #MapSet<[Wys]>

    Takes in a list of cards and returns a MapSet of Wyses

  """
  def find_possible_wyses(cards) do
    four_the_sames =
      Globals.numbers()
      |> Enum.map(fn n ->
        generate_wys(:four_the_same, n)
      end)

      |> Enum.filter(fn wys -> 
         MapSet.subset? wys, MapSet.new(cards)
      end)
      |> Enum.map(fn cards -> 
        %Wys{name: :four_the_same, cards: cards} 
      end)
      # Filter for the n_in_a_rows and concat them with the four the sames.
      cards
      |> Enum.map(fn x -> 
        Enum.reduce(cards, [x], fn(y, [head | _] = acc) ->
          if Card.next_card(head) == y do
            [y | acc]
          else
            acc
          end
        end) 
      end)
      |> Enum.filter(fn wys -> length wys >= 3 end)
      |> Enum.map(fn wys -> %Wys{name: :n_in_a_row, cards: MapSet.new wys} end)
      |> MapSet.new()
      |> MapSet.union(four_the_sames)
  end

  @doc """
    generate_stoeck() ==> %MapSet{}
    The stoeck of a certain game_type are the king and the queen 
    of the color that is chosen as trumpf
    Note that in up and down, there are no stoeck and the function yields an error

    ## Example

    iex> Wys.generate_stoeck("hearts")
    [%Card{color: "hearts", number: "queen"}, %Card{color: "hearts", number: "king"}]

    iex> Wys.generate_stoeck("up")
    :error

    `generate_stoeck/1`
  """
  def generate_stoeck(game_type) when game_type in @colors do
    [Card.new(game_type, "queen"), Card.new(game_type, "king")] 
    |> MapSet.new()
  end
  def generate_stoeck(_) do
    :error
  end

  @doc """
    generate_four_the_same(number) ==> %Wys{}
    This function takes in a number and returns four cards
    with that number but different color.
    This function needs a valid number to work,
    invalid numbers yield an error.
    
    ## Example
    iex> Wys.generate_four_the_same("9")
    [%Card{color: "hearts", number: "9"}, 
     %Card{color: "diamonds", number: "9"},
     %Card{color: "spades", number: "9"},
     %Card{color: "clubs", number: "9"}]

     iex> Wys.generate_four_the_same("5")
     :error

    `generate_four_the_same/1`
  """
  # @TODO remove and use generate_wys
  def generate_four_the_same(number) when number in @numbers do
    Enum.map @colors(), fn c -> 
      new(c, number)
    end
  end
  def generate_four_the_same(_) do
    :error
  end


  @doc """
    Wys.generate_wys_cards(name, card, n\\3 ==> MapSet
    Generates a MapSet, given the name and a card in the wys.
    For n_in_a_row, the card must be the lowest.
    And n defaults to 3, but can go up to 9
    
    ## Example

    iex> Wys.generate_wys(:four_the_same, %Card{number: "6", color: "hearts"})
    #MapSet<[%Card{color: "hearts", number: "6"}, %Card{color: "diamonds", number: "6"}, %Card{color: "spades", number: "6"}, %Card{color: "clubs", number: "6"}]>

    iex> Wys.generate_wys(:n_in_a_row, %Card{number: "6", color: "hearts"})
    #MapSet<[%Card{color: "hearts", number: "6"}, %Card{color: "hearts", number: "7"}, %Card{color: "hearts", number: "8"}]>

    `generate_wys_cards/3`
  """
  def generate_wys(name, card, n \\ 3)
  def generate_wys(:four_the_same, %Card{number: number}, _n) do
    Enum.map @colors, fn color ->
      Card.new(color, number)
    end
    |> MapSet.new()
  end
  def generate_wys(:n_in_a_row, start = %Card{color: color}, n) do
    nine_in_a_row(color)
    |> Enum.slice(start, n)
    |> MapSet.new()
    |> MapSet.put(start)
  end
  defp nine_in_a_row(color) when color in @colors do
    Enum.map @numbers, fn number ->
      Card.new(color, number)
    end
  end
end