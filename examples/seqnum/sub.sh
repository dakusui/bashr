read -a a

for i in "${a[@]}"; do
  printf 'a=%s\n' $i
done
