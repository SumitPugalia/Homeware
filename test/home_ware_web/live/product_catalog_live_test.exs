defmodule HomeWareWeb.ProductCatalogLiveTest do
  use HomeWareWeb.ConnCase

  import Phoenix.LiveViewTest
  alias HomeWare.Factory
  alias HomeWare.Guardian

  setup %{conn: conn} do
    user = Factory.insert(:user)
    category = Factory.insert(:category)
    product = Factory.insert(:product, %{category_id: category.id})
    {:ok, token, _claims} = Guardian.encode_and_sign(user)
    conn = conn
           |> fetch_session()
           |> put_session(:user_token, token)
    %{conn: conn, product: product, category: category, user: user}
  end

  describe "index" do
    test "renders product catalog", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/products")
      assert html =~ "Filters"
    end

    test "filters products by category", %{conn: conn, category: category} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      assert index_live
             |> form("#filter-form", %{category: category.id})
             |> render_submit()
    end

    test "filters products by brand", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      assert index_live
             |> form("#filter-form", %{brand: "Test Brand"})
             |> render_submit()
    end

    test "filters products by price range", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      assert index_live
             |> form("#filter-form", %{min_price: "10", max_price: "100"})
             |> render_submit()
    end

    test "adds product to cart", %{conn: conn, product: product} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      assert index_live
             |> element("[data-product-id='#{product.id}'] button[phx-click='add_to_cart']")
             |> render_click()
    end
  end
end
