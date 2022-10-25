defmodule ExAws.CloudSearch.IndexField do
  @moduledoc """
  An index field definition for CloudSearch.
  """

  defmodule Options do
    @moduledoc """
    Options for a CloudSearch index field.

    - `scheme`: The name of an analysis scheme. Used only for fields of type
      `text` or `text-array`.
    - `default`: The value to use if not specified.
    - `facet`: If true, facet information can be returned from the field.
    - `highlight`: If true, highlights can be returned from the field.
    - `return`: If true, the contents may be returned in search results.
    - `search`: If true, the contents are searchable.
    - `sort`: If true, the contents are usable for sort.
    - `source`: A source field name or a list of source field names that
      are mapped to the field.
    """
    @type t :: %__MODULE__{
            scheme: nil | String.t(),
            default: nil | String.t(),
            facet: boolean,
            highlight: boolean,
            return: boolean,
            search: boolean,
            sort: boolean,
            source: nil | String.t() | list(String.t())
          }

    defstruct [
      :scheme,
      :default,
      :source,
      facet: true,
      highlight: true,
      return: true,
      search: true,
      sort: true
    ]
  end

  @typedoc """
  Permitted CloudSearch index field types.
  """
  @type types ::
          :date
          | :double
          | :int
          | :latlon
          | :literal
          | :text
          | {:array, :date}
          | {:array, :double}
          | {:array, :int}
          | {:array, :literal}
          | {:array, :text}

  @type t :: %__MODULE__{
          name: String.t(),
          type: types,
          options: nil | Options.t()
        }

  @enforce_keys [:name, :type]

  defstruct [
    :name,
    :type,
    :options
  ]
end
