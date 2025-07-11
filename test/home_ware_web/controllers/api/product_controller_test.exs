defmodule HomeWareWeb.Api.ProductControllerTest do
  use HomeWareWeb.ConnCase

  alias HomeWare.Factory

  setup do
    category = Factory.insert(:category)
    product = Factory.insert(:product, %{category_id: category.id})
    %{product: product}
  end

  describe "GET /api/products" do
    test "returns products list", %{conn: conn} do
      conn = get(conn, ~p"/api/products")
      response = json_response(conn, 200)

      assert response["products"]
      assert response["pagination"]
      assert response["pagination"]["page_number"] == 1
    end
  end

  describe "GET /api/products/:id" do
    test "returns product when found", %{conn: conn, product: product} do
      conn = get(conn, ~p"/api/products/#{product.id}")
      response = json_response(conn, 200)

      assert response["id"] == product.id
      assert response["name"] == product.name
      assert response["price"] == product.price
    end

    test "returns 404 when product not found", %{conn: conn} do
      conn = get(conn, ~p"/api/products/non-existent-id")
      assert json_response(conn, 404)
    end
  end
end
