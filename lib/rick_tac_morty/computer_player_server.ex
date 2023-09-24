defmodule RickTacMorty.ComputerPlayerServer do
  use GenServer
  require Logger

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

  def start_link(player_id, game_server_id) do
    result =
      GenServer.start_link(
        ComputerPlayerServer,
        %{
          player_id: player_id,
          game_server_id: game_server_id
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
  def init(init_args) do
    {:ok, init_args}
  end
end
