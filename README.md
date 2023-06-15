# Traversability Estimation

Segmentation of Images and Point Clouds for Traversability Estimation.

The module assigns to individual measured LiDAR points either a binary flag or non-negative cost
of passing the point by a given robot.
Exit from this module could be used as one of the inputs of the planning module.
Its use allows planning safe paths around obstacles in a mostly static environment.
Example of the module being used in navigation pipeline:
[video](https://www.youtube.com/watch?v=0Kx-SJ763O4),
[in simulator](https://drive.google.com/file/d/1n_Ba2h8XUM64c3eQR-tHYTJO4hkhtB8i/view?usp=share_link).

![](./docs/segmented_pc.png)

### Installation

Please, follow the instructions in [./docs/install.md](./docs/install.md).

#### Docker
To build the package with Docker, you obviously need Docker installed on your system and NVIDIA Container Toolkit set up ([instructions](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#install-guide)). Then issue these commands:
- Run the command `docker build -t traversability_estimation .`. It will install all the dependencies, get the neural network weights and build everything, so it will take a while.
- Run the command `docker run --rm --runtime=nvidia --gpus all --network=host -it traversability_estimation`.

### [Images Semantic Segmentation Node](https://docs.google.com/document/d/1ZKGbDJ3xky1IdwFRN3pk5FYKq3wiQ5QcbyBPlOGammw/edit?usp=sharing)

The node takes as input RGB images and intrinsics (from several cameras as well is supported).
Output is a set of semantic labels for each input RGB image.

#### Topics:

- `input_0/rgb, ... input_{num_cameras - 1}/rgb`
- `input_0/camera_info, ... input_{num_cameras - 1}/camera_info`
- `output_0/semseg,... output_{num_cameras - 1}/semseg`
- `output_0/camera_info,... output_{num_cameras - 1}/camera_info`

#### Parameters:

- `num_cameras [int]` - number of image topics for segmentation
- `device [str]` - cpu/cuda
- `legend [bool]` - if legend for segmentation is required
- `image_transport [str]` - 'compressed' or 'raw' if input image topic is compressed

Look at [segmentation_inferece](./scripts/segmentation_inference) for more details.

### Point Cloud Semantic Segmentation Node

The node takes as input a point cloud from which a depth image is calculated.
The depth image is an input for semantic segmentation network (2D-convolutions based) from
[torchvision.models.segmentation](https://pytorch.org/vision/0.11/models.html#semantic-segmentation).
The network predicts semantic label for each pixel in the depth image.
The labels are futher used to output segmented point cloud.

![](./docs/semantic_traversability_pipeline.png)

#### Topics:

- `cloud_in`: input point cloud to subscribe to
- `cloud_out`: returned segmented point cloud

#### Parameters:

- `device`: device to run tensor operations on: cpu or cuda
- `max_age`: maximum allowed time delay for point clouds time stamps to be processed
- `range_projection [bool]`: whether to perform point cloud projection to range image inside a node
- `lidar_channels`: number of lidar channels of input point cloud (for instance 32 or 64)
- `lidar_beams`: number of lidar beams of input point cloud (for instance 1024 or 2048)
- `lidar_fov_up`: LiDAR sensor vertical field of view (from X-axis to Z-axis direction)
- `lidar_fov_down`: LiDAR sensor vertical field of view (from X-axis against Z-axis direction)
- `weights`: name of torch weights file (*.pth), located in
   [./config/weights/depth_cloud/](http://subtdata.felk.cvut.cz/robingas/data/traversability_estimation/weights/depth_cloud/) folder
- `cloud_in`: topic name to subscribe to (point cloud being segmented)
- `clou_out`: topic name to publish segmented cloud to
- `debug`: whether to publish debug information (for example range image): may slow down the node performance.

Look at [cloud_segmentation](./scripts/cloud_segmentation) for more details.

### Datasets

- For **images** semantic segmentation we provide wrappers for the following datasets:
  
  - [Rellis3DImages](https://unmannedlab.github.io/research/RELLIS-3D)
  - [CWT](https://gamma.umd.edu/researchdirections/autonomousdriving/excavator_tns/)
  - [TraversabilityImages](http://subtdata.felk.cvut.cz/robingas/data/traversability_estimation/TraversabilityDataset/supervised/images/)

- For **point clouds** semantic segmentation we provide wrappers for the following datasets:
  
  - [Rellis3DClouds](https://unmannedlab.github.io/research/RELLIS-3D)
  - [SeamanticKITTI](http://semantic-kitti.org/) and [SemanticUSL](https://unmannedlab.github.io/semanticusl)
  - [TraversabilityClouds](http://subtdata.felk.cvut.cz/robingas/data/traversability_estimation/TraversabilityDataset/supervised/clouds/) and [FlexibilityClouds](http://subtdata.felk.cvut.cz/robingas/data/traversability_estimation/TraversabilityDataset/self_supervised/clouds/)

### Models Training

The following scripts should be run from the [./scripts/tools/](./scripts/tools/) folder:
```commandline
roscd traversability_estimation/scripts/tools/
```

Train point cloud segmentation model to predict traversability labels on SemanticKITTI and SemanticUSL data:

```commandline
python train_depth --datasets SemanticKITTI SemanticUSL --batch_size 4 --output traversability 
```

Train image segmentation model on Rellis3D data:

```commandline
python train_img --dataset Rellis3DImages --batch_size 4 --architecture fcn_resnet50 
```

### Models Evaluation

Evaluate (get IoU score) a point cloud segmentation model trained on TraversabilityClouds data:

```commandline
python eval_depth --dataset TraversabilityClouds --weights /path/to/deeplabv3_resnet101_lr_0.0001_bs_8_epoch_90_TraversabilityClouds_depth_labels_traversability_iou_0.972.pth --output traversability
```

### 3D-Point Cloud Semantic Segmentation Node

The node takes as input a point cloud and utilizes a 3D-convolutions-based network to predict semantic labels for each point.
The model is trained using the semi-supervised technique for domain adaptation proposed in
[T-Concord3D](https://github.com/ctu-vras/T-Concord3D) project.
[Rellis3DClouds](https://unmannedlab.github.io/research/RELLIS-3D)
data was utilized as the source dataset, while
[TraversabilityDataset](http://subtdata.felk.cvut.cz/robingas/data/traversability_estimation/TraversabilityDataset/self_supervised/clouds/)
was utilized as the target dataset (using pseudo-labels).
Please, have a look at the T-Concord3D project repository for more details about the training procedure.

#### Topics:

- `cloud_in`: input point cloud to subscribe to
- `cloud_out`: returned segmented point cloud

#### Parameters:

- `device`: device to run tensor operations on: cpu or cuda
- `max_age`: maximum allowed time delay for point clouds time stamps to be processed
- `weights`: name of torch weights file (*.pt), located in
   [./config/weights/t-concord3d/](http://subtdata.felk.cvut.cz/robingas/data/traversability_estimation/weights/t-concord3d/) folder
- `cloud_in`: topic name to subscribe to (point cloud being segmented)
- `clou_out`: topic name to publish segmented cloud to

Look at [cloud_segmentation_tconcord3d](./scripts/cloud_segmentation_tconcord3d) for more details.

### Geometric Traversability Node

Manually designed geometric features describing the local neighborhood of points based on:

- estimation of **slope** (inclination angles) of supporting terrain,
- estimation of **step** of supporting terrain.

For more information, please, refer to traversability node implemented in the
[naex](https://github.com/ctu-vras/naex/) package.

### Fused Traversability Node

Method which combines geometric and semantic traversability results.
Definitely passable and definitely impassable costs assigned to points values were defined on the basis of geometrical traversability.
In the rest of the area (part of point cloud), especially in vegetation where geometrical approach cannot be applied,
a model learned from the data was used (semantic traversability estimation).

#### Topics:

- `geometric_traversability`: input point cloud to subscribe to containing geometric traversability information
- `semantic_traversability`: input point cloud to subscribe to containing semantic traversability information
- `fused_traversability`: output point cloud topic to be published containing resultant traversability information

#### Parameters:

- `fixed_frame`: name of the coordinate frame to consider constant in time to find transformation between semantic and geometric clouds frames
- `trigger`: one of "both", "geometric", "semantic", or "timer": defines when to perform traversability cost fusion based on availability of actual geometric or semantic data
- `sync`: whether to use [approximate time synchronizer](http://wiki.ros.org/message_filters#ApproximateTime_Policy) or fuse latest available geometric and semantic messages
- `max_time_diff`: maximum allowed time difference between semantic and geometric messages
- `dist_th`: maximum allowed distance between closest points from geometric and semantic clouds
- `flat_cost_th`: lower value of geometrical traversability cost starting from which seamntic traversability is used
- `obstacle_cost_th`: higher value of geometrical traversability cost starting from which seamntic traversability is not used
- `semantic_cost_offset`: value to add to semantic traversability cost (in the range it's being utilized)
- `timeout`: time to wait for the target frame to become available (when looking for transformation between geometric and semantic clouds frames)

Look at [traversability_fusion](./scripts/traversability_fusion) for more details.

### Demos

- Semantic segmentation of images from RELLIS-3D dataset with HRNet:

    ```bash
    roslaunch traversability_estimation image_segmentation_dataset_demo.launch model_name:=hrnet
    ```
  
- Semantic segmentation of point clouds from RELLIS-3D dataset:

    ```bash
    roslaunch traversability_estimation traversability_dataset_demo.launch traversability:=semantic
    ```

- Coloring lidar cloud using calibrated cameras and semantic classes:

    ![](./docs/colored_pc_demo.png)
    
    - Clone and build the [point_cloud_color](https://github.com/ctu-vras/point_cloud_color) package.
    - Run demo:
        ```bash
        roslaunch traversability_estimation color_pc_bagfile_demo.launch
        ```

### Citation

Please, cite the paper if you find the package relevant to your research:

[Trajectory Optimization using Learned Robot-Terrain Interaction Model in Exploration of Large Subterranean Environments](https://ieeexplore.ieee.org/document/9699042).

```
@ARTICLE{9699042,
  author={Agishev, Ruslan and Petříček, Tomáš and Zimmermann, Karel},
  journal={IEEE Robotics and Automation Letters},
  title={Trajectory Optimization Using Learned Robot-Terrain Interaction Model in Exploration of Large Subterranean Environments},
  year={2022},
  volume={7},
  number={2},
  pages={3365-3371},
  doi={10.1109/LRA.2022.3147332}
}
```
