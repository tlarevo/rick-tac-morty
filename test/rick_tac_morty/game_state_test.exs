defmodule RickTacMorty.GameStateTest do
  use RickTacMorty.GameStateCaseTemplate

  alias RickTacMorty.Cell
  alias RickTacMorty.GameState
  alias RickTacMorty.Player

  describe "new/3" do
    test "Success: new game with game_code, player and game type returns game state struct", %{
      players: [p1, _p2]
    } do
      %GameState{} = state = GameState.new("c137", p1, :HvC)
      assert state.code == "c137"
      assert [player] = state.players
      assert player.name == "rick"
      assert player.letter == "O"
      assert state.timer_ref != nil
      assert is_reference(state.timer_ref)
    end
  end

  describe "join_game/2" do
    test "Success: second player join game", %{players: [p1, p2]} do
      state = GameState.new("c137", p1, :HvC)
      assert {:ok, _new_state} = GameState.join_game(state, p2)
    end
  end

  describe "find_player/2" do
    test "Success: given the player ID return a tuple including :ok and player struct", %{
      players: [p1, p2]
    } do
      state = GameState.new("c137", p1, :HvC)
      assert {:ok, new_state} = GameState.join_game(state, p2)
      assert {:ok, %Player{} = ^p1} = GameState.find_player(new_state, to_string(p1.id))
    end
  end

  describe "get_player_owned_cells/2" do
    test "Success: given board arrangement and player letter returns list of cells owned by player",
         %{players: [p, _]} do
      board = [
        Cell.build(:c11, "O"),
        Cell.build(:c12, "O"),
        Cell.build(:c13, "O"),
        Cell.build(:c21),
        Cell.build(:c22, "X"),
        Cell.build(:c23),
        Cell.build(:c31),
        Cell.build(:c32, "X"),
        Cell.build(:c33)
      ]

      assert [:c11, :c12, :c13 | _] = GameState.get_player_owned_cells(board, p.letter)
    end
  end

  describe "check_for_player_win/2" do
    test "Success: given game state and player return wining sequence", %{
      players: [p1, _] = players
    } do
      state = %GameState{
        players: players,
        board: [
          Cell.build(:c11, "O"),
          Cell.build(:c12, "O"),
          Cell.build(:c13, "O"),
          Cell.build(:c21),
          Cell.build(:c22, "X"),
          Cell.build(:c23),
          Cell.build(:c31),
          Cell.build(:c32, "X"),
          Cell.build(:c33)
        ]
      }

      assert [:c11, :c12, :c13] == GameState.check_for_player_win(state, p1)
    end
  end
end
