defmodule RickTacMorty.ComputerPlayerServer do
  use GenServer
  require Logger

  alias RickTacMorty.GameState
  alias RickTacMorty.Cell
  alias RickTacMorty.GameServer
  alias Phoenix.PubSub
  alias __MODULE__

  def child_spec(opts) do
    player_id = Keyword.fetch!(opts, :player_id)
    game_server_id = Keyword.fetch!(opts, :game_server_id)

    %{
      id: "#{ComputerPlayerServer}_#{player_id}",
      start: {ComputerPlayerServer, :start_link, [player_id, game_server_id]},
      shutdown: 10_000,
      restart: :transient
    }
  end

  def start_link(player_id, player_letter, game_server_code, game_state) do
    result =
      GenServer.start_link(
        ComputerPlayerServer,
        %{
          player_id: player_id,
          player_letter: player_letter,
          game_server_code: game_server_code,
          game_state: game_state
        },
        name: ComputerPlayerServer
      )

    case result do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info(
          "Already started Computer Player Server #{inspect(player_id)}, pid: #{pid}, ignoring"
        )

        :ignore
    end
  end

  @impl true
  def init(
        %{player_id: _player_id, player_letter: _player_letter, game_server_code: game_code} =
          init_args
      ) do
    PubSub.subscribe(RickTacMorty.PubSub, "game:#{game_code}")
    {:ok, init_args}
  end

  @impl true
  def handle_info(
        {:game_state, %GameState{player_turn: letter} = game_state},
        %{player_id: player_id, player_letter: letter} = state
      ) do
    # [%Cell{} = cell | _] = get_available_cells(game_state.board)
    {{%Cell{} = cell, _}, _} = best_move(game_state.board, letter)
    GameServer.move(game_state.code, player_id, cell.name)
    {:noreply, %{state | game_state: game_state}}
  end

  def handle_info({:game_state, %GameState{} = game_state}, state) do
    {:noreply, %{state | game_state: game_state}}
  end

  @spec get_available_cells([Cell.t()]) :: [Cell.t()]
  def get_available_cells(board) do
    Enum.filter(board, fn cell -> Cell.is_open?(cell) end)
  end

  # @spec join_game(String.t(), Player.t()) :: any()
  # def join_game(server_code, player) do
  # nd
  def make_move(board, cell, player) do
    Enum.map(board, fn
      ^cell = %Cell{letter: nil} -> %Cell{cell | letter: player}
      cell -> cell
    end)
  end

  def minmax(board, player) when player == "X" do
    {:best, best_move} =
      Enum.reduce(get_available_cells(board), {:best, -1_000}, fn cell, {:best, value} ->
        new_board = make_move(board, cell, player)
        {_, val} = minmax(new_board, "O")

        if val > value do
          {:best, val}
        else
          {:best, value}
        end
      end)

    # Logger.info("Best move: #{inspect(best_move)}")
    {:best, best_move}
  end

  def minmax(board, player) when player == "O" do
    {:best, best_move} =
      Enum.reduce(get_available_cells(board), {:best, 1_000}, fn cell, {:best, value} ->
        new_board = make_move(board, cell, player)
        {_, val} = minmax(new_board, "X")

        if val < value do
          {:best, val}
        else
          {:best, value}
        end
      end)

    # Logger.info("Best move: #{inspect(best_move)}")
    {:best, best_move}
  end

  def best_move(board, player) do
    moves =
      Enum.map(get_available_cells(board), fn cell ->
        new_board = make_move(board, cell, player)
        {_, value} = minmax(new_board, player)
        {cell, value}
      end)

    max_value = Enum.max_by(moves, fn {_, value} -> value end)

    {max_value, make_move(board, max_value |> elem(0), player)}
  end

  defmodule TicTacToe do
    @rows 3
    @cols 3

    defstruct name: "", letter: nil

    def winner(board) do
      win_patterns =
        [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
          [1, 4, 7],
          [2, 5, 8],
          [3, 6, 9],
          [1, 5, 9],
          [3, 5, 7]
        ]

      for pattern <- win_patterns do
        [a, b, c] = Enum.map(pattern, &Map.get(board, "c#{&1}").letter)

        if a == b && b == c && a != nil do
          a
        end
      end

      nil
    end

    def game_over(board) do
      winner = winner(board)

      if winner != nil do
        {:win, winner}
      else
        if Enum.all?(board, fn
             %{letter: letter} -> letter != nil
             _ -> false
           end) do
          {:draw}
        else
          {:continue}
        end
      end
    end

    def available_moves(board) do
      Enum.filter(board, fn
        %{letter: letter} -> is_nil(letter)
      end)
    end

    def make_move(board, cell, player) do
      Enum.map(board, fn
        ^cell = %{letter: nil} -> %{cell | letter: player}
        cell -> cell
      end)
    end

    def minmax(board, player) when player == "X" do
      {:best, best_move} =
        Enum.reduce(available_moves(board), {:best, -1_000}, fn cell, {:best, value} ->
          new_board = make_move(board, cell, player)
          {_, val} = minmax(new_board, "O")

          if val > value do
            {:best, val}
          else
            {:best, value}
          end
        end)

      Logger.info("Best move: #{inspect(best_move)}")
      {:best, best_move}
    end

    def minmax(board, player) when player == "O" do
      {:best, best_move} =
        Enum.reduce(available_moves(board), {:best, 1_000}, fn cell, {:best, value} ->
          new_board = make_move(board, cell, player)
          {_, val} = minmax(new_board, "X")

          if val < value do
            {:best, val}
          else
            {:best, value}
          end
        end)

      Logger.info("Best move: #{inspect(best_move)}")
      {:best, best_move}
    end

    def best_move(board, player) do
      moves =
        Enum.map(available_moves(board), fn cell ->
          new_board = make_move(board, cell, player)
          {_, value} = minmax(new_board, player)
          {cell, value}
        end)

      max_value = Enum.max_by(moves, fn {_, value} -> value end)

      {max_value, make_move(board, max_value |> elem(0), player)}
    end
  end
end
