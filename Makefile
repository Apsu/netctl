export VERSION = 0.1

.PHONY: install install-docs docs tarball pkgbuild clean

install: install-docs
	# Configuration files
	install -d $(DESTDIR)/etc/network.d/{examples,hooks,interfaces}
	install -m644 docs/examples/* $(DESTDIR)/etc/network.d/examples/
	# Libs
	install -d $(DESTDIR)/usr/lib/network/connections
	install -m644 src/lib/{8021x,globals,ip,rfkill} $(DESTDIR)/usr/lib/network/
	install -m644 src/lib/connections/* $(DESTDIR)/usr/lib/network/connections/
	install -m755 src/lib/{auto.action,network} $(DESTDIR)/usr/lib/network/
	# Scripts
	install -d $(DESTDIR)/usr/bin
	install -m755 \
	    src/netctl \
	    src/netctl-auto \
	    src/wifi-menu \
	    $(DESTDIR)/usr/bin/
	install -Dm755 src/ifplugd.action $(DESTDIR)/etc/ifplugd/netctl.action
	# Services
	install -d $(DESTDIR)/usr/lib/systemd/system
	install -m644 services/*.service $(DESTDIR)/usr/lib/systemd/system/

install-docs: docs
	install -d $(DESTDIR)/usr/share/man/{man1,man5,man7}
	install -m644 docs/*.1 $(DESTDIR)/usr/share/man/man1/
	install -m644 docs/*.5 $(DESTDIR)/usr/share/man/man5/
	install -m644 docs/*.7 $(DESTDIR)/usr/share/man/man7/

docs:
	$(MAKE) -C $@

tarball: netctl-$(VERSION).tar.xz
netctl-$(VERSION).tar.xz: | docs
	cp src/netctl{,.orig}
	sed -i "s/NETCTL_VERSION=.*/NETCTL_VERSION=$(VERSION)/" src/netctl
	git stash save -q
	git archive -o netctl-$(VERSION).tar --prefix=netctl-$(VERSION)/ stash
	git stash pop -q
	mv src/netctl{.orig,}
	tar --exclude-vcs --transform "s%^%netctl-$(VERSION)/%" --owner=root --group=root --mtime=./netctl-$(VERSION).tar -rf netctl-$(VERSION).tar docs/*.[1-8]
	xz netctl-$(VERSION).tar

pkgbuild: PKGBUILD
PKGBUILD: netctl-$(VERSION).tar.xz
	sed -e "s/%pkgver%/$(VERSION)/" -e "s/%md5sum%/$(shell md5sum $< | cut -d ' ' -f 1)/" contrib/PKGBUILD > $@

clean:
	$(MAKE) -C docs clean
	-@rm -vf PKGBUILD *.xz 2>/dev/null

