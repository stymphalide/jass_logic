defmodule JassLogic.Game do
	@moduledoc """
  The game is played by applying actions to a certain game state.
  The Game map must contain this:
    players => [player name]
    onTurnPlayer => player name
    groups => %{players: [player name], points: int, wonCards: [card]}
    cards => %{player names => [card]}
    round => int
    turn => int
    table => [card || nil] length 4
    gameType => string 
    stoeck => nil || player name
    proposed_wyses => [{player name, [wys]}]
    valid_wyses => [{player name, [wys]}]

  A Wys looks like this:
  %{name => :four_the_same || :n_in_a_row,
  cards => [card]
  }

  An action is a tuple with the following values
    :set_game_type # Sent by players
    :set_game_type_after_swap # Sent by players
    :play_card # Sent by players
    :play_card_with_stoeck # Sent by players
    :next_round # Sent by server
	"""
  alias JassLogic.Card
  alias JassLogic.Player
  alias JassLogic.Globals
  alias JassLogic.GameState
  alias JassLogic.Group
  alias JassLogic.Wys
  alias JassLogic.Table

  @stoeck_points 20

  # INIT PHASE DONE

  # PLAY PHASE
  @doc """
  eval_game(game_state, actions)
  Takes in a game_state and a list of actions

  Returns an updated game_state
  
  `eval_game/2`
  """
  def eval_game(game_state, []), do: {:ok, game_state}
  def eval_game(game_state, actions) do
    [first_action | rest_actions] =
      Enum.reverse actions
    evaluate_game_states(game_state, first_action, rest_actions)
  end

  # evaluate_game_state/3

  # End of recursion
  defp evaluate_game_states(game_state, action, []) do
    case evaluate_game_state(game_state, action) do
      :error ->
        {:error, {:reason, "invalid action"}} 
      new_game_state ->
        {:ok, new_game_state}
    end
  end
  defp evaluate_game_states(game_state, action, [next_action | rest_actions ]) do
    case evaluate_game_state(game_state, action) do
      :error ->
        {:error, {:reason, "invalid action"}} 
      new_game_state ->
        evaluate_game_states(new_game_state, next_action, rest_actions)
    end
  end
  
  # evaluate_game_state/2
  # Set Game Type cases
  # If the player chooses to 'swap' ==> set game_type to swap, swap the onTurnPlayer
  defp evaluate_game_state(%GameState{players: players, onTurnPlayer: onTurnPlayer} = game_state, {:set_game_type, "swap"}) do
    %GameState{game_state | gameType: "swap", onTurnPlayer: Player.swap_players(players, onTurnPlayer) }
  end
  # Any other game_type ==> set game_type
  defp evaluate_game_state(%GameState{cards: cards} = game_state, {:set_game_type, game_type}) do     
    %GameState{game_state | gameType: game_type, stoeck: Wys.find_stoeck(cards, game_type)}
  end
  # If the game_type is set by the opposite located player ==> set game_type ==> swap player
  defp evaluate_game_state(%GameState{onTurnPlayer: onTurnPlayer, players: players, cards: cards} = game_state, {:set_game_type_after_swap, game_type}) do    
    %GameState{game_state |  onTurnPlayer: Player.swap_players(players, onTurnPlayer), gameType: game_type, stoeck: Wys.find_stoeck(cards, game_type)}
  end
  # Play Cards Cases 
  # first round finished ==> add wys to proposed wyses,  evaluate valid wyses and add points, play_card
  defp evaluate_game_state( %GameState{round: 0, 
                                      turn: 3, 
                                      players: players,
                                      proposed_wyses: proposed_wyses, 
                                      groups: groups, 
                                      onTurnPlayer: onTurnPlayer,
                                      gameType: game_type,
                                      } = game_state, 
                                    {:play_card, %{card: card, wys: wys}}) do
    new_proposed_wyses = [{onTurnPlayer, wys} | proposed_wyses]
    main_group =
      Group.get_group_by_player(groups, Player.next_player(players, onTurnPlayer))
    valid_wyses =
      Wys.find_valid_wyses(new_proposed_wyses, game_type, main_group.players)

    new_groups =
      valid_wyses
      |> Enum.map(fn {player, wys} -> 
        Group.update_points_at_player(groups, player, Wys.points(game_type, wys))
      end)
      |> Enum.reduce(fn [%Group{points: new_points1} = new_group1, %Group{points: new_points2} = new_group2], [%Group{points: old_points1}, %Group{points: old_points2}] -> 
        [%Group{new_group1 | points: old_points1 + new_points1}, %Group{new_group2 | points: old_points2 + new_points2}]
      end)

    new_game_state =
      %GameState{game_state | valid_wyses: valid_wyses, groups: new_groups, proposed_wyses: new_proposed_wyses}
    evaluate_game_state(new_game_state, {:play_card, card})
  end
  defp evaluate_game_state(%GameState{round: 0, 
                             proposed_wyses: proposed_wyses, 
                             onTurnPlayer: onTurnPlayer} = game_state, 
                          {:play_card, %{card: card, wys: wys}}) do
    new_game_state =
      %GameState{game_state | proposed_wyses: [{onTurnPlayer, wys} | proposed_wyses]}
    evaluate_game_state(new_game_state, {:play_card, card})
  end
  defp evaluate_game_state(%GameState{gameType: game_type, groups: groups, onTurnPlayer: onTurnPlayer} = game_state, {:play_card_with_stoeck, card}) do
    points =
      @stoeck_points*Globals.multiplier(game_type)
    new_game_state =
      %GameState{game_state | groups: Group.update_points_at_player(groups, onTurnPlayer, points)}
    evaluate_game_state(new_game_state, {:play_card, card})
  end
  defp evaluate_game_state(game_state, {:play_card, card}), do: next_turn(game_state, card)
  # Next round case
  defp evaluate_game_state(game_state, :next_round), do: next_round(game_state)
  # If nothing fits, thats an error
  defp evaluate_game_state(_game_state, _invalid_action), do: :error

  # HELPERS for the play part.

  # Updates the game_state at the end of a round
  # => Sets new onTurnPlayer
  # => Distributes scores
  # => Empties the table
  # => Updates the round and turn counter
  defp next_round(%GameState{players: players,
                    onTurnPlayer: onTurnPlayer,
                    gameType: game_type,
                    cards: cards,
                    groups: groups,
                    table: table,
                    round: game_round,
                    } = game_state) do
    newOnTurnPlayer = 
      determine_round_winner(table, players, game_type, onTurnPlayer)
    
    new_points = 
      if Enum.any? groups, &match?(&1.wonCards) do
        sum_points(cards, game_type, game_round) + 100*Globals.multiplier(game_type)
      else
        sum_points(cards, game_type, game_round)
      end
    %GameState{game_state | onTurnPlayer: newOnTurnPlayer, 
                            groups: Group.update_group_at_player(groups, newOnTurnPlayer, new_points, cards), 
                            turn: 0, 
                            round: game_round + 1, 
                            table: Table.new(),
                      }
  end
  #Helper function to sum up the points
  defp sum_points(cards, game_type, 8) do
    cards
    |> Enum.map(&Card.points(game_type, &1))
    |> Enum.sum()
    |> Kernel.+(5 * Globals.multiplier(game_type))
  end
  defp sum_points(cards, game_type, _game_round) do
    cards
    |> Enum.map(&Card.points(game_type, &1)) 
    |> Enum.sum()
  end
  defp match?(wonCards) when length(wonCards) == 9, do: true
  defp match?(_wonCards), do: false


  # Makes player, card pairs and determines which player has played the highest card
  # Return that player
  defp determine_round_winner(cards, players, game_type, onTurnPlayer) do
    # Find the required color that was to be played
    {%{color: req_col}, _} =
      cards
      |> Enum.zip(players)
      |> Enum.filter(fn {_card, player} -> player == onTurnPlayer end)
      |> hd()
    # Find the player, who played the highest card.
    cards
    |> Enum.zip(players)
    |> Enum.max_by(fn({card, _}) -> Card.ordering(game_type, req_col, card) end)
    |> (fn({_, p}) -> p end).()
  end

  
  #  Gives the next turn, within one round
  #  removes one card from players hand
  #  adds it to the table
  #  finds next player and makes them new playerOnTurn
  #  increases the turn variable by 1
  #  `next_turn/2`
  def next_turn(%GameState{players: players, 
                  table: table, 
                  cards: cards, 
                  onTurnPlayer: onTurnPlayer,
                  turn: turn
                } = game_state, 
                card) do

    new_table =
      table
      |> Enum.zip(players)
      |> Enum.map(fn {old_card, player} -> 
        if player == onTurnPlayer do
          card
        else
          old_card
        end
      end)


    new_cards =
      %{cards | onTurnPlayer => List.delete(cards[onTurnPlayer], card)}


    %GameState{game_state | table:  new_table,
                            cards: new_cards,
                            onTurnPlayer: Player.next_player(players, onTurnPlayer),
                            turn: turn + 1, }
  end
end