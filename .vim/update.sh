#!/bin/bash -e
#
# Updates Vim plugins.
#

cd ~/.dotfiles

vimdir=.vim
bundledir=$vimdir/bundle
tmp=/tmp/$LOGNAME-vim-update

# URLS --------------------------------------------------------------------

# This is a list of all plugins which are available via Git repos.
repos=(
  git://git.wincent.com/command-t.git
  https://github.com/altercation/vim-colors-solarized.git
  https://github.com/fholgado/minibufexpl.vim.git
  https://github.com/kchmck/vim-coffee-script.git
  https://github.com/msanders/snipmate.vim.git
  https://github.com/scrooloose/nerdtree.git
  https://github.com/tpope/vim-fugitive.git
  https://github.com/tpope/vim-haml.git
  https://github.com/tpope/vim-markdown.git
  https://github.com/tpope/vim-pathogen.git
  https://github.com/tpope/vim-ragtag.git
  https://github.com/tpope/vim-surround.git
  https://github.com/vim-scripts/Railscasts-Theme-GUIand256color.git
  https://github.com/vim-scripts/ZenCoding.vim.git
  https://github.com/vim-scripts/moria.git
  )

# Here's a list of everything else to download in the format
# <destination>;<url>
other=(
  'vim-fuzzyfinder;https://bitbucket.org/ns9tks/vim-fuzzyfinder/get/tip.zip'
  'zenburn/colors;http://slinky.imukuppi.org/zenburn/zenburn.vim'
  'L9;https://bitbucket.org/ns9tks/vim-l9/get/tip.zip'
  )

case "$1" in

  # GIT -----------------------------------------------------------------
  repos)
    set -x

    for url in ${repos[@]}; do
      dest="$bundledir/$(basename $url | sed -e 's/\.git$//')"

      # Add the submodule if it doesn't already exist. (Using [ -d ] alone
      # isn't a reliable way of checking.
      git submodule add $url $dest || true

      # Ignore any changes in the submodules such as when a plugin compiles its
      # help tags.
      git config submodule.$dest.ignore dirty
    done

    # Init and update everything. Should be idempotent.
    git submodule update --init $bundledir
    git submodule update --rebase $bundledir
    ;;

  # TARBALLS AND SINGLE FILES -------------------------------------------
  other)
    set -x
    rm -rf $tmp
    mkdir $tmp
    pushd $tmp

    for pair in ${other[@]}; do
      parts=($(echo $pair | tr ';' '\n'))
      name=${parts[0]}
      url=${parts[1]}
      dest=$bundledir/$name

      rm -rf $dest

      if echo $url | egrep '.vim$'; then
        # For single files, create the destination directory and download the
        # file there. The filename.
        mkdir -p $dest
        pushd $dest
        curl -OL $url
        popd

      elif echo $url | egrep '.zip$'; then
        # Zip archives from VCS tend to have an annoying outer wrapper
        # directory, so unpacking them into their own directory first makes it
        # easy to remove the wrapper.
        f=download.zip
        curl -L $url >$f
        unzip $f -d $name
        mkdir -p $dest
        mv $name/*/* $dest
        rm -rf $name $f

      else
        # Tarballs: TODO
        echo TODO
      fi

    done

    popd
    rm -rf $tmp
    ;;

  # COMPILING -----------------------------------------------------------
  compile)
    # Some plugins, particularly Command-T, need to be compiled.
    for dir in $bundledir/*/Rakefile; do
      pushd "$(dirname $dir)"
      rake make || true
      popd
    done
    ;;

  # HELP ----------------------------------------------------------------

  all)
    $0 repos
    $0 other
    $0 compile
    ;;

  *)
    set +x
    echo
    echo "Usage: $0 <section>"
    echo "...where section is one of:"
    egrep '\w\)$' $0 | sed -e 's/)//'
    exit 1

esac