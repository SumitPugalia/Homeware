defmodule HomeWareWeb.PageController do
  use HomeWareWeb, :controller

  alias HomeWare.Products
  alias HomeWare.Categories

  def home(conn, _params) do
    featured_products = Products.list_featured_products()
    categories = Categories.list_categories()

    render(conn, :home,
      featured_products: featured_products,
      categories: categories
    )
  end
end
