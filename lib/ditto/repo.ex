defmodule Ditto.Repo do
  use Ecto.Repo,
    otp_app: :ditto,
    adapter: Ecto.Adapters.SQLite3
end
