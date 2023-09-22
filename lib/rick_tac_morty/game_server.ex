defmodule RickTacMorty.GameServer do
  @moduledoc """
  A GenServer that manages and models the state for a specific game instance.
  """
  use GenServer
  require Logger

  alias __MODULE__
  alias RickTacMorty.Player
  alias RickTacMorty.GameState
  alias Phoenix.PubSub

  # Client

  def child_spec(opts) do
    name = Keyword.get(opts, :name, GameServer)
    player = Keyword.fetch!(opts, :player)

    %{
      id: "#{GameServer}_#{name}",
      start: {GameServer, :start_link, [name, player]},
      shutdown: 10_000,
      restart: :transient
    }
  end

  @doc """
  Start a GameServer with the specified game_code as the name.
  """
  def start_link(name, %Player{} = player) do
    case GenServer.start_link(GameServer, %{player: player, code: name}, name: via_tuple(name)) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info(
          "Already started GameServer #{inspect(name)} at #{inspect(pid)}, returning :ignore"
        )

        :ignore
    end
  end

  @doc """
  Generate a unique game code for starting a new game server.
  """
  @spec generate_game_code() :: {:ok, GameState.game_code()} | {:error, String.t()}
  def generate_game_code() do
    # Generate 3 server codes to try. Take the first that is unused.
    # If no unused ones found, add an error
    codes = Enum.map(1..3, fn _ -> do_generate_code() end)

    case Enum.find(codes, &(!GameServer.server_found?(&1))) do
      nil ->
        # no unused game code found. Report server busy, try again later.
        {:error, "Didn't find unused code, try again later"}

      code ->
        {:ok, code}
    end
  end

  defp do_generate_code() do
    # Generate a single 4 character random code
    range = ?A..?Z

    1..4
    |> Enum.map(fn _ -> [Enum.random(range)] |> List.to_string() end)
    |> Enum.join("")
  end

  @doc """
  Start a new game or join an existing game.
  """
  @spec start_or_join(GameState.game_code(), Player.t()) ::
          {:ok, :started | :joined} | {:error, String.t()}
  def start_or_join(game_code, %Player{} = player) do
    case Horde.DynamicSupervisor.start_child(
           RickTacMorty.DistributedSupervisor,
           {GameServer, [name: game_code, player: player]}
         ) do
      {:ok, _pid} ->
        Logger.info("Started game server #{inspect(game_code)}")
        {:ok, :started}

      :ignore ->
        Logger.info("Game server #{inspect(game_code)} already running. Joining")

        case join_game(game_code, player) do
          :ok -> {:ok, :joined}
          {:error, _reason} = error -> error
        end
    end
  end

  @doc """
  Join a running game server
  """
  @spec join_game(GameState.game_code(), Player.t()) :: :ok | {:error, String.t()}
  def join_game(game_code, %Player{} = player) do
    GenServer.call(via_tuple(game_code), {:join_game, player})
  end

  @doc """
  Perform a move for the player
  """
  @spec move(GameState.game_code(), player_id :: String.t(), cell :: atom()) ::
          :ok | {:error, String.t()}
  def move(game_code, player_id, cell) do
    GenServer.call(via_tuple(game_code), {:move, player_id, cell})
  end

  @doc """
  Request and return the current game state.
  """
  @spec get_current_game_state(GameState.game_code()) ::
          GameState.t() | {:error, String.t()}
  def get_current_game_state(game_code) do
    GenServer.call(via_tuple(game_code), :current_state)
  end

  @doc """
  Reset the current game keeping the same players.
  """
  @spec restart(GameState.game_code()) :: :ok | {:error, String.t()}
  def restart(game_code) do
    GenServer.call(via_tuple(game_code), :restart)
  end

  ###
  ### Server (callbacks)
  ###

  @impl true
  def init(%{player: player, code: code}) do
    # Create the new game state with the creating player assigned
    {:ok, GameState.new(code, player)}
  end

  @impl true
  def handle_call({:join_game, %Player{} = player}, _from, %GameState{} = state) do
    with {:ok, new_state} <- GameState.join_game(state, player),
         {:ok, started} <- GameState.start(new_state) do
      broadcast_game_state(started)
      {:reply, :ok, started}
    else
      {:error, reason} = error ->
        Logger.error("Failed to join and start game. Error: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call(:current_state, _from, %GameState{} = state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:move, player_id, cell}, _from, %GameState{} = state) do
    with {:ok, player} <- GameState.find_player(state, player_id),
         {:ok, new_state} <- GameState.move(state, player, cell) do
      broadcast_game_state(new_state)
      {:reply, :ok, new_state}
    else
      {:error, reason} = error ->
        Logger.error("Player move failed. Error: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call(:restart, _from, %GameState{} = state) do
    new_state = GameState.restart(state)
    broadcast_game_state(new_state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_info(:end_for_inactivity, %GameState{} = state) do
    # Shutdown the game server when it's been inactive for too long.
    Logger.info("Game #{inspect(state.code)} was ended for inactivity")
    {:stop, :normal, state}
  end

  def broadcast_game_state(%GameState{} = state) do
    PubSub.broadcast(RickTacMorty.PubSub, "game:#{state.code}", {:game_state, state})
  end

  @doc """
  Return the `:via` tuple for referencing and interacting with a specific
  GameServer.
  """
  def via_tuple(game_code), do: {:via, Horde.Registry, {RickTacMorty.GameRegistry, game_code}}

  @doc """
  Lookup the GameServer and report if it is found. Returns a boolean.
  """
  @spec server_found?(GameState.game_code()) :: boolean()
  def server_found?(game_code) do
    # Look up the game in the registry. Return if a match is found.
    case Horde.Registry.lookup(RickTacMorty.GameRegistry, game_code) do
      [] -> false
      [{pid, _} | _] when is_pid(pid) -> true
    end
  end
end
