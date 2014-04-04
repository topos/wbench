help:; @echo "make install"

install: pkgs fonts emacs gems

PKGS = ruby ruby-dev rake ksh fvwm git diffuse source-highlight flex bison g++-4.8
pkgs: aptitude
	for p in ${PKGS}; do sudo aptitude install -y $$p; done
	sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 20
	sudo update-alternatives --config gcc
	sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 20
	sudo update-alternatives --config g++

aptitude:; sudo apt-get install -y aptitude

LIBS = libgconf2-4 libgconf2-dev libnss3-dev libnss3-1d libnss3-tools libudev-dev libxss-dev libxss-dev libxml2-dev libncurses-dev libgpm-dev libgmp10-dev libgmp10 libmpfr-dev libmpc-dev libisl-dev libcloog-isl-dev
libs:
	for p in ${LIBS}; do sudo aptitude install -y $$p; done

FONTS = ttf-mscorefonts-installer
fonts:
	for p in ${FONTS}; do sudo aptitude install -y $$p; done
	sudo aptitude install -y edubuntu-fonts emacs-intl-fonts xfonts-100dpi xfonts-100dpi-transcoded xfonts-75dpi xfont-75dpi-transcoded gsfont gsfonts-other gsfonts-x11
	sudo fc-cache -f -v

update:; sudo aptitude update -y

upgrade:; sudo aptitude upgrade -y

full-upgrade:; sudo aptitude full-upgrade -y

aptitude:; sudo apt-get install -y aptitude
emacs:; sudo aptitude install -y emacs24 emacs24-el emacs-goodies-el emacs-goodies-extra-el

java:;	sudo add-apt-repository ppa:webupd8team/java
	sudo aptitude update -y
	sudo aptitude install -y oracle-java8-installer

ghc:; sudo aptitude install -y ghc libghc-cabal-dev cabal-install haskell-mode

postgresql:
	sudo aptitude install -y postgresql postgresql-client postgresql-server-dev-9.1 libpq-dev

media: media-ppa
	sudo aptitude install -y non-free-codecs libdvdcss

media-ppa:; sudo -E wget --output-document=/etc/apt/sources.list.d/medibuntu.list http://www.medibuntu.org/sources.list.d/$$(lsb_release -cs).list && sudo apt-get --quiet update && sudo apt-get --yes --quiet --allow-unauthenticated install medibuntu-keyring && sudo apt-get --quiet update

# nvidia:
# 	cd /tmp && sudo apt-get --purge remove xserver-xorg-video-nouveau
# 	cd /tmp && sudo sudo service lightdm stop
# 	cd /tmp && wget -c us.uk.download.nvidia.com/XFree86/Linux-x86_64/319.17/NVIDIA-Linux-x86_64-319.17.run
# 	cd /tmp && sudo chmod +x NVIDIA-Linux-x86-319.17.run && sudo ./NVIDIA-Linux-x86-319.17.run
# -alternative -
# sudo apt-add-repository ppa:ubuntu-x-swat/x-updates
# sudo apt-get update
# sudo apt-get install nvidia-current


dev: tools
	for i in $$(aptitude search -F '%p' x11|grep dev|grep -v :i386|grep -v libhgc); do sudo aptitude install -y $$i; done
	sudo aptitude install -y libtiff-dev libtiff-tools libjpeg8-dev libgif-dev libxpm-dev
	sudo aptitude install -y xserver-xorg-input-mtrack
	sudo aptitude install -y ubuntu-dev-tools libgmp3-dev libgmp-dev libmpfr-dev libmpc-dev bison flex gcc-multilib xz-utils
	sudo aptitude install -y freeglut3-dev

dev-info:; aptitude search -F '%p' x11|grep dev|grep -v :i386|grep -v libhgc


tools:;	sudo aptitude install -y curl wget imagemagick graphicsmagick-imagemagick-compat

default-keyboard:
	sudo cp keyboard /etc/default/keyboard
	sudo dpkg-reconfigure -phigh console-setup

gemrc:; echo 'gem: --no-ri --no-rdoc' >> ~/.gemrc

GEMS=rake smart_colored
gems:
	@for i in ${GEMS}; do \
		gem=$$(echo $$i|sed 's/:/ -v /1'); \
		echo $$gem; \
	if [ "$$(gem list --local -i $$gem)" = "false" ]; then sudo gem install --no-ri --no-rdoc $$gem; fi \
	done

buildr:
	@if [ "$$(gem list --local -i $@)" = "false" ]; then \
		if [ -z "${JAVA_HOME}" ]; then \
			sudo env JAVA_HOME=/usr/lib/jvm/java-6-sun gem install --no-ri --no-rdoc $@; \
		else \
			sudo gem install --no-ri --no-rdoc $@; \
		fi; \
	fi

sudo:; sudo cp ml.sudo /etc/sudoers.d/ml

clean:
	sudo apt-get autoremove -y unity-lens-shopping
	sudo apt-get autoremove -y unity-lens-music
	sudo apt-get autoremove -y unity-lens-photos
	sudo apt-get autoremove -y unity-lens-gwibber
	sudo apt-get autoremove -y unity-lens-video
	sudo aptitude clean -y && sudo aptitude autoclean -y

remove: clean
	sudo apt-get autoremove --purge unity unity-common unity-services unity-lens-* unity-scope-* unity-webapps-* gnome-control-center-unity hud libunity-core-6* libunity-misc4 libunity-webapps* appmenu-gtk appmenu-gtk3 appmenu-qt* overlay-scrollbar* activity-log-manager-control-center firefox-globalmenu thunderbird-globalmenu libufe-xidgetter0 xul-ext-unity xul-ext-webaccounts webaccounts-extension-common xul-ext-websites-integration
