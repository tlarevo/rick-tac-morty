defmodule RickTacMortyWeb.StartLive do
  @moduledoc """
  LiveView module for starting the game and picking play type such as play against
  human player, computer player or just watch a ongoing match
  """
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

  def handle_event(
        "participant_type_selected",
        %{"participant_type" => "spectator"} = params,
        socket
      ) do
    Logger.info("Watch others play")
    # {:noreply, put_flash(socket, :error, "Sorry feature still not implemented")}
    socket = push_navigate(socket, to: ~p"/player?#{params}")
    {:noreply, socket}
  end
end
