defmodule ScpToAnywhere.Slack do
  use ScpToAnywhere.Destination
  require Logger

  @spec start_file_xfer(String.t, String.t, String.t) :: {:ok, term} | {:error, term}
  def start_file_xfer(user, dest, filename) do
    # ex: <team>/channel/<channel name>
    # TODO support also sending to users
    path = Path.split(dest)
    case path do
      [team, "channel", chname] ->
        {:ok, token} = get_slack_token(user, team)
        {:ok, ref} = :hackney.request(:post, "https://slack.com/api/files.upload", [], :stream_multipart, [])
        start_multipart(ref, token, chname, filename)
      _ ->
        {:error, :unsupported_path}
    end
  end

  def file_xfer_part(ref, part) do
    :hackney.send_multipart_body(ref, {:part_bin, part})
  end

  def finish_file_xfer(ref, last_part) do
    :ok = :hackney.send_multipart_body(ref, {:part_bin, last_part})
    :ok = :hackney.send_multipart_body(ref, {:part, :eof})
    :ok = :hackney.send_multipart_body(ref, :eof)
    {:ok, _status, _headers, ref} = :hackney.start_response(ref)
    # TODO actually handle response body, there could be errors in here
    {:ok, _body} = :hackney.body(ref)
    :ok
  end

  defp start_multipart(ref, token, channel, filename) do
    :ok = :hackney.send_multipart_body(ref, {:data, "token", token})
    :ok = :hackney.send_multipart_body(ref, {:data, "channels", "##{channel}"})
    :ok = :hackney.send_multipart_body(ref, {:data, "filename", filename})
    :ok = :hackney.send_multipart_body(ref, {:data, "file", filename})
    # Sending a weird name for the part, so slack understands. Probably a better way to set this
    # TODO Figure out better way to send 'name="file"; filename="name_of_file.jpg"' in content-disposition
    :ok = :hackney.send_multipart_body(ref, {:part, "file\"; filename=\"#{filename}"})

    {:ok, ref}
  end

  defp get_slack_token(_user, _team) do
    token = Application.get_env(:scp_to_anywhere, :slack_token)
    {:ok, token}
  end
end
