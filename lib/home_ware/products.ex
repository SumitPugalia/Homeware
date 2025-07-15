defmodule HomeWare.Products do
  @moduledoc """
  The Products context.
  """

  import Ecto.Query, warn: false
  alias HomeWare.Repo
  alias HomeWare.Products.Product
  alias HomeWare.Categories.Category

  def list_products(params \\ %{}) do
    case params do
      %{} when map_size(params) == 0 ->
        Product
        |> where(is_active: true)
        |> preload(:category)
        |> Repo.all()

      _ ->
        page = params["page"] || 1
        per_page = params["per_page"] || 10

        Product
        |> where(is_active: true)
        |> preload(:category)
        |> order_by([p], desc: p.inserted_at)
        |> Repo.paginate(%{page: page, per_page: per_page})
    end
  end

  def list_all_products do
    Product
    |> preload(:category)
    |> order_by([p], desc: p.inserted_at)
    |> Repo.all()
  end

  def list_featured_products do
    Product
    |> where(is_active: true, is_featured: true)
    |> preload(:category)
    |> limit(8)
    |> Repo.all()
  end

  def list_products_with_variants do
    Product
    |> where(is_active: true)
    |> preload(:category)
    |> preload(variants: ^from(v in HomeWare.Products.ProductVariant, where: v.is_active == true))
    |> Repo.all()
  end

  def list_products_with_filters(filters \\ %{}) do
    Product
    |> where(is_active: true)
    |> apply_search_filter(filters[:search])
    |> apply_category_filter(filters[:category_id])
    |> apply_price_filters(filters[:min_price], filters[:max_price])
    |> preload(:category)
    |> preload(variants: ^from(v in HomeWare.Products.ProductVariant, where: v.is_active == true))
    |> order_by([p], desc: p.inserted_at)
    |> Repo.all()
  end

  defp apply_search_filter(query, nil), do: query
  defp apply_search_filter(query, ""), do: query

  defp apply_search_filter(query, search_term) do
    search_pattern = "%#{search_term}%"

    query
    |> where(
      [p],
      ilike(p.name, ^search_pattern) or ilike(p.description, ^search_pattern) or
        ilike(p.brand, ^search_pattern)
    )
  end

  defp apply_category_filter(query, nil), do: query
  defp apply_category_filter(query, ""), do: query

  defp apply_category_filter(query, category_id) do
    query
    |> where([p], p.category_id == ^category_id)
  end

  defp apply_price_filters(query, nil, nil), do: query

  defp apply_price_filters(query, min_price, nil) when is_number(min_price) do
    query
    |> where([p], p.selling_price >= ^min_price)
  end

  defp apply_price_filters(query, nil, max_price) when is_number(max_price) do
    query
    |> where([p], p.selling_price <= ^max_price)
  end

  defp apply_price_filters(query, min_price, max_price)
       when is_number(min_price) and is_number(max_price) do
    query
    |> where([p], p.selling_price >= ^min_price and p.selling_price <= ^max_price)
  end

  defp apply_price_filters(query, _, _), do: query

  def paginated_products(page, per_page, filters \\ %{}) do
    Product
    |> where(is_active: true)
    |> apply_filters(filters)
    |> preload(:category)
    |> preload(variants: ^from(v in HomeWare.Products.ProductVariant, where: v.is_active == true))
    |> order_by([p], desc: p.inserted_at)
    |> Repo.paginate(page: page, page_size: per_page)
  end

  def get_product!(id) do
    Product
    |> where(id: ^id)
    |> preload(:category)
    |> Repo.one!()
  end

  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  def delete_product(%Product{} = product) do
    product
    |> Product.changeset(%{is_active: false})
    |> Repo.update()
  end

  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end

  def list_categories do
    Category
    |> where(is_active: true)
    |> Repo.all()
  end

  def list_brands do
    Product
    |> where(is_active: true)
    |> distinct([p], p.brand)
    |> select([p], p.brand)
    |> where([p], not is_nil(p.brand))
    |> Repo.all()
  end

  def min_price do
    Product
    |> where(is_active: true)
    |> select([p], min(p.price))
    |> Repo.one()
    |> case do
      nil -> 0
      min_price -> min_price
    end
  end

  def max_price do
    Product
    |> where(is_active: true)
    |> select([p], max(p.price))
    |> Repo.one()
    |> case do
      nil -> 1000
      max_price -> max_price
    end
  end

  def list_products_by_category(category_id) do
    Product
    |> where(category_id: ^category_id, is_active: true)
    |> preload(:category)
    |> Repo.all()
  end

  def list_related_products(product) do
    Product
    |> where(category_id: ^product.category_id, is_active: true)
    |> where([p], p.id != ^product.id)
    |> preload(:category)
    |> limit(4)
    |> Repo.all()
  end

  def search_products(query) do
    search_term = "%#{query}%"

    Product
    |> where(is_active: true)
    |> where([p], ilike(p.name, ^search_term) or ilike(p.description, ^search_term))
    |> preload(:category)
    |> Repo.all()
  end

  def list_product_reviews(_product_id) do
    # This would need to be implemented when ProductReview is available
    []
  end

  def list_brands_by_category(category_id) do
    Product
    |> where(category_id: ^category_id, is_active: true)
    |> distinct([p], p.brand)
    |> select([p], p.brand)
    |> where([p], not is_nil(p.brand))
    |> Repo.all()
  end

  def count_products do
    import Ecto.Query
    alias HomeWare.Products.Product
    HomeWare.Repo.one(from p in Product, select: count(p.id))
  end

  # Product Variant functions
  alias HomeWare.Products.ProductVariant

  def get_product_with_variants!(id) do
    Product
    |> where(id: ^id)
    |> preload(:category)
    |> preload(variants: ^from(v in HomeWare.Products.ProductVariant, where: v.is_active == true))
    |> Repo.one!()
  end

  def create_product_variant(attrs \\ %{}) do
    %ProductVariant{}
    |> ProductVariant.changeset(attrs)
    |> Repo.insert()
  end

  def update_product_variant(%ProductVariant{} = variant, attrs) do
    variant
    |> ProductVariant.changeset(attrs)
    |> Repo.update()
  end

  def delete_product_variant(%ProductVariant{} = variant) do
    variant
    |> ProductVariant.changeset(%{is_active: false})
    |> Repo.update()
  end

  def get_product_variant!(id) do
    ProductVariant
    |> Repo.get!(id)
  end

  def list_product_variants(product_id) do
    ProductVariant
    |> where(product_id: ^product_id, is_active: true)
    |> Repo.all()
  end

  def change_product_variant(%ProductVariant{} = variant, attrs \\ %{}) do
    ProductVariant.changeset(variant, attrs)
  end

  def top_selling_products(n) do
    import Ecto.Query
    alias HomeWare.Products.Product
    # This is a stub: add a random sales_count for demo
    products = HomeWare.Repo.all(from p in Product, limit: ^n)
    Enum.map(products, fn p -> Map.put(p, :sales_count, Enum.random(100..1000)) end)
  end

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn {key, value}, acc ->
      case key do
        :category ->
          acc |> where([p], p.category_id == ^value)

        :brand ->
          acc |> where([p], p.brand == ^value)

        :min_price ->
          acc |> where([p], p.price >= ^value)

        :max_price ->
          acc |> where([p], p.price <= ^value)

        :rating ->
          acc |> where([p], p.average_rating >= ^value)

        :availability ->
          case value do
            "in_stock" -> acc |> where([p], p.inventory_quantity > 0)
            "out_of_stock" -> acc |> where([p], p.inventory_quantity == 0)
            _ -> acc
          end

        _ ->
          acc
      end
    end)
  end
end
