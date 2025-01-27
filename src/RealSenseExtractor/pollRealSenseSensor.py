import pyrealsense2 as rs

pipeline = rs.pipeline()
config = rs.config()
config.enable_stream(rs.stream.depth, rs.format.z16)
pipeline.start(config)

while True:
    try:
        frames = pipeline.wait_for_frames()
        depth_frame = frames.get_depth_frame()
            
        if not depth_frame:
            raise RuntimeError("Could not get depth frame")

        width = depth_frame.get_width()
        height = depth_frame.get_height()
        time_stamp = depth_frame.get_timestamp()
        center_x, center_y = width // 2, height // 2
        depth = depth_frame.get_distance(center_x, center_y)


    finally:
        pipeline.stop()
