#!/bin/bash -e
# Downloads all AZW3 books and their covers from
# Standard ebooks and copies them to Kindle.
#
# Dependencies: curl, rg, openssl, awk, rsync
#
# Usage: ./standard-to-kindle.bash [kindle mount point]

cd "${0%/*}"

STANDARD_EBOOKS_SITE='https://standardebooks.org'
CATALOG_DIR='catalog'
BOOKS_DIR='books'
COVERS_DIR='covers'
KINDLE_MOUNT_POINT=${1:-'/Volumes/Kindle'}
KINDLE_DOCUMENTS_DIR="${KINDLE_MOUNT_POINT}/documents"
KINDLE_COVERS_DIR="${KINDLE_MOUNT_POINT}/system/thumbnails"

function create_directories() {
    mkdir -p {"$CATALOG_DIR","$BOOKS_DIR","$COVERS_DIR"}
}

function download_catalog() {
    echo 'Downloading Standard Ebooks catalog.'
    curl -# -C - "${STANDARD_EBOOKS_SITE}/opds/all" -o "./${CATALOG_DIR}/catalog.xml"
}

function download_books() (
    cd "$BOOKS_DIR"

    azw3_file_paths="$(rg 'href="(/.+\.azw3)"' -oNIr '$1' ../${CATALOG_DIR})"
    file_count="$(echo "$azw3_file_paths" | wc -l | awk '{$1=$1};1')"

    echo "Found $file_count AZW3 books in the catalog."
    echo 'Downloading books...'

    counter=0

    while read -r file_path; do
        counter=$((counter + 1))
        filename=$(echo "$file_path" | awk -F/ '{print $NF}')
        echo "[${counter}/${file_count}]: $filename"

        if [ -f "$filename" ]
        then
            echo '...found locally!'
        else
            curl -# -C - "${STANDARD_EBOOKS_SITE}${file_path}" -o "./${filename}.part" \
            && mv "./${filename}.part" "./${filename}"
        fi
    done <<< "$azw3_file_paths"
)

function download_covers() (
    cd "$COVERS_DIR"

    book_urls="$(rg '<id>(.+)</id>' -oNIr '$1' "../${CATALOG_DIR}")"
    book_count="$(echo "$book_urls" | wc -l | awk '{$1=$1};1')"

    echo "Found $book_count books in the catalog."
    echo 'Downloading covers...'

    counter=0

    while read -r url; do
        counter=$((counter + 1))
        url_hash="$(echo -n "$url" | openssl dgst -sha1)"
        filename="thumbnail_${url_hash}_EBOK_portrait.jpg"
        echo "[${counter}/${book_count}]: $filename"

        if [ -f "$filename" ]
        then
            echo '...found locally!'
        else
            curl -# -C - "${url}/dist/${filename}" -o "./${filename}.part" \
            && mv "./${filename}.part" "./${filename}"
        fi
    done <<< "$book_urls"
)

function copy_books() {
    if [ -d "$KINDLE_DOCUMENTS_DIR" ]
    then
        echo 'Copying books to Kindle...'
        rsync -a -v --ignore-existing "./${BOOKS_DIR}/" "${KINDLE_DOCUMENTS_DIR}/"
    else
        echo "Could not find Kindle documents directory: ${KINDLE_DOCUMENTS_DIR}"
        exit 1
    fi
}

function copy_covers() {
    if [ -d "$KINDLE_COVERS_DIR" ]
    then
        echo 'Copying cover pictures to Kindle...'
        rsync -a -v --ignore-existing "./${COVERS_DIR}/" "${KINDLE_COVERS_DIR}/"
    else
        echo "Could not find Kindle covers directory: ${KINDLE_COVERS_DIR}"
        exit 1
    fi
}

create_directories
download_catalog
download_books
download_covers
copy_books
copy_covers
