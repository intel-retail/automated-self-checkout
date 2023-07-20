package utilities

import "math"

func ExpPow(val float32) float32 {
	val_float64 := float64(val)
	results := math.Exp(val_float64)
	return float32(results)
}

func Sigmoid(x float32) float32 {
	return 1.0 / (1.0 + ExpPow(-x))
}

func Min(value1 float32, value2 float32) float32 {
	if value1 < value2 {
		return value1
	}
	return value2
}

func Max(value1 float32, value2 float32) float32 {
	if value1 > value2 {
		return value1
	}
	return value2
}

func Clamp(val float32, min float32, max float32) float32 {
	if val < min {
		return min
	}
	if val > max {
		return max
	}
	return val
}
