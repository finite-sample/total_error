# Fixed browsing benchmark

The three bundled files reproduce the fewlab extract at original local commit
`e360f6542c0e97c6b8819da6c17d5e08c1543762`, byte-for-byte. That original snapshot
was not available from GitHub when checked. The author authorized redistribution
in this package on October 4, 2026; reproduction uses these bundled files and
does not require access to the original branch or another repository.
`manifest.csv` records SHA-256 hashes and the source commit.
`Rscript analysis/verify_data.R` checks file integrity.
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
