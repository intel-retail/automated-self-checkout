// License: Apache 2.0. See LICENSE file in root directory.
// Copyright(c) 2021 Intel Corporation. All Rights Reserved.

#pragma once

// GCC, when using -pedantic, gives the following inside libusb.h:


#ifdef __GNUC__
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpedantic"
#endif

#include <libusb.h>

#ifdef __GNUC__
#pragma GCC diagnostic pop
#endif
