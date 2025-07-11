defmodule HomeWare.Guardian do
  use Guardian, otp_app: :home_ware

  alias HomeWare.Accounts

  def subject_for_token(user, _claims) do
    {:ok, user.id}
  end

  def resource_from_claims(%{"sub" => user_id}) do
    case Accounts.get_user!(user_id) do
      user -> {:ok, user}
    end
  rescue
    Ecto.NoResultsError -> {:error, :resource_not_found}
  end
end
