defmodule HomeWare.UploadService do
  @moduledoc """
  Service for handling file uploads to DigitalOcean Spaces.
  """

  @behaviour HomeWare.UploadBehaviour

  alias ExAws.S3
  require Logger

  @impl true
  def upload_file(file_path, destination_path) do
    Logger.info("Uploading file to DigitalOcean Spaces: #{file_path} -> #{destination_path}")

    file_path
    |> S3.Upload.stream_file()
    |> S3.upload(bucket(), destination_path, acl: :public_read)
    |> ExAws.request()
    |> case do
      {:ok, response} ->
        Logger.info("Uploaded file to DigitalOcean Spaces: #{inspect(response)}")
        {:ok, build_public_url(destination_path)}

      {:error, reason} ->
        Logger.error("Error uploading file to DigitalOcean Spaces: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Uploads multiple files and returns a list of public URLs.
  """
  def upload_files(files, base_path) do
    files
    |> Enum.with_index()
    |> Enum.map(fn {file, index} ->
      destination_path = "#{base_path}/#{index}_#{Path.basename(file)}"
      upload_file(file, destination_path)
    end)
    |> Enum.reduce({:ok, []}, fn
      {:ok, url}, {:ok, urls} -> {:ok, [url | urls]}
      {:error, reason}, _ -> {:error, reason}
    end)
    |> case do
      {:ok, urls} -> {:ok, Enum.reverse(urls)}
      error -> error
    end
  end

  @doc """
  Deletes a file from DigitalOcean Spaces.
  """
  def delete_file(file_path) do
    S3.delete_object(bucket(), file_path)
    |> ExAws.request()
  end

  @doc """
  Generates a unique filename for uploads.
  """
  def generate_filename(original_filename) do
    extension = Path.extname(original_filename)
    filename = Path.basename(original_filename, extension)
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    random = :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
    "#{filename}_#{timestamp}_#{random}#{extension}"
  end

  @doc """
  Validates if a file is an image.
  """
  def validate_image(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        case content do
          # JPEG
          <<0xFF, 0xD8, _::binary>> -> {:ok, :jpeg}
          # PNG
          <<0x89, 0x50, 0x4E, 0x47, _::binary>> -> {:ok, :png}
          # GIF
          <<0x47, 0x49, 0x46, 0x38, _::binary>> -> {:ok, :gif}
          # WebP
          <<0x52, 0x49, 0x46, 0x46, _::binary>> -> {:ok, :webp}
          _ -> {:error, "Invalid image format"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Processes uploaded files from Phoenix uploads and uploads them to DO Spaces.
  """
  def process_uploads(uploads, base_path) do
    uploads
    |> Enum.map(fn upload ->
      case upload_file(upload.path, "#{base_path}/#{upload.filename}") do
        {:ok, url} -> {:ok, url}
        {:error, reason} -> {:error, reason}
      end
    end)
    |> Enum.reduce({:ok, []}, fn
      {:ok, url}, {:ok, urls} -> {:ok, [url | urls]}
      {:error, reason}, _ -> {:error, reason}
    end)
    |> case do
      {:ok, urls} -> {:ok, Enum.reverse(urls)}
      error -> error
    end
  end

  defp bucket do
    Application.get_env(:home_ware, :do_spaces_bucket, "vibe")
  end

  defp build_public_url(path) do
    bucket = bucket()
    region = Application.get_env(:home_ware, :do_spaces_region, "blr1")
    "https://#{bucket}.#{region}.digitaloceanspaces.com/#{bucket}/#{path}"
  end

  @doc """
  Sets a public bucket policy to allow public read access to all objects.
  This should be called once during application startup.
  """
  def ensure_bucket_public_access do
    bucket_name = bucket()

    policy =
      %{
        "Version" => "2012-10-17",
        "Statement" => [
          %{
            "Sid" => "PublicReadGetObject",
            "Effect" => "Allow",
            "Principal" => "*",
            "Action" => "s3:GetObject",
            "Resource" => "arn:aws:s3:::#{bucket_name}/*"
          }
        ]
      }
      |> Jason.encode!()

    S3.put_bucket_policy(bucket_name, policy)
    |> ExAws.request()
    |> case do
      {:ok, _response} ->
        Logger.info("Successfully set bucket #{bucket_name} policy to public-read")
        :ok

      {:error, reason} ->
        Logger.warning("Could not set bucket policy: #{inspect(reason)}")
        :error
    end
  end
end
