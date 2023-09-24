defmodule RickTacMortyWeb.StartLive do
  use RickTacMortyWeb, :live_view
  alias RickTacMortyWeb.GameStarter
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:changeset, GameStarter.insert_changeset(%{}))}
  end

  @impl true
  def handle_event("game_type_selected", %{"game_type" => "HvH"} = params, socket) do
    Logger.info("Play against human")
    socket = push_navigate(socket, to: ~p"/player?#{params}")
    {:noreply, socket}
  end

  def handle_event("game_type_selected", %{"game_type" => "HvC"} = params, socket) do
    Logger.info("Play against computer")
    socket = push_navigate(socket, to: ~p"/player?#{params}")
    {:noreply, socket}
  end

  def handle_event("game_type_selected", %{"game_type" => "spectator"}, socket) do
    Logger.info("Watch others play")
    {:noreply, socket}
  end
end
