# ROS Noetic + Gazebo 11 + OCS2 image for running legged_control in simulation.
# OCS2 is built into the image (/opt/ocs2_ws); legged_control itself is built
# from the host-mounted ~/src in a catkin workspace that extends it.

# ros:noetic-ros-base-focal is multi-arch (amd64 + arm64); osrf/ros:noetic-desktop-full is amd64-only.
# desktop-full (incl. Gazebo 11) is installed from apt below and is published for both archs.
ARG BASE_IMAGE=ros:noetic-ros-base-focal
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-c"]
ARG DEBIAN_FRONTEND=noninteractive

##### System + ROS dependencies #####
RUN apt-get update -q && \
    apt-get install -y --no-install-recommends \
        build-essential cmake git sudo tini vim wget curl \
        bash-completion python3-catkin-tools python3-osrf-pycommon \
        liburdfdom-dev liboctomap-dev libassimp-dev \
        libglpk-dev libgmp-dev libmpfr-dev libyaml-cpp-dev \
        mesa-utils x11-apps xauth \
        ros-noetic-desktop-full \
        ros-noetic-octomap-msgs \
        ros-noetic-grid-map-msgs \
        ros-noetic-ros-control \
        ros-noetic-ros-controllers \
        ros-noetic-gazebo-ros-control \
        ros-noetic-rqt-controller-manager \
        ros-noetic-realtime-tools \
        ros-noetic-angles \
        ros-noetic-xacro \
        ros-noetic-joy \
        ros-noetic-teleop-twist-keyboard && \
    rm -rf /var/lib/apt/lists/*

##### OCS2 (only ocs2_legged_robot_ros + self-collision and their deps) #####
# Pinned to what legged_control (last code change 2024-01) was developed against:
#   ocs2        164c26b4  last code commit on main (2023-10-02); later commits are docs only
#   pinocchio   b86197e0  leggedrobotics fork master (v2.5.1 + catkin package.xml)
#   hpp-fcl     8be41cba  leggedrobotics fork master (catkin package.xml)
#   ocs2_robotic_assets   v10.3
ARG OCS2_SHA=164c26b46bed5d24cd03d90588db8980d03a4951
ARG PINOCCHIO_SHA=b86197e04265892c32966736000a01ee4862a060
ARG HPP_FCL_SHA=8be41cba990eaef717bd4d2b4a7bb05c8ae66ccd
ARG ASSETS_SHA=b126d00d55f1e67905c3c1516995466df6873c5c
ARG CMAKE_CLANG_TOOLS_SHA=8bffee02eaa1a6d5391da5f6aa4b9afffd39c995
ARG CATKIN_JOBS=8
RUN mkdir -p /opt/ocs2_ws/src && cd /opt/ocs2_ws/src && \
    clone() { git clone -q $1 $2 && git -C $2 checkout -q $3 && git -C $2 submodule update -q --init --recursive; } && \
    clone https://github.com/leggedrobotics/ocs2.git ocs2 ${OCS2_SHA} && \
    clone https://github.com/leggedrobotics/pinocchio.git pinocchio ${PINOCCHIO_SHA} && \
    clone https://github.com/leggedrobotics/hpp-fcl.git hpp-fcl ${HPP_FCL_SHA} && \
    clone https://github.com/leggedrobotics/ocs2_robotic_assets.git ocs2_robotic_assets ${ASSETS_SHA} && \
    clone https://github.com/ANYbotics/cmake_clang_tools.git cmake_clang_tools ${CMAKE_CLANG_TOOLS_SHA}

RUN cd /opt/ocs2_ws && source /opt/ros/noetic/setup.bash && \
    catkin init && \
    catkin config --extend /opt/ros/noetic -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    catkin build ocs2_legged_robot_ros ocs2_self_collision_visualization \
        -j ${CATKIN_JOBS} -p 2 --no-status --summarize && \
    rm -rf /opt/ocs2_ws/build /opt/ocs2_ws/logs

##### User matching the host UID/GID so files in mounted ~/src keep ownership #####
ARG USER_NAME=ubuntu
ARG USER_PASSWD=ubuntu
ARG USER_UID=1000
ARG USER_GID=1000
# -l: skip lastlog/faillog (huge sparse files with large domain UIDs)
RUN (getent group ${USER_GID} || groupadd -g ${USER_GID} ${USER_NAME}) && \
    useradd -l -m -s /bin/bash -u ${USER_UID} -g ${USER_GID} -G sudo,video ${USER_NAME} && \
    echo "${USER_NAME}:${USER_PASSWD}" | chpasswd

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER ${USER_NAME}
WORKDIR /home/${USER_NAME}
RUN mkdir -p src && { \
      echo "source /opt/ros/noetic/setup.bash"; \
      echo "source /opt/ocs2_ws/devel/setup.bash"; \
      echo "[ -f \$LEGGED_WS/devel/setup.bash ] && source \$LEGGED_WS/devel/setup.bash"; \
      echo "export ROBOT_TYPE=\${ROBOT_TYPE:-a1}"; \
    } >> ~/.bashrc

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
