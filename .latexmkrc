# Rebuild fresh_rewrite.pdf on change (latexmk -pvc and one-shot builds).
$pdf_mode = 1;
$interaction = 'nonstopmode';
$pdflatex = 'pdflatex -synctex=1 -file-line-error %O %S';
$bibtex_use = 2;
$pdf_previewer = 'none';
$sleep_time = 1;
