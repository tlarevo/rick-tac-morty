defmodule RickTacMortyWeb.PlayerLive do
  use RickTacMortyWeb, :live_view
  import Phoenix.HTML.Form
  alias RickTacMortyWeb.GameStarter
  alias RickTacMorty.Player
  alias RickTacMorty.GameServer

  @impl true
  def mount(%{"game_type" => game_type} = params, _session, socket) do
    {:ok,
     socket
     |> assign(changeset: GameStarter.insert_changeset(params), game_type: game_type)}
  end

  @impl true
  def handle_event("validate", %{"game_starter" => params}, socket) do
    changeset =
      params
      |> GameStarter.insert_changeset()
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"game_starter" => params}, socket) do
    dbg(socket.assigns.changeset.data)
    game_type = String.to_existing_atom(socket.assigns.game_type)

    with {:ok, starter} <- GameStarter.create(params),
         {:ok, game_code} <- GameStarter.get_game_code(starter),
         {:ok, player} <- Player.create(%{name: starter.name}),
         {:ok, _} <- GameServer.start_or_join(game_code, player, game_type) do
      # Set params
      params = %{game: game_code, player: player.id, game_type: starter.game_type}

      socket =
        push_navigate(socket, to: ~p"/game?#{params}")

      {:noreply, socket}
    else
      {:error, reason} when is_binary(reason) ->
        {:noreply, put_flash(socket, :error, reason)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp new_game?(changeset) do
    Ecto.Changeset.get_field(changeset, :type) == :start
  end
end
