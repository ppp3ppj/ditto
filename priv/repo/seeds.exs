# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Ditto.Repo.insert!(%Ditto.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Ditto.Accounts.User
alias Ditto.Repo

# Default sysadmin credentials:
#   Email:    admin@admin.com
#   Password: Admin@123456
#
# Change the password immediately after first login via /users/settings.

sysadmin_attrs = %{
  "email" => "admin@admin.com",
  "username" => "sysadmin",
  "password" => "Admin@123456"
}

case Repo.get_by(User, email: "admin@admin.com") do
  nil ->
    %User{}
    |> User.registration_changeset(sysadmin_attrs)
    |> Ecto.Changeset.put_change(:is_sysadmin, true)
    |> Repo.insert!()

    IO.puts("✓ Default sysadmin created: admin@admin.com / Admin@123456")

  _existing ->
    IO.puts("- Sysadmin admin@admin.com already exists, skipping.")
end
