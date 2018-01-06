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
  alias JassLogic.Globals
  alias JassLogic.GameState

  # INIT PHASE DONE

  # PLAY PHASE
  @doc """
  eval_game(game_state, actions)
  Takes in a game_state and a list of actions

  Returns an updated game_state
  
  `eval_game/2`
  """
  def eval_game(game_state, []) do
    {:ok, game_state}
  end
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
  defp evaluate_game_state(%{players: players, onTurnPlayer: onTurnPlayer} = game_state, {:set_game_type, "swap"}) do
    nextOnTurnPlayer =
      swap_players(onTurnPlayer, players)

    Map.merge(game_state, %{gameType: "swap", onTurnPlayer: nextOnTurnPlayer})
  end
  # Any other game_type ==> set game_type
  defp evaluate_game_state(%{cards: cards, players: players} = game_state, {:set_game_type, game_type}) do
    stoeck =
      find_stoeck(cards, game_type, players)
    Map.merge(game_state, %{gameType: game_type, stoeck: stoeck})
  end
  # If the game_type is set by the opposite located player ==> set game_type ==> swap player
  defp evaluate_game_state(game_state, {:set_game_type_after_swap, game_type}) do
    nextOnTurnPlayer =
      swap_players(game_state.onTurnPlayer, game_state.players)
    stoeck =
      find_stoeck(game_state.cards, game_type, game_state.players)
    Map.merge(game_state, %{onTurnPlayer: nextOnTurnPlayer, gameType: game_type, stoeck: stoeck})
  end
  # Play Cards Cases 
  # first round finished ==> add wys to proposed wyses,  evaluate valid wyses and add points, play_card
  defp evaluate_game_state( %{round: 0, 
                              turn: 3, 
                              proposed_wyses: proposed_wyses, 
                              groups: groups, 
                              onTurnPlayer: onTurnPlayer,
                              gameType: game_type,
                              } = game_state, 
                            {:play_card, %{card: card, wys: wys}}) do
    new_proposed_wyses =
      [{onTurnPlayer, wys} | proposed_wyses]
    valid_wyses = # list of tuples player with wys
      find_valid_wyses(game_type, new_proposed_wyses)

    new_groups =
      case Enum.fetch valid_wyses, 0 do
        {:ok, {player, _}} ->
          points =
            valid_wyses
            |> Enum.map(fn {_p, w} -> 
              Enum.map(w, fn wys ->
                Globals.points(game_type, wys)
              end)
            end)
            |> List.flatten()
            |> Enum.sum()
          update_group(groups, player, points, [])
        :error ->
          groups
      end
    new_game_state =
      Map.merge(game_state, %{valid_wyses: valid_wyses, groups: new_groups, proposed_wyses: new_proposed_wyses})
    evaluate_game_state(new_game_state, {:play_card, card})
  end
  defp evaluate_game_state(%{round: 0, 
                             proposed_wyses: proposed_wyses, 
                             onTurnPlayer: onTurnPlayer} = game_state, 
                          {:play_card, %{card: card, wys: wys}}) do
    new_proposed_wyses =
      [{onTurnPlayer, wys} | proposed_wyses]
    new_game_state =
      Map.merge(game_state, %{proposed_wyses: new_proposed_wyses })
    evaluate_game_state(new_game_state, {:play_card, card})
  end
  defp evaluate_game_state(%{gameType: game_type, groups: groups, onTurnPlayer: onTurnPlayer} = game_state, {:play_card_with_stoeck, card}) do
    points =
      20*Globals.multiplier(game_type)
    new_groups =
      update_group(groups, onTurnPlayer, points, [])
    new_game_state =
      Map.merge(game_state, %{groups: new_groups, stoeck: nil})

    evaluate_game_state(new_game_state, {:play_card, card})
  end
  defp evaluate_game_state(game_state, {:play_card, card}) do
    next_turn(game_state, card)
  end
  # Next round case
  defp evaluate_game_state(game_state, :next_round) do
    next_round(game_state)
  end
  # If nothing fits, thats an error
  defp evaluate_game_state(_game_state, _invalid_action) do
    :error
  end

  # HELPERS for the play part.

   # Finds whether a player has the stoeck
   # find_stoeck/3
  defp find_stoeck(%{} = player_cards, game_type, players) do
    case game_type do
      "up" -> nil
      "down" -> nil
      game_type ->
        players
        |> Enum.map(fn p -> find_stoeck(player_cards[p], game_type, p) end)
        |> Enum.filter(fn x -> !is_nil(x) end) 
        |> List.first
    end
  end
  # find_stoeck(player_cards, game_type)
  # find_stoeck/2
  defp find_stoeck(cards, game_type, player) do
    cards
    |> Enum.filter(fn card -> 
      card == Card.new(game_type, "queen") 
      or card == Card.new(game_type, "king")
    end)
    if cards == Card.generate_stoeck(game_type) do
      player
    else
      nil
    end
  end


  # find_valid_wyses(game_type [{player, wys}])
  defp find_valid_wyses(game_type, proposed_wyses) do
    # Find the highest wys and the player associated with them.
    players =
      proposed_wyses
      |> Enum.map(fn {p, _w} -> p end)
    {winning_player, _wys} =
      proposed_wyses
      |> Enum.max_by(fn {_player, wyses} -> 
        Enum.max(Enum.map wyses, fn(wys) -> 
          Globals.order(game_type, wys)
        end)
      end)
    allied_player =
      swap_players(players, winning_player)

    # Return a list of tuples [{player, wys}] with the winning player and their ally
    proposed_wyses
    |> Enum.filter(fn {player, _wys} -> 
      player == winning_player or player == allied_player
    end)
  end

  # Updates the game_state at the end of a round
  # => Sets new onTurnPlayer
  # => Distributes scores
  # => Empties the table
  # => Updates the round and turn counter
  defp next_round(%{players: players,
                    onTurnPlayer: onTurnPlayer,
                    gameType: game_type,
                    cards: cards,
                    groups: groups,
                    table: table,
                    turn: turn,
                    round: game_round,
                    } = game_state) do
    newOnTurnPlayer = 
      table
      |> determine_round_winner(players, game_type, onTurnPlayer)
    
    new_points = 
      cards
      |> sum_points(game_type)
      |> (fn points ->
        if game_round == 8 and turn == 4 do
          new_points =
            points + 5*Globals.multiplier(game_type)
          if Enum.any?(groups, fn group -> length group.wonCards == 9 end) do # Add 100 points for a matsch
            new_points + 100 * Globals.multiplier(game_type)
          else
            new_points
          end
        else
          points
        end
      end).()

    new_groups = 
      groups
      |> update_group(onTurnPlayer, new_points, cards)


    Map.merge(game_state, %{onTurnPlayer: newOnTurnPlayer, 
                      groups: new_groups, 
                      turn: 0, 
                      round: game_round + 1, 
                      table: [nil, nil, nil, nil],
                      })
  end
  #Helper function to sum up the points
  defp sum_points(cards, game_type) do
    Enum.map(cards, fn(c) -> Globals.points(game_type, c) end) 
    |> Enum.sum()
  end

  # Update groups with won cards and points, by giving the following arguments
  # update_group([groups], player, points, cards)
  defp update_group([%{players: [pl_1, pl_2], points: p, wonCards: c} , g2], pl, points, cards) when pl_1 == pl or pl_2 == pl do
    [%{players: [pl_1, pl_2], points: p + points, wonCards: [cards | c] |> List.flatten} , g2]
  end
  defp update_group([g1, %{players: [pl_1, pl_2], points: p, wonCards: c}], pl, points, cards) when pl_1 == pl or pl_2 == pl do
    [g1, %{players: [pl_1, pl_2], points: p + points, wonCards: [cards | c] |> List.flatten}]
  end

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
    |> Enum.max_by(fn({card, _}) -> Globals.order(game_type, req_col, card) end)
    |> (fn({_, p}) -> p end).()
  end

  
  #  Gives the next turn, within one round
  #  removes one card from players hand
  #  adds it to the table
  #  finds next player and makes them new playerOnTurn
  #  increases the turn variable by 1
  #  `next_turn/2`
  def next_turn(%{players: players, 
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
      %{cards | onTurnPlayer => List.delete(cards, card)}



    %GameState{game_state | table:  new_table,
                            cards: new_cards,
                            onTurnPlayer: next_player(onTurnPlayer, players),
                            turn: turn + 1, }
  end
  # Swaps the player on turn
  defp swap_players(onTurnPlayer, players) do
    next_player(onTurnPlayer, players)
    |> next_player(players)
  end
  # Finds the next player in the list.
  defp next_player(onTurnPlayer, players) do
    next_player(onTurnPlayer, players, true, hd players)
  end
  # next_player(player_on_turn, players, (actually find the next player), first player)
  defp next_player(_, [], false, start) do
    start
  end
  defp next_player(_, [player | _], false, _) do
    player
  end
  defp next_player(player, [player | players], true, start) do
    next_player(player, players, false, start)
  end
  defp next_player(player, [_ | players], true, start) do
    next_player(player, players, true, start)
  end
end