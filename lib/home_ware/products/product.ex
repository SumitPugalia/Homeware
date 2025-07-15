defmodule HomeWare.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "products" do
    field :name, :string
    field :brand, :string
    field :model, :string
    field :product_type, :string
    field :product_category, :string
    field :description, :string

    field :price, :decimal
    field :selling_price, :decimal

    field :dimensions, :map
    field :specifications, :map

    field :images, {:array, :string}, default: []
    field :featured_image, :string

    field :inventory_quantity, :integer
    field :is_active, :boolean, default: true
    field :is_featured, :boolean, default: false

    belongs_to :category, HomeWare.Categories.Category
    has_many :order_items, HomeWare.Orders.OrderItem
    has_many :product_reviews, HomeWare.ProductReview
    has_many :cart_items, HomeWare.CartItem

    timestamps(type: :utc_datetime)
  end

  def changeset(product, attrs) do
    product
    |> cast(attrs, [
      :name,
      :description,
      :price,
      :selling_price,
      :brand,
      :model,
      :product_type,
      :product_category,
      :dimensions,
      :specifications,
      :images,
      :featured_image,
      :inventory_quantity,
      :is_active,
      :is_featured,
      :category_id
    ])
    |> validate_required([
      :name,
      :brand,
      :product_type,
      :product_category,
      :description,
      :price,
      :selling_price,
      :inventory_quantity,
      :category_id,
      :dimensions,
      :specifications,
      :is_active,
      :is_featured
    ])
    |> validate_number(:price, greater_than: 0)
    |> validate_number(:selling_price, greater_than: 0)
    |> validate_number(:inventory_quantity, greater_than_or_equal_to: 0)
  end
end
