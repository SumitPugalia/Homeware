defmodule HomeWare.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Bcrypt, only: [hash_pwd_salt: 1, verify_pass: 2]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @roles ~w(customer admin)a

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :utc_datetime
    field :first_name, :string
    field :last_name, :string
    field :phone, :string
    field :role, Ecto.Enum, values: @roles, default: :customer
    field :is_active, :boolean, default: true

    has_many :addresses, HomeWare.Address
    has_many :orders, HomeWare.Orders.Order
    has_many :product_reviews, HomeWare.ProductReview
    has_many :cart_items, HomeWare.CartItem

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :hashed_password,
      :confirmed_at,
      :first_name,
      :last_name,
      :phone,
      :role,
      :is_active
    ])
    |> validate_required([:email, :hashed_password, :role])
    |> unique_constraint(:email)
    |> validate_inclusion(:role, @roles)
  end

  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :first_name, :last_name, :phone])
    |> validate_email(opts)
    |> validate_password(opts)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 80)
    |> validate_format(:password, ~r/[a-z]/,
      message: "must include at least one lowercase letter"
    )
    |> validate_format(:password, ~r/[0-9]/, message: "must include at least one number")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> validate_length(:password, max: 80, count: :bytes)
      |> put_change(:hashed_password, hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, HomeWare.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  def valid_password?(%HomeWare.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    false
  end

  def change_password(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end
end
