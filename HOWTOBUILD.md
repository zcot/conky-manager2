# How to build this software. It was tested on Mint 18.x and 19 versions, but will probably build just the same on the various *ubuntu systems too.

## additional required packages to build:
 build-essential
 git
 valac
 libgee-0.8-dev
 libgtk-3-dev
 libjson-glib-dev
 gettext
 libgettextpo-dev

## additional required run time packages:
 p7zip-full
 imagemagick

## here is a one-shot installation command for all of the above packages:
```
apt install build-essential git valac libgee-0.8-dev libgtk-3-dev libjson-glib-dev gettext libgettextpo-dev p7zip-full imagemagick
```


## clone this repository
the following command will create a subdirectory from whatever directory you are currently in called conky-manager2 then download the files from github and put them in that subdirectory:
```
git clone https://github.com/zcot/conky-manager2.git
```

## change the directory to that source code location:
```
cd conky-manager2
```

## compile the source:
```
make
```
( follow instructions here to build a `.deb` file instead: https://gist.github.com/zcot/ff43f40ceaf970623bfd18ead1bd65b2 )
## install the finished program into the local file system:
```
sudo make install
```

## can be uninstalled as follows:
```
sudo make uninstall
```



