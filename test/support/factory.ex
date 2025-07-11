defmodule HomeWare.Factory do
  @moduledoc """
  Factory module for creating test data.
  """

  def build(factory, attrs \\ %{})

  def build(:user, attrs) do
    %HomeWare.Accounts.User{
      id: Ecto.UUID.generate(),
      email: "user#{System.unique_integer()}@example.com",
      hashed_password: Bcrypt.hash_pwd_salt("password123"),
      first_name: "John",
      last_name: "Doe",
      phone: "+1-555-123-4567",
      role: :customer,
      is_active: true,
      confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }
    |> Map.merge(attrs)
  end

  def build(:category, attrs) do
    %HomeWare.Categories.Category{
      id: Ecto.UUID.generate(),
      name: "Test Category",
      slug: "test-category",
      description: "Test category description",
      image_url: "https://example.com/category.jpg",
      is_active: true
    }
    |> Map.merge(attrs)
  end

  def build(:product, attrs) do
    category_id = Map.get(attrs, :category_id) || HomeWare.Factory.insert(:category).id
    %HomeWare.Products.Product{
      id: Ecto.UUID.generate(),
      name: "Test Product",
      slug: "test-product",
      description: "Test product description",
      short_description: "Test short description",
      price: Decimal.new("99.99"),
      compare_at_price: Decimal.new("129.99"),
      sku: "SKU-#{System.unique_integer()}",
      brand: "Test Brand",
      model: "Test Model",
      weight: Decimal.new("5.5"),
      dimensions: %{"length" => 10, "width" => 5, "height" => 3},
      specifications: %{"color" => "White", "material" => "Stainless Steel"},
      images: ["https://example.com/image1.jpg"],
      featured_image: "https://example.com/featured.jpg",
      inventory_quantity: 10,
      is_featured: false,
      is_active: true,
      average_rating: Decimal.new("4.5"),
      review_count: 5,
      category_id: category_id
    }
    |> Map.merge(attrs)
  end

  def build(:address, attrs) do
    %HomeWare.Address{
      id: Ecto.UUID.generate(),
      address_type: :shipping,
      first_name: "John",
      last_name: "Doe",
      company: "ACME Corp",
      address_line_1: "123 Main St",
      address_line_2: "Apt 4B",
      city: "New York",
      state: "NY",
      postal_code: "10001",
      country: "USA",
      phone: "+1-555-123-4567",
      is_default: true,
      user_id: Ecto.UUID.generate()
    }
    |> Map.merge(attrs)
  end

  def build(:order, attrs) do
    %HomeWare.Orders.Order{
      id: Ecto.UUID.generate(),
      order_number: "ORD-#{System.unique_integer()}",
      status: :pending,
      subtotal: Decimal.new("100.00"),
      tax_amount: Decimal.new("8.00"),
      shipping_amount: Decimal.new("10.00"),
      discount_amount: Decimal.new("0.00"),
      total_amount: Decimal.new("118.00"),
      currency: "USD",
      notes: "Test order",
      tracking_number: nil,
      shipped_at: nil,
      delivered_at: nil,
      cancelled_at: nil,
      cancellation_reason: nil
    }
    |> Map.merge(attrs)
  end

  def build(:order_item, attrs) do
    %HomeWare.Orders.OrderItem{
      id: Ecto.UUID.generate(),
      quantity: 2,
      unit_price: Decimal.new("49.99"),
      total_price: Decimal.new("99.98"),
      notes: "Test order item"
    }
    |> Map.merge(attrs)
  end

  def build(:product_review, attrs) do
    %HomeWare.ProductReview{
      id: Ecto.UUID.generate(),
      rating: 5,
      title: "Great Product!",
      content: "This is an excellent product that exceeded my expectations. Highly recommended!",
      status: :approved,
      is_verified_purchase: true,
      helpful_votes: 10,
      unhelpful_votes: 2
    }
    |> Map.merge(attrs)
  end

  def build(:cart_item, attrs) do
    %HomeWare.CartItem{
      id: Ecto.UUID.generate(),
      quantity: 3,
      unit_price: Decimal.new("49.99"),
      total_price: Decimal.new("149.97"),
      notes: "Gift for mom",
      user_id: Ecto.UUID.generate(),
      product_id: Ecto.UUID.generate()
    }
    |> Map.merge(attrs)
  end

  # Helper function to create and insert records
  def insert(factory, attrs \\ %{}) do
    build(factory, attrs)
    |> HomeWare.Repo.insert!()
  end
end
