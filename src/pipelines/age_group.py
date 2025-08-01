#!/usr/bin/env python3

import gi
gi.require_version('GstVideo', '1.0')
from gi.repository import Gst, GstVideo

class AgeGroup:
    def __init__(self):
        self.groups = [
            (0, 20, "Not_Eligible"),
            (21, 26, "Young_Adult"),
            (27, 35, "Adult"),
            (36, 59, "Middle_Aged"),
            (60, 200, "Senior")
        ]

    def process_frame(self, frame):
        try:
            with frame.data() as frame_data:
                for region in frame_data.regions():
                    age_value = self._extract_age(region)
                    if age_value is not None:
                        age_group = self._get_age_group(age_value)
                        region.set_label(age_group)
                        region.add_param("age_group", age_group)
        except Exception as e:
            print(f"Error: {e}")
            return False
        return True

    def _extract_age(self, region):
        # Try tensor data first
        for tensor in region.tensors():
            if tensor.name() in ['age_conv3', 'age']:
                data = tensor.data()
                if len(data) > 0:
                    return float(data[0]) * 100
        
        # Try classification metadata
        for classification in region.classifications():
            age_attr = classification.get_attribute("age")
            if age_attr:
                return float(age_attr.get_value())
        
        return None

    def _get_age_group(self, age_value):
        age_value = max(0, min(100, age_value))
        for min_age, max_age, label in self.groups:
            if min_age <= age_value <= max_age:
                return label
        return "Unknown"