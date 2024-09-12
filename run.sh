# get the args
# ./AFLplusplus/afl-fuzz -i $seed_from -o $output/${program}_cmplog -c ./programs_AFLplusplus/cmp/${program} -m 1024 -- ./programs_AFLplusplus/justafl/${program} $before @@ $after
#!/bin/bash

# Usage: ./run.sh -i input -o output -c ./programs_AFLplusplus/jhead -m 1024 -- ./programs_AFLplusplus/justafl/jhead -b @@ -a

#!/bin/bash

# Print usage message if arguments are not passed correctly
# if [ $# -lt 5 ]; then
#   echo "Usage: $0 -i input -o output -c <path_to_cmp_program> -m <memory_limit> -- <program_to_run> [additional_args]"
#   exit 1
# fi

# Parse the required options
# while [[ "$#" -gt 0 ]]; do
#     case $1 in
#         -i) input="$2"; shift ;;
#         -o) output="$2"; shift ;;
#         -c) cmp_program="$2"; shift ;;
#         -m) memory_limit="$2"; shift ;;
#         --) shift; break ;;
#         *) echo "Unknown parameter: $1"; exit 1 ;;
#     esac
#     shift
# done

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i)
            input="$2"
            shift 2
            ;;
        -o)
            output="$2"
            shift 2
            ;;
        *)
            remaining_command+=("$1")
            shift
            ;;
    esac
done

# Remaining arguments are the program to run and its options
# program_to_run="$1"
# shift
# program_args="$@"

# Run the command
# echo "./afl-fuzz -c $cmp_program -m $memory_limit -- $program_to_run $program_args"
# $cmp_program -m $memory_limit -- $program_to_run $program_args
# echo ./afl-fuzz -i $input -o $output ${remaining_command[*]}


# separate the initial seeds into multiple independent seed sets
# Check if the provided path is a valid directory
if [ ! -d "$input" ]; then
  echo "Error: $input is not a valid directory."
  exit 1
fi

# Create individual folders for each seed file
counter=1
for seed_file in "$input"/*; do
  # Check if it's a file
  if [ -f "$seed_file" ]; then
    # Create a new directory named by the counter
    new_dir="$input/$counter"
    mkdir -p "$new_dir"

    # Move the seed file into the newly created directory
    mv "$seed_file" "$new_dir"

    # Increment the counter
    ((counter++))
  fi
done

# run the sub-fuzzing for a target time limit
# -V to control the fuzzing time (second)
dir_count=$(find "$input" -mindepth 1 -maxdepth 1 -type d | wc -l)
echo $dir_count
fuzz_time=$((86400 / $dir_count))



fuzz_time=60

echo $fuzz_time

find "$input" -mindepth 1 -maxdepth 1 -type d | while read -r subdir; do

  # run the sub-fuzzing
  # echo ./afl-fuzz -i $subdir -o tmp -V $fuzz_time -c $cmp_program -m $memory_limit -- $program_to_run $program_args
  # ./afl-fuzz -i $subdir -o tmp -V $fuzz_time -c $cmp_program -m $memory_limit -- $program_to_run $program_args

  echo ./afl-fuzz -i $subdir -o tmp ${remaining_command[*]}
  ./afl-fuzz -i $subdir -o tmp ${remaining_command[*]}

  # merge the current outputs into the global output
  if [ -d "$output" ]; then
    
    # Iterate over each file in the source directory
    for file in tmp/default/queue/*; do
      # Get the base name of the file (without path)
      file_name=$(basename "$file")

      target_dir=$output/default/queue

      # If a file with the same name exists in the target directory
      if [ -e "$target_dir/$file_name" ]; then
        # Append a timestamp or incrementing number to avoid name clash
        timestamp=$(date +%s)
        new_file_name="${file_name%.*}_$timestamp.${file_name##*.}"

        echo "Name clash: Renaming '$file_name' to '$new_file_name'"
        cp "$file" "$target_dir/$new_file_name"
      else
        # No name clash, simply copy the file
        cp "$file" "$target_dir/$file_name"
      fi
    done

  else
    cp -r tmp $output
  fi

  rm -r -f tmp

done

# collect the finial results periodically