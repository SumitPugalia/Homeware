defmodule HomeWare.UploadBehaviour do
  @callback upload_file(String.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
end
