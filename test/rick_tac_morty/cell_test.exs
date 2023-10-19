defmodule RickTacMorty.CellTest do
  @moduledoc """
  Tests for cells of game board
  """
  use ExUnit.Case
  alias RickTacMorty.Cell

  doctest RickTacMorty.Cell

  describe "build/2" do
    test "Success: create a cell with name only" do
      assert %Cell{name: :c11, letter: nil} == Cell.build(:c11)
    end

    test "Success: create a cell with name and letter O" do
      assert %Cell{name: :c12, letter: "O"} == Cell.build(:c12, "O")
    end

    test "Success: create a cell with name and letter X" do
      assert %Cell{name: :c13, letter: "X"} == Cell.build(:c13, "X")
    end

    test "Error: throw error when cell name is not an atom" do
      assert_raise(FunctionClauseError, fn -> Cell.build("X") end)
    end
  end
end
