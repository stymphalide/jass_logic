defmodule JassLogic.GameState do
  alias JassLogic.Card
  alias JassLogic.Group
  alias JassLogic.Table

  @enforce_keys [:players, 
                 :onTurnPlayer, 
                 :groups,
                 :cards,
                ]
  defstruct [players: [], 
             onTurnPlayer: "", 
             groups: [%Group{}, %Group{}],
             cards: %{},
             round: 0,
             turn: 0,
             table: Table.new(),
             gameType: nil,
             stoeck: nil,
             proposed_wyses: %{},
             valid_wyses: %{},
            ]


  @doc """
    Creates a new game state struct.
    new(players, onTurnPlayer, groups, cards)
  `new/4`
  """
  def new(players, opts \\ %{onTurnPlayer: false, groups: false}) do
    if check_players(players) do
      %__MODULE__{players: players, 
                  onTurnPlayer: opts.onTurnPlayer || Enum.random(players), 
                  groups: opts.groups || Group.initialise_groups(players), 
                  cards: create_cards(players),
                  proposed_wyses: %{},
                  valid_wyses: %{},
                }
    else
      :error
    end
  end
  defp check_players([pl1, pl2, pl3, pl4] = players) when is_bitstring(pl1) and is_bitstring(pl2) and is_bitstring(pl3) and is_bitstring(pl4) do
    uniq_players =
      players
      |> Enum.uniq()
    uniq_players == players
  end
  defp check_players(_) do
    false
  end
  defp create_cards(players) do
    Card.generate_deck()
      |> Enum.take_random(36)
      |> Enum.chunk_every(9)
      |> split_deck(players, %{})
  end
  # Splits the deck (as a list of 4x9 cards) map with players, where nth player gets nth cards
  defp split_deck([hand | tl_hands], [pl | tl_players], result) do 
    split_deck(tl_hands, tl_players, Map.merge(result, %{pl => sort_cards(hand)}))
  end
  defp split_deck([], [], result) do
    result
  end
    # Returns a sorted list of cards
  defp sort_cards(cards) do
    Enum.sort_by(cards, fn(c) -> Card.sorting(c) end)
  end
end