# Bundled research data

## Fixed browsing benchmark

The three bundled files reproduce the fewlab extract at original local commit
`e360f6542c0e97c6b8819da6c17d5e08c1543762`, byte-for-byte. That original snapshot
was not available from GitHub when checked. The author authorized redistribution
in this package on October 4, 2026; reproduction uses these bundled files and
does not require access to the original branch or another repository.
`manifest.csv` records SHA-256 hashes and the source commit.
`Rscript scripts/verify_data.R` checks file integrity.
The source repository's license is retained in `SOURCE_LICENSE`.

The extract contains 1,132 pseudonymized users, 34,078 domains with recorded
Blacklight scanner results, and 103,853 user-domain records. Source provenance
is the June 2022 YouGov Pulse/RealityMine panel and associated Blacklight scans:
Harvard Dataverse DOI 10.7910/DVN/VIV4TS and DOI 10.7910/DVN/3N7TDZ. Consult the
upstream extract documentation for construction from those source releases.
This package starts from the pinned local extract; it does not claim to
reproduce its construction or its scanner measurements.

- `visits.csv.gz`: user, entity, visits, duration. Analyses use visit counts.
- `features.csv.gz`: the upstream demographic design matrix. We retain its coding
  and finite evaluation frame; no population-representative or causal claim is made.
  Reference categories are Male, White, HS or Below, and under 25; all other
  displayed indicators are relative to these omitted categories. The age names
  are inherited from the source coding, not recomputed at June 2022: birth-year
  intervals (1929,1958], (1958,1973], (1973,1988], (1988,1998], and
  (1998,2003] are labeled 65+, 50–64, 35–49, 25–34, and under 25.
- `labels.csv.gz`: seven recorded scanner measures. The benchmark uses an indicator
  of a positive value for each measure. This dichotomizes `ddg_join_ads` and
  `third_party_cookies`; the other five columns are already binary.

Missing labels are not zero. Only domains with recorded labels belong to this
benchmark, and shares are normalized over that frame. The checks require unique
user-domain records, positive finite visits, full join coverage, unique identifier
keys, finite complete features/labels, nonnegative labels, and a full-rank design.
Recorded scanner outcomes serve as fixed benchmark labels, not error-free truth
about all forms of tracking. Predictions and their mistakes are deliberately
imposed by the experiment; no result estimates a real classifier's performance.

## Observed adult-domain classifications

`adult_domains.csv.gz` is a derived extract of the public
[`soodoku/adult`](https://github.com/soodoku/adult) repository at commit
`f25d0c00a733450061c1f260c2890c9873a73d61`. It has 64,074 domains and
6,236,834 visits from the June 2022 YouGov browsing study. Each row contains a
SHA-256 domain identifier, its total visits, one Piedomains prediction, and up
to three recorded provider categories. It contains no user-level records or
domain names. Missing provider categories remain missing, not negative.
The domain-name join matches 64,064 of 64,074 Piedomains rows; the remaining
ten have no provider category.

The source files are `data/piedomains_classification.csv.gz` (SHA-256
`f847e21d19cd20ada82449e8438babf1879fce4badc47ca57465804a31d25ea6`)
and `data/vt_domain_categories.csv` (SHA-256
`0bde99f39e87a490b5b0d56fa28d51310b8bb3cc32e9a7dd897c549eef71ec75`).
The [builder](../scripts/build_adult_input.py) verifies these hashes, joins
`private_domain` to `domain`, and regenerates the bundled file with:

```sh
python3 scripts/build_adult_input.py /path/to/adult-checkout
```

The Piedomains indicator follows the adult repository's analysis rule:
`pred_label == "porn"` and `label_prob >= 0.033`. The three reference indicators
are exact category matches: Bitdefender `porn`, Forcepoint ThreatSeeker `sex`,
and alphaMountain AI `Pornography`. These are alternate classification systems,
not verified content labels. Their category definitions can differ. A recorded
category other than the named positive one is coded zero, including nonspecific
categories such as Bitdefender `misc` and alphaMountain `Unrated`; zero is not a
verified negative content label. Each comparison restricts to domains with a
recorded category from that provider and normalizes visit weights within that
frame. The table therefore measures
cross-system disagreement and the effect on visit-weighted shares, not either
classifier's accuracy against truth. The three rows have different domain and
visit coverage and should not be read as estimates on one common frame.
`data/results/adult_head_sensitivity.csv` records the bounds after retaining
both observed labels for the 0, 10, 50, 250, or 1,000 highest-visit domains in
each provider frame. This is an information-loss calculation using existing
classifications, not a verified-label audit.
