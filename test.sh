#!/usr/bin/env bash
set -eu

function usage() {
    echo -n "$0

USAGE: $0 [options] [tif]

OPTIONS:
-h
    Display this help message.
-m {all|single|serial|parallel}
    Processing method.
    single = process whole raster file (default)
    serial = split raster (8x8) processed one-at-a-time
    parallel = split raster (8x8) processed all at once
    all = all of the above
"
}

function get_opts() {

    # defaults
    METHOD=single

    while getopts ":hm:" opt; do
        case $opt in
            h)  usage; exit;;
            m)  METHOD=$OPTARG;;
            \?) error "Invalid option '$OPTARG'";;
        esac
    done
    ARGC=$(($#-(OPTIND-1)))
    shift $((OPTIND-1))

    if [[ $METHOD != 'all' ]] \
            && [[ $METHOD != 'single' ]] \
            && [[ $METHOD != 'serial' ]] \
            && [[ $METHOD != 'parallel' ]]; then
        error "Unknown output mode '$METHOD'."
    fi

    if [[ $ARGC -eq 1 ]]; then
        INPUT=${1:-0}
    else
        INPUT="11_1444_804.tif"
    fi
}

# test single file
function single_file() {
    gdal_polygonize.py -q \
        $RASTER -f "ESRI Shapefile" \
        ${OUTPUT}.shp
}

# test chunks in serial
function in_serial() {
    ./split.sh $RASTER $XCHUNKS $YCHUNKS

    for x in $(eval echo {0..$(($XCHUNKS-1))}); do
        for y in $(eval echo {0..$(($YCHUNKS-1))}); do
            gdal_polygonize.py -q \
                input/${x}_${y}.tif -f "ESRI Shapefile" \
                ${OUTPUT}_serial_${x}_${y}.shp
        done
    done
}

# test chunks in parallel using Pool
function in_parallel() {
    ./split.sh $RASTER $XCHUNKS $YCHUNKS

    python -c "if True:
        from multiprocessing import Pool
        import subprocess

        chunks = []
        for x in range(0, $(($XCHUNKS-1))):
            for y in range(0, $(($YCHUNKS-1))):
                chunks.append(str(x) + '_' + str(y))

        def polygonize(chunk):
            subprocess.call([
                'gdal_polygonize.py -q \
                input/'+chunk+'.tif -f \"ESRI Shapefile\" \
                ${OUTPUT}_parallel_'+chunk+'.shp'
            ], shell=True)

        if __name__ == '__main__':
            pool = Pool()
            pool.map(polygonize, chunks)"
}

function main() {

    get_opts $@

    # setup
    if [[ -d input ]]; then
        rm -r input
    fi
    if [[ -d output ]]; then
        rm -r output
    fi
    mkdir -p input
    mkdir -p output
    OUTPUT=output/out
    RASTER=input/${INPUT%.*}.vrt

    XCHUNKS=8
    YCHUNKS=8

    # make VRT, white=nodata
    gdal_translate -q -a_nodata 255 -of VRT $INPUT $RASTER

    # single
    if [[ $METHOD = 'all' ]] || [[ $METHOD = 'single' ]]; then
        echo "Testing $INPUT as a single file:"
        echo -e "Done! \n" $( TIMEFORMAT="TIME: %Rs"; { time single_file; } 2>&1 ) "\n"
    fi

    # serial
    if [[ $METHOD = 'all' ]] || [[ $METHOD = 'serial' ]]; then
        echo "Testing $INPUT in serial:"
        echo -e "Done! \n" $( TIMEFORMAT="TIME: %Rs"; { time in_serial; } 2>&1 ) "\n"
    fi

    # parallel
    if [[ $METHOD = 'all' ]] || [[ $METHOD = 'parallel' ]]; then
        echo "Testing $INPUT in parallel:"
        echo -e "Done! \n" $( TIMEFORMAT="TIME: %Rs"; { time in_parallel; } 2>&1 )
    fi
}

main $@
