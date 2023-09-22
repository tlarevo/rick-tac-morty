defmodule RickTacMorty.Repo do
  use Ecto.Repo,
    otp_app: :rick_tac_morty,
    adapter: Ecto.Adapters.Postgres
end
