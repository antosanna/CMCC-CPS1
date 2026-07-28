#!/bin/sh -l
OUTFILE="timing_summary.csv"
[[ "${@: -1}" == *.csv ]] && { OUTFILE="${@: -1}"; FILES="${@:1:$#-1}"; } || FILES="$@"
NODES=3
CORES_PER_NODE=112

echo "case;throughput [sim_y/day];cpl_comm_sec [sec];total_time_sec [sec];total_corehours [hr];hours_per_simmonth [hr]" > "$OUTFILE"

for logfile in $FILES; do
    case_name=$(grep "Case\s*:" "$logfile" | awk '{print $NF}')
    throughput=$(grep "Model Throughput" "$logfile" | grep -oP '[\d.]+(?=\s+simulated_years/day)')
    cpl_comm=$(grep "^\s*CPL COMM Time" "$logfile" | grep -oP '[\d.]+(?= seconds)' | head -1)
    init_time=$(grep "^\s*Init Time" "$logfile" | grep -oP '[\d.]+(?= seconds)' | head -1)
    run_time=$(grep "^\s*Run Time" "$logfile" | grep -oP '[\d.]+(?= seconds)' | head -1)
    final_time=$(grep "^\s*Final Time" "$logfile" | grep -oP '[\d.]+(?= seconds)' | head -1)

    [[ -z "$case_name" || -z "$throughput" || -z "$cpl_comm" || -z "$init_time" || -z "$run_time" || -z "$final_time" ]] && \
        echo "⚠️  Skippato: $logfile" && continue

    total_time=$(echo "$init_time + $run_time + $final_time" | bc)
    total_corehours=$(echo "scale=4; $total_time / 3600 * $NODES * $CORES_PER_NODE" | bc)
    hours_per_simmonth=$(echo "scale=4; 24 / ($throughput * 12)" | bc)

    throughput_it=$(echo "$throughput" | sed 's/\./,/')
    cpl_comm_it=$(echo "$cpl_comm" | sed 's/\./,/')
    total_time_it=$(echo "$total_time" | sed 's/\./,/')
    total_corehours_it=$(echo "$total_corehours" | sed 's/\./,/')
    hours_per_simmonth_it=$(echo "$hours_per_simmonth" | sed 's/\./,/')

    echo "$case_name;$throughput_it;$cpl_comm_it;$total_time_it;$total_corehours_it;$hours_per_simmonth_it" >> "$OUTFILE"
    echo "✓ $case_name → throughput=$throughput | corehours=$total_corehours | hours/simmonth=$hours_per_simmonth"
done

echo "Salvato in: $OUTFILE"
