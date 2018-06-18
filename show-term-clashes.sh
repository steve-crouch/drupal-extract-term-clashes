#!/bin/bash
#
# Compare sets of taxonomy term data from two Drupal servers
# and show any clashes on term ID
#
# Inputs: a set of taxonomy export files from each server, one
# for each taxonomy set. Exported using the term_csv_export_import
# module with its filename prefixed with a unique string to identify
# its source e.g. live, dev, production
#
# Output: a list of clashing term IDs on both servers, together with
# term name and other metadata

# Clean from last run
rm -f 2.parseable/*
rm -f 3.parseable/*

# Throw away the second UUID field - it confuses the search, then sort
for file in 1.raw/*; do
    echo "Sorting and cleaning ${file}..."
    filename=$(basename "${file}")
    cat "${file}" | cut -d, -f2 --complement | sort > "2.parseable/${filename}"
done

# Get the unique prefixes from cleaned term files
declare -A uniq_source_prefixes
for cleaned in 2.parseable/*; do
    filename=$(basename "${cleaned}")
    file_prefix=$(echo "${filename}" | sed 's/-.*$//g')
    uniq_source_prefixes[$file_prefix]=1
done

# Combine taxonomy files together, one for each server
echo
for source in ${!uniq_source_prefixes[@]}; do
    echo "Combining ${source}-related files..."
    cat 2.parseable/${source}* | sort > "3.combined/${source}.txt"
done

# Extract clashing term IDs
echo -e "\nExtract clashing term IDs..."
grep -vf 3.combined/* | cut -d, -f1 > clashes.txt

# Show the clashes in context of cleaned server sets,
# to show where the clashes originate
echo -e "\nClashing terms..."
while read id; do
    grep "${id}" 2.parseable/*
done <clashes.txt
