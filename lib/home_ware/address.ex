defmodule HomeWare.Address do
  use Ecto.Schema
  import Ecto.Changeset

  @types ~w(shipping billing)a

  schema "addresses" do
    field :type, Ecto.Enum, values: @types
    field :first_name, :string
    field :last_name, :string
    field :company, :string
    field :address_line_1, :string
    field :address_line_2, :string
    field :city, :string
    field :state, :string
    field :postal_code, :string
    field :country, :string
    field :phone, :string
    field :is_default, :boolean, default: false

    belongs_to :user, HomeWare.Accounts.User
    has_many :billing_orders, HomeWare.Orders.Order, foreign_key: :billing_address_id
    has_many :shipping_orders, HomeWare.Orders.Order, foreign_key: :shipping_address_id

    timestamps()
  end

  def changeset(address, attrs) do
    address
    |> cast(attrs, [:type, :first_name, :last_name, :company, :address_line_1, :address_line_2, :city, :state, :postal_code, :country, :phone, :is_default, :user_id])
    |> validate_required([:type, :first_name, :last_name, :address_line_1, :city, :state, :postal_code, :country, :user_id])
    |> validate_inclusion(:type, @types)
  end
end
