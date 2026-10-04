.PHONY: all analysis paper test lint check clean

all: paper

analysis:
	Rscript analysis/verify_data.R
	Rscript analysis/browsing_study.R
	Rscript analysis/rare_errors.R
	Rscript analysis/refinement_study.R
	Rscript analysis/audit_study.R
	Rscript analysis/make_exhibits.R
	Rscript -e 'rmarkdown::render("sim_total_error.Rmd", quiet = TRUE)'

paper: analysis
	latexmk -pdf -interaction=nonstopmode -halt-on-error total_error.tex

test:
	Rscript tests/test_total_error.R
	Rscript tests/test_audit_bounds.R
	Rscript tests/test_audit_design.R

lint:
	Rscript -e 'source("R/audit_bounds.R"); files <- c("sim_total_error.R", "sim_total_error.Rmd", list.files(c("R", "analysis", "tests"), pattern = "[.]R$$", full.names = TRUE)); issues <- unlist(lapply(files, lintr::lint), recursive = FALSE); if (length(issues)) { print(issues); quit(status = 1) }'

check: test lint paper
	git diff --check

clean:
	latexmk -c total_error.tex
