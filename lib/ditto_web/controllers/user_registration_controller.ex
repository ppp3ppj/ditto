defmodule DittoWeb.UserRegistrationController do
  use DittoWeb, :controller

  alias Ditto.Accounts
  alias DittoWeb.UserAuth

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Account created! Join an organization to get started.")
        |> UserAuth.log_in_user(user)

      {:error, %Ecto.Changeset{} = _changeset} ->
        conn
        |> put_flash(:error, "Registration failed. Please check your details and try again.")
        |> redirect(to: ~p"/users/register")
    end
  end
end
