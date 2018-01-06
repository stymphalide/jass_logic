defmodule JassLogicTest do
  use ExUnit.Case
  doctest JassLogic

  test "greets the world" do
    assert JassLogic.hello() == :world
  end
end
