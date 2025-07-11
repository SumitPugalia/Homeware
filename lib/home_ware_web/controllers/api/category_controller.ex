defmodule HomeWareWeb.Api.CategoryController do
  use HomeWareWeb, :controller

  alias HomeWare.Categories

  def index(conn, _params) do
    categories = Categories.list_categories()

    conn
    |> put_status(:ok)
    |> json(%{
      categories: Enum.map(categories, &category_to_json/1)
    })
  end

  defp category_to_json(category) do
    %{
      id: category.id,
      name: category.name,
      description: category.description,
      slug: category.slug,
      is_active: category.is_active,
      inserted_at: category.inserted_at,
      updated_at: category.updated_at
    }
  end
end
