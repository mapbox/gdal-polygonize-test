# gdal_polygonize.py test case
This test case is intended to evaluate the speed of gdal_polygonize.py.

### Background
The basic test will simply run `gdal_polygonize.py` on the provided raster image and output a shapefile and report the processing time.

For comparison two additional methods can be used wherein the original raster is split into equal-sized chunks (8x8 is default) and then processed in serial or in parallel. Re-unioning the resulting chunks is not included in these processes.

### Sample raster
The provided sample is a 4224x4224 tif that was produced first by running `gdaldem hillshade` and then reducing the colors to 2 using graphicsmagick, resulting in a binary black and white image (0 or 255).

![](https://cloud.githubusercontent.com/assets/843058/6859455/476fe9ba-d3d6-11e4-8f3e-4445e0396f13.jpg)

### Results

Latest results (using GDAL 1.11.1)

method | total time
----- | -----
single | 39.359s
serial | 5.830s
parallel | 2.957s


### Dependencies

 - GDAL >= 1.11.1
 - Python 2.7

Installing on OSX:

`brew install gdal`

Installing on Ubuntu:

`apt-get install gdal-bin`

### Running the test

```
wget https://mapbox-matt.s3.amazonaws.com/gdal-test/11_1444_804.tif
./test.sh [-m {single(default)|serial|parallel|all}]
```
