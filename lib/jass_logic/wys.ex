defmodule JassLogic.Wys do
  @moduledoc """
  Provides functions to work with wyses
  Provides a struct with two required keys, :name and :cards
  the name is either :four_the_same or :n_in_a_row

  cards is a MapSet of Cards
  """
  @enforce_keys [:name, :cards]
  defstruct [:name, :cards]

  alias __MODULE__
  alias JassLogic.Card
  alias JassLogic.Player
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



    `Wys.new/2`
  """
  def new(name, cards) when name in @name_space do
    cards = Enum.sort_by(cards, &(Card.sorting(&1)))
    valid_wys_cards =
      generate_wys_cards(name, hd(cards), length(cards))
    case valid_wys_cards do
      :error ->
        :error
      _ ->
        if MapSet.equal? valid_wys_cards, MapSet.new(cards) do
          %Wys{name: name, cards: valid_wys_cards}
        else
          :error
        end
    end
  end
  def new(_name, _cards) do
    :error
  end

  @doc """
    Wys.points(game_type, wys)

    Returns the amount of points a certain wys can be accounted for, also takes the game type into account, to multiply by a certain factor.

  """
  # Clauses for wyses
  def points(game_type, %Wys{name: :four_the_same, cards: cards}) do
    jacks = 
      generate_four_the_same("jack")
    nells = 
      generate_four_the_same("9")
    case cards do
      ^jacks ->
        200 * Globals.multiplier(game_type)
      ^nells ->
        150 * Globals.multiplier(game_type)
      _ ->
        100 * Globals.multiplier(game_type)
    end
  end
  def points(game_type, %Wys{name: :n_in_a_row, cards: cards}) do
    case MapSet.size(cards) do
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
    
  """
  def ordering(game_type, wys, player, [_pl1, player]), do: ordering(game_type, wys) + 5
  def ordering(game_type, wys, player, [player, _pl2]), do: ordering(game_type, wys) + 5
  def ordering(game_type, wys, _player, _group_players), do: ordering(game_type, wys)

  defp ordering("down", %Wys{name: wys_name, cards: cards}) do
    cards = Enum.sort_by cards, fn card -> Card.sorting(card) end
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
  defp ordering(_game_type, %Wys{name: wys_name, cards: cards}) do
    cards = Enum.sort_by cards, fn card -> Card.sorting(card) end
    case wys_name do
      :four_the_same ->
        Card.trumpf_order((hd cards).number) * 100000
      :n_in_a_row ->
        n = length cards
        Card.basic_order((Enum.fetch! cards, (n-1)).number) * n * 10 
    end
  end
  @doc """
    find_possible_wyses(cards) ==> #MapSet<[Wys]>

    Takes in a MapSet of cards and returns a MapSet of Wyses
  """
  def find_possible_wyses(cards) do
    four_the_sames =
      Globals.numbers()
      |> Enum.map(fn n ->
        generate_four_the_same(n)
      end)
      |> Enum.filter(fn wys -> 
         MapSet.subset? wys, MapSet.new(cards)
      end)
      |> Enum.map(fn wys_cards -> 
        %Wys{name: :four_the_same, cards: wys_cards}
      end)
      # Filter for the n_in_a_rows and concat them with the four the sames.
      sorted_cards = Enum.sort_by(cards, &(Card.sorting(&1))) 
      cards
      |> Enum.map(fn c -> 
        Enum.reduce(sorted_cards, [c], fn(y, [head | _] = acc) ->
          if Card.next_card(head) == y do
            [y | acc]
          else
            acc
          end
        end) 
      end)
      |> Enum.filter(fn wys -> length(wys) >= 3 end)
      |> Enum.map(fn wys -> new(:n_in_a_row, wys) end)
      |> MapSet.new()
      |> MapSet.union(MapSet.new(four_the_sames))
  end

  @doc """
    generate_stoeck() ==> %MapSet{}
    The stoeck of a certain game_type are the king and the queen 
    of the color that is chosen as trumpf
    Note that in up and down, there are no stoeck and the function yields an error


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
    generate_four_the_same(number) ==> MapSet Card
    This function takes in a number and returns four cards
    with that number but different color.
    This function needs a valid number to work,
    invalid numbers yield an error.
    
    `generate_four_the_same/1`
  """
  # @TODO remove and use generate_wys
  def generate_four_the_same(number) when number in @numbers, do: generate_wys_cards(:four_the_same, %Card{number: number, color: "hearts"})
  def generate_four_the_same(_number), do: :error


  @doc """
    Wys.generate_wys_cards(name, card, n\\3 ==> MapSet
    Generates a MapSet, given the name and a card in the wys.
    For n_in_a_row, the card must be the lowest.
    And n defaults to 3, but can go up to 9

    `generate_wys_cards/3`
  """
  def generate_wys_cards(name, card, n \\ 3)
  def generate_wys_cards(:four_the_same, %Card{number: number}, _n) do
    Enum.map(@colors, fn color ->
      Card.new(color, number)
    end)
    |> MapSet.new()
  end
  def generate_wys_cards(:n_in_a_row, start, n) do
    wys_cards = 
      Enum.reduce(1..(n-1), [start], fn _, cards = [last | _] ->
        if(last == :error) do
          [:error]
        else 
          next_card = Card.next_card(last)
          if is_nil(next_card) do
            [:error]
          else
            [ next_card | cards]
          end
        end
      end)
    if wys_cards == [:error] do
      :error
    else
      MapSet.new(wys_cards)
    end
  end
  def generate_wys_cards(_invalid_name, _invalid_cards, _n), do: :error



  @doc """
    Wys.find_stoeck(%cards, game_type, players) ==> player || nil
    Finds a player who has the stoeck

   `find_stoeck/2`
  """
  def find_stoeck(_cards, "up"), do: nil
  def find_stoeck(_cards, "down"), do: nil
  def find_stoeck(cards, game_type) do
        cards
        |> Enum.filter(fn {_player, cards} -> 
          MapSet.subset? generate_stoeck(game_type), MapSet.new(cards)
        end)
        |> Enum.map(fn {player, _cards} -> player end)
        |> List.first()
  end

  @doc """
    find_valid_wyses([{player, wys}], game_type, group_players) ==> [{player, wys}]

    `find_valid_wyses/3`
  """
  # 
  def find_valid_wyses(proposed_wyses, game_type, group_players) do
    # Find the highest wys and the player associated with them.
    players =
      proposed_wyses
      |> Enum.map(fn {p, _w} -> p end)
    {winning_player, _wys} =
      proposed_wyses
      |> Enum.max_by(fn {player, wyses} -> 
        if !Enum.empty? wyses do
          Enum.max(Enum.map(wyses, fn wys -> 
            ordering(game_type, wys, player, group_players)
          end))
        else
          0
        end
      end)
    allied_player =
      Player.swap_players(players, winning_player)

    # Return a list of tuples [{player, wys}] with the winning player and their ally
    proposed_wyses
    |> Enum.filter(fn {player, _wys} -> 
      player == winning_player or player == allied_player
    end)
  end
end