defmodule JassLogic.Group do
  @moduledoc false
  defstruct players: [], points: 0, wonCards: []
  @doc """
  Takes in a list of 4 players
  returns a list of two groups, with two players each.

  

  ## Example
  iex> Group.initialise_groups(["pl1", "pl2", "pl3", "pl4"])
  [%Group{players: ["pl1", "pl3"], points: 0, wonCards: []}, %Group{players: ["pl2", "pl4"], points: 0, wonCards: []}]

  iex> Group.initialise_groups([])
  :error

  `initialise_groups/1`

  """
  def initialise_groups([pl1, pl2, pl3, pl4]) do
    [%__MODULE__{players: [pl1, pl3]}, %__MODULE__{players: [pl2, pl4]}]
  end
  def initialise_groups(_players) do
    :error
  end
  @doc """
    update_group(group, points, wonCards) ==> %Group{}
    
    ## Example
    iex> new_wonCards = [Card.new("hearts", "ace"), Card.new("hearts", "6"), Card.new("hearts", "7"), Card.new("hearts", "10")]
    iex> Group.update_group(%Group{players: ["pl1", "pl3"], points: 0, wonCards: []}, 50,  new_wonCards)
    %Group{players: ["pl1", "pl3"], points: 50, wonCards: [[%Card{color: "hearts", number: "ace"}, %Card{color: "hearts", number: "6"}, %Card{color: "hearts", number: "7"}, %Card{color: "hearts", number: "10"}]]}    
    
    `update_group/2`

  """
  def update_group(group = %__MODULE__{wonCards: wonCards, points: points}, new_points, new_wonCards) do
    %__MODULE__{group | wonCards: [new_wonCards | wonCards], points: points + new_points }
  end

  @doc """
    update_points(group, points) ==> %Group{}
    ## Example
    iex> Group.update_points(%Group{players: ["pl1", "pl3"], points: 0, wonCards: []}, 50)
    %Group{players: ["pl1", "pl3"], points: 50, wonCards: []}
  """
  def update_points(group = %__MODULE__{points: points}, new_points) do
    %__MODULE__{group | points: points + new_points}
  end

  @doc """
    update_points_at_player(groups, player, points) ==> [%Groups{}]

    iex> Group.update_points_at_player(Group.initialise_groups(["pl1", "pl2", "pl3", "pl4"]), "pl1", 50)
    [%Group{players: ["pl1", "pl3"], points: 50, wonCards: []}, %Group{players: ["pl2", "pl4"], points: 0, wonCards: []}]

  """
  def update_points_at_player(groups, player, points) do
    groups
    |> Enum.map(fn group -> 
      if player in group.players do
        update_points(group, points)
      else
        group
      end
    end)
  end
  @doc """
    update_group_at_player(groups, player, points) ==> [%Group{}]

    iex> Group.update_group_at_player(Group.initialise_groups(["pl1", "pl2", "pl3", "pl4"]), "pl1", 50, [])
    [%Group{players: ["pl1", "pl3"], points: 50, wonCards: [[]]}, %Group{players: ["pl2", "pl4"], points: 0, wonCards: []}]

  """
  def update_group_at_player(groups, player, points, wonCards) do
    groups
    |> Enum.map(fn group -> 
      if player in group.players do
        update_group(group, points, wonCards)
      else
        group
      end
    end)
  end

  @doc """
    get_group_by_player

  """
  def get_group_by_player(groups, player) do
    Enum.find groups, fn group -> player in group.players end
  end
end
  