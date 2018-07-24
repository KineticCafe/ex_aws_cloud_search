defmodule ExAws.CloudSearch do
  @moduledoc """
  Operations on AWS CloudSearch.
  """

  alias ExAws.Operation.CloudSearch, as: Operation

  @typedoc """
  The type of search expression definitions (`[name: "expression"]`, `%{name:
  "expression"}`, or `%{"name" => "expression"}`). Becomes
  `expr.name=expression`.
  """
  @type expr_option_value :: keyword(String.t()) | %{required(String.t() | atom) => String.t()}

  @typedoc "Facet field configuration."
  @type facet_config ::
          nil
          | String.t()
          | [
              {:sort, :bucket | :count},
              {:buckets, list(String.t() | struct)},
              {:size, non_neg_integer}
            ]
          | %{
              optional(:sort) => :bucket | :count,
              optional(:buckets) => list(String.t() | struct),
              optional(:size) => non_neg_integer
            }

  @typedoc "Field Facet definitions"
  @type facet_option_value ::
          list(String.t() | atom | {String.t() | atom, facet_config})
          | %{required(String.t() | atom) => facet_config}

  @typedoc "Field highlight configuration."
  @type highlight_config ::
          nil
          | String.t()
          | [
              {:format, :text | :html},
              {:max_phrases, non_neg_integer},
              {:pre_tag, String.t()},
              {:post_tag, String.t()}
            ]
          | %{
              optional(:format) => :text | :html,
              optional(:max_phrases) => non_neg_integer,
              optional(:pre_tag) => String.t(),
              optional(:post_tag) => String.t()
            }

  @typedoc "Field Highlight definitions"
  @type highlight_option_value ::
          list(String.t() | atom | {String.t() | atom, highlight_config})
          | %{required(String.t() | atom) => highlight_config}

  @typedoc "Query Parser Option Configuration"
  @type qoptions_config ::
          [
            {:defaultOperator, String.t()},
            {:fields, list(String.t())},
            {:operators, list(String.t())},
            {:phraseFields, list(String.t())},
            {:phraseSlop, non_neg_integer},
            {:explicitPhraseSlop, non_neg_integer},
            {:tieBreaker, float}
          ]
          | %{
              optional(:defaultOperator) => String.t(),
              optional(:fields) => list(String.t()),
              optional(:operators) => list(String.t()),
              optional(:phraseFields) => list(String.t()),
              optional(:phraseSlop) => non_neg_integer,
              optional(:explicitPhraseSlop) => non_neg_integer,
              optional(:tieBreaker) => float
            }

  @typedoc "Supported search options."
  @type search_options :: [
          {:cursor, :initial | String.t()},
          {:expr, expr_option_value},
          {:facet, facet_option_value},
          {:fq, String.t() | struct},
          {:highlight, highlight_option_value},
          {:partial, boolean},
          {:options, qoptions_config},
          {:qoptions, qoptions_config},
          {:parser, :simple | :structured | :lucene | :dismax},
          {:qparser, :simple | :structured | :lucene | :dismax},
          {:return, String.t() | list(String.t())},
          {:size, non_neg_integer},
          {:sort, list(String.t() | {String.t(), :asc | :desc})},
          {:start, non_neg_integer},
          {:page, non_neg_integer}
        ]
  @typedoc "Search terms."
  @type search_term :: String.t() | struct | map

  @doc """
  Create a search request for the provided terms.

  The first parameter is the search criteria for the request. How you specify
  the search criteria depends on the query parser used for the request and the
  parser options specified in the `options` parameter. By default, the `simple`
  query parser is used to process requests. To use the `structured`, `lucene`,
  or `dismax` query parser, you must also specify the `parser` parameter. For
  more information about specifying search criteria, see [Searching Your Data
  with Amazon CloudSearch][searching].

  If the [csquery][] is present, a `CSQuery.Expression` may be provided and the
  query parser will automatically be configured to use the `structured` query.

  ```
  search("fritters") |> ExAws.request!
  search(CSQuery.parse(and: ["fritters", type: "donuts"])) |> ExAws.request!
  ```

  ## Options

  ### `cursor`

  Retrieves a cursor value you can use to page through large result sets. Use
  the `size` parameter to control the number of hits you want to include in
  each response. You can specify either the `cursor` or `start` parameter in a
  request, they are mutually exclusive. For more information, see [Paginate the
  results][].

  To get the first cursor, specify `cursor: initial` in your initial request.
  In subsequent requests, specify the cursor value returned in the `hits`
  section of the response.

  For example, the following request sets the cursor value to initial and the
  size parameter to 20 to get the first set of hits. The cursor for the next
  set of hits is included in the response, as shown.

  ```
  cursor =
    "fritters"
    |> search("fritters", size: 20, cursor: :initial)
    |> ExAws.request!() |> get_in(~w(hits cursor))
  # => "VegKzpYYQW9JSVFFRU1UeWwwZERBd09EUTNPRGM9ZA"

  "fritters"
  |> search(size: 20, cursor: cursor)
  |> ExAws.request!()
  ```

  ### `expr`

  Defines expressions that can be used to sort results, or that may be
  specified in the `return` field. For more information about defining and
  using expressions, see [Configuring Expressions][].

  The `expr` option takes a map or keyword list, where the key is the name of
  the expression and the value is the expression itself. Multiple expressions
  may be defined and used in a search request.

  ```
  search(
    "fritters",
    expr: [expression1: "_score*rating"],
    sort: "-expression1",
    return: ~w(name rating _score expression1)
  )
  search(
    "fritters",
    expr: %{expression1: "_score*rating"},
    sort: "-expression1",
    return: ~w(name rating _score expression1)
  )
  ```

  ### `facet`

  Defines a facet request for a field, which must be facet enabled in the
  domain configuration. The `facet` option expects field names with optional
  configurations that can be converted into a JSON object.

  All of the examples below mean the same thing, `facet.rating={}` (an empty
  configuration):

  ```
  search("fritters", facet: ["rating"])
  search("fritters", facet: [rating: nil])
  search("fritters", facet: %{rating: %{}})
  search("fritters", facet: %{"rating" => "{}"})
  ```

  #### Facet Configuration

  If the facet configuration object is empty, `facet.FIELD={}`, facet counts
  are computed for all field values, the facets are sorted by facet count, and
  the top 10 facets are returned in the results.

  You can specify three options in the facet configuration:

  *   `sort` specifies how you want to sort the facets in the results: `:bucket`
      or `:count`. Specify `:bucket` to sort alphabetically or numerically by
      facet value (in ascending order). Specify `:count` to sort by the facet
      counts computed for each facet value (in descending order). To retrieve
      facet counts for particular values or ranges of values, use the `buckets`
      option instead of `sort`.

      The following sorts ratings into buckets:

      ```
      facet: [rating: [sort: :bucket]]
      ```

  *   `buckets` specifies an array of the facet values or ranges you want to
      count. Buckets are returned in the order they are specified in the
      request. To specify a range of values, use a comma (,) to separate the
      upper and lower bounds and enclose the range using brackets or braces. A
      square bracket, [ or ], indicates that the bound is included in the
      range, a curly brace, { or }, excludes the bound. You can omit the upper
      or lower bound to specify an open-ended range. When omitting a bound, you
      must use a curly brace. The `sort` and `size` options are not valid if
      you specify `buckets`.

      The following splits ratings into two buckets with ranges up to 3 and
      equal to or over 3:

      ```
      facet: [rating: [buckets: ["{,3}","[3,}"]]]
      ```

  *   `size` specifies the maximum number of facets to include in the results.
      By default, Amazon CloudSearch returns counts for the top 10. The `size`
      parameter is only valid when you specify the `sort` option; it cannot be
      used in conjunction with `buckets`.

      The following request gets facet counts for the `year` field, sorts the
      facet counts by value and returns counts for the top three:

      ```
      facet: [year: [sort: :bucket, size: 3]]
      ```

  To specify which values or range of values you want to calculate facet counts
  for, use the buckets option. For example, the following request calculates
  and returns the facet counts by decade:

  ```
  facet: [year: [buckets: [
    "[1970,1979]",
    "[1980,1989]",
    "[1990,1999]",
    "[2000,2009]",
    "[2010,}"
  ]]]
  ```

  You can also specify individual values as buckets:

  ```
  facet: [genres: [buckets: ["Action","Adventure","Sci-Fi"]]]
  ```

  Note that the facet values are case-sensitive—with the sample IMDb movie
  data, if you specify ["action","adventure","sci-fi"] instead of
  ["Action","Adventure","Sci-Fi"], all facet counts are zero.

  ### `fq`

  Specifies a structured query that filters the results of a search without
  affecting how the results are scored and sorted. You use `fq` in conjunction
  with the search term to filter the documents that match the constraints
  specified in the search term. Specifying a filter just controls which
  matching documents are included in the results, it has no effect on how they
  are scored and sorted. The `fq` parameter supports the full [structured query
  syntax][sss]. For more information about using filters, see [Filtering Matching
  Documents][fmd].

  As with the search term, a `CSQuery.Expression` may be provided and the query
  parser will produce the query string as long as [CSQuery][csquery] is loaded.

  ### `highlight`

  Retreives highlights for matches in the specified text or text-array field.
  The `highlight` option expects field names with optional configurations that
  can be converted into a JSON object.

  All of the examples below mean the same thing, `highlight.name={}` (an empty
  configuration):

  ```
  search("fritter", facet: ["name"])
  search("fritter", facet: [name: nil])
  search("fritter", facet: %{name: %{}})
  search("fritter", facet: %{"name" => "{}"})
  ```

  #### Highlight Configuration

  If the highlight configuration object is empty, `highlight.FIELD={}`, the
  returned field text is treated as HTML and the first match is highlighted
  with emphasis tags: &lt;em>search-term&lt;/em>.

  You can specify four options in the highlight configuration:

  *   `format` specifies the format of the data in the text field: `:text` or
      `:html`. When data is returned as HTML, all non-alphanumeric characters
      are encoded. The default is `:html`.
  *   `max_phrases` specifies the maximum number of occurrences of the search
      term(s) you want to highlight. By default, the first occurrence is
      highlighted.
  *   `pre_tag` specifies the string to prepend to an occurrence of a search
      term. The default for HTML highlights is `<em>`. The default for text
      highlights is `*`.
  *   `post_tag` specifies the string to append to an occurrence of a search
      term. The default for HTML highlights is `</em>`. The default for text
      highlights is `*`.

  #### Examples

  ```
  highlight: ["plot"]
  highlight: [plot: [format: :text, max_phrases: 2, pre_tag: "_", post_tag: "_"]]
  ```

  ### `partial`

  Controls whether partial results are returned if one or more index partitions
  are unavailable. When your search index is partitioned across multiple search
  instances, by default Amazon CloudSearch only returns results if every
  partition can be queried (`partial: false`). This means that the failure of a
  single search instance can result in 5xx (internal server) errors. When you
  specify `partial: true`, Amazon CloudSearch returns whatever results are
  available and includes the percentage of documents searched in the search
  results (`percent-searched`). This enables you to more gracefully degrade
  your users' search experience. For example, rather than displaying no
  results, you could display the partial results and a message indicating that
  the results might be incomplete due to a temporary system outage.

  ### `options` or `qoptions`

  (In the AWS CloudSearch documentation this is referred to as `q.options`.)

  Configure options for the query parser specified in the `parser` option. The
  options are specified as keyed object, for example:

  ```
  qoptions: [defaultOperator: "or", fields: ["title^5", "description"]]
  options: %{defaultOperator: "or", fields: ["title^5", "description"]}
  ```

  The options you can configure vary according to which parser you use:

  *   `defaultOperator`: The default operator used to combine individual terms
      in the search string. For example: `defaultOperator: "or"`. For the
      `dismax` parser, specify a percentage that represents the percentage of
      terms in the search string (rounded down) that must match, rather than a
      default operator. A value of 0% is the equivalent to OR, and a value of
      100% is equivalent to AND. The percentage must be specified as a value in
      the range 0-100 followed by the percent (%) symbol. For example,
      `defaultOperator: 50%`. Valid values: `and`, `or`, a percentage in the
      range 0%-100% (`dismax` parser only). Default: `and` (`simple`,
      `structured`, `lucene`) or `100%` (`dismax`). Valid for: `simple`,
      `structured`, `lucene`, and `dismax`.
  *   `fields`: An array of the fields to search when no fields are specified
      in a search. If no fields are specified in a search and this option is
      not specified, all statically configured text and text-array fields are
      searched. You can specify a weight for each field to control the relative
      importance of each field when Amazon CloudSearch calculates relevance
      scores. To specify a field weight, append a caret (`^`) symbol and the
      weight to the field name. For example, to boost the importance of the
      title field over the description field you could specify: `fields:
      ["title^5","description"]`. Valid values: The name of any configured
      field and an optional numeric value greater than zero. Default: All
      statically configured text and text-array fields. Dynamic fields and
      literal fields are not searched by default. Valid for: `simple`,
      `structured`, `lucene`, and `dismax`.
  *   `operators`: An array of the operators or special characters you want to
      disable for the `simple` query parser. If you disable the `and`, `or`, or
      `not` operators, the corresponding operators (`+`, `|`, `-`) have no
      special meaning and are dropped from the search string. Similarly,
      disabling `prefix` disables the wildcard operator (`*`) and disabling
      `phrase` disables the ability to search for phrases by enclosing phrases
      in double quotes. Disabling `precedence` disables the ability to control
      order of precedence using parentheses. Disabling `near` disables the
      ability to use the `~` operator to perform a sloppy phrase search.
      Disabling the `fuzzy` operator disables the ability to use the `~`
      operator to perform a fuzzy search. Disabling `escape` disables the
      ability to use a backslash (<code>\\</code>) to escape special characters
      within the search string. Disabling `whitespace` is an advanced option
      that prevents the parser from tokenizing on whitespace, which can be
      useful for Vietnamese. (It prevents Vietnamese words from being split
      incorrectly.) For example, you could disable all operators other than the
      phrase operator to support just simple term and phrase queries:
      `operators: ["and", "not", "or", "prefix"]`. Valid values: `and`,
      `escape`, `fuzzy`, `near`, `not`, `or`, `phrase`, `precedence`, `prefix`,
      `whitespace`. Default: All operators and special characters are enabled.
      Valid for: `simple`.
  *   `phraseFields`: An array of the text or text-array fields you want to use
      for phrase searches. When the terms in the search string appear in close
      proximity within a field, the field scores higher. You can specify a
      weight for each field to boost that score. The `phraseSlop` option
      controls how much the matches can deviate from the search string and
      still be boosted. To specify a field weight, append a caret (`^`) symbol
      and the weight to the field name. For example, to boost phrase matches in
      the title field over the abstract field, you could specify:
      `phraseFields: ["title^3", "abstract"]`. Valid values: The name of any
      text or text-array field and an optional numeric value greater than zero.
      Default: No fields. If you don't specify any fields with phraseFields,
      proximity scoring is disabled even if phraseSlop is specified. Valid for:
      `dismax`.
  *   `phraseSlop`: An integer value that specifies how much matches can
      deviate from the search phrase and still be boosted according to the
      weights specified in the `phraseFields` option. For example, `phraseSlop:
      2`. You must also specify `phraseFields` to enable proximity scoring.
      Valid values: positive integers. Default: 0. Valid for: `dismax`.
  *   `explicitPhraseSlop`: An integer value that specifies how much a match
      can deviate from the search phrase when the phrase is enclosed in double
      quotes in the search string. (Phrases that exceed this proximity distance
      are not considered a match.) `explicitPhraseSlop: 5`. Valid values:
      positive integers. Default: 0. Valid for: `dismax`.
  *   `tieBreaker`: When a term in the search string is found in a document's
      field, a score is calculated for that field based on how common the word
      is in that field compared to other documents. If the term occurs in
      multiple fields within a document, by default only the highest scoring
      field contributes to the document's overall score. You can specify a
      `tieBreaker` value to enable the matches in lower-scoring fields to
      contribute to the document's score. That way, if two documents have the
      same max field score for a particular term, the score for the document
      that has matches in more fields will be higher.

      The formula for calculating the score with a tieBreaker is `(max field
      score) + (tieBreaker) * (sum of the scores for the rest of the matching
      fields)`.

      For example, the following query searches for the term "dog" in the
      `title`, `description`, and `review` fields and sets `tieBreaker` to
      `0.1`:

      ```
      search(
        "dog",
        parser: :dismax,
        options: [fields: ~w(title description review), tieBreaker: 0.1]
      )
      ```

      If `dog` occurs in all three fields of a document and the scores for each
      field are `title=1`, `description=3`, and `review=1`, the overall score
      for the term `dog` is `3 + 0.1 * (1 + 1) = 3.2`.

      Set `tieBreaker` to 0 to disregard all but the highest scoring field
      (pure max). Set to `1` to sum the scores from all fields (pure sum).
      Valid values: 0.0 to 1.0. Default: 0.0. Valid for: `dismax`.

  ### `parser` or `qparser`

  (In the AWS CloudSearch documentation this is referred to as `q.parser`.)

  Specifies which query parser to use to process the request: `simple`,
  `structured`, `lucene`, and `dismax`. If `parser` is not specified, Amazon
  CloudSearch uses the `simple` query parser.

  *   `simple`: perform simple searches of text and text-array fields. By
      default, the `simple` query parser searches all statically configured
      text and text-array fields. You can specify which fields to search by
      with the `options` parameter. If you prefix a search term with a plus
      sign (`+`) documents must contain the term to be considered a match.
      (This is the default, unless you configure the default operator with the
      `options` parameter.) You can use the `-` (NOT), `|` (OR), and `*`
      (wildcard) operators to exclude particular terms, find results that match
      any of the specified terms, or search for a prefix. To search for a
      phrase rather than individual terms, enclose the phrase in double quotes.
      For more information, see [Searching Your Data with Amazon
      CloudSearch][earching].
  *   `structured`: perform advanced searches by combining multiple expressions
      to define the search criteria. You can also search within particular
      fields, search for values and ranges of values, and use advanced options
      such as term boosting, matchall, and near. For more information, see
      [Constructing Compound Queries][compound].
  *   `lucene`: search using the Apache Lucene query parser syntax. For more
      information, see [Apache Lucene Query Parser Syntax][lucene].
  *   `dismax`: search using the simplified subset of the Apache Lucene query
      parser syntax defined by the DisMax query parser. For more information,
      see [DisMax Query Parser Syntax][dismax].

  ### `return`

  The field and expression values to include in the response, specified as a
  list. By default, a search response includes all return enabled fields
  (`return: "_all_fields"`). To return only the document IDs for the matching
  documents, specify `return: "_no_fields"`. To retrieve the relevance score
  calculated for each document, specify `return: "_score"`. You specify
  multiple return fields as a comma separated list. For example, `return:
  ["title", "_score"]` returns just the `title` and relevance score of each
  matching document.

  ### `size`

  The maximum number of search hits to return (default 10).

  ### `sort`

  A list of fields or custom expressions to use to sort the search results. A
  maximum of ten sort fields or expressions may be specified (this is
  automatically enforced by ExAws.CloudSearch, by trimming sort expressions
  exceeding the first ten).

  CloudSearch requires that each field have its sort direction specified
  (`:asc` or `:desc`), but ExAws.CloudSearch provides multiple ways to do this.
  Both of these expressions result in the same behaviour: sort by year
  descending and title ascending.

  ```
  sort: ["-year", "title"]
  sort: [{"year", :desc}, {"title", :asc}]
  ```

  To use a field to sort results, it must be sort enabled in the domain
  configuration. Array type fields cannot be used for sorting. If no sort
  parameter is specified, results are sorted by their default relevance scores
  in descending order: `sort: {"_score", :desc}`. You can also sort by document
  ID (`sort: "_id"`) and version (`sort: "_version"`).

  ### `start` or `page`

  The offset of the first search hit you want to return. You can specify either
  the `start` or `cursor` parameter in a request, they are mutually exclusive.
  For more information, see [Paginate the results][].

  As a convenience option, `page` may be provided, which calculates the `start`
  based on the `size` parameter. If both `page` and `start` are specified,
  `page` is discarded.

  [Paginate the results]: https://docs.aws.amazon.com/cloudsearch/latest/developerguide/paginating-results.html
  [Configuring Expressions]: https://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html
  [sss]: https://docs.aws.amazon.com/cloudsearch/latest/developerguide/search-api.html#structured-search-syntax
  [fmd]: https://docs.aws.amazon.com/cloudsearch/latest/developerguide/filtering-results.html
  [csquery]: https://github.com/KineticCafe/csquery
  [searching]: https://docs.aws.amazon.com/cloudsearch/latest/developerguide/searching.html
  [compound]: https://docs.aws.amazon.com/cloudsearch/latest/developerguide/searching-compound-queries.html
  [lucene]: https://lucene.apache.org/solr/guide/6_6/the-standard-query-parser.html
  [dismax]: https://lucene.apache.org/solr/guide/6_6/the-dismax-query-parser.html
  """
  @spec search(search_term, search_options) :: Operation.t() | no_return
  def search(term, options) do
    %Operation{
      path: "/search",
      params: build_search_params(term, options),
      request_type: :search
    }
  end

  @spec build_search_params(search_term, search_options) :: map | no_return
  defp build_search_params(term, options) do
    options
    |> Enum.reduce([{"q", term}], &build_search_options/2)
    |> Enum.reject(&match?({_, v} when is_nil(v) or v == "", &1))
    |> Enum.reverse()
    |> Enum.into(%{})
    |> case do
      %{"page" => _, "start" => _} = params ->
        Map.delete(params, "page")

      %{"page" => page} = params ->
        params
        |> Map.put("start", round((page - 1) * Map.get(params, "size", 10)))
        |> Map.delete("page")

      params ->
        params
    end
  end

  @spec build_search_params(search_options, list) :: list | no_return
  defp build_search_options({:cursor, cursor}, params), do: [{"cursor", cursor} | params]

  defp build_search_options({:expr, expressions}, params) do
    Enum.reduce(expressions, params, fn {name, expr}, params ->
      [{"expr.#{name}", expr} | params]
    end)
  end

  defp build_search_options({:facet, facets}, params) do
    Enum.reduce(facets, params, &build_named_json_option("facet", &1, &2))
  end

  defp build_search_options({:fq, fq}, params), do: [{"fq", fq} | params]

  defp build_search_options({:highlight, highlights}, params) do
    Enum.reduce(highlights, params, &build_named_json_option("highlight", &1, &2))
  end

  defp build_search_options({name, qoptions}, params) when name in ~w(options qoptions)a do
    qoptions =
      case qoptions do
        nil -> "{}"
        value when is_binary(value) -> value
        value when is_map(value) -> {:json, value}
        value when is_list(value) -> {:json, Enum.into(value, %{})}
      end

    [{"q.options", qoptions} | params]
  end

  defp build_search_options({name, qparser}, params) when name in ~w(parser qparser) do
    [{"q.parser", qparser} | params]
  end

  defp build_search_options({:partial, partial}, params) do
    [{"partial", !!partial} | params]
  end

  defp build_search_options({:return, fields}, params) do
    fields =
      fields
      |> List.wrap()
      |> Enum.reject(&(&1 == "_id"))
      |> Enum.join(",")

    [{"return", fields} | params]
  end

  defp build_search_options({:size, size}, params), do: [{"size", to_integer(size)} | params]

  defp build_search_options({:sort, sort}, params) do
    {sort, _} = Enum.split(List.wrap(sort), 10)

    sort =
      sort
      |> Enum.map(&normalize_sort/1)
      |> Enum.join(",")

    [{"sort", sort} | params]
  end

  defp build_search_options({:start, start}, params) do
    [{"start", to_integer(start)} | params]
  end

  defp build_search_options({:page, page}, params) do
    [{"page", to_integer(page)} | params]
  end

  defp build_search_options(_options, params), do: params

  @spec build_named_json_option(
          String.t(),
          String.t() | {String.t(), nil | String.t() | map | keyword},
          list
        ) :: list
  defp build_named_json_option(type, {name, nil}, params),
    do: [{"#{type}.#{name}", "{}"} | params]

  defp build_named_json_option(type, {name, value}, params) when is_binary(value) do
    [{"#{type}.#{name}", value} | params]
  end

  defp build_named_json_option(type, {name, value}, params) when is_map(value) do
    [{"#{type}.#{name}", {:json, value}} | params]
  end

  defp build_named_json_option(type, {name, value}, params) when is_list(value) do
    [{"#{type}.#{name}", {:json, Enum.into(value, %{})}} | params]
  end

  defp build_named_json_option(type, name, params), do: [{"#{type}.#{name}", "{}"} | params]

  defp to_integer(value) when is_number(value), do: round(value)

  defp to_integer(value) when is_binary(value), do: String.to_integer(value)

  defp to_integer(value), do: to_integer(to_string(value))

  defp normalize_sort("-" <> field), do: normalize_sort({field, :desc})

  defp normalize_sort(field) when is_binary(field), do: normalize_sort({field, :asc})

  defp normalize_sort({field, direction}) when direction in ~w(asc desc),
    do: "#{field} #{direction}"
end
