defmodule JassLogic.Action do
  @moduledoc """
    An action is a tuple with the following values
    {:set_game_type, MapSet game_types} # Sent by players
    {:set_game_type_after_swap, MapSet game_types} # Sent by players
    {:play_card, MapSet Card} # Sent by players
    {:play_card, %{wys: MapSet Wys, card: MapSet Card}} # Sent by player in first round
    {:play_card_with_stoeck, MapSet Card} # Sent by players with stoeck
    :next_round  # Sent by server
    :end_game # Sent by server
  """
  alias JassLogic.Globals
  alias JassLogic.Card
  alias JassLogic.GameState
  alias JassLogic.Wys
  alias JassLogic.Table

  @doc """
  eval_action_space(game_state) ==> #MapSet<[actions]>
  Returns a MapSet of possible actions, 
  based on the current state.
  `eval_action_space/1`
  """
  # If there is no game type set, one can only set a new game_type
  def eval_action_space(%GameState{gameType: nil}), do: [{:set_game_type, MapSet.new(Globals.game_types())}]
  # If there is the swap game type set, one can only set a new game_type without swapping
  def eval_action_space(%GameState{gameType: "swap"}) do
    Globals.game_types()
    |> tl()
    |> (fn types -> 
      [{:set_game_type_after_swap, MapSet.new(types)}]
    end).()
  end
  # If it is the last round
  def eval_action_space(%GameState{round: 9}) do
    [:end_game]
  end
  # If it is the last turn
  def eval_action_space(%GameState{turn: 4}) do
    [:next_round]
  end
  # If it is the first round and the first turn and the player on Turn has the stoeck
  def eval_action_space(%GameState{round: 0, onTurnPlayer: onTurnPlayer, cards: cards, table: [nil, nil, nil, nil], stoeck: onTurnPlayer,}) do
    cards_player =
      MapSet.new(cards[onTurnPlayer])
    possible_wyses =
      Wys.find_possible_wyses(cards_player)
    [{:play_card_with_stoeck, %{wys: possible_wyses, card: cards_player}}]
  end
  # If it is the first round and first turn
  def eval_action_space(%GameState{round: 0, onTurnPlayer: onTurnPlayer, cards: cards, table: [nil, nil, nil, nil],}) do
    cards_player = 
      MapSet.new(cards[onTurnPlayer])
    possible_wyses =
      Wys.find_possible_wyses(cards_player)
    # 9 *(length possible_wyses + 1) In there
    [{:play_card, %{wys: possible_wyses, card: cards_player}}]
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

    possible_cards = 
      Card.find_possible(cards_player, Table.order_table(table, players, onTurnPlayer), game_type)
      |> MapSet.new()

    possible_wyses =
      Wys.find_possible_wyses(cards_player)

    # 9 *(length possible_wyses + 1) In there
    [{:play_card, %{wys: possible_wyses, card: possible_cards}},
        {:play_card_with_stoeck, %{wys: possible_wyses, card: possible_cards}}]
  end
  # If it is the first round and any turn
  def eval_action_space(%GameState{round: 0, players: players, onTurnPlayer: onTurnPlayer, cards: cards, gameType: game_type, table: table}) do
    cards_player = cards[onTurnPlayer]

    possible_cards = 
      Card.find_possible(cards_player, Table.order_table(table, players, onTurnPlayer), game_type)
      |> MapSet.new()

    possible_wyses =
      Wys.find_possible_wyses(cards_player)
    # 9 *(length possible_wyses + 1) In there

    [{:play_card, %{wys: possible_wyses, card: possible_cards}}]
  end

  # If it is any round and the first turn and the player has the stoeck
  def eval_action_space(%GameState{onTurnPlayer: onTurnPlayer, cards: cards, table: [nil, nil, nil, nil], stoeck: onTurnPlayer,}) do
    player_cards =
      MapSet.new(cards[onTurnPlayer])
    [{:play_card, player_cards}, {:play_card_with_stoeck, player_cards}]
  end
  # If it is any round and the first turn
  def eval_action_space(%GameState{onTurnPlayer: onTurnPlayer, cards: cards,table: [nil, nil, nil, nil],
                        }) do
    [{:play_card, MapSet.new(cards[onTurnPlayer])}]
  end
  # If it is any round and any turn and the player has the stoeck
  def eval_action_space(%GameState{players: players, onTurnPlayer: onTurnPlayer, cards: cards, gameType: game_type, table: table, stoeck: onTurnPlayer,}) do
    possible_cards = 
      Card.find_possible(cards[onTurnPlayer], Table.order_table(table, players, onTurnPlayer), game_type)
      |> MapSet.new()
    # 9 *(length possible_wyses + 1) In there
    [{:play_card, possible_cards}, {:play_card_with_stoeck, possible_cards}]
  end
  # If it is any round and any turn
  def eval_action_space(%GameState{players: players, onTurnPlayer: onTurnPlayer, cards: cards, gameType: game_type, table: table,}) do
    possible_cards = 
      Card.find_possible(cards[onTurnPlayer], Table.order_table(table, players, onTurnPlayer), game_type)
      |> MapSet.new()
    # 9 *(length possible_wyses + 1) In there
    [{:play, possible_cards}]
  end
end