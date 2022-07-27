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
# https://github.com/Homebrew/homebrew-core/pull/105614
# ghostscript
git cherry-pick bdfcd5ec34a74ca20e0d30e109164d7d585ee951
# https://github.com/Homebrew/homebrew-core/pull/106654
# libunistring
git cherry-pick 60360d41ecf75e7afe9164babcf1914a17d9d3d6
popd
