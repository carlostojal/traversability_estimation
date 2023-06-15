FROM carlostojal/cuda-ros:noetic-cuda12.1.1-ubuntu20.04

# environment variables
ENV DEBIAN_FRONTEND=noninteractive

# install dependencies
RUN apt update
RUN apt install -y \
    build-essential \
    python3 \
    python3-pip \
    python3-catkin-tools \
    python3-rosdep \
    libpcl-dev \
    libopencv-dev \
    libeigen3-dev \
    vim \
    git \
    xauth \
    wget \
    doxygen \
    ffmpeg \
    libsm6 \
    libxext6 \
    libfontconfig1 \
    libxrender1 \
    libswscale-dev \
    libtbb2 \
    libtbb-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libavformat-dev \
    libpq-dev \
    libturbojpeg \
    software-properties-common \
    libboost-all-dev \
    libssl-dev \
    libgeos-dev \
    nano \
    sudo \
    python3-matplotlib \
    python3-opencv \
    python3-tk \
    python3-vcstool \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install python packages
RUN pip3 install \
    tqdm==4.62.3 \
    yacs==0.1.6 \
    #open3d==0.11.2 \
    gnupg==2.3.1 \
    configparser==5.2.0 \
    psutil==5.8.0 \
    rospkg \
    empy \
    torch \
    torchvision

# it calls "python" but it is python3. create a symbolic link
RUN ln -s /usr/bin/python3 /usr/bin/python

# init rosdep
RUN rosdep init
RUN rosdep update
RUN apt update

# copy the ros package
RUN mkdir -p /catkin_ws/src/traversability_estimation/weights/depth_cloud
COPY . /catkin_ws/src/traversability_estimation

# get the neural network weights
WORKDIR /catkin_ws/src/traversability_estimation/weights/depth_cloud
# RUN wget http://subtdata.felk.cvut.cz/robingas/data/traversability_estimation/weights/depth_cloud/deeplabv3_resnet101_lr_0.0001_bs_8_epoch_90_TraversabilityClouds_depth_labels_traversability_iou_0.972.pth

# get cloud_proc
WORKDIR /catkin_ws/src
RUN git clone https://github.com/ctu-vras/cloud_proc.git
WORKDIR /catkin_ws

# install dependencies
RUN rosdep install --from-paths /catkin_ws --ignore-src --rosdistro noetic -y
# build
RUN /bin/bash -c "source /opt/ros/noetic/setup.bash && \
    cd /catkin_ws && \
    catkin build"

# launch the aggregator
CMD /bin/bash -c "source /opt/ros/noetic/setup.bash && \
    source /catkin_ws/devel/setup.bash && \
    roslaunch traversability_estimation semantic_traversability.launch"