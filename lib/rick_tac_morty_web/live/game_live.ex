defmodule RickTacMortyWeb.GameLive do
  use RickTacMortyWeb, :live_view
  require Logger
  alias Phoenix.PubSub
  alias RickTacMorty.GameState
  alias RickTacMorty.GameServer
  import RickTacMortyWeb.Components

  @impl true
  def mount(%{"game" => game_code, "player" => player_id} = _params, _session, socket) do
    if connected?(socket) do
      # Subscribe to game update notifications
      PubSub.subscribe(RickTacMorty.PubSub, "game:#{game_code}")
      send(self(), :load_game_state)
    end

    {:ok,
     assign(socket,
       game_code: game_code,
       player_id: player_id,
       participant_type: :player,
       player: nil,
       game: GameServer.get_current_game_state(game_code),
       server_found: GameServer.server_found?(game_code)
     )}
  end

  def mount(
        %{"game" => game_code, "participant_type" => "spectator", "participant_name" => name} =
          _params,
        _session,
        socket
      ) do
    if connected?(socket) do
      # Subscribe to game update notifications
      PubSub.subscribe(RickTacMorty.PubSub, "game:#{game_code}")
      send(self(), :load_game_state)
    end

    {:ok,
     assign(socket,
       game_code: game_code,
       participant_type: :spectator,
       spectator_name: name,
       game: %GameState{},
       server_found: GameServer.server_found?(game_code)
     )}
  end

  def mount(_params, _session, socket) do
    {:ok, push_navigate(socket, to: ~p"/")}
  end

  @impl true
  def handle_event(
        "move",
        %{"cell" => cell},
        %{assigns: %{game_code: code, player: player}} = socket
      ) do
    case GameServer.move(code, player.id, String.to_existing_atom(cell)) do
      :ok ->
        # We get the new official game state through a PubSub event
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  @impl true
  def handle_event("restart", _params, %{assigns: %{game_code: code}} = socket) do
    case GameServer.restart(code) do
      :ok ->
        # We get the new official game state through a PubSub event
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  @impl true
  def handle_info(
        :load_game_state,
        %{assigns: %{server_found: true, participant_type: :spectator}} = socket
      ) do
    case GameServer.get_current_game_state(socket.assigns.game_code) do
      %GameState{} = game ->
        {:noreply, assign(socket, server_found: true, game: game)}

      error ->
        Logger.error("Failed to load game server state. #{inspect(error)}")
        {:noreply, assign(socket, :server_found, false)}
    end
  end

  def handle_info(:load_game_state, %{assigns: %{server_found: true}} = socket) do
    case GameServer.get_current_game_state(socket.assigns.game_code) do
      %GameState{} = game ->
        player = GameState.get_player(game, socket.assigns.player_id)
        {:noreply, assign(socket, server_found: true, game: game, player: player)}

      error ->
        Logger.error("Failed to load game server state. #{inspect(error)}")
        {:noreply, assign(socket, :server_found, false)}
    end
  end

  def handle_info(:load_game_state, socket) do
    Logger.debug("Game server #{inspect(socket.assigns.game_code)} not found")
    # Schedule to check again
    Process.send_after(self(), :load_game_state, 500)
    {:noreply, assign(socket, :server_found, GameServer.server_found?(socket.assigns.game_code))}
  end

  @impl true
  def handle_info(
        {:game_state, %GameState{status: :done, won_by: player_id} = state} = _event,
        %Phoenix.LiveView.Socket{assigns: %{player_id: player_id}} = socket
      ) do
    # def handle_info({:game_state, %GameState{status: :done} = state} = _event, socket) do

    updated_socket =
      socket
      |> clear_flash()
      |> assign(:game, state)

    {:noreply, push_event(updated_socket, "done", %{win: true})}
  end

  def handle_info({:game_state, %GameState{} = state} = _event, socket) do
    updated_socket =
      socket
      |> clear_flash()
      |> assign(:game, state)

    dbg(state)
    {:noreply, updated_socket}
  end
end
