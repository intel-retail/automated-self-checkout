import cv2
import tkinter as tk
from tkinter import ttk, messagebox
from PIL import Image, ImageTk
import glob
import os
import platform
import threading
import time

class CameraMonitor:
    def __init__(self, update_callback):
        self.update_callback = update_callback
        self.running = True
        self.known_cameras = []
        self.monitor_thread = threading.Thread(target=self.monitor_loop)
        self.monitor_thread.daemon = True
        self.monitor_thread.start()

    def monitor_loop(self):
        while self.running:
            current_cameras = self.detect_cameras()
            if current_cameras != self.known_cameras:
                self.known_cameras = current_cameras
                self.update_callback(current_cameras)
            time.sleep(2)

    def stop(self):
        self.running = False

    def detect_cameras(self):
        cameras = []
        try:
            if platform.system() == 'Windows':
                # Check more indexes to account for multiple cameras
                for index in range(20):  # Increased from 10 to 20
                    cap = cv2.VideoCapture(index, cv2.CAP_DSHOW)
                    if cap.isOpened():
                        cameras.append(f"Camera Index {index}")
                        cap.release()
            else:
                # Check both device paths and indexes for Linux/WSL
                cameras = self.check_linux_devices()
                
                # Additional check for integrated cameras using indexes
                if not cameras or self.is_wsl():
                    cameras += self.check_camera_indexes()
        except Exception as e:
            print(f"Camera detection error: {str(e)}")
        return list(set(cameras))  # Remove duplicates

    def check_linux_devices(self):
        devices = []
        # Check standard video devices
        video_devices = glob.glob('/dev/video*')
        for device in video_devices:
            if os.access(device, os.R_OK):
                devices.append(device)
        
        # Check additional potential integrated camera paths
        integrated_paths = [
            '/dev/v4l/by-path/platform-*-video-index*',
            '/dev/v4l/by-id/usb-*-video-index*'
        ]
        for path in integrated_paths:
            devices += glob.glob(path)
        return devices

    def check_camera_indexes(self):
        indexes = []
        for index in range(10):
            try:
                cap = cv2.VideoCapture(index)
                if cap.isOpened():
                    indexes.append(f"Camera Index {index}")
                    cap.release()
            except:
                continue
        return indexes

    def is_wsl(self):
        if platform.system() == 'Linux':
            try:
                with open('/proc/version', 'r') as f:
                    content = f.read().lower()
                    return 'microsoft' in content or 'wsl' in content
            except FileNotFoundError:
                pass
        return False

class CameraApp:
    def __init__(self):
        self.window = tk.Tk()
        self.window.title("Camera Monitor")
        self.window.geometry("1000x800")
        
        # Configure main layout
        self.main_frame = ttk.Frame(self.window)
        self.main_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=20)
        
        # Camera list panel
        self.list_frame = ttk.Frame(self.main_frame, width=300)
        self.list_frame.pack(side=tk.LEFT, fill=tk.Y, padx=10, pady=10)
        
        # Preview panel
        self.preview_frame = ttk.Frame(self.main_frame)
        self.preview_frame.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Camera list components
        ttk.Label(self.list_frame, text="Connected Cameras:", font=('Arial', 12, 'bold')).pack(pady=10)
        self.cam_listbox = tk.Listbox(self.list_frame, width=35, height=20, font=('Arial', 10))
        self.cam_listbox.pack(fill=tk.BOTH, expand=True)
        self.cam_listbox.bind('<<ListboxSelect>>', self.on_camera_select)
        
        # Preview components
        ttk.Label(self.preview_frame, text="Live Preview", font=('Arial', 12, 'bold')).pack(pady=10)
        self.preview_canvas = tk.Canvas(self.preview_frame, bg='#2e2e2e')
        self.preview_canvas.pack(fill=tk.BOTH, expand=True)
        
        self.cap = None
        self.current_cam = None
        self.monitor = CameraMonitor(self.update_camera_list)
        self.window.protocol("WM_DELETE_WINDOW", self.on_close)
        self.window.mainloop()

    def update_camera_list(self, cameras):
        self.window.after(0, self._update_listbox, sorted(cameras))

    def _update_listbox(self, cameras):
        current_selection = self.cam_listbox.curselection()
        current_items = self.cam_listbox.get(0, tk.END)
        
        # Remove disconnected cameras
        for item in set(current_items) - set(cameras):
            self.cam_listbox.delete(current_items.index(item))
            
        # Add new cameras
        for item in set(cameras) - set(current_items):
            self.cam_listbox.insert(tk.END, item)
            
        # Restore selection if still available
        if current_selection:
            selected = self.cam_listbox.get(current_selection)
            if selected in cameras:
                self.cam_listbox.selection_set(current_selection[0])

    def on_camera_select(self, event):
        selection = event.widget.curselection()
        if selection:
            selected_cam = self.cam_listbox.get(selection)
            if selected_cam != self.current_cam:
                self.current_cam = selected_cam
                self.start_preview(selected_cam)

    def start_preview(self, camera_id):
        if self.cap:
            self.cap.release()
            self.cap = None
            
        try:
            # Extract camera index from different identifier formats
            if "video" in camera_id:
                index = int(camera_id.split('video')[-1])
            else:
                index = int(camera_id.split()[-1])
                
            # Use appropriate backend for Windows
            if platform.system() == 'Windows':
                self.cap = cv2.VideoCapture(index, cv2.CAP_DSHOW)
            else:
                self.cap = cv2.VideoCapture(index)
                
            if not self.cap.isOpened():
                raise Exception(f"Failed to access {camera_id}")
            
            self.update_preview()
        except Exception as e:
            messagebox.showerror("Camera Error", str(e))
            self.current_cam = None

    def update_preview(self):
        if self.cap and self.cap.isOpened():
            ret, frame = self.cap.read()
            if ret:
                frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                img = Image.fromarray(frame)
                img.thumbnail((self.preview_canvas.winfo_width(), 
                             self.preview_canvas.winfo_height()))
                
                # Center the image in the canvas
                x = (self.preview_canvas.winfo_width() - img.width) // 2
                y = (self.preview_canvas.winfo_height() - img.height) // 2
                
                self.preview_canvas.delete("all")
                self.preview_image = ImageTk.PhotoImage(image=img)
                self.preview_canvas.create_image(x, y, anchor=tk.NW, 
                                                image=self.preview_image)
                
        self.window.after(30, self.update_preview)

    def on_close(self):
        self.monitor.stop()
        if self.cap:
            self.cap.release()
        self.window.destroy()

if __name__ == "__main__":
    app = CameraApp()