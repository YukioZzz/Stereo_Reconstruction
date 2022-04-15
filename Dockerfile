FROM ubuntu:18.04 

# Add non root user, add it into sudoers
ARG user_name=yukio
ARG user_uid=1000
ARG user_home=/home/$user_name
ARG user_shell=/bin/bash
ARG ck_dir=$user_home/catkin_ws
ARG ck_src_dir=$ck_dir/src

RUN useradd -m -d $user_home -s $user_shell -u $user_uid $user_name \
    && echo "PS1='\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;33m\]\u\[\033[00m\]@\[\033[01;31m\]\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> ~/.bashrc

RUN apt-get update && apt-get install -qy build-essential apt-utils cmake git libgtk2.0-dev pkg-config libcanberra-gtk-module libcanberra-gtk3-module
RUN true \ 
##        && apt-get update \
        && apt-get install -q -y \
                wget \
                apt-utils \
                gcc-8 g++-8 \
                sudo \
        && apt upgrade -y \
        && apt-get clean -q -y \
        && rm -rf /var/lib/apt/lists/* \
        && echo "%$user_name ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
        && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 100 \
        && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 100 

# opencv
WORKDIR /usr/src/
RUN git clone https://github.com/opencv/opencv.git \
    && git clone https://github.com/opencv/opencv_contrib.git \
    && cd opencv_contrib \
    && git checkout 3.2.0 \
    && cd ../opencv \
    && git checkout 3.2.0 \
    && mkdir build \
    && cd build \
    && cmake -D CMAKE_BUILD_TYPE=Release -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules -D CMAKE_INSTALL_PREFIX=/usr/local .. \
    && make -j4 \
    && make install

# eigen 3.3
WORKDIR /usr/src/
RUN git clone https://gitlab.com/libeigen/eigen.git \
    && cd eigen \
    && git checkout 3.3 \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make install

RUN ln /usr/local/include/eigen3 /usr/include/eigen3 -sf \
    && apt-get update && apt-get install -yq libboost-all-dev libsuitesparse-dev qt5-qmake

# g2o
RUN git clone https://github.com/RainerKuemmerle/g2o.git \
    && cd g2o \
    && git reset --hard eb61932a5c4a33b1dee95ed17b454429ca9e8102 \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make install \
    && cp ../cmake_modules/FindG2O.cmake /usr/share/cmake-3.10/Modules

# Install dependency: ceres 
WORKDIR /usr/src/
RUN apt-get update -q \
    && apt-get install -y libgoogle-glog-dev \
    && git clone --depth 1 --branch 2.1.0 https://ceres-solver.googlesource.com/ceres-solver \
    && cd ceres-solver \
    && git checkout 2.1.0 \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j4 \
    && make install

RUN apt-get install -yq vim

USER $user_name
RUN true \
    && echo "PS1='\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]@\[\033[01;31m\]\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> ~/.bashrc

WORKDIR $user_home
ADD --chown=$user_name:$user_name ./ ./project

# Compile the project
RUN mkdir -p project/build \
    && cd project/build \
    && cmake .. \
    && make

CMD /bin/bash 
