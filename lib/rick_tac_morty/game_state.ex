defmodule RickTacMorty.GameState do
  @moduledoc """
  Model the game state for a tic-tac-toe game.
  """
  alias RickTacMorty.Cell
  alias RickTacMorty.Player
  alias __MODULE__

  # The board's cells are addressible using an atom like this: `:c11` for
  # "Cell: Row 1, Column 1". Ths goes through `:c33` for "Cell: Row 3,
  # Column 3".
  defstruct code: nil,
            players: [],
            player_turn: nil,
            status: :not_started,
            timer_ref: nil,
            board: [
              # Row 1
              Cell.build(:c11),
              Cell.build(:c12),
              Cell.build(:c13),
              # Row 2
              Cell.build(:c21),
              Cell.build(:c22),
              Cell.build(:c23),
              # Row 3
              Cell.build(:c31),
              Cell.build(:c32),
              Cell.build(:c33)
            ]

  # won_by: nil

  @type game_code :: String.t()

  @type t :: %GameState{
          code: nil | String.t(),
          status: :not_started | :playing | :done,
          players: [Player.t()],
          player_turn: nil | integer(),
          timer_ref: nil | reference(),
          board: [Cell.t()]
          # won_by: nil | String.t()
        }

  # 30 Minutes of inactivity ends the game
  @inactivity_timeout 1000 * 60 * 30

  @doc """
  Return an initialized GameState struct. Requires one player to start.
  """
  @spec new(game_code(), Player.t()) :: t()
  def new(game_code, %Player{} = player) do
    %GameState{code: game_code, players: [%Player{player | letter: "O"}]}
    |> reset_inactivity_timer()
  end

  @doc """
  Allow another player to join the game. Exactly 2 players are required to play.
  """
  @spec join_game(t(), Player.t()) :: {:ok, t()} | {:error, String.t()}
  def join_game(%GameState{players: []} = _state, %Player{}) do
    {:error, "Can only join a created game"}
  end

  def join_game(%GameState{players: [_p1, _p2]} = _state, %Player{} = _player) do
    {:error, "Only 2 players allowed"}
  end

  def join_game(%GameState{players: [p1]} = state, %Player{} = player) do
    player =
      if p1.letter == "O" do
        %Player{player | letter: "X"}
      else
        %Player{player | letter: "O"}
      end

    {:ok, %GameState{state | players: [p1, player]} |> reset_inactivity_timer()}
  end

  @doc """
  Return the player from the game state found by the ID.
  """
  @spec get_player(t(), player_id :: String.t()) :: nil | Player.t()
  def get_player(%GameState{players: players} = _state, player_id) do
    Enum.find(players, &(&1.id == player_id))
  end

  @doc """
  Return the player from the game state found by the ID in an `:ok`/`:error` tuple.
  """
  @spec find_player(t(), player_id :: String.t()) :: {:ok, Player.t()} | {:error, String.t()}
  def find_player(%GameState{} = state, player_id) do
    case get_player(state, player_id) do
      nil ->
        {:error, "Player not found"}

      %Player{} = player ->
        {:ok, player}
    end
  end

  @doc """
  Return the opponent player from the perspective of the given player.
  """
  @spec opponent(t(), Player.t()) :: nil | Player.t()
  def opponent(%GameState{} = state, %Player{} = player) do
    # Find the first player that doesn't have this ID
    Enum.find(state.players, &(&1.id != player.id))
  end

  @doc """
  Start the game.
  """
  @spec start(t()) :: {:ok, t()} | {:error, String.t()}
  def start(%GameState{status: :playing}), do: {:error, "Game in play"}
  def start(%GameState{status: :done}), do: {:error, "Game is done"}

  def start(%GameState{status: :not_started, players: [_p1, _p2]} = state) do
    {:ok, %GameState{state | status: :playing, player_turn: "O"} |> reset_inactivity_timer()}
  end

  def start(%GameState{players: _players}), do: {:error, "Missing players"}

  @doc """
  Return a boolean value for if it is currently the given player's turn.
  """
  @spec player_turn?(t(), Player.t()) :: boolean()
  def player_turn?(%GameState{player_turn: turn}, %Player{letter: letter}) when turn == letter,
    do: true

  def player_turn?(%GameState{}, %Player{}), do: false

  @doc """
  Check to see if the player won. Return a tuple of the winning cells if the they won. If no win found, returns `:not_found`.

  Tests for all the different ways the player could win.
  """
  @spec check_for_player_win(t(), Player.t()) :: :not_found | [atom()]
  def check_for_player_win(%GameState{board: board}, %Player{letter: letter}) do
    case board do
      #
      # Check for all the straight across wins
      [%Cell{letter: ^letter}, %Cell{letter: ^letter}, %Cell{letter: ^letter} | _] ->
        [:c11, :c12, :c13]

      [_, _, _, %Cell{letter: ^letter}, %Cell{letter: ^letter}, %Cell{letter: ^letter} | _] ->
        [:c21, :c22, :c23]

      [
        _,
        _,
        _,
        _,
        _,
        _,
        %Cell{letter: ^letter},
        %Cell{letter: ^letter},
        %Cell{letter: ^letter}
      ] ->
        [:c31, :c32, :c33]

      #
      # Check for all the vertical wins
      [
        %Cell{letter: ^letter},
        _,
        _,
        %Cell{letter: ^letter},
        _,
        _,
        %Cell{letter: ^letter},
        _,
        _ | _
      ] ->
        [:c11, :c21, :c31]

      [
        _,
        %Cell{letter: ^letter},
        _,
        _,
        %Cell{letter: ^letter},
        _,
        _,
        %Cell{letter: ^letter},
        _ | _
      ] ->
        [:c12, :c22, :c32]

      [
        _,
        _,
        %Cell{letter: ^letter},
        _,
        _,
        %Cell{letter: ^letter},
        _,
        _,
        %Cell{letter: ^letter} | _
      ] ->
        [:c13, :c23, :c33]

      #
      # Check for the diagonal wins
      [
        %Cell{letter: ^letter},
        _,
        _,
        _,
        %Cell{letter: ^letter},
        _,
        _,
        _,
        %Cell{letter: ^letter} | _
      ] ->
        [:c11, :c22, :c33]

      [
        _,
        _,
        %Cell{letter: ^letter},
        _,
        %Cell{letter: ^letter},
        _,
        %Cell{letter: ^letter},
        _,
        _ | _
      ] ->
        [:c13, :c22, :c31]

      _ ->
        :not_found
    end
  end

  @doc """
  Return a list of all the cells that are a valid move given the current games
  state.
  """
  @spec valid_moves(t()) :: [atom()]
  def valid_moves(%GameState{board: board}) do
    Enum.reduce(board, [], fn cell, acc ->
      if Cell.is_open?(cell) do
        [cell.name | acc]
      else
        acc
      end
    end)
  end

  @doc """
  Check for who the game's result. Either a player won, the game ended in a
  draw, or the game is still going.
  """
  @spec result(t()) :: :playing | :draw | Player.t()
  def result(%GameState{players: [p1, p2]} = state) do
    player_1_won =
      case check_for_player_win(state, p1) do
        :not_found -> false
        [_, _, _] -> true
      end

    player_2_won =
      case check_for_player_win(state, p2) do
        :not_found -> false
        [_, _, _] -> true
      end

    cond do
      player_1_won -> p1
      player_2_won -> p2
      valid_moves(state) == [] -> :draw
      true -> :playing
    end
  end

  @doc """
  Find a cell on the board by it's name.
  """
  def find_cell(%GameState{} = state, cell) do
    case Enum.find(state.board, &(&1.name == cell)) do
      nil ->
        {:error, "Cell not found"}

      %Cell{} = cell ->
        {:ok, cell}
    end
  end

  @doc """
  Performs a player move. Returns a new GameState after the move. Will be the
  next player's turn. Returns an error tuple if the move is not allowed or not
  the player's turn.
  """
  @spec move(t() | {:ok, t()}, Player.t(), cell :: atom()) :: {:ok, t()} | {:error, String.t()}
  def move({:ok, %GameState{} = state}, %Player{} = player, cell) do
    move(state, player, cell)
  end

  def move(%GameState{status: :playing} = state, %Player{} = player, cell) do
    # - verify player's turn
    # - new board with the player's letter in the cell
    # - check for a win/draw
    # - if more moves are posible,
    # - set to the next player's turn
    # - reset the inactivity timer
    state
    |> verify_player_turn(player)
    |> verify_cell(cell)
    |> player_claim_cell(player, cell)
    |> check_for_done()
    |> next_player_turn()
    |> reset_inactivity_timer()
  end

  def move(%GameState{status: :not_started} = _state, %Player{} = _player, _cell) do
    {:error, "Game hasn't started yet!"}
  end

  def move(%GameState{status: :done} = _state, %Player{} = _player, _cell) do
    {:error, "Game is over!"}
  end

  @doc """
  Restart the game resetting the state back.
  """
  def restart(%GameState{players: [p1 | _]} = state) do
    blank_state = %GameState{}

    %GameState{state | board: blank_state.board, status: :playing, player_turn: p1.letter}
    |> reset_inactivity_timer()
  end

  defp verify_player_turn(%GameState{} = state, %Player{} = player) do
    if player_turn?(state, player) do
      {:ok, state}
    else
      {:error, "Not your turn!"}
    end
  end

  defp verify_cell({:ok, %GameState{} = state}, cell) do
    # Find the cell and verify the player can go there
    case GameState.find_cell(state, cell) do
      {:ok, %Cell{letter: nil}} -> {:ok, state}
      {:ok, %Cell{}} -> {:error, "Cell already taken"}
      {:error, _reason} = error -> error
    end
  end

  defp verify_cell({:error, _reason} = error, _cell), do: error

  defp player_claim_cell({:ok, %GameState{} = state}, %Player{} = player, cell) do
    {:ok, place_letter(state, player.letter, cell)}
  end

  defp player_claim_cell({:error, _reason} = error, _player, _cell), do: error

  @doc false
  @spec place_letter(t, Cell.t(), letter :: nil | String.t()) :: t
  def place_letter(%GameState{} = state, letter, cell) do
    updated_board =
      Enum.map(state.board, fn sq ->
        if sq.name == cell do
          %Cell{sq | letter: letter}
        else
          sq
        end
      end)

    %GameState{state | board: updated_board}
  end

  defp check_for_done({:ok, %GameState{} = state}) do
    case result(state) do
      :playing ->
        {:ok, state}

      # %Player{} = player ->
      #   {:ok, %GameState{state | won_by: player.id}}

      _game_done ->
        {:ok, %GameState{state | status: :done}}
    end
  end

  defp check_for_done({:error, _reason} = error), do: error

  defp next_player_turn({:error, _reason} = error), do: error

  defp next_player_turn({:ok, %GameState{player_turn: turn} = state}) do
    {:ok, %GameState{state | player_turn: if(turn == "X", do: "O", else: "X")}}
  end

  defp reset_inactivity_timer({:error, _reason} = error), do: error

  defp reset_inactivity_timer({:ok, %GameState{} = state}) do
    {:ok, reset_inactivity_timer(state)}
  end

  defp reset_inactivity_timer(%GameState{} = state) do
    state
    |> cancel_timer()
    |> set_timer()
  end

  defp cancel_timer(%GameState{timer_ref: ref} = state) when is_reference(ref) do
    Process.cancel_timer(ref)
    %GameState{state | timer_ref: nil}
  end

  defp cancel_timer(%GameState{} = state), do: state

  defp set_timer(%GameState{} = state) do
    %GameState{
      state
      | timer_ref: Process.send_after(self(), :end_for_inactivity, @inactivity_timeout)
    }
  end
end
