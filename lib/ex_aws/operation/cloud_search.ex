defmodule ExAws.Operation.CloudSearch do
  @moduledoc """
  A datastructure representing an operation on AWS CloudSearch.

  This is fundamentally the same as `ExAws.Operation.JSON`, but it requires a
  separate `ExAws.Operation` implementation so that separate configurations do
  not have to be used for document API calls and search API calls. The
  `ExAws.Operation.CloudSearch` must be configured with the `domain`,
  and depending on the action being performed, one of the `config`, `doc`, or
  `search` domains will be filled into the `config` during execution.

  The `before_request` callback will be called before the host configuration is
  finalized or the CloudSearch API version is prepended to the path.
  """

  defstruct stream_builder: nil,
            http_method: :post,
            parser: nil,
            path: "/",
            data: %{},
            params: %{},
            headers: [],
            before_request: nil,
            domain: nil,
            api_version: "2013-01-01",
            request_type: :search,
            service: :cloudsearch

  @type t :: %__MODULE__{
          stream_builder: nil | (ExAws.Config.t() -> ExAws.Config.t()),
          http_method: :get | :post | :put | :patch | :head | :delete,
          parser: nil | fun(),
          path: String.t(),
          data: map,
          params: map,
          headers: list({String.t(), String.t()}),
          before_request: nil | (t, ExAws.Config.t() -> t),
          domain: String.t(),
          api_version: String.t(),
          request_type: :config | :doc | :search,
          service: :cloudsearch
        }

  @spec new(Enum.t()) :: t
  def new(opts) do
    struct(%__MODULE__{parser: & &1}, opts)
  end

  defimpl ExAws.Operation do
    @type response_t :: %{} | ExAws.Request.error_t() | no_return

    alias ExAws.{Config, Operation.CloudSearch}

    @spec perform(CloudSearch.t(), Config.t()) :: response_t
    def perform(operation, config) do
      operation = handle_callbacks(operation, config)

      {operation, config} = handle_host_config(operation, config)

      {operation, data, headers} = prep_operation(operation)

      url = ExAws.Request.Url.build(operation, config)

      headers = [{"x-amz-content-sha256", ""} | headers]

      ExAws.Request.request(
        operation.http_method,
        url,
        data,
        headers,
        config,
        :cloudsearch
      )
      |> parse(config)
    end

    @spec stream!(CloudSearch.t(), Config.t()) :: no_return
    def stream!(_, _), do: raise(ArgumentError, "This operation does not support streaming!")

    @spec handle_callbacks(CloudSearch.t(), Config.t()) :: CloudSearch.t()
    defp handle_callbacks(%{before_request: nil} = op, _), do: op

    defp handle_callbacks(%{before_request: callback} = op, config), do: callback.(op, config)

    @spec handle_host_config(CloudSearch.t(), Config.t()) :: {CloudSearch.t(), Config.t()}
    defp handle_host_config(
           %{api_version: version, path: path, request_type: type, domain: domain} = operation,
           %{region: region} = config
         ) do
      {
        %{operation | path: "/#{version}/#{path}", service: :cloudsearch},
        %{config | host: "#{type}-#{domain}.#{region}.cloudsearch.amazonaws.com"}
      }
    end

    @spec prep_operation(CloudSearch.t()) :: {CloudSearch.t(), map | String.t(), list({String.t(), String.t()})}
    defp prep_operation(%{request_type: :search, http_method: :post} = op) do
      data = URI.encode_query(op.params)
      headers = [{"content-type", "application/x-www-form-urlencoded"} | op.headers]
      {Map.put(op, :params, %{}), data, headers}
    end

    defp prep_operation(%{data: data, headers: headers} = op), do: {op, data, headers}

    @spec parse({:ok, %{body: String.t()}} | {:error, any}, Config.t()) ::
            {:ok, map} | {:error, any} | no_return
    defp parse({:error, _} = result, _), do: result

    defp parse({:ok, %{body: ""}}, _), do: {:ok, %{}}

    defp parse({:ok, %{body: body}}, config) do
      {:ok, config[:json_codec].decode!(body)}
    end
  end
end
