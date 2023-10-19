defmodule RickTacMorty.Player do
  @moduledoc """
  Player struct of the game, player can be human or computer
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  embedded_schema do
    field :name, :string
    field :letter, :string
    field :is_computer, :boolean
  end

  @type t :: %Player{
          name: nil | String.t(),
          letter: nil | String.t(),
          is_computer: false | boolean()
        }

  @doc false
  def insert_changeset(attrs) do
    changeset(%Player{}, attrs)
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:name, :letter, :is_computer])
    |> validate_required([:name])
    |> generate_id()
  end

  defp generate_id(changeset) do
    case get_field(changeset, :id) do
      nil ->
        put_change(changeset, :id, Ecto.UUID.generate())

      _value ->
        changeset
    end
  end

  @doc """
  Create a Player struct instance from the attributes.

  ## Example

    iex> alias RickTacMorty.Player
    iex> {:ok, %Player{name: "rick", letter: nil, is_computer: nil} = player } = Player.create(%{name: "rick"})
    iex> true = Map.has_key?(player, :id)
    iex> {:error, %Ecto.Changeset{} = _changeset} = Player.create(%{})

  """
  @spec create(params :: map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def create(params) do
    params
    |> insert_changeset()
    |> apply_action(:insert)
  end
end
