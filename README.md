# ExAws.CloudSearch

[![Build Status][build_status_svg]][build status]

An [ex_aws][] service module for AWS [CloudSearch][].

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

## CSQuery Integration

During search construction, if a `CSQuery.Expression` is provided as the query,
`ExAws.CloudSearch` will also configure the query parser to be structured and
it will use `CSQuery.to_query/1` to produce the query string. (If `CSQuery` is
not loaded, an error will be thrown.)

## Community and Contributing

We welcome your contributions, as described in [Contributing.md][]. Like all
Kinetic Cafe [open source projects][], is under the Kinetic Cafe Open Source
[Code of Conduct][kccoc].

[ex_aws]: https://github.com/ex-aws
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
