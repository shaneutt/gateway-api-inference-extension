/*
Copyright 2025 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package scheduling

import (
	"fmt"
	"math/rand/v2"

	"sigs.k8s.io/gateway-api-inference-extension/pkg/epp/scheduling/types"
	logutil "sigs.k8s.io/gateway-api-inference-extension/pkg/epp/util/logging"
)

type maxScorePicker struct {
}

func (p *maxScorePicker) Name() string {
	return "max score picker"
}

func (p *maxScorePicker) Pick(ctx *types.Context, pods []types.Pod) (*types.Result, error) {
	ctx.Logger.V(logutil.DEBUG).Info(fmt.Sprintf("Selecting a pod with maximum score from %d candidates: %+v", len(pods), pods))

	// select pod with maximum score, if more than one with the max score - use random pods from the list
	var highestScoreTargets []types.Pod
	// score weights cound be negative
	maxScore := 0.0
	isFirst := true

	for _, pod := range pods {
		if isFirst {
			maxScore = pod.Score()
			highestScoreTargets = []types.Pod{pod}
			isFirst = false
		} else {
			if pod.Score() > maxScore {
				maxScore = pod.Score()
				highestScoreTargets = []types.Pod{pod}
			} else if pod.Score() == maxScore {
				highestScoreTargets = append(highestScoreTargets, pod)
			}
		}
	}

	// single pod with max score
	if len(highestScoreTargets) == 1 {
		return &types.Result{TargetPod: highestScoreTargets[0]}, nil
	}

	// select random pod from list of pods with max score
	return &types.Result{TargetPod: highestScoreTargets[rand.IntN(len(highestScoreTargets))]}, nil
}
