defmodule RickTacMorty.GameStateCaseTemplate do
  @moduledoc """
  Case template for game state tests
  """
  use ExUnit.CaseTemplate

  alias RickTacMorty.Player

  setup do
    {:ok, p1} = Player.create(%{name: "rick", letter: "O"})
    {:ok, p2} = Player.create(%{name: "morty", letter: "X"})
    %{players: [p1, p2]}
  end
end
