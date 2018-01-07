defmodule JassLogic.Validation do
	@moduledoc """
	Is responsible for validating cards that want to be played.
	As well as finding the winner of a round
	And distributing points (While not actually updating the group)

	"""
  alias JassLogic.Card

	@doc """
  validate_card(card, cards_player, cards_on_table, game_type)

	Takes in the card that is proposed to be played, as well as the cards of the player and on the cards on the table and the game_type.
  Remember that it takes the cards_on_table as a List (So it is easy to find the first card)

	There are several cases for this function:
	1. There are no cards on the table ==> true
	2. There is a card from a certain color first played on the table, and the player wants to play the same color. ==> true
	3. There is a card from a certain color first played on the table but the player wants to play another color
		3a) It is either "up" or "down" game type
			3a) i. The player doesn't have this specific color ==> true
			3a) ii. The player has this specific color ==> false
		3b) It is hearts, spades etc.
    	3b) i. There is a card from the type color first played on the table. But the player wants to play another color
    		3b) i.1 The player doesn't have the type color ==> true.
    		3b) i.2 The player has at least one card of the type color.
    			3b) i.2.a The player only has the jack of the type color ==> true
    			3b) i.2.a The player has several cards of the type color ==> false
      3b) ii. The player doesn't play the type color ==> cases 3a i.) /3a ii.) apply.
      3b) iii. The player does play the type color
        3b) iii.1 There are no other cards of the type color on the table. ==> true
        3b) iii.2 There are other cards of the type color on the table.
          3b) iii.2.a It is higher than the other card(s) of that color ==> true
          3b) iii.2.b It is lower than the other card on the table.
            3b) iii.2.b.i The player doesn't have another valid card. ==> true
            3b) iii.2.b.ii The player does have another valid card. ==> false

	Returns a bool that is true when the player is allowed to play the card under these conditions

  `validate_card/4`
	"""
  # @TODO This is horrible, refactor this at some stage.
  def validate_card(_card, _cards_player, [nil, nil, nil, nil], _game_type), do: true
	def validate_card(card, cards_player, cards_on_table, game_type) do # Assumes a sorted list of cards_on_table
    cond do
      cards_on_table |> length == 0 ->  # case 1
        true
      hd(cards_on_table).color == card.color ->  # Case 2
        true
      game_type == "up" || game_type == "down" ->  # Case 3a
        hd(cards_on_table).color |> validate_trivial(cards_player)
      game_type == hd(cards_on_table).color -> # Case 3b i
        validate_with_type(card, cards_player, game_type) 
      game_type != card.color ->  # Case  3b ii
        hd(cards_on_table).color |> validate_trivial(cards_player)
      cards_with_type(cards_on_table, game_type, []) == [] ->  # Case 3b iii 1
        true
      cards_with_type(cards_on_table, game_type, []) |> is_highest(card, game_type) ->  # Case 3b iii 2.a
        true
      List.delete(cards_player, card) |> validate_others(game_type) ->  # Case 3b iii 2.b.i
        true
      true -> false # Case 3b iii 2 b ii (Or the default case)
    end
  end

  # Matches the cases 3a i./and 3a ii. (Recursive)
  defp validate_trivial(required_color, [%Card{color: required_color, number: _} | _])  do
    false
  end
  defp validate_trivial(_, []) do
    true
  end
  defp validate_trivial(required_color, [_ | cards_player]) do
    validate_trivial(required_color, cards_player)
  end

  # Case 3b) i
  defp validate_with_type(_, cards_player, game_type) do
    case cards_with_type(cards_player, game_type, []) do
      [] -> true        
      [%Card{color: ^game_type, number: "jack"} ] -> true
      _ -> false
    end
  end

  # Case 3b iii
  defp cards_with_type([%Card{color: game_type, number: number} | []], game_type, result) do
    [%Card{color: game_type, number: number} | result]
  end
  defp cards_with_type([%Card{color: game_type, number: number} | cards_on_table], game_type, result)  do
    cards_with_type(cards_on_table, game_type, [%Card{color: game_type, number: number} | result])
  end
  defp cards_with_type([_ | []], _, result) do
    result
  end
  defp cards_with_type([_ | cards_on_table], game_type, result) do
    cards_with_type(cards_on_table, game_type, result)
  end

  # Case 3b iii.2.a
  defp is_highest(cards, card, game_type) do
    Enum.max_by([card | cards], fn(c) -> Card.ordering(game_type, hd(cards).color, c) end) == card
  end

  # Case 3b iii 2.b.i (Recursion)
  defp validate_others([], _) do
    true
  end
  defp validate_others(cards_player, game_type) do
    cond do 
      cards_with_type(cards_player, game_type, []) == cards_player ->
        true
      true -> 
        false
    end
  end




  @doc """
    validate_action(action_space, action)

    Checks whether a certain action is in the action space of that game_state
    Returns a bool
  """
  def validate_action(action_space, action) do
     Enum.any?(action_space, &validate_in_action_space(&1, action))
  end

  defp validate_in_action_space({name, %{wys: wyses, card: cards}}, {name, %{wys: wys, card: card}}) do
    MapSet.subset?(wys, wyses) and MapSet.member?(cards, card)
  end
  defp validate_in_action_space({name, arguments}, {name, argument}) do
    MapSet.member? arguments, argument
  end
  defp validate_in_action_space(:end_game, :end_game) do
    true
  end
  defp validate_in_action_space(:next_round, :next_round) do
    true
  end
  defp validate_in_action_space(_actions, _action) do
    false
  end
end