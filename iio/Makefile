# MEX   = mex                # for matlab
MEX     = mkoctfile --mex    # for octave

LDLIBS  = -lpng -ltiff -ljpeg
CFLAGS  = -fPIC

BIN     = iio_read.mex iio_write.mex

default : $(BIN)

%.mex   : %.c iio.o ; $(MEX) $< iio.o $(LDLIBS)

clean   :           ; $(RM) *.o *.mex
