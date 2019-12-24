# Getting Started

## Requirements

* Matlab with Signal Processing toolbox. Should work on Matlab R2014b or newer.
* The [PhysioNet WFDB tools](https://www.physionet.org/physiotools/wfdb.shtml).
  The toolbox can install this for you.

## Installation

1. Clone the [repo](https://github.com/physiozoo/mhrv) or download the source code.

2. From matlab, run the `mhrv_init` function from the root of the repo. This
   function will:

    * Check for the presence of the WFDB tools in your system `PATH`.
    * If WFDB tools are not detected, it will attempt to automatically download
      them for you into the folder `bin/wfdb` under the repository root.
    * Set up your MATLAB path to include the code from this toolbox.

### Notes about matlab's `pwd` and `path`

Matlab maintains a PWD, or "present working directory". It's the folder you see
at the top of the interface, containing the files you see in the file explorer
pane. Type `pwd` at the matlab command prompt to see it's value.

Additionally, matlab maintains a PATH variable, containing a list of folders in
which it searches for function definitions (similar to the shell PATH concept).
Type `path` at the matlab command prompt to see it's value.

You don't need to change your `pwd` to the root of the repo folder for the
toolbox to work. You can simple run the `mhrv_init` function from your current
`pwd`, and it will take care of updating matlab's path. For example, if you
cloned or downloaded the toolbox in the folder `/Users/myname/mhrv/`, you can
run the following command from the matlab prompt:

```matlab
run /Users/myname/mhrv/mhrv_init.m
```

After this the toolbox will be ready to use, regardless of your `pwd`.

### Manual WFDB Installation (Optional)

The above steps should be enough to get most users started.
In some cases `mhrv_init` may fail to download the correct binaries for you, or
you may want to install them yourself.

  * On macOS, you can use [homebrew](http://brew.sh). First install homebrew,
    then install `wfdb` with `brew tap brewsci/science && brew install wfdb`.
  * On any OS (including macOS), you can compile the WFDB binaries [from
    source](https://archive.physionet.org/physiotools/wfdb.shtml)
    using the instructions on their website.

Once you have the binaries, place them in some folder on your `$PATH` or
somewhere under the repo's root folder (`bin/wfdb` would be a good choice as it's
`.gitignore`d) and they will be found and used automatically.
You can replace the binaries that were automatically downloaded with your
compiled ones. If you used homebrew, they should already be on your `$PATH`.

If you would like to manually specify a path outside the repo which contains the
WFDB binaries (e.g. `/usr/local/bin` for a homebrew install), you can edit
[`cfg/defaults.yml`](https://github.com/physiozoo/mhrv/blob/master/cfg/defaults.yml)
and set the `mhrv.paths.wfdb_path` variable to the desired path.

For macOS users it's recommended to install with homebrew, and 
for linux users it's recommended to install from source, as the binaries provided
on the PhysioNet website are very outdated.
