defmodule HomeWareWeb.AdminProductsLiveTest do
  use HomeWareWeb.ConnCase

  import Phoenix.LiveViewTest
  alias HomeWare.Factory
  alias HomeWare.Guardian

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(HomeWare.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(HomeWare.Repo, {:shared, self()})
    user = Factory.insert(:user, %{role: :admin})
    {:ok, token, _claims} = Guardian.encode_and_sign(user)
    %{user: user, token: token}
  end

  defp log_in_user(conn, user, token) do
    conn
    |> put_req_header("authorization", "Bearer #{token}")
    |> assign(:current_user, user)
  end

  describe "index" do
    test "redirects to login when not authenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log_in"}}} = live(conn, ~p"/admin/products")
    end

    test "redirects when user is not admin", %{conn: conn} do
      user = Factory.insert(:user, %{role: :customer})
      {:ok, token, _claims} = Guardian.encode_and_sign(user)
      conn = log_in_user(conn, user, token)
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin/products")
    end

    test "renders products management when authenticated as admin", %{
      conn: conn,
      user: user,
      token: token
    } do
      conn = log_in_user(conn, user, token)
      {:ok, _index_live, html} = live(conn, ~p"/admin/products")
      assert html =~ "Product Management"
      assert html =~ "Add Product"
    end

    test "shows products table", %{conn: conn, user: user, token: token} do
      conn = log_in_user(conn, user, token)
      {:ok, _index_live, html} = live(conn, ~p"/admin/products")
      assert html =~ "Products"
      assert html =~ "Product"
      assert html =~ "Category"
      assert html =~ "Price"
      assert html =~ "Inventory"
      assert html =~ "Status"
      assert html =~ "Actions"
    end

    test "shows add product form when button is clicked", %{conn: conn, user: user, token: token} do
      conn = log_in_user(conn, user, token)
      {:ok, index_live, _html} = live(conn, ~p"/admin/products")

      assert index_live
             |> element("button", "Add Product")
             |> render_click() =~ "Add New Product"
    end

    test "can create a new product", %{conn: conn, user: user, token: token} do
      category = Factory.insert(:category)
      conn = log_in_user(conn, user, token)
      {:ok, index_live, _html} = live(conn, ~p"/admin/products")

      # Click add product button
      index_live
      |> element("button", "Add Product")
      |> render_click()

      # Fill in the form
      index_live
      |> form("#product-form", %{
        "product[name]" => "Test Product",
        "product[slug]" => "test-product",
        "product[price]" => "29.99",
        "product[category_id]" => category.id,
        "product[description]" => "A test product",
        "product[sku]" => "TEST-001",
        "product[brand]" => "Test Brand",
        "product[inventory_quantity]" => "10",
        "product[is_active]" => "true"
      })
      |> render_submit()

      # Should show success message
      assert has_element?(index_live, ".alert", "Product created successfully")
    end

    test "can edit an existing product", %{conn: conn, user: user, token: token} do
      product = Factory.insert(:product, %{name: "Original Name"})
      category = Factory.insert(:category)
      conn = log_in_user(conn, user, token)
      {:ok, index_live, _html} = live(conn, ~p"/admin/products")

      # Click edit button
      index_live
      |> element("button", "Edit")
      |> render_click()

      # Update the form
      index_live
      |> form("#product-form", %{
        "product[name]" => "Updated Name",
        "product[price]" => "39.99"
      })
      |> render_submit()

      # Should show success message
      assert has_element?(index_live, ".alert", "Product updated successfully")
    end

    test "can delete a product", %{conn: conn, user: user, token: token} do
      product = Factory.insert(:product, %{name: "Product to Delete"})
      conn = log_in_user(conn, user, token)
      {:ok, index_live, _html} = live(conn, ~p"/admin/products")

      # Click delete button
      index_live
      |> element("button", "Delete")
      |> render_click()

      # Should show confirmation dialog
      assert has_element?(index_live, "[data-confirm]")
    end
  end
end
