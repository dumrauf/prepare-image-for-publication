#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ln -s "${DIR}"/prepare_image_for_publication.sh /usr/local/bin/prepare_image_for_publication
