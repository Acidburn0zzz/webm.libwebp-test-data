#!/bin/sh
##
## test_cwebp.sh
##
## Simple test to validate encoding of source images using the cwebp
## example utility.
##
## This file distributed under the same terms as libwebp. See the libwebp
## COPYING file for more information.
##
set -e

self=$0

usage() {
    cat <<EOT
Usage: $self [options] <source files to test>

Options:
  --exec=</path/to/cwebp>
  --loop=<count>
  --nocheck
  --mt
  --noalpha
  --lossless
EOT
    exit 1
}

run() {
    # simple means for a batch speed test
    ${executable} $file
}

check() {
    # test the optimized vs. unoptimized versions. this is a bit
    # fragile, but good enough for optimization testing.
    md5=$({ ${executable} -o - $file || echo "fail1"; } | md5sum)
    md5_noasm=$( { ${executable} -noasm -o - $file || echo "fail2"; } | md5sum)

    printf "$file:\t"
    if [ "$md5" = "$md5_noasm" ]; then
        printf "OK\n"
    else
        printf "FAILED\n"
        exit 1
    fi
}

check="true"
noalpha=""
lossless=""
mt=""
n=1
for opt; do
    optval=${opt#*=}
    case ${opt} in
        --exec=*) executable="${optval}";;
        --loop=*) n="${optval}";;
        --mt) mt="-mt";;
        --lossless) lossless="-lossless";;
        --noalpha) noalpha="-noalpha";;
        --nocheck) check="";;
        -*) usage;;
        *) break;;
    esac
    shift
done

[ $# -gt 0 ] || usage
[ "$n" -gt 0 ] || usage

executable=${executable:-cwebp}
${executable} 2>/dev/null | grep -q Usage || usage
executable="${executable} -quiet ${mt} ${lossless} ${noalpha}"

if [ "$check" = "true" ]; then
    TEST=check
else
    TEST=run
fi

N=$n
while [ $n -gt 0 ]; do
    for file; do
        $TEST
    done
    n=$((n - 1))
    printf "DONE (%d of %d)\n" $(($N - $n)) $N
done