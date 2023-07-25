/*********************************************************************
 * Copyright (c) Intel Corporation 2023
 * SPDX-License-Identifier: Apache-2.0
 **********************************************************************/

package utilities

import "flag"

type Flags struct {
	InputSrc     string
	ModelName    string
	ModelVersion string
	URL          string
	Labels       string
	Host         string
	Output       string
}

func ParseFlags() Flags {
	var flags Flags
	flag.StringVar(&flags.InputSrc, "i", "coca-cola-4465029.mp4", "Input src string")
	flag.StringVar(&flags.ModelName, "n", "yolov5s", "Name of model being served. ")
	flag.StringVar(&flags.ModelVersion, "v", "", "Version of model. ")
	flag.StringVar(&flags.URL, "u", "localhost:9000", "Inference Server URL. ")
	flag.StringVar(&flags.Labels, "l", "", "Path to a file with a list of labels.")
	flag.StringVar(&flags.Host, "h", "0.0.0.0:8080", "Restream host location")
	flag.StringVar(&flags.Output, "o", "/tmp/results", "Results output directory")
	flag.Parse()
	return flags
}
