# MacPorts

## How to overlay a port in this repo.

### Get the port

1. You can find the port you want to overlay in the [MacPorts Port Index](https://ports.macports.org/). Navigate to the port you want to overlay and copy the URL from the address bar. The URL should look something like this: `https://ports.macports.org/port/<category>/<port>/`.
2. Plug the URL into this page https://download-directory.github.io/?url=https://github.com/macports/macports-ports/tree/master/graphics/fontconfig
3. Download the zip file and extract it to the `ports/<category>/<port>` directory in this repo.

### Get the patch

In order to get the patch, you need to find the relevant merge request or commit in the upstream repository. Both github and gitlab allow you to download a patch file directly from the web interface.

#### GitHub

https://dilankam.medium.com/creating-a-patch-from-github-pull-request-a0381fb3606d

1. Navigate to the pull request or commit you want to use as a patch.
2. Add `.patch` to the end of the URL and hit enter.
3. Copy the contents of the page and save it to a file in the `ports/<category>/<port>/files` directory.

#### GitLab

1. Navigate to the merge request or commit you want to use as a patch.
2. Click on the "Changes" tab.
3. To the right, click the "Code" button and under "Download" select "patches".

### Fix the patch

1. Copy the patch file to the `ports/<category>/<port>/files` directory.
2. Open the patch file in a text editor
3. Remove all references to `a/` and `b/` in the patch file. For example, change:
   ```diff
   --- a/src/file.c
   +++ b/src/file.c
   ```
   to:
   ```diff
   --- src/file.c
   +++ src/file.c
   ```
4. Save the file.

This is because most Portfiles do applys without the `a/` and `b/` prefixes.

### Modify the port

1. Open the `Portfile` in a text editor.
2. Change revision to one number highter than the current revision. For example, if the current revision is `0`, change it to `1`. This ensures your overlay is picked up. If you want to be super sure, change add `epoch 1` instead. Or up that if there's an epoch already.
3. Add the patch file to a `patchfiles-append` line after existing ones (if any). Otherwise relatively early in the Portfile. For example:
   ```tcl
   # Remove this overlay when <link to MR or commit> is merged
   patchfiles-append my-fix.patch
   ```

### Finish

That's it. Now create an MR and test that it worked. You will know your version was used if the revision number is higher than the one in the official MacPorts repository. All port versions are printed in SBOM.txt files after a build (as well as in the dependency builds).

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
