defmodule JassLogic.Action do
  @moduledoc """
    An action is a tuple with the following values
    {:set_game_type, "swap" || "up" || "down" || "hearts" || "diamonds" || "spades" || "clubs"} # Sent by players
    {:set_game_type_after_swap, "up" || "down" || "hearts" || "diamonds" || "spades" || "clubs"} # Sent by players
    {:play_card, card} # Sent by players
    {:play_card, %{wys: wys, card: card}} # Sent by player in first round
    {:play_card_with_stoeck, card} # Sent by players with stoeck
    :next_round  # Sent by server
  """
  alias JassLogic.Globals
  alias JassLogic.Card
  alias JassLogic.GameState
  alias JassLogic.Validation
  alias JassLogic.Wys

  @doc """
  eval_action_space(game_state) ==> #MapSet<[actions]>
  Returns a MapSet of possible actions, 
  based on the current state.
  `eval_action_space/1`
  """
  # If there is no game type set, one can only set a new game_type
  def eval_action_space(%GameState{gameType: nil}) do
    actions =
    Enum.map Globals.game_types(), fn type ->
      {:set_game_type, type}
    end
    MapSet.new(actions)
  end
  # If there is the swap game type set, one can only set a new game_type without swapping
  def eval_action_space(%GameState{gameType: "swap"}) do
    Globals.game_types()
    |> tl()
    |> Enum.map(fn type -> 
      {:set_game_type_after_swap, type}
    end)
  end
  # If it is the last round
  def eval_action_space(%GameState{round: 9}) do
    []
  end
  # If it is the last turn
  def eval_action_space(%GameState{turn: 4}) do
    [:next_round]
  end
  # If it is the first round and the first turn and the player on Turn has the stoeck
  def eval_action_space(%GameState{round: 0,
                          onTurnPlayer: onTurnPlayer,
                          cards: cards,
                          table: [nil, nil, nil, nil],
                          stoeck: onTurnPlayer,
                        }) do
    cards_player =
      cards[onTurnPlayer]
    possible_wyses =
      Wys.find_wyses(cards_player)
    # 9 *(length possible_wyses + 1) In there
    Enum.map cards_player, fn card ->
      for wys <- possible_wyses do
        [{:play_card, %{wys: wys, card: card}},
        {:play_card_with_stoeck, %{wys: wys, card: card}}]
      end
    end
    |> List.flatten()
  end
  # If it is the first round and first turn
  def eval_action_space(%GameState{round: 0,
                          onTurnPlayer: onTurnPlayer,
                          cards: cards,
                          table: [nil, nil, nil, nil],
                        }) do
    cards_player = cards[onTurnPlayer]
    possible_wyses =
      Wys.find_wyses(cards_player)
    # 9 *(length possible_wyses + 1) In there
    Enum.map cards_player, fn card ->
      for wys <- possible_wyses do
        {:play_card, %{wys: wys, card: card}}
      end
    end
    |> List.flatten()
  end

  # If it is the first round and any turn and the player has the stoeck
  def eval_action_space(%GameState{round: 0,
                          players: players,
                          onTurnPlayer: onTurnPlayer,
                          cards: cards,
                          gameType: game_type,
                          table: table,
                          stoeck: onTurnPlayer,
                        }) do
    cards_player = cards[onTurnPlayer]

    {cards_on_table, _players} =
      table
      |> Enum.zip(players)
      |> order_table(onTurnPlayer)
      |> Enum.unzip()


    possible_cards = 
      Enum.filter cards_player, fn card ->
        Validation.validate_card(card, cards_player, cards_on_table, game_type)
      end

    possible_wyses =
      Wys.find_possible_wyses(cards_player)
    # 9 *(length possible_wyses + 1) In there
    Enum.map possible_cards, fn card ->
      for wys <- possible_wyses do
        [{:play_card, %{wys: wys, card: card}},
        {:play_card_with_stoeck, %{wys: wys, card: card}}]
      end
    end
    |> List.flatten()
  end
  # If it is the first round and any turn
  def eval_action_space(%GameState{round: 0,
                          players: players,
                          onTurnPlayer: onTurnPlayer,
                          cards: cards,
                          gameType: game_type,
                          table: table,
                        }) do
    cards_player = cards[onTurnPlayer]
    {cards_on_table, _players} =
      table
      |> Enum.zip(players)
      |> order_table(onTurnPlayer)
      |> Enum.unzip()


    possible_cards = 
      Enum.filter cards_player, fn card ->
        Validation.validate_card(card, cards_player, cards_on_table, game_type)
      end

    possible_wyses =
      Wys.find_wyses(cards_player)
    # 9 *(length possible_wyses + 1) In there
    Enum.map possible_cards, fn card ->
      for wys <- possible_wyses do
        {:play_card, %{wys: wys, card: card}}
      end
    end
    |> List.flatten()
  end

  # If it is any round and the first turn and the player has the stoeck
  def eval_action_space(%GameState{onTurnPlayer: onTurnPlayer, 
                          cards: cards,
                          table: [nil, nil, nil, nil],
                          stoeck: onTurnPlayer,
                        }) do

    Enum.map cards[onTurnPlayer], fn card ->
      [{:play_card, card},
      {:play_card_with_stoeck, card}]
    end
    |> List.flatten()
  end
  # If it is any round and the first turn
  def eval_action_space(%GameState{onTurnPlayer: onTurnPlayer, 
                          cards: cards,
                          table: [nil, nil, nil, nil],
                        }) do
    Enum.map cards[onTurnPlayer], fn card ->
      {:play_card, card}
    end
  end
  # If it is any round and any turn and the player has the stoeck
  def eval_action_space(%GameState{players: players,
                          onTurnPlayer: onTurnPlayer,
                          cards: cards,
                          gameType: game_type,
                          table: table,
                          stoeck: onTurnPlayer,
                        }) do
    cards_player = cards[onTurnPlayer]
    {cards_on_table, _players} =
      table
      |> Enum.zip(players)
      |> order_table(onTurnPlayer)
      |> Enum.unzip()


    possible_cards = 
      Enum.filter cards_player, fn card ->
        Validation.validate_card(card, cards_player, cards_on_table, game_type)
      end
    # 9 *(length possible_wyses + 1) In there
    Enum.map possible_cards, fn card ->
      [{:play_card,  card},
      {:play_card_with_stoeck, card}]
    end
    |> List.flatten()
  end
  # If it is any round and any turn
  def eval_action_space(%GameState{players: players,
                          onTurnPlayer: onTurnPlayer,
                          cards: cards,
                          gameType: game_type,
                          table: table,
                        }) do
    cards_player = cards[onTurnPlayer]
    {cards_on_table, _players} =
      table
      |> Enum.zip(players)
      |> order_table(onTurnPlayer)
      |> Enum.unzip()

    possible_cards = 
      Enum.filter cards_player, fn card ->
        Validation.validate_card(card, cards_player, cards_on_table, game_type)
      end
    # 9 *(length possible_wyses + 1) In there
    Enum.map possible_cards, fn card ->
      {:play_card,  card}
    end
    |> List.flatten()
  end

  # Returns a list of cards, in the order they were played
  defp order_table(cards_player = [{_card1, onTurnPlayer} | _tail],  onTurnPlayer) do
    Globals.rotate_list(cards_player)
  end
  defp order_table(cards_player,  onTurnPlayer) do
    order_table(Globals.rotate_list(cards_player), onTurnPlayer)
  end
end