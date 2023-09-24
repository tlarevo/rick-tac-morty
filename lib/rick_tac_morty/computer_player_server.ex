defmodule RickTacMorty.ComputerPlayerServer do
  use GenServer
  require Logger

  alias RickTacMorty.GameState
  alias RickTacMorty.Cell
  alias RickTacMorty.GameServer
  alias Phoenix.PubSub
  alias __MODULE__
  alias RickTacMorty.Player

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
    [%Cell{} = cell | _] = get_available_cells(game_state.board)
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
  # end
end
