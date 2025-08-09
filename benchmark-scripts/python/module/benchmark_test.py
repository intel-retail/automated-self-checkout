import unittest
import benchmark


class Testing(unittest.TestCase):

    def test_foo(self):
        res = benchmark.foo()
        self.assertEqual(res, "bar")


if __name__ == '__main__':
    unittest.main()
