.PHONY: all analysis paper test lint check clean

all: paper

analysis:
	Rscript -e 'rmarkdown::render("sim_total_error.Rmd", quiet = TRUE)'

paper: analysis
	latexmk -pdf -interaction=nonstopmode -halt-on-error total_error.tex

test:
	Rscript tests/test_total_error.R

lint:
	Rscript -e 'files <- c("sim_total_error.R", "tests/test_total_error.R", "sim_total_error.Rmd"); issues <- unlist(lapply(files, lintr::lint), recursive = FALSE); if (length(issues)) { print(issues); quit(status = 1) }'

check: test lint paper
	git diff --check

clean:
	latexmk -c total_error.tex
