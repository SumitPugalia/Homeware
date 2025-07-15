defmodule HomeWareWeb.Admin.ProductControllerTest do
  use HomeWareWeb.ConnCase

  alias HomeWare.Products

  setup %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, %{})
    {:ok, conn: conn}
  end

  describe "GET /admin/products/new" do
    test "renders new product form", %{conn: conn} do
      conn = log_in_admin_user(conn)
      conn = get(conn, ~p"/admin/products/new")
      assert html_response(conn, 200) =~ "Product Details"
    end
  end

  describe "POST /admin/products" do
    setup do
      category = HomeWare.Factory.insert(:category)
      %{category: category}
    end

    test "creates product with valid data", %{conn: conn, category: category} do
      conn = log_in_admin_user(conn)
      product_params = %{
        "name" => "Test Product",
        "slug" => "test-product",
        "description" => "A test product.",
        "category_id" => category.id,
        "brand" => "TestBrand",
        "sku" => "SKU123",
        "inventory_quantity" => 10,
        "price" => 99.99,
        "compare_at_price" => 120.00
      }

      conn = post(conn, ~p"/admin/products", %{"product" => product_params})
      assert redirected_to(conn) == ~p"/admin/products"
      assert get_flash(conn, :info) =~ "Product created"
      assert Products.get_product_by_slug!("test-product").name == "Test Product"
    end
  end
end
