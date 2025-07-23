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
    has_many :wishlist_items, HomeWare.WishlistItem

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
    |> cast_assoc(:variants, with: &HomeWare.Products.ProductVariant.changeset/2, required: false)
  end

  @doc """
  Gets the availability status text for display.
  """
  def availability_status(%__MODULE__{} = product) do
    cond do
      !product.is_active -> "Inactive"
      !product.available? -> "Out of Stock"
      has_available_variants?(product) -> "In Stock"
      product.inventory_quantity <= 5 -> "Low Stock"
      true -> "In Stock"
    end
  end

  @doc """
  Gets the availability status color class for display.
  """
  def availability_color(%__MODULE__{} = product) do
    cond do
      !product.is_active -> "bg-gray-500"
      !product.available? -> "bg-red-500"
      has_available_variants?(product) -> "bg-green-500"
      product.inventory_quantity <= 5 -> "bg-yellow-500"
      true -> "bg-green-500"
    end
  end

  @doc """
  Checks if a product is out of stock.
  """
  def out_of_stock?(%__MODULE__{} = product) do
    !product.available?
  end

  @doc """
  Checks if a product has low stock (5 or fewer items).
  """
  def low_stock?(%__MODULE__{} = product) do
    product.available? && product.inventory_quantity <= 5
  end

  @doc """
  Gets the total available quantity for a product.
  """
  def total_available_quantity(%__MODULE__{} = product) do
    if product.is_active, do: product.inventory_quantity, else: 0
  end

  @doc """
  Checks if a product has variants.
  """
  def has_variants?(%__MODULE__{variants: %Ecto.Association.NotLoaded{}}), do: false
  def has_variants?(%__MODULE__{variants: variants}), do: length(variants) > 0

  @doc """
  Checks if a product has any available variants.
  """
  def has_available_variants?(%__MODULE__{variants: %Ecto.Association.NotLoaded{}}), do: false

  def has_available_variants?(%__MODULE__{variants: variants}) when is_list(variants) do
    Enum.any?(variants, & &1.available?)
  end

  def has_available_variants?(_), do: false
end
