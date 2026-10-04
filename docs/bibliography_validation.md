# Bibliography validation

Checked October 4, 2026. Scope: every entry in every `.bib` file in this repository;
there is one file, `ms/references.bib`, containing 12 entries. Uncited entries were
included. Author order, title, year/version, publication type, venue, volume/issue,
pages where supplied by the source, and DOI or repository URL were checked against
publisher records, publisher-deposited Crossref metadata, official citation files,
or the identified manuscript version. A resolving DOI alone was not treated as
proof that the citation matched.

| Entry | Verification source | Result |
| --- | --- | --- |
| `sood2024holier` | [Publisher-deposited DOI metadata](https://api.crossref.org/works/10.51685/jqd.2024.011) | Replaced the incomplete 2023 draft entry with the published 2024 article: Sood then Shen; revised title; Journal of Quantitative Description: Digital Media, volume 4; DOI added. The registry supplies no page range, so none was invented. |
| `chintalapati2026piedomains` | [Official CITATION.cff](https://github.com/themains/piedomains/blob/main/CITATION.cff) | Matched the recommended software citation: Chintalapati and Sood, version 0.14.0, released August 17, 2026. Replaced the unspecific 2022 entry, retained the verified title, and recorded the version. |
| `laohaprapanon2020domain` | [Original manuscript commit](https://github.com/themains/domain_knowledge/blob/850644c06d19a3d787a444443472367dd1bd3046/ms/domain_knowledge.tex) | Title and author order match the source. June 14, 2020 is the original commit's date; the note now explicitly describes a manuscript version, not a journal publication. |
| `vaz2019quantification` | [JMLR record](https://www.jmlr.org/papers/v20/18-456.html) | Authors, title, 2019, volume 20, article 79, and pages 1–33 match. No DOI added without a source. |
| `sood2026fewlab` | Local `fewlab` commit `e360f6542c0e97c6b8819da6c17d5e08c1543762`, `ms/few.tex`; [companion repository](https://github.com/finite-sample/fewlab) | Title and author verified directly in the committed manuscript; commit dated August 21, 2026. Marked explicitly as an unpublished working manuscript. The repository URL identifies the companion project; it is not asserted to expose that exact local manuscript revision. |
| `fong2021predictions` | [Cambridge article](https://www.cambridge.org/core/journals/political-analysis/article/abs/machine-learning-predictions-as-regression-covariates/462A74A46A97C20A17CF640BDA72B826), [DOI metadata](https://api.crossref.org/works/10.1017/pan.2020.38) | Authors, title, Political Analysis 29(4), pages 467–484, and DOI match. Retained the 2021 issue year; November 2020 is the online-first date. |
| `stark2008audits` | [DOI metadata](https://api.crossref.org/works/10.1214/08-AOAS161), [author's journal-version record](https://arxiv.org/abs/0807.4005) | Author, title, 2008, Annals of Applied Statistics 2(2), pages 550–581, and DOI match. The journal-version record supplies the pages omitted by Crossref. |
| `shekhar2023audits` | [Official PMLR citation](https://proceedings.mlr.press/v216/shekhar23a.html) | All five authors, title, UAI 2023 proceedings, PMLR volume 216, and pages 1932–1941 match. |
| `hoeffding1963` | [Publisher-deposited DOI metadata](https://api.crossref.org/works/10.1080/01621459.1963.10500830) | Author, title, JASA 58(301), pages 13–30, and DOI match. Retained original print year 1963; the 2012 online date is retrospective digitization. |
| `adao2019` | [DOI metadata](https://api.crossref.org/works/10.1093/qje/qjz025), [Oxford issue](https://academic.oup.com/qje/issue/134/4) | All authors and diacritics, title, QJE 134(4), pages 1949–2010, year, and DOI match. The publisher's trailing title asterisk is a footnote marker and is omitted. |
| `egami2023` | [Official proceedings BibTeX](https://proceedings.neurips.cc/paper_files/paper/2023/file/d862f7f5445255090de13b825b880d59-Bibtex-Conference.bib) | Authors, title, volume 36, and 2023 match. Added missing pages 68589–68601, publisher, and DOI 10.52202/075280-3000 from the official record. |
| `kim2019` | [DOI metadata](https://api.crossref.org/works/10.1145/3306618.3314287), [author's paper](https://www.cs.cornell.edu/~mpkim/pubs/multiaccuracy.pdf) | All authors, main title and subtitle, 2019 AIES proceedings, pages 247–254, and DOI match. Crossref stores the subtitle separately; the citation includes both. |

`make bibliography` uses the standard BibTeX parser with `\citation{*}` to check
all entries, including uncited ones. It fails on BibTeX warnings or errors, and
`make check` includes it. The manuscript build also checks that cited keys resolve.
This local check validates syntax and required fields; the source-based metadata
review above is separate and dated. Future bibliographic edits need renewed source
checks. No network call is required to reproduce the analyses or build the paper.
