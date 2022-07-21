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
git cherry-pick fa4bec6 61074f9
popd
