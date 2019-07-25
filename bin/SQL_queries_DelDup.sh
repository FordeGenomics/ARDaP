#!/bin/bash


seq=$1
RESISTANCE_DB=$2 

declare -A SQL_loss_report=()
STATEMENT_GENE_LOSS_COV () {
COUNTER=1
while read line; do 
chromosome=$(echo "$line" | awk '{print $1}')
q_start=$(echo "$line" | awk '{print $2}')
q_end=$(echo "$line" | awk '{print $3 }')
SQL_loss_report[$COUNTER]=$(
cat << EOF
SELECT
    Coverage.Gene,
    Coverage.Locus_tag,
    Coverage.Upregulation_or_loss,
    Coverage.Antibiotic_affected,
    Coverage.Known_combination,
	Coverage.Comments
FROM
    Coverage
WHERE
    Coverage.Chromosome = '$chromosome'
    AND Coverage.Start_coords < '$q_end'
    AND Coverage.End_coords > '$q_start'
    AND Coverage.Upregulation_or_loss LIKE 'Loss';
EOF
)

COUNTER=$((COUNTER+1))
done < <(tail -n +2 ${seq}.deletion_summary.txt)
LOSS_COUNT="$COUNTER"
}


declare -A SQL_upregulation_report=()
STATEMENT_UPREGULATION () {
COUNTER=1
while read line; do
  chromosome=$(echo "$line" | awk '{print $1}')
  q_start=$(echo "$line" | awk '{print $2}')
  q_end=$(echo "$line" | awk '{print $3 }')
SQL_upregulation_report[$COUNTER]=$(
cat << EOF
SELECT
    Coverage.Gene,
    Coverage.Locus_tag,
    Coverage.Upregulation_or_loss,
    Coverage.Antibiotic_affected,
    Coverage.Known_combination,
	Coverage.Comments
FROM
    Coverage
WHERE
    Coverage.Chromosome = '$chromosome'
    AND Coverage.Start_coords > '$q_start'
    AND Coverage.End_coords < '$q_end'
    AND Coverage.Upregulation_or_loss LIKE 'Upregulation';
EOF
)

COUNTER=$((COUNTER+1))
done < <(tail -n +2 ${seq}.duplication_summary.txt)
UPREG_COUNT="$COUNTER"
}

declare -A SQL_loss_func=()
STATEMENT_GENE_LOSS_FUNC () {
COUNTER=1
while read line; do 
gene=$(echo "$line" | awk '{print $1}')
#variant=$(echo $line | awk '{print $2 }')
SQL_loss_func[$COUNTER]=$(
cat << EOF
SELECT
    Coverage.Gene,
    Coverage.Locus_tag,
    Coverage.Upregulation_or_loss,
    Coverage.Antibiotic_affected,
    Coverage.Known_combination,
	Coverage.Comments
FROM
    Coverage
WHERE
    Coverage.Gene = '$gene'
	AND Coverage.Upregulation_or_loss LIKE 'loss';
EOF
)

COUNTER=$((COUNTER+1))
done < ${seq}.Function_lost_list.txt
LOSS_FUNC_COUNT="$COUNTER"
}

echo "Creating function lost statements"
STATEMENT_GENE_LOSS_FUNC 
echo -e "Creating loss statements\n"
STATEMENT_GENE_LOSS_COV
echo -e "Creating upregulation statements\n"
STATEMENT_UPREGULATION

echo "Running duplication detection queries"
for (( i=1; i<"$UPREG_COUNT"; i++ )); do $SQLITE "$RESISTANCE_DB" "${SQL_upregulation_report[$i]}" >> AbR_output.txt; done
echo "done"
echo "Running loss of coverage queries"
for (( i=1; i<"$LOSS_COUNT"; i++ )); do $SQLITE "$RESISTANCE_DB" "${SQL_loss_report[$i]}" >> AbR_output.txt; done
echo "done"
echo "Running detection of functional loss queries"
for (( i=1; i<"$LOSS_FUNC_COUNT"; i++ )); do $SQLITE "$RESISTANCE_DB" "${SQL_loss_func[$i]}" >> AbR_output.txt; done
echo "done"
