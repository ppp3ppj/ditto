defmodule Ditto.Accounts.Policy do
  @behaviour Bodyguard.Policy

  alias Ditto.Accounts.{User, Organization}

  # Sysadmins can perform any action on any resource
  def authorize(_action, %User{is_sysadmin: true}, _params), do: :ok

  # Only admins can update their own organization's details
  def authorize(:update_organization, %User{role: "admin", organization_id: org_id}, %Organization{id: org_id}),
    do: :ok

  # Only admins can invite new users to their org
  def authorize(:invite_user, %User{role: "admin", organization_id: org_id}, %Organization{id: org_id}),
    do: :ok

  # Admins and managers can view member list
  def authorize(:view_members, %User{role: role, organization_id: org_id}, %Organization{id: org_id})
      when role in ["admin", "manager"],
      do: :ok

  # Only admins can change user roles within their org
  def authorize(:update_user_role, %User{role: "admin", organization_id: org_id}, %Organization{id: org_id}),
    do: :ok

  # Only admins can remove users from their org
  def authorize(:remove_user, %User{role: "admin", organization_id: org_id}, %Organization{id: org_id}),
    do: :ok

  # Catch-all: deny everything else
  def authorize(_action, _user, _params), do: :error
end
