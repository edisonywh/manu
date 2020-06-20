ExUnit.start()

defmodule Manu.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:password, :string)
    field(:password_hash, :string, virtual: true)

    has_one(:address, Manu.Address)
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:name, :email])
    |> validate_required([:name])
    |> validate_length(:name, min: 3)
  end

  def changeset_cast_assoc(schema, attrs) do
    schema
    |> changeset(attrs)
    |> cast_assoc(:address)
  end

  def changeset_put_assoc(schema, attrs) do
    schema
    |> changeset(attrs)
    |> put_assoc(:address, attrs.address)
  end

  def email_changeset(schema, attrs) do
    schema
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
  end
end

defmodule Manu.Address do
  use Ecto.Schema
  import Ecto.Changeset

  schema "addresses" do
    field(:lat, :float)
    field(:lon, :float)
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:lat, :lon])
    |> validate_change(:lon, fn :lon, val ->
      if val >= 5.0 do
        []
      else
        [lon: "needs to be more than 5.0"]
      end
    end)
  end
end
