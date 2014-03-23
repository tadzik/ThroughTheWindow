LIBS=$(shell sdl2-config --libs)
CFLAGS=$(shell sdl2-config --cflags)

all: sdlwrapper.so

sdlwrapper.so: sdlwrapper.c
	cc -c -fPIC -o sdlwrapper.o  -pipe -fstack-protector $(CFLAGS) -I/usr/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE -DHASATTRIBUTE_CONST  -DHASATTRIBUTE_DEPRECATED  -DHASATTRIBUTE_MALLOC  -DHASATTRIBUTE_NONNULL  -DHASATTRIBUTE_NORETURN  -DHASATTRIBUTE_PURE  -DHASATTRIBUTE_UNUSED  -DHASATTRIBUTE_WARN_UNUSED_RESULT  -DHASATTRIBUTE_HOT  -DHASATTRIBUTE_COLD  -DDISABLE_GC_DEBUG=1 -DNDEBUG -DHAS_GETTEXT   sdlwrapper.c
	cc -shared -O2 -L/usr/local/lib -fstack-protector -fPIC  -fstack-protector -L/usr/local/lib -lnsl -ldl -lm -lcrypt -lutil -lpthread -lrt -lreadline  -lffi -o sdlwrapper.so sdlwrapper.o $(LIBS)
	rm -f sdlwrapper.o
	cp sdlwrapper.so sdlwrapperlib.so

clean:
	rm -f *.so
