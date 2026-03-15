inputs=("1_000nds" "10_000nds")
ccns=(100 1000 10000 100000)
tsizes=(2 4 8)

for input in "${inputs[@]}"; do
	mkdir -p out/p/$input
	mkdir -p out/s/$input
	for tsize in "${tsizes[@]}";do
		export OMP_NUM_THREADS="$tsize"
		echo "Executing with num threads = $OMP_NUM_THREADS"
		mkdir -p out/p/$input/$OMP_NUM_THREADS	
		for ccn in "${ccns[@]}"; do
			echo "ccn: $ccn; input $input"
			echo "Parallel Run, $OMP_NUM_THREADS threads"
			./build/openmp_fixed_dimna/openmp_fixed_di_mna --in ../MNA/inputs/parquet/$input --out out/p/$input/$OMP_NUM_THREADS --runs 1 --ccn $ccn --cs 2
		done
	done
	for ccn in "${ccns[@]}"; do
		echo "ccn: $ccn; input $input"
		echo "Serial Run"
		./build/dimna/di_mna --in ../MNA/inputs/parquet/"$input"/ --out out/s/$input/ --runs 1 --ccn $ccn --cs 2
	done
done
