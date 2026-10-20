# Run the simulation example

Assumes the image is built and legged_control is built in `~/src/wei-hsuan-cheng/legged_ws` (see [README.md](README.md)).

You need **4 terminals** (+1 optional for RViz). Every terminal first enters the container:

```bash
docker exec -it legged_noetic bash
```

`ROBOT_TYPE=a1` and workspace sourcing are already set inside the container.

## 0. Clean start (host, once)

```bash
xhost +local:docker
cd ~/src/wei-hsuan-cheng/legged_control/docker && docker compose restart
```

## Terminal 1: Gazebo

```bash
roslaunch legged_unitree_description empty_world.launch
```

Wait until the A1 appears lying on the ground.

## Terminal 2: Load controllers + gait prompt

```bash
roslaunch legged_controllers load_controller.launch cheater:=false
```

Leave it at `Enter the desired gait...`. You'll type gaits here later.

## Terminal 3: Start the controller

```bash
rosservice call /controller_manager/switch_controller "{start_controllers: [controllers/joint_state_controller, controllers/legged_controller], stop_controllers: [], strictness: 0, start_asap: false, timeout: 0.0}"
```

The robot stands up. Then go back to **Terminal 2**, type `trot` and press Enter.

## Terminal 4: Drive it

```bash
rosrun rqt_robot_steering rqt_robot_steering
```

Use the sliders to publish `/cmd_vel`.

## Terminal 5 (optional): RViz

```bash
rviz
```

Set Fixed Frame to `odom` and add **RobotModel** and **TF**. The **2D Nav Goal** tool sends `move_base_simple/goal`.

## Notes

- Type `stance` in Terminal 2 to stop walking.
- Don't type `stance` while the robot is still lying down; it's already in stance.
- To start over, run `docker compose restart` and repeat from Terminal 1.
