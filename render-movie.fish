#!/usr/bin/fish

for start in (seq 0 7)
    fish -c "cd $PWD; for suffix in (seq -f '%04g' $start 8 60); ./ayanami movies/$argv[1]-\$suffix.yaml renders/movies/$argv[1]/\$suffix.png; end" &
end
