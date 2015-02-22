CFLAGS = -O3 -Wall
OBJS_BRP = brp.o
HEADERS = brutils.h
LIBS =
TARGET_BRP = brp
BINDIR=/usr/local/bin

all:	$(TARGET_BRP)

$(TARGET_BRP):	$(OBJS_BRP) $(HEADERS)
	$(CC) -o $(TARGET_BRP) $(OBJS_BRP) $(LIBS)

clean:
	rm -f $(OBJS_BRP) $(TARGET_BRP)

install: all
	install -c brp $(BINDIR)

