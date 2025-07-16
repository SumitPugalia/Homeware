defmodule HomeWare.Products do
  @moduledoc """
  The Products context.
  """

  import Ecto.Query, warn: false
  alias HomeWare.Repo
  alias HomeWare.Products.Product
  alias HomeWare.Categories.Category
  alias HomeWare.Products.ProductVariant

  def list_products(params \\ %{}) do
    case params do
      %{} when map_size(params) == 0 ->
        Product
        |> where(is_active: true)
        |> preload(:category)
        |> Repo.all()
        |> Enum.map(&set_availability/1)

      _ ->
        page = params["page"] || 1
        per_page = params["per_page"] || 10

        Product
        |> where(is_active: true)
        |> preload(:category)
        |> order_by([p], desc: p.inserted_at)
        |> Repo.paginate(%{page: page, per_page: per_page})
        |> Map.update!(:entries, fn entries -> Enum.map(entries, &set_availability/1) end)
    end
  end

  def list_all_products do
    Product
    |> preload(:category)
    |> order_by([p], desc: p.inserted_at)
    |> Repo.all()
    |> Enum.map(&set_availability/1)
  end

  def list_featured_products do
    Product
    |> where(is_active: true, is_featured: true)
    |> preload(:category)
    |> limit(8)
    |> Repo.all()
    |> Enum.map(&set_availability/1)
  end

  def list_products_with_variants do
    Product
    |> where(is_active: true)
    |> preload(:category)
    |> preload(variants: ^from(v in HomeWare.Products.ProductVariant, where: v.is_active == true))
    |> Repo.all()
    |> Enum.map(&set_availability/1)
  end

  def list_products_with_filters(filters \\ %{}) do
    Product
    |> where(is_active: true)
    |> apply_search_filter(filters[:search])
    |> apply_category_filter(filters[:category_id])
    |> apply_brand_filter(filters[:brand])
    |> apply_price_filters(filters[:min_price], filters[:max_price])
    |> preload(:category)
    |> preload(variants: ^from(v in HomeWare.Products.ProductVariant, where: v.is_active == true))
    |> order_by([p], desc: p.inserted_at)
    |> Repo.all()
    |> Enum.map(&set_availability/1)
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

  defp apply_brand_filter(query, nil), do: query
  defp apply_brand_filter(query, ""), do: query

  defp apply_brand_filter(query, brand) do
    search_pattern = "%#{brand}%"
    query |> where([p], ilike(p.brand, ^search_pattern))
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
    parsed_filters = Map.update(filters, :min_price, nil, &parse_price/1)
    parsed_filters = Map.update(parsed_filters, :max_price, nil, &parse_price/1)

    Product
    |> where(is_active: true)
    |> apply_filters(parsed_filters)
    |> preload(:category)
    |> preload(variants: ^from(v in HomeWare.Products.ProductVariant, where: v.is_active == true))
    |> order_by([p], desc: p.inserted_at)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.update!(:entries, fn entries -> Enum.map(entries, &set_availability/1) end)
  end

  defp parse_price(nil), do: nil
  defp parse_price(""), do: nil

  defp parse_price(price) when is_binary(price) do
    case Float.parse(price) do
      {num, _} -> num
      :error -> nil
    end
  end

  defp parse_price(price) when is_number(price), do: price

  def get_product!(id) do
    Product
    |> where(id: ^id)
    |> preload(:category)
    |> Repo.one!()
    |> set_availability()
  end

  def get_product_with_variants!(id) do
    product =
      Product
      |> where(id: ^id)
      |> preload(:category)
      |> preload(
        variants: ^from(v in HomeWare.Products.ProductVariant, where: v.is_active == true)
      )
      |> Repo.one!()

    # Set available? on all variants first
    variants = HomeWare.Products.ProductVariant.set_availability(product.variants)
    product_with_variants = %{product | variants: variants}

    # Then set the product's availability (which depends on variants)
    set_availability(product_with_variants)
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
    |> Enum.map(&set_availability/1)
  end

  def list_related_products(product) do
    Product
    |> where(category_id: ^product.category_id, is_active: true)
    |> where([p], p.id != ^product.id)
    |> preload(:category)
    |> limit(4)
    |> Repo.all()
    |> Enum.map(&set_availability/1)
  end

  def search_products(query) do
    Product
    |> where(is_active: true)
    |> where([p], ilike(p.name, ^"%#{query}%") or ilike(p.description, ^"%#{query}%"))
    |> preload(:category)
    |> Repo.all()
    |> Enum.map(&set_availability/1)
  end

  def list_featured_products_by_category(category_id, limit \\ 4) do
    Product
    |> where(category_id: ^category_id, is_active: true, is_featured: true)
    |> preload(:category)
    |> limit(^limit)
    |> Repo.all()
    |> Enum.map(&set_availability/1)
  end

  defp apply_filters(query, filters) do
    query
    |> apply_search_filter(filters[:search])
    |> apply_category_filter(filters[:category_id])
    |> apply_brand_filter(filters[:brand])
    |> apply_price_filters(filters[:min_price], filters[:max_price])
  end

  @doc """
  Sets the available? field for a product based on its status and inventory.
  If the product has variants, it's considered available if any variant is available.
  """
  def set_availability(%Product{} = product) do
    # If product has variants, check if any variant is available
    available =
      if product.variants && is_list(product.variants) && length(product.variants) > 0 do
        # Product is available if any variant is available
        product.is_active && Enum.any?(product.variants, & &1.available?)
      else
        # Product is available if it's active and has inventory
        product.is_active && product.inventory_quantity > 0
      end

    %{product | available?: available}
  end

  # Product Variant functions for admin
  def create_product_variant(attrs \\ %{}) do
    %ProductVariant{}
    |> ProductVariant.changeset(attrs)
    |> Repo.insert()
  end

  def get_product_variant!(id) do
    ProductVariant
    |> Repo.get!(id)
    |> ProductVariant.set_availability()
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

  def change_product_variant(%ProductVariant{} = variant, attrs \\ %{}) do
    ProductVariant.changeset(variant, attrs)
  end

  # Admin dashboard functions
  def count_products do
    Product
    |> where(is_active: true)
    |> select([p], count(p.id))
    |> Repo.one()
  end

  def top_selling_products(limit \\ 5) do
    # This is a placeholder - in a real app you'd query order_items to get top sellers
    Product
    |> where(is_active: true)
    |> limit(^limit)
    |> Repo.all()
    |> Enum.map(&set_availability/1)
  end

  def list_brands_by_category(category_id) do
    Product
    |> where(category_id: ^category_id, is_active: true)
    |> distinct([p], p.brand)
    |> select([p], p.brand)
    |> where([p], not is_nil(p.brand))
    |> Repo.all()
  end
end
