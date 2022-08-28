if [[ $(uname -m) == 'arm64' ]]; then
  build_arm64=true
  echo "*** Build: arm64"
  PREFIX=$HOME/homebrew
else
  build_arm64=false
  echo "*** Build: x86_64"
  PREFIX=$HOME/homebrew_x86_64
fi

pushd ${PREFIX}/Library/Taps/homebrew/homebrew-core
git remote add lukaso git@github.com:lukaso/homebrew-core.git
git fetch lukaso
# libunistring
# https://github.com/Homebrew/homebrew-core/pull/109128
git cherry-pick 9fee4fb5b5ece28da26a5e92027573c797100441
# poppler
# https://github.com/Homebrew/homebrew-core/pull/106665
git cherry-pick 7dfe8ca1cd8410b9019a1469614c2fb58c911f76
popd
