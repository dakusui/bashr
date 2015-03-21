{
    for (l=1; (getline line) > 0; l++) {
	gsub(/([[:punct:]]|[[:blank:]])+/, " ", line);
	n=split(line,cols," ");
	for (i = 2; i < n; i++) { print cols[i]; };
    }
}
