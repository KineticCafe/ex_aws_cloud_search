# Changelog

## 0.3.0 / 2022-MM-DD

- @thawk55 fixed an error with the `parser`/`qparser` search option builder in
  [#3][].

- Cleaned up a couple of warnings that show up on modern versions of Elixir.

## 0.2.0 / 2018-08-07

- Add `ExAws.CloudSearch.Config` functions to hit the CloudSearch config API.
  All of the APIs have been written to the specification of the CloudSearch
  documentation, but only a few have been meaningfully tested. They may not
  work.

- Add `ExAws.CloudSearch.Document` functions to add and remove documents from
  the index. These have been tested live and should work.

- Add `ExAws.CloudSearch.suggest/{2,3}` for suggestion queries.

## 0.1.1 / 2018-07-31

- Search options are supposed to be optional. Provided a default for
  `ExAws.CloudSearch.search/2`, making it `ExAws.CloudSearch.search/{1,2}`.

## 0.1.0 / 2018-07-24

- Initial release with basic search support.

[#3]: https://github.com/KineticCafe/ex_aws_cloud_search/pulls/3
