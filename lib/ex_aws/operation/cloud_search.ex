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

  Note: ExAws.CloudSearch only supports version 2013-01-01.
  """

  defstruct stream_builder: nil,
            service: :cloudsearch,
            http_method: :post,
            parser: nil,
            path: "/",
            data: %{},
            params: %{},
            headers: [],
            before_request: nil,
            api_version: "2013-01-01",
            request_type: :search

  @type t :: %__MODULE__{
          stream_builder: nil | (ExAws.Config.t() -> ExAws.Config.t()),
          service: :cloudsearch,
          http_method: :get | :post | :put | :patch | :head | :delete,
          parser: nil | fun(),
          path: String.t(),
          data: map,
          params: map,
          headers: list({String.t(), String.t()}),
          before_request: nil | (t, ExAws.Config.t() -> t),
          api_version: String.t(),
          request_type: :config | :doc | :search
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
      operation = handle_before(operation, config)
      {operation, config} = configure_host(operation, config)
      {operation, data, headers} = prepare_request(operation, config)

      url = ExAws.Request.Url.build(operation, config)

      headers = [{"accept", "application/json"}, {"x-amz-content-sha256", ""} | headers]

      operation.http_method
      |> ExAws.Request.request(url, data, headers, config, :cloudsearch)
      |> parse_response(config)
    end

    @spec stream!(CloudSearch.t(), Config.t()) :: no_return
    def stream!(_, _), do: raise(ArgumentError, "This operation does not support streaming!")

    @spec handle_before(CloudSearch.t(), Config.t()) :: CloudSearch.t()
    defp handle_before(%{before_request: nil} = op, _), do: op

    defp handle_before(%{before_request: callback} = op, config), do: callback.(op, config)

    @spec configure_host(CloudSearch.t(), Config.t()) :: {CloudSearch.t(), Config.t()}
    defp configure_host(
           %{api_version: version, request_type: :config} = operation,
           %{region: region} = config
         ) do
      verify_version(version)
      {operation, %{config | host: "cloudsearch.#{region}.amazonaws.com"}}
    end

    defp configure_host(
           %{api_version: version, path: path, request_type: type} = operation,
           %{region: region, search_domain: domain} = config
         ) do
      verify_version(version)

      {
        %{operation | path: "/#{version}/#{path}", service: :cloudsearch},
        %{config | host: "#{type}-#{domain}.#{region}.cloudsearch.amazonaws.com"}
      }
    end

    @spec prepare_request(CloudSearch.t(), Config.t()) ::
            {CloudSearch.t(), map | String.t(), list({String.t(), String.t()})}

    defp prepare_request(%{request_type: :search, http_method: :post} = op, config) do
      data =
        op
        |> parse_search_query(config)
        |> URI.encode_query()

      headers = [{"content-type", "application/x-www-form-urlencoded"} | op.headers]
      {Map.put(op, :params, %{}), data, headers}
    end

    defp prepare_request(%{request_type: :search} = op, config) do
      {Map.put(op, :params, parse_search_query(op, config)), %{}, op.headers}
    end

    defp prepare_request(%{data: data, headers: headers, request_type: :doc} = op, _config) do
      {op, data, [{"content-type", "application/json"} | headers]}
    end

    defp prepare_request(%{request_type: :config, http_method: :post} = op, _config) do
      data = URI.encode_query(op.params)
      headers = [{"content-type", "application/x-www-form-urlencoded"} | op.headers]
      {Map.put(op, :params, %{}), data, headers}
    end

    defp prepare_request(%{data: data, headers: headers} = op, _config), do: {op, data, headers}

    @spec parse_response({:ok, %{body: String.t()}} | {:error, any}, Config.t()) ::
            {:ok, map} | {:error, any} | no_return
    defp parse_response({:error, _} = result, _), do: result

    defp parse_response({:ok, %{body: ""}}, _), do: {:ok, %{}}

    defp parse_response({:ok, %{body: body}}, config) do
      {:ok, config[:json_codec].decode!(body)}
    end

    @spec parse_search_query(map, Config.t()) :: map
    defp parse_search_query(%{params: %{} = params}, config) do
      {query, parser} =
        params
        |> Map.get_lazy("q", fn -> Map.fetch!(params, :q) end)
        |> ExAws.CloudSearch.QueryParser.parse()

      {fq, _} =
        params
        |> Map.get("fq", Map.get(params, :fq))
        |> ExAws.CloudSearch.QueryParser.parse()

      params
      |> put_param(:"q.parser", parser)
      |> put_param(:fq, fq)
      |> put_param(:q, query)
      |> Enum.reduce(%{}, &convert_json_params(config, &1, &2))
    end

    @spec convert_json_params(Config.t(), {String.t() | atom, String.t() | {:json, map}}, map) ::
            map
    defp convert_json_params(config, {key, {:json, value}}, params) do
      Map.put(params, key, config[:json_codec].encode!(value))
    end

    defp convert_json_params(_config, {key, value}, params), do: Map.put(params, key, value)

    @spec put_param(map, atom, any) :: map
    defp put_param(params, _, nil), do: params

    defp put_param(params, name, value) when is_atom(name) do
      params
      |> Map.put(to_string(name), value)
      |> Map.delete(name)
    end

    defp verify_version("2013-01-01"), do: nil

    defp verify_version(version),
      do: raise(ExAws.Error, "Unsupported CloudSearch API version #{version}")
  end
end
