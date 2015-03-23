BEGIN {
    c=0;
}
{
    if (key == "") key=$1;
    c++;
}
END {
    print "" key " " c;
}
