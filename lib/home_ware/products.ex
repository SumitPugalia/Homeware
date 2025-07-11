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

  def paginated_products(page, per_page, filters \\ %{}) do
    Product
    |> where(is_active: true)
    |> apply_filters(filters)
    |> preload(:category)
    |> order_by([p], desc: p.inserted_at)
    |> Repo.paginate(page: page, page_size: per_page)
  end

  def get_product!(id) do
    Product
    |> where(id: ^id)
    |> preload(:category)
    |> Repo.one!()
  end

  def get_product_by_slug!(slug) do
    Product
    |> where(slug: ^slug)
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
    Repo.delete(product)
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
