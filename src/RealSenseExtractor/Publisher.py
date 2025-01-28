from abc import ABC, abstractmethod
class Publisher(ABC):
    @abstractmethod
    def push(self, height, width, depth, timestamp):
        pass