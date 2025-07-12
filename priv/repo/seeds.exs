# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     HomeWare.Repo.insert!(%HomeWare.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias HomeWare.Categories

# Create categories
case Categories.create_category(%{
       name: "Vape",
       slug: "vape",
       description: "Vaping products and accessories",
       is_active: true
     }) do
  {:ok, category} -> IO.puts("✅ Created category: #{category.name}")
  {:error, changeset} -> IO.puts("❌ Failed to create Vape category: #{inspect(changeset.errors)}")
end

case Categories.create_category(%{
       name: "Sex Toys",
       slug: "sex-toys",
       description: "Adult toys and accessories",
       is_active: true
     }) do
  {:ok, category} ->
    IO.puts("✅ Created category: #{category.name}")

  {:error, changeset} ->
    IO.puts("❌ Failed to create Sex Toys category: #{inspect(changeset.errors)}")
end

IO.puts("✅ Seed file completed!")
