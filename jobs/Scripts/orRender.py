import argparse
import sys
import os
import subprocess
import psutil
import json

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), os.path.pardir, os.path.pardir)))
from jobs_launcher.core.config import main_logger
from jobs_launcher.core.config import RENDER_REPORT_BASE
import cpuinfo
import ctypes
import pyscreenshot
from local_config import OR_CASE_REPORT_SUFFIX


def get_windows_titles():
    EnumWindows = ctypes.windll.user32.EnumWindows
    EnumWindowsProc = ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int))
    GetWindowText = ctypes.windll.user32.GetWindowTextW
    GetWindowTextLength = ctypes.windll.user32.GetWindowTextLengthW
    IsWindowVisible = ctypes.windll.user32.IsWindowVisible

    titles = []

    def foreach_window(hwnd, lParam):
        if IsWindowVisible(hwnd):
            length = GetWindowTextLength(hwnd)
            buff = ctypes.create_unicode_buffer(length + 1)
            GetWindowText(hwnd, buff, length + 1)
            titles.append(buff.value)
        return True

    EnumWindows(EnumWindowsProc(foreach_window), 0)

    return titles


def createArgsParser():
    parser = argparse.ArgumentParser()

    parser.add_argument('--tests_list', required=True, metavar="<path>")
    parser.add_argument('--app_path', required=True, metavar="<path>")
    parser.add_argument('--assets_path', required=True, metavar="<path")
    parser.add_argument('--output_dir', required=True)
    return parser


def main():
    args = createArgsParser().parse_args()

    with open(args.tests_list, 'r') as file:
        tests_list = json.loads(file.read())

    try:
        os.makedirs(os.path.join(args.output_dir, 'Color'))
    except OSError as err:
        main_logger.error(str(err))
        return 1

    for test in tests_list:
        if test['status'] == 'active':

            case_report = RENDER_REPORT_BASE
            # TODO: fill empty fileds
            case_report.update({
                "test_case": test['name'],
                "original_color_path": "Color/" + test['name'] + '.jpg',
                "original_render_log": test['name'] + '.or.log',
                "render_device": cpuinfo.get_cpu_info()['brand'],
                "file_name": test['name'] + '.png',
                "scene_name": test['name']
            })

            with open(os.path.join(args.output_dir, test['name'] + OR_CASE_REPORT_SUFFIX), 'w') as file:
                json.dump([case_report], file, indent=4)

    tests = ", ".join(['"{}"'.format(x['name']) for x in tests_list if x['status'] == 'active'])

    with open(os.path.join(os.path.dirname(__file__), 'or_template.ms'), 'r') as file:
        ms_script = file.read().format(scene_list=tests,
                                       output_path=os.path.normpath(args.output_dir).replace('\\', '\\\\'),
                                       res_path=os.path.normpath(args.assets_path.replace('\\', '\\\\')))

    with open(os.path.join(args.output_dir, 'render_or_script.ms'), 'w') as file:
        file.write(ms_script)

    cmd_script_path = os.path.join(args.output_dir, 'run_or.bat')
    maxScriptPath = os.path.abspath(os.path.join(args.output_dir, 'render_or_script.ms'))

    cmdRun = '"{tool}" -U MAXScript "{job_script}" -silent'. \
        format(tool=args.app_path, job_script=os.path.join(args.output_dir, 'render_or_script.ms'))

    with open(cmd_script_path, 'w') as file:
        file.write(cmdRun)

    os.chdir(args.output_dir)
    p = psutil.Popen(cmd_script_path, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    rc = -1

    while True:
        try:
            rc = p.communicate(timeout=60)
        except (subprocess.TimeoutExpired, psutil.TimeoutExpired) as err:
            fatal_errors_titles = [maxScriptPath + ' - MAXScript', '3ds Max', 'Microsoft Visual C++ Runtime Library',
                                   '3ds Max Error Report', '3ds Max application', 'Image I/O Error']
            if set(fatal_errors_titles).intersection(get_windows_titles()):
                rc = -1
                try:
                    error_screen = pyscreenshot.grab()
                    error_screen.save(os.path.join(args.output, 'error_screenshot.jpg'))
                except:
                    pass
                for child in reversed(p.children(recursive=True)):
                    child.terminate()
                p.terminate()
                break
        else:
            rc = 0
            break

    for test in tests_list:
        if test['status'] == 'active':
            if os.path.exists(os.path.join(args.output_dir, test['name'] + '.or.render_time.log')):
                try:
                    with open(os.path.join(args.output_dir, test['name'] + '.or.render_time.log'), 'r') as file:
                        time = file.read()
                        with open(os.path.join(args.output_dir, test['name'] + '_AI.json'), 'r') as case_file:
                            temp_case_report = json.loads(case_file.read())
                        temp_case_report[0].update({"render_time": float(time)})
                        with open(os.path.join(args.output_dir, test['name'] + '_AI.json'), 'w') as case_file:
                            json.dump(temp_case_report, case_file, indent=4)
                except Exception as err:
                    main_logger.error("Error {} during AI time log parsing: {}".format(str(err), test['name'] + '.or.render_time.log'))

    return rc


if __name__ == "__main__":
    exit(main())
