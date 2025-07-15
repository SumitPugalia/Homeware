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
    field :compare_at_price, :decimal

    field :weight, :decimal
    field :dimensions, :map

    field :specifications, :map

    field :images, {:array, :string}, default: []

    field :featured_image, :string

    field :inventory_quantity, :integer
    field :is_featured, :boolean, default: false
    field :is_active, :boolean, default: true

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
      :slug,
      :description,
      :short_description,
      :price,
      :compare_at_price,
      :sku,
      :brand,
      :model,
      :weight,
      :dimensions,
      :specifications,
      :images,
      :featured_image,
      :inventory_quantity,
      :is_featured,
      :is_active,
      :category_id,
      :average_rating,
      :review_count
    ])
    |> validate_required([:name, :slug, :price])
    |> validate_number(:price, greater_than: 0)
    |> validate_number(:inventory_quantity, greater_than_or_equal_to: 0)
    |> validate_number(:average_rating, greater_than_or_equal_to: 0, less_than_or_equal_to: 5)
    |> validate_number(:review_count, greater_than_or_equal_to: 0)
    |> unique_constraint(:slug)
    |> unique_constraint(:sku)
  end
end
