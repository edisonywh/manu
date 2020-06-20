defmodule ManuTest do
  use ExUnit.Case
  doctest Manu

  test "greets the world" do
    assert Manu.hello() == :world
  end
end
