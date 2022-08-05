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
# https://github.com/Homebrew/homebrew-core/pull/106658
# gsettings-desktop-schemas
git cherry-pick 5f6eda4a0fc468e92c49f20c0b48fb85a37ad9b6
# poppler
# https://github.com/Homebrew/homebrew-core/pull/106665
git cherry-pick 0129523ec1026a9f8ba0a22c393db03055360bef
popd
