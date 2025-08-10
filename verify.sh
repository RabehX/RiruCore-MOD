if ! $BOOTMODE; then
    abort "! Install from Recovery is not supported"
fi


# extract <zip> <file> <target dir> <junk paths>
extract() {
  zip=$1
  file=$2
  dir=$3
  junk_paths=$4
  [ -z "$junk_paths" ] && junk_paths=false
  opts="-o"
  [ $junk_paths = true ] && opts="-oj"
  file_path="$dir/$file"

  unzip $opts "$zip" "$file" -d "$dir" >&2
  [ -f "$file_path" ] || abort_verify "$file not exists"


  ui_print "- Extracted $file" >&1
}
