defmodule CardTest do
  use ExUnit.Case
  alias JassLogic.Card
  doctest Card
  test "find_possible/3 returns correct cards" do
    cards_player = [Card.new("hearts", "6")]
    cards_on_table = []
    game_type = "hearts"
    assert cards_player == Card.find_possible(cards_player, cards_on_table, game_type)
  end
end

