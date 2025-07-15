defmodule HomeWare.Products.ProductVariant do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "product_variants" do
    field :option_name, :string
    field :sku, :string
    field :price_override, :decimal
    field :quantity, :integer, default: 0
    field :is_active, :boolean, default: true

    belongs_to :product, HomeWare.Products.Product

    timestamps(type: :utc_datetime)
  end

  def changeset(product_variant, attrs) do
    product_variant
    |> cast(attrs, [:option_name, :sku, :price_override, :quantity, :is_active, :product_id])
    |> validate_required([:option_name, :quantity, :sku, :product_id])
    |> validate_number(:quantity, greater_than_or_equal_to: 0)
    |> validate_number(:price_override, greater_than: 0)
    |> foreign_key_constraint(:product_id)
  end
end
