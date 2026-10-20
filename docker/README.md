# legged_control in Docker (ROS Noetic + Gazebo 11)

The image ships ROS Noetic desktop-full (Gazebo 11) and a prebuilt OCS2 workspace at `/opt/ocs2_ws`.
`legged_control` itself is **not** baked in: `~/src` on the host is mounted to `~/src` in the container,
and you build it there in `~/src/wei-hsuan-cheng/legged_ws` (extends `/opt/ocs2_ws`).

Works on **amd64 and arm64** (base image `ros:noetic-ros-base-focal` is multi-arch).

## Pinned dependency versions

| Repo | Commit | Why |
|------|--------|-----|
| leggedrobotics/ocs2 | `164c26b4` | last code commit on `main` (2023-10); later commits are docs only |
| leggedrobotics/pinocchio | `b86197e0` | fork `master` = v2.5.1 + catkin `package.xml` |
| leggedrobotics/hpp-fcl | `8be41cba` | fork `master` with catkin `package.xml` |
| leggedrobotics/ocs2_robotic_assets | `v10.3` | |
| ANYbotics/cmake_clang_tools | `8bffee02` | listed as a dependency by OCS2/legged_control packages |

## 1. Build the image

```bash
cd ~/src/wei-hsuan-cheng/legged_control/docker
HOST_UID=$(id -u) HOST_GID=$(id -g) docker compose build
```

On an arm64 machine (e.g. Jetson) the same command builds natively.

## 2. Start the container

```bash
xhost +local:docker            # allow GUI windows (Gazebo/RViz) from the container
cd ~/src/wei-hsuan-cheng/legged_control/docker
docker compose up -d
docker exec -it legged_noetic bash
```

## 3. Build legged_control (inside the container, once)

`legged_ws/src/legged_control` is a relative symlink to `../../legged_control`, so it resolves on the host and in the container.

```bash
cd ~/src/wei-hsuan-cheng/legged_ws
catkin init
catkin config --extend /opt/ocs2_ws/devel -DCMAKE_BUILD_TYPE=RelWithDebInfo
catkin build legged_controllers legged_unitree_description legged_gazebo
source devel/setup.bash
```

`legged_unitree_hw` (real robot) is not needed for simulation.

## 4. Run the simulation

Each step in its own `docker exec -it legged_noetic bash` shell (`ROBOT_TYPE` defaults to `a1`):

```bash
# Terminal 1: Gazebo
roslaunch legged_unitree_description empty_world.launch

# Terminal 2: load controllers (type the gait here, e.g. "trot")
roslaunch legged_controllers load_controller.launch cheater:=false

# Terminal 3: start the controller
rosservice call /controller_manager/switch_controller \
  "{start_controllers: ['controllers/legged_controller'], stop_controllers: [], strictness: 0, start_asap: false, timeout: 0.0}"

# Terminal 4: drive it
rosrun rqt_robot_steering rqt_robot_steering   # publishes /cmd_vel
rviz                                           # add RobotModel / TF; use "2D Nav Goal" for move_base_simple/goal
```

The first `load_controller.launch` run auto-generates the OCS2 CppAD libraries, which takes a few minutes.

## Troubleshooting

- Black / crashing Gazebo or RViz window: `LIBGL_ALWAYS_SOFTWARE=1 docker compose up -d` (software rendering).
- `Error when loading 'controllers/...'` from `load_controller.launch`: the controllers are already loaded in this
  Gazebo session (e.g. you re-ran the launch). Harmless: the gait prompt still works and the existing controllers keep
  running. For a clean start, `docker compose restart` and launch from step 4 again.
- `cannot open display`: run `xhost +local:docker` on the host again (resets on logout).
