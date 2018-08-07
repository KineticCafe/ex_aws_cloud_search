defmodule ExAws.CloudSearch.Config do
  @moduledoc """
  CloudSearch configuration operations. These are intentionally undocumented
  with this version. Use them at your own risk (but they appear to work with
  limited testing).
  """

  alias ExAws.Operation.CloudSearch, as: Operation

  def index_documents(domain_name, options \\ []) do
    request(:index_documents, domain_name, %{}, options)
  end

  def build_suggesters(domain_name, options \\ []) do
    request(:build_suggesters, domain_name, %{}, options)
  end

  def define_suggester(domain_name, suggester, options \\ []) do
    request(:define_suggester, domain_name, %{"Suggester" => suggester}, options)
  end

  def delete_suggester(domain_name, name, options \\ []) do
    request(:delete_suggester, domain_name, %{"SuggesterName" => name}, options)
  end

  def describe_suggesters(domain_name, options \\ []) do
    request(
      :describe_suggesters,
      domain_name,
      Map.merge(%{"Deployed" => deployed?(options)}, names("SuggesterNames", options)),
      post!(options)
    )
  end

  def create_domain(domain_name, options \\ []) do
    request(:create_domain, domain_name, %{}, options)
  end

  def delete_domain(domain_name, options \\ []) do
    request(:delete_domain, domain_name, %{}, options)
  end

  def describe_domains(options \\ []) do
    request(:describe_domains, nil, names("DomainNames", options), post!(options))
  end

  def list_domain_names(options \\ []) do
    request(:list_domain_names, nil, %{}, options)
  end

  def define_analysis_scheme(domain_name, scheme, options \\ []) do
    request(:define_analysis_scheme, domain_name, %{"AnalysisScheme" => scheme}, options)
  end

  def delete_analysis_scheme(domain_name, name, options \\ []) do
    request(:delete_analysis_scheme, domain_name, %{"AnalysisSchemeName" => name}, options)
  end

  def describe_analysis_schemes(domain_name, options \\ []) do
    request(
      :describe_analysis_schemes,
      domain_name,
      Map.merge(%{"Deployed" => deployed?(options)}, names("AnalysisSchemeNames", options)),
      post!(options)
    )
  end

  def describe_availability_options(domain_name, options \\ []) do
    request(
      :describe_availability_options,
      domain_name,
      %{"Deployed" => deployed?(options)},
      options
    )
  end

  def update_availability_options(domain_name, multi_az, options \\ []) do
    request(:update_availability_options, domain_name, %{"MultiAZ" => !!multi_az}, post!(options))
  end

  def describe_scaling_parameters(domain_name, options \\ []) do
    request(:describe_scaling_parameters, domain_name, %{}, options)
  end

  def update_scaling_parameters(domain_name, scaling, options \\ []) do
    request(
      :update_scaling_parameters,
      domain_name,
      %{"ScalingParameters" => scaling},
      post!(options)
    )
  end

  def describe_service_access_policies(domain_name, options \\ []) do
    request(
      :describe_service_access_policies,
      domain_name,
      %{"Deployed" => deployed?(options)},
      options
    )
  end

  def update_service_access_policies(domain_name, policies, options \\ []) do
    request(
      :update_service_access_policies,
      domain_name,
      %{"AccessPolicies" => policies},
      post!(options)
    )
  end

  def define_expression(domain_name, name, value, options \\ []) do
    request(
      :define_expression,
      domain_name,
      %{"Expression" => %{"ExpressionName" => name, "ExpressionValue" => value}},
      options
    )
  end

  def delete_expression(domain_name, name, options \\ []) do
    request(:delete_expression, domain_name, %{"ExpressionName" => name}, options)
  end

  def describe_expressions(domain_name, options \\ []) do
    request(
      :describe_expressions,
      domain_name,
      Map.merge(%{"Deployed" => deployed?(options)}, names("ExpressionNames", options)),
      post!(options)
    )
  end

  def define_index_field(domain_name, index_field, options \\ []) do
    request(:define_index_field, domain_name, %{"IndexField" => index_field}, options)
  end

  def delete_index_field(domain_name, name, options \\ []) do
    request(:delete_index_field, domain_name, %{"IndexFieldName" => name}, options)
  end

  def describe_index_fields(domain_name, options \\ []) do
    request(
      :describe_index_fields,
      domain_name,
      Map.merge(%{"Deployed" => deployed?(options)}, names("FieldNames", options)),
      post!(options)
    )
  end

  defp request(action, domain_name, params, options) do
    %Operation{
      http_method: Keyword.get(options, :http_method, :get),
      request_type: :config,
      #     action: action,
      path: Keyword.get(options, :path, "/"),
      params: params(action, domain_name, params, options)
    }
  end

  defp params(action, domain_name, params, options) do
    params
    |> Map.merge(%{
      "Action" => Macro.camelize(Atom.to_string(action)),
      "DomainName" => domain_name,
      "Version" => Keyword.get(options, :api_version, "2013-01-01")
    })
    |> Enum.reject(&empty?/1)
    |> Enum.into(%{})
  end

  defp empty?({_, nil}), do: true

  defp empty?({_, []}), do: true

  defp empty?({_, ""}), do: true

  defp empty?(_), do: false

  defp post!(list) do
    list
    |> Keyword.delete(:http_method)
    |> Keyword.put(:http_method, :post)
  end

  defp deployed?(list), do: Keyword.get(list, :deployed)

  defp names(base, list) do
    list
    |> Keyword.get(:names)
    |> List.wrap()
    |> Enum.with_index(1)
    |> Enum.map(fn {name, index} -> {"#{base}.member.#{index}", name} end)
    |> Enum.into(%{})
  end
end
