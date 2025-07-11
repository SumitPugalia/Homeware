defmodule HomeWareWeb.ProductCatalogLiveTest do
  use HomeWareWeb.ConnCase

  import Phoenix.LiveViewTest
  alias HomeWare.Factory

  setup do
    category = Factory.insert(:category)
    product = Factory.insert(:product, %{category_id: category.id})
    %{product: product, category: category}
  end

  describe "index" do
    test "renders product catalog", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/products")
      assert html =~ "Product Catalog"
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
             |> element("[data-product-id='#{product.id}']")
             |> render_click()
    end
  end
end
