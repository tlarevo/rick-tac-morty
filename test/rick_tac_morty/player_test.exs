defmodule RickTacMorty.PlayerTest do
  use ExUnit.Case

  doctest RickTacMorty.Player

  alias RickTacMorty.Player

  describe "create/1" do
    test "Success: given name returns a tuple with :ok atom and player struct" do
      assert {:ok, %Player{id: _, name: "rick", letter: nil, is_computer: nil}} =
               Player.create(%{name: "rick"})
    end

    test "Success: given name returns a player struct that includes valid auto generated UUID" do
      {:ok, player} = Player.create(%{name: "rick"})
      assert Map.has_key?(player, :id) == true
      assert {:ok, _} = Ecto.UUID.dump(player.id)
    end

    test "Success: given name, letter returns a tuple with :ok and valid player struct" do
      assert {:ok, %Player{id: _, name: "rick", letter: "O", is_computer: nil}} =
               Player.create(%{name: "rick", letter: "O"})
    end

    test "Success: given name, letter and computer player returns a tuple with :ok and valid player struct" do
      assert {:ok, %Player{id: _, name: "rick", letter: "O", is_computer: true}} =
               Player.create(%{name: "rick", letter: "O", is_computer: true})
    end

    test "Error: given empty map as input produces error" do
      assert {:error, %Ecto.Changeset{} = changeset} = Player.create(%{})
      assert [name: {"can't be blank", [validation: :required]}] == changeset.errors
    end
  end
end
