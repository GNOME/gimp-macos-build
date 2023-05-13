## How to Patch a Port on Your System

Modified from: https://trac.macports.org/wiki/howto/PatchLocal

- Audience: People who want to change the code of an existing port
- Requires: MacPorts >= 2.1.2?

## Introduction

If you've ever found a port that doesn't work, then found a patch for it with Google, the next step is to apply the patch to the source code, then compile, test, and install the new version of the port so you can use it and get on with your work. This HOWTO will show you how to do that. In this example, I'll be using the 'arb' program as an example.

## Installation

### Step 1: Set up a local repository

If you want to make changes that stick and won't be overwritten by accident, you need to set up a local repository, described in full here: ​http://guide.macports.org/#development.local-repositories

Do this to create a new Port (as root):

```sh
mkdir -p ~/mac_ports
```

Create the port's category directory (using port "arb" as an example):

```sh
port=arb
PORT_CATEGORY=`port dir ${port} | awk -F\/ '{ print $(NF-1) }'`
mkdir ~/mac_ports/$PORT_CATEGORY
cd ~/mac_ports/$PORT_CATEGORY
cp -r `port dir ${port}` .
mv ${port} ${port}-devel
# edit ${port}-devel/Portfile and replace "name arb" with "name arb-devel", and 
#   create two new lines, one defining "distname arb-${version}", overriding the 
#   default of ${name}-${version}, and one defining "dist_subdir arb",
#   overriding the default of ${name}, otherwise the fetch  will fail to 
#   find the distfile, because it will be including the "-devel" as part of 
#   the path and distfile on the mirror site
cd ${port}-devel
port lint # to check for problems
```

Add this line before the 'rsync://.......' line in `/opt/local/etc/macports/sources.conf`, at the end of the file:

```
file:///Users/lukasoberhuber/mac_ports
```

Then run this command:

```sh
cd ~/mac_ports && portindex
```

Step 2: Get your port's sourcecode

```sh
sudo port patch ${port}-devel
cd `port work ${port}-devel`
```

Step 3: Modify the source with your patch

```sh
cp Makefile Makefile.orig
vi Makefile
* make changes, compile it, test it *
```

Step 4: Make a patch

See [​http://guide.macports.org/#development.patches.source](​http://guide.macports.org/#development.patches.source)

```sh
diff -u Makefile.orig Makefile > `port dir ${port}-devel`/files/patch-ARB-makefile2.diff
port edit ${port}-devel # (add the patch-ARB-makefile2.diff file to the list of patches)
```

Step 5: Test the modified port

```sh
# leave work dir to ensure that the port clean isn't trying to remove an in-use 
# directory and make the build fail
cd ~/mac_ports
port clean ${port}-devel
port build ${port}-devel
```

Step 6: Make it real

```sh
port -s install ${port}-devel
```
