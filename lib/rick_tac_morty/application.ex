defmodule RickTacMorty.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies) || []
    children = [
      # Start the Telemetry supervisor
      RickTacMortyWeb.Telemetry,
      # Start the Ecto repository
      RickTacMorty.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: RickTacMorty.PubSub},
      # Start Finch
      {Finch, name: RickTacMorty.Finch},
      # setup for clustering
      {Cluster.Supervisor, [topologies, [name: RickTacMorty.ClusterSupervisor]]},
      # Start the registry for tracking running games
      {Horde.Registry, [name: RickTacMorty.GameRegistry, keys: :unique, members: :auto]},
      {Horde.DynamicSupervisor,
       [
         name: RickTacMorty.DistributedSupervisor,
         shutdown: 1000,
         strategy: :one_for_one,
         members: :auto
       ]},
      # Start the Endpoint (http/https)
      RickTacMortyWeb.Endpoint
      # Start a worker by calling: RickTacMorty.Worker.start_link(arg)
      # {RickTacMorty.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RickTacMorty.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RickTacMortyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
