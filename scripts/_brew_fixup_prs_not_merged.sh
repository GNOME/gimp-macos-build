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
# https://github.com/Homebrew/homebrew-core/pull/106654
git cherry-pick 7941db447dc903c621be20a0e8aaeae6252d9089
# poppler
# https://github.com/Homebrew/homebrew-core/pull/106665
git cherry-pick a0d2522d0c174f1ddfb1485909f957fac4824169
popd
