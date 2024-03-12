import argparse

def parse_args(print=False):
    parser = argparse.ArgumentParser(
                      prog='benchmark',
                      description='runs benchmarking processes',
                      epilog='Note:\n' +
                                   '\n\t1. dgpu.x should be replaced with targetted GPUs such as dgpu (for all GPUs), dgpu.0, dgpu.1, etc' +
                                   '\n\t2. filesrc will utilize videos stored in the sample-media folder' +
                                   '\n\t3. Set environment variable STREAM_DENSITY_MODE=1 for starting single container stream density testing' +
                                   '\n\t4. Set environment variable RENDER_MODE=1 for displaying pipeline and overlay CV metadata' +
                                   '\n\t5. Stream density can take two parameters: first one TARGET_FPS is for target fps, a float type value, and' +
                                   'the second one PIPELINE_INCREMENT is increment integer of pipelines and is optional (in which case the increments will be dynamically adjusted internally)\n')
    parser.add_argument('--performance_mode', help='the system performance setting [powersave | performance]')
    parser.add_argument('--pipelines', type=int, help='number of pipelines')
    parser.add_argument('--stream_density', type=int, help='target FPS')
    parser.add_argument('--logdir', help='full path to the desired log directory')
    parser.add_argument('--duration', type=int, default=0, help='time in seconds, not needed when --stream_density is specified')
    parser.add_argument('--init_duration', type=int, help='time in seconds')
    parser.add_argument('--platform', help='desired running platform [core|xeon|dgpu.x]')
    parser.add_argument('--inputsrc', help='source of the input video [RS_SERIAL_NUMBER | CAMERA_RTSP_URL | file: video.mp4 | /dev/video0 ]')
    if print:
        parser.print_help()
    return parser.parse_args()

def foo():
    """
    This is a sample function

    :return:
    a fixed string, "bar"
    """
    return "bar"


if __name__ == '__main__':
    parse_args(print=True)
    my_args = parse_args()
    print(my_args)
