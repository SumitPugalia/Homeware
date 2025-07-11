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

  def about(conn, _params) do
    render(conn, :about)
  end

  def contact(conn, _params) do
    render(conn, :contact)
  end

  def shipping(conn, _params) do
    render(conn, :shipping)
  end

  def returns(conn, _params) do
    render(conn, :returns)
  end

  def privacy(conn, _params) do
    render(conn, :privacy)
  end

  def terms(conn, _params) do
    render(conn, :terms)
  end
end
