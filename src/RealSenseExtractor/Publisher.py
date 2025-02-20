# 
# Copyright (C) 2025 Intel Corporation. 
# 
# SPDX-License-Identifier: Apache-2.0 
#

from abc import ABC, abstractmethod
class Publisher(ABC):
    @abstractmethod
    def push(self, height, width, depth, timestamp):
        pass