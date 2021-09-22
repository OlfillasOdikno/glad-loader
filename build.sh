#!/bin/bash

for i in "$@"; do
  case $i in
    --linux* | --win*) arch=${i#--};;
    --docker-image) docker=true; image=true ci=false;;
    --docker) docker=true; image=false ci=false;;
    --ci) docker=true; image=false ci=true;;
  esac
done

archs=(
  "linux32"
  "linux64"
  "win32"
  "win64"
  "linuxarmhf"
)

hosts=(
  ""
  ""
  "i686-w64-mingw32"
  "x86_64-w64-mingw32"
  "arm-linux-gnueabihf"
)

ccflags=(
  "-m32"
  "-m64"
  "-m32"
  "-m64"
  ""
)

if [ "$docker" = true ]; then
  if [ "$image" = true ]; then
    for i in ${!archs[@]}; do
      if [ ! -z ${arch} ] && [ ! ${archs[$i]} = ${arch} ]; then
        continue
      fi
      docker build -t glad-builder:${archs[$i]} - < docker/${archs[$i]}.Dockerfile
    done
  else
    for i in ${!archs[@]}; do
      if [ ! -z ${arch} ] && [ ! ${archs[$i]} = ${arch} ]; then
        continue
      fi
      if [ "$ci" = true ]; then
        docker run --rm -tv jenkins_home:/var/jenkins_home -w "$(pwd)" glad-builder:${archs[$i]} ./build.sh "--${archs[$i]}"
      else
        docker run --rm -tv "$(pwd)":/work -w /work glad-builder:${archs[$i]} ./build.sh "--${archs[$i]}"
      fi
    done
  fi
  exit
fi

for i in ${!archs[@]}; do
  if [ ! -z ${arch} ] && [ ! ${archs[$i]} = ${arch} ]; then
    continue
  fi

  mkdir -p "obj/${archs[$i]}"
  mkdir -p "lib/${archs[$i]}"

  prefix=`[ ! -z ${hosts[$i]} ] && echo ${hosts[$i]}-`
  ${prefix}gcc ${ccflags[$i]} -Iinclude -c src/gl.c -o obj/${archs[$i]}/gl.o
  ${prefix}gcc ${ccflags[$i]} -Iinclude -c src/egl.c -o obj/${archs[$i]}/egl.o
  ${prefix}gcc ${ccflags[$i]} -Iinclude -c src/vulkan.c -o obj/${archs[$i]}/vulkan.o
  ${prefix}ar crs lib/${archs[$i]}/libglad-static.a obj/${archs[$i]}/gl.o obj/${archs[$i]}/egl.o obj/${archs[$i]}/vulkan.o
  ${prefix}strip --strip-unneeded lib/${archs[$i]}/libglad-static.a
done
