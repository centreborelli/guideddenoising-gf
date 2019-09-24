# Guided Filter

To execute this program you only need [GNU Octave](https://www.gnu.org/software/octave/), a C compiler and the make program. All the rest is included.


## Installation

First we need to install the image package from Octave. Start Octave by typing `octave` in a terminal. Then, simply do
```
pkg install image
```
from the Octave prompt.

Then we need to compile the mex files that make the interface between Octave and [iio](https://github.com/mnhrdt/iio). Simply type
```bash
make -C iio
```
This will create the files `iio/iio_read.mex` and `iio/iio_write.mex` which are used to read and write images.


## Usage

Print the program's help by calling it without arguments
```
./denoise_with_gf.m
```
this outputs:
```
./denoise_with_gf input guide output epsilon radius
- input  : path to input image
- guide  : path to guide image use "NULL" if no guide
- output : path to output *directory* (created if needed)
- sqrteps: square-root of epsilon: amount of smoothing, in (0,255]
- radius : patch size = (2*radius+1)^2
```

All common image formats can be read and written, and some less common too. In particular, floating point tiff images are handled.

Each of the `n` channels of the input image are filtered using the `n + m` channels available, where `m` is the number of channels of the guide image (when no guide is provided `m = 0`). In this program the maximal value for `n + m` is 3.

The filtered image is saved in the given output directory with the same name as the input image.


## Example

Let's say we have a directory called `in` with the images `image_vis.tif` and `image_ir.tif` inside.
We can denoise it by running:
```
./denoise_with_gf.m in/image_vis.tif NULL out 52 7
```
or using a guide by running:
```
./denoise_with_gf.m in/image_vis.tif in/image_ir.tif out 52 7
```
In both cases the output image is `out/image_vis.tif`.


