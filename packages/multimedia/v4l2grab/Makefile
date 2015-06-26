LDLIBS=-ljpeg

MAIN = v4l2grab.c

SOURCES = $(MAIN)
OBJS = $(SOURCES:.c=.o)

.PHONY: all clean install

all: v4l2grab
v4l2grab: $(OBJS)
	$(LINK.c) $^ $(LOADLIBES) $(LDLIBS) -o $@

clean:
	rm -f *.o v4l2grab

INSTALL_DIR = $(DESTDIR)/usr/bin

install: v4l2grab
	mkdir -p $(INSTALL_DIR)
	cp -f v4l2grab $(INSTALL_DIR)

