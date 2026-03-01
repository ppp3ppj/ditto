defmodule Ditto.Accounts.Scope do
  @moduledoc """
  Defines the scope of the caller to be used throughout the app.

  The `Ditto.Accounts.Scope` allows public interfaces to receive
  information about the caller, such as if the call is initiated from an
  end-user, and if so, which user. Additionally, such a scope can carry fields
  such as "super user" or other privileges for use as authorization, or to
  ensure specific code paths can only be access for a given scope.

  It is useful for logging as well as for scoping pubsub subscriptions and
  broadcasts when a caller subscribes to an interface or performs a particular
  action.
  """

  alias Ditto.Accounts.{User, Organization}

  defstruct user: nil, organization: nil

  @doc """
  Creates a scope for the given user, automatically loading their organization.

  Returns nil if no user is given.
  """
  def for_user(%User{} = user) do
    org =
      if user.organization_id do
        Ditto.Repo.get(Organization, user.organization_id)
      end

    %__MODULE__{user: user, organization: org}
  end

  def for_user(nil), do: nil
end
