# Makefile for resume generation

# Variables
LATEX = pdflatex
CONVERT = magick
FILENAME = resume

# OS detection
ifeq ($(OS),Windows_NT)
    RM = del /Q
    MV = move
    CP = copy
    MKDIR = md
    RMDIR = rd /S /Q
    NULL = nul
    SHELL = cmd.exe
else
    RM = rm -f
    MV = mv
    CP = cp
    MKDIR = mkdir -p
    RMDIR = rm -rf
    NULL = /dev/null
    SHELL_CMD = sh -c
endif

# Load environment variables if .env.local exists
ifneq (,$(wildcard .env.local))
    include .env.local
    export
endif

# Default target - build both versions
all: public private

# Public version (no phone number) - default resume
public: $(FILENAME).pdf

# Private version (with phone number)
private: $(FILENAME)-private.pdf

# Generate public PDF (no phone) - main resume file
$(FILENAME).pdf: $(FILENAME).tex
	powershell.exe -Command "(Get-Content $(FILENAME).tex) -replace 'PHONESECTIONPLACEHOLDER', '' | Set-Content $(FILENAME)-temp.tex"
	$(LATEX) $(FILENAME)-temp.tex
	$(MV) $(FILENAME)-temp.pdf $(FILENAME).pdf
	$(RM) $(FILENAME)-temp.tex $(FILENAME)-temp.aux $(FILENAME)-temp.log $(FILENAME)-temp.out

# Generate private PDF (with phone)
$(FILENAME)-private.pdf: $(FILENAME).tex .env.local
	powershell.exe -Command "if (-not $$env:PHONE_NUMBER) { Write-Host 'Error: PHONE_NUMBER not set in .env.local'; exit 1 }"
	powershell.exe -Command "(Get-Content $(FILENAME).tex) -replace 'PHONESECTIONPLACEHOLDER', \"$$env:PHONE_NUMBER \$\$|\$\$ \" | Set-Content $(FILENAME)-private.tex"
	$(LATEX) $(FILENAME)-private.tex
	$(RM) $(FILENAME)-private.tex $(FILENAME)-private.aux $(FILENAME)-private.log $(FILENAME)-private.out

# Generate public PNGs - separate files per PDF page
png: $(FILENAME).pdf
	$(CONVERT) -density 300 "$(FILENAME).pdf" -background white -alpha remove -quality 90 "$(FILENAME)-page-%d.png"

# Generate private PNGs - separate files per PDF page
png-private: $(FILENAME)-private.pdf
	$(CONVERT) -density 300 "$(FILENAME)-private.pdf" -background white -alpha remove -quality 90 "$(FILENAME)-private-page-%d.png"

# Backward compatibility targets
$(FILENAME).png: png
	@echo "Generated $(FILENAME)-page-0.png etc."

$(FILENAME)-private.png: png-private
	@echo "Generated $(FILENAME)-private-page-0.png etc."

# Clean auxiliary files
clean:
	$(RM) $(FILENAME)*.aux $(FILENAME)*.log $(FILENAME)*.out $(FILENAME)*.fdb_latexmk $(FILENAME)*.fls $(FILENAME)*.synctex.gz

# Clean all generated files
clean-all: clean
	$(RM) $(FILENAME).pdf $(FILENAME).png $(FILENAME)-private.pdf $(FILENAME)-private.png

# Force rebuild
rebuild: clean all

# Install dependencies (macOS with Homebrew)
install-deps:
	brew install --cask mactex
	brew install imagemagick

# Install dependencies (Windows with Chocolatey)
install-deps-windows:
	choco install miktex
	choco install imagemagick

# Help target
help:
	@echo "Available targets:"
	@echo "  all              - Build both public and private versions (default)"
	@echo "  public           - Build public version as resume.pdf/png (no phone number)"
	@echo "  private          - Build private version as resume-private.pdf/png (with phone number)"
	@echo "  clean            - Remove auxiliary files"
	@echo "  clean-all        - Remove all generated files"
	@echo "  rebuild          - Clean and rebuild all"
	@echo "  install-deps     - Install required dependencies (macOS)"
	@echo "  install-deps-windows - Install required dependencies (Windows)"
	@echo "  help             - Show this help message"

# Backward compatibility hook (still works by creating same names)
resume.png: png
	@echo "Generated $(FILENAME)-page-0.png ..."

resume-private.png: png-private
	@echo "Generated $(FILENAME)-private-page-0.png ..."

.PHONY: all public private clean clean-all rebuild install-deps install-deps-windows help pdf png png-private resume.png resume-private.png