defmodule HomeWareWeb.Formatters do
  @moduledoc """
  Utility functions for formatting data in templates.
  """

  @doc """
  Formats a decimal amount as currency with the ₹ symbol.
  """
  def format_currency(amount, precision \\ 2) do
    "₹#{Number.Delimit.number_to_delimited(amount, precision: precision)}"
  end

  @doc """
  Formats a price with discount display.
  """
  def format_price_with_discount(original_price, selling_price) do
    discount_percentage = calculate_discount_percentage(original_price, selling_price)
    "#{format_currency(selling_price)} (#{discount_percentage}% OFF)"
  end

  @doc """
  Calculates discount percentage between original and selling price.
  """
  def calculate_discount_percentage(original_price, selling_price) do
    discount = Decimal.sub(original_price, selling_price)
    percentage = Decimal.div(discount, original_price)

    Decimal.mult(percentage, Decimal.new(100))
    |> Decimal.round(0)
    |> Decimal.to_integer()
  end

  @doc """
  Formats availability status for display.
  """
  def format_availability_status(available?, inventory_quantity \\ nil) do
    cond do
      !available? -> "Out of Stock"
      inventory_quantity && inventory_quantity <= 5 -> "Low Stock"
      true -> "In Stock"
    end
  end

  @doc """
  Formats a date in a human-readable format.
  """
  def format_date(date) do
    Calendar.strftime(date, "%B %d, %Y")
  end

  @doc """
  Formats a datetime in a human-readable format.
  """
  def format_datetime(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y at %I:%M %p")
  end

  @doc """
  Truncates text to a specified length with ellipsis.
  """
  def truncate_text(text, max_length) when is_binary(text) and byte_size(text) > max_length do
    text
    |> binary_part(0, max_length)
    |> Kernel.<>("...")
  end

  def truncate_text(text, _max_length), do: text
end
