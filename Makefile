bindir = /opt/vyatta/bin
sbindir = /opt/vyatta/sbin/
templatesdir = /opt/vyatta/share/vyatta-op/templates
tmplscriptdir = /opt/vyatta/share/tmplscripts
yangdir = /usr/share/configd/yang

cpiop = find  . ! -regex '\(.*~\|.*\.bak\|.*\.swp\|.*\#.*\#\)' -print0 | \
  cpio -0pd

all: ;

install:
	mkdir -p $(DESTDIR)$(bindir)
	install -m 755 -t $(DESTDIR)$(bindir) \
		scripts/vplane-l2tpeth-show.pl
	mkdir -p $(DESTDIR)$(sbindir)
	install -m 755 scripts/vyatta-l2tpeth.pl $(DESTDIR)$(sbindir)
	install -m 755 scripts/vyatta-xconnect.pl $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(templatesdir)
	cd templates && $(cpiop) $(DESTDIR)$(templatesdir)
	mkdir -p $(DESTDIR)$(tmplscritdir)
	cd tmplscripts && $(cpiop) $(DESTDIR)$(tmplscriptdir)
	mkdir -p $(DESTDIR)$(yangdir)
	cd yang && $(cpiop) $(DESTDIR)$(yangdir)
