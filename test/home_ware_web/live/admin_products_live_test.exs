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
      live |> element("button", "Add Product") |> render_click()
      html = render(live)
      assert html =~ "Add New Product"
      assert html =~ category.name
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
      # Check that the product appears in the table
      assert render(live) =~ "UI Created Product"
    end

    test "can edit an existing product", %{conn: conn, user: user, token: token} do
      category = Factory.insert(:category)
      product = Factory.insert(:product, %{category_id: category.id})
      conn = log_in_user(conn, user, token)
      {:ok, live, _html} = live(conn, ~p"/admin/products")
      assert render(live) =~ product.name
      live |> element("button", "Edit") |> render_click()
      html = render(live)
      assert html =~ "Edit Product"
      assert html =~ product.name

      live
      |> form("#product-form", %{
        "product[name]" => "Edited Product Name",
        "product[price]" => "99.99"
      })
      |> render_submit()

      assert has_element?(live, ".alert", "Product updated successfully")
      assert render(live) =~ "Edited Product Name"
    end

    test "can delete a product", %{conn: conn, user: user, token: token} do
      category = Factory.insert(:category)
      product = Factory.insert(:product, %{category_id: category.id})
      conn = log_in_user(conn, user, token)
      {:ok, live, _html} = live(conn, ~p"/admin/products")
      assert render(live) =~ product.name
      assert has_element?(live, "[data-confirm]")
    end

    test "form validation works", %{conn: conn, user: user, token: token} do
      category = Factory.insert(:category)
      conn = log_in_user(conn, user, token)
      {:ok, live, _html} = live(conn, ~p"/admin/products")
      live |> element("button", "Add Product") |> render_click()

      live
      |> form("#product-form", %{
        "product[name]" => "",
        "product[price]" => "invalid"
      })
      |> render_submit()

      assert render(live) =~ "Add New Product"
      # The form should still be visible after validation errors
      assert render(live) =~ "Name"
    end

    test "can cancel form", %{conn: conn, user: user, token: token} do
      conn = log_in_user(conn, user, token)
      {:ok, live, _html} = live(conn, ~p"/admin/products")
      live |> element("button", "Add Product") |> render_click()
      assert render(live) =~ "Add New Product"
      live |> element("button", "Cancel") |> render_click()
      refute render(live) =~ "Add New Product"
    end
  end
end
