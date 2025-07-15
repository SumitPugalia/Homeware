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

    # Virtual field for availability
    field :available?, :boolean, virtual: true

    belongs_to :category, HomeWare.Categories.Category
    has_many :variants, HomeWare.Products.ProductVariant
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

  @doc """
  Checks if a product is available for purchase.
  For products without variants, checks total inventory quantity.
  For products with variants, checks if any variant has quantity > 0.
  """
  def available?(%__MODULE__{variants: []} = product) do
    product.inventory_quantity > 0
  end

  def available?(%__MODULE__{variants: variants}) do
    Enum.any?(variants, &(&1.quantity > 0))
  end

  @doc """
  Gets the total available quantity for a product.
  For products without variants, returns inventory_quantity.
  For products with variants, returns the sum of all variant quantities.
  """
  def total_available_quantity(%__MODULE__{variants: []} = product) do
    product.inventory_quantity
  end

  def total_available_quantity(%__MODULE__{variants: variants}) do
    variants
    |> Enum.filter(& &1.is_active)
    |> Enum.map(& &1.quantity)
    |> Enum.sum()
  end

  @doc """
  Checks if a product has variants.
  """
  def has_variants?(%__MODULE__{variants: variants}) do
    length(variants) > 0
  end
end
