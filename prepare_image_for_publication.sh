#!/bin/bash

# Stop on all errors
set -e


###############################################################################
#                             Default Arguments                               #
###############################################################################

# Static definitions; purpose of each variable stated in the name
# The visual difference can be neglegible but the overall size can be drastically reduced by this setting
DEFAULT_IMAGE_QUALITY=75 
# A default copyright text to use - change this permanently or use the optional parameter
CURRENT_YEAR=$(date +%Y)
DEFAULT_COPYRIGHT_TEXT="(C) Dominic Dumrauf, ${CURRENT_YEAR}"




###############################################################################
#                              Helper Functions                               #
###############################################################################

# Helper function for checking multiple dependencies
function check_dependencies {
	dependencies=$1
	for dependency in ${dependencies};
	do
		if ! hash ${dependency} 2>/dev/null;
		then
		        echo -e "This script requires '${dependency}' but it cannot be detected. Aborting..."
		        exit 1
		fi
	done
}


# Helper function for displaying help text (pun intended)
function display_help {
  script_name=`basename "$0"`
  echo "Usage  : $script_name -i <input-file> -o <output-directory> -w <width> -q [jpeg-quality] -c [copyright-text] -d [is-displaying-copyright-text] -v(erbose)"
  echo "Example: $script_name -i "'"image.jpg"  -o "converted/"       -w 1600'
  echo "Example: $script_name -i "'"image.jpg"  -o "converted/"       -w 1600    -q 75'
  echo "Example: $script_name -i "'"image.jpg"  -o "converted/"       -w 1600    -q 75             -c "(C) Your Name"'
  echo "Example: $script_name -i "'"image.jpg"  -o "converted/"       -w 1600    -q 75             -c "(C) Your Name"  -d false'
}


# Helper function for echoing debug information
function echo_debug {
  if $is_verbose;
  then 
    echo "$1"
  fi
}




###############################################################################
#                             Dependency Checks                               #
###############################################################################

# Check dependencies of Bash script
DEPENDENCIES='convert exiftool pngquant'
check_dependencies "${DEPENDENCIES}"




###############################################################################
#                          Input Argument Handling                            #
###############################################################################

# Input argument parsing
while getopts ":hi:o:w:q:c:d:v" option
do
  case "${option}" in
    i) filename=${OPTARG};;
    o) outdir=${OPTARG};;
    w) width=${OPTARG};;
    q) image_quality=$OPTARG;;
    c) copyright_text=$OPTARG;;
    d) is_displaying_copyright_text=$OPTARG;;
    v) is_verbose=true;;
    h) display_help; exit -1;;
    :) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
  esac
done

# Mandatory input arguments check
if [[ -z "${filename}" || -z "${outdir}" || -z "${width}" ]]; then
    display_help
    exit -1
fi

# Handle optional verbosity parameter
is_verbose=${is_verbose:-false}

# Handle optional image quality parameter
image_quality=${image_quality:-$DEFAULT_IMAGE_QUALITY}
echo_debug "JPEG quality set to ${image_quality}"

# Handle optional copyright text parameter
copyright_text=${copyright_text:-$DEFAULT_COPYRIGHT_TEXT}
echo_debug "Copyright text set to \"${copyright_text}\""

# Handle optional copyright text display parameter
is_displaying_copyright_text=${is_displaying_copyright_text:-true}
echo_debug "Is copyright text visible: ${is_displaying_copyright_text}"




###############################################################################
#                              Image Conversion                               #
###############################################################################

# Convert image
outfile=${outdir}/$(basename "${filename}")
extension="${filename##*.}"
lower_case_extension="$(echo "${extension}" | awk '{print tolower($0)}')"
if [ "${lower_case_extension}" = "png" ]
then
  temp_file="${outfile}.temp"

  # Helper function for cleaning up temporary files
  function finish {
      rm "${temp_file}"
  }

  # Ensure proper cleanup, regardless of the exit status of the script
  trap finish EXIT

  convert "${filename}" -resize ${width}  ${extension}:"${temp_file}"
  pngquant "${temp_file}" --quality ${image_quality} --speed 1 --output "${outfile}" --force
else
  convert "${filename}" -quality ${image_quality} -resize ${width}  ${extension}:"${outfile}"
fi

# Remove all EXIF tags and replace with ${copyright_text}
exiftool -all= "${outfile}" -overwrite_original
exiftool -copyright="${copyright_text}" "${outfile}" -overwrite_original


# Depending on "${is_displaying_copyright_text}", add ${copyright_text} to image
if ${is_displaying_copyright_text};
then
  convert "${outfile}"  -font Arial -pointsize 10 \
          -draw "gravity southwest \
                  fill black  text 10,10 '${copyright_text}' \
                  # fill white  text 11,11 '${copyright_text}' " \
          "${outfile}"
fi
