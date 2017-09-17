defmodule ScpToAnywhere.Slack do
  require Logger

  @spec open_client() :: term
  def open_client() do
    {:ok, ref} = :hackney.request(:post, "https://slack.com/api/files.upload", [], :stream_multipart, [])
    ref
  end

  @spec send_info(term, String.t, String.t, String.t) :: atom
  def send_info(ref, token, channel, filename) do
    :ok = :hackney.send_multipart_body(ref, {:data, "token", token})
    :ok = :hackney.send_multipart_body(ref, {:data, "channels", "##{channel}"})
    :ok = :hackney.send_multipart_body(ref, {:data, "filename", filename})
    :ok = :hackney.send_multipart_body(ref, {:data, "file", filename})
    # Sending a weird name for the part, so slack understands. Probably a better way to set this
    # TODO Figure out better way to send 'name="file"; filename="name_of_file.jpg"' in content-disposition
    :ok = :hackney.send_multipart_body(ref, {:part, "file\"; filename=\"#{filename}"})
    ref
  end

  @spec send_part(term, binary) :: :ok | {:error, term}
  def send_part(ref, part) do
    :hackney.send_multipart_body(ref, {:part_bin, part})
  end

  def finish(ref, last_part) do
    :ok = :hackney.send_multipart_body(ref, {:part_bin, last_part})
    :ok = :hackney.send_multipart_body(ref, {:part, :eof})
    :ok = :hackney.send_multipart_body(ref, :eof)
    {:ok, _status, _headers, ref} = :hackney.start_response(ref)
    # TODO actually handle response body, there could be errors in here
    {:ok, _body} = :hackney.body(ref)
  end
end
