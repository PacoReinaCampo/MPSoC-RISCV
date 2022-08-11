rm -f *.tex
rm -f *.pdf

pandoc BOOK.md -s -o MPSoC-RISCV.tex
pandoc BOOK.md -s -o MPSoC-RISCV.pdf
