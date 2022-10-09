defmodule ExAws.CloudSearch.Document do
  @moduledoc """
  Operations to add and remove documents from a CloudSearch domain index.
  """

  alias ExAws.Operation.CloudSearch, as: Operation

  @typedoc """
  Field values may be strings (`text`, `literal`, `latlon`, `date`), lists of
  strings (`text-array`, `literal-array`, `date-array`), numbers (`int`,
  `double`), or lists of numbers (`int-array`, `double-array`). Empty or `nil`
  values are not permitted.
  """
  @type field_value :: String.t() | list(String.t()) | number | list(number)

  @typedoc """
  Fields are maps of field names (which must be strings matching the pattern
  `[a-zA-Z0-9][a-zA-Z0-9_]{0,63}`) with field values. At least one field/value
  pair must be provided.
  """
  @type fields :: %{required(String.t() | atom) => field_value}

  @type add :: %{type: :add, id: String.t(), fields: fields}
  @type delete :: %{type: :delete, id: String.t()}

  @type document :: add | delete
  @type batch :: list(document)

  @type request :: %Operation{
          params: batch,
          request_type: :doc
        }

  @doc """
  Adds the provided document(s) to the index. Note that nothing in this
  function prevents a request from being too large to process in CloudSearch
  (batches may be at most 5Mb, with each document being at most 1Mb).

  Documents may be added in several ways:

      add(%Band{id: 3, name: "Grimes"})
      add(%{id: 3, name: "Grimes"})
      add(%{"id" => 3, "name" => "Grimes"})
      add(%{3 => %{"name" => "Grimes"}})
      add({3, %{"name" => "Grimes"}})
      add([%Band{id: 3, name: "Grimes"}])
      add([%{id: 3, name: "Grimes"}])
      add([%{"id" => 3, "name" => "Grimes"}])
      add([%{3 => %{"name" => "Grimes"}}])
      add([{3, %{name: "Grimes"}}])

  However the document is provided, it must have an ID and the list of fields.
  The list of fields *must* match the document as defined in the index field
  configuration in CloudSearch (or the document upload will fail at least for
  that document).

  The ID will be converted to a string with `to_string/1`. Fields may not be
  `nil` or empty (`""` or `[]`), so those will be removed.
  """
  def add(%_mod{} = document) do
    add(add_normalize(document))
  end

  def add(%{id: _} = document) do
    add(add_normalize(document))
  end

  def add(%{"id" => _} = document) do
    add(add_normalize(document))
  end

  def add(documents) when is_map(documents) do
    add(Enum.into(documents, []))
  end

  def add({_id, _fields} = document) do
    add([document])
  end

  def add([]) do
    raise(ExAws.Error, "Must provide documents to index.")
  end

  def add(documents) when is_list(documents) do
    documents
    |> Enum.map(&add_normalize/1)
    |> Enum.map(&to_add_request/1)
    |> request()
  end

  @doc """
  Removes the provided document(s) by ID from the index.

      remove(%Band{id: 3})
      remove(%{id: 3})
      remove(%{"id" => 3})
      remove(3)
      remove([%Band{id: 3}])
      remove([%{id: 3}])
      remove([%{"id" => 3}])
      remove([3])
  """
  def remove(%_mod{} = document) do
    remove(remove_normalize(document))
  end

  def remove(%{id: _} = document) do
    remove(remove_normalize(document))
  end

  def remove(%{"id" => _} = document) do
    remove(remove_normalize(document))
  end

  def remove([]) do
    raise(ExAws.Error, "Must provide documents to remove.")
  end

  def remove(documents) when is_list(documents) do
    documents
    |> Enum.flat_map(&remove_normalize/1)
    |> Enum.map(&to_remove_request/1)
    |> request()
  end

  def remove(document) do
    remove(remove_normalize(document))
  end

  defp add_normalize(%_mod{id: _} = document) do
    add_normalize(Map.from_struct(document))
  end

  defp add_normalize(%mod{}) do
    raise ExAws.Error,
          "Cannot add a document directly from struct #{mod}; it does not have an id field."
  end

  defp add_normalize(%{id: id} = document) do
    add_normalize({id, Map.delete(document, :id)})
  end

  defp add_normalize(%{"id" => id} = document) do
    add_normalize({id, Map.delete(document, "id")})
  end

  defp add_normalize(%{}) do
    raise ExAws.Error,
          "Cannot add a document from a map that does not have an id field."
  end

  defp add_normalize({id, fields}) when is_map(fields) do
    if Enum.empty?(fields) do
      raise ExAws.Error, "At least one field must be specified for document #{id}."
    else
      {to_string(id), fields}
    end
  end

  defp add_normalize({id, _}) do
    raise ExAws.Error, "Cannot add document #{id} because it does not have a map for fields."
  end

  defp remove_normalize(%_mod{id: id}) do
    [id]
  end

  defp remove_normalize(%{id: id}) do
    [id]
  end

  defp remove_normalize(%{"id" => id}) do
    [id]
  end

  defp remove_normalize(%mod{}) do
    raise(
      ExAws.Error,
      "Cannot remove a document of struct #{mod}; it does not have an id field."
    )
  end

  defp remove_normalize(%{}) do
    raise(
      ExAws.Error,
      "Cannot find an id field in the provided map to remove this document."
    )
  end

  defp remove_normalize(id) do
    List.wrap(id)
  end

  defp to_add_request({id, fields}) do
    %{type: :add, id: to_string(id), fields: add_normalize_fields(fields)}
  end

  defp to_remove_request(id) do
    %{type: :delete, id: to_string(id)}
  end

  defp add_normalize_fields(%{} = fields) do
    fields
    |> Enum.map(&add_normalize_field/1)
    |> Enum.filter(&elem(&1, 1))
    |> Enum.into(%{})
  end

  defp add_normalize_field({key, %Date{} = value}) do
    {key, "#{Date.to_iso8601(value)}T00:00:00Z"}
  end

  defp add_normalize_field({key, %Time{}}) do
    raise ExAws.Error, "Cannot add a Time as a document field for #{key}."
  end

  defp add_normalize_field({key, %DateTime{} = value}) do
    {key, DateTime.to_iso8601(value)}
  end

  defp add_normalize_field({key, []}) do
    {key, nil}
  end

  defp add_normalize_field({key, ""}) do
    {key, nil}
  end

  defp add_normalize_field(pair) do
    pair
  end

  defp request(batch) do
    %Operation{
      path: "/documents/batch",
      data: List.wrap(batch),
      request_type: :doc
    }
  end
end
