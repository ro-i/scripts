#!/usr/bin/gawk -f

# Analyze the output of top -b -c (ran for some time and redirected to a file).

# Note from the manual of GNU awk: Uninitialized variables have the numeric
# value zero and the string value "" (the null, or empty, string).

function per_cent(v, c) {
	return (v / c) * 100
}


BEGIN {
	# Traverse arrays in descending order of the numerical value of their
	# values.
	PROCINFO["sorted_in"] = "@val_type_desc"

	compute = 0
}


/^$/ { compute = 0; next }

/\s*PID\s*USER\s*PR\s*NI\s*VIRT\s*RES\s*SHR\s*S\s*%CPU\s*%MEM\s*TIME\+\s*COMMAND\s*/ {
	compute = 1; next
}

/^top -/ { global_count++; next }

# un-niced user processes + kernel processes + niced user processes
/^%Cpu\(s\):/ { global_cpu += $2 + $4 + $6; next }

# used mem / total mem
/^MiB Mem/ { global_mem += per_cent($8, $4); next }

{
	if (!compute)
		next

	# Per COMMAND stats.

	# Concatenate PID and COMMAND.
	name = "(" $1 ")"
	for (i = 12; i <= NF; i++)
		name = name " " $i
	count[name]++;

	cpu[name] += $9
	mem[name] += $10
}


END {
	if (!global_count)
		exit 1

	printf("%s     %s     %s\n", "GLOBAL/LIFETIME CPU", "GLOBAL/LIFETIME RAM", "PROCESS")

	for (proc in cpu) {
		printf("CPU %6.2f%%; %6.2f%% || RAM %6.2f%%; %6.2f%% || %s\n",
		       cpu[proc] / global_count, cpu[proc] / count[proc],
		       mem[proc] / global_count, mem[proc] / count[proc], proc)
	}

	printf("\nTotal: %.2f%% CPU || %.2f%% RAM\n",
	       global_cpu / global_count,
	       global_mem / global_count)
}
