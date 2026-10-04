.PHONY: all analysis exhibits report manuscript paper bibliography test lint check clean

all: paper

analysis:
	Rscript scripts/verify_data.R
	Rscript scripts/browsing_study.R
	Rscript scripts/rare_errors.R
	Rscript scripts/refinement_study.R
	Rscript scripts/audit_study.R

exhibits: analysis
	Rscript scripts/make_exhibits.R

report:
	Rscript -e 'root <- getwd(); rmarkdown::render("docs/sim_total_error.Rmd", knit_root_dir = root, quiet = TRUE)'

manuscript:
	cd ms && latexmk -pdf -auxdir=build -interaction=nonstopmode -halt-on-error main.tex

paper: exhibits report
	$(MAKE) manuscript

bibliography:
	mkdir -p ms/build
	printf '%s\n' '\relax' '\citation{*}' '\bibstyle{plainnat}' '\bibdata{references}' > ms/build/bibliography.aux
	cd ms && bibtex build/bibliography
	! grep -E 'Warning--|error message' ms/build/bibliography.blg

test:
	Rscript tests/test_total_error.R
	Rscript tests/test_audit_bounds.R
	Rscript tests/test_audit_design.R

lint:
	Rscript -e 'source("R/audit_bounds.R"); files <- c("docs/sim_total_error.Rmd", list.files(c("R", "scripts", "tests"), pattern = "[.]R$$", full.names = TRUE)); issues <- unlist(lapply(files, lintr::lint), recursive = FALSE); if (length(issues)) { print(issues); quit(status = 1) }'

check: test lint bibliography paper
	git diff --check

clean:
	cd ms && latexmk -c -auxdir=build main.tex
