# ExAws.CloudSearch

[![Build Status][build status svg]][build status]

An [ex\_aws][] service module for AWS [CloudSearch][].

## Installation

The package can be installed by adding `ex_aws_cloud_search` to your list of
dependencies in `mix.exs` along with `:ex_aws_cloud_search` and your preferred
JSON codec and HTTP client.

If you are using the [structured search syntax][sss], you may wish to use
[csquery][].

```elixir
def deps do
  [
    {:ex_aws, "~> 2.0"},
    {:ex_aws_s3, "~> 1.0"},
    {:poison, "~> 3.0"},
    {:hackney, "~> 1.9"},
    {:csquery, "~> 1.0"} # Optional, but recommended.
  ]
end
```

Documentation can be found at [HexDocs.pm][].

## Configuration

The request configuration for `ExAws.CloudSearch` is a little different than
most other AWS services, in that it requires an additional configuration
parameter to know what host to use for document management or searches. When
configuring, add a `search_domain` configuration.

```elixir
config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, {:aws_profile, "default", 30}],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, {:aws_profile, "default", 30}],
  region: "us-west-2",
  search_domain: "exaws-search-test-d3adbeef65rvt"
```

The actual host will be chosen based on the `search_domain` provided. As with
all `ExAws` requests, this may be provided a runtime:

```elixir
"José"
|> ExAws.CloudSearch.search()
|> ExAws.request!(region: "us-west-2", search_domain: "exaws-search-test-d3adbeef65rvt")
```

## CSQuery Integration

During search construction, if a `CSQuery.Expression` is provided as the query,
`ExAws.CloudSearch` will also configure the query parser to be structured and
it will use `CSQuery.to_query/1` to produce the query string. (If `CSQuery` is
not loaded, an error will be thrown.)

## Planned Features

- [x] Search - v0.1.0
- [x] Suggest - v0.2.0
- [x] Document management (add/update, delete) - v0.2.0
- [x] Configuration - v0.2.0
- [ ] Improved configuration hygiene by providing more helper structs and
  functions.
- [ ] Tests (I know, I know) - v1.0.0

## Community and Contributing

We welcome your contributions, as described in [Contributing.md][]. Like all
Kinetic Cafe [open source projects][], is under the Kinetic Cafe Open Source
[Code of Conduct][kccoc].

[ex\_aws]: https://github.com/ex-aws
[HexDocs.pm]: https://hexdocs.pm/ex_aws_cloud_search
[build status svg]: https://travis-ci.org/KineticCafe/csquery.svg?branch=master
[build status]: https://travis-ci.org/KineticCafe/csquery
[Hex.pm]: https://hex.pm
[Contributing.md]: Contributing.md
[open source projects]: https://github.com/KineticCafe
[kccoc]: https://github.com/KineticCafe/code-of-conduct
[CloudSearch]: https://docs.aws.amazon.com/cloudsearch/
[sss]: https://docs.aws.amazon.com/cloudsearch/latest/developerguide/search-api.html#structured-search-syntax
[csquery]: https://github.com/KineticCafe/csquery
