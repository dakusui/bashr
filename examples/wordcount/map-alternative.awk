{
    gsub(/([[:punct:]]|[[:blank:]])+/, " ", $0);
    n=split($0,cols," ");
    for (i = 1; i <= n; i++) { print cols[i]; };
}
