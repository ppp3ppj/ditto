defmodule Ditto.Accounts.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @derive {Phoenix.Param, key: :slug}

  schema "organizations" do
    field :name, :string
    field :slug, :string
    field :active, :boolean, default: true

    has_many :users, Ditto.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(org, attrs) do
    org
    |> cast(attrs, [:name, :slug, :active])
    |> validate_required([:name, :slug])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:slug, min: 2, max: 63)
    |> validate_format(:slug, ~r/^[a-z0-9][a-z0-9-]*$/,
      message: "must start with a letter or number and only contain lowercase letters, numbers, or hyphens"
    )
    |> update_change(:slug, &String.downcase/1)
    |> unique_constraint(:slug)
  end
end
