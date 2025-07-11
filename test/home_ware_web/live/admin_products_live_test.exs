defmodule HomeWareWeb.AdminProductsLiveTest do
  use HomeWareWeb.ConnCase

  import Phoenix.LiveViewTest
  alias HomeWare.Factory
  alias HomeWare.Guardian

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(HomeWare.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(HomeWare.Repo, {:shared, self()})
    end

    user = Factory.insert(:user, %{role: :admin})
    {:ok, token, _claims} = Guardian.encode_and_sign(user)
    %{user: user, token: token}
  end

  defp log_in_user(conn, user, token) do
    conn
    |> put_req_header("authorization", "Bearer #{token}")
    |> assign(:current_user, user)
  end

  describe "admin products live" do
    test "redirects to login when not authenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log_in"}}} = live(conn, ~p"/admin/products")
    end

    test "redirects when user is not admin", %{conn: conn} do
      user = Factory.insert(:user, %{role: :customer})
      {:ok, token, _claims} = Guardian.encode_and_sign(user)
      conn = log_in_user(conn, user, token)
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin/products")
    end

    test "renders products management for admin", %{conn: conn, user: user, token: token} do
      conn = log_in_user(conn, user, token)
      {:ok, _live, html} = live(conn, ~p"/admin/products")
      assert html =~ "Product Management"
      assert html =~ "Add Product"
    end

    test "shows products table", %{conn: conn, user: user, token: token} do
      conn = log_in_user(conn, user, token)
      {:ok, _live, html} = live(conn, ~p"/admin/products")
      assert html =~ "Products"
      assert html =~ "Category"
      assert html =~ "Price"
      assert html =~ "Inventory"
      assert html =~ "Status"
      assert html =~ "Actions"
    end

    test "shows add product form when button is clicked", %{conn: conn, user: user, token: token} do
      category = Factory.insert(:category)
      conn = log_in_user(conn, user, token)
      {:ok, live, _html} = live(conn, ~p"/admin/products")
      assert live |> element("button", "Add Product") |> render_click() =~ "Add New Product"
    end

    test "can create a new product", %{conn: conn, user: user, token: token} do
      category = Factory.insert(:category)
      conn = log_in_user(conn, user, token)
      {:ok, live, _html} = live(conn, ~p"/admin/products")
      live |> element("button", "Add Product") |> render_click()

      live
      |> form("#product-form", %{
        "product[name]" => "UI Created Product",
        "product[slug]" => "ui-created-product",
        "product[price]" => "123.45",
        "product[category_id]" => category.id,
        "product[description]" => "A product created via UI test",
        "product[sku]" => "UI-001",
        "product[brand]" => "UITestBrand",
        "product[inventory_quantity]" => "7",
        "product[is_active]" => "true"
      })
      |> render_submit()

      assert has_element?(live, ".alert", "Product created successfully")
      assert render(live) =~ "UI Created Product"
    end

    test "can edit an existing product", %{conn: conn, user: user, token: token} do
      category = Factory.insert(:category)
      conn = log_in_user(conn, user, token)
      {:ok, live, _html} = live(conn, ~p"/admin/products")
      # Create product via UI
      live |> element("button", "Add Product") |> render_click()

      live
      |> form("#product-form", %{
        "product[name]" => "Editable Product",
        "product[slug]" => "editable-product",
        "product[price]" => "50.00",
        "product[category_id]" => category.id,
        "product[description]" => "To be edited",
        "product[sku]" => "EDIT-001",
        "product[brand]" => "EditBrand",
        "product[inventory_quantity]" => "3",
        "product[is_active]" => "true"
      })
      |> render_submit()

      assert has_element?(live, ".alert", "Product created successfully")
      # Click edit on the first Edit button
      live |> element("button", "Edit") |> render_click()

      live
      |> form("#product-form", %{
        "product[name]" => "Edited Product",
        "product[price]" => "99.99"
      })
      |> render_submit()

      assert has_element?(live, ".alert", "Product updated successfully")
      assert render(live) =~ "Edited Product"
    end

    test "can delete a product", %{conn: conn, user: user, token: token} do
      category = Factory.insert(:category)
      conn = log_in_user(conn, user, token)
      {:ok, live, _html} = live(conn, ~p"/admin/products")
      # Create product via UI
      live |> element("button", "Add Product") |> render_click()

      live
      |> form("#product-form", %{
        "product[name]" => "Deletable Product",
        "product[slug]" => "deletable-product",
        "product[price]" => "10.00",
        "product[category_id]" => category.id,
        "product[description]" => "To be deleted",
        "product[sku]" => "DEL-001",
        "product[brand]" => "DelBrand",
        "product[inventory_quantity]" => "1",
        "product[is_active]" => "true"
      })
      |> render_submit()

      assert has_element?(live, ".alert", "Product created successfully")
      # Click delete on the first Delete button
      live |> element("button", "Delete") |> render_click()
      # Should show confirmation dialog (data-confirm)
      assert has_element?(live, "[data-confirm]")
    end
  end
end
