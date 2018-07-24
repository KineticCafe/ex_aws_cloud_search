defmodule ExAws.CloudSearch.QueryParser do
  @moduledoc """
  A wrapper for query parsers. The base case is that the query is a string, in
  which case the query is passed through unmodified.
  """

  @type query_mode :: nil | :simple | :structured | :lucene | :dismax

  @doc """
  Attempt to parse the query provided. If the parser sets a particular mode,
  that value will be returned with the query; otherwise the query mode will be
  `nil`, indicating that the parser cannot determine the type of query.
  """
  @spec parse(nil | String.t() | struct) :: {String.t(), query_mode} | no_return
  def parse(query)

  def parse(nil), do: {nil, nil}

  def parse(query) when is_binary(query), do: {query, nil}

  if Code.ensure_loaded?(CSQuery.Expression) do
    def parse(%CSQuery.Expression{} = query),
      do: {CSQuery.Expression.to_query(query), :structured}
  end

  def parse(%mod{}) when is_atom(mod), do: missing_query_parser(mod)

  defp missing_query_parser(type) do
    raise ExAws.Error, "Missing CloudSearch query parser for type #{type}. Please see docs."
  end
end
