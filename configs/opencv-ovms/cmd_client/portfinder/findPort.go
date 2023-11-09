// ----------------------------------------------------------------------------------
// Copyright 2023 Intel Corp.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//	   http://www.apache.org/licenses/LICENSE-2.0
//
//	Unless required by applicable law or agreed to in writing, software
//	distributed under the License is distributed on an "AS IS" BASIS,
//	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//	See the License for the specific language governing permissions and
//	limitations under the License.
//
// ----------------------------------------------------------------------------------

package portfinder

import (
	"fmt"
	"log"
	"net"
)

const (
	defaultStartPort = 9000
)

type PortFinder struct {
	IpAddress string
}

func (pf *PortFinder) GetFreePortNumber(from int) int {
	if from <= 0 {
		return defaultStartPort
	}

	if tcpAddr, err := net.ResolveTCPAddr("tcp", fmt.Sprintf("%s:0", pf.IpAddress)); err == nil {
		var tcpLis *net.TCPListener
		if tcpLis, err = net.ListenTCP("tcp", tcpAddr); err == nil {
			defer tcpLis.Close()
			portNum := tcpLis.Addr().(*net.TCPAddr).Port
			if portNum < from { // retry again until we find one port number is bigger
				return pf.GetFreePortNumber(from)
			}
			return portNum
		}
	} else {
		log.Printf("resolve error on tcpAddr: %v", tcpAddr)
	}
	return defaultStartPort
}
