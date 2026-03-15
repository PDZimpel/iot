inputs=("1_000nds" "10_000nds" "100_000nds")
ccns=(100 1000 10000 100000)

for input in "${inputs[@]}"; do
	mkdir out/p/$input
	mkdir out/s/$input
	for ccn in "${ccns[@]}"; do
		echo "ccn: $ccn; input $input"
		echo "Parallel Run"
		./build/openmp_fixed_dimna/openmp_fixed_di_mna --in ../MNA/inputs/parquet/$input --out out/p/$input/ --runs 1 --ccn $ccn --cs 2
		echo "Serial Run"
		./build/dimna/di_mna --in ../MNA/inputs/parquet/"$input"/ --out out/s/$input/ --runs 1 --ccn $ccn --cs 2
	done
done
