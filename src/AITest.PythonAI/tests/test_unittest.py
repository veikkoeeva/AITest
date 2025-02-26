from src.inc_dec import inc_dec
import unittest

class TestIncrementDecrement(unittest.TestCase):
    def test_increment(self):
        self.assertEqual(inc_dec.increment(3), 4)
    
    def test_decrement(self):
        self.assertEqual(inc_dec.decrement(3), 2)  # Corrected expected value

if __name__ == '__main__':
    unittest.main()