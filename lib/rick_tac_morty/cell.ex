defmodule RickTacMorty.Cell do
  @moduledoc """
  Struct that represents the state of a single cell of a game board
  """
  alias __MODULE__

  defstruct name: nil, letter: nil

  @type t :: %Cell{
          name: nil | atom(),
          letter: nil | String.t()
        }

  @doc """
  Build and return a board square. Provide the name.
  """
  @spec build(name :: atom, letter :: nil | String.t()) :: t()
  def build(name, letter \\ nil) do
    %Cell{name: name, letter: letter}
  end

  @doc """
  Return if the cell is open. True if no player has claimed the square. False
  if a player occupies it.

  ## Example

      iex> Cell.is_open?(%RickTacMorty.Cell{name: :c11, letter: nil})
      true

      iex> Cell.is_open?(%RickTacMorty.Cell{name: :c11, letter: "O"})
      false

      iex> Cell.is_open?(%RickTacMorty.Cell{name: :c11, letter: "X"})
      false
  """
  @spec is_open?(t()) :: boolean()
  def is_open?(%Cell{letter: nil}), do: true
  def is_open?(%Cell{}), do: false
end
